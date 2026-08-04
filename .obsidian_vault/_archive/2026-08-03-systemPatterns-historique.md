# Archive — systemPatterns.md, sections datées (2026-08-03)

Sections retirées de `systemPatterns.md` lors de la refonte du 3 août 2026 : descriptions de chantiers d'architecture passés, rattachées à une version révolue. Conservées verbatim. **Ne pas éditer.**

---

## 13. Système de Design Centralisé & Tokens UI (Design System, v0.0.99)

Le sprint v0.0.99 a introduit un **système de design centralisé** dans le module `lib/ui/theme/`, éliminant les magic constants dispersées dans les 15+ fichiers de widgets et standardisant l'identité visuelle du jeu.

### 13.1. Module `lib/ui/theme/`

Le module regroupe trois fichiers complémentaires :

| Fichier | Classe | Responsabilité |
|:---|:---|:---|
| `app_colors.dart` | `AppColors` | Toutes les couleurs du jeu (Neon Dark, Parchemin, stats sémantiques, raretés cartes/reliques) |
| `app_spacing.dart` | `AppSpacing` | Helpers d'`EdgeInsets` et de padding standardisés |
| `app_theme.dart` | `AppTheme` | Factory de `ThemeData` Flutter complet (dark/light, polices, couleurs primaires, styles de texte) |

### 13.2. Palettes de Couleurs (`AppColors`)

`AppColors` structure les couleurs en domaines sémantiques distincts :
- **Neon Dark** : Couleurs de base de l'interface sombre (fond, surface, texte, accents neon).
- **Parchemin** : Couleurs de l'ambiance carte/parchemin médiéval (fond brun, dorure, texte sépia).
- **Stats sémantiques** : Couleurs HP, Mana, Armure, Critique (identiques dans tout le jeu).
- **Raretés de cartes** : Chaque `CardRarity` (Common, Uncommon, Rare, Epic, Legendary) possède une couleur canonique.
- **Raretés de reliques** : Chaque `RelicRarity` possède une couleur canonique distincte des cartes.

### 13.3. Extensions Dart sur les Enums de Rareté

Pour supprimer les `switch` redondants, des **extensions Dart** ajoutent un getter `.color` sur les deux enums de rareté :

```dart
// Sur CardRarity
extension CardRarityColor on CardRarity {
  Color get color => AppColors.cardRarityColors[this]!;
}

// Sur RelicRarity
extension RelicRarityColor on RelicRarity {
  Color get color => AppColors.relicRarityColors[this]!;
}
```

**Avant (pattern à bannir)** :
```dart
Color _getRelicColor(RelicRarity rarity) {
  switch (rarity) {
    case RelicRarity.common: return Colors.grey;
    case RelicRarity.uncommon: return Colors.green;
    case RelicRarity.rare: return Colors.blue;
    case RelicRarity.epic: return Colors.purple;
    case RelicRarity.legendary: return Colors.orange;
  }
}
```

**Après (pattern à adopter)** :
```dart
// Directement dans le widget :
color: relic.rarity.color
```

### 13.4. Extension de Thème Flutter (GameThemeExtension)

Pour permettre l'accès typé et centralisé aux jetons visuels spécifiques au gameplay via le `BuildContext` standard de Flutter (ex: `Theme.of(context).extension<GameThemeExtension>()`), une extension de thème a été introduite :
- **`game_theme_extension.dart`** (`lib/ui/theme/game_theme_extension.dart`) :
  - Contient les couleurs des raretés de cartes, les couleurs des statistiques de combat (HP, Mana, Armure, Force, etc.) et les lueurs néon de l'interface.
  - Implémente les méthodes `copyWith` et `lerp` requises par la classe de base `ThemeExtension` de Flutter pour des transitions de thèmes fluides.
  - Enregistrée au sein d' `AppTheme` dans les thèmes clairs (`ThemeData.light()`) et sombres (`ThemeData.dark()`), garantissant que ces jetons graphiques s'adaptent et s'harmonisent avec le mode graphique sélectionné.

### 13.5. Règles de Contribution

- **Aucune magic constant** dans les widgets. Toute couleur, espacement ou style de texte doit provenir de `AppColors`, `AppSpacing` ou `AppTheme`.
- **Toute nouvelle rareté** (de carte ou de relique) doit être ajoutée simultanément dans les maps de `AppColors` et dans les extensions d'enum correspondantes.
- **Les tokens de design ne dépendent d'aucun provider Riverpod**. Ils sont purement statiques et instanciables sans contexte d'application.

---

## 14. Architecture d'Amélioration de l'Interface & Cartes (UX Combat) (v0.1.00)

Le sprint v0.1.00 introduit de nouveaux patrons d'interaction et de rendu pour l'interface de combat (Flame et Flutter).

### 14.1. Verrouillage Tactile Temporaire lors du Dealing (Input Blocking)

Pour éviter les race conditions d'interactions (comme le fait de survoler, cliquer ou glisser une carte en train d'être distribuée depuis la pioche, ce qui provoquait des sauts physiques ou des désalignements de l'arc de la main), un patron de verrouillage a été mis en œuvre :
1. **Drapeau d'état** : `CardComponent` possède le drapeau public `isEnteringHand`.
2. **Garde d'interaction** : Les méthodes d'entrée de `CardComponent` (`onTapDown`, `onDragStart`, `onHoverEnter`, `onHoverExit`, `onDragUpdate`) effectuent une garde directe :
   ```dart
   if (isEnteringHand || isPlayed) return;
   ```
3. **Orchestration de la Pioche** : Lors de la pioche dans `HerosDraftGame._applyDeckState()`, les nouvelles cartes sont instanciées avec `isEnteringHand = true`.
4. **Ralentissement de Transition** : Dans `_layoutHand()`, la durée du `MoveEffect` est portée à `0.7s` (au lieu de `0.35s` pour le tri standard) pour donner une impression de distribution fluide et majestueuse. Un callback `onComplete` réinitialise `card.isEnteringHand = false` lorsque le glissement se termine, rendant la carte de nouveau interactive.

### 14.2. Affichage Ciblé des Infobulles de Combat (Focused Tooltips)

Afin d'éviter l'encombrement de l'écran par des infobulles intempestives lors du simple glissement de la souris, le système de tooltips a été restreint :
- **Sélection Active uniquement** : Les rappels `onShowTooltip`/`onHideTooltip` ne sont plus déclenchés au simple survol de la souris en combat. Ils sont uniquement lancés lorsque le joueur clique activement sur une carte pour la focaliser ou initier un ciblage.
- **Auto-masquage** : Le tooltip est automatiquement masqué lorsque la carte est jouée, désélectionnée (clic dans le vide), ou lorsque la phase du combat change.
- **Formatage des Upgrades** : Le descriptif de l'infobulle appelle `_buildDetailedDescription()` qui concatène proprement la liste des améliorations de forge sous la forme d'une liste à puces en bas du texte.

### 14.3. Rendu d'Étoiles de Forge (Upgrade Progress Stars)

Pour matérialiser visuellement le niveau de forge de chaque carte sans surcharger son illustration :
- **Calcul du Ratio** : La carte affiche un nombre d'étoiles proportionnel à sa capacité maximale :
  - Nombre d'étoiles total = $\text{Capacité} = baseMaxForgeUpgrades + rarityIndex$
  - Nombre d'étoiles dorées pleines = `card.forgeUpgrades.length`
  - Le reliquat de la capacité est dessiné sous forme d'étoiles vides.
- **Rendu Unifié (Flame & Flutter)** :
  - Dans `card_text_renderer.dart` (Flame) : Une boucle dessine des étoiles dorées vectorielles via l'API Canvas sous le label de rareté.
  - Dans `ui_card.dart` (Flutter) : Une rangée d'icônes `Icons.star` / `Icons.star_border` dorées est insérée de manière dynamique dans l'arbre de widgets.

### 14.4. Double Jauge de Transition et Décélération (HP Dual-Bar Animation & Deceleration) (v0.1.7)

Pour fournir un feedback d'impact clair tout en conservant une traînée persistante sous les dégâts subis :
- **Modèle Double-Jauge** : La barre de vie comporte une jauge avant-plan (verte/jaune/rouge représentant la vie instantanée) et une jauge arrière-plan (rouge/orange représentant la vie précédente avant transition).
- **Interpolation lagging de Dégâts (Ralentie à 1200ms)** :
  - La jauge verte d'avant-plan chute instantanément pour donner une sensation d'impact immédiate.
  - La jauge rouge de catch-up d'arrière-plan descend plus lentement via une animation d'une durée portée à **1200ms** (au lieu de 500ms initialement) avec la courbe de décélération progressive `Curves.easeOut`. Cette décélération prolongée permet au joueur de mieux ressentir et quantifier la violence des dégâts reçus.
- **Alignement instantané de Soin (Snappy)** :
  - La jauge verte d'avant-plan augmente de manière animée et progressive en **500ms** pour signifier la guérison.
  - La jauge rouge d'arrière-plan s'aligne immédiatement sur le nouveau montant de PV pour éviter tout effet de traînée inverse inesthétique.
- **Gestion d'État** : `PlayerHealthBar` est un `StatefulWidget` qui écoute les modifications de `currentPv` et de `maxPv`. Elle reconfigure dynamiquement la durée de l'animation lors du `didUpdateWidget` selon que la valeur de PV augmente (soin) ou diminue (dégâts), et anime les ratios calculés via un `AnimatedBuilder`.

### 14.5. Textes Flottants Premium & Effets Néon (Premium Neon Floating Text) (v0.1.7)

Les textes flottants de dégâts et d'effets de combat (`FloatingText`) ont été restructurés et enrichis pour améliorer le jus visuel (visual juice) en combat :
1. **Ombres Néon Colorées Thématiques** : Chaque type d'effet applique un ensemble de filtres d'ombres néon cumulés via l'attribut `shadows` du `TextStyle` (dessinés sans `saveLayer` pour de meilleures performances CPU/GPU) :
   - *Coup Critique* : Lueur néon intense orange et rouge (`Colors.orangeAccent` blur 8, `Colors.redAccent` blur 16, ainsi qu'une ombre noire portée blur 4).
   - *Poison* : Lueur toxique verte et vert clair (`Colors.greenAccent` blur 6, `Colors.lightGreenAccent` blur 12).
   - *Bouclier/Armure* : Lueur de barrière cyan et bleue (`Colors.cyanAccent` blur 6, `Colors.blueAccent` blur 12).
2. **Signalétique Symbolique & Sizing** :
   - Les coups critiques prépendent le symbole `"💥 CRIT "` et affichent un corps de texte agrandi à 36 (contre 26 pour les dégâts normaux).
   - Le poison prépende l'icône de fiole `"🧪 "` et affiche un corps de texte de 22.
   - Les gains d'armure prépendent le bouclier `"🛡️ "` et affichent un corps de texte de 26.
3. **Trajectoire Organique & Rotation Aléatoire** :
   - À sa naissance (`onLoad`), chaque texte flottant subit un effet de rotation aléatoire (`RotateEffect.to`) de faible amplitude (entre -0.15 et +0.15 radians) sur 150ms pour casser la rigidité de l'affichage.
   - Il subit un déplacement en arc de cercle (`MoveEffect.by`) incluant un balayage latéral aléatoire (drift) et une dérive verticale.
   - Pour le poison, une oscillation sinusoïdale horizontale additionnelle (`sin(time * 10) * 0.8`) est injectée dans la méthode `update` pour simuler une traînée toxique gazeuse flottante.
4. **Cinématique de Pop d'Échelle de Critique (Elastic Animation Sequence)** :
   - Contrairement aux textes standard qui effectuent un pop de rebond classique (`Curves.bounceOut`), les critiques subissent une séquence complexe d'effets d'échelle (`SequenceEffect`) :
     1. Un gonflement rapide et surdimensionné à 1.5x via `Curves.elasticOut` (durée 350ms) pour l'effet de punch.
     2. Un amortissement léger ramenant l'échelle à 1.15x via `Curves.easeOut` (durée 150ms).
     3. Une animation de pulsation infinie alternée (`alternate: true`, `infinite: true`) oscillant entre 1.15x et 1.3x toutes les 300ms pour maintenir le focus visuel sur le critique.
5. **Cycle de Vie & Fondu** :
   - L'ensemble du composant s'estompe via un fondu de transparence (`OpacityEffect.fadeOut` en 1.2s via `Curves.easeIn`) et est retiré automatiquement de l'arène de jeu Flame via un `RemoveEffect(delay: 1.2)`.

### 14.6. Attribut floor Explicite de MapNode (v0.2.4)

Afin de sécuriser l'évaluation de l'étage actuel d'un nœud et d'éradiquer les expressions fragiles basées sur le découpage de son ID de type chaîne (`id.split('_')[1]`), l'attribut `floor` a été introduit :
- **Attribut Explicite** : `final int floor;` a été ajouté au modèle `MapNode` sous `lib/models/map_node.dart`.
- **Désérialisation Rétrocompatible** : Le constructeur `fromJson` récupère `json['floor'] ?? int.parse(id.split('_')[1])` pour garantir le fonctionnement avec d'anciennes sauvegardes persistantes sérialisées ne comportant pas encore ce champ.
- **Sécurisation de la Logique de Navigation** : Les fichiers `MapContentPlacer`, `MapValidator`, `MapScreen` et `MapNodeGenerator` ont été modifiés pour utiliser directement `node.floor` au lieu de parser l'identifiant.

### 14.7. Harmonisation Post-Refactoring de l'Architecture (v0.2.4)

L'étape d'harmonisation a permis d'unifier l'expérience UI, de découpler les registries et d'éliminer la duplication logique restante :
1. **Harmonisation UI** : Migration complète de `ClassSelectionScreen` vers les composants unifiés de la charte graphique (`ScreenScaffold` et `PageHeader`), éliminant l'ancien Scaffold et l'AppBar dupliqués.
2. **Déduplication Graphique dans Flame** : Déplacement et centralisation de la détection de changement de statistiques (`updateStats`), d'affichage des textes flottants (`spawnFloatingText`) et des secousses dans `CombatEntity`, nettoyant `HeroCard` et `EnemyCard`.
3. **Riverpodisation d'EffectRegistry** : Migration d'`EffectRegistry` pour être fourni par `effectRegistryProvider`. La méthode `EffectResolver.resolveCard` prend maintenant l'instance fournie en paramètre. Nettoyage de tous les callbacks orphelins inutilisés dans `HerosDraftGame`.
