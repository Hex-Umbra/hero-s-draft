import 'package:flutter/material.dart';

import '../../models/data/hero_data.dart';
import '../../ui/widgets/class_identity.dart';
import '../../ui/widgets/class_passive_list.dart';
import '../tutorial_engine.dart';

/// Étape 02 — choix de classe, **et de son passif**.
///
/// Les trois héros, leurs points de vie et les passifs qu'ils ouvrent
/// viennent de `assets/data/classes/<id>/class.json` et
/// `assets/data/passives/`, par le point d'accès unique de P-49 : aucune
/// valeur n'est écrite ici, et aucun identifiant de classe n'est comparé
/// (ADR-090).
///
/// Le bloc des passifs est **celui de l'écran de sélection**
/// (`ClassPassiveList`), et non une seconde implémentation : c'est le remède
/// que demande le §1.4 de la spec. Repliée, chaque carte montre le passif
/// avec lequel la run partirait ; la carte choisie est dépliée et ses tuiles
/// sont cliquables.
class TutorialClassChoiceWidget extends StatefulWidget {
  final TutorialEngine engine;

  const TutorialClassChoiceWidget({super.key, required this.engine});

  @override
  State<TutorialClassChoiceWidget> createState() =>
      _TutorialClassChoiceWidgetState();
}

class _TutorialClassChoiceWidgetState extends State<TutorialClassChoiceWidget> {
  // Vaut pour la carte choisie seulement : une carte non choisie est
  // toujours repliee, quel que soit ce booleen (`isExpanded: isSelected &&
  // _deplie`). Une seule carte a la fois peut donc etre depliee, sans qu'il
  // faille savoir laquelle ici.
  bool _deplie = false;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isFrench = locale == 'fr';
    final heroes = widget.engine.fixtures.heroes;
    final chosenId = widget.engine.mockState.chosenHero?.id;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            isFrench
                ? 'Choisissez votre classe, puis son passif'
                : 'Choose your class, then its passive',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 12,
                runSpacing: 12,
                children: heroes
                    .map((hero) => _buildHeroCard(hero, locale, chosenId == hero.id))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(HeroData hero, String locale, bool isSelected) {
    final passives = widget.engine.fixtures.passivesFor(hero);
    final activeId = widget.engine.mockState.activePassive?.id;
    // Le rang du passif retenu dans *cette* liste. Une carte non choisie
    // montre donc toujours son propre premier passif, jamais celui d'une
    // autre classe : `indexWhere` rend -1, ramené à 0.
    final rank = isSelected ? passives.indexWhere((p) => p.id == activeId) : -1;
    final selectedIndex = rank < 0 ? 0 : rank;

    return InkWell(
      onTap: () {
        if (isSelected) {
          // Retaper la carte deja choisie (le nom, les PV, le badge
          // « Passifs »...) ne doit jamais rappeler `chooseHero`, qui
          // reecrit `activePassive` sur le premier passif de la classe et
          // perd le choix du joueur. Le tap replie ou deplie a la place —
          // le geste que le badge « Passifs » promet par son chevron.
          setState(() => _deplie = !_deplie);
        } else {
          widget.engine.chooseHero(hero);
          setState(() => _deplie = true);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hero.getName(locale),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${hero.maxHp} ${locale == 'fr' ? 'PV' : 'HP'}',
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            Text(
              '${hero.maxMana} Mana',
              style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
            ),
            const Divider(color: Colors.white12, height: 18),
            if (passives.isNotEmpty)
              ClassPassiveList(
                passives: passives,
                selectedIndex: selectedIndex,
                classMastery: hero.mastery,
                // Seule la classe choisie peut être dépliée, et seulement
                // si le joueur ne l'a pas repliée depuis : une seule carte
                // à la fois, comme à l'écran de sélection, mais ici le
                // dépliage se retape (`_deplie`) puisqu'un retap sur la
                // carte choisie ne peut plus rappeler `chooseHero`.
                isExpanded: isSelected && _deplie,
                // La carte du tutoriel fait 190 px : c'est la mise en page
                // compacte qu'il lui faut, quelle que soit la taille de
                // l'écran.
                isMobile: true,
                locale: locale,
                classColor: ClassIdentity.colorOf(hero),
                onSelect: (i) {
                  widget.engine.choosePassive(passives[i]);
                  setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}
