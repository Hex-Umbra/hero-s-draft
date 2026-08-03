## 🔇 ADR-012 : Absence de Système Audio

### Statut
⚠️ Accepté (dette technique reconnue)

### Contexte
`// TODO: Audio Hook` est disséminé dans les fichiers d'effets et d'interactions de cartes, mais aucune dépendance audio n'existe dans `pubspec.yaml`.

### Décision Actuelle
Pas d'audio. Pas de `flame_audio`, pas de `audioplayers`, pas de `AudioService`.

### Conséquences
- ❌ L'expérience de jeu manque de feedback sensoriel.
- 📋 **Identifié dans la roadmap** : ajouter `flame_audio`, créer un `AudioService` central.
