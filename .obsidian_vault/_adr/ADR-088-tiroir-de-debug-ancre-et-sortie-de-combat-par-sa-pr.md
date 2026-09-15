### Statut

✅ **Livré le 2026-09-06**, chantier P-30 (menu de debug), lot 1, branche
`feat/menu-debug-lot-2`. Complète [ADR-087](ADR-087-run-debug-declaree-au-lancement-et-verrou-de-persis.md).

### Contexte

Le menu de debug s'ouvrait d'abord en **dialogue** depuis le menu de pause (commit `525d6d5`).
Un dialogue est une route poussée sur la pile du `Navigator`. Or plusieurs actions naviguent :
tuer le dernier ennemi termine le combat.

`GameScreen._completeAndExitCombat` finissait par un `Navigator.pop()` nu. Depuis le dialogue,
ce `pop` fermait **le dialogue** au lieu de l'écran de combat : le joueur restait en combat sur
un nœud déjà marqué résolu, `nextLevel()` avait rempli le mana, le bouton de fin de tour
réclamait une confirmation et aucun tour ne repartait. **Le bug précédait le menu** — tout
élément empilé au-dessus du combat l'aurait déclenché.

### Décision

**D1 — Le combat sort par sa propre route, jamais par le sommet de pile.** `GameScreen` capture sa
`ModalRoute`, dépile jusqu'à elle, puis se retire (`popUntil(route == combatRoute)` puis `pop()`).
C'est la correction de fond, indépendante du menu.

**D2 — Le menu est un tiroir ancré au bord gauche de l'écran, jamais un dialogue empilé.**
`DebugDrawer` est un enfant du `Stack` de l'écran : une poignée « DEBUG » ouvre un panneau, et
aucune route n'est poussée. Rien ne peut donc être fermé à la place de l'écran.

**D3 — Deux jeux d'onglets disjoints selon le contexte.** Sur la carte : Héros, Run, Deck,
Reliques. En combat : l'onglet Combat **seul**, sans barre d'onglets — les statistiques qui bougent
au fil des tours y vivent. Une action de progression ne peut donc pas être lancée au milieu d'un
tour.

**D4 — Le ciblage des ennemis se fait dans le tiroir, un par un, pas sur les sprites.** Garder la
logique hors de Flame (séparation des couches, [ADR-001](ADR-001-separation-triangulaire-etat-rendu-ui.md)).

**D5 — Libellés en français écrits en dur, sans clé ARB**, exception délibérée et bornée à
`lib/ui/widgets/debug/` : l'outil n'existe pas en release et n'a pas de joueur à localiser.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Sortie de combat | `lib/ui/screens/game_screen.dart` — `popUntil((route) => route == combatRoute)` |
| Tiroir | `lib/ui/widgets/debug/debug_drawer.dart`, onglets sous `lib/ui/widgets/debug/tabs/` |
| Insertion carte | `lib/ui/screens/map_screen.dart` — `DebugDrawer(inCombat: false)` |
| Insertion combat | `lib/ui/screens/game_screen.dart` — `DebugDrawer(inCombat: true)` |
| Actions | `lib/game/services/debug_actions.dart` — classe statique composant les contrôleurs existants |
| Tests | `test/widget/debug_drawer_test.dart` |

### Conséquences

- Le menu de pause ne porte plus qu'un sous-titre « RUN DEBUG — aucune sauvegarde ».
- **La correction de navigation n'a pas de test automatisé** : `GameScreen` exige Flame et les
  données chargées (message du commit `5667fb0`).
- `DebugActions` n'ajoute aucune méthode aux contrôleurs : tout ce qu'il manipule était déjà
  public, parce que `SaveService.load()` en avait besoin.
- Spec : `docs/superpowers/specs/2026-09-05-menu-debug-lot-1-manipulateur-de-run-design.md` (v5).
