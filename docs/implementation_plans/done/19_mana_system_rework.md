# Phase 19 : Refonte et Équilibrage du Système de Mana

## 1. Analyse Approfondie du Problème

Dans l'état actuel de *Hero's Draft*, l'économie de mana est structurellement déséquilibrée. Les héros disposent d'une réserve de mana très élevée (10 pour le Paladin, 15 pour le Mage) par rapport au coût moyen des cartes (qui oscille entre 0 et 3). 

**Conséquences directes en jeu :**
- **Absence de choix stratégique :** Le joueur n'a quasiment jamais à choisir entre jouer une carte d'attaque ou de défense, car sa réserve de mana lui permet de jouer l'intégralité de sa main à chaque tour.
- **Ressources limitantes erronées :** Le goulot d'étranglement actuel est la taille de la main et la pioche, rendant le mana obsolète en tant que mécanique de restriction.
- **Identité de classe biaisée :** Le Berserker, avec ses 5 points de mana, est le seul à ressentir une véritable contrainte, ce qui le désavantage structurellement par rapport au Mage et au Paladin.

## 2. Pistes de Solutions Détaillées

Pour résoudre ce problème, deux grandes philosophies de game design s'offrent à nous.

### Option A : Le Modèle "Deckbuilder Roguelike" Standard (Recommandé)
Ce modèle (utilisé par *Slay the Spire* ou *Monster Train*) impose une contrainte stricte et constante.
- **Principe :** Tous les héros commencent le combat avec un montant de mana maximum fixe (ex: 3 Mana par tour). Ce mana est rafraîchi au début de chaque tour, et le surplus non utilisé est perdu.
- **Avantages :** 
  - Crée une tension immédiate : chaque carte jouée est un choix tactique.
  - Facilite grandement l'équilibrage des cartes (une carte à 2 ou 3 de mana a un impact massif).
  - L'identité de classe se fait par les effets des cartes et des passifs, non par la réserve de mana.
- **Impacts :** Les coûts actuels des cartes (0, 1, 2) sont déjà adaptés à ce modèle. Il faut surtout baisser drastiquement le mana des héros.

### Option B : Le Modèle "RPG / TCG" (Type Hearthstone)
Ce modèle propose une montée en puissance progressive au cours d'un même combat.
- **Principe :** Le joueur commence le combat avec 1 Mana. À chaque tour, son maximum augmente de 1, jusqu'à une limite (ex: 10). Le mana est rafraîchi à chaque tour.
- **Avantages :** 
  - Permet de concevoir des cartes "Ultimes" très puissantes coûtant 8, 9 ou 10 de mana, impossibles à jouer en début de combat.
  - Donne un rythme croissant aux combats.
- **Impacts :** Nécessite de revoir l'intégralité des points de vie des ennemis (à multiplier par 3 ou 4) pour s'assurer que les combats durent assez longtemps pour atteindre les hauts niveaux de mana. Il faut également créer un tout nouveau set de cartes à coût élevé.

### Option C : Le Modèle "Ressource Persistante"
- **Principe :** Le mana ne se régénère pas (ou très peu, ex: +1 par tour) entre les tours, mais le joueur possède une grande réserve (ex: 20). Certaines cartes permettent de "gagner" du mana.
- **Inconvénients :** Très complexe à équilibrer sur un format roguelike, risque d'effets boule de neige.

## 3. Plan d'Implémentation Étape par Étape (Basé sur l'Option A)

La recommandation est de partir sur l'**Option A**, qui correspond le mieux au genre actuel du jeu et nécessite le moins de refonte totale des cartes existantes.

### Étape 1 : Mise à jour des données JSON (Héros)
- **Fichier ciblé :** `assets/data/heroes.json`
- **Action :** Uniformiser la propriété `mana` ou `maxMana` pour tous les héros à une valeur standard, par exemple **3**.
  - *Note additionnelle :* Si l'on souhaite garder une identité asymétrique légère, le Mage pourrait avoir 4 de mana mais moins de PV, tandis que le Berserker pourrait avoir 3. Cependant, 3 pour tout le monde est le point de départ idéal.

### Étape 2 : Adaptation de la logique de combat dans Riverpod
- **Fichiers ciblés :** `lib/game/controllers/run_controller.dart` (ou équivalent gérant l'état du combat).
- **Actions :**
  - S'assurer qu'au début de **chaque tour du joueur**, la valeur de mana courante est réinitialisée à sa valeur maximale (`maxMana` défini par le héros).
  - Retirer toute mécanique qui permettrait au mana de se cumuler d'un tour à l'autre, à moins qu'il ne s'agisse d'un buff spécifique ("Conserve son mana au prochain tour").

### Étape 3 : Rééquilibrage et Audit des Cartes
- **Fichier ciblé :** `assets/data/cards.json`
- **Actions :**
  - Puisque le mana maximum par tour est maintenant de 3, une carte coûtant 2 consomme 66% du tour.
  - Vérifier que `Frappe Lourde` (coût 2, 14 dégâts) est correctement balancée par rapport à jouer deux fois `Frappe` (coût 1x2, 6x2 = 12 dégâts).
  - Ajuster les cartes "gratuites" : Une carte coûtant 0 (comme `Attaque Rapide`) devient extrêmement précieuse. Elle ne devrait pas donner un avantage en cartes (supprimer l'effet de pioche ou la passer à coût 1).

### Étape 4 : Ajout de mécaniques de gain de Mana
- **Actions :** Créer de nouvelles cartes ou reliques ("Items") qui permettent de manipuler le mana.
  - Exemple de carte (Type Compétence) : *Concentration* - Coût 0. Gagnez 1 de Mana ce tour-ci. Épuisement (Exhaust).
  - Ceci apporte de la profondeur stratégique à l'économie de base très stricte.

### Étape 5 : Mise à jour de l'Interface Utilisateur (UI)
- **Fichiers ciblés :** `lib/ui/game_screen.dart` ou les widgets de l'HUD.
- **Actions :**
  - Mettre en évidence la jauge de Mana (ex: 3 sphères ou cristaux qui s'allument/s'éteignent) plutôt qu'un simple texte "10/10", puisque la valeur sera maintenant petite et discrète.
  - Ajouter un effet visuel ("shake" ou clignotement rouge) sur les cartes en main qui coûtent plus de mana que ce que le joueur possède, pour bien indiquer qu'elles sont injouables (et bloquer l'interaction si ce n'est pas déjà le cas).

## 4. Critères de Validation
- [ ] Le `heroes.json` a été mis à jour avec des valeurs de mana à 3.
- [ ] En jeu, le joueur commence son tour avec 3 de mana. Jouer des cartes déduit ce mana.
- [ ] Finir le tour avec du mana restant ne le transfère pas au tour suivant (retour à 3/3 au tour d'après).
- [ ] L'interface met correctement à jour l'état du mana en temps réel.
- [ ] La commande `dart analyze` ne remonte aucune erreur sur le nouveau code.
- [ ] Un test unitaire (`flutter test`) vérifie la remise à zéro du mana lors d'un changement de tour.
