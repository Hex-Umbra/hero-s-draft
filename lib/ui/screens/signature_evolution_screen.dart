import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import 'package:roguelike_card_game/ui/theme/app_spacing.dart';
import '../../game/controllers/run_controller.dart';
import '../../game/systems/signature_evolution_rules.dart';
import '../../models/data/signature_evolution_data.dart';
import '../../models/signature_instance.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/game_moment.dart';
import '../../services/audio/music_scene.dart';
import '../../services/game_data_service.dart';
import '../widgets/class_identity.dart';
import '../widgets/effect_style.dart';
import '../widgets/game_button.dart';
import '../widgets/page_header.dart';
import '../widgets/screen_scaffold.dart';
import '../widgets/signature_run_card.dart';
import '../widgets/ui_card/ui_card_helpers.dart';

/// Le choix des évolutions de [signatures], sur un seul écran (D78, D79) :
/// aucun tirage, tout ce que le palier admet se choisit, et le reste du pool se
/// lit. Toucher une ligne la sélectionne, la fiche montre le résultat, et seul
/// le bouton prend les évolutions, toutes ensemble, puis [onComplete]. Le
/// retour ramène au rideau sans rien perdre : rien n'est tiré à l'ouverture.
class SignatureEvolutionScreen extends ConsumerStatefulWidget {
  final List<SignatureInstance> signatures;
  final VoidCallback onComplete;

  const SignatureEvolutionScreen({
    super.key,
    required this.signatures,
    required this.onComplete,
  });

  @override
  ConsumerState<SignatureEvolutionScreen> createState() =>
      _SignatureEvolutionScreenState();
}

class _SignatureEvolutionScreenState
    extends ConsumerState<SignatureEvolutionScreen> {
  /// L'évolution sélectionnée de chaque signature, par id de signature.
  final Map<String, SignatureEvolutionData> _selected = {};
  bool _confirmed = false;

  /// Le niveau déjà pris de [evolution] sur [signature], 0 si elle n'est pas
  /// prise.
  int _takenLevel(
    SignatureInstance signature,
    SignatureEvolutionData evolution,
  ) =>
      signature.taken
          .where((t) => t.$1.id == evolution.id)
          .map((t) => t.$2)
          .firstOrNull ??
      0;

  void _select(SignatureInstance signature, SignatureEvolutionData evolution) {
    ref.read(audioDirectorProvider).onMoment(GameMoment.draftCardPick);
    setState(() => _selected[signature.data.id] = evolution);
  }

  void _confirm() {
    if (_confirmed) return;
    _confirmed = true;
    final run = ref.read(runProvider.notifier);
    // Refusé ou non, le rideau de la carte rouvre ce qui reste.
    for (final MapEntry(key: signatureId, value: evolution)
        in _selected.entries) {
      run.chooseSignatureEvolution(signatureId, evolution.id);
    }
    widget.onComplete();
  }

  /// [signature] telle qu'elle sera après le choix sélectionné, s'il y en a un.
  SignatureInstance _preview(SignatureInstance signature) {
    final selected = _selected[signature.data.id];
    if (selected == null) return signature;
    return SignatureEvolutionRules.take(signature, selected.id) ?? signature;
  }

  /// La ligne d'une évolution du palier : son texte au niveau qu'elle prendrait.
  Widget _choiceRow(
    AppLocalizations l10n,
    SignatureInstance signature,
    SignatureEvolutionData evolution,
    Color classColor,
  ) {
    final taken = _takenLevel(signature, evolution);
    final description = evolution.getDescription(
      taken + 1,
      l10n.localeName,
      cost: signature.data.cost,
    );
    return _EvolutionRow(
      evolution: evolution,
      description: taken > 0
          ? l10n.evolutionBoardLevelUp(taken, taken + 1, description)
          : description,
      accent: classColor,
      selected: evolution.id == _selected[signature.data.id]?.id,
      onTap: () => _select(signature, evolution),
    );
  }

  /// La ligne d'une évolution qu'on ne peut pas prendre maintenant : son texte
  /// à son niveau actuel, ou au premier si elle n'est pas prise.
  Widget _lockedRow(
    AppLocalizations l10n,
    SignatureInstance signature,
    SignatureEvolutionData evolution,
    Color classColor, {
    String? tag,
  }) {
    final taken = _takenLevel(signature, evolution);
    return _EvolutionRow(
      evolution: evolution,
      description: evolution.getDescription(
        taken > 0 ? taken : 1,
        l10n.localeName,
        cost: signature.data.cost,
      ),
      accent: classColor,
      tag: tag,
    );
  }

  /// Le pool de [signature], section par section : ce qu'on peut prendre
  /// d'abord.
  List<Widget> _pool(
    AppLocalizations l10n,
    SignatureInstance signature,
    Color classColor,
  ) {
    final locale = l10n.localeName;
    final board = SignatureEvolutionRules.board(signature);
    final upcomingMinors = signature.nextTier == EvolutionTier.major;
    return [
      _SectionTitle(l10n.evolutionBoardToChoose, color: classColor),
      for (final evolution in board.choices)
        _choiceRow(l10n, signature, evolution, classColor),
      if (board.upcoming.isNotEmpty) ...[
        _SectionTitle(
          upcomingMinors
              ? l10n.evolutionBoardUpcomingMinors(board.upcomingHeroLevel)
              : l10n.evolutionBoardUpcomingMajors(board.upcomingHeroLevel),
        ),
        for (final evolution in board.upcoming)
          _lockedRow(
            l10n,
            signature,
            evolution,
            classColor,
            tag: _takenLevel(signature, evolution) > 0
                ? l10n.evolutionBoardTakenLevel(
                    _takenLevel(signature, evolution),
                  )
                : null,
          ),
      ],
      if (board.takenMajors.isNotEmpty) ...[
        _SectionTitle(l10n.evolutionBoardTaken),
        for (final evolution in board.takenMajors)
          _lockedRow(l10n, signature, evolution, classColor),
      ],
      if (board.excluded.isNotEmpty) ...[
        _SectionTitle(l10n.evolutionBoardExcluded),
        for (final (evolution, by) in board.excluded)
          _lockedRow(
            l10n,
            signature,
            evolution,
            classColor,
            tag: l10n.evolutionBoardExcludedBy(by.getName(locale)),
          ),
      ],
    ];
  }

  String _tierLine(AppLocalizations l10n, SignatureInstance signature) {
    final level = signature.nextEvolutionHeroLevel;
    return signature.nextTier == EvolutionTier.major
        ? l10n.evolutionBoardTierMajor(level)
        : l10n.evolutionBoardTierMinor(level);
  }

  Widget _confirmButton(AppLocalizations l10n, Color classColor) {
    final signatures = widget.signatures;
    final ready = signatures.every((s) => _selected.containsKey(s.data.id));
    final String text;
    if (signatures.length > 1) {
      text = ready ? l10n.evolutionBoardTakeBoth : l10n.evolutionBoardPickBoth;
    } else {
      final selected = _selected[signatures.single.data.id];
      text = selected == null
          ? l10n.evolutionBoardPick
          : l10n.evolutionBoardTake(selected.getName(l10n.localeName));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GameButton(
          text: text,
          baseColor: classColor,
          width: double.infinity,
          onPressed: ready ? _confirm : null,
        ),
      ),
    );
  }

  /// Large : une colonne par signature, sa fiche puis son pool. Chaque colonne
  /// défile seule. Sans [withSheet], sur une fenêtre basse où la fiche cacherait
  /// le pool, le coût et la recharge d'après le choix la remplacent.
  Widget _wide(
    AppLocalizations l10n,
    int heroLevel,
    Color classColor, {
    required bool withSheet,
  }) {
    final signatures = widget.signatures;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560.0 * signatures.length),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            for (final signature in signatures)
              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tierLine(l10n, signature),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            withSheet
                                ? (_selected.containsKey(signature.data.id)
                                        ? l10n.evolutionBoardAfter
                                        : l10n.evolutionBoardToday)
                                    .toUpperCase()
                                : l10n.signatureCostAndCooldown(
                                    _preview(signature).cost,
                                    _preview(signature).cooldown,
                                  ),
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (withSheet)
                      SignatureRunCard(
                        signature: _preview(signature),
                        heroLevel: heroLevel,
                        classColor: classColor,
                      ),
                    ..._pool(l10n, signature, classColor),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Le pool d'une signature sur téléphone : la fiche ne tient pas, le coût et
  /// la recharge d'après le choix restent visibles sous la liste.
  Widget _narrowPage(
    AppLocalizations l10n,
    SignatureInstance signature,
    Color classColor,
  ) {
    final preview = _preview(signature);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              Text(
                _tierLine(l10n, signature),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              ..._pool(l10n, signature, classColor),
            ],
          ),
        ),
        AppSpacing.heightSm,
        Text(
          l10n.signatureCostAndCooldown(preview.cost, preview.cooldown),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
        ),
      ],
    );
  }

  /// Téléphone : un onglet par signature, coché quand son choix est fait.
  Widget _narrow(AppLocalizations l10n, Color classColor) {
    final signatures = widget.signatures;
    if (signatures.length == 1) {
      return _narrowPage(l10n, signatures.single, classColor);
    }
    return DefaultTabController(
      length: signatures.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            indicatorColor: classColor,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            tabs: [
              for (final signature in signatures)
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      Flexible(
                        child: Text(
                          signature.data.getName(l10n.localeName),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_selected.containsKey(signature.data.id))
                        Icon(Icons.check_circle, color: classColor, size: 16),
                    ],
                  ),
                ),
            ],
          ),
          AppSpacing.heightSm,
          Expanded(
            child: TabBarView(
              children: [
                for (final signature in signatures)
                  _narrowPage(l10n, signature, classColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.read(musicConductorProvider).onScene(MusicScene.map);

    final l10n = AppLocalizations.of(context)!;
    final runState = ref.watch(runProvider);
    final gameData = ref.watch(gameDataLoaderProvider).requireValue;
    final classColor = ClassIdentity.colorOf(
      gameData.heroes.firstWhere((h) => h.id == runState.heroClassId),
    );
    final signatures = widget.signatures;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: PageHeader(
        title: signatures.length > 1
            ? l10n.evolutionScreenTitleBoth
            : l10n.evolutionScreenTitle(
                signatures.single.data.getName(l10n.localeName),
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 600
                    ? _narrow(l10n, classColor)
                    : _wide(
                        l10n,
                        runState.heroStats.level,
                        classColor,
                        withSheet: constraints.maxHeight >= 420,
                      ),
              ),
            ),
            AppSpacing.heightSm,
            _confirmButton(l10n, classColor),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle(this.text, {this.color = const Color(0xFF8A8A98)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Une évolution du pool. Sans [onTap], elle ne se prend pas maintenant : sa
/// ligne est plus petite et éteinte, avec [tag] pour dire pourquoi.
class _EvolutionRow extends StatelessWidget {
  static const _dimName = Color(0xFF8A8A98);
  static const _dimText = Color(0xFF6E6E7C);

  final SignatureEvolutionData evolution;
  final String description;
  final Color accent;
  final bool selected;
  final String? tag;
  final VoidCallback? onTap;

  const _EvolutionRow({
    required this.evolution,
    required this.description,
    required this.accent,
    this.selected = false,
    this.tag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = onTap == null;
    final tag = this.tag;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? Color.alphaBlend(accent.withAlpha(46), neutralCardBackground)
            : (locked ? const Color(0xFF191926) : neutralCardBackground),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected
                ? accent
                : (locked ? const Color(0xFF2A2A38) : const Color(0xFF3C3C50)),
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: locked ? 7 : 10,
            ),
            child: Row(
              spacing: 10,
              children: [
                EvolutionIcon(
                  evolution: evolution,
                  size: locked ? 22 : 28,
                  color: locked
                      ? Color.alphaBlend(
                          EvolutionIcon.tintOf(evolution).withAlpha(115),
                          const Color(0xFF191926),
                        )
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evolution.getName(
                          AppLocalizations.of(context)!.localeName,
                        ),
                        style: TextStyle(
                          color: locked ? _dimName : Colors.white,
                          fontSize: locked ? 13 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          color: locked ? _dimText : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tag != null)
                  Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (selected)
                  Icon(Icons.check_circle, color: accent, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
