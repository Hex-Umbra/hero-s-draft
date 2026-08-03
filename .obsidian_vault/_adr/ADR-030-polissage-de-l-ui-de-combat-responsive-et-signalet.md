## 🎨 ADR-030 : Polissage de l'UI de Combat Responsive et Signalétique de Ciblage Localisée (Combat UI Polish & Sizing)

### Statut
✅ Accepté & Implémenté

### Contexte
L'arène de combat Flame et l'interface utilisateur Flutter (HUD) présentaient des problèmes d'affichage sur des terminaux aux rapports d'aspect variés. Le HUD joueur de combat (Mana, PV, Armure) subissait parfois des chevauchements ou des troncatures. De plus, la signalétique de ciblage des cartes (Single Target, AoE, Self) n'était pas bilingue et risquait de déborder sur les petits écrans. Enfin, les cartes d'ennemis sur le plateau Flame possédaient une taille uniforme ne reflétant pas leur dangerosité relative, et l'accès au deck ou aux reliques depuis la carte du monde manquait de repères visuels clairs.

### Décision
1. **HUD de Combat Responsive Clamped** :
   - Rendre le panneau de statistiques du joueur et des compétences réactif à la hauteur et à la largeur de l'écran en utilisant `MediaQuery` et des facteurs de mise à l'échelle.
   - Appliquer des contraintes de clamping sur les hauteurs et largeurs des conteneurs pour préserver la lisibilité sans clipping sur les tablettes et les mobiles étroits.
2. **Badges de Ciblage de Cartes FittedBox Wrapped** :
   - Ajouter un badge visuel sur la face avant de chaque carte unifiée `UiCard` indiquant son mode de ciblage (`_resolveTarget`).
   - Mapper les types d'effets pour obtenir un label textuel bilingue ('Cible unique', 'Tous les ennemis', 'Soi-même' en français / 'Single Target', 'All Enemies', 'Self' en anglais).
   - Envelopper le texte du badge dans un composant `FittedBox` pour forcer la mise à l'échelle automatique du texte et interdire tout débordement en dehors du badge physique.
3. **Badges et Indicateurs de Navigation sur la Carte** :
   - Ajouter un badge d'inventaire dynamique sur le bouton Reliques de la `MapScreen` montrant en temps réel le nombre de reliques collectées.
   - Intégrer un badge numérique sur le bouton Deck de la carte, affichant à tout moment le nombre actuel de cartes dans le master deck du joueur.
4. **Scaling Échelle des Ennemis** :
   - Modifier l'échelle visuelle (`scale`) des cartes d'ennemis (`EnemyCard`) en fonction de leur niveau de menace et de leur type (Elite ou Boss) pour donner une impression de grandeur et de puissance relative sur le plateau Flame.

### Preuves dans le code
- `GameScreen` : Layouts flexibles du HUD utilisant des contraintes proportionnelles aux dimensions de l'écran.
- `UiCard._resolveTarget` et `_buildTargetIcon` : Construction dynamique des icônes et textes bilingues de ciblage enveloppés de `FittedBox`.
- `MapScreen` : Badge numérique sur le bouton reliques (`relics.length`) et badge numérique sur le bouton de deck (`deck.length`).
- `EnemyCard` : Application de facteurs de scale personnalisés lors de l'initialisation du composant graphique.
- Validation complète et absence totale d'erreurs statiques sous `dart analyze`.

### Conséquences
- ✅ **Lisibilité universelle** : L'adaptation responsive assure un rendu professionnel et sans clipping sur l'ensemble de la gamme d'appareils testés.
- ✅ **Guidage utilisateur amélioré** : Les badges bilingues de ciblage et les indicateurs d'inventaire guident immédiatement le joueur sur les actions possibles.
- ✅ **Game Feel Premium** : Le scaling des sprites d'ennemis renforce visuellement la structure dramatique des rencontres de combat.
