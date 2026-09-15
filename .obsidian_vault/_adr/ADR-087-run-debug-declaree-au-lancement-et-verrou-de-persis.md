### Statut

✅ **Livré le 2026-09-06**, chantier P-30 (menu de debug), lot 1, branche
`feat/menu-debug-lot-2`. Prolonge [ADR-069](ADR-069-systeme-de-sauvegarde-de-run-checkpoint-carte-refr.md) :
le verrou vit dans le service qu'elle a créé.

### Contexte

Le lot 1 du menu de debug manipule l'état vivant d'une run : or, statistiques, deck, reliques,
PV des ennemis. Une run ainsi trafiquée pose une question de persistance que l'autosave
d'ADR-069 ne se posait pas.

La première conception (v3 de la spec) levait un **drapeau de contamination** à la première
action de debug, lu par le checkpoint pour refuser l'écriture. Elle ne gardait qu'une porte sur
deux : `SaveService.clear` est appelé par `DeathOverlay`, et le menu offre « Perdre le combat ».
**Tester une mort effaçait la vraie sauvegarde.**

### Décision

**D1 — Le mode est déclaré au lancement, pas déduit d'une modification.** Le bouton « RUN DEBUG »
de l'accueil pose une demande (`DebugRunNotifier.requestDebugRun`), consommée par
`RunController.startNewRun` (`applyRequestedMode`). Un mode déclaré refuse la persistance dès la
première ligne et peut s'afficher ; un mode déduit ne réagit qu'après coup, et reste invisible.

**D2 — Une run debug ne persiste rien : ni écriture, ni effacement.** Une sauvegarde trafiquée est
indistinguable d'une sauvegarde légitime, et l'effacement est aussi destructeur que l'écriture.

**D3 — Le verrou est dans `SaveService`, pas chez ses appelants.** `save()` et `clear()` prennent
le même `RefReader` et sortent d'emblée si la run est en debug. Placé dans le service, il couvre
les appelants externes, les deux `clear` internes du chemin « sauvegarde corrompue », et ceux que
personne n'a encore écrits.

**D4 — Le menu n'existe que dans une run debug, et `DebugActions` refuse d'agir ailleurs.** Chaque
méthode vérifie `kDebugMode && isDebugRun`. Une run normale n'est pas seulement dépourvue de
boutons : elle est intouchable, y compris par un appel égaré.

**D5 — Deux pièges silencieux, chacun son test.**
1. *L'intention qui traîne* : « RUN DEBUG », retour, puis « JOUER ». Chaque bouton de départ
   déclare donc son mode (`requestNormalRun`).
2. *La sauvegarde chargée après une run debug* : `SaveService.load` rabaisse le mode dès sa
   première ligne (`clearForLoadedRun`), avant les `clear` du chemin corrompu.

**D6 — « RUN DEBUG » ne passe ni par la confirmation d'écrasement ni par `clear()`** : une run qui
ne persiste rien n'a rien à écraser.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| État et demandes | `lib/game/controllers/debug_run_controller.dart` — `DebugRunState`, `debugRunProvider` |
| Consommation de la demande | `lib/game/controllers/run_controller.dart` (`applyRequestedMode`, sous `kDebugMode`) |
| Verrou | `lib/services/save_service.dart` — `_isDebugRun`, `save`, `clear(RefReader)`, `load` |
| Garde des actions | `lib/game/services/debug_actions.dart` — `_allowed` |
| Départ sans écrasement | `lib/ui/screens/home_screen.dart` — `_startDebugRun` |
| Tests | `test/unit/debug_run_test.dart`, `test/unit/debug_actions_test.dart` |

Le drapeau de contamination (`debug_taint_controller.dart`, commit `53da52c`) a été supprimé par
`95ca8e1`. `autosaveOrchestratorProvider` ne porte aucune condition propre, par construction.

### Conséquences

- `DeathOverlay` devient un `ConsumerWidget` pour transmettre `ref.read` à `clear`.
- Une valeur forcée peut produire un état que le jeu n'atteint jamais — risque accepté, rien n'est
  persisté.
- **Exclusion du build release** : tout point d'entrée est gardé par `kDebugMode`, constante de
  compilation. **Vérifié à la main par le propriétaire le 2026-09-14** sur un build release, après
  la réécriture en tiroir : ni la colonne de debug de l'accueil, ni le tiroir ne sont atteignables.
  La vérification reste manuelle, sans script ni test ; la procédure AOT de la spec (§7.1) date du
  2026-09-05 et l'un de ses témoins d'absence (« Menu de debug ») n'existe plus dans `lib/`.
- Spec : `docs/superpowers/specs/2026-09-05-menu-debug-lot-1-manipulateur-de-run-design.md`.
