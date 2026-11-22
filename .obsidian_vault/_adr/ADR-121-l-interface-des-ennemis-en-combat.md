---
description: The enemy interface in combat (P-05 bestiary, wave 1) — every display rule is a pure function tested without a screen (ArmorVeil, IntentPips, StatusReadout, EnemySheetView, SheetPlacement, pickHoveredEntity); the health bar, the status tabs, the enlargement and the dimming veil are Flame components attached to their card; the intents panel and the sheet frame are Flutter HUD widgets; the open sheet is a display state owned by HerosDraftGame, which GameScreen reflects one frame later; no new Riverpod state, no model change; one zone per combat card serves hover, tap and drop alike; the sheet closes on any primary press except the pointer Flame has just held; an enemy card's scale and position move by relative deltas because every GameScreen rebuild re-runs onGameResize; StatBadge, StatusIndicator and CircleProgressComponent are deleted; carries owner decisions B6 (in part), B9 to B16 and B31 to B41, B32 amending B14; the enemy armor veil ships dormant; amends ADR-119 point 3, completes ADR-104, ADR-117 and ADR-013
---

# ADR-121 — L'Interface des Ennemis en Combat

### Statut

✅ Accepté — 2026-11-22 (P-05, le bestiaire ; décisions du propriétaire B6 pour sa part, B9 à B16
et B31 à B41, tranchées sur maquettes les 20 et 21/11). **Livré sur la branche
`feat/v0.6.1-interface-des-ennemis` — vague 1 du
[cadrage du bestiaire](../../docs/possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), test du propriétaire passé le 2026-11-22, en attente de la PR, de la fusion et du tag du propriétaire.** Rien n'en est dans `main`.
[Spec](../../docs/superpowers/specs/2026-11-21-p05-interface-des-ennemis-design.md) (arbitrages A1 à
A16, quatre tours) ; [plan](../../docs/superpowers/plans/2026-11-21-p05-interface-des-ennemis.md)
(décisions D1 à D16, trois tours) ; code `a356cabc`..`23c9823a`, note de version `5ea848fb`. Leurs
motifs ne se recopient pas ici.

**Testé par le propriétaire le 2026-11-22** : 25 ✅ (T1 à T19, T21 à T25, puis C1), T20 non testé —
le voile d'armure n'est pas atteignable en jeu —
([cahier](../../docs/superpowers/reports/2026-11-22-bestiaire-vague-1-tests-manuels.md)). **Une
correction de fin de vague, C1** (`1876a07b`, note de version `477e9b12`) : la fiche écrit une ligne
d'aide sous chaque entrée — une phrase pour le Poison, la Puissance et les quatre régénérations, et
pour une charge sa phrase courte, `summary_fr` / `summary_en`, **obligatoire dans son fichier** et à
jetons contrôlés comme la description, que `ChargeData.summaryFor` remplit ; nulle sur la rupture
propre du héros, dont la languette écrit déjà l'effet. La description longue reste aux infobulles
des cartes. C1 touche donc `lib/models/data/charge_data.dart` et les trois fichiers de
`assets/data/charges/` : le « aucun fichier de `lib/models/` ni `assets/data/` ne bouge » du
Contexte décrit la vague avant sa correction.

**Amende [ADR-119](ADR-119-les-corrections-de-fin-de-vague-8.md)** sur son point 3 : le panneau perd
les PV et passe en trois colonnes, l'infobulle passe de la pastille à la rangée. **Complète
[ADR-104](ADR-104-un-statut-par-source-et-ratio-de-conversion.md)** — l'affichage d'un ennemi ne
suppose plus une entrée par `id` —, **[ADR-117](ADR-117-les-charges-elementaires.md)** — les états
des charges se lisent au repos et au déroulé des languettes — et
**[ADR-013](ADR-013-systeme-de-mort-et-de-stats-synchronise-z-sync.md)**, dont le texte nomme
`StatBadge` et `HealthBar` : le différé de Z-Sync vaut désormais pour la barre et les languettes.
Chacun de ces ADR ne change que de Statut.

### Contexte

Au-dessus de la carte d'un ennemi, un badge serrait sa Puissance, son armure et ses PV, et la
barre n'occupait qu'une part de la carte ; le voile d'armure valait `armure / PV max`. Ses statuts
tenaient en icônes sans nom, réconciliées par `id`. Le panneau des intentions répétait ses PV.
Toucher un ennemi sans carte sélectionnée ne faisait rien. Avant que des ennemis posent du Gel, du
Feu ou du Poison (vagues suivantes du cadrage), l'écran devait savoir les montrer. **Rien ne change à
ce que les ennemis font** : aucun fichier de `lib/models/`, `lib/game/controllers/`,
`lib/game/services/` ni `assets/data/` (hors note de version) ne bouge.

### Décision

1. **Chaque élément vit dans une couche, et aucun état Riverpod n'est créé** (A1, A13). Les règles
   d'affichage sont des **fonctions pures, testées sans écran** : `ArmorVeil`
   (`lib/game/systems/armor_veil.dart`), `IntentPips` (`lib/ui/widgets/hud/intent_pips.dart`),
   `StatusReadout` et `statusEmoji` (`lib/game/systems/status_readout.dart`), `EnemySheetView` et
   `SheetPlacement` (`lib/ui/widgets/hud/enemy_sheet_view.dart`), `pickHoveredEntity`,
   `enemyBodyRect` et `unfoldsInward` (`lib/game/systems/entity_hover.dart`). **En Flame**, attachés
   à la carte qu'ils habillent : la barre (`EnemyHealthBar`), les languettes (`StatusTabs`),
   l'agrandissement de la carte ouverte et le voile d'estompage (`InspectionVeil`). **En Flutter**,
   dans le HUD : le panneau des intentions et le cadre de la fiche (`EnemySheetPanel`), qui
   n'importe aucun composant Flame (D12). **La fiche ouverte est un état d'affichage de
   `HerosDraftGame`** (`inspectedEnemy`, seul le jeu l'écrit), annoncé par un rappel unique,
   `onInspectionChanged(EnemyInspection?)` ; `GameScreen` le reflète **à la frame suivante**
   (`addPostFrameCallback`), le rappel pouvant venir pendant le `build` du `LayoutBuilder` de
   `GameWidget`. Aucune décision de Flame ne lit ce reflet.
2. **Le plein du voile d'armure est un état d'affichage de `EnemyCard`** (A2), calculé par
   `ArmorVeil.nextPeak` à chaque état appliqué : tout gain devient le plein (B16), un coup qui
   entame le laisse, zéro l'efface. La part couverte ne lit pas les PV (B15). Le mettre dans
   `EntityStats` l'aurait fait entrer dans la sauvegarde du héros.
3. **La zone d'une carte de combat est la règle unique du survol, de l'appui et du lâcher** (A3,
   A8, D3). `CombatEntity.zone` : le rectangle continu de la barre au bas de la carte, plus chaque
   languette, **par son rectangle dessiné et par son rectangle au repos** — déroulée vers
   l'intérieur au bord de l'écran (B39), elle quitte la bande où se trouve encore le pointeur.
   `zoneContains` sert `_livingEnemyAt`, l'arbitre du survol et `findHoveredEnemy` (la cible d'une
   carte qu'on glisse). La barre et les languettes portent `TapCallbacks` et **renvoient leur appui
   au `onTapDown` de leur carte** (D2, D13) : une languette déroulée sur la carte voisine ne joue
   jamais la carte sur la voisine. Le survol vient des seuls `PointerMoveEvent` de Flame — un doigt
   n'en produit pas : au doigt, rien ne se déroule (B14).
4. **Le toucher qui ouvre la fiche passe en dernier** (A10) : une carte focalisée garde le toucher,
   une signature armée reçoit l'ennemi, sinon l'ennemi vivant ouvre sa fiche, la garde ou remplace
   celle d'un autre ; seulement au tour du joueur (B35).
5. **La fiche se ferme par le pointeur que Flame vient de retenir** (A12). `GameScreen` enveloppe
   son `Stack` d'un `Listener` translucide qui, à chaque appui du bouton principal, appelle
   `closeInspectionUnlessOn(event.pointer)` : **Flame reçoit l'appui d'abord** ; s'il a ouvert ou
   gardé la fiche, il a retenu ce pointeur, que la fermeture lit puis oublie. Tout autre appui
   ferme — HUD et cadre compris. La décision ne lit ni un point ni le reflet. Flame ferme aussi de
   lui-même : carte focalisée, signature armée, décor, `executeTurn`, et `closeInspectionIfStale`
   après chaque état appliqué (ennemi parti, phase quittée, combat fini).
6. **L'échelle et la place d'une carte d'ennemi sont des écarts relatifs** (D10, D15, D16), parce
   que **chaque reconstruction de `GameScreen` rappelle `onGameResize`**, à taille inchangée.
   `baseScale` porte le facteur 1,25 de la fiche ; `_snapScale` laisse aller à son terme un
   agrandissement dont la cible n'a pas changé ; `place` et `animateInspection` ajoutent à la
   position l'écart entre la place visée et la précédente, si bien que les secousses d'un coup ne
   faussent plus l'arrivée ; `repositionEnemies` ne réémet le rectangle de la fiche que s'il a
   changé. La carte ouverte grandit vers le bas, sa barre à la hauteur des autres (B40).
7. **Ce qui a disparu** : `StatBadge` (`stat_badge.dart`), `StatusIndicator`
   (`status_indicator.dart`), `CircleProgressComponent` (`circle_progress.dart`), l'appui long sur
   la jauge (B13), `EnemyCard.getTranslation`, les trois tailles de badge de `GameConstants` et neuf
   clés ARB sans lecteur ; `onShowTooltip` ne sert plus qu'aux cartes (`CardType` non nul).
   `statusEmoji` quitte Flame pour `status_readout.dart`.
8. **Les décisions du propriétaire que l'ADR porte** : B6 pour la part qui ne dépend pas du langage
   des intentions — une pastille par intention d'aujourd'hui, sans compteur « +1 » ; B9 à B16 ; B31
   (la Puissance garde la flèche violette, exception à « la couleur de son statut » de B6) ; **B32,
   qui amende B14** (la Foudre chargée en jaune dans la languette de droite) ; B33 à B41.

### Preuves dans le code

- Les règles pures : les six fichiers du point 1 ; `test/unit/armor_veil_test.dart`,
  `intent_pips_test.dart`, `status_readout_test.dart`, `enemy_sheet_view_test.dart`,
  `entity_hover_test.dart`, `card_rule_texts_test.dart`.
- Flame : `lib/game/components/entities/enemy_health_bar.dart`, `status_tabs.dart`,
  `combat_entity.dart` (`zone`, `addStatusTabs`), `enemy_card.dart` (`baseScale`, `place`,
  `animateInspection`, `inspectionRect`), `hero_card.dart` ;
  `lib/game/components/visual_effects/inspection_veil.dart` ; `lib/game/heros_draft_game.dart`
  (`inspectEnemy`, `closeInspectionUnlessOn`, `closeInspectionIfStale`, `refreshEntityHover`) ;
  `lib/game/systems/layout_system.dart`, `state_sync_system.dart` ;
  `test/unit/combat_tap_forwarding_test.dart`, `heros_draft_game_targeting_test.dart`.
- Flutter : `lib/ui/widgets/hud/enemy_intents_panel.dart`, `enemy_sheet_panel.dart`,
  `lib/ui/screens/game_screen.dart` (le `Listener`, le reflet différé) ;
  `lib/tutorial/widgets/tutorial_combat_overview_widget.dart`, `lib/tutorial/tutorial_data.dart`.
- Priorités : `GameConstants.priorityEntityHovered` (5), `priorityInspectionVeil` (180),
  `priorityInspectedEnemy` (190), `inspectionScale` (1,25).

### Conséquences

- **1935 tests** (+69 sur la base de 1866 de la branche, S9 compris), `dart analyze` propre —
  vérifié le 2026-11-22 ; aucun test d'écran neuf ([ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)) ;
  25 tests manuels, T1 à T25, au cahier de la vague
  (`docs/superpowers/reports/2026-11-22-bestiaire-vague-1-tests-manuels.md`).
- **Dormant** : **le voile d'armure d'un ennemi**, qu'aucun ennemi du jeu ne déclenche encore
  (aucun ne gagne d'armure, et le menu de debug n'en pose pas sur un ennemi) — B12, B15 et B16
  livrés sans être visibles ; ils se verront avec la vague qui donnera de l'armure à un ennemi.
- **Ce que la vague de B1 devra fixer** : la lecture du « +1 » de B6, les pastilles de statut, la
  phrase d'une intention à plusieurs effets ; les seuils 6, 12 et 20 des paliers d'attaque, écrits
  trois fois.
- **Ce qui reste ouvert** (compte rendu de la vague, §0 et §4) : le cadre de la fiche n'a pas de
  hauteur maximale ; une languette intérieure plus large que sa carte recouvre l'autre (B39 n'en
  dit rien) ; `onGameResize`, rappelé à chaque reconstruction, coupe encore les secousses et l'effet
  de mort d'un ennemi (antérieur, seule la fiche en est protégée) ; la Puissance et la Foudre
  partagent l'émoji ⚡ ; `health_bar.dart` n'a aucun lecteur.
- Un seul changement visible que le propriétaire n'a pas tranché (V1, plan D14) : une carte
  focalisée visant les ennemis, les ennemis non sélectionnés gardent une bordure cyan sous leur
  halo, au lieu du blanc.
