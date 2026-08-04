## 🎨 ADR-040 : Harmonie Visuelle & Améliorations de Boutique (Visual Harmony & Shop Improvements)

### Statut
✅ Accepté & Implémenté (v0.1.3)

### Contexte
La version 0.1.3 a introduit des améliorations axées sur l'ergonomie, la clarté visuelle et l'équilibrage de la boutique ("Shop & Economy") :
1. **Exclusion des cartes de rareté unique de la boutique** : Les cartes de rareté `unique` (les cartes de classe des héros) sont conçues pour être acquises via le draft de départ ou la forge, afin de préserver l'équilibre et de forcer des choix d'amélioration stratégiques. Elles risquaient cependant d'apparaître dans les pools de cartes proposés à la vente dans la boutique, créant des déséquilibres d'acquisition (Item #103).
2. **Identification visuelle lente en main/boutique** : Auparavant, les cartes de tous types (Attaque, Compétence, Pouvoir, Statut) partageaient le même arrière-plan générique sombre, ce qui ralentissait l'identification à la volée. L'UX en combat et dans la boutique exigeait une différenciation sémantique plus claire (Item #115).
3. **Erreurs de mise en page en boutique** : L'affichage des cartes en vente dans la boutique souffrait de défauts d'alignement ou d'overflow sur différents facteurs de forme, nécessitant un réalignement propre sous forme de grille uniforme et fluide (Item #99).

### Décision
1. **Exclusion des cartes uniques de la boutique** :
   - Mettre à jour la méthode helper `_getEligibleCards` dans `ShopController` pour filtrer à la fois les cartes de type `status` et celles de rareté `CardRarity.unique`.
   - Garantir que lors de l'initialisation initiale (`initializeShop`), du renouvellement (`rerollCards`), ou de l'expansion de boutique (`expandShop`), aucune carte de classe unique ne soit tirée au sort.
2. **Coloration d'arrière-plan par type dans `UiCard`** :
   - Ajouter la méthode helper `_getTypeColor()` renvoyant les couleurs d'accent de type : `Colors.redAccent` (Attaque), `Colors.blueAccent` (Compétence), `Colors.amber` (Pouvoir), `Colors.blueGrey` (Statut).
   - Ajouter la méthode helper `_getBackgroundColor()` renvoyant les couleurs de fond associées : `Color(0xFF4A1D1D)` (Attaque), `Color(0xFF152A4A)` (Compétence), `Color(0xFF453215)` (Pouvoir), `Color(0xFF2D2D2D)` (Statut), et `Color(0xFF2A2A3D)` par défaut.
   - Rendre le fond du widget de carte dynamique en passant un dégradé `LinearGradient` basé sur le `bgColor` et `bgColor.withAlpha(200)` au conteneur principal. Le contour (`border`) prend la couleur d'accent du type.
3. **Mise en page stable de la boutique (Wrap Grid)** :
   - Remplacer les dispositions rigides ou floues par un conteneur `Wrap` avec un espacement défini (`spacing: 12`, `runSpacing: 20`) dans `ShopScreen` pour présenter le catalogue des cartes en vente.
   - Envelopper chaque composant de carte (`_ShopCardItem`) dans un `SizedBox` de largeur fixe `150` pour imposer des dimensions de grille rigoureuses et une répartition adaptative sans overflow.

### Preuves dans le code
- `lib/game/controllers/shop_controller.dart` : Filtre `c.rarity != CardRarity.unique` appliqué au pool global de cartes de la boutique.
- `lib/ui/widgets/ui_card.dart` : Méthodes `_getTypeColor` et `_getBackgroundColor` câblées au build de `UiCard`.
- `lib/ui/screens/shop_screen.dart` : Utilisation de `Wrap` et `SizedBox(width: 150)` pour le positionnement harmonieux en grille.
- **Vérification** : `dart analyze` exempt d'erreurs, suite de 106 tests automatisés validée verte.

### Conséquences
- ✅ **Respect du Gameplay System** : Les cartes spécifiques à un héros ne polluent plus le pool de la boutique, renforçant la spécificité des mécaniques de forge et de fusion de départ.
- ✅ **Confort de Lecture Amélioré (Cognitive Load Reduction)** : Les couleurs de fond thématiques permettent une identification immédiate du type de carte, rendant le combat et le choix d'achat plus fluides et rapides.
- ✅ **Grid Layout Impeccable** : Le comportement adaptatif du Wrap élimine tout risque d'overflow horizontal ou vertical sur mobile ou desktop, avec des cartes parfaitement alignées dans leur contrainte SizedBox.
