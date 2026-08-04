## 🎡 ADR-042 : Protection Anti-Spoil dans le Carrousel de Reliques & Décoration Dynamique (Relic Carousel Rarity Masking & Polish)

### Statut
✅ Accepté & Implémenté (v0.1.4)

### Contexte
Le système de carrousel de récompense de reliques (`RelicRewardCarouselOverlay`) simule une machine à sous pour introduire du suspense. Cependant, dans la version précédente, les cartes du carrousel affichaient dès le départ la couleur de leur rareté, le nom réel de la relique et ses badges d'effets/déclencheurs. Cela gâchait l'effet de surprise ("spoil"), car le joueur devinait instantanément la relique cible et sa rareté pendant le spin.

### Décision
Mettre en place un masquage d'informations tant que le carrousel tourne :
1. **État local de Masquage (`isWon`)** :
   - Passer un paramètre booléen `isWon` à `RelicCarouselCard`.
   - Tant que `isWon` est faux (le carrousel est en cours de spin) :
     - La bordure et l'arrière-plan de la carte de relique sont grisés/neutres (`AppColors.neutralGrey`).
     - Les badges de rareté et de déclencheur affichent textuellement « ??? » sur fond gris neutre.
     - Le titre de rareté de l'en-tête supérieur du dialogue est masqué.
2. **Animation de Révélation au Point d'Arrêt** :
   - Lorsque le carrousel ralentit et s'immobilise sur le gagnant, le drapeau `isWon` passe à vrai.
   - Les vraies couleurs de rareté de la carte s'allument avec un effet de lueur.
   - Le texte de description, le nom réel (coloré selon la rareté) et les badges techniques de déclencheurs sont révélés de manière dynamique.
   - L'en-tête supérieur de la page s'anime pour afficher fièrement la rareté correspondante.

### Preuves dans le code
- `lib/ui/widgets/relic_carousel/relic_carousel_card.dart` : Rendu conditionnel basé sur `isWon`, utilisation d'une bordure grise neutre si faux, affichage de "???" pour les badges, et coloration textuelle du nom selon la rareté si vrai.
- `lib/ui/widgets/relic_carousel/relic_carousel_screen.dart` : Masquage du sous-titre de rareté en cours de rotation, activation progressive à la complétion.

### Conséquences
- ✅ **Suspense Décuplé** : Le joueur assiste à un défilement de silhouettes grises anonymes et ne découvre la relique exacte et sa valeur qu'à la frame précise de l'arrêt, maximisant le plaisir de la récompense.
- ✅ **Clarté UX** : L'accentuation par couleur de rareté uniquement sur l'objet gagné clarifie visuellement la transaction.
