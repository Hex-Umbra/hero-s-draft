import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/controllers/inventory_controller.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/services/forge_rune_rules.dart';
import '../../models/card_instance.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../models/data/game_data_registry.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/forge/forge_slot_row.dart';
import '../widgets/game_button.dart';
import '../widgets/gold_indicator.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/page_header.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/ui_card.dart';

/// Le Puits d'échange (D6, D22 ; spec P-43 E2, A5, §4.8) : une rune d'une
/// carte contre n'importe quelle autre que le prédicat lui permet, aux deux
/// tiers de son niveau, contre `50 × niveau` or. Un échange par visite : fait,
/// l'écran ne propose plus que la sortie, et toute sortie résout le nœud. Le
/// nœud garde son type `forgeFusion`, l'écran son nom (A17).
class ForgeFusionScreen extends ConsumerStatefulWidget {
  const ForgeFusionScreen({super.key});

  @override
  ConsumerState<ForgeFusionScreen> createState() => _ForgeFusionScreenState();
}

class _ForgeFusionScreenState extends ConsumerState<ForgeFusionScreen> {
  /// La carte choisie, par son identifiant : elle se relit dans le deck.
  String? _cardId;

  /// La rune à donner, sur la carte choisie.
  String? _givenId;

  /// Un échange par visite (spec P-43 E2, A5) : un état de déroulé de
  /// l'écran, qui ne lui survit pas — toute sortie après l'échange résout le
  /// nœud.
  bool _exchanged = false;

  /// Les runes du [catalog] que [card] porte, chacune à son niveau.
  static List<(ForgeUpgradeData, int)> _runesOf(
    CardInstance card,
    List<ForgeUpgradeData> catalog,
  ) =>
      [
        for (final MapEntry(key: id, value: level)
            in ForgeUpgradeData.levelsOf(card.forgeUpgrades).entries)
          if (catalog.where((r) => r.id == id).firstOrNull case final rune?)
            (rune, level),
      ];

  void _exchange(
    CardInstance card,
    ForgeUpgradeData given,
    ForgeUpgradeData received,
    int level,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    if (!ref
        .read(runProvider.notifier)
        .exchangeRune(card.uniqueId, given.id, received.id)) {
      return;
    }
    setState(() => _exchanged = true);
    context.showNotification(
      l10n.wellDone(given.getName(locale), received.getName(locale), level),
      type: NotificationType.success,
    );
  }

  void _leave() {
    ref.read(runProvider.notifier).completeCurrentNode();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final gold = ref.watch(inventoryProvider).gold;
    final catalog = GameDataRegistry.instance?.forgeUpgrades ?? const [];
    final cards = [
      for (final card in ref.watch(deckProvider).masterDeck)
        if (_runesOf(card, catalog).isNotEmpty) card,
    ];
    final selected = cards.where((c) => c.uniqueId == _cardId).firstOrNull;

    final Widget content;
    if (_exchanged) {
      content = const Center(
        child: Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
      );
    } else if (cards.isEmpty) {
      content = Center(
        child: Text(
          l10n.wellEmpty,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      content = SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.wellPickCard,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final card in cards)
                  SizedBox(
                    width: 120,
                    child: UiCard.fromInstance(
                      card: card,
                      locale: locale,
                      l10n: l10n,
                      isSelected: card.uniqueId == _cardId,
                      onTap: () => setState(() {
                        _cardId = card.uniqueId;
                        _givenId = null;
                      }),
                    ),
                  ),
              ],
            ),
            if (selected != null) ..._runeChoice(selected, catalog, gold),
          ],
        ),
      );
    }

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      // Avant tout échange, le retour ferme l'écran sans résoudre le nœud :
      // le joueur peut revenir. Après, il le résout par le chemin de la
      // sortie ; le pop de `_leave` repasse ici avec `didPop` vrai (A5).
      canPop: !_exchanged,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      appBar: PageHeader(
        title: l10n.wellTitle,
        showBackButton: false,
        isParchment: false,
        actions: const [GoldIndicator()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: content),
            const SizedBox(height: 24),
            Center(
              child: GameButton(
                text: l10n.wellLeave,
                onPressed: _leave,
                baseColor: Colors.deepPurpleAccent,
                height: 48,
                width: 220,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Les runes de [card], la rune à donner choisie parmi elles, puis toutes
  /// ses remplaçantes (spec P-43 E2, A5, §4.8). Une rune sans remplaçante se
  /// montre inactive, avec son motif.
  List<Widget> _runeChoice(
    CardInstance card,
    List<ForgeUpgradeData> catalog,
    int gold,
  ) {
    final runes = _runesOf(card, catalog);
    final given = runes.where((r) => r.$1.id == _givenId).firstOrNull;
    return [
      const SizedBox(height: 24),
      for (final (rune, level) in runes) _givenTile(card, rune, level, catalog),
      if (given case (final rune, final level)) ...[
        const SizedBox(height: 16),
        for (final received in ForgeRuneRules.wellOptions(card, rune.id, catalog))
          _optionRow(card, rune, level, received, gold),
      ],
    ];
  }

  /// Une rune de la carte, à donner.
  Widget _givenTile(
    CardInstance card,
    ForgeUpgradeData rune,
    int level,
    List<ForgeUpgradeData> catalog,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final hasOption =
        ForgeRuneRules.wellOptions(card, rune.id, catalog).isNotEmpty;
    return ListTile(
      enabled: hasOption,
      selected: rune.id == _givenId,
      textColor: Colors.white,
      selectedColor: Colors.deepPurpleAccent,
      selectedTileColor: Colors.white10,
      leading: Text(rune.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(rune.nameAt(level, locale)),
      subtitle: hasOption
          ? null
          : Text(
              l10n.wellNoOption,
              style: const TextStyle(color: Colors.white54),
            ),
      onTap: () => setState(() => _givenId = rune.id),
    );
  }

  /// Une remplaçante de [given], portée au niveau [givenLevel] : son niveau
  /// d'arrivée, ce qu'elle fait sur la carte, et « Échanger — coût or »,
  /// inactif faute d'or.
  Widget _optionRow(
    CardInstance card,
    ForgeUpgradeData given,
    int givenLevel,
    ForgeUpgradeData received,
    int gold,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    // Sous le plafond effectif de la run (spec P-43 E3, §4.8, A17).
    final level = ForgeRuneRules.wellLevel(
      received,
      givenLevel,
      capBonus: ref.watch(runProvider).runeCapBonus,
    );
    final cost = ForgeRuneRules.wellCost(givenLevel);
    return ForgeSlotRow(
      rune: received,
      title: received.getName(locale),
      detail: l10n.wellReceive(level),
      description:
          received.getDescription(level, locale, card.data, card.rarity),
      actionLabel: l10n.wellExchange(cost),
      onAction: gold >= cost
          ? () => _exchange(card, given, received, level)
          : null,
    );
  }
}
