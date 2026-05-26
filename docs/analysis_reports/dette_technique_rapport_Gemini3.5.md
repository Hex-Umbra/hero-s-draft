# Rapport d'Analyse de la Dette Technique - Hero's Draft

Ce rapport présente une analyse approfondie et exhaustive de la structure actuelle du projet **Hero's Draft** (développé avec **Flutter**, **Flame**, et **Riverpod**). L'objectif est d'identifier les zones de fragilité (dette technique), d'expliquer les risques qu'elles comportent pour la maintenance et l'évolutivité du jeu, et de proposer un plan de refactoring rigoureux pour assainir la base de code.

---

## 1. Résumé Exécutif

**Hero's Draft** est un excellent exemple de jeu de cartes roguelike intégrant de manière fluide un moteur de rendu performant (Flame) et une interface utilisateur réactive (Flutter). L'intégration de Riverpod permet de gérer efficacement l'état global de la run (niveaux, or, reliques, statistiques du héros).

Cependant, le projet souffre de **trois types majeurs de dette technique** qui entravent le développement de nouvelles fonctionnalités (comme la sauvegarde à mi-combat, l'ajout de nouveaux modes de jeu, ou l'écriture de tests unitaires fiables) :
1. **Couplage fort entre la logique de combat et le moteur graphique (Flame) :** L'état du combat (points de vie des ennemis, intentions, statuts appliqués) n'est pas géré de manière pure par Riverpod mais réside directement au sein des composants visuels Flame (`EnemyCard`).
2. **Écrans monolithiques massifs :** Les fichiers d'interface principaux, notamment `map_screen.dart` (2300+ lignes) et `game_screen.dart` (1350+ lignes), souffrent d'un manque criant de modularité. Ils centralisent les calculs de navigation, les dessins personnalisés, les fenêtres de dialogue complexes (Statistiques, Reliques, Probabilités) et l'agencement du HUD.
3. **Congestion des composants Flame :** Certains composants de rendu comme `stat_badge.dart` (720 lignes) et `card_component.dart` (1030 lignes) gèrent en même temps le dessin vectoriel de base, le calcul de la taille des textes, la gestion du glisser-déposer, les animations de tremblement, et les générateurs de particules.

---

## 2. Couplage Architectural : Flame vs Riverpod

> [!WARNING]
> **Problème Majeur :** L'état de combat n'est pas centralisé dans la couche de gestion d'état globale (Riverpod) mais est dispersé dans les composants Flame (`HerosDraftGame` et `EnemyCard`).

### Les Symptômes
- **Directives de modification en direct :** Dans [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart#L121), la résolution d'une carte d'attaque modifie directement l'état visuel en appelant `selectedEnemy.updateStats(...)` sur un composant visuel de Flame.
- **Synchronisation ad-hoc :** [heros_draft_game.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/heros_draft_game.dart) utilise des callbacks complexes (`onPlayerTakeDamage`, `onPlayerGainArmor`, `onPlayCard`, `onEnemiesDead`) passés depuis [game_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/game_screen.dart) pour synchroniser bidirectionnellement les données entre le moteur Flame et le contrôleur de run de Riverpod.
- **Double vérité de l'état :** L'état des ennemis (PV, armure, intentions d'action, statuts comme le poison ou la faiblesse) n'existe *que* sous forme de variables d'instance dans les composants graphiques `EnemyCard`. Si l'application doit sauvegarder la partie en plein combat, elle en est incapable car ces données s'évaporent à la fermeture de l'écran.

```mermaid
graph TD
    subgraph Architecture Actuelle (Couplée)
        FlameGame[HerosDraftGame] <-->|Callbacks Ad-hoc| GameScreen[game_screen.dart]
        GameScreen <-->|Lecture/Écriture| RunProvider[run_controller.dart]
        EffectResolver[effect_resolver.dart] -->|Modifie directement| EnemyCard[EnemyCard Component]
        EnemyCard -->|Détient l'état unique| EnemyStats[Stats & Intentions]
    end
```

```mermaid
graph TD
    subgraph Architecture Cible (Découplée)
        CombatController[CombatController Riverpod] -->|Gère purement| CombatState[CombatState: Ennemis, Intentions, Tour]
        RunController[RunController Riverpod] -->|Gère globalement| RunState[RunState: Or, Reliques, Niveau]
        HerosDraftGame[HerosDraftGame Flame] -->|Lit / Écoute| CombatController
        HerosDraftGame -->|Affiche| VisualComponents[Composants de Rendu]
        EffectResolver[effect_resolver.dart] -->|Résout purement sur| CombatController
    end
```

### Conséquences
- **Impossible d'écrire des tests unitaires purs de combat :** Pour tester si une carte applique correctement 3 de poison à un ennemi, vous devez obligatoirement instancier le moteur de jeu Flame et ses composants graphiques, ce qui ralentit les tests et les rend fragiles.
- **Difficulté à faire évoluer les combats :** L'ajout de mécaniques de combat complexes (ex: reliques complexes qui modifient l'intention des ennemis, effets de statut affectant l'or à la fin du combat) nécessite de modifier en cascade le moteur graphique et les services de logique.

---

## 3. Analyse des Écrans Monolithiques

Certaines interfaces graphiques clés centralisent trop de responsabilités, ce qui viole le principe de responsabilité unique (SRP).

### A. Le Monolithe de la Carte (`map_screen.dart`)
Avec plus de **2300 lignes**, ce fichier gère en même temps :
1. **La logique algorithmique :** Recherche de chemins inverses (`_findPathToCurrent`) pour calculer les surbrillances et les trajets admissibles.
2. **Le dessin vectoriel (Canvas) :** La classe `MapConnectionPainter` qui trace les lignes pointillées et les arcs entre les nœuds.
3. **Les boîtes de dialogue et overlays :** Les méthodes `_showStatsDialog`, `_showInventoryDialog`, et `_showProbabilitiesDialog` qui construisent des interfaces volumineuses à base de modaux personnalisés.
4. **Les composants internes :** Les classes `_MapNodeWidget`, `_PlayerPawn`, `_LegendItem`, et `_InventoryRelicRow` qui pourraient être réutilisées ou du moins isolées.

### B. Le Monolithe de Combat (`game_screen.dart`)
Avec ses **1350 lignes**, ce fichier combine :
1. **L'instanciation et le paramétrage lourd du jeu :** Des dizaines de lignes de callbacks complexes configurés dans le constructeur de `HerosDraftGame` dans `initState`.
2. **L'affichage du HUD de combat :** Le dessin à la main des cristaux de mana, de la barre de vie progressive avec l'armure superposée, et du panneau des statuts actifs du joueur.
3. **Le panneau des intentions ennemies :** Une itération directe sur les cartes ennemies de Flame pour en extraire l'intention active et construire des listes UI Flutter.
4. **La gestion des overlays :** Pause, écran de draft de cartes (`DraftScreen`), et écran de défaite ("VOUS ÊTES MORT").

> [!TIP]
> **Recommandation :** Extraire ces sous-panneaux en widgets autonomes (`/lib/ui/widgets/hud/` et `/lib/ui/widgets/dialogs/`) pour réduire la taille de ces fichiers sous la barre des 300 lignes.

---

## 4. Congestion des Composants Flame

Les entités de Flame devraient se concentrer uniquement sur le rendu, la mise à jour des coordonnées à chaque frame, et les effets visuels. Actuellement, elles portent trop de logique UI et de calcul.

### A. Le badge de statistiques (`stat_badge.dart`)
Ce fichier de **720 lignes** est surchargé :
- Il intègre les icônes vectorielles personnalisées dessinées via Canvas : `FlameSwordIcon` et `FlameShieldIcon`.
- Il contient des sous-composants entiers pour le rendu visuel : `CircleProgressComponent` et `LinearProgressBarComponent`.
- Il fait des calculs géométriques et typographiques avec `TextPainter` pour mesurer la taille de la police et caler dynamiquement des formats complexes comme `Total (Base + Bonus)` avec alignement horizontal parfait.

### B. Le composant carte de jeu (`card_component.dart`)
Ce fichier de **1030 lignes** centralise :
- La définition des dimensions physiques et les couleurs de rareté.
- La configuration de 6 à 7 instances de `TextPainter` pour peindre manuellement le titre, la rareté, les cristaux de mana, la description formatée selon les forces du joueur, et les labels de types.
- La gestion complète du glisser-déposer (`onDragStart`, `onDragUpdate`, `onDragEnd`) avec détection de collision sur la zone d'annulation ou les cartes ennemies.
- Les générateurs de particules pour l'épuisement (`_spawnExhaustParticles`) et la traînée de rubans (`_spawnTrailParticles`).
- La sélection d'animations complexes (corps à corps, à distance, sorts) et les mouvements cinématiques de retour en main (`_returnToHand`).

---

## 5. Multi-langue : Un Squelette Incomplet

L'application intègre le support d'internationalisation de Flutter (`flutter_localizations`, `l10n.yaml`, `AppLocalizations`) comme on peut le voir dans [main.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/main.dart#L23-L29).

Cependant :
- La grande majorité des chaînes de caractères affichées à l'utilisateur sont **codées en dur** en français ("VOUS ÊTES MORT", "TOUR JOUEUR", "TOUR ENNEMI", "MON DECK", "RELIQUES", "EFFETS DU JOUEUR", "INTENTIONS ENNEMIES", "En attente...", "Plus de mana.\nTerminer le tour ?", etc.).
- Les textes informatifs des cartes et des statuts sont codés en dur en anglais ou en français de manière inconsistante dans le code (ex: "USAGE UNIQUE", "strength", "poison").
- Il n'y a pas de canalisation des descriptions de cartes et de reliques générées par le code vers le fichier de traduction locale.

---

## 6. Code Mort & Incohérences

- **Callback orphelin :** La fonction `onEnemyDebuffDeck` dans `HerosDraftGame` est déclarée, mais le commentaire stipule qu'elle est vide et désactivée car la carte "Blessure de test" a été supprimée du projet.
- **Calculs de force décentralisés :** Les calculs de bonus d'attaque liés aux effets de statut de Force se font à trois endroits différents :
  1. Dans `run_controller.dart` pour le calcul de `effectiveAttaque`.
  2. Dans `effect_resolver.dart` pour `_calculateDamage`.
  3. Dans `card_component.dart` pour formater la description de la carte en fonction de la force active (`_buildDescription`).

---

## 7. Plan d'Action Complet et Feuille de Route pour le Refactoring

Pour éliminer proprement cette dette technique sans interrompre le fonctionnement du jeu (en préservant la validité des tests unitaires existants), nous proposons un plan d'action structuré en 4 étapes majeures.

### Phase 1 : Introduction d'un Contrôleur de Combat Riverpod (Architecture)
L'objectif est d'extraire la logique de combat hors de Flame pour la placer dans un `CombatController` Riverpod pur.

1. **Créer le modèle `CombatState` :**
   - Doit stocker la liste des ennemis actifs avec leurs points de vie, armure, intentions d'action, et statuts actifs.
   - Doit stocker le statut du tour actif (phase du joueur, phase de l'ennemi, numéro de tour).
   - Doit stocker l'ennemi sélectionné/ciblé par le joueur.
2. **Créer `CombatController` (`StateNotifier<CombatState>`) :**
   - Déplacer la logique de fin de tour et de riposte des ennemis (`_enemyRipostePhase` de Flame) vers ce contrôleur.
   - Gérer le ciblage des ennemis et le calcul des intentions.
3. **Mettre à jour `EffectResolver` :**
   - Modifier les méthodes pour qu'elles s'exécutent sur `CombatController` et `RunController`, éliminant toute référence directe aux composants Flame `EnemyCard`.
4. **Refactoriser Flame pour n'être qu'un consommateur d'état :**
   - `HerosDraftGame` et ses composants écoutent le `CombatState` via Riverpod ou via des méthodes de synchronisation épurées.
   - Les modifications de PV ou de statut déclenchent simplement des animations cosmétiques dans Flame, le calcul ayant déjà été validé par Riverpod.

### Phase 2 : Découpage des Écrans Monolithiques (UI Flutter)
Alléger la couche de présentation Flutter en découpant les composants géants.

1. **Extraction de `map_screen.dart` :**
   - Créer `lib/ui/widgets/map/map_connection_painter.dart` pour y déplacer le painter.
   - Créer `lib/ui/widgets/map/map_legend.dart` pour la légende cartographique.
   - Créer `lib/ui/widgets/map/map_node_widget.dart` et `player_pawn.dart` pour le rendu graphique des nœuds de la carte et du pion joueur.
   - Créer un sous-dossier `lib/ui/widgets/map/dialogs/` et y créer des fichiers distincts pour `stats_dialog.dart`, `relics_dialog.dart`, et `probabilities_dialog.dart`.
2. **Extraction de `game_screen.dart` :**
   - Créer `lib/ui/widgets/hud/player_health_bar.dart` pour le rendu complexe de la vie et de l'armure du joueur.
   - Créer `lib/ui/widgets/hud/mana_indicator.dart` pour les cristaux de mana.
   - Créer `lib/ui/widgets/hud/status_effects_panel.dart` pour la liste des statuts actifs du joueur.
   - Créer `lib/ui/widgets/hud/enemy_intents_panel.dart` pour le panneau d'intentions ennemies.
   - Créer `lib/ui/widgets/hud/dialogs/pause_dialog.dart` pour le menu de pause.

### Phase 3 : Modularisation des Composants Flame (UI Flame)
Améliorer la lisibilité et l'organisation du code dans la couche graphique Flame.

1. **Extraction de `stat_badge.dart` :**
   - Extraire les icônes vectorielles dans `lib/game/components/widgets/flame_sword_icon.dart` et `flame_shield_icon.dart`.
   - Extraire les barres de progression dans `lib/game/components/widgets/linear_progress_bar.dart` et `circle_progress_bar.dart`.
2. **Allègement de `card_component.dart` :**
   - Créer un helper ou un système de rendu typographique dédié aux cartes pour désencombrer le fichier des multiples configurations de `TextPainter`.
   - Déplacer la génération cinématique de particules et d'animations complexes dans une classe utilitaire ou un composant d'effet réutilisable.

### Phase 4 : Remplacement des Chaînes en dur par la Traduction (Localisation)
Internationaliser le jeu proprement.

1. **Remplir les fichiers de ressources :**
   - Définir toutes les traductions françaises et anglaises correspondantes dans `lib/l10n/app_fr.arb` et `lib/l10n/app_en.arb`.
2. **Adapter le code de l'interface :**
   - Remplacer les chaînes littérales par des appels à `AppLocalizations.of(context)!.nomDeLaChaine`.
3. **Mettre en place un traducteur pour le moteur Flame :**
   - Passer les chaînes traduites aux composants Flame ou leur fournir un accès indirect aux chaînes internationalisées pour les tooltips et les types de cartes.

---

## 8. Conclusion

En résolvant ces dettes techniques, le projet **Hero's Draft** atteindra un standard de qualité de niveau production. Le code sera plus lisible, extrêmement modulaire, entièrement testable par des tests unitaires automatisés, et prêt à accueillir de nouvelles extensions (comme de nouvelles classes de personnages, des modes de jeu alternatifs, ou un système de sauvegarde persistant).
