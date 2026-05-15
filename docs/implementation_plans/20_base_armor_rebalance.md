# Phase 20 : Rééquilibrage de l'Armure de Base

## 1. Analyse Approfondie du Problème

Actuellement, l'armure de base fonctionne de manière problématique, particulièrement pour le Paladin qui commence avec 20 points d'armure. 

**Conséquences directes en jeu :**
- **Trivialisation du début de partie :** Avec 20 d'armure, le Paladin peut ignorer complètement les attaques des ennemis des premiers niveaux (comme le Gobelin avec 5 de dégâts ou le Slime avec 5). Il n'y a aucun risque et donc aucune réflexion nécessaire sur la défense.
- **Déséquilibre entre les classes :** Le Berserker ayant 0 d'armure de base subit des dégâts complets dès le début, rendant sa survie beaucoup plus difficile et dépendante de la chance à la pioche.
- **Mécanique statique :** L'armure de base est actuellement une statistique fixe au début du combat. Elle n'encourage pas de gameplay dynamique.

## 2. Pistes de Solutions Détaillées

### Option A : Les "Traits Passifs" (Recommandé)
Au lieu d'une valeur brute d'armure de base, chaque héros possède un "Trait" qui génère de la défense de manière conditionnelle ou progressive.
- **Paladin :** "Gagne 2 d'Armure à la fin de chaque tour" ou "La première fois que vous subissez des dégâts chaque tour, réduisez les de 3".
- **Mage :** "Gagne 1 d'Armure chaque fois que vous jouez une carte Compétence".
- **Berserker :** "Gagne 1 d'Armure pour chaque tranche de 10 PV manquants".
- **Avantages :** Donne une forte identité de gameplay à chaque classe, encourage la synergie avec le deck.

### Option B : "Armure Temporaire" en début de combat
- **Principe :** Le héros commence avec une quantité d'armure (ex: 10 pour le Paladin), mais cette armure est perdue à la fin du premier tour si elle n'est pas consommée par une attaque.
- **Avantages :** Simple à implémenter, protège contre une mauvaise main de départ ("bricking") au tour 1.
- **Inconvénients :** Moins intéressant sur le long terme du combat.

### Option C : Suppression pure et simple
- **Principe :** Tous les héros commencent avec 0 d'armure. La survie dépend uniquement des cartes du deck.
- **Avantages :** Équité totale.
- **Inconvénients :** Gomme une partie de la distinction (le côté "tanky") du Paladin.

## 3. Plan d'Implémentation Étape par Étape (Basé sur l'Option A - Traits Passifs)

La recommandation est d'implémenter un système de Traits Passifs pour remplacer la stat brute `base_armor`.

### Étape 1 : Mise à jour des modèles de données
- **Fichier ciblé :** `lib/models/data/hero.dart` et `assets/data/heroes.json`.
- **Actions :**
  - Remplacer le champ `baseArmor` par un objet ou un enum `passiveTrait` (ex: `Trait.regenArmor`, `Trait.spellArmor`, etc.).
  - Mettre à jour les données JSON pour assigner les nouveaux traits aux héros existants.

### Étape 2 : Création du gestionnaire de Traits (Trait System)
- **Fichiers ciblés :** Un nouveau fichier `lib/game/systems/trait_system.dart` ou une extension dans `RunController`.
- **Actions :**
  - Mettre en place des écouteurs d'événements (Event Listeners) sur les actions du jeu : `onTurnEnd`, `onCardPlayed`, `onDamageTaken`.
  - Implémenter la logique spécifique de chaque trait. Ex: si le héros actuel a le trait `regenArmor`, alors lors de l'événement `onTurnEnd`, ajouter 2 d'armure au joueur.

### Étape 3 : Mise à jour de l'interface
- **Fichiers ciblés :** `lib/ui/game_screen.dart` ou `lib/ui/widgets/hero_avatar.dart`.
- **Actions :**
  - Ajouter une icône de passif visible sur ou à côté de l'avatar du héros.
  - Ajouter un tooltip (infobulle) expliquant l'effet du passif lorsque le joueur laisse son doigt/souris dessus.
  - S'assurer que le gain d'armure passif s'accompagne d'un petit retour visuel ("juice") pour que le joueur comprenne ce qui se passe.

## 4. Critères de Validation
- [ ] La statistique brute d'armure de base est retirée. Le Paladin commence le combat avec 0 d'armure.
- [ ] Le système de Traits est actif : le Paladin gagne son armure en fonction de sa condition (ex: à la fin du tour).
- [ ] L'interface affiche clairement le passif du héros.
- [ ] Aucun plantage lors du déclenchement des événements du système de traits.
