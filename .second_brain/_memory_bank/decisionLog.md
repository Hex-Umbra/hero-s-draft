# 📋 Registre des Décisions Architecturales (Decision Log)

Ce document répertorie sous forme d'**ADR (Architecture Decision Records)** les choix de conception structurants qui pilotent le développement et l'évolution technique de **Hero's Draft**.

---

## 🏛️ ADR 1 : Séparation stricte État/Rendu (Riverpod ⇄ Flame)

### Statut
Accepté & Implémenté

### Contexte
Dans les jeux intégrant des moteurs de rendu interactifs comme Flame, il est fréquent que la logique métier (calcul de dégâts, cycle de vie du deck, debuffs, cooldowns) se retrouve mélangée au code de dessin ou de gestion des animations (`PositionComponent`). Cela rend le code instable, rend les tests automatisés impossibles sans instancier le moteur graphique, et augmente le risque de désynchronisations.

### Décision
- Exclure toute logique métier ou de calcul de dégâts du moteur Flame.
- Centraliser l'état global et les statistiques au sein de contrôleurs **Riverpod** purs (`RunController`, `DeckNotifier`, `CombatController`).
- Rendre la boucle Flame réactive : elle observe passivement l'état Riverpod à chaque frame (`syncState`, `syncCombat`, `syncDeck` dans `HerosDraftGame.update()`) et s'aligne visuellement par diffing.
- Limiter les interactions physiques Flame à des déclenchements de callbacks Riverpod (`onPlayCard`, `onSelectEnemy`, etc.).

### Conséquences
- **Positives** : Possibilité de tester 100% de la logique de combat, de pioche, de fusion et d'effet via des tests unitaires standard ultra-rapides (58 tests au vert).
- **Positives** : Éradication des bugs de désynchronisation entre l'affichage graphique et les vraies valeurs logiques de vie ou de mana.
- **Négatives** : Nécessite une rigueur de synchronisation asynchrone (tampons d'état) dans le `update` Flame pour éviter des sauts visuels brusques.

---

## 📐 ADR 2 : Système de Responsivité Dynamique et Homogénéisation des Échelles

### Statut
Accepté & Implémenté

### Contexte
Le jeu est conçu pour être déployé sur divers supports : smartphones étroits, tablettes, et moniteurs PC 4K. Flame utilise un canvas absolu par défaut, ce qui peut tronquer l'affichage des cartes en main ou des monstres sur les écrans hors-normes.

### Décision
- Implémenter une formule de mise à l'échelle dynamique (scaling) basée sur la hauteur réelle du viewport de l'application :
  ```dart
  double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);
  ```
- Dimensionner et repositionner l'ensemble des composants graphiques (taille des cartes physiques `140x196`, espacements des ennemis, courbes d'arc de la main du joueur) proportionnellement à ce coefficient.

### Conséquences
- **Positives** : Parfaite adaptabilité visuelle du jeu du mobile jusqu'à l'écran PC 4K, sans rupture de mise en page.
- **Positives** : Préservation du "Game Feel" organique et de l'alignement des éléments de l'arène.
- **Négatives** : Contrainte d'incorporer le multiplicateur `scaleFactor` sur toutes les dimensions codées en dur, augmentant le risque d'oublis lors de l'intégration de nouveaux éléments.

---

## 🌐 ADR 3 : Rénovation de la Localisation et Architecture 100% Data-Driven

### Statut
Accepté & Implémenté (Récemment achevé)

### Contexte
La version initiale comportait de nombreuses chaînes de caractères codées en dur dans les widgets Flutter (en français) et des variables d'état locales `isFr` pour commuter manuellement les traductions. De même, les fichiers JSON d'assets (cartes, reliques) contenaient des chaînes françaises figées, empêchant toute traduction propre et polluant la logique de jeu.

### Décision
- Éradiquer toutes les variables locales `isFr` et conditions manuelles.
- Migrer la totalité du contenu textuel de l'UI Flutter vers des fichiers ARB compilés (`app_en.arb`, `app_fr.arb`) exploités via `AppLocalizations`.
- Rendre les modèles de données (`CardData`, `HeroData`, `EnemyData`) asynchrones et dotés de double-champs multilingues (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`).
- Nettoyer les statuts de combat pour ne faire transiter dans la logique Flame et Riverpod que des identifiants techniques neutres (ex : `poison`, `weakness`), l'UI se chargeant de la traduction à la volée via `StatusEffectsPanel`.

### Conséquences
- **Positives** : Élimination complète de la dette technique de traduction (100% i18n conforme, `flutter analyze` vierge).
- **Positives** : Ouverture facile vers de nouvelles langues (espagnol, allemand, etc.) simplement en complétant les JSON de données et les fichiers ARB, sans altérer le code.
- **Positives** : Modularité absolue pour le modding (changement des valeurs ou équilibrage des JSON pris en compte instantanément).

---

## 🃏 ADR 4 : Unification et Déduplication du Rendu de Cartes (Widget `UiCard`)

### Statut
Accepté & Implémenté

### Contexte
La représentation graphique des cartes était dupliquée et implémentée séparément dans 6 fichiers d'écrans différents (`ShopScreen`, `DraftScreen`, `StarterDeckDraftScreen`, etc.). Toute modification du design des cartes (couleur des raretés, taille des polices, affichage du mana) exigeait de modifier 6 fichiers en parallèle, représentant un risque élevé de régression visuelle.

### Décision
- Concevoir un widget Flutter générique et configurable nommé `UiCard` dans `lib/ui/widgets/ui_card.dart`.
- Ce widget calcule automatiquement les descriptions cumulées et mises à l'échelle du niveau de la carte (`_buildDescription()`) et encapsule la totalité des styles graphiques (dégradés, ombres, contours colorés selon la rareté, icônes internes vectorielles de type).
- Remplacer toutes les implémentations inline de rendu de cartes dans les 5 écrans UI par une instanciation de `UiCard`.

### Conséquences
- **Positives** : Cohérence graphique absolue sur l'ensemble de l'interface utilisateur.
- **Positives** : Éradication de plusieurs centaines de lignes de code redondant (Dette Technique résorbée).
- **Positives** : Maintenance simplifiée à un seul fichier source en cas de refonte graphique du design des cartes.
