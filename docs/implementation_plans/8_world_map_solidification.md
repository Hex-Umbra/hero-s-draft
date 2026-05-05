# Plan d'Implémentation 8 : World Map et Solidification Technique

Ce document détaille le plan pour implémenter la Section 3 de l'analyse technique des évolutions futures (`docs/possible_upgrades/2_analyse_techniques_evols.md`). L'objectif est de structurer la progression du joueur via une carte du monde et de garantir la robustesse du code par des tests et du polissage technique.

## Phase 1 : World Map (Navigation Procédurale)

Remplacer la progression linéaire automatique par un système de choix de chemin.

### 1.1 Modélisation de la Carte
- Créer `lib/models/map_node.dart` :
  - `id` (String).
  - `type` (Enum: combat, elite, shop, rest, event).
  - `connections` (List<String> IDs des nœuds suivants).
  - `position` (Vector2 pour l'affichage).
- Créer un service de génération `lib/services/map_generator.service.dart` pour créer un graphe acyclique dirigé (DAG).

### 1.2 Interface World Map
- Créer `lib/ui/screens/map_screen.dart` :
  - Utiliser un `SingleChildScrollView` ou un `InteractiveViewer`.
  - Dessiner les nœuds et les lignes de connexion via un `CustomPainter`.
  - Intégrer la logique de navigation : le joueur ne peut cliquer que sur les nœuds connectés à son nœud actuel.

### 1.3 Intégration du Flux de Jeu
- Modifier `GameScreen` pour qu'il soit appelé depuis `MapScreen`.
- À la fin d'un combat (après le draft), au lieu de passer au niveau suivant, revenir à `MapScreen` en marquant le nœud actuel comme "complété".

---

## Phase 2 : Système d'Or et Boutique

Donner une utilité aux récompenses de combat.

### 2.1 Économie (RunController)
- Ajouter `int gold` au `RunState`.
- Implémenter des méthodes `gainGold(int amount)` et `spendGold(int amount)`.
- Récompenser le joueur en or à la fin de chaque combat.

### 2.2 Boutique (ShopScreen)
- Créer `lib/ui/screens/shop_screen.dart`.
- Afficher une sélection aléatoire de cartes (utilisant `GameDataService`).
- Permettre l'achat de cartes, de soins ou de retrait de cartes du deck (épuration).

---

## Phase 3 : Solidification et Robustesse

Garantir que les nouvelles mécaniques fonctionnent comme prévu.

### 3.1 Tests Automatisés
- **Tests Unitaires** (`test/unit/`) :
  - `effect_resolver_test.dart` : Tester les nouveaux types d'effets (poison, buff, etc.).
  - `map_generator_test.dart` : Vérifier que le graphe généré est valide (pas d'impasse, pas de cycles).
- **Tests de Widget** (`test/widget/`) :
  - Vérifier que les boutons de la World Map sont activés/désactivés correctement.

### 3.2 Internationalisation (i18n)
- Configurer `flutter_localizations`.
- Créer les fichiers `.arb` pour le français et l'anglais.
- Extraire toutes les chaînes "hardcodées" des écrans Flutter et des JSON de données.

---

## Phase 4 : Optimisation et Polissage Final

### 4.1 Sprite Sheets
- Regrouper les images individuelles en Sprite Sheets pour améliorer les performances de Flame.
- Utiliser Flame's `SpriteAnimation` pour les animations de repos des personnages.

### 4.2 Équilibrage (Data-Driven)
- Ajuster les valeurs dans `enemies.json` et `cards.json` en fonction des retours de test.
- Équilibrer le coût des cartes de type "Power" par rapport à leur impact sur le long terme.

---

## Phase 5 : Validation Finale

- Parcourir une run complète du début à la fin (Boss Final).
- Vérifier la persistence de l'état entre les écrans Combat -> Map -> Shop.
- Lancer `dart analyze` et corriger tous les avertissements.
