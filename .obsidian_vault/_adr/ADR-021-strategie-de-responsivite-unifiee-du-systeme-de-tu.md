## 📱 ADR-021 : Stratégie de Responsivité Unifiée du Système de Tutoriel (Unified Tutorial Responsiveness Strategy)

### Statut
✅ Accepté & Implémenté

### Contexte
Le système de tutoriel original composé de 13 illustrations et interacteurs souffrait de sévères contraintes de mise en page. Sur les écrans de smartphones de faible largeur ou lors de l'utilisation du mode paysage sur mobile (faible hauteur verticale disponible, ~360px), les contraintes fixes de flexibilité et les coordonnées de positionnement absolues provoquaient des erreurs de contraintes de boîte ("Yellow-Black Stripes") et masquaient le texte ou les éléments interactifs.

### Décision
Établir et appliquer de façon systématique quatre patrons de responsivité à l'échelle de l'ensemble des 13 widgets du tutoriel :
1. **FittedBox Canvas Scaling Pattern** : Pour les widgets s'appuyant sur des coordonnées de positionnement absolues ou des animations complexes (`Map`, `Combat Overview`, `Play Card`, `Merge`, `Armor`), envelopper le conteneur principal à taille fixe (ex: `SizedBox(width: 360, height: 260)`) dans un widget `FittedBox` configuré avec `fit: BoxFit.contain`. Cela force l'illustration à s'échelonner comme un graphique vectoriel unique proportionnellement à l'espace alloué, éliminant tout overflow.
2. **LayoutBuilder Orientation Split Pattern** : Structurer la classe principale `TutorialScreen` de sorte qu'elle détecte l'orientation active via un `LayoutBuilder`. Si l'écran est en mode paysage (largeur > hauteur et hauteur < 500px) ou si la largeur dépasse 720px (mode tablette/bureau), diviser l'écran à l'aide d'un `Row` horizontal (50% pour l'illustration interactive à gauche, 50% pour les descriptions textuelles et les boutons à droite) au lieu du split vertical `Column` par défaut qui écrase l'illustration sur les écrans courts.
3. **Scrollable Container Pattern** : Remplacer l'utilisation de `NeverScrollableScrollPhysics` par `BouncingScrollPhysics` et injecter des conteneurs `SingleChildScrollView` élastiques sur les descriptions ou les grilles pour autoriser l'utilisateur à scroller en cas de réduction drastique de la hauteur d'écran.
4. **Adaptive Columns & Wraps** : Utiliser le widget `Wrap` (ex. pour la légende des raretés de reliques ou les types de nœuds) et des listes déroulantes horizontales (pour la main de cartes ou les choix de draft) afin que les cellules s'écoulent naturellement en fonction de la largeur disponible. Réorganiser les types de nœuds en grille compacte 3x2.

### Preuves dans le code
- `lib/tutorial/tutorial_screen.dart` : Exploitation de `LayoutBuilder` et aiguillage vers la structure `Row` ou `Column` selon le ratio d'aspect.
- `lib/tutorial/widgets/` :
  - `tutorial_map_widget.dart` et `tutorial_combat_overview_widget.dart` : Utilisation combinée de `SizedBox` de taille de référence et de `FittedBox(fit: BoxFit.contain)`.
  - `tutorial_node_types_widget.dart` : Grille flexible reconfigurée en 3x2 avec support du défilement.
  - `tutorial_relics_widget.dart` : Remplacement du layout `Row` horizontal rigide des raretés par un `Wrap` adaptatif.

### Conséquences
- ✅ **Compatibilité universelle multi-plateforme** : Le tutoriel s'affiche de manière premium sur toutes les résolutions d'écran sans aucun bug visuel ou texte rogné.
- ✅ **Expérience Mobile Paysage Premium** : Le split horizontal évite l'écrasement vertical des illustrations, préservant la lisibilité sur smartphone tenu à l'horizontale.
- ⚠️ **Surcharge légère d'encapsulation** : Obligation d'utiliser un gabarit de conteneur virtuel (`SizedBox`) sur les widgets canvas pour assurer la stabilité du `FittedBox`.
