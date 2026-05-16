# Plan d'Implémentation 16 : Polissage Visuel et Corrections de Bugs

Ce document détaille le plan pour implémenter les correctifs et améliorations issus des idées d'amélioration (`docs/possible_upgrades/upgrade_ideas.md`). L'objectif est d'améliorer la clarté de l'interface, d'intégrer de nouveaux assets visuels et de corriger des problèmes de navigation.

## Phase 1 : Clarté des Indicateurs et Statistiques (UI/UX)

L'objectif est de rendre les informations de combat plus lisibles et compréhensibles pour le joueur au premier coup d'œil.

### 1.1 Clarification de l'Indicateur des Ennemis
- **Problème :** Le joueur peut ne pas comprendre quand l'action indiquée sera exécutée.
- **Action :** Revoir le design du `IntentionIndicator` au-dessus des ennemis.
- **Action :** Ajouter la mention explicite "Prochaine action :" ou "Next action :" pour indiquer clairement que cela correspond à ce que fera l'ennemi à la fin du tour.
- **Action :** Afficher des valeurs claires à côté des icônes d'intention (ex: montant exact des dégâts que l'ennemi va infliger).
- **Action :** S'assurer que les couleurs d'intention contrastent bien avec l'arrière-plan du jeu.

### 1.2 Amélioration de l'Affichage des Statistiques
- **Problème :** Les statistiques (Armure, Force, etc.) des personnages et ennemis ne sont pas assez claires.
- **Action :** Améliorer le design visuel des badges de statistiques (`StatBadge`) sur les cartes des entités (icônes plus grandes, couleurs plus distinctes).
- **Action :** Améliorer le système de tooltips (`onLongTapDown`) pour fournir une description exhaustive de toutes les statistiques actuelles (base + modificateurs) de l'entité survolée.

---

## Phase 2 : Enrichissement Visuel

L'objectif est d'intégrer les assets définitifs pour remplacer les placeholders.

### 2.1 Intégration des Assets Visuels (Aseprite)
- **Action :** Intégrer les nouvelles images en pixel-art créées par l'utilisateur pour les cartes du Berserker et du Mage.
- **Action :** Intégrer les nouvelles images en pixel-art pour chaque type d'ennemi.
- **Note :** Aucun son ne sera ajouté dans cette phase. L'effort porte uniquement sur le remplacement des images.

---

## Phase 3 : Correction de Bugs (Navigation Map)

L'objectif est de corriger le comportement erratique de la carte lors du déplacement.

### 3.1 Résolution du Bug de Drag sur la Map
- **Problème :** La carte se remet à gauche lors d'un "drag" vers le haut sur certains écrans.
- **Action :** Inspecter l'implémentation de l'`InteractiveViewer` dans le `MapScreen`.
- **Action :** Vérifier les paramètres de `boundaryMargin`, `constrained`, et `minScale`/`maxScale` qui pourraient forcer un recadrage indésirable de la caméra.
- **Action :** Si nécessaire, envelopper l'`InteractiveViewer` dans une contrainte spatiale fixe ou ajuster les dimensions du `CustomPainter` de la carte.
- **Action :** Tester le drag sur plusieurs ratios d'écran (notamment en mode portrait sur mobile).
