---
description: Six end-of-wave-8 fixes chosen by the owner on mockups — the save is erased the moment the hero dies (a listener on runProvider.isDead, and SaveService.save refuses a dead hero), no longer by the death screen's buttons; the sharpen selection lists only cards with a sharpenable rune instead of greying the others; the enemy intents panel becomes one compact row per enemy with a hover / long-press tooltip, capped above End Turn; hand hover is decided by one pure geometric arbiter instead of per-card HoverCallbacks, and the fan widens with the available width; one shared calculator, DisplayedEffectValue, gives every in-combat displayed value, signatures included; a negative max-HP event action reads "-12 Max HP"; amends ADR-106 A4, completes ADR-069, ADR-114 and ADR-118
---

# ADR-119 — Les Corrections de Fin de Vague 8

### Statut

✅ Accepté — 2026-11-19 (corrections de fin de vague, avant la clôture de la vague 8 ; six lignes de
`docs/possible_upgrades/upgrade_ideas.md`). Options présentées sur maquettes dans
`docs/presentations/2026-11-19_corrections_fin_vague_8_lot_1_maquettes.pptx` et retenues par le
propriétaire le 2026-11-19 : **B** pour le panneau des intentions (lignes compactes, plus une
infobulle par intention, ajoutée par le propriétaire), les recommandations pour les quatre autres ;
la sixième, un signe en trop, sans présentation. **Livré sur la branche `feat/v0.6.0-p42-tranche-3`**,
un commit par point (`70fce82b`, `2e6c440f`, `c921d52e`, `c64f66ff`, `4db6c1bb`, `ee60f62f`), tests
manuels C1 à C6 et section « Corrections et Améliorations » de la note 0.6.0 (`40974c0f`) ; tests C1 à C6
**validés par le propriétaire le 2026-11-19 ; en attente de la fusion et du tag.** Rien n'en est dans `main`.

**Amende [ADR-106](ADR-106-fusion-egale-forge.md) A4** (la carte sans rune affûtable n'est plus
grisée, elle n'est plus listée). **Complète [ADR-069](ADR-069-systeme-de-sauvegarde-de-run-checkpoint-carte-refr.md)**
(point 3 : l'effacement à la mort a lieu à la mort, plus au clic),
**[ADR-114](ADR-114-les-evolutions-de-signature.md)** (A40 : la tuile lit ses valeurs d'un calcul
partagé, toujours sans widget qui calcule) et **[ADR-118](ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md)**
(la vague qu'elles corrigent). Chacun de ces ADR ne change que de Statut.

**Fusionné dans `main` le 2026-11-19 par la PR #56** (commit de fusion `84a1ee34`), avec la vague 8, tagué `v0.6.0` sur ce commit ; CI de tête `44548499546` et `release.yml` run `44556736195` verts — re-vérifié par `gh` le 2026-11-19.

**Point 3 amendé le 2026-11-22 par [ADR-121](ADR-121-l-interface-des-ennemis-en-combat.md)** (P-05
vague 1, livré sur la branche `feat/v0.6.1-interface-des-ennemis`, test du propriétaire passé le 2026-11-22, en attente de la PR, de
la fusion et du tag du propriétaire) : le panneau perd les PV et passe en trois colonnes, niveau, nom,
pastilles ; l'infobulle enveloppe la rangée des pastilles, son contenu inchangé.

### Contexte

Le propriétaire a relevé, au fil des vagues, des défauts que la vague 8 corrige avant sa fusion :
sur un petit écran face à cinq ennemis, le panneau des intentions cachait « Fin de Tour » ; sur le
web, F5 sur l'écran de mort rechargeait le combat perdu, la sauvegarde n'étant effacée qu'au clic
d'un bouton ; au-delà de cinq cartes, certaines cartes du milieu de la main ne se survolaient pas —
chaque `CardComponent` recevait ses `HoverCallbacks`, et deux cartes qui se chevauchent se
disputaient le survol ; la tuile d'une signature affichait 15 là où la carte infligeait 17 (la
Puissance n'y était pas) ; l'affûtage listait des cartes grisées qu'on ne pouvait pas prendre ; la
*Fontaine Bénie* affichait « +-12 PV Max ».

### Décision

1. **La mort efface la sauvegarde, sur-le-champ.** `autosaveOrchestratorProvider` écoute
   `runProvider.select((run) => run.isDead)` et appelle `SaveService.clear` dès que le héros meurt ;
   `SaveService.save` refuse un héros mort, pour qu'aucun checkpoint pris après la mort ne recrée la
   sauvegarde. `DeathOverlay` ne fait plus que naviguer. Une run debug reste hors persistance
   ([ADR-087](ADR-087-run-debug-declaree-au-lancement-et-verrou-de-persis.md)). **Quitter un combat
   sans mourir** rejoue toujours le combat (ADR-069) — la question est ouverte dans `upgrade_ideas.md`.
2. **L'affûtage ne liste que les cartes affûtables.** `RestCardSelectionScreen`, en mode affûtage,
   filtre le deck par `ForgeRuneRules.hasSharpenableRune` (plafond effectif compris) ; sans carte,
   le message `restCampSharpenNone`. `isGrayedOut` quitte `UiCard` et `getCardBackgroundColor` ;
   `sharpenNothingOnCard` disparaît. L'option « Affûter » reste inactive quand rien ne peut monter.
3. **Le panneau des intentions : une ligne par ennemi, une infobulle par intention.** Nom, « Niv. N »,
   PV, une pastille icône + valeur ; au survol ou à l'appui long, le libellé complet et une phrase
   (« À son tour, … attaquera le héros pour 25 dégâts. ») ; un ennemi gelé a sa pastille barrée, et
   sa bulle dit qu'il ne fait rien. Hauteur bornée par `intentsPanelMaxHeight` (H / 2 − 151, au
   moins 100), défilement au-delà ; « Fin de Tour » se peint au-dessus du panneau.
4. **Le survol de la main : un arbitre géométrique unique.** `CardComponent` perd `HoverCallbacks` ;
   `HerosDraftGame.refreshHover` lit la dernière position du pointeur et demande à
   `pickHoveredCard` (`lib/game/systems/hand_geometry.dart`, pur) la carte au-dessus : la plus haute
   carte au repos qui contient le pointeur l'emporte, la carte survolée n'est gardée que là où aucune
   carte au repos ne le contient. L'arbitre est rappelé à chaque mise en page ; sortir de la fenêtre
   ou commencer un glisser oublie le pointeur. L'éventail s'ouvre selon la largeur disponible
   (`handAngleStep`, entre les deux panneaux latéraux, `handSideReserve` = 286), jamais plus serré
   qu'avant ni plus ouvert que 0,08 rad par carte.
5. **Une seule règle du chiffre affiché en combat** : `DisplayedEffectValue`
   (`lib/game/services/displayed_effect_value.dart`) — valeur + terme de croissance + Puissance par
   coup pour un `damage`, bonus de statut pour le premier `apply_status`, « ×coups » dès deux coups,
   avant ce que la cible y change et sans critique. Le badge et l'infobulle des cartes, la bande et
   la liste des signatures la lisent ; `CardTextRenderer` n'a plus de calcul propre.
6. **Une perte de PV max s'écrit « -N PV Max »** : `EventScreen.maxHpText` choisit `eventLoseMaxHp`
   pour une valeur négative de `gain_max_hp`, badge rouge à icône « moins », comme les autres pertes.

### Preuves dans le code

- `lib/game/controllers/checkpoint_controller.dart`, `lib/services/save_service.dart`,
  `lib/ui/widgets/hud/death_overlay.dart` ; `test/unit/checkpoint_autosave_test.dart`.
- `lib/ui/screens/rest_card_selection_screen.dart`, `lib/ui/widgets/ui_card/ui_card_helpers.dart`.
- `lib/ui/widgets/hud/enemy_intents_panel.dart`, `lib/ui/widgets/hud/combat_side_panels.dart` ;
  `test/unit/enemy_intents_panel_texts_test.dart`.
- `lib/game/systems/hand_geometry.dart`, `lib/game/heros_draft_game.dart`,
  `lib/game/systems/layout_system.dart` ; `test/unit/hand_geometry_test.dart`.
- `lib/game/services/displayed_effect_value.dart`, `lib/ui/widgets/hud/signature_bar.dart` ;
  `test/unit/displayed_effect_value_test.dart`.
- `lib/ui/screens/event_screen.dart` ; `test/unit/event_max_hp_text_test.dart`.

### Conséquences

- **1859 tests** (+33 sur les 1826 de la vague 8 livrée), `dart analyze` propre — vérifié le
  2026-11-19 ; aucun test d'écran neuf (D77), six tests manuels C1 à C6.
- **Ce qui reste ouvert** : la main ne se redessine pas sur un changement du seul `CombatState`
  (antérieur) ; la phrase de l'appui long d'une signature n'écrit pas encore « ×N » (aucune
  signature multi-coups aujourd'hui) ; quitter un combat avant de mourir, à trancher.
