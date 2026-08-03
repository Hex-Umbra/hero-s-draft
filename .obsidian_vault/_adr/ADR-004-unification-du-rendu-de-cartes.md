## 🃏 ADR-004 : Unification du Rendu de Cartes (Widget `UiCard`)

### Statut
✅ Accepté & Implémenté

### Contexte
La représentation graphique des cartes était dupliquée dans 6 fichiers d'écrans (ShopScreen, DraftScreen, StarterDeckDraftScreen, etc.). Toute modification du design nécessitait 6 modifications parallèles.

### Décision
- Concevoir un widget Flutter unique `UiCard` dans `lib/ui/widgets/ui_card.dart`.
- Ce widget encapsule : gradient rareté, cristal mana, icône type, barre nom, badge level, description dynamique.
- `_buildDescription()` calcule automatiquement les valeurs mises à l'échelle du niveau et remplace les placeholders.
- Remplacer toutes les implémentations inline dans les 5+ écrans UI.

### Preuves dans le code
- `UiCard` utilisé dans `StarterDeckDraftScreen`, `DraftScreen`, `ShopScreen`, `CampfireScreen`, `DictionaryScreen`.
- Ratio d'aspect constant `70 / 110`.
- Gradients par rareté : grey (common), green (uncommon), blue (rare), purple (epic), gold (legendary).

### Conséquences
- ✅ Cohérence graphique absolue sur l'ensemble de l'UI.
- ✅ Réduction de plusieurs centaines de lignes de code redondant.
- ✅ Maintenance centralisée en un seul fichier.
- ⚠️ **Dualité non résolue** : `CardComponent` (Flame) a son propre rendu de carte indépendant — deux systèmes de rendu coexistent.
