## 🚫 ADR-010 : Absence Délibérée de Routeur Centralisé

### Statut
⚠️ Accepté (dette technique reconnue)

### Contexte
Le projet utilise des appels directs `Navigator.of(context).push(MaterialPageRoute(...))` pour toutes les transitions d'écran (20+ occurrences).

### Décision Actuelle
Navigation hardcodée dans les callbacks graphiques des écrans. Pas de `GoRouter`, pas de `NavigationController`, pas de routes nommées.

### Raison Probable
Simplicité initiale et développement incrémental — chaque écran ajouté naviguait directement vers le suivant.

### Conséquences
- ✅ Simplicité de mise en œuvre initiale.
- ❌ **Fragile** : Pas de deep linking, pas de restauration d'état à la reprise.
- ❌ **Difficile à maintenir** : 20+ transitions dispersées dans le code.
- 📋 **Identifié comme refactoring Phase 4** dans les plans d'implémentation.
