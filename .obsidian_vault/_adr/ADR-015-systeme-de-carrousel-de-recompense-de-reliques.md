## 🎡 ADR-015 : Système de Carrousel de Récompense de Reliques (Interactive Relic Carousel Reward System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans la boucle de gameplay originale, lorsqu'un joueur battait un ennemi élite ou un boss, une relique lui était octroyée de manière instantanée, affichée sous forme d'une alerte Toast standard à l'écran. Cette approche manquait grandement d'impact visuel et de feedback émotionnel ("satisfaction du butin") pour le joueur, un aspect pourtant capital dans les roguelikes premium.

### Décision
Concevoir un écran de célébration et de tirage interactif en plein écran appelé **Relic Carousel Reward System** :
1. **Option B (Présentation en Picker 3 cartes simultanées)** :
   - Plutôt que d'afficher une seule relique au centre, présenter 3 cartes simultanément dans un `PageView` doté d'un `viewportFraction` réduit (~0.7).
   - Les cartes latérales subissent un effet de recul/rétrécissement d'échelle (`0.85x`) et de flou/translucidité (`0.4` d'opacité), tandis que la carte centrale active est mise en avant (échelle `1.0x` et pleine opacité `1.0`) pour un guidage visuel optimal.
2. **Animation de décélération fluide** :
   - Un défilement automatique rapide de type machine à sous est lancé.
   - Il décélère de manière progressive en appliquant une courbe cubique de ralentissement (`Curves.easeOutCubic`) sur une durée de 4,0 secondes pour s'arrêter au pixel près sur la relique cible pré-sélectionnée par le contrôleur de jeu.
3. **Sound Hooks Integration** :
   - Lancer un callback de tick sonore (`onTick`) à chaque changement d'index visuel du carrousel pour simuler le bruit d'une roue de loterie.
   - Lancer un callback d'arrêt final (`onLand`) au moment exact de la stabilisation sur la relique gagnée pour déclencher un son de triomphe.
4. **Option A (Bouton de confirmation « Récupérer »)** :
   - La relique n'est **PAS** ajoutée à l'inventaire lors de la phase de rotation pour éviter toute triche ou incohérence visuelle/métier.
   - Un bouton de confirmation « Récupérer » n'apparaît qu'une fois le carrousel parfaitement arrêté et verrouillé sur sa cible, déclenchant simultanément l'écriture dans l'inventaire (`addRelic`) et la transition sécurisée vers l'écran suivant (Draft ou Carte).
5. **Célébration visuelle vectorielle** :
   - À l'arrêt, un `CustomPainter` de particules vectorielles projette des gerbes d'étoiles dorées et de confettis peints sur le Canvas en arrière-plan de la relique remportée.

### Preuves dans le code
- Classe `RelicRewardCarouselOverlay` (widget de carrousel interactif).
- Utilisation de `Curves.easeOutCubic` et d'une durée de 4,0 secondes dans l'orchestrateur de l'animation de défilement du `PageController`.
- Callbacks `onTick` et `onLand` câblés dans l'animation du carrousel.
- `RelicParticlePainter` pour l'effet de projection de particules de victoire.
- Bouton de confirmation conditionné par `isSpinning == false`.

### Conséquences
- ✅ **Game Feel Premium Exceptionnel** : L'effet de suspense de la machine à sous et l'explosion de confettis transforment l'obtention de reliques en un moment de célébration mémorable.
- ✅ **Respect de l'état logique (ADR-001)** : L'inventaire n'est mis à jour qu'au clic sur « Récupérer », maintenant une cohérence parfaite et empêchant toute perte de données en cas de crash/fermeture intempestive pendant la rotation.
- ✅ **Architecture Audio Orientée Événements** : Les hooks `onTick` et `onLand` sont prêts pour brancher le système audio de façon propre sans couplage visuel.
