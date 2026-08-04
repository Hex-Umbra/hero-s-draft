## 🎨 ADR-020 : Feedback de Focus de Récompenses (Hover & Selection Glow Visual Feedback in Draft Screen)

### Statut
✅ Accepté & Implémenté

### Contexte
La sélection de cartes de récompenses dans l'écran de Draft standard et le draft du tutoriel manquait de retour sensoriel et tactile. Le joueur pouvait avoir des difficultés à repérer la carte survolée et celle activement choisie avant confirmation.

### Décision
Mettre en place un pipeline d'animations de focus partagé entre le tutoriel et le jeu de production :
- **Survol (Hover)** : Envelopper les cartes de choix dans une `MouseRegion` et appliquer un `AnimatedScale` pour modifier dynamiquement l'échelle à `1.05x` en 200ms lors du survol.
- **Sélection (Selection)** : En cas de tap ou clic actif, faire grossir la carte sélectionnée à `1.12x` et lui attribuer une surbrillance dorée intense via une décoration `BoxShadow` de couleur `Colors.amber` avec un rayon de flou de 16px et une extension de 3px.
- **Confirmation Sécurisée** : Conserver la carte en état sélectionné/grossi jusqu'à ce que le joueur appuie sur le bouton de validation de draft pour valider la transition.

### Preuves dans le code
- `lib/tutorial/widgets/tutorial_draft_widget.dart` : Implémentation complète avec `MouseRegion`, `AnimatedScale`, et lueur dorée BoxShadow.
- `lib/ui/screens/draft_screen.dart` / `lib/ui/widgets/relic_carousel/draft_card_reel.dart` : Intégration des effets de focus similaires pour le Draft de production.

### Conséquences
- ✅ **Amélioration immédiate du game feel** : La sélection devient agréable et offre une rétroaction instantanée sur les intentions de l'utilisateur.
- ✅ **Accessibilité accrue** : Le contraste visuel de la lueur dorée et l'échelle augmentée identifient sans équivoque la carte cible active.
