## 🎨 ADR-050 : Animation Dynamique des Particules du Carrousel de Reliques (v0.1.7)

### Statut
✅ Accepté & Implémenté (v0.1.7)

### Contexte
1. L'overlay de carrousel de reliques (`RelicRewardCarouselOverlay` / `RelicCarouselScreen`) comportait une célébration visuelle de victoire générant des particules dessinées sur Canvas. Cependant, à la fin de la rotation (onLand), ces particules étaient figées/immobiles à l'écran car aucun mécanisme d'animation temporelle n'actualisait leur position et leur opacité à chaque frame.
2. L'absence de mouvement brisait le ressenti de jus visuel ("visual juice") recherché pour cette transition critique.

### Décision
1. **Contrôle via AnimationController** : Intégrer un `AnimationController` dédié nommé `_particleAnimationController` avec une durée de 1800ms dans `RelicCarouselScreenState`. Un écouteur (`addListener`) y est rattaché pour déclencher un `setState` à chaque rafraîchissement d'écran.
2. **Initialisation des Particules** : À l'instant exact où le carrousel s'immobilise sur la relique gagnante (`onLand`), peupler la liste de 55 particules avec des angles aléatoires ($0 \rightarrow 2\pi$), des vitesses initiales radiales ($150 \rightarrow 500$), des tailles ($3 \rightarrow 8$px) et des opacités de départ ($0.6 \rightarrow 1.0$). Lancer immédiatement le contrôleur via `_particleAnimationController.forward(from: 0.0)`.
3. **Formules de Physique Canvas** : Dans la méthode `draw` de la classe `_Particle`, appliquer les paramètres physiques suivants interpolés par la progression du contrôleur (allant de 0.0 à 1.0) :
   - *Friction/Traînée* : `final double distance = speed * progress * (1.0 - 0.5 * progress)` limitant la distance radiale finale.
   - *Gravité* : `final double gravityY = 250.0 * progress * progress` tirant les particules vers le bas.
   - *Fondu d'Opacité* : `final double currentOpacity = (initialOpacity * (1.0 - progress)).clamp(0.0, 1.0)`.
4. **IgnorePointer & CustomPaint** : Dessiner l'overlay de particules à l'aide d'un widget `CustomPaint` enveloppé dans un `IgnorePointer` pour ne pas intercepter les interactions utilisateur sur l'écran.

### Preuves dans le code
- `lib/ui/widgets/relic_carousel/relic_carousel_screen.dart` : Définition de `_particleAnimationController`, instanciation de la liste de particules dans `_startSpin().then()`, et implémentation de la physique dans `_Particle.draw()`.

### Conséquences
- ✅ **Sensation Premium Renforcée** : L'explosion de confettis/particules de couleur de rareté est fluide, dynamique, et retombe élégamment vers le bas de l'écran tout en s'estompant.
- ✅ **Respect du Cycle de Vie** : Le contrôleur est correctement libéré via `dispose()` pour éviter toute fuite de mémoire.
