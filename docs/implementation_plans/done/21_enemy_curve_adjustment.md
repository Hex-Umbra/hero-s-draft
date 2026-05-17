# Phase 21 : Ajustement de la Courbe de Difficulté des Ennemis

## 1. Analyse Approfondie du Problème

Les ennemis actuels présentent des disparités qui rendent la progression chaotique plutôt que fluide et croissante.

**Conséquences directes en jeu :**
- **"Glass Cannon" extrême :** Le Squelette, avec ses 15 PV et 12 de dégâts, est symptomatique d'un équilibrage en "tout ou rien". Soit le joueur a de quoi le tuer tour 1 (ce qui est facile avec 15 PV), soit il subit des dégâts massifs (20% des PV du Mage).
- **Rapport PV/Dégâts déséquilibré :** Les ennemis manquent globalement de PV. Avec l'ancienne économie de mana très généreuse, ils mouraient presque tous au tour 1. Même avec la refonte du mana (Phase 19), 10 PV pour le Slime et 15 pour le Squelette restent très faibles face à des cartes qui infligent facilement 6 à 14 dégâts.
- **Absence de notion de paliers (Actes) :** Les statistiques actuelles ne permettent pas de définir clairement quel ennemi appartient au début de partie et lequel est un challenge de milieu de partie.

## 2. Pistes de Solutions Détaillées

### Lissage de la Courbe d'Apprentissage et de Difficulté
Il est nécessaire de redéfinir le rôle de chaque ennemi :
- **Ennemi "Chair à canon" (Slime) :** Peu de dégâts, peu de PV. Sert à s'échauffer et tester des combos.
- **Ennemi "Mur" (Orc Furieux) :** Dégâts modérés mais réguliers, beaucoup de PV. Teste l'endurance et la génération de dégâts sur la durée du joueur.
- **Ennemi "Punisseur" (Squelette) :** Dégâts élevés, PV modérés. Teste la capacité de génération d'armure d'urgence et le burst ciblé.

### Ajustements Numériques Proposés
Pour correspondre à l'économie de mana standardisée (3 par tour) et aux cartes actuelles :
- **Slime :** PV augmentés de 10 à **18**. Dégâts réduits de 5 à **4**. (Survit souvent à un tour 1).
- **Gobelin :** PV augmentés de 25 à **28**. Dégâts maintenus à **5**. (Équilibre standard).
- **Squelette :** PV augmentés de 15 à **22**. Dégâts réduits de 12 à **8** ou **9**. (Moins de "One shot", nécessite plus de gestion de l'armure).
- **Orc Furieux :** PV augmentés de 40 à **50**. Dégâts maintenus à **8**. (Fait figure d'Élite ou de boss mineur).

## 3. Plan d'Implémentation Étape par Étape

### Étape 1 : Audit et Modification du fichier des Ennemis
- **Fichier ciblé :** `assets/data/enemies.json`.
- **Actions :**
  - Appliquer les ajustements numériques ci-dessus sur les PV et les Dégâts de chaque type d'ennemi.
  - Ajouter éventuellement un champ `tier` ou `act` dans la structure JSON pour commencer à classer les ennemis par difficulté, préparant le terrain pour une génération procédurale plus intelligente des rencontres.

### Étape 2 : Ajout d'Intentions (Intents) Variables
- **Fichiers ciblés :** `lib/models/data/enemy.dart`, `RunController`.
- **Actions :**
  - Pour éviter que l'Orc Furieux ne fasse 8 de dégâts à CHAQUE tour de manière monotone, implémenter un système d'Intentions basique (ex: Tour 1: Attaque, Tour 2: Se buff, Tour 3: Grosse Attaque).
  - Cela brise la prévisibilité totale et force le joueur à s'adapter (bloquer les tours d'attaque, attaquer lors des tours de buff).

### Étape 3 : Tests de Combat (Playtesting automatisé ou manuel)
- **Actions :**
  - Lancer le jeu avec le héros standard (Mage ou Berserker).
  - Vérifier qu'un combat contre un Squelette prend généralement 2 à 3 tours et que les dégâts subis sans armure sont punitifs mais pas fatals immédiatement.
  - Ajuster les valeurs de manière itérative si nécessaire.

## 4. Critères de Validation
- [ ] Le fichier `enemies.json` a été mis à jour avec la nouvelle grille de PV et de Dégâts.
- [ ] Les ennemis survivent globalement au moins un tour face à un héros ayant 3 de mana.
- [ ] Le burst de dégâts du Squelette est lissé, le rendant moins aléatoirement fatal.
- [ ] Le jeu compile correctement et la sérialisation JSON des ennemis fonctionne.
