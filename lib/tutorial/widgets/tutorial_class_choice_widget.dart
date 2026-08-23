import 'package:flutter/material.dart';

import '../../models/data/hero_data.dart';
import '../tutorial_engine.dart';

/// Étape 02 — choix de classe.
///
/// Les trois héros, leurs points de vie et leur passif viennent de
/// `heroes.json` et `passives.json` : aucune valeur n'est écrite ici.
class TutorialClassChoiceWidget extends StatefulWidget {
  final TutorialEngine engine;

  const TutorialClassChoiceWidget({super.key, required this.engine});

  @override
  State<TutorialClassChoiceWidget> createState() =>
      _TutorialClassChoiceWidgetState();
}

class _TutorialClassChoiceWidgetState extends State<TutorialClassChoiceWidget> {
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
            isFrench ? 'Choisissez votre classe' : 'Choose your class',
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
    final passive = widget.engine.fixtures.passiveFor(hero);

    return InkWell(
      onTap: () {
        widget.engine.chooseHero(hero);
        setState(() {});
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
            Text(
              passive.getName(locale),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              passive.getDescription(locale),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
