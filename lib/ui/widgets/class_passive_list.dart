import 'package:flutter/material.dart';
import 'package:roguelike_card_game/l10n/app_localizations.dart';
import '../../models/data/passive_data.dart';

/// Le bloc dépliant des passifs, au bas d'une carte de classe.
///
/// Replié, il montre en entier le passif avec lequel la run partirait — nom,
/// effet et ce qu'un point de Maîtrise lui apporte — pour que le joueur
/// compare les trois classes sans rien ouvrir. Déplier ajoute les autres
/// passifs disponibles pour la classe (point d'accès unique de P-49). Dans
/// les deux cas, l'étiquette « Passifs » ferme le bloc.
///
/// Il ne décide pas de son propre dépliage : c'est la carte qui le lui dit,
/// parce qu'une seule carte à la fois peut être ouverte.
class ClassPassiveList extends StatelessWidget {
  final List<PassiveData> passives;

  /// Le rang du passif retenu dans `passives`.
  final int selectedIndex;

  /// La Maîtrise avec laquelle la classe démarre — 0 pour deux des trois
  /// classes livrées, ce que la ligne de Maîtrise dit en toutes lettres.
  final int classMastery;

  final bool isExpanded;
  final bool isMobile;
  final String locale;
  final Color classColor;
  final ValueChanged<int> onSelect;

  const ClassPassiveList({
    super.key,
    required this.passives,
    required this.selectedIndex,
    required this.classMastery,
    required this.isExpanded,
    required this.isMobile,
    required this.locale,
    required this.classColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // L'écart sous le bouton, posé ici et non par la carte : le bloc
        // tient tous ses espacements, faute de quoi ils divergent. Ils
        // valaient 8px décidés par la carte plus 4px de padding sur la
        // tuile, contre 6px avant le badge — 12 contre 6, mesuré.
        SizedBox(height: _gap),
        // Repliée, la carte montre quand même le passif retenu en entier :
        // le joueur sait avec quoi il partirait sans avoir à déplier.
        // Déplier n'ajoute que les autres.
        //
        // `AnimatedSize` fait grandir la carte au lieu de la faire sauter :
        // sans lui, l'écran a l'air de s'être reconstruit plutôt que la
        // carte de s'être ouverte. Il ne mesure que ce bloc-ci, pas la
        // carte entière, donc rien d'autre n'est animé au passage.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isExpanded)
                for (var i = 0; i < passives.length; i++) ...[
                  if (i > 0) SizedBox(height: _gap),
                  _buildOption(i, l10n),
                ]
              else
                _buildOption(selectedIndex, l10n),
            ],
          ),
        ),
        // L'étiquette ferme le bloc, elle ne l'ouvre pas : le passif retenu
        // est ce que le joueur vient lire, l'étiquette est l'invitation à
        // en voir davantage.
        SizedBox(height: _gap),
        // Un badge, et non du texte nu : posée à même le fond, l'étiquette
        // flottait sans appartenir à rien. La pastille reprend la forme des
        // badges de stats du haut de la carte et la teinte de la classe —
        // c'était le seul élément de la carte à rester cyan quelle que soit
        // la classe, ce qui suffisait à le détacher du reste.
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: classColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: classColor.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    // Elle ne nomme pas le passif : la tuile au-dessus le
                    // fait déjà, repliée comme dépliée.
                    l10n.passivesLabel,
                    style: TextStyle(
                      fontSize: _labelFontSize,
                      fontWeight: FontWeight.w600,
                      color: classColor,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: isMobile ? 3 : 4),
                // Une seule icône qui pivote, plutôt que deux glyphes
                // échangés : le chevron accompagne le dépliage au lieu de
                // sauter d'un état à l'autre.
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.expand_more,
                    // Le chevron suit la taille du texte : c'est la même
                    // affordance, les désaccorder la casserait en deux.
                    size: _labelFontSize + 3,
                    color: classColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// L'écart entre chaque élément du bloc : sous le bouton, entre deux
  /// tuiles, et avant le badge. Une seule valeur, pour que les trois
  /// espaces se vaillent.
  double get _gap => isMobile ? 6 : 8;

  /// La taille de l'étiquette « Passifs ».
  ///
  /// Doublée par rapport au reste du bloc, puis réduite d'un tiers (deux
  /// demandes successives du propriétaire) : elle reste l'élément le plus
  /// lisible du bloc sans redevenir un titre.
  double get _labelFontSize => isMobile ? 14 : 15.5;

  Widget _buildOption(int i, AppLocalizations l10n) {
    final passive = passives[i];
    final bool selected = i == selectedIndex;
    final mastery = passive.mastery;

    return InkWell(
        // Repliée, la tuile est un affichage et non un choix — le seul
        // passif montré est déjà le retenu. Sans geste à elle, le tap
        // traverse jusqu'à la carte, qui se déplie : taper le passif
        // qu'on voit fait donc apparaître les autres.
        onTap: isExpanded ? () => onSelect(i) : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          // La ligne entière porte le geste, et jamais moins que la cible
          // tactile de Material : l'ancienne puce du sélecteur, haute d'une
          // trentaine de pixels, ne la tenait pas.
          constraints: const BoxConstraints(minHeight: 48),
          padding: EdgeInsets.all(isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: selected
                ? classColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            // Largeur constante, seule la couleur change : une bordure qui
            // s'épaissit à la sélection remesurerait la ligne à chaque tap,
            // et la rangée desktop entière avec elle.
            border: Border.all(
              color: selected ? classColor : Colors.white24,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: isMobile ? 16 : 18,
                color: selected ? classColor : Colors.white38,
              ),
              SizedBox(width: isMobile ? 6 : 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passive.getName(locale),
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passive.getDescription(locale),
                      style: TextStyle(
                        fontSize: isMobile ? 9.5 : 10.5,
                        color: Colors.white70,
                        height: 1.25,
                      ),
                    ),
                    if (mastery != null) ...[
                      const SizedBox(height: 3),
                      // La valeur de départ de la classe accompagne
                      // l'effet : deux classes sur trois démarrent à 0 et
                      // pouvaient croire l'effet actif. Il reste écrit
                      // parce qu'elles peuvent gagner de la Maîtrise en
                      // cours de run (récompense « Affinité »).
                      Text(
                        l10n.passiveMasteryAtStart(
                          classMastery,
                          mastery.describe(locale, 1),
                        ),
                        style: TextStyle(
                          fontSize: isMobile ? 9 : 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.cyanAccent.withValues(alpha: 0.75),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}
