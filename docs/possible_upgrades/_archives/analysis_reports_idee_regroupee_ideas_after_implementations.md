# Hero's Draft — Audit d'Améliorations (Roadmap vs Codebase)

Ce document présente l'état d'avancement des fonctionnalités listées dans la roadmap d'améliorations ([idees_regroupees.md](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/docs/possible_upgrades/idees_regroupees.md)) par rapport au code implémenté.

---

## 📊 Matrice d'État d'Implémentation

Le tableau suivant synthétise l'état de chaque sous-section du fichier de roadmap :

| Section | Sous-fonctionnalité / Idée | Statut | Fichiers impliqués |
| :--- | :--- | :---: | :--- |
| **1. Équilibrage Ennemis** | A. Courbe de scaling adoucie | **Implémenté** | [encounter_system.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/systems/encounter_system.dart) |
| | B. Armure progressive selon l'acte | **Non implémenté** | [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart) |
| | C. Intention ennemie masquée ("❓") | **Non implémenté** | [enemy_intents_panel.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/hud/enemy_intents_panel.dart) |
| | D. Statistiques de critique en combat | **Implémenté** | [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart) |
| **2. Système de Cartes** | A. Profil élémentaire pur vs hybride | **Non implémenté** | [cards.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/cards.json) |
| | B. Contrepartie fusion (coût mana) | **Non implémenté** | [card_instance.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/card_instance.dart) |
| | C. Tooltips de ciblage / Icône front | **Partiel** | [ui_card.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/ui_card.dart) |
| **3. Système Reliques** | A. Audit et correction `energy_stone` | **Implémenté** | [run_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/run_controller.dart) |
| | B. Rencontre d'échange de reliques | **Non implémenté** | [inventory_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/inventory_controller.dart) |
| | C. Reliques augmentant le critique | **Implémenté** | [relics.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/relics.json) |
| **4. Événements** | A. Choix Autel Mystérieux (sacrifice) | **Non implémenté** | [events.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/events.json) |
| | B. Choix Goblin Merchant rééquilibré | **Non implémenté** | [events.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/events.json) |
| **5. Génération Map** | A. Anti-répétition des types nœuds | **Non implémenté** | [map_generator_service.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/services/map_generator_service.dart) |
| | B. Quotas min/max par type de nœud | **Non implémenté** | [map_generator_service.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/services/map_generator_service.dart) |
| | C. Divergence chemins et multi-boss | **Non implémenté** | [map_generator_service.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/services/map_generator_service.dart) |
| **6. Interface & HUD** | A. HUD stats joueur responsive | **Partiel** | [game_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/game_screen.dart) |
| | B. Espacement dynamique des ennemis | **Implémenté** | [heros_draft_game.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/heros_draft_game.dart) |
| | C. Tooltips / Tracé de ciblage | **Implémenté** | [game_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/game_screen.dart) |
| | D. Badge du nombre total sur "Mon Deck" | **Non implémenté** | [map_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/map_screen.dart) |
| **7. Repos & Forge** | A. Limiter le nombre d'upgrades forge | **Implémenté** | [rest_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/rest_screen.dart) |
| | B. Système de forge à options multiples | **Implémenté** | [forge_upgrade_dialog.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/forge_upgrade_dialog.dart) |
| **8. Méta-Fonctions** | A. Tutoriel interactif | **Implémenté** | [tutorial_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/tutorial/tutorial_screen.dart) |
| | B. Menu Patch Notes | **Non implémenté** | — |
| | C. Effets hover/sélection dans le draft | **Implémenté** | [draft_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/draft_screen.dart) |

---

## 🔍 Analyse Détaillée par Section

### Section 1. ⚔️ Équilibrage des Ennemis (Scaling, Armure, Intentions)

*   **Formules de scaling adoucies : Implémenté.**
    *   La formule de scaling a été ajustée dans [encounter_system.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/systems/encounter_system.dart) conformément aux recommandations de réduction logarithmique/linéaire :
        *   Multiplicateur HP : `(1.0 + 0.06 * (enemyLevel - 1)) * (1.0 + 0.20 * (act - 1))`
        *   Multiplicateur Dégâts : `(1.0 + 0.04 * (enemyLevel - 1)) * (1.0 + 0.15 * (act - 1))`
    *   Les coefficients de scaling de base ont bien été réduits de moitié pour correspondre à des valeurs non agressives.
*   **Armure progressive : Non implémenté.**
    *   Le paramètre `baseArmor` n'existe pas dans [enemies.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/enemies.json) ou [enemy_data.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/data/enemy_data.dart).
    *   L'armure initiale de spawn est codée en dur à `0` dans `combat_controller.dart`.
*   **Cacher les intentions : Non implémenté.**
    *   Toutes les intentions ennemies sont stockées et affichées en permanence via `enemy_intents_panel.dart` sans possibilité de masquage dynamique.
*   **Statistique de critique : Implémenté.**
    *   Les attributs `critChance` (valeur initiale par ennemi définie dans `enemies.json`) et `critMultiplier` (valeur par défaut `1.5` sur `EntityStats`) sont actifs et utilisés dans [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart) pour les dégâts, les soins et les sorts, ainsi que pour les attaques des monstres dans `combat_controller.dart`.

### Section 2. 🃏 Système de Cartes (Éléments, Fusion, Mana)

*   **Profils élémentaires pur vs hybride : Non implémenté.**
    *   Dans `cards.json`, toutes les cartes appliquant des statuts infligent également des dégâts directs (ex: *Coup Empoisonné*, *Boule de Feu*, *Trait de Glace*). Aucune carte élémentaire "pure" (ex: uniquement Poison ou Gel avec 0 dégât de base) n'a été ajoutée.
*   **Contreparties de fusion : Non implémenté.**
    *   Les cartes n'ont plus de système de niveau numérique mais progressent par rareté (Commune $\rightarrow$ Peu Commune $\rightarrow$ Rare $\rightarrow$ Épique $\rightarrow$ Légendaire) avec des multiplicateurs d'effets. Cependant, le coût de mana n'augmente pas à chaque palier de fusion. Il reste fixe dans [card_instance.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/card_instance.dart) : `int get currentCost => temporaryCost ?? data.cost;`.
*   **Tooltips de ciblage / Icônes front : Partiel.**
    *   Le tracé d'une ligne de ciblage dynamique ainsi que le surlignage lumineux des cibles valides lors du glissement de carte sont pleinement opérationnels en combat.
    *   Toutefois, il n'y a pas d'icône de ciblage dédiée (ex: 🎯, 💥, 🛡️) affichée sur la face avant de la carte en dehors du texte descriptif affiché en long-press dans [ui_card.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/widgets/ui_card.dart).

### Section 3. 💎 Système de Reliques (Équilibrage, Échange, Triggers)

*   **Audit logic / `energy_stone` : Implémenté.**
    *   La relique `energy_stone` applique bien son trigger `startOfTurn`. Le mana du héros est restauré à sa valeur maximum dans `startTurn()`, puis les reliques ajoutent leur valeur en plus. `energy_stone` ajoute +1 mana et permet donc de dépasser le cap de mana initial de manière valide pour le tour (ex: 4/3 mana).
    *   Les autres reliques (`iron_talisman`, `protection_rune`, `regen_ring`, `mana_crystal`) sont actives et se déclenchent à leurs moments respectifs.
*   **Rencontre d'échange de reliques : Non implémenté.**
    *   Il n'existe aucun nœud de type `relicForge` dans la génération de map ni d'écran ou logique de conversion des reliques par paquets de 3 dans `inventory_controller.dart`.
*   **Reliques Critique : Implémenté.**
    *   Deux reliques spécifiques sont opérationnelles dans `relics.json` : `critical_lens` (octroie un statut de combat de +15% de critique) et `lucky_charm` (augmente définitivement la statistique `critChance` du héros de +10% en début de run).

### Section 4. 🎭 Événements & Rencontres

*   **Rééquilibrages de l'Autel Mystérieux et du Gobelin Marchand : Non implémenté.**
    *   Dans [events.json](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/assets/data/events.json), les choix n'ont pas subi d'altérations :
        *   *Autel Mystérieux* : Pas d'option permettant de détruire une carte en échange d'une relique.
        *   *Gobelin Marchand* : Le troisième choix ("L'aider à se cacher") offre toujours une relique gratuite sans aucune contrepartie négative (PV perdus, fatigue ou autre). De plus, l'option 1 affiche un texte évoquant un risque de perte de PV mais applique directement un gain net de gold.

### Section 5. 🗺️ Génération de la Map & Chemins

*   **Anti-répétition et Quotas de nœuds : Non implémenté.**
    *   La méthode de choix aléatoire de nœud dans [map_generator_service.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/services/map_generator_service.dart) repose uniquement sur des coefficients de chance fixes. Il n'y a aucun historique de chemin pour éviter de générer 3 Elites ou 3 Repos d'affilée.
    *   Les seuls quotas sont structurels (départ forcé en combat, chokepoint au milieu, repos final avant le boss).
*   **Chemins divergents vers des boss différents : Non implémenté.**
    *   La structure finale du graphe de map converge vers une largeur de ligne unique de 1, menant à un seul nœud Boss. Aucun combat de Boss alternatif n'est configuré ou visible sur la carte.

### Section 6. 🖥️ Interface de Combat & HUD

*   **Stats joueur responsive : Partiel.**
    *   La barre de vie et le HUD s'adaptent horizontalement à la largeur de l'écran en utilisant `MediaQuery.of(context).size.width * factor`. Cependant, les tailles de police, les dimensions des icônes et la hauteur globale du conteneur (88 px) sont des valeurs fixes qui ne s'adaptent pas à la hauteur d'affichage.
*   **Espacement des ennemis : Implémenté.**
    *   L'espacement horizontal est dynamiquement calculé dans `heros_draft_game.dart` via `size.x * 0.8 / (enemies.length + 1)` avec un clamping (120 à 250 pixels), empêchant tout chevauchement des modèles.
*   **Badge Deck sur la Toolbar : Non implémenté.**
    *   Le bouton "Mon Deck" sur `map_screen.dart` n'affiche pas de badge numérique indiquant la taille du deck. Il se contente d'afficher un point rouge vide en cas de fusion possible de 3 exemplaires.

### Section 7. 🏕️ Zone de Repos & Forge

*   **Toutes les fonctionnalités de la Forge Roguelike : Implémentées.**
    *   La capacité d'upgrade d'une instance de carte est plafonnée par $\text{baseMaxForgeUpgrades} + \text{rarityIndex}$ et validée au niveau de l'entrée du dialogue et lors de l'Auto-Merge.
    *   La Forge dans [rest_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/rest_screen.dart) ouvre le `ForgeUpgradeDialog` proposant de 1 à 5 options (probabilités de fente : 100%, 50%, 25%, 10%, 2%).
    *   Coût de relance (reroll) de fente individuel et progressif : $\text{cost} = \text{round}(20 \times 1.25^{\text{rerolls}})$.
    *   Pools par rareté de carte (Commun, Peu Commun, Rare).
    *   Contraintes d'affinités (statuts élémentaires sur cartes d'attaque uniquement, upgrade `enduring` pour enlever exhaust uniquement sur les cartes non-Power).
    *   Intégration et résolution en combat de tous les bonus (`sharp`, `hardened`, `quick`, `eco`, `burning`, `freezing`, `shocking`, `enduring`).

### Section 8. 🎮 Méta-Fonctionnalités (Tutoriel, Patch Notes, Draft UX)

*   **Tutoriel interactif : Implémenté.**
    *   Le dossier `lib/tutorial/` contient un moteur complet de simulation du tutoriel divisé en 13 modules thématiques interactifs expliquant l'intégralité du fonctionnement du jeu.
*   **Patch Notes : Non implémenté.**
    *   Aucune structure `patch_notes.json` ou écran `patch_notes_screen.dart` n'existe dans le projet.
*   **Effets hover/sélection sur le Draft : Implémenté.**
    *   `draft_screen.dart` et `DraftChoiceCard` intègrent des animations de mise à l'échelle progressive (1.05x au hover, 1.12x à la sélection) associées à des glows de bordure colorés selon la rareté de la carte et des effets de particules.

---

## 💡 Recommandations et Prochaines Étapes

Pour finaliser les éléments non implémentés de cette roadmap :
1.  **Section 1 & 5 (Scaling / Map)** : Introduire l'armure de base progressive pour les ennemis dans `enemies.json` et implémenter la logique d'historique de nœuds (anti-répétition) dans `map_generator_service.dart`.
2.  **Section 2 & 4 (Cartes / Événements)** : Ajouter de vrais fichiers de configuration pour les cartes élémentaires de type pur (0 dégât) et corriger le déséquilibre des récompenses de l'événement `goblin_merchant` et de l'achat de sac.
3.  **Section 8 (Méta)** : Implémenter l'écran des notes de mise à jour à partir d'un fichier `patch_notes.json` statique.
