## 🎰 ADR-017 : Système Interactif de Révélation de Cartes par Rouleaux 3D (Staggered Draft Slots & Reels)

### Statut
✅ Accepté & Implémenté

### Contexte
Lors de la sélection du deck de départ ou de l'obtention de cartes de draft après une victoire, l'affichage instantané et plat des choix de cartes manquait grandement de "game feel", de dynamisme et d'attrait visuel. Pour transformer l'acquisition de nouvelles cartes en un moment fort et tactile à forte récompense émotionnelle, nous souhaitions concevoir un système inspiré des machines à sous, où chaque slot de carte défile verticalement de manière asynchrone avant de se stabiliser par un effet spectaculaire de rotation 3D (Flip).

### Décision
1. **Composant de Rouleau Individuel (`DraftCardReel`)** :
   - Remplacer l'affichage brut de cartes par trois widgets `DraftCardReel` autonomes.
   - Chaque rouleau simule un défilement vertical ultra-rapide de textures de dos de cartes pour évoquer le suspense d'un tirage.

2. **Révélation Séquentielle Échelonnée (Staggered Stoppage)** :
   - Configurer des délais asynchrones pour l'arrêt de chaque rouleau de gauche à droite afin de rythmer la découverte :
     - **Rouleau 1** : Arrêt et flip à **0.8 seconde**.
     - **Rouleau 2** : Arrêt et flip à **1.4 seconde**.
     - **Rouleau 3** : Arrêt et flip à **2.0 secondes**.
   - Au moment exact de l'arrêt, la carte effectue une rotation 3D à 180° sur l'axe Y pour révéler son identité visuelle unifiée (`UiCard`).

3. **Célébration Temporelle et Visuelle des Raretés Rares/Légendaires** :
   - Si une carte sélectionnée par l'algorithme est de rareté **Épique** ou **Légendaire** :
     - Prolonger délibérément le temps de défilement du rouleau correspondant (+0.8s) pour faire monter le suspense.
     - À l'arrêt, déclencher un effet de secousse de l'écran (`screen-shake`), une explosion radiale de particules d'étoiles dorées et un halo de lumière éclatant sur canvas en arrière-plan.

4. **Architecture Découplée pour l'Audio (Sound Hooks)** :
   - Intégrer des rappels audio `onTick` (bruit sec à chaque changement d'index durant la rotation) et `onLand` (son d'impact lourd lors de l'arrêt) pour autoriser un couplage audio réactif sans lier directement le framework sonore à l'UI visuelle.

### Preuves dans le code
- Widget `DraftCardReel` exploitant un `AnimatedBuilder` pour le flip 3D avec perspective `transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(...)`.
- `DraftScreen` qui instancie les reels avec des décalages temporels de défilement configurés.
- Traitement conditionnel basé sur `CardRarity` pour étendre la durée et émettre des particules de célébration dorées.

### Conséquences
- ✅ **Visual Juice de Niveau Commercial** : La transition post-combat est transformée en une expérience visuelle mémorable et excitante qui valorise le butin.
- ✅ **Découplage Technique Sain** : La couche de présentation Flutter gère ses animations de transition de manière isolée, tout en émettant des hooks prêts pour l'audio et alignés avec les conventions architecturales.
- ⚠️ **Durée du Draft** : La révélation complète requiert un minimum de 2.0 secondes (et plus si célébration légendaire), ce qui peut s'avérer répétitif pour les joueurs aguerris lors de runs successives très rapides. Il est recommandé de conserver ce rythme mais d'analyser la demande des utilisateurs pour un éventuel bouton de raccourci d'affichage immédiat ("Fast Reveal").
