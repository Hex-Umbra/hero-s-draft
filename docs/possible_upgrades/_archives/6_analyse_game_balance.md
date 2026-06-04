# Rapport d'Analyse : Équilibrage du Jeu (Dégâts, Armure, Stats)

## 1. Introduction
Ce rapport présente une analyse de l'équilibrage actuel du jeu (Héros, Ennemis, Cartes) basée sur les données des fichiers JSON (`heroes.json`, `enemies.json`, `cards.json`). L'objectif est de mettre en évidence les disparités signalées, notamment concernant les valeurs d'armure et de dégâts, et d'identifier les problèmes structurels de l'économie du jeu en combat.

## 2. Analyse des Héros
Actuellement, 3 classes sont définies avec des profils très marqués :
- **Paladin** : 100 PV, 10 Mana, 5 Dégâts de base, 20 Armure de base.
- **Berserker** : 80 PV, 5 Mana, 15 Dégâts de base, 0 Armure de base.
- **Mage** : 60 PV, 15 Mana, 10 Dégâts de base, 5 Armure de base.

**Critique :**
- **Pool de Mana excessif :** Avec 10 à 15 points de Mana pour le Paladin et le Mage, et des coûts de cartes moyens de 1 ou 2, le Mana n'est pas une ressource limitante. Un Mage pourrait virtuellement jouer toute sa main à chaque tour sans épuiser sa réserve. Le Berserker, avec ses 5 Mana, est beaucoup plus restreint et dépendra d'une économie différente.
- **Armure de base (Paladin) :** 20 d'armure de base est une valeur colossale. Si cette armure s'applique à chaque tour (ou même juste au début du combat), elle rend le Paladin virtuellement invulnérable contre les menaces mineures (comme le Gobelin ou le Slime) pendant les premiers tours.

## 3. Analyse des Ennemis
Le bestiaire actuel comporte 4 ennemis avec les stats suivantes :
- **Gobelin** : 25 PV / 5 Dégâts
- **Slime** : 10 PV / 5 Dégâts
- **Orc Furieux** : 40 PV / 8 Dégâts
- **Squelette** : 15 PV / 12 Dégâts

**Critique :**
- Les points de vie des ennemis sont très faibles par rapport aux capacités de burst des héros (surtout avec la grande réserve de mana). Un ennemi comme le Squelette (15 PV) peut être éliminé en une seule carte comme `Frappe Lourde` (14 dégâts) avec n'importe quel boost, ou deux `Frappe` basiques.
- Le Squelette est un "Glass Cannon" extrême : 12 dégâts par attaque représentent une menace énorme pour le Mage (60 PV max, soit 20% de sa vie en un coup), mais reste triviale pour le Paladin grâce à ses 20 d'armure de base.
- L'écart de puissance offensive (5 à 12 dégâts) et défensive (10 à 40 PV) manque de lissage et de notion de progression (ex: Acte 1 vs Acte 3).

## 4. Analyse des Cartes
L'analyse des valeurs nominales (sans prendre en compte les synergies) :
- **Valeur du Mana (Coût vs Effet) :**
  - La carte basique `Frappe` (1 Mana) inflige 6 dégâts. Ratio : 6 Dégâts / Mana.
  - La carte `Frappe Lourde` (2 Mana) inflige 14 dégâts. Ratio : 7 Dégâts / Mana.
  - La carte `Défense` (1 Mana) donne 5 Armure. Ratio : 5 Armure / Mana.
  - `Mur de Fer` (2 Mana) donne 12 Armure. Ratio : 6 Armure / Mana.

**Critique :**
- **Déséquilibre Dégâts/Armure :** Historiquement dans ce genre de jeu, générer de l'armure est souvent légèrement plus "coûteux" ou au pire égal aux dégâts. Ici, les monstres infligent jusqu'à 12 de dégâts, ce qui nécessite 2 à 3 cartes de Défense (2 à 3 Mana) pour bloquer une seule attaque.
- **Cartes utilitaires sous-évaluées :** `Attaque Rapide` coûte 0 Mana pour 3 dégâts et 1 pioche. Cette carte génère un avantage en "Card Advantage" sans aucun coût en mana, ce qui est extrêmement (voire trop) fort, surtout combiné aux réserves de mana de 10-15 des héros. 
- **Soin :** `Potion de Soin` coûte 2 Mana pour rendre 8 PV. Bien qu'elle soit "Rare", dans un jeu roguelike, soigner de manière répétable en combat est une mécanique dangereuse qui casse la notion de survie à long terme, d'autant que le Paladin a déjà beaucoup de survivabilité.

## 5. Problèmes Structurels Majeurs Identifiés
1. **L'Économie de Mana est cassée :** Les valeurs de mana des héros (5 à 15) ne correspondent pas à l'échelle de coût des cartes (0 à 3). La ressource limitante actuelle est plutôt la *Taille de la main* et la *Pioche* que le Mana lui-même.
2. **Polarisation de la Difficulté :** Les capacités de base des héros trivialisent les combats basiques. Le Paladin n'a besoin d'aucune carte d'armure pour survivre aux ennemis normaux. Le Berserker (0 armure, mais 15 dégâts de base ?) risque de mourir très vite face aux Squelettes s'il ne les tue pas au premier tour.
3. **Le ratio Dégâts/PV est en faveur du joueur :** Les ennemis manquent de statistiques défensives pour survivre à un tour de burst d'un héros ayant 10 ou 15 points de mana.

## 6. Pistes de Solutions et Recommandations
- **Refonte des valeurs de Mana :** 
  - Standardiser le mana de départ pour tous les héros (ex: 3 ou 4 par tour), et moduler les coûts des cartes en conséquence.
  - Si le système de mana est fait pour être cumulatif ou élevé (façon Hearthstone ou RPG classique), alors il faut augmenter considérablement la vie des ennemis (Multiplier par 3 ou 4) et le coût de certaines cartes fortes.
- **Rééquilibrage de l'Armure de base :**
  - Remplacer l' "Armure de Base" (20 pour le Paladin) par un trait passif plus équilibré (ex: "Gagne 2 d'Armure à la fin de chaque tour" ou "Commence le combat avec 10 d'Armure temporaire").
- **Ajustement de la Courbe des Ennemis :**
  - Revoir le "Squelette" pour réduire ses dégâts à 8-9 et augmenter un peu ses PV pour éviter qu'il ne soit trop punitif ou trop trivial.
- **Nerf / Buff de Cartes :**
  - `Attaque Rapide` (0 Mana) devrait perdre sa pioche, ou coûter 1 Mana pour devenir un cycle neutre.
  - S'assurer que les cartes de soin sont consommables (exhaust/épuisement) pour éviter de faire durer un combat indéfiniment juste pour se soigner.
