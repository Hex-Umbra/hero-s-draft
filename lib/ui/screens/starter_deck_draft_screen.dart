import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/controllers/deck_controller.dart';
import '../../game/systems/starter_draft.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/data/hero_data.dart';
import '../../models/data/hero_skills_link.dart';
import '../../models/data/passive_data.dart';
import '../../services/game_data_service.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/game_moment.dart';
import '../../services/audio/music_scene.dart';
import '../widgets/class_identity.dart';
import '../widgets/ui_card.dart';
import 'map_screen.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/draft/card_draft_layout.dart';

class StarterDeckDraftScreen extends ConsumerStatefulWidget {
  final HeroData playerClass;
  final PassiveData? passive;

  const StarterDeckDraftScreen({
    super.key,
    required this.playerClass,
    required this.passive,
  });

  @override
  ConsumerState<StarterDeckDraftScreen> createState() =>
      _StarterDeckDraftScreenState();
}

class _StarterDeckDraftScreenState
    extends ConsumerState<StarterDeckDraftScreen> {
  late StarterDraft _draft;
  // Index dans `_draft.pool` : le lot d'abord, puis les neutres.
  final Set<int> _selectedIndexes = {};
  bool _isPoolGenerated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPoolGenerated) {
      _generateDraftPool();
      _isPoolGenerated = true;
    }
  }

  void _generateDraftPool() {
    final gameData = ref.read(gameDataLoaderProvider).requireValue;

    // Le pool est affiché et sélectionné par index, sans mélange : sans tri
    // explicite (fait par `StarterDraft`), le premier choix d'une run suivrait
    // l'ordre du registre, c'est-à-dire l'ordre alphabétique des `id`.
    _draft = StarterDraft.of(gameData.cards, widget.passive?.id);
  }

  List<CardData> get _chosen => [
    for (final idx in _selectedIndexes) _draft.pool[idx],
  ];

  void _toggleCardSelection(int index) {
    final l10n = AppLocalizations.of(context)!;
    ref.read(audioDirectorProvider).onMoment(GameMoment.draftCardPick);
    final card = _draft.pool[index];
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else if (_draft.accepts(_chosen, card)) {
        _selectedIndexes.add(index);
      } else {
        context.showNotification(
          card.passive != null
              ? l10n.draftDeckSnackbarMaxLot(_draft.lotQuota)
              : l10n.draftDeckSnackbarMaxNeutral(_draft.neutralQuota),
          type: NotificationType.warning,
        );
      }
    });
  }

  void _startAdventure() {
    if (!_draft.isComplete(_chosen)) return;

    // 2. Le deck de départ : les 5 cartes choisies, rien d'autre. Les
    // signatures de la classe ne sont pas des cartes.
    final List<CardInstance> finalDeck = [
      for (final card in _chosen) CardInstance(data: card),
    ];

    // 3. Initialiser les providers
    final gameData = ref.read(gameDataLoaderProvider).requireValue;
    ref.read(deckProvider.notifier).clearDeck();
    ref
        .read(runProvider.notifier)
        .startNewRun(
          widget.playerClass,
          widget.passive,
          widget.playerClass.getSignatures(gameData),
        );
    ref.read(deckProvider.notifier).initializeStarterDeck(finalDeck);

    // 4. Redirection propre vers la map de jeu
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MapScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;

    final classColor = ClassIdentity.colorOf(widget.playerClass);

    final isConfirmEnabled = _draft.isComplete(_chosen);
    final passive = widget.passive;

    return CardDraftLayout(
      title: l10n.draftDeckTitle,
      subtitle: l10n.draftDeckSubtitle,
      cardCountText: l10n.draftDeckSelectedCount(_selectedIndexes.length),
      confirmButtonText: l10n.draftDeckProceed,
      onConfirm: _startAdventure,
      isConfirmEnabled: isConfirmEnabled,
      themeColor: classColor,
      // Rien n'est encore engagé : la run ne démarre qu'à la validation.
      onBack: () => Navigator.of(context).maybePop(),
      child: _draft.pool.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Un groupe vide (run sans passif) n'a pas de section.
                  if (passive != null && _draft.lot.isNotEmpty)
                    _buildSection(
                      key: const ValueKey('starter-draft-lot'),
                      title: l10n.draftDeckLotSection(passive.getName(locale)),
                      cards: _draft.lot,
                      offset: 0,
                      quota: _draft.lotQuota,
                      classColor: classColor,
                      isMobile: isMobile,
                    ),
                  if (_draft.neutrals.isNotEmpty)
                    _buildSection(
                      key: const ValueKey('starter-draft-neutral'),
                      title: l10n.draftDeckNeutralSection,
                      cards: _draft.neutrals,
                      offset: _draft.lot.length,
                      quota: _draft.neutralQuota,
                      classColor: classColor,
                      isMobile: isMobile,
                    ),
                ],
              ),
            ),
    );
  }

  /// Une section : son titre, son compteur `choisis/quota`, sa grille. `offset`
  /// est l'index de sa première carte dans `_draft.pool`.
  Widget _buildSection({
    required Key key,
    required String title,
    required List<CardData> cards,
    required int offset,
    required int quota,
    required Color classColor,
    required bool isMobile,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final picked = _chosen.where((c) => cards.contains(c)).length;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: classColor,
                    fontSize: isMobile ? 14 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.draftDeckQuota(picked, quota),
                style: TextStyle(
                  color: picked == quota ? Colors.greenAccent : Colors.white70,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isMobile ? 140 : 180,
            childAspectRatio: 70 / 110,
            crossAxisSpacing: isMobile ? 8 : 16,
            mainAxisSpacing: isMobile ? 8 : 16,
          ),
          itemCount: cards.length,
          itemBuilder: (context, i) =>
              _buildCard(context, offset + i, classColor),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCard(BuildContext context, int index, Color classColor) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final card = _draft.pool[index];
    final isSelected = _selectedIndexes.contains(index);
    // Le plafond se lit par groupe : une carte du lot reste claire tant que
    // le lot n'est pas plein, même si les neutres le sont.
    final isGroupFull = !isSelected && !_draft.accepts(_chosen, card);

    return GestureDetector(
      onTap: () => _toggleCardSelection(index),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isGroupFull ? 0.4 : 1.0,
        child: Stack(
          children: [
            UiCard.fromData(
              card: card,
              locale: locale,
              l10n: l10n,
              isSelected: isSelected,
            ),
            // Indicateur Checkmark
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: classColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
