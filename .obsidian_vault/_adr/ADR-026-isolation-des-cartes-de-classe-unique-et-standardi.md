## 🃏 ADR-026 : Isolation des Cartes de Classe "Unique" et Standardisation du Draft Initial (Class Card Isolation & Starter Draft Overhaul)

### Statut
✅ Accepté & Implémenté

### Contexte
Les cartes de classe initiales (`holy_shield`, `smite`, `reckless_strike`, `rage_form`, `magic_missile`, `mana_surge`) étaient mélangées dans `cards.json` avec les cartes neutres globales. Ce couplage nuisait à l'identité stratégique de chaque héros, car les cartes spécifiques apparaissaient de manière confuse dans les tables d'acquisition ou de boutique, et les mécaniques de fusions n'étaient pas adaptées à des sorts de classe intrinsèques. De plus, l'écran `StarterDeckDraftScreen` original reposait sur une sélection aléatoire par vagues de 3 cartes qui nuisait à l'arbitrage tactique initial du joueur.

### Décision
1. **Séparation des JSON de cartes** : Extraire toutes les cartes spécifiques de classe de `cards.json` vers `assets/data/hero_cards.json`.
2. **Introduction de la Rareté `unique`** : Créer le type de rareté `unique` dans l'enum `CardRarity`. Les cartes uniques possèdent une valeur de multiplicateur fixe à `1.0` (définie dans `card_instance.dart`) et une limite de forge `baseMaxForgeUpgrades` bloquée à 5.
3. **Verrouillage Métier de la Fusion & Obtention** : Empêcher explicitement la fusion de cartes de rareté `unique` en désactivant le bouton correspondant dans l'UI et en levant une erreur dans `deck_controller.dart`. Filtrer également ces cartes pour qu'elles ne soient jamais proposées en boutique ou en draft après un combat.
4. **Liaison Dynamique Héros-Skills** : Structurer `heroes.json` avec l'intégration du champ `"skills"` qui contient les identifiants de cartes de départ uniques. Implémenter l'extension `HeroSkillsLink` et sa méthode `getHeroCards(gameData)` pour charger dynamiquement ces cartes basées sur les compétences du héros.
5. **Standardisation Globale & VPM** : Passer toutes les cartes globales de `cards.json` à la rareté `common`. Rééquilibrer leurs statistiques fondamentales pour les stabiliser autour de ratios de Valeur Par Mana (VPM) justes et équitables (ex: `heal_potion` coût 1, heal 4, exhaust; `iron_wall` coût 2, 10 block; `heavy_strike` coût 2, 12 dmg).
6. **Refonte et Stabilisation de l'écran `StarterDeckDraftScreen`** : Remplacer l'ancien système de draft par vagues par une grille affichant l'intégralité du catalogue des 15 cartes globales. Le joueur sélectionne de manière totalement libre exactement 5 cartes globales de départ parmi le pool complet (la logique intermédiaire consistant à restreindre le choix à un sous-ensemble aléatoire de 10 cartes a été complètement supprimée). Les cartes de classe uniques obtenues via `getHeroCards()` sont ajoutées automatiquement au deck initial. Les descriptions de localisation `draftDeckSubtitle` ont été révisées et corrigées en français/anglais, et les importations et méthodes mathématiques inutilisées (`dart:math` et `_rollRarity`) ont été supprimées.

### Preuves dans le code
- Fichier `assets/data/hero_cards.json` contenant les 6 cartes spécifiques.
- Fichier `assets/data/cards.json` contenant les 15 cartes globales rééquilibrées.
- Enum `CardRarity` étendu avec `unique`.
- Code de validation de merge dans `deck_controller.dart` qui rejette les cartes `unique`.
- Méthode `HeroSkillsLink.getHeroCards(gameData)` dans `lib/models/data/hero_data.dart` (ou extension équivalente).
- Grille de sélection interactive et validation de la taille de sélection (exactement 5) dans `StarterDeckDraftScreen`.
- Fichiers `app_en.arb` et `app_fr.arb` modifiant la clé `draftDeckSubtitle` pour supprimer l'ancienne mention d'une sélection "parmi les 10 proposées".
- Nettoyage du code de `starter_deck_draft_screen.dart` avec retrait des fonctions probabilistes inutilisées.
- Validation de la suite complète de 78 tests automatisés après mise à jour des mocks de tests unitaires/widgets pour s'adapter à la grille globale étendue.

### Conséquences
- ✅ **Renforcement de l'identité des Héros** : Chaque classe démarre avec des compétences fortes, stables et caractéristiques qui ne diluent pas son identité au fil des fusions.
- ✅ **Pouvoir de Décision Initial accru** : Le joueur compose consciemment sa stratégie de départ parmi les cartes globales sans subir l'aléa du tirage.
- ✅ **Coût de Maintenance Réduit** : La distinction nette entre le pool global et le pool de classe facilite l'implémentation de futurs héros et cartes sans perturber le système d'acquisition général.
- ⚠️ **Évolution Statique de Classe** : N'étant pas fusionnables, les cartes uniques de classe ne s'améliorent que via les slots probabilistes de la Forge, accentuant l'importance stratégique des feux de camp.
- ✅ **Vérification Intègre & Cohérence** : Tous les 78 tests automatisés passent avec succès, et le linter est vierge sous `dart analyze`. Les descriptions de l'interface et les comportements du code sont en parfaite adéquation.
