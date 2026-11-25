### 5.11. Unification UI et Composants Communs (v0.2.2)

Pour éradiquer la duplication massive de code UI et uniformiser l'expérience visuelle, la Phase 3 a introduit un ensemble de composants d'infrastructure réutilisables :

1. **`ScreenScaffold` (`lib/ui/widgets/screen_scaffold.dart`)** :
   - Encapsule le widget `Scaffold` standard.
   - Propose un enum `ScreenBackgroundType` (`dark` pour les ambiances de combat/menus avec un dégradé subtil, `parchment` pour une texture papier de la carte/autels, `none` pour la transparence).
   - Intègre de manière transparente la gestion de `SafeArea` et de `PopScope` (cycle de vie des retours arrière sur mobile) de manière paramétrable.
   - **Vague 2 du bestiaire** (sur la branche `feat/v0.6.2-cadres-et-decors` — [ADR-123](../_adr/ADR-123-le-cadre-de-tier-et-la-carte-d-ennemi-composee.md)) : un paramètre `decor` (`DecorScreen?`) enveloppe le fond dans `LocationBackdrop` (`lib/ui/widgets/location_backdrop.dart`), qui lit `currentLocationProvider` et pose l'image du lieu pour cet écran par `decorFitFor` (couvre l'écran, centrée, rognée, jamais lissée) ; sans image pour l'écran, le fond de `backgroundType` reste. Six écrans le déclarent — l'événement, le repos et sa sélection de carte, la boutique, l'échange de reliques, la forge de fusion — et aucun n'a d'image : ils sont dormants ; le décor de combat est posé par Flame, non par ce widget.

2. **`PageHeader` (`lib/ui/widgets/page_header.dart`)** :
   - Implémente `PreferredSizeWidget` pour s'insérer en tant qu'appBar ou s'utiliser directement dans le corps d'une page.
   - Gère un bouton de retour arrière stylisé et standardisé (`Icons.arrow_back_ios_new`), un titre soigné, et une liste d'actions (boutons ou indicateurs).
   - Ajuste dynamiquement sa couleur d'accent (texte et boutons de retour) selon le type de fond (parchemin foncé vs dégradé sombre).

3. **`GoldIndicator` (`lib/ui/widgets/gold_indicator.dart`)** :
   - Badge d'affichage de l'or connecté à l'état global du run via Riverpod (`inventoryProvider`).
   - Adapte ses couleurs et contrastes selon qu'il est rendu sur fond parchemin ou sur fond sombre.

4. **`CardDraftLayout` (`lib/ui/widgets/draft/card_draft_layout.dart`)** :
   - Structure de mise en page commune pour les phases de draft de cartes.
   - Gère le titre principal, les compteurs de sélection (ex: "Sélectionné : X / Y"), les boutons de validation désactivables et une grille adaptative pour les cartes.

5. **Découpage de la Forge (`lib/ui/widgets/forge/`)** :
   - La boîte de dialogue de forge monolithique a été scindée en sous-composants unitaires pour respecter SRP :
     - `ForgeCardPreview` : Rendu de la carte qui reçoit la rune et de ses runes, sans jauge de capacité depuis [ADR-106](../_adr/ADR-106-fusion-egale-forge.md).
     - `ForgeSlotRow` : La ligne de rune des trois écrans — fusion, affûtage, Puits —, dont le bouton reçoit son libellé et son état (« Choisir », « Affûter — coût or », « Échanger — coût or ») ; la relance a disparu.
     - `SharpenRuneDialog` : Le dialogue d'affûtage du feu de camp, une ligne par rune portée.
     - `rune_style.dart` : Les tables `runeIcons` et `runeColors`, qui traduisent les noms d'icône et de couleur d'une rune.
     - `ForgeBuySlotButton`, le bouton d'achat de fentes, est supprimé avec les fentes achetées.
