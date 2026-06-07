# Rapport d'Analyse du Codebase : Cohérence UI, Moteur de Jeu Flame & Architecture Riverpod

Ce rapport d'analyse synthétise les audits menés par notre équipe de sous-agents spécialisés sur l'application **Hero's Draft**. L'objectif est d'évaluer la cohérence de l'interface, la propreté du code Flame/Riverpod, et d'identifier les chantiers de refactorisation prioritaires pour améliorer la maintenance et la scalabilité du projet.

---

## 1. Uniformisation et Cohérence de l'Interface Utilisateur (UI Flutter)

### A. Espacements, Paddings et Alignements (Layout)
* **Constat** : De nombreuses valeurs d'espacement et de marges intérieures/extérieures sont écrites en dur dans le code (ex: `SizedBox(height: 10)`, `SizedBox(height: 30)`, `Padding(padding: const EdgeInsets.all(20.0))`, `EdgeInsets.symmetric(horizontal: 40)`) dans des fichiers comme `draft_screen.dart`, `boss_card_draft_screen.dart`, `shop_screen.dart` et `class_selection_screen.dart`. Il manque un référentiel commun de jetons de design (design tokens).
* **Double Thématique Graphique** : L'application utilise deux thèmes très différents : le thème **Neon Dark** (combat, sélection de classe, draft) et le thème **RPG Parchment Light** (carte de jeu, échange de reliques). Bien que ce choix artistique sépare bien le monde extérieur du combat, la transition visuelle est brutale et manque de conteneurs ou de logique d'animation communs.
* **Adaptabilité (Responsive Layout)** : Certains écrans (`draft_screen.dart`, `forge_upgrade_dialog.dart`) s'adaptent finement via `LayoutBuilder` (portrait vs paysage), tandis que d'autres (`deck_screen.dart`) utilisent des grilles à tailles fixes (`maxCrossAxisExtent: 200`) risquant des débordements sur petits écrans.

### B. Typographie, Couleurs et Boîtes de Dialogue
* **Palette de Couleurs Éparpillée** : Les codes hexadécimaux de conteneurs (`Color(0xFF1E1E2C)`, `Color(0xFF2A2A3D)`, `Color(0xFF13131E)`) et de rareté (Commun, Rare, Épique, Légendaire) sont dupliqués manuellement entre `relic_exchange_screen.dart`, `card_dictionary_screen.dart` et `ui_card.dart` au lieu de provenir de constantes partagées.
* **Typographie Inline** : Les styles textuels redéfinissent polices, tailles et graisses en dur (`TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold)`) plutôt que de consommer le `Theme.of(context).textTheme`.
* **Doublons de Composants de Dialogue** : Les boîtes de dialogue (`PauseDialog`, `StatsDialog`, `ForgeUpgradeDialog`, `_MergeDialog` dans `deck_screen.dart`) partagent une identité visuelle commune (effet de flou, bordures lumineuses, présentation de cartes) mais sont entièrement redéfinies à partir de rien dans chaque fichier, dupliquant le code de décoration et d'affichage.

### C. Duplication de la Logique de Formatage (Enums)
* **Traduction / Localisation** : La traduction des énumérations (`CardRarity`, `CardTarget`, `RelicRarity`, `RelicTrigger`) en labels localisés (`_getRarityLabel`, `_getTargetLabel`) est copiée-collée à l'identique dans plusieurs fichiers UI (`boss_card_draft_screen.dart`, `card_dictionary_screen.dart`, `forge_upgrade_dialog.dart`, `ui_card.dart`, `relic_exchange_screen.dart`).

---

## 2. Moteur de Rendu de Jeu, Animations et Graphismes (Flame Engine)

### A. Architecture des Composants et Typage
* **Typage Lâche** : Dans `lib/game/heros_draft_game.dart`, la méthode `tryPlayCard(dynamic cardComp, EnemyCard? target)` utilise un type `dynamic` pour le composant de carte. Il est préférable de forcer le type `CardComponent`.
* **Points Positifs** : L'organisation interne de `CardComponent` est excellente, déléguant son rendu textuel à `CardTextRenderer` et ses séquences d'animations à `CardAnimator`. La réconciliation à la volée des icônes d'effets dans `StatusIndicator` (`_refresh`) évite les reconstructions inutiles.

### B. Gestion du Z-Indexing (Priorités)
* **Priorités en Dur** : Lors du drag & drop, la priorité de `CardComponent` est définie en dur à `200` (`CardComponent.onDragStart`), ce qui entre en conflit avec la constante `GameConstants.priorityCardDraggingMax = 500` définie dans `CardAnimator`.
* **Priorité par Défaut** : `HeroCard` et `EnemyCard` n'ont pas de priorité explicite et héritent de la valeur par défaut `0`, créant un risque de chevauchement visuel indésirable si d'autres composants sont ajoutés sur la grille.

### C. Optimisation des Performances Visuelles (Jank / Saccades)
* **Surcharge GPU avec `saveLayer`** : Les méthodes de rendu de `FloatingText` et `EffectIcon` utilisent `canvas.saveLayer(size.toRect(), paint)` pour appliquer une opacité progressive (fade-out). Cette opération force le GPU à allouer un buffer hors écran (offscreen render buffer), provoquant des micro-saccades sur mobile lorsque de nombreux chiffres de dégâts s'affichent simultanément.
* **Appels `saveLayer` Redondants** : Dans `EffectIcon`, `saveLayer` est inutile car l'opacité est déjà prise en compte dans la couleur des tracés vectoriels (`glowColor.withValues(alpha: opacity)`).
* **Re-layout Surchargé du Texte des Cartes** : Quand l'opacité d'une carte change (durant une animation de glissement ou de retour en main), la modification appelle `refreshVisuals()`, ce qui force `TextPainter.layout()` à recalculer les dimensions de plus de 8 textes par carte **60 fois par seconde**, ce qui s'avère extrêmement coûteux pour le CPU.

### D. Bugs de Synchronisation et Transitions Visuelles
* **Bug du Double Impact Visuel** : Lors du jeu d'une carte, Riverpod met à jour les points de vie instantanément. L'UI réagit immédiatement en déclenchant le texte flottant de dégâts et le tremblement de la cible, tandis que la carte en mouvement n'a pas encore atteint l'ennemi. Quand la carte touche enfin sa cible 1 seconde plus tard, l'animation d'impact se déclenche une seconde fois, et le texte des PV ne s'actualise qu'à ce moment précis.
* **Transition de Pioche Visuelle** : Les cartes ajoutées à la main apparaissent instantanément sans transition de glissement depuis la pile de pioche.

---

## 3. Gestion de l'État Global et Architecture Système (Riverpod)

### A. Modernisation de Riverpod (Migration vers Notifier)
* **Utilisation de Classes Obsolètes** : Les contrôleurs (`RunController`, `CombatController`, `DeckNotifier`, etc.) utilisent tous `StateNotifier` et `StateNotifierProvider`. Dans la version 2.x de Riverpod, il est recommandé d'utiliser le générateur de code `@riverpod` avec les classes `Notifier` / `AsyncNotifier`.
* **Signatures de Méthodes Surchargées** : Pour éviter de lire `ref` directement à l'intérieur des contrôleurs, le code appelant (l'UI Flutter) doit orchestrer l'échange de providers. Par exemple, la méthode `ShopController.buyCard` prend en paramètres `InventoryController` et `DeckNotifier`. Cela oblige l'UI à surveiller et extraire plusieurs contrôleurs uniquement pour exécuter une action de jeu.
* **Dépendances Cycliques** : Il y a un couplage bidirectionnel dangereux entre `RunController` (qui lit `inventoryProvider` et `skillProvider`) et `InventoryController` (qui lit `runProvider`).

### B. Découplage de la Logique de Jeu du Rendu Flame
* **Calculs Mathématiques Hors Contrôleurs** : La méthode `HerosDraftGame.executeSkill` (lignes 635-723) calcule la logique métier pure du combat : les dégâts effectifs du héros (`effectiveAttaque * (skill.effectValue / 100)`), le vol d'armure, les coups critiques, le vol de vie, puis notifie manuellement Riverpod.
* **Duplication des Formules** : Le calcul de coup critique et les formules de dégâts physiques/magiques sont dupliqués entre `EffectResolver._calculateDamage` (pour les cartes) et `HerosDraftGame.executeSkill` (pour les compétences).

### C. Immuabilité et Détection de Changement d'État
* **Données Mutables** : `CardInstance` (`lib/models/card_instance.dart`) possède des propriétés non-finales (`rarity`, `forgeUpgrades`, `temporaryCost`) modifiées directement en place dans les listes. Cela empêche Riverpod de détecter les changements via l'égalité de référence et peut bloquer la mise à jour visuelle des cartes dans l'interface.

### D. Évolutivité / Extensibilité des Règles (Switch-case bloquants)
* **Chaînes Conditionnelles Rigides** : Les résolutions d'effets de cartes (`EffectResolver.resolveCard`), la création d'états de statut (`EffectResolver._createStatus`), les compétences et les traits passifs utilisent de longs blocs `switch` ou des `if-else` imbriquées. L'ajout d'une nouvelle mécanique de statut ou d'un nouvel effet implique de modifier le code à de multiples endroits du projet.

---

## 4. Recommandations de Réfactorisation (Feuille de Route)

### Chantier 1 : Système de Design Centralisé (Design Tokens)
1. Créer un répertoire `lib/ui/theme/`.
2. Définir une classe `AppColors` pour les palettes Neon Dark, Parchemin et la couleur des raretés.
3. Définir `AppSpacing` pour standardiser les marges et fournir des instances globales de `SizedBox` préconfigurées.
4. Créer un widget générique `GameDialog` unifiant le flou d'arrière-plan (`BackdropFilter`), les bordures dégradées et les ombres.
5. Créer un widget générique `GameButton` gérant l'échelle au survol, l'icône d'or et l'état désactivé de manière homogène.

### Chantier 2 : Robustesse Asynchrone et Centralisation des Callbacks
1. **Sécuriser les appels asynchrones** : Ajouter des vérifications `if (!isMounted)` avant d'exécuter des callbacks asynchrones dans `HerosDraftGame.executeTurn` et `_enemyRipostePhase` pour éviter les fuites de mémoire et exceptions si l'utilisateur quitte l'écran de combat.
2. **Interface de Communication** : Regrouper les 17 callbacks individuels passés au constructeur de `HerosDraftGame` dans une interface unique `CombatCallbackHandler`.

### Chantier 3 : Immuabilité et Refactoring des Modèles
1. Rendre `CardInstance` 100% immuable avec des attributs `final` et une méthode `copyWith`.
2. Créer des extensions Dart sur les enums (ex: `CardRarityExtension` sur `CardRarity`) pour centraliser les libellés de traduction :
   ```dart
   extension CardRarityExtension on CardRarity {
     String getLocalizedName(BuildContext context) {
       final l10n = AppLocalizations.of(context)!;
       switch (this) {
         case CardRarity.common: return l10n.rarityCommon;
         // ... autres cas
       }
     }
   }
   ```

### Chantier 4 : Modernisation de Riverpod & Découplage de la Logique Métier
1. Migrer les contrôleurs héritant de `StateNotifier` vers le générateur `@riverpod` avec la classe `Notifier`.
2. Utiliser `ref` en interne pour orchestrer les contrôleurs (ex: `ref.read(deckProvider.notifier)` au sein de `ShopController`) afin de simplifier les appels depuis l'UI.
3. Déplacer toute la logique mathématique des compétences (lignes 635-723 de `heros_draft_game.dart`) vers les contrôleurs Riverpod ou vers un service partagé `CombatLogicService` unifié avec les cartes.
4. Remplacer les switch-cases procéduraux d'effets par le patron de conception **Stratégie (Strategy Pattern)** en créant une interface `GameEffectBehavior` implémentée par classe d'effet (`DamageEffect`, `HealEffect`, `ApplyStatusEffect`), enregistrées dans un registre extensible.

### Chantier 5 : Optimisations Graphiques du Moteur Flame
1. **Élimination de `saveLayer`** : Modifier `FloatingText` pour appliquer l'opacité directement sur le style du texte (`TextStyle`) plutôt que via le canvas. Retirer l'appel à `saveLayer` de `EffectIcon`.
2. **Éviter le Layout CPU** : Empêcher l'appel à `refreshVisuals()` dans le setter d'opacité de `CardComponent`. N'utiliser le `canvas.saveLayer` temporairement que si l'opacité est inférieure à 1.0 lors des courtes animations de transition de cartes.
3. **Correction de la désynchronisation des PV** : Reporter l'application visuelle des dégâts (chiffres flottants, tremblements) dans `EnemyCard` au moment exact où le composant de carte physique entre en collision avec la cible, garantissant un rendu fluide et logique.
4. **Transition de pioche** : Animer le déplacement de la carte depuis les coordonnées de la pile de pioche jusqu'aux coordonnées calculées dans la main lors de la distribution initiale.
