## 🌍 ADR-006 : Localisation Data-Driven (i18n)

### Statut
✅ Accepté & Implémenté

### Contexte
La version initiale comportait des chaînes codées en dur en français, des variables `isFr` locales pour commuter les traductions, et des données JSON monolingues.

### Décision
- Éradiquer toutes les variables `isFr` et conditions manuelles de langue.
- Migrer l'UI Flutter vers `AppLocalizations` (ARB : `app_en.arb`, `app_fr.arb`).
- Ajouter des double-champs bilingues dans tous les modèles Data (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`).
- Exposer des méthodes `getName(locale)` / `getDescription(locale)` sur chaque modèle.
- Les statuts de combat transitent via des identifiants techniques neutres (`poison`, `weakness`), traduits à la volée par `StatusEffectsPanel`.

### Preuves dans le code
- Zéro variable `isFr` dans tout le codebase.
- `CardData.fromJson` supporte un fallback `name` → `nameEn` pour rétrocompatibilité.
- `StatusEffectsPanel` traduit dynamiquement les identifiants techniques.

### Conséquences
- ✅ Conformité i18n à 100%, `flutter analyze` vierge.
- ✅ Extension facile vers d'autres langues (ajouter ARB + compléter JSON).
- ⚠️ **Exception** : `SkillData` n'a qu'un champ `name` unique — pas encore migré vers le bilingue.
