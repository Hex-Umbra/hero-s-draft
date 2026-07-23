# Système de Rareté des Récompenses et Statistique de Chance

Ce document détaille le fonctionnement technique, l'équilibrage et l'implémentation du système de récompenses post-combat (Draft) et de l'influence de la statistique de Chance (`luck`).

## 1. Localisation du Code
- **Logique de génération** : `lib/ui/screens/draft_screen.dart`
- **Statistiques du héros** : `lib/models/hero_stats.dart`
- **Affichage visuel** : `lib/ui/widgets/ui_card.dart`
- **Contrôleur de run** : `lib/game/controllers/run_controller.dart`

---

## 2. Niveaux de Rareté et Multiplicateurs

Le système utilise l'énumération `RewardRarity`. Chaque niveau (hors Légendaire) applique un multiplicateur aux valeurs de base des bonus de statistiques.

| Rareté | Multiplicateur | Couleur UI | Effets Visuels |
| :--- | :---: | :--- | :--- |
| **Commun** | x1.0 | Blanc / Ambre | Bordure standard (1.5px) |
| **Peu Commun** | x1.5 | Vert | Bordure verte (1.5px) |
| **Rare** | x2.0 | Bleu | Bordure bleue (1.5px) |
| **Épique** | x3.0 | Violet | Bordure violette + Halo lumineux (Glow) |
| **Légendaire** | Spécial | Orange / Or | Bordure épaisse (2.5px) + Halo intense |

---

## 3. Équilibrage des Statistiques

### Valeurs de Base (Rareté Commun)
- **Vitalité** : +5 PV Max
- **Aiguisage** : +2 Attaque
- **Forge d'Acier** : +1 Maîtrise d'Armure
- **Sagesse** : +1 Mana Max

### Tableau des Valeurs par Rareté
*Valeurs arrondies à l'entier le plus proche.*

| Statistique | Commun (x1) | Peu Commun | Rare | Épique |
| :--- | :---: | :---: | :---: | :---: |
| **PV Max** | +5 | +8 | +10 | +15 |
| **Attaque** | +2 | +3 | +4 | +6 |
| **Maîtrise d'Armure** | +1 | +2 | +3 | +5 |
| **Mana Max** | +1 | +2 | +2 | +3 |

---

## 4. Algorithme de Chance (Luck)

La statistique `luck` influence les probabilités de "roll" une rareté élevée. Elle commence par défaut à **0**.

### Probabilités de Base (0 Luck)
- **Légendaire** : 1.0 %
- **Épique** : 4.0 %
- **Rare** : 15.0 %
- **Peu Commun** : 30.0 %
- **Commun** : 50.0 %

### Influence de la Statistique Luck
Chaque point de `luck` augmente les chances des raretés supérieures :
- **Légendaire** : +0.5 % par point
- **Épique** : +1.5 % par point
- **Rare** : +3.0 % par point
- **Peu Commun** : +4.0 % par point

---

## 5. Mécanique des Récompenses "Bonus" (Légendaires)

Les objets de rareté **Légendaire** ne remplacent pas les 3 choix standards. Ils sont testés de manière indépendante et s'ajoutent à la liste des récompenses comme des bonus exceptionnels.

### Objets Légendaires Actuels
1.  **Trèfle à 4 feuilles** : Octroie **+1 Chance** de manière permanente pour la run.
2.  **Miroir Magique** : Permet de **cloner** une carte au choix parmi 3 de son deck actuel.

### Logique de Génération (DraftScreen)
1.  **Génération Slots 1-3** : Toujours 3 récompenses standards (Commun à Épique).
2.  **Test Bonus 1** : Lancement d'un dé pour le Trèfle (Probabilité Légendaire).
3.  **Test Bonus 2** : Lancement d'un dé pour le Miroir (Probabilité Légendaire).

*Note : Il est possible d'avoir 3, 4 ou 5 récompenses au total selon la réussite de ces tests bonus.*

---

## 6. Focus : Maîtrise d'Armure (Forge d'Acier)

La Maîtrise d'Armure est une statistique synergique qui augmente **tous les gains d'armure** de sa valeur.
- **Exemple** : Si vous avez 3 de Maîtrise et jouez une carte donnant 5 Armure, vous recevez réellement **8 Armure** (5 + 3).
- **Synergies** : Fonctionne avec les cartes, les traits passifs (Regen d'armure du Paladin) et les reliques.
- **Persistance** : Contrairement à l'armure qui est remise à 0 au début de chaque combat, la Maîtrise est une statistique permanente.

---

## 6. Guide de Modification

### Pour changer les probabilités :
Modifier la méthode `_rollRarity` dans `draft_screen.dart`. Ajustez les variables `legendaryChance`, `epicChance`, etc.

### Pour ajouter un nouveau bonus de statistique :
1.  Ajouter le type dans `_generateChoices` (variable `type = rng.nextInt(X)`).
2.  Définir la valeur de base et appliquer le `multiplier`.

### Pour ajouter un nouvel objet Légendaire :
1.  Ajouter un bloc de test indépendant à la fin de `_generateChoices`.
2.  Utiliser `_rollRarity(luck)` pour vérifier si le résultat est `RewardRarity.legendary`.
3.  Ajouter l'objet à la liste `choices`.
