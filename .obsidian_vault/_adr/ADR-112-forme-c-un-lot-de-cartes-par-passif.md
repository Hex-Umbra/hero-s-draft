---
description: P-42 tranche 1, form C — every passive gets its card folder cards/<passive>/, the folder injects CardData.passive, offers read the active passive (isOfferable(activePassiveId)), a passive with no lot card leaves the selection, PassiveData.classes holds exactly one class and feeds names what a lot card must touch, three lots ship (Rampart, Blood, Arcanist), Focus is removed and Demon Form moves, and the starter draft becomes two quotas, two lot cards and three neutrals
---

# ADR-112 — La Forme C : un Lot de Cartes par Passif, le Passif Injecté par le Répertoire, et le Masquage d'un Passif sans Lot

### Statut

✅ Accepté — 2026-11-04 (P-42, **tranche 1** ; brainstorm v3, décisions D8, D9, D10, D15, D16, D17,
D28, D34 pour l'ordre, D45, D50, D63 ; réponses du propriétaire Q8, Q9, O5). **Livré sur la branche
`feat/v0.5.7-p42-tranche-1-p44-lot-1` — vague 5 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Partie 2 de la vague : code
`3a6d218f`..`0c15ffee` et le correctif de revue `d339ce6a`, sur le plan `b271e85e`. P-42 reste
ouvert : deux tranches à venir (vagues 6 et 8). **Amende
[ADR-109](ADR-109-signatures-hors-du-deck.md)** : `CardData.isOfferable` reçoit le passif actif.
**Complète** [ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md) (le
répertoire injecte aussi le passif), [ADR-096](ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md)
(la disponibilité gagne une condition) et [ADR-100](ADR-100-console-de-contenu-vocabulaire-du-moteur-et-ident.md)
(une dixième catégorie d'éditeur). Conception :
[spec](../../docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §3.2 à §3.5, §4.8,
§4.9, §7 — arbitrages A1 à A10 et leurs motifs.

### Contexte

En `0.5.6`, le catalogue comptait 17 cartes neutres et rien d'autre : les signatures avaient quitté
les cartes (ADR-109), et aucune carte n'appartenait à un passif. Le brainstorm v3 fait de chaque
passif un archétype de deckbuilding : un lot de 5 à 6 cartes que seul ce passif reçoit (D10, D16),
rangé là où le répertoire dit à qui il appartient (D15). Livrer neuf lots d'un coup était hors de
portée ; livrer trois lots laissait six passifs sans cartes.

### Décision

**D1 — La forme C** (D10, D15, A1, A2). `assets/data/cards/<id>.json` est une neutre ;
`assets/data/cards/<passif>/<id>.json` est une carte du lot de ce passif. Le nom du dossier **est**
l'id du passif. Deux `EntitySource` : la première injecte `passive: null`, la seconde le dossier.
`passive` n'est jamais écrit dans un fichier — le chargeur le refuse —, et aucune valeur `lot` ni
`category` ne revient (Q10 sans objet).

**D2 — L'offre lit le passif actif** (A3, amende ADR-109). `isOfferable(activePassiveId)` : les
neutres et le lot du passif de la run, jamais un statut. Trouvaille, boutique, draft de départ et
pool du tutoriel le lisent ; les sources qui copient le deck (Miroirs, copie de boutique, boss
« cartes ») ne changent pas.

**D3 — Un passif sans lot quitte la sélection** (O5, A4). `availablePassivesFor` rend les passifs
**éligibles et pourvus d'un lot** — au moins une carte du registre porte leur id —, sans liste en
dur : le lot d'une tranche suivante ouvre son passif sans code. Une sauvegarde sous un passif masqué
reprend avec lui (`PassiveData.getById` ne lit pas la disponibilité).

**D4 — Un passif, une classe, et ce qu'il nourrit** (D9, D45, A5, A6). `PassiveData.classes` vaut
exactement une classe ; `feeds`, exigé et non vide, liste ce qu'une carte du lot doit toucher, en
cinq formes (un type de carte, un type d'effet, `status:<id>`, `cost:hp` ou `cost:armor`,
`scale:<source>`).
`LotRules.faultsOf` — lu par le test du catalogue et par l'éditeur — refuse une carte de lot qui ne
touche aucune entrée, ou qui coûte de l'Armure sous une classe qui convertit la sienne (A7, lu sur
la `statRule`, jamais sur l'id).

**D5 — Trois lots, six cartes chacun** (D16, D34, Q8). **Rempart** (`regen_armor`, Paladin),
**Sang** (`rage`, Berserker), **Arcaniste** (`mana_flux`, Mage) ; toutes communes, aucune carte-pont,
aucune à coût total nul. *Focalisation* (`focus`) est supprimée (D28) ; *Forme Démoniaque* passe
dans le lot Sang, contenu inchangé. Le noyau neutre compte 15 cartes.

**D6 — Le draft de départ, deux quotas** (Q9, D63). `StarterDraft` : `min(2, taille du lot)` cartes
du lot et le reste de 5 en neutres ; choisir au-delà d'un quota refuse et notifie ; « Valider »
attend les deux quotas. Le tutoriel suit, sa carte d'un groupe plein se grisant comme au jeu (S11).

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Les deux sources de cartes | `lib/services/game_data_service.dart` (`cardSources`) |
| `passive`, `isOfferable(activePassiveId)` | `lib/models/data/card_data.dart` |
| Le masquage | `lib/game/systems/passive_availability.dart` |
| `classes`, `feeds`, leurs formes | `lib/models/data/passive_data.dart`, `lib/models/data/passive_feeds.dart` |
| Les règles d'une carte de lot | `lib/models/data/lot_rules.dart` ; `test/unit/` (catalogue, intégrité référentielle) |
| Les trois lots | `assets/data/cards/regen_armor/`, `cards/rage/`, `cards/mana_flux/` |
| Le draft à deux quotas | `lib/game/systems/starter_draft.dart` ; `lib/ui/screens/starter_deck_draft_screen.dart` ; `lib/tutorial/widgets/tutorial_starter_deck_widget.dart` |
| La carte de lot dans l'éditeur | `lib/services/content_editor/` (`entity_catalog.dart`, `entity_validator.dart`), commit `0c15ffee` |

Règles de jeu : [`_rules/02-3`](../_rules/02-3-catalogue-de-cartes.md),
[`_rules/02-2`](../_rules/02-2-systeme-de-heros.md) §Passifs ; chargeur :
[`_patterns/17-00`](../_patterns/17-00-chargeur-de-donnees-generique-et-motifs-de-che.md).

### Conséquences

- **Une classe, un passif jouable, jusqu'à la tranche 2** : *Régénération d'Armure*, *Rage*, *Flux
  de Mana*. Le Mage démarre donc sur *Flux de Mana*, tutoriel compris. Le libellé « Passifs » et son
  chevron restent avec un seul passif (S10).
- **Un dossier de lot est un dossier d'assets** : `dart run tool/sync_assets.dart` le déclare dans
  `pubspec.yaml`, et l'étape 2 du flux de contenu de `CLAUDE.md` ne le dit pas encore
  (`docs/ROADMAP.md` §8).
- **Le pool d'une run compte 15 neutres et 6 cartes de lot**, non les 9 + 6 que la simulation a
  jouées : les six neutres de trop attendent leurs lots (spec §2.1).
- **L'éditeur accepte une carte à `costs.armor` sous un passif sans classe unique** (S12) — à la file
  ; `draftDeckSubtitle` dit « 2 + 3 » quand le lot manque (compte rendu §4).
- **La simulation ne lit pas `cards/*/*.json`** et ne tourne plus depuis E4 — accepté (ADR-108 D5).
