# 📋 Revue des Idées d'Amélioration Restantes — Hero's Draft

> **Source** : [`upgrade_ideas.md`](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/docs/possible_upgrades/upgrade_ideas.md) — Section non cochée (après le séparateur `---`)

---

## Vue d'ensemble

**20 items restants** ont été analysés et regroupés en **7 sections thématiques**. Chaque section est décrite avec son contexte, ses items détaillés et son niveau de complexité estimé.

---

## Section 1 — 🃏 Interface & Cartes à Jouer (UX Combat)

**Contexte** : Plusieurs items concernent directement l'expérience de jeu pendant le combat, notamment la lisibilité des cartes, les interactions et les animations.

### Items regroupés

| # | Item | Complexité |
|---|------|-----------|
| 101 | Les cartes restent bloquées sur la souris pendant l'animation depuis la pioche → les rendre non-interactibles pendant l'animation + ralentir l'anim | Moyenne |
| 106 | Modifier **quand** le tooltip apparaît sur les cartes en combat + afficher les upgrades de forge dans le tooltip | Faible |
| 107 | Rajouter des **étoiles** sur la carte pour indiquer le nombre d'améliorations de forge prises/disponibles | Faible |
| 108 | **Supprimer l'icône background** transparente de la carte (pollution visuelle) | Très faible |
| 109 | **Réduire la taille de la police** des cartes | Très faible |
| 117 | Animation **smooth** sur la barre de vie du joueur quand il perd des HP | Faible |

### Analyse
Ces 6 items forment une itération de polish sur le widget carte et l'UX combat. Ils sont tous **interdépendants visuellement** (même composant `CardWidget` ou son équivalent Flame) et peuvent être traités en un seul bloc de refactoring UI. Le plus impactant est le **tooltip enrichi** (106+107) car il améliore directement la lisibilité du gameplay.

---

## Section 2 — 🔨 Menu de Forge

**Contexte** : La forge a déjà été revue, mais plusieurs problèmes d'UX et de logique de gameplay subsistent.

### Items regroupés

| # | Item | Complexité |
|---|------|-----------|
| 102 | Revoir l'aspect esthétique du menu forge + le rendre **scrollable** | Moyenne |
| 105 | Empêcher le **reroll gratuit** des options en sortant et revenant dans le menu forge | Faible |
| 112 | **Filtrer les types d'amélioration** selon le type de carte (attaque/compétence/pouvoir) | Moyenne |
| 113 | Permettre au joueur d'**acheter des fentes d'options** supplémentaires (jusqu'à 5 max) | Moyenne |

### Analyse
Ces 4 items ont une forte cohésion : ils réforment la forge en profondeur sur 3 axes — **visuel** (102), **anti-exploit** (105) et **game design** (112, 113). Le fix 105 est urgent car c'est un exploit actif. Les items 112 et 113 ajoutent de la profondeur stratégique. À traiter comme une **seule itération "Forge v2"**.

---

## Section 3 — 🏪 Shop & Économie

**Contexte** : Le shop a des problèmes d'affichage et de logique de contenu.

### Items regroupés

| # | Item | Complexité |
|---|------|-----------|
| 99 | Les cartes de la colonne "Cartes à vendre" s'affichent **en ligne 1 par 1** au lieu de **4 colonnes** | Faible |
| 103 | **Retirer du pool du shop** les cartes uniques des personnages (ne doivent pas être achetables) | Faible |
| 115 | Modifier le style visuel des cartes dans la colonne "Cartes à vendre" pour **respecter le type** (fond par type de carte, pas bleu uniforme) | Faible |

### Analyse
3 items rapides et indépendants, tous dans le même écran `ShopScreen`. Peuvent être regroupés en un **seul PR "Shop fixes"**. Le 103 est à la fois un bugfix de game design (les cartes uniques ne devraient pas être achetables) et le 99 est un bug visuel post-refactoring à corriger rapidement.

---

## Section 4 — 🗺️ Map, Draft & Progression

**Contexte** : Items liés à la progression sur la map, aux menus de récompenses post-combat et aux nœuds.

### Items regroupés

| # | Item | Complexité |
|---|------|-----------|
| 110 | Le draft post-level-up doit **attendre l'arrivée sur la map** + animation "Level Up" au centre de l'écran avant d'afficher le menu | Moyenne |
| 111 | Dans le **carrousel de reliques**, ne pas afficher la rareté avant la fin de l'animation — afficher le nom de la relique avec la couleur de sa rareté à la fin | Faible |
| 114 | Transformer le nœud du milieu de la map en **nœud d'élite fixe** (au lieu d'aléatoire) | Faible |

### Analyse
3 items de polish sur la progression. Le 110 améliore le **game feel** de la montée de niveau. Le 111 corrige un **spoil** de récompense (on voit la rareté avant l'animation). Le 114 est un simple changement de game design sur la génération de map. Peuvent former un bloc **"Map & Progression polish"**.

---

## Section 5 — 🎮 Systèmes de Gameplay

**Contexte** : Items qui touchent à des mécaniques de jeu plus profondes.

### Items regroupés

| # | Item | Complexité |
|---|------|-----------|
| 98 | Pour certains ennemis ou à partir d'un certain acte, **cacher les intentions** des ennemis | Moyenne |
| 104 | **Diminuer le scaling des dégâts** des ennemis | Faible (tuning JSON) |
| 116 | Cartes de rareté "Unique" : interface **distincte** + onglet dédié dans le dictionnaire groupé par héros | Moyenne |

### Analyse
Ces items touchent à **l'équilibrage et à la profondeur** du jeu. Le 98 introduit un nouveau mécanisme d'incertitude stratégique (cacher les intentions). Le 104 est un ajustement d'équilibrage probablement rapide (valeurs JSON ou formule). Le 116 améliore la lisibilité du système de cartes de héros. Groupés en **"Gameplay & Équilibrage"**.

---

## Section 6 — 🐛 Bugs & Exploits Actifs

**Contexte** : Items identifiés comme bugs ou exploits exploitables maintenant.

### Items regroupés

| # | Item | Complexité |
|---|------|-----------|
| 105 | **Exploit forge** : reroll gratuit en sortant/revenant (déjà listé en Section 2 — priorité élevée) | Faible |

> *Note : Le 105 est également dans la Section 2, mais sa nature de bug-exploit le place ici comme priorité critique.*

---

## Section 7 — 🛠️ Outils & Debug

**Contexte** : Un seul item technique, non lié au gameplay.

### Items regroupés

| # | Item | Complexité |
|---|------|-----------|
| 100 | Rajouter un **menu de debug** accessible par combinaison de touches | Élevée |

### Analyse
Item utile pour le développement mais sans impact joueur. À reporter après stabilisation des features gameplay. La complexité vient de la nécessité d'exposer des hooks sur tous les systèmes (santé, cartes, XP, etc.) de manière sécurisée.

---

## 📊 Récapitulatif par Complexité

| Section | Items | Complexité globale |
|---------|-------|--------------------|
| Shop & Économie (S3) | 3 | ⭐ Faible |
| Map, Draft & Progression (S4) | 3 | ⭐⭐ Faible-Moyenne |
| Interface & Cartes UX (S1) | 6 | ⭐⭐ Faible-Moyenne |
| Forge v2 (S2) | 4 | ⭐⭐⭐ Moyenne |
| Gameplay & Équilibrage (S5) | 3 | ⭐⭐ Faible-Moyenne |
| Outils Debug (S7) | 1 | ⭐⭐⭐⭐ Élevée |

---

## 🚀 Ordre de Priorité Recommandé

> Classement basé sur : **impact joueur × risque × dépendances entre items**

---

### 🥇 Priorité 1 — Bugs & Exploits Immédiats
**Section 3 (Shop) + Item 105 (Exploit Forge)**

*Raison* : Le reroll gratuit de la forge est un exploit actif qui casse l'équilibrage. Les bugs shop (layout 4 colonnes, cartes uniques achetables, style visuel) dégradent l'expérience directement visible. Corrections rapides, haut impact.

**Items** : 99, 103, 105, 115

---

### 🥈 Priorité 2 — Polish UI Combat (Cartes)
**Section 1 — Interface & Cartes à Jouer**

*Raison* : Le combat est le cœur du jeu. Améliorer la lisibilité (tooltip enrichi, étoiles d'upgrades, suppression du bruit visuel, police réduite) et corriger l'animation de pioche sont des gains de clarté immédiate pour le joueur. L'animation smooth de la barre de vie est un must-have de game feel.

**Items** : 101, 106, 107, 108, 109, 117

---

### 🥉 Priorité 3 — Forge v2
**Section 2 — Menu de Forge**

*Raison* : La forge est un système central post-combat. La refonte esthétique + scrollable (102), le filtrage par type de carte (112) et les fentes d'options achetables (113) améliorent profondément la stratégie. À faire après les fixes urgents car c'est une itération plus longue.

**Items** : 102, 112, 113

---

### 4️⃣ Priorité 4 — Map & Progression
**Section 4**

*Raison* : L'animation Level Up et la correction du spoil de rareté dans le carrousel de reliques améliorent le **game feel** des moments forts de la progression. Le nœud d'élite fixe au milieu est un changement de design simple mais structurant pour la map.

**Items** : 110, 111, 114

---

### 5️⃣ Priorité 5 — Gameplay & Équilibrage
**Section 5**

*Raison* : Cacher les intentions (98), rebalancer le scaling (104) et distinguer les cartes uniques (116) sont des améliorations de profondeur qui demandent plus de réflexion game-design. À traiter une fois les fundations visuelles stabilisées.

**Items** : 98, 104, 116

---

### 6️⃣ Priorité 6 — Outils de Debug
**Section 7**

*Raison* : Utile en développement mais sans impact direct sur l'expérience joueur. À implémenter lorsque les features principales sont stables.

**Items** : 100

---

## 📌 Résumé Exécutif

```
P1 (Urgents)  : Shop fixes + Exploit forge       → 4 items  — ~1-2 sessions
P2 (Impactant): Polish UI Combat & Cartes         → 6 items  — ~2-3 sessions  
P3 (Forge v2) : Refonte forge UX + game design   → 3 items  — ~2 sessions
P4 (Progression): Map polish & Level Up flow     → 3 items  — ~1 session
P5 (Équilibre): Gameplay depth & tuning          → 3 items  — ~1-2 sessions
P6 (Debug)    : Menu debug développeur           → 1 item   — ~1 session
```

**Total estimé** : ~20 items → ~8-11 sessions de développement ciblées.
