## 🎓 ADR-019 : Système de Tutoriel Autonome Isolant la Boucle Principale (Standalone Tutorial System with State Isolation)

### Statut
✅ Accepté & Implémenté — **Amendé par [ADR-081](ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md) le 2026-08-23** : dans la section Décision ci-dessous, « Éviter les providers Riverpod de production » devient « zéro provider d'*état* », qui autorise la lecture de données immuables via `gameDataLoaderProvider` en un point unique. Le reste de cette décision tient inchangé.

### Contexte
L'onboarding des nouveaux joueurs est un aspect crucial pour "Hero's Draft", mais l'arène de combat Flame, les providers Riverpod complexes (RunController, DeckNotifier, etc.) et le chargement de données asynchrones lient fortement l'application à un flux de production stricte. Essayer de greffer un tutoriel guidé sur la boucle de gameplay classique créerait des risques majeurs d'effets de bord, d'effondrement de la run de production, ou de corruption de données. Un sous-système de tutoriel complètement découplé et autonome est nécessaire.

### Décision
- **Créer un module isolé** sous `lib/tutorial/` regroupant tout le code lié à l'apprentissage (widgets d'étapes, état simulé, moteur de transitions).
- **Éviter les providers Riverpod de production** : Le tutoriel n'utilise pas `runProvider` ou `deckProvider`. À la place, il repose sur un `TutorialEngine` (`ChangeNotifier` simple) qui encapsule sa propre structure de données d'état `TutorialMockState`.
- **Réinitialiser l'état par étape** : Au début de chaque étape du PageView, `resetMockState()` est appelé par le moteur pour injecter précisément les cartes en main, les PV, le mana, l'armure et l'ennemi nécessaires à l'exercice d'apprentissage de cette étape.
- **Utiliser SharedPreferences pour la persistance** : La réussite du tutoriel est tracée de manière persistante par `TutorialProgressService` sous le flag `tutorial_completed`. L'écran `HomeScreen` lit cette donnée pour afficher un badge "NEW" rouge clignotant sur le bouton d'accès.

### Preuves dans le code
- `lib/tutorial/tutorial_engine.dart` : Classe `TutorialEngine` et `TutorialMockState`.
- `lib/tutorial/widgets/` : 13 classes widgets représentant les étapes d'apprentissage.
- `lib/tutorial/tutorial_progress_service.dart` : Persistance via `SharedPreferences`.
- `lib/ui/screens/home_screen.dart` : Notification visuelle "NEW" dynamique basée sur la complétion.

### Conséquences
- ✅ **Sécurité et robustesse de la production** : Zéro risque de corrompre l'état de la run principale ou de casser les tests automatisés de production.
- ✅ **Grande liberté de scénarisation** : Chaque étape est un bac à sable parfait configuré sur mesure.
- ✅ **Rejouabilité infinie** : Le joueur peut rejouer le tutoriel à tout moment depuis l'écran d'accueil.
- ⚠️ **Duplication fonctionnelle légère** : Certains composants et modèles ont été recréés sous forme simplifiée (ex: `TutorialCard` vs `CardInstance`), impliquant de répercuter manuellement les changements graphiques si le design global des cartes change radicalement.
