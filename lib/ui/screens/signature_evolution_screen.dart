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

/// Le choix d'une évolution de [signature], sur le tableau de son pool (D78) :
/// aucun tirage, tout ce que le palier admet se choisit, et le reste du pool se
/// lit. Toucher une ligne la sélectionne, la fiche montre le résultat, et seul
/// le bouton prend l'évolution, puis [onComplete]. Le retour ramène au rideau
/// sans rien perdre : rien n'est tiré à l'ouverture.
class SignatureEvolutionScreen extends ConsumerStatefulWidget {
  final SignatureInstance signature;
  final VoidCallback onComplete;

  const SignatureEvolutionScreen({
    super.key,
    required this.signature,
    required this.onComplete,
  });

  @override
  ConsumerState<SignatureEvolutionScreen> createState() =>
      _SignatureEvolutionScreenState();
}

class _SignatureEvolutionScreenState
    extends ConsumerState<SignatureEvolutionScreen> {
  SignatureEvolutionData? _selected;
  bool _confirmed = false;

  /// Le niveau déjà pris de [evolution], 0 si elle n'est pas prise.
  int _takenLevel(SignatureEvolutionData evolution) =>
      widget.signature.taken
          .where((t) => t.$1.id == evolution.id)
          .map((t) => t.$2)
          .firstOrNull ??
      0;

  void _select(SignatureEvolutionData evolution) {
    ref.read(audioDirectorProvider).onMoment(GameMoment.draftCardPick);
    setState(() => _selected = evolution);
  }

  void _confirm(SignatureEvolutionData evolution) {
    if (_confirmed) return;
    _confirmed = true;
    // Refusé ou non, le rideau de la carte rouvre ce qui reste.
    ref
        .read(runProvider.notifier)
        .chooseSignatureEvolution(widget.signature.data.id, evolution.id);
    widget.onComplete();
  }

  /// La ligne d'une évolution du palier : son texte au niveau qu'elle prendrait.
  Widget _choiceRow(
    AppLocalizations l10n,
    SignatureEvolutionData evolution,
    Color classColor,
  ) {
    final taken = _takenLevel(evolution);
    final description = evolution.getDescription(
      taken + 1,
      l10n.localeName,
      cost: widget.signature.data.cost,
    );
    return _EvolutionRow(
      evolution: evolution,
      description: taken > 0
          ? l10n.evolutionBoardLevelUp(taken, taken + 1, description)
          : description,
      accent: classColor,
      selected: evolution.id == _selected?.id,
      onTap: () => _select(evolution),
    );
  }

  /// La ligne d'une évolution qu'on ne peut pas prendre maintenant : son texte
  /// à son niveau actuel, ou au premier si elle n'est pas prise.
  Widget _lockedRow(
    AppLocalizations l10n,
    SignatureEvolutionData evolution,
    Color classColor, {
    String? tag,
  }) {
    final taken = _takenLevel(evolution);
    return _EvolutionRow(
      evolution: evolution,
      description: evolution.getDescription(
        taken > 0 ? taken : 1,
        l10n.localeName,
        cost: widget.signature.data.cost,
      ),
      accent: classColor,
      tag: tag,
    );
  }

  /// Le pool, section par section : ce qu'on peut prendre d'abord.
  List<Widget> _pool(
    AppLocalizations l10n,
    SignatureEvolutionBoard board,
    Color classColor,
  ) {
    final locale = l10n.localeName;
    final upcomingMinors = widget.signature.nextTier == EvolutionTier.major;
    return [
      _SectionTitle(l10n.evolutionBoardToChoose, color: classColor),
      for (final evolution in board.choices)
        _choiceRow(l10n, evolution, classColor),
      if (board.upcoming.isNotEmpty) ...[
        _SectionTitle(
          upcomingMinors
              ? l10n.evolutionBoardUpcomingMinors(board.upcomingHeroLevel)
              : l10n.evolutionBoardUpcomingMajors(board.upcomingHeroLevel),
        ),
        for (final evolution in board.upcoming)
          _lockedRow(
            l10n,
            evolution,
            classColor,
            tag: _takenLevel(evolution) > 0
                ? l10n.evolutionBoardTakenLevel(_takenLevel(evolution))
                : null,
          ),
      ],
      if (board.takenMajors.isNotEmpty) ...[
        _SectionTitle(l10n.evolutionBoardTaken),
        for (final evolution in board.takenMajors)
          _lockedRow(l10n, evolution, classColor),
      ],
      if (board.excluded.isNotEmpty) ...[
        _SectionTitle(l10n.evolutionBoardExcluded),
        for (final (evolution, by) in board.excluded)
          _lockedRow(
            l10n,
            evolution,
            classColor,
            tag: l10n.evolutionBoardExcludedBy(by.getName(locale)),
          ),
      ],
    ];
  }

  Widget _confirmButton(AppLocalizations l10n, Color classColor) {
    final selected = _selected;
    return GameButton(
      text: selected == null
          ? l10n.evolutionBoardPick
          : l10n.evolutionBoardTake(selected.getName(l10n.localeName)),
      baseColor: classColor,
      width: double.infinity,
      onPressed: selected == null ? null : () => _confirm(selected),
    );
  }

  /// Large : la fiche et le bouton à gauche, le pool à droite.
  Widget _wide(
    AppLocalizations l10n,
    SignatureEvolutionBoard board,
    SignatureInstance preview,
    int heroLevel,
    Color classColor,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.lg,
          children: [
            SizedBox(
              width: 330,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionTitle(
                    _selected == null
                        ? l10n.evolutionBoardToday
                        : l10n.evolutionBoardAfter,
                    color: Colors.amberAccent,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SignatureRunCard(
                        signature: preview,
                        heroLevel: heroLevel,
                        classColor: classColor,
                      ),
                    ),
                  ),
                  AppSpacing.heightSm,
                  _confirmButton(l10n, classColor),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: _pool(l10n, board, classColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Téléphone : la fiche ne tient pas. Le pool défile, et le coût et la
  /// recharge d'après le choix restent visibles au-dessus du bouton.
  Widget _narrow(
    AppLocalizations l10n,
    SignatureEvolutionBoard board,
    SignatureInstance preview,
    Color classColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: _pool(l10n, board, classColor),
          ),
        ),
        AppSpacing.heightSm,
        Text(
          l10n.signatureCostAndCooldown(preview.cost, preview.cooldown),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.amberAccent, fontSize: 12),
        ),
        AppSpacing.heightSm,
        _confirmButton(l10n, classColor),
      ],
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

    final signature = widget.signature;
    final board = SignatureEvolutionRules.board(signature);
    final selected = _selected;
    final preview = selected == null
        ? signature
        : SignatureEvolutionRules.take(signature, selected.id) ?? signature;
    final tierLevel = signature.nextEvolutionHeroLevel;

    return ScreenScaffold(
      backgroundType: ScreenBackgroundType.dark,
      appBar: PageHeader(
        title: l10n.evolutionScreenTitle(
          signature.data.getName(l10n.localeName),
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
            Text(
              signature.nextTier == EvolutionTier.major
                  ? l10n.evolutionBoardTierMajor(tierLevel)
                  : l10n.evolutionBoardTierMinor(tierLevel),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            AppSpacing.heightSm,
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 600
                    ? _narrow(l10n, board, preview, classColor)
                    : _wide(
                        l10n,
                        board,
                        preview,
                        runState.heroStats.level,
                        classColor,
                      ),
              ),
            ),
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
