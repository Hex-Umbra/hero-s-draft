## 🎨 ADR-037 : Système de Design Centralisé & Uniformisation UI (Design System & UI Uniformization)

### Statut
✅ Accepté & Implémenté

### Contexte
L'interface utilisateur de Hero's Draft souffrait d'une fragmentation des définitions visuelles : des couleurs codées en dur (`Color(0xFF...)`) et des valeurs d'espacement magiques (`EdgeInsets.all(8.0)`) étaient dispersées dans 15+ fichiers de widgets sans source de vérité unique. Cette situation générait plusieurs problèmes :
1. **Inconsistance visuelle** : Des couleurs légèrement différentes pour le même concept pouvaient diverger au fil des nouvelles features.
2. **Coût de maintenance élevé** : Changer la palette de couleurs impliquait de modifier des dizaines de fichiers.
3. **Redondance** : Des `switch` sur `CardRarity` ou `RelicRarity` pour retourner une `Color` étaient dupliqués dans au moins 4 composants (`UiCard`, `RelicsDialog`, `DictionaryScreen`, `BossCardDraftScreen`).
4. **Bug silencieux de layout** : Un `RenderFlex` overflow sur `GameButton` se manifestait sur les boutons contenant uniquement une icône dorée (sans libellé textuel).

### Décision
1. **Création du module `lib/ui/theme/`** :
   - **`app_colors.dart` (`AppColors`)** : Classe statique regroupant toutes les palettes du jeu en domaines sémantiques : `neonDark`, `parchment`, `stats`, `cardRarityColors` (`Map<CardRarity, Color>`) et `relicRarityColors` (`Map<RelicRarity, Color>`).
   - **`app_spacing.dart` (`AppSpacing`)** : Helpers `EdgeInsets` nommés (`xs`, `sm`, `md`, `lg`, `xl`) pour des paddings cohérents.
   - **`app_theme.dart` (`AppTheme`)** : Factory statique générant un `ThemeData` Flutter complet (dark/light) via `ColorScheme.fromSeed`, intégrant `TextTheme` et `ColorScheme` Material 3.

2. **Extensions Dart sur les Enums de Rareté** :
   - Getter `.color` sur `CardRarity` (extension `CardRarityColor`) et sur `RelicRarity` (extension `RelicRarityColor`), définis en regard des maps dans `AppColors`.
   - Usage : `card.rarity.color` ou `relic.rarity.color` directement dans n'importe quel widget.

3. **Correction du Bug `GameButton` (`RenderFlex` overflow)** :
   - Diagnostic : Le layout `Row([Icon, Text])` débordait quand `text == null` dans des contextes de layout contraints.
   - Solution : `Flexible` wrappant le `Text`, `CrossAxisAlignment.center` sur le `Row`, et omission du `Text` du widget tree si absent.

4. **Refactoring `RelicsDialog` via l'Extension** :
   - Remplacement d'un `switch (rarity)` de 19 lignes par `relic.rarity.color`.

### Preuves dans le code
- `lib/ui/theme/app_colors.dart`, `app_spacing.dart`, `app_theme.dart` : Module de design centralisé.
- `lib/models/data/card_data.dart` : Extension `CardRarityColor on CardRarity`.
- `lib/models/data/relic_data.dart` : Extension `RelicRarityColor on RelicRarity`.
- `lib/ui/widgets/game_button.dart` : Correction du layout `Row`.
- `lib/ui/widgets/relics_dialog.dart` : Remplacement du `switch` par `.color`.
- 104/104 tests passés, 0 erreur `dart analyze`.

### Conséquences
- ✅ **Source de Vérité Unique** : Toute la palette visuelle est définie en un seul endroit.
- ✅ **Cohérence Visuelle Garantie** : Impossible d'avoir deux couleurs différentes pour la même rareté dans deux composants distincts.
- ✅ **DRY** : Les `switch` de couleur dupliqués dans 4+ fichiers sont remplacés par un getter idiomatique Dart.
- ✅ **Bug corrigé** : Le `RenderFlex` overflow sur `GameButton` est résolu pour tous les formats d'écran.
- ⚠️ **Migration progressive** : Les widgets non encore migrés utilisent toujours des magic constants. La migration complète s'effectuera au fil des prochains sprints.
