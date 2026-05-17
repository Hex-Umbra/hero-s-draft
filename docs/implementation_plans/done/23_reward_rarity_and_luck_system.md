# Phase 23 : Système de Rareté des Récompenses et Statistique de Chance

## 1. Analyse Approfondie du Problème

Actuellement, les récompenses à la fin d'un combat (Draft) sont fixes (ex: Sagesse donne toujours +5 Mana Max). 
- Cela rend les récompenses prévisibles et enlève l'aspect "Loot" grisant d'un roguelike.
- Il n'y a aucun moyen pour le joueur de maximiser ses chances d'obtenir de très bonnes récompenses.
- L'idée est d'ajouter un système de **Rareté** (Commun, Peu Commun, Rare, Épique) qui multipliera l'effet de base (ex: x1, x2, x3, x4) et d'ajouter une statistique de **Chance** (`luck`) pour influencer ces probabilités.

## 2. Pistes de Solutions Détaillées

### Système de Rareté
- **Niveaux de rareté :**
  - **Commun** (Gris/Blanc) : Effet de base (ex: +5 PV Max)
  - **Peu Commun** (Vert) : Effet x1.5 ou x2 (ex: +10 PV Max)
  - **Rare** (Bleu) : Effet x2 ou x3 (ex: +15 PV Max)
  - **Épique** (Violet) : Effet x3 ou x4 (ex: +20 PV Max)
  - **Légendaire** (Doré) : Réserve pour des stats uniques (ex: +1 Chance)

### Statistique de Chance (Luck)
- Ajout d'une propriété `luck` (par défaut 0) au `HeroStats` et `HeroData`.
- Cette statistique peut être augmentée par une récompense de fin de combat très rare (Légendaire) ou par de futures reliques.
- L'algorithme de génération de récompense dans `DraftScreen` utilisera le `luck` pour ajuster les poids des raretés (ex: chaque point de `luck` augmente de 10% la chance d'avoir du Rare+).

## 3. Plan d'Implémentation Étape par Étape

### Étape 1 : Ajout de la statistique de Chance (Luck)
- **Fichiers ciblés :** `lib/models/hero_stats.dart`, `lib/models/data/hero_data.dart`
- **Actions :**
  - Ajouter `luck` (int, défaut 0).
  - Mettre à jour `fromJson`, `toJson`, `copyWith`.
  - Mettre à jour `RunController` (notamment `applyLevelUpReward`) pour pouvoir recevoir un bonus de Chance.

### Étape 2 : Création de l'enum et des multiplicateurs de Rareté
- **Fichiers ciblés :** `lib/ui/screens/draft_screen.dart` (ou un nouveau fichier `reward_rarity.dart`)
- **Actions :**
  - Créer l'enum `RewardRarity { common, uncommon, rare, epic, legendary }`.
  - Créer une classe `RewardTier` ou ajuster `_DraftChoice` pour contenir cette rareté.

### Étape 3 : Algorithme de génération de Rareté avec prise en compte de la Chance
- **Fichier ciblé :** `lib/ui/screens/draft_screen.dart`
- **Actions :**
  - Dans `_generateChoices()`, pour chaque choix, tirer une rareté au sort selon des probabilités de base.
  - Modifier ces probabilités en fonction de `runState.heroStats.luck`.
  - Si "Légendaire" est tiré, remplacer le choix par "Trèfle à 4 feuilles (+1 Chance)".
  - Appliquer le multiplicateur de la rareté aux valeurs (PV, Attaque, Armure, Mana).

### Étape 4 : Retour Visuel de la Rareté dans l'UI du Draft
- **Fichier ciblé :** `lib/ui/screens/draft_screen.dart`
- **Actions :**
  - Modifier l'affichage des tuiles de récompense.
  - Utiliser des couleurs de bordure/fond différentes selon la rareté (Gris, Vert, Bleu, Violet, Doré).
  - Ajouter le nom de la rareté (ex: "Sagesse Rare") dans le titre.

## 4. Critères de Validation
- [ ] La stat `luck` est bien présente dans `HeroStats`.
- [ ] Les récompenses de fin de combat ont des raretés visuellement distinctes.
- [ ] Les valeurs des récompenses varient selon la rareté.
- [ ] Le code compile et `dart analyze` passe.
