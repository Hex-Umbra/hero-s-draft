# Archive — productContext.md, rapports de sprint (2026-08-03)

Sections §9 à §11 retirées de `productContext.md` lors de la refonte du 3 août 2026 : rapports de sprint historiques (v0.0.97 → v0.2.2), sans valeur de règle métier courante. Conservées verbatim. **Ne pas éditer.**

---

## 9. Sprint de Consolidation Architecturale & Qualité Visuelle (v0.0.97 → v0.0.99)

Ce sprint tri-phase constitue un investissement majeur dans la **qualité technique** et la **maintenabilité à long terme** du projet, sans ajout de features gameplay. Chaque phase a été validée avec 104/104 tests au vert et 0 erreur `dart analyze`.

### 9.1. Option A — Modernisation Architecturale (v0.0.97)

**Impact produit** : Réduction de la dette technique critique. Les contrôleurs métier (8+) migrent de `StateNotifier` vers `Notifier`, ce qui supprime les constructeurs à injection massive et les risques de cycles de dépendances. `CardInstance` devient strictement immuable.

**Portée technique** :
- `RunController`, `CombatController`, `DeckNotifier`, `InventoryController`, `SkillController`, `EventController`, `ShopController`, `RewardController` → héritage de `Notifier<T>`.
- `CardInstance.forgeUpgrades` → `List<String>.unmodifiable` avec pattern `copyWith`.
- Logique `executeSkill` extraite de `HerosDraftGame` vers `CombatController`.

### 9.2. Option B — Performance & Animations (v0.0.98)

**Impact produit** : Fluidité et "game feel" améliorés, notamment sur mobile. Les animations de combat sont synchronisées à la frame d'impact réelle, et la pioche devient physiquement satisfaisante.

**Portée technique** :
- `FloatingText` & `EffectIcon` : suppression des `saveLayer` → peindre direct.
- `CardComponent` : caching `TextPainter`, `saveLayer` conditionnel (`opacity < 1.0`).
- `EnemyCard` : buffer `_pendingVisualInstance`, déclenchement sur `resolvePendingVisualStats()`.
- `CardAnimator` : suppression des branches de double-déclenchement.
- Spawn pioche à `Vector2(40, size.y - 40)` + Flame Effects chaînés.

### 9.3. Option C — Système de Design & Uniformisation UI (v0.0.99)

**Impact produit** : Cohérence visuelle garantie à l'échelle de toute l'application. Les couleurs de rareté, les espacements et la typographie sont maintenant gérés depuis une source de vérité unique. Un bug de layout `GameButton` est résolu.

**Portée technique** :
- Module `lib/ui/theme/` : `AppColors`, `AppSpacing`, `AppTheme`.
- Extensions `CardRarityColor` et `RelicRarityColor` sur les enums de rareté.
- Correction `GameButton` : `Flexible` + omission `Text` si null.
- `RelicsDialog` : `switch` de 19 lignes → `.color`.

### 9.4. Invariants de Qualité Post-Sprint

| Invariant | Valeur |
|:---|:---|
| Tests automatisés | 104/104 ✅ |
| Erreurs `dart analyze` | 0 ✅ |
| Pattern Riverpod | `Notifier<T>` (v2.x) pour tous les contrôleurs |
| Source de vérité couleurs | `AppColors` (aucune magic constant dans les widgets) |
| Immuabilité des modèles | `CardInstance` : tous attributs `final` + `List.unmodifiable` |

---

## 10. Sprint d'Amélioration de l'Interface & Cartes (UX Combat) (v0.1.00)

Ce sprint cible l'optimisation visuelle et tactile du combat pour élever le niveau d'immersion et de satisfaction sensorielle.

### 10.1. Impact Produit

- **Fluidité de Pioche** : Protection contre les clics ou glissements prématurés durant la pioche, garantissant un comportement sans à-coups ni instabilités physiques.
- **Transparence Tactique** : Présentation directe et contextualisée des améliorations (upgrades de forge) appliquées aux cartes en combat, permettant des choix informés.
- **Clarté Visuelle Rénovée** : Élimination du bruit visuel causé par les icônes de fond translucides et les tailles de police trop imposantes sur les cartes Flame et Flutter. Indication élégante du niveau d'upgrade de la carte via des badges d'étoiles.
- **Game Feel Premium (HUD)** : Transformation de la simple barre de vie statique du héros en une jauge double-niveau interactive et dynamique, améliorant le feedback émotionnel lors des dégâts reçus ou des soins appliqués.

### 10.2. Portée Technique

- **Verrouillage Tactile de Pioche** : Introduction d'un drapeau `isEnteringHand` dans `CardComponent` qui filtre les callbacks de survol, glissement et clic. La durée de distribution est portée à `0.7s` dans `_layoutHand` avant d'être réalignée à `0.35s` après complétion.
- **Exhibition Sélective des Tooltips** : Raccordement du cycle de vie des infobulles aux seuls événements de focus sur la carte en combat. Enrichissement de la description textuelle par une liste mise en forme des upgrades de forge actifs.
- **Rénovation Esthétique des Cartes** :
  - **Flame** : Retrait du dessin de fond dans `card_text_renderer.dart`, diminution des polices et dessin vectoriel d'étoiles dorées proportionnelles à `card.forgeUpgrades.length`.
  - **Flutter** : Retrait de l'icône centrale translucide et réduction des polices dans `ui_card.dart`. Rendu d'une rangée d'étoiles dorées sous le label de rareté avec ajustement des offsets.
- **Double Jauge de Vie Animée (HP Dual-Bar)** : Conversion de `PlayerHealthBar` en `StatefulWidget`. Câblage d'un `TweenAnimationBuilder` (500ms, `Curves.easeOutCubic`) animant la différence de ratio entre les PV actuels et les PV précédents sous forme d'une jauge secondaire rouge/orange qui glisse lentement en arrière-plan sous les dégâts. En cas de soin, la jauge verte augmente de suite de manière fluide et la barre rouge s'y aligne instantanément.

---

## 11. Sprint d'Unification de l'UI & Composants Communs (v0.2.2)

Ce sprint standardise l'ensemble des interfaces de menus et de progression du jeu, éliminant la duplication de code et garantissant une cohérence visuelle stricte.

### 11.1. Impact Produit
- **Harmonisation Visuelle Immédiate** : Centralisation de tous les décors d'arrière-plan (dégradé sombre pour les menus/combats et parchemin historique pour la carte et les échanges) sous une infrastructure commune.
- **Expérience Utilisateur Unifiée** : Standardisation du cycle de vie de la navigation (gestion des retours physiques arrière via `PopScope`) et présentation d'un en-tête d'écran homogène incluant le solde d'or du joueur.
- **Grille de Sélection Cohérente** : Intégration d'un layout partagé pour tous les drafts de cartes (Starter Deck et Boss Rewards) avec une mise en page fluide et adaptative.
- **Allègement de la Forge** : Simplification fonctionnelle du dialogue de forge, le recentrant sur l'orchestration logique et améliorant la responsivité globale du système sur mobile et desktop.

### 11.2. Portée Technique
- **`ScreenScaffold`** : Composant centralisant le Scaffold, la gestion thématique des arrière-plans (`dark`, `parchment`, `none`), la `SafeArea` et la prévention des retours physiques arrière accidentels.
- **`PageHeader`** : En-tête standardisé qui s'adapte visuellement au thème de fond, exposant le titre, le bouton de retour arrière stylisé et les actions transversales.
- **`GoldIndicator`** : Badge d'or universel, branché de façon autonome sur `inventoryProvider`, qui ajuste son contraste et ses teintes selon le support.
- **`CardDraftLayout`** : Widget de mise en page réutilisable pour la sélection interactive de cartes, uniformisant les grilles de cartes et les boutons de confirmation.
- **Décomposition Modulaire de la Forge** : Division de la logique monolithique en 3 composants distincts : `ForgeCardPreview` (rendu carte et jauges de runes), `ForgeSlotRow` (actions et boutons de reroll d'une ligne d'amélioration), et `ForgeBuySlotButton` (extension de capacité).
- **Factories `UiCard`** : Simplification drastique de la création des widgets Flutter de cartes avec les constructeurs nommés `UiCard.fromInstance` et `UiCard.fromData`.
