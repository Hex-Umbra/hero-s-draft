## 🔇 ADR-012 : Absence de Système Audio

### Statut
✅ **Remplacé par [ADR-082](ADR-082-directeur-audio-central-et-mapping-par-donnees.md) le
2026-08-25** (chantier P-03) : un système audio complet existe désormais, la décision
« pas d'audio » ci-dessous est intégralement renversée. Conservé pour mémoire.

### Contexte
`// TODO: Audio Hook` est disséminé dans les fichiers d'effets et d'interactions de cartes, mais aucune dépendance audio n'existe dans `pubspec.yaml`.

### Décision Actuelle
Pas d'audio. Pas de `flame_audio`, pas de `audioplayers`, pas de `AudioService`.

### Conséquences
- ❌ L'expérience de jeu manque de feedback sensoriel.
- 📋 **Identifié dans la roadmap** : ajouter `flame_audio`, créer un `AudioService` central.
