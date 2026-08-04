## ⚔️ ADR-022 : Ciblage Interactif en Deux Phases et Clarté des Info-bulles (Two-Phase Targeting & Canvas Cards Tooltips)

### Statut
✅ Accepté & Implémenté

### Contexte
Le système de tutoriel initial possédait des étapes interactives simplifiées qui ne reflétaient pas pleinement la dynamique fine du système de ciblage et de description des effets de statut du jeu de production. L'étape 6 (Play Card) n'illustrait pas les cas de sélection de cibles multiples (ennemi vs héros), et l'étape 5 (Cards & Mana) affichait des descriptions textuelles plates dépourvues des icônes vectorielles et des info-bulles présentes en combat réel.

### Décision
1. **Interactive Two-Phase Targeting** : À l'étape 6, implémenter une séquence interactive obligeant le joueur à comprendre les deux directions possibles de ciblage. Phase 1 : glisser et déposer la carte d'attaque offensive sur le Slime cible. Phase 2 : glisser la carte d'armure défensive sur le portrait du Héros (soi-même). La progression n'est déverrouillée qu'une fois les deux gestes complétés avec succès.
2. **True Canvas Vector Icons & Tooltips** : À l'étape 5, refactoriser le rendu des cartes de démonstration en remplaçant les chaînes plates par les vraies icônes vectorielles dessinées sur le Canvas Flutter (Épée, Bouclier, Poison). De plus, intégrer un système de détection de clic/hover qui affiche des info-bulles descriptives localisées détaillant précisément les règles mécaniques de chaque effet de combat.
3. **Alignement du Combat Overview** : Repositionner et calibrer les lignes d'annotation à l'étape 4 pour qu'elles s'alignent précisément sur les coordonnées du HUD de combat réel.

### Preuves dans le code
- `lib/tutorial/widgets/tutorial_play_card_widget.dart` : Logique de ciblage intégrant une machine à états locale (Phases de jeu d'attaque puis de défense) avec validation des cibles.
- `lib/tutorial/widgets/tutorial_cards_widget.dart` : Remplacement des rendus statiques par l'affichage d'icônes Canvas vectorielles et insertion de widgets d'info-bulles tactiles.
- `lib/tutorial/widgets/tutorial_combat_overview_widget.dart` : Ajustement millimétré des positions absolues des conteneurs d'annotations et réduction de la taille des cartes représentées.

### Conséquences
- ✅ **Fidélité d'apprentissage optimale** : Le joueur appréhende les gestes complexes de ciblage de production de manière sûre dans un bac à sable isolé.
- ✅ **Expérience utilisateur immersive** : Les info-bulles et les icônes de haute qualité vectorielle améliorent instantanément la qualité perçue du jeu.
