### Statut

✅ **Livré le 2026-09-14**, branche `feat/menu-debug-lot-2` — commits `97f1553` (accueil, Quitter,
retours arrière) et `b47f2e3` (suppression de la persistance du tutoriel). Remplace la persistance de complétion du tutoriel décrite par
[`_rules/08-00`](../_rules/08-00-systeme-de-tutoriel-autonome.md) §8.5 jusqu'à cette date.

### Contexte

Quatre demandes du propriétaire sur le parcours d'entrée, toutes nées du **build Windows** :

- l'accueil empilait au centre, dans une même colonne, le menu joueur et les deux boutons de debug ;
- aucun bouton ne fermait le jeu — sur desktop, seule la croix de la fenêtre le faisait ;
- la sélection de classe masquait son bouton retour (`showBackButton: false`), et le draft de
  départ n'en avait aucun : sur mobile le geste système suffit, pas sur Windows ;
- le badge « NEW » du bouton Tutoriel.

### Décision

**D1 — Menu joueur à gauche, menu de debug dans sa propre colonne à droite.** Les boutons du menu
joueur partagent une largeur commune : alignés à gauche, des largeurs différentes formeraient un
bord droit en escalier. Sous 700 px de large, la colonne de debug passe sous le menu principal.

**D2 — « Quitter » passe par le moteur, selon la plateforme.** Desktop :
`ServicesBinding.exitApplication(AppExitType.required)`. Android : `SystemNavigator.pop()`, Android
n'implémentant pas la requête de sortie. **Masqué sur web** (une page ne ferme pas son onglet) **et
sur iOS** (Apple interdit à une app de se fermer elle-même) : un bouton sans effet serait pire
qu'aucun.

**D3 — Le retour du draft de départ est une option de `CardDraftLayout` (`onBack`), activée par le
seul `StarterDeckDraftScreen`.** Le draft post-boss partage la mise en page mais n'en reçoit pas :
on ne revient pas sur une récompense en cours de run. Revenir du draft de départ ne coûte que la
sélection — la run ne naît qu'à la validation.

**D4 — Retrait du badge « NEW », et de toute la persistance de complétion du tutoriel.** Le badge
était le **seul lecteur** de `TutorialProgressService.hasCompletedTutorial()`. Sans lui, le service
n'aurait plus fait qu'écrire un drapeau que rien ne lit : il est supprimé avec son test, et
`TutorialScreen` ne l'appelle plus en fin de parcours.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Accueil, sortie par plateforme | `lib/ui/screens/home_screen.dart` — `_quitGame`, `_canQuit`, `_buildMainMenu`, `_buildDebugMenu` |
| Libellé bilingue | `lib/l10n/app_fr.arb`, `lib/l10n/app_en.arb` — clé `quitGame` |
| Retour de la sélection de classe | `lib/ui/screens/class_selection_screen.dart` — `PageHeader` au retour par défaut |
| Retour du draft de départ | `lib/ui/widgets/draft/card_draft_layout.dart` (`onBack`), `lib/ui/screens/starter_deck_draft_screen.dart` |
| Fin du tutoriel | `lib/tutorial/tutorial_screen.dart` — `_handleNext` ne persiste plus rien |
| Tests | `test/widget/home_screen_menu_test.dart` (6) |

La sortie desktop se teste sans fermer le processus : le binding de test lève une `FlutterError`
sur une sortie `required` et n'en lève aucune sur `cancelable` — l'erreur prouve l'appel **et**
son type.

### Conséquences

- La clé `shared_preferences` `tutorial_completed` reste sur les installations existantes, jamais
  relue ; aucune migration, la valeur est inerte.
- Le retour ne prévient pas de la perte de la sélection du draft de départ.
- Visible du joueur : ces changements ont rejoint la note `0.5.1`, jamais publiée, complétée en place (commit `d8d9319`).
