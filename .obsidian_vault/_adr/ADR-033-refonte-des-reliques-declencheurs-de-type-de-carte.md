## 🎒 ADR-033 : Refonte des Reliques, Déclencheurs de Type de Carte et Système de Charges (Relic Overhaul, Card-Type Triggers & Charge Systems)

### Statut
✅ Accepté & Implémenté

### Contexte
La version 0.0.94 de Hero's Draft comportait un ensemble de 14 reliques, ce qui déséquilibrait le pool en sous-représentant les reliques communes (seulement 1 relique commune, le Talisman de Fer, par rapport aux nombreuses reliques atypiques, rares ou épiques). De plus, les déclencheurs de reliques étaient limités à des phases globales de combat ou au fait de jouer n'importe quelle carte (`onCardPlayed`), ne permettant pas de concevoir des reliques favorisant des archétypes de deck spécifiques (tels que des decks centrés sur les attaques ou les compétences). Enfin, le jeu manquait de reliques actives ou à compteurs de charges (inspirées des classiques de type *Slay the Spire* comme Kunaï, Shuriken, Pen Nib ou Encensoir), qui récompensent l'accumulation d'actions au fil des tours ou du combat.

### Décision
1. **Équilibrage et Extension du Pool de Reliques** :
   - Ajouter 10 nouvelles reliques dans `relics.json`, portant le total à 24 reliques.
   - Introduire 4 nouvelles reliques Communes pour rééquilibrer le tirage en début de partie : *Pierre à aiguiser* (Whetstone, +1 Force), *Bottes en cuir* (Leather Boots, +3 Armure au combat), *Pièce de chance* (Lucky Coin, +5% Critique permanent), et *Bandage de voyage* (Travel Bandage, Soin 1 PV à la fin du tour).
   - Introduire *Plume de scribe* (Pen Nib, atypique) et *Couronne des Rois* (Crown of Kings, légendaire).
   - Introduire 4 nouvelles reliques Rares basées sur des compteurs de charges : *Croc Kunaï* (Kunai), *Shuriken*, et *Encensoir* (Incense Burner).
2. **Gestion du Mana Permanent et de Combat** :
   - Implémenter le gain de Mana max permanent pour toute la run via l'effet `gain_mana` associé au trigger `startOfRun` de la *Couronne des Rois* dans `RunController.applyRelics` (incrémente `state.maxMana` de manière durable).
   - Implémenter le gain de Mana de combat via la *Plume de Phénix* (trigger `startOfCombat` avec l'effet `gain_mana`) en ajoutant la valeur de la relique à la réserve de mana de départ du joueur.
3. **Déclencheurs par Type de Carte Spécifique** :
   - Ajouter les valeurs `onAttackPlayed`, `onSkillPlayed` et `onPowerPlayed` à l'énumération `RelicTrigger`.
   - Dans `CombatController.applyPlayerCardPlay`, après avoir déclenché `onCardPlayed`, évaluer le type de la carte jouée (`card.type`) :
     - Si `CardType.attack` : propager `RelicTrigger.onAttackPlayed`.
     - Si `CardType.skill` : propager `RelicTrigger.onSkillPlayed`.
     - Si `CardType.power` : propager `RelicTrigger.onPowerPlayed`.
4. **Système de Charges et Compteurs via Statuts Empilables** :
   - Utiliser la liste existante des statuts (`EntityStats.statuses`) pour stocker et incrémenter visuellement les compteurs sous forme de `StatusEffect` spécifiques attachés au Héros.
   - Les charges possèdent un indicateur textuel et une icône correspondante dans le panneau des effets de statut du HUD de combat, garantissant un retour visuel direct.
   - Dans `RunController.applyRelicEffect`, gérer la logique de charge :
     - **Kunaï** (`kunai`) & **Shuriken** (`shuriken`) : Utilise des charges à durée de 1 tour (`kunai_charge`, `shuriken_charge`). À chaque attaque jouée, la charge s'incrémente. Si elle atteint 3, les charges sont supprimées et le bonus permanent (+1 Maîtrise d'Armure pour Kunaï, +1 Force de combat pour Shuriken) est appliqué. Si le tour se termine avant d'atteindre 3 charges, le tick de début de tour décrémente et détruit automatiquement les charges non-résolues.
     - **Plume de scribe** (`pen_nib`) : Utilise des charges persistantes d'un tour à l'autre (`pen_nib_charge` avec une durée de 99). À chaque carte jouée, la charge s'incrémente. À 5 charges, reset et confère +3 Force temporaire (durée de 1 tour).
     - **Encensoir** (`incense_burner`) : Utilise des charges persistantes (`incense_charge` de durée 99) incrémentées au début de chaque tour. À 4 charges, reset et confère +8 Armure.
5. **Persistance de l'Armure et Synergies** :
   - Le jeu conservant l'Armure d'un tour à l'autre (l'Armure ne decay pas en fin de tour dans Hero's Draft), la Maîtrise d'Armure conférée par le Kunaï et l'armure brute de l'Encensoir s'avèrent particulièrement puissantes pour les builds défensifs.
6. **Statistiques Permanentes de Run vs Buffs de Combat** :
   - Afin de rationaliser les effets agissant sur les statistiques du joueur (Force/Attaque, Chances de Critique), les reliques d'ajustement de statistiques fixes de début de combat (comme *Pierre à aiguiser*, *Lame Maudite*, *Lentille de Focalisation*) ont été converties pour agir à l'échelle de toute la run (déclencheur `startOfRun`). Cela permet à ces bonus de modifier directement et de manière permanente la fiche de personnage globale plutôt que de polluer le panneau des statuts de combat sous forme de buffs de 99 tours. Les gains d'Armure et de Mana au combat (ressources éphémères) conservent leur déclencheur `startOfCombat`.
7. **Mise à jour du Dictionnaire de Reliques (bilingue)** :
   - Adapter `DictionaryScreen` (`card_dictionary_screen.dart`) pour mapper et traduire les nouveaux types de déclencheurs (`onAttackPlayed` → "At Play (Attack)" / "Jouer (Attaque)", etc.) sous forme de badges de couleurs spécifiques.

### Preuves dans le code
- `assets/data/relics.json` : Modifié pour intégrer les 10 nouvelles reliques et corriger les identifiants techniques et triggers.
- `lib/models/data/relic_data.dart` : Ajout des enums et valeurs de triggers `onAttackPlayed`, `onSkillPlayed`, `onPowerPlayed` dans `RelicTrigger`.
- `lib/game/controllers/combat_controller.dart` : Propagation des événements de type de carte dans `applyPlayerCardPlay` (lignes 215-221).
- `lib/game/controllers/run_controller.dart` : Implémentation du switch de charges dans `applyRelicEffect` (lignes ~369-482), gestion de la suppression des statuts de charge lors de l'application de l'effet, et prise en charge du gain de Mana max permanent dans `addRelic`.
- `lib/ui/screens/card_dictionary_screen.dart` : Ajout des libellés bilingues et styles de badges de trigger.
- Validation statique vierge sous `dart analyze` et passage des 100 tests unitaires et widget-tests de la suite de tests.

### Conséquences
- ✅ **Profondeur Stratégique Accrue** : Les joueurs peuvent désormais bâtir des synergies spécialisées autour de decks fortement agressifs (Shuriken/Kunaï) ou de la tempo (Encensoir, Plume de Scribe).
- ✅ **Clarté Visuelle Maximale** : L'utilisation de `StatusEffect` pour afficher les compteurs de charges réutilise l'infrastructure existante du HUD tout en offrant une rétroaction instantanée sans surcharge visuelle.
- ✅ **Équilibrage de Rareté Réussi** : Le pool de reliques communes passe de 1 à 5, diminuant la frustration liée aux tirages de reliques d'entrée de jeu.
- ✅ **Architecture Découplée et Propre** : Les calculs de charges et d'effets se font intégralement côté contrôleurs Riverpod, préservant l'isolation de la couche Flame et de l'interface graphique.
