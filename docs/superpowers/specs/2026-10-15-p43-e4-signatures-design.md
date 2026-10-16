# P-43 E4 — Les signatures en compétences de classe — Conception

Date : 2026-10-15
Statut : **Conception** — vague 4 (`0.5.6`), branche `feat/v0.5.6-p43-e4-signatures`

Chantier ROADMAP : **P-43** « Économie unifiée », lot **E4**, le dernier des cinq lots E0 à E4 (D53). Le déroulé
fait foi dans le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§8.4 ; les décisions, dans le [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1
et §4.4.

> **Ce qu'E4 livre, en une phrase.** Les six signatures quittent les cartes : deux par classe, rangées sous
> `classes/<id>/skills/`, hors du deck, jouables dès le premier tour de chaque combat depuis une barre à gauche
> du HUD, pour leur coût d'aujourd'hui et une recharge de deux tours — résolues comme une carte, jamais piochées,
> défaussées, épuisées, offertes ni copiées ; la rareté `unique`, `isAcquirable` et `CardCategory` disparaissent
> avec elles.

Toute référence `fichier:ligne` de ce document a été lue le 2026-10-15 sur `d0ac431`.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce qu'E4 en livre | Où |
|:---|:---|:---|
| **D49** | Deux signatures par classe, hors du deck, listées par `HeroData.skills` ; coût en mana, recharge en tours ; ni piochées, ni défaussées, ni offertes, ni clonées ; `classes/<id>/cards/` devient `classes/<id>/skills/` ; `unique` et `characterSpecific` supprimées ; barre au HUD, tutoriel, draft de départ, sauvegarde. Vocabulaire : **signature** | §3 à §9 |
| **D41** | Disponibles dès le premier tour de chaque combat : la recharge naît vide à chaque combat | §4.2 |
| **D53** | Dernier lot de E ; l'écran d'évolution reste à la vague 5 — E4 crée `SignatureInstance`, sur laquelle elle écrira | §4.1 |
| **D7** (forme) | Une signature ne reçoit plus de rune : aucun chemin de rune n'atteint ce qui n'est pas dans le deck | §4.6 |
| **D28** | `magic_missile` passe au type `skill` | §3.2, §4.5 |

### 1.2. Les réponses du propriétaire (classe P), reprises telles quelles

| Question | Réponse |
|:---|:---|
| Coût et recharge | Une recharge de **2 tours pour les six**, aux **coûts d'aujourd'hui** — Châtiment 1, Bouclier Sacré 1, Frappe Téméraire 2, Posture de Rage 1, Projectile Magique 1, Surtension de Mana 0. Elles « reviennent tous les deux tours » : jouée au tour 1, une signature est rejouable au tour 3 (sémantique exacte : §4.2) |
| Épuisement | **Il disparaît.** Bouclier Sacré et Surtension de Mana passent en recharge comme les quatre autres |
| Déclencheurs de passif | **Oui.** Une signature jouée est résolue comme une carte et déclenche les passifs de son type. *Marque du Mage* ne se déclenche plus sur Projectile Magique, devenu Compétence : voulu, la note le dit |
| Les reliques voient-elles une signature jouée ? (Q-P1, née à l'écriture, répondue le 15/10) | **Oui.** Les quatre reliques qui réagissent à une carte jouée — *Amulette du Mage* et *Plume de scribe* (`onCardPlayed`), *Shuriken* et *Croc Kunaï* (`onAttackPlayed`) ; `PlayerStatsManager.applyRelics`, `player_stats_manager.dart:236`, leurs charges `:327`, `:361`, `:396` — voient une signature jouée par le même événement que les passifs : « résolue comme une carte » vaut pour tout ce qui écoute une carte jouée, un seul chemin dans le code (§4.3, étape 6). La note dit qu'une signature compte comme une carte de son type |
| Le tutoriel enseigne-t-il la barre par un geste ? (Q-P2, née à l'écriture, répondue le 15/10) | **La prose seule**, dans l'étape « Votre deck de départ » (§7.2) ; pas d'étape jouable de plus |

### 1.3. Les arbitrages

**A1 — Le modèle : un `SignatureData` propre** *(T, filtre 1)*. Un `CardData` restreint garderait les signatures dans
`registry.cards`, que lisent la boutique, la trouvaille, le dictionnaire, le draft de départ et le menu de debug ;
chacun devrait les écarter, alors que D49 dit qu'elles ne sont plus des cartes. Un modèle à part, dans une liste à
part du registre (`registry.signatures`), les tient hors de tout pool **par construction**. La résolution ne
duplique rien : une signature se joue par une **vue de carte** construite à la volée (§4.1), que `resolveCard` et
les stratégies lisent sans changer.

**A2 — `CardCategory` disparaît, enum et champ** *(T, filtre 5)*. Avec `characterSpecific` partie, `global` serait
seule : un champ toujours égal à la même valeur, un filtre de draft tautologique — du code sans information, que
`CLAUDE.md` exclut. Le chargeur cesse d'injecter `category`. La question Q10 de la vague 5 (`global` + `passive`, ou
une valeur `lot`) reste entière : réintroduire une énumération y sera un choix, pas une restauration.

**A3 — Les noms : `Signature…`, et l'interdit d'ADR-084 n'est pas levé** *(T, filtre 1)*. D49 fixe le mot
(« on dit toujours signature ») et le brainstorm nomme déjà `SignatureInstance` et `SignatureEvolutionData`. Aucun
nom de l'ancienne chaîne n'est repris : `SignatureData`, `SignatureInstance`, `playSignature`, `signaturesReadyOn` ;
la recharge se **dérive** du compteur de tours (§4.2), sans aucune fonction qui décompte. L'invariant de purge
d'ADR-084 reste vrai tel quel — son motif `skills\.json` ne reconnaît pas `skills/<id>.json`. Seuls `HeroData.skills`
et le répertoire `skills/`, imposés par D49, portent le mot.

**A4 — Les signatures entrent dans l'éditeur de contenu, comme neuvième catégorie** *(T, filtre 5)*. Mesuré :
l'éditeur n'existe qu'en debug (`home_screen.dart:173-178`, `kDebugMode` ; l'entrée est `:474-478`, dans le menu
de debug) — la question reste T. L'éditeur porte aujourd'hui toute une mécanique de propriété pour la carte de
classe : chemin sous la classe (`entity_descriptor.dart:172-180`), catalogue par propriétaire
(`entity_catalog.dart:30-37`, `:63-68`), bijection `skills` ↔ dossier (`entity_validator.dart:482-532`),
inscription dans `skills` à l'écriture (`entity_writer.dart:263-290`), signatures écrites par la recette de classe
(`class_recipe.dart:13-14`, `:93-100`). Sans E4, elle écrirait dans un dossier que plus rien ne charge. La
transposer à la signature garde la règle « une source de chargement, un descripteur » que garde
`entity_descriptor_test.dart:12-35` — neuf sources pour neuf catégories, l'écart assumé de la carte disparaît — ;
la retirer ferait un trou dans cette règle et du code à rebâtir.

**A5 — Le découpage en deux parties** *(T, filtre 7)* : §11.

**A6 — La barre au HUD : sa place, ses états, son ciblage** *(T, délégué par le propriétaire, filtre 6 puis 5)*.
À gauche, au milieu de l'écran, en miroir du bouton de fin de tour : les actions du tour encadrent le héros, et
le joueur lit la barre et le bouton d'un même regard. Chaque tuile dit sur elle-même pourquoi elle n'est pas
jouable — tour ennemi, recharge avec son compte de tours, mana. Le ciblage reprend le geste du clic-pour-jouer
d'une carte : toucher la signature, puis l'ennemi. Flame ne connaît pas les signatures — il rapporte seulement
qu'un ennemi a été choisi, par un rappel qui existe déjà et que rien n'appelle ; le glisser depuis la barre,
écarté, demanderait à Flutter de lire les positions des composants Flame. Forme complète : §5.

**A7 — La recharge s'écrit comme un tour de disponibilité, pas comme un compteur** *(T, filtre 8)*. Les deux
formes donnent la sémantique du propriétaire. Le tour de disponibilité s'écrit une fois, au jeu de la signature,
se lit par une soustraction, et ne demande aucun décompte dans l'ouverture du tour — donc aucun ordre d'appel à
tenir dans `startPlayerTurn` ; il se remet à zéro avec l'état de combat. §4.2.

**A8 — La liste des signatures de la run vit dans `RunState`, relue de la classe, jamais sérialisée** *(T,
filtre 5)*. L'état de la run vit dans `RunController` ; une signature d'E4 n'a encore aucun état propre à la run :
c'est du contenu, relu de la classe à la reprise exactement comme `statRules`
(`run_controller.dart:64-72`). La vague 5 y ajoutera les évolutions — et leur sérialisation — sans déplacer le
champ.

**A9 — Le draft de départ adopte le prédicat d'offre** *(T, filtre 5)*. ADR-101 D3 le tenait à `category == global`
parce que les signatures étaient ajoutées d'office et ne devaient pas être prenables deux fois. Ce motif part
avec elles, `category` aussi : un seul prédicat — `isOfferable`, A13 — dit désormais quelles cartes un joueur peut
recevoir, au départ comme en cours de run.

**A10 — `CardData.heroClass` est retiré, et une carte qui déclare `heroClass` ou `category` échoue au chargement**
*(T, filtre 5 — tranché par l'orchestrateur au premier tour de vérification)*. Après E4, plus aucune source
de cartes n'injecte `heroClass` : le champ serait toujours nul, sa clause dans `isOfferableTo` toujours vraie — le code sans
information qu'A2 retire. Pire, l'appartenance passerait du répertoire au fichier : une carte neutre qui déclarerait
`heroClass` deviendrait une carte de classe, et `category`, refusée aujourd'hui parce que la source l'injecte
(`game_data_loader.dart:226-237` ; `game_data_service.dart:80`), serait ignorée en silence. `CardData.fromJson`
refuse donc les deux clés, nommées, comme A11 pour une signature ; `toJson` ne les écrit plus. La vague 5
réintroduira l'appartenance par un `passive` injecté.

**A11 — Un fichier de signature refuse les champs de carte** *(T, filtre 5)*. `rarity`, `isExhaust` et `category`
dans un `skills/<id>.json` échouent au chargement, nommés : un `isExhaust: true` resté par mégarde serait sinon
une promesse silencieuse que le moteur ne tient pas — l'esprit d'ADR-086.

**A13 — Le prédicat d'offre devient `CardData.isOfferable`, sans paramètre** *(T, filtre 5 — né de A10)*. Sans
`heroClass`, `isOfferableTo(String heroClassId)` garde un paramètre que rien ne lit. Le prédicat reste unique
(ADR-101 D1) et devient un accesseur : `type != CardType.status`. Ses lecteurs — boutique
(`shop_controller.dart:56`), trouvaille (`reward_controller.dart:221`), draft de départ, `starterPool` du
tutoriel — n'ont plus d'id de classe à passer. La vague 5 lui donnera le passif actif.

**A12 — Le test de la transition E3 → E4 est retiré** *(T, filtre 5)*. `test/unit/signature_cards_transition_test.dart`
gardait l'état transitoire — les signatures exclues de la trouvaille par `unique`, sans rune, au rang 0. Ce qu'il
protégeait devient une propriété du registre : aucune signature n'est une carte. Elle se garde là où elle vit
(§10, intégrité).

### 1.4. Les questions ouvertes

Aucune. Les deux questions de classe P nées à l'écriture ont reçu la réponse du propriétaire (§1.2). Aucune
question de classe D : rien n'exige d'amender une décision acquise.

---

## 2. Périmètre

**Dans E4** : les six fichiers déplacés et leur modèle ; le chargeur, le registre, `sync_assets` ; `SignatureInstance`
et sa vue de carte ; la recharge dans l'état de combat ; `CombatController.playSignature` ; la suppression de
`CardRarity.unique`, `isAcquirable`, `CardCategory`, `CardData.heroClass` et de tout ce qui les lit ; la barre au HUD et son ciblage ; le
draft de départ à 5 cartes ; la sélection de classe et l'onglet du dictionnaire ; le tutoriel ; l'éditeur de contenu ;
la sauvegarde ; les textes, en français et en anglais.

| Hors d'E4 | Où |
|:---|:---|
| `SignatureEvolutionData`, les pools, `SignatureInstance.evolutions` et leur sauvegarde, l'écran, *Célérité* | Vague 5 (D19, D21, D54) |
| `onDamagingCardPlayed` — *Marque du Mage* sur la première carte de dégâts | Vague 7 (D34) |
| Toute carte, toute rune ; l'appartenance des cartes par passif (`passive` injecté, Q10) | Vague 5 |
| Tout rééquilibrage des six signatures au-delà de l'épuisement retiré | — |
| `tool/simulations/` : il lit `classes/*/cards/` (`d26_economy_sim.dart:866`) et cessera de tourner — accepté (ADR-108 D5) ; il reste `dart analyze` propre, aucune ligne n'y change | — |

---

## 3. Données

### 3.1. Le fichier d'une signature

`assets/data/classes/<classe>/skills/<id>.json` — le nom est l'`id`, le dossier est la classe :

```json
{
  "id": "smite",
  "name_en": "Smite",
  "name_fr": "Châtiment",
  "description_en": "Deal 6 damage and gain 4 Block.",
  "description_fr": "Inflige 6 dégâts et donne 4 d'Armure.",
  "cost": 1,
  "cooldown": 2,
  "type": "attack",
  "target": "singleEnemy",
  "animation": "melee",
  "effects": [
    { "type": "damage", "value": 6 },
    { "type": "armor", "value": 4 }
  ]
}
```

| Clé | Règle au chargement (`SignatureData.fromJson`) |
|:---|:---|
| `cost` | Entier ≥ 0, exigé |
| `cooldown` | Entier **≥ 1**, exigé — 1 veut dire « une fois par tour » ; 0 est refusé, c'est le plancher de *Célérité* (D54) |
| `type` | `attack`, `skill` ou `power` ; `status` est refusé (`canPlayCard` ne joue jamais un statut, `effect_resolver.dart:112-114`). Lu par la Puissance (`power_rules.dart:17-21`) et par les déclencheurs |
| `target` | Comme une carte, `singleEnemy` par défaut |
| `effects` | Non vide ; mêmes effets que les cartes, même registre de stratégies |
| `animation`, `sfx` | Comme une carte : `SignatureData` implémente `AudioSource` |
| `name_*`, `description_*` | Les quatre, bilingues (`CLAUDE.md`) |
| `heroClass` | **Exigé, et injecté** depuis le dossier ; le déclarer échoue (ADR-086). L'éditeur l'ajoute de même avant de construire (§8) |
| `rarity`, `isExhaust`, `category` | **Refusés**, nommés (A11) |

Pas de `toJson` : une signature n'est jamais sérialisée (§9). Pas de `getById` : elle se retrouve par sa classe
(§3.3).

### 3.2. Les six fichiers

Déplacés de `classes/<classe>/cards/` vers `classes/<classe>/skills/`, sans autre changement que ceux-ci :

| Signature | Classe | Coût | `cooldown` | Type | Change |
|:---|:---|:---:|:---:|:---|:---|
| `smite` — Châtiment | paladin | 1 | 2 | attack | `rarity` retirée |
| `holy_shield` — Bouclier Sacré | paladin | 1 | 2 | skill | `rarity` et **`isExhaust`** retirés |
| `reckless_strike` — Frappe Téméraire | berserker | 2 | 2 | attack | `rarity` retirée |
| `rage_form` — Posture de Rage | berserker | 1 | 2 | skill | `rarity` retirée |
| `magic_missile` — Projectile Magique | mage | 1 | 2 | **skill** (était `attack`) | `rarity` retirée ; **D28** |
| `mana_surge` — Surtension de Mana | mage | 0 | 2 | skill | `rarity` et **`isExhaust`** retirés |

Noms, descriptions, cibles et effets ne changent pas. Les trois dossiers `classes/<classe>/cards/` disparaissent ;
`class.json` garde `skills` tel quel (D49).

### 3.3. Chargeur, registre, `sync_assets`

| Élément | Aujourd'hui | Avec E4 |
|:---|:---|:---|
| Source des cartes de classe | `game_data_service.dart:82-90` — `classes/*/cards/*.json`, injecte `heroClass` et `category: characterSpecific` | **Retirée** |
| Source des signatures | — | `EntitySource('assets/data/classes/*/skills/*.json', SignatureData.fromJson, inject: (c) => {'id': c[1], 'heroClass': c[0]})`, dans `loadGameDataRegistry` — la source n° 9, le compte ne bouge pas |
| Source des cartes neutres | `:77-81` — injecte `category: global` | N'injecte plus que `id` |
| Registre | — | `GameDataRegistry.signatures`, `List<SignatureData>`, **défaut `const []`** comme `levelUpRewards` : les registres de test ne cassent pas |
| Lien de classe | `HeroSkillsLink.getHeroCards` (`hero_skills_link.dart:6-13`), cherche dans `cards` | `getSignatures(GameDataRegistry)`, `List<SignatureData>` dans l'ordre de `skills`, **fail-fast** comme aujourd'hui |
| `pubspec.yaml` | `:38`, `:40`, `:42` déclarent les trois `cards/` | `dart run tool/sync_assets.dart` les remplace par les trois `skills/` ; vider `build/unit_test_assets` avant de croire `real_bundle_load_test` |

### 3.4. Ce qui disparaît

| Élément | Site |
|:---|:---|
| `CardRarity.unique` et ses bras de `switch` | `card_data.dart:17`, `:29`, `:39`, `:49` ; `model_extensions.dart:23-24`, `:40-41` ; `shop_controller.dart:47-48` ; `card_component.dart:139`, `:149`, `:309` ; `ui_card.dart:201` et `PolychromaticBorder.isUnique` (`polychromatic_border.dart:8`, `:16`, `:68`, `:85`, `:93`, `:99`, `:220`) ; `ui_card_helpers.dart:188`, `:289` ; `AppColors.rarityUnique` (`app_colors.dart:44`) et `GameThemeExtension.rarityUnique` ; `kRarityColors['unique']` (`editor_style.dart:125`) |
| `CardRarity.isAcquirable` | `card_data.dart:78-81` ; ses lecteurs : `isOfferableTo` (`:173`), `DeckState.copyableCards` (`deck_controller.dart:54-55`) |
| `CardCategory` et `CardData.category` | `card_data.dart:9`, `:124`, `:196-199`, `:229` ; l'injection (`game_data_service.dart:80`, `:88`) ; le filtre du draft (`starter_deck_draft_screen.dart:55-57`) et du tutoriel (`tutorial_fixtures.dart:63-64`) |
| `CardData.heroClass`, sa clause d'offre et son écriture | `card_data.dart:125`, `:145`, `:174`, `:200`, `:230` (A10) ; `isOfferableTo` devient `isOfferable` (A13) |
| La réparation B5 d'ADR-094 D6 | `deck_controller.dart:95-99` : une instance `unique` ne peut plus exister |
| `HeroSkillsLink.getHeroCards` | Remplacée (§3.3) |

Restent, recentrés : `copyableCards` (le deck entier, toujours le seul point des quatre sources de copie) ;
`isOfferable` (`type != status`, A13) ; `fusionRank`, `next`, `multiplier` sur cinq raretés. Les commentaires qui
citent `` `unique` `` comme cas d'exemple sont réécrits : `deck_controller.dart:58`, `:313` ; `shop_controller.dart:98` ;
`forge_rune_rules.dart:93` ; `tutorial_engine.dart:255-262`, `:427` — ceux de `card_data.dart:21`, `:23`, `:33`,
`:47`, `:79` partent avec le code qu'ils commentent, `deck_controller.dart:95` avec la réparation B5. Deux autres
commentaires suivent les renommages : `forge_rune_rules.dart:62` (« `CardData.isOfferableTo` » → `isOfferable`) et
`entity_validator.dart:203` (la liste des énumérations à repli silencieux perd `CardCategory`).

**Reste, et n'est pas une rareté** : `ui_card_helpers.dart:17`, `t.contains('unique')` dans `resolveTarget` — un mot
clé de **cible**, qui reconnaît le libellé traduit « Cible unique » (`app_fr.arb:187`) et rend `singleEnemy`. Il
n'est pas touché ; le contrôle de §12 l'écarte par son contenu.

---

## 4. Le moteur

### 4.1. `SignatureInstance` et sa vue de carte

`lib/models/signature_instance.dart` — **la signature telle qu'elle se joue** : `SignatureInstance(SignatureData data)`,
avec `cost`, `cooldown` et `asCard`. En E4 ces trois lectures rendent la donnée ; la vague 5 y appliquera les
évolutions, sans que leurs lecteurs changent.

`asCard` construit une `CardInstance` neuve : un `CardData` qui reprend `id`, noms, descriptions, `cost`, `type`,
`target`, `animation`, `sfx` et `effects` de la signature, `isExhaust: false`, rareté
`common` ; l'instance est `common`, sans rune. À `fusionRank` 0, G1 rend la valeur de base
(`card_data.dart:69-76`) : la vue joue exactement le fichier. Elle n'entre dans aucune pile et ne survit pas au jeu.

### 4.2. La recharge

`CombatState` gagne `signaturesReadyOn`, `Map<String, int>` : par id de signature, **le tour à partir duquel elle se
rejoue**. Absente = disponible. Deux lectures :

- `signatureTurnsLeft(id)` = `max(0, signaturesReadyOn[id] − turnCount)`, 0 si absente ;
- `isSignatureReady(id)` = `signatureTurnsLeft(id) == 0`.

Jouée au tour T : `signaturesReadyOn[id] = T + cooldown`. `turnCount` monte d'un à chaque fin de tour ennemi
(`turn_phase_manager.dart:85-91`).

| `cooldown` | Jouée au tour | Affiche, aux tours T · T+1 · T+2 | Rejouable au tour |
|:---:|:---:|:---|:---:|
| 2 | T | 2 · 1 · prête | **T+2** — « tous les deux tours » |
| 1 (*Célérité*, vague 5) | T | 1 · prête | **T+1** — à chaque tour, une fois |

Le compte affiché ne bouge pas pendant le tour ennemi : il dit dans combien de tours joueur la signature revient.

**Remise à zéro** : `initializeCombat` remplace l'état par un `CombatState` neuf (`combat_controller.dart:177-186`),
`turnCount` à 1 et la table vide — toutes les signatures sont prêtes au premier tour (D41), sans code de plus.
**Jamais sauvegardée** : la table n'entre ni dans `CombatState.toJson` ni dans `fromJson` (`combat_state.dart:55-104`),
et `SaveService` n'écrit jamais l'état de combat (`save_service.dart:57-63`).

### 4.3. Jouer une signature — `CombatController.playSignature`

`bool playSignature(SignatureInstance signature, {String? enemyId})`, dans cet ordre :

1. **Refus sans effet** — rend `false`, ne touche à rien — si : le tour n'est pas au joueur ou le combat est fini ;
   la signature n'est pas dans `runState.signatures` ; `!isSignatureReady(id)` ; sa cible est `singleEnemy` et
   `enemyId` est nul — **jamais la sélection restante** d'une carte précédente, que le joueur n'a pas choisie.
2. `card = signature.asCard`. `EffectResolver.canPlayCard(card, runState, enemyId)` (`effect_resolver.dart:104-119`)
   — mana (`:109-110`) et cible — : faux, rendre `false`, **avant toute écriture** ; rien n'est payé, la
   sélection n'a pas bougé, la signature reste prête.
3. Pour `singleEnemy`, `selectEnemy(enemyId)`, comme l'écran le fait avant de jouer une carte
   (`game_screen.dart:347-349`) ; puis `EffectResolver.resolveCard(card, …, enemyId, …)` (`:122-155`), qui **paie le
   mana** (`:134`) et résout chaque effet par sa stratégie. Le contrôle de l'étape 2 étant fait sur le même état,
   il rend `true`.
4. `signaturesReadyOn[id] = turnCount + signature.cooldown`.
5. **Aucune pile** : ni `DeckNotifier.playCard`, ni défausse, ni épuisement. La main, la pioche, la défausse et la
   pile d'épuisement sont identiques avant et après.
6. La suite commune au jeu d'une carte, extraite d'`applyPlayerCardPlay` (`combat_controller.dart:227-274`) en
   une méthode privée que les deux appellent : passifs (`onCardPlayed`, puis l'événement du type), reliques
   (les mêmes événements, §1.2), nettoyage des morts. L'ennemi de l'événement est `enemyId` pour une
   signature `singleEnemy`, nul sinon (`:234-236`).
7. Rend `true`.

`applyPlayerCardPlay` devient : `resolveCard` → `deckController.playCard` → la suite commune. Son comportement ne
change pas.

### 4.4. Les crochets « carte jouée »

Tous passent par la suite commune (étape 6) — mesuré : aucun autre site ne lit une carte jouée
(`git grep` de `onCardPlayed|onAttackPlayed|onSkillPlayed|onPowerPlayed|PlayedThisTurn|cardsPlayed` dans `lib/` ne
rend que `combat_controller.dart`, l'enum et ses libellés).

| Crochet | Voit une signature ? | Par |
|:---|:---|:---|
| Passifs `onCardPlayed` / par type — *Soif de Sang* (`onAttackPlayed`), *Flux de Mana* (`onSkillPlayed`, compteur par combat), *Marque du Mage* (`onAttackPlayed`, compteur par tour) | **Oui**, selon son type | La réponse du propriétaire |
| Effets de dégâts : Puissance par type, critique, vol de vie de *Soif de Sang* (`DamageEffectStrategy`) | **Oui** — c'est la résolution même | La réponse du propriétaire |
| Statuts posés : source `card:<id>` de la Puissance de *Posture de Rage* (D36) | **Oui**, une source par signature | La résolution ; l'intégrité garde les ids distincts des cartes (§10) |
| Reliques `onCardPlayed` / `onAttackPlayed` et leurs charges (`player_stats_manager.dart:236`, `:258`, `:327-430`) | **Oui**, selon son type | La réponse du propriétaire (Q-P1) |
| Pioche des effets `draw` | Oui, la main en reçoit, bornée par `maxHandSize` | La résolution |
| Son `cardPlay`, animation du héros | Oui (§5.4) | L'écran |
| Tutoriel, statistiques, journal de combat | Aucun ne compte les cartes jouées | — |

### 4.5. *Marque du Mage* en `0.5.6`

Le fichier ne change pas : `passives/mage_mark.json`, `trigger: onAttackPlayed`. Les deux signatures du Mage sont
désormais des Compétences : **la Marque ne se déclenche plus sur une signature**, seulement sur la première Attaque
du deck de chaque tour (`passive_strategies.dart:64-97`). Voulu (orchestration §7.2, D70) ; D34 le corrige en
vague 7. Corollaire, couvert par la même réponse : *Flux de Mana* compte désormais Projectile Magique et Surtension
de Mana, et la Puissance du Mage frappe Projectile Magique (`mightTargets` : `skill`) — c'est l'objet de D28.

### 4.6. Ce qui ne voit jamais une signature

Tout ce qui lit `registry.cards` ou le `masterDeck` : boutique, trouvaille, draft de boss, Miroirs, copie du deck,
fusion, forge, affûtage, Puits, boss « XP », DDA (`fusionRankSum`), menu de debug (`debug_deck_tab.dart:17`),
dictionnaire des cartes. Aucun filtre n'est écrit pour cela : elles n'y sont pas.

---

## 5. La barre de signatures au HUD

### 5.1. Place et anatomie

`lib/ui/widgets/hud/signature_bar.dart` — `SignatureBar`, widget sans état, posé par `GameScreen` à côté de
`TurnControlPanel`. **À gauche, centrée sur la hauteur de l'écran** (`left: 20`), en miroir du bouton de fin de tour
(`turn_control_panel.dart:101-104`, `right: 20`) ; au-dessus du panneau des statuts du héros, qui reste à
`bottom: 80` (`combat_side_panels.dart:71-75`). Une colonne de boutons larges, un par signature dans l'ordre de
`HeroData.skills` : 220 px de large, 170 en mobile (largeur < 600), la hauteur suivant le contenu.

Une tuile porte : le médaillon de coût en haut à gauche, comme une carte ; à sa droite, le nom entier, le type
(Attaque / Compétence) à sa couleur, la description de l'effet sur deux lignes au plus, et, en recharge seulement, un
sablier et le compte (« 2 tours ») ; un fond neutre, le même quel que soit le type, sans liseré ; la couleur de la
classe (`ClassIdentity.colorOf`) en bordure. **Tranché par le propriétaire le 16/10, à son test** : la spec
prévoyait des tuiles carrées de 76 px, le nom seul et la couleur du type en liseré — deux carrés trop petits à l'écran,
et le rouge d'une Attaque qui, sans type écrit, se lisait comme une erreur.
Le fond neutre sans liseré vaut aussi pour la tuile hors combat (§6), qui occupe toute la largeur de la carte de
classe ; hors combat, seule la tuile détaillée du dictionnaire dit le type (P-2).

### 5.2. Les états

Dans l'ordre de priorité — le premier qui s'applique gagne :

| État | Quand | Ce que la tuile montre | Toucher |
|:---|:---|:---|:---|
| **Inactive** | Pas le tour du joueur (`combatState.turnPhase` ou `_game.currentPhase`), animation de carte en cours (`_game.isCardAnimating`), héros mort, combat fini — la condition de `canEndTurn` (`game_screen.dart:537-540`) | Atténuée ; le compte de recharge reste lisible | Rien |
| **En recharge** | `signatureTurnsLeft > 0` | Grisée ; sous la description, un sablier et le compte (« 2 tours ») | Rien |
| **Mana insuffisant** | Mana courant < coût | Couleurs gardées, médaillon de coût en rouge | Son `insufficientMana` et une secousse, comme une carte (`card_interaction_handler.dart:134-139`) ; rien n'est joué |
| **Armée** | Une `singleEnemy` touchée, en attente de cible | Bordure pulsante ; sous la barre, « Choisissez une cible » | La retoucher désarme |
| **Disponible** | Sinon | Pleine couleur, lueur de classe | Toute cible autre que `singleEnemy` (`self`, `allEnemies`, `none` — `card_data.dart:84`) : joue aussitôt. `singleEnemy` : **arme** la signature |

Ni survol ni appui long : **pas d'infobulle** — tranché par le propriétaire le 16/10, la tuile écrivant elle-même le
nom, le type, la description et la recharge (§5.1). La spec prévoyait l'infobulle de combat (`CombatTooltipOverlay`)
avec la ligne « Coût · Recharge » ; cette ligne ne se lit plus en combat qu'en recharge, et hors combat sur les tuiles
de la carte de classe et du dictionnaire (§6). **Au survol** (bureau), demandé par le propriétaire le 16/10 : une tuile
qui répond au toucher (disponible, armée, mana insuffisant) grossit à 1,05, ancrée sur son bord gauche, en 100 ms,
sa lueur de classe s'intensifie et le curseur devient une main ; une tuile inactive ou en recharge ne réagit pas. La
mise en page ne bouge pas.

### 5.3. Le ciblage — le contrat entre la barre et Flame

Mesuré : une carte cible par glisser (`card_interaction_handler.dart:97-102`, `:142-147`) ou par clic-pour-jouer —
carte focalisée, puis ennemi touché (`heros_draft_game.dart:277-300`) ; `selectedEnemyId` n'est écrit qu'au jeu
d'une carte (`game_screen.dart:347-349`), et le rappel `onSelectEnemy` (`heros_draft_game.dart:77`, branché
`game_screen.dart:392-394`) **n'est appelé par aucun code Flame**.

| Côté | Ce qu'il fait |
|:---|:---|
| `GameScreen` (Flutter) | Tient la signature armée. Armer : `_game.awaitingEnemyTarget = true` et `_game.setFocusedCard(null)`. Reçoit l'ennemi par `onSelectEnemy` et joue la signature armée avec lui ; désarme à la fin du tour, au désarmement par la tuile, et sur `onEnemyTargetCancelled` |
| `HerosDraftGame` (Flame) | Gagne `bool awaitingEnemyTarget` et `VoidCallback? onEnemyTargetCancelled`. Dans `_handlePlayerTargeting`, **une carte focalisée garde la priorité** ; sinon, si une cible est attendue, appelle `onSelectEnemy(target.id)` et cesse d'attendre. Tant qu'elle attend, l'ennemi survolé s'illumine (`highlightEnemy`, `:179-185`). Focaliser ou saisir une carte, ou toucher le décor, cesse d'attendre et appelle `onEnemyTargetCancelled` |

Flame ne connaît ni `SignatureInstance` ni la barre ; la barre ne lit aucun composant Flame. Un seul geste est en
cours à la fois.

### 5.4. Le jeu, côté écran

`GameScreen._playSignature(signature, {enemyId})` reprend ce que fait `onPlayCard` pour une carte
(`game_screen.dart:327-377`) : l'animation du héros selon le type (`dashAnimation` pour une attaque, sinon
`buffAnimation`), le son `GameMoment.cardPlay` avec la signature pour source, `combatController.playSignature`, puis
l'avertissement « plus de mana », extrait dans une méthode que les deux chemins appellent. La tuile étant inactive
pendant une animation de carte, le rendu des coups est immédiat (`state_sync_system.dart:101-120`).

---

## 6. Les autres écrans

| Écran | Avec E4 |
|:---|:---|
| **Draft de départ** (`starter_deck_draft_screen.dart`) | Le pool : `isOfferable`, trié comme aujourd'hui (A9, A13). Le deck de départ : **les 5 cartes choisies, rien d'autre** (`:94-110`). `startNewRun` reçoit les signatures de la classe (§9). Les textes de l'écran ne changent pas |
| **Sélection de classe** (`class_selection_screen.dart`) | Un bloc « Signatures » sur la carte de classe, entre le bloc de la Puissance (`:616-663`) et la description (`:676`) : les deux tuiles en version compacte — nom, coût, recharge, description |
| **Dictionnaire** (`card_dictionary_screen.dart:36-62`) | Un troisième onglet, « Signatures » : par classe, dans l'ordre de `displayOrder`, le nom de la classe à sa couleur puis ses signatures en version détaillée |
| **Tutoriel** | §7.2 |

Les deux versions de tuile hors combat sont un seul widget, `lib/ui/widgets/signature_tile.dart`.

Conséquence à connaître : un deck de 5 cartes pour 5 cartes piochées par tour met tout le deck en main au premier
combat, et le remélange suit chaque tour jusqu'à la première trouvaille. C'est ce que la simulation a joué
(rapport §1.2, « Draft de départ ») ; rien ne le corrige ici.

---

## 7. Textes joueur

### 7.1. Clés ARB (`app_fr.arb`, `app_en.arb`)

Les noms et descriptions des six signatures ne changent pas. Le mot est **signature** (D49).

| Clé | Français | English |
|:---|:---|:---|
| `signatures` | Signatures | Signatures |
| `signatureChooseTarget` | Choisissez une cible | Choose a target |
| `signatureTurnsLeft` *(pluriel)* | `{count, plural, =1{1 tour} other{{count} tours}}` | `{count, plural, =1{1 turn} other{{count} turns}}` |
| `signatureCostAndCooldown` *(pluriel)* | `Coût : {cost} Mana · Recharge : {cooldown, plural, =1{1 tour} other{{cooldown} tours}}` | `Cost: {cost} Mana · Cooldown: {cooldown, plural, =1{1 turn} other{{cooldown} turns}}` |

### 7.2. Tutoriel

| Où | Changement |
|:---|:---|
| `tutorial_engine.dart:173-190` — `setStarterDeck` | Le deck est les 5 cartes choisies ; plus de `hero.skills.map(fixtures.card)` (`:183`), qui lèverait — les signatures ne sont plus dans `registry.cards` |
| `tutorial_fixtures.dart` | `SignatureData signature(String id)`, fail-fast sur `registry.signatures` ; `starterPool` (`:63-66`) filtre par `isOfferable` — sans id de classe à fournir (A13) |
| `tutorial_starter_deck_widget.dart:41-44`, `:104-108` | Le bandeau « Ajoutées d'office » devient « Vos signatures, toujours disponibles en combat : X, Y » / « Your signatures, always available in combat: X, Y », lues par `fixtures.signature` |
| Étape « Votre deck de départ » (`tutorial_data.dart:35-44`) | FR : « Choisissez 5 cartes dans le pool commun : elles forment votre deck de départ, celui avec lequel vous jouerez le reste du tutoriel.\n\nVotre classe apporte en plus ses deux **signatures**, qui ne sont pas des cartes : jamais piochées, elles ne fusionnent pas. En combat, elles vous attendent dans une barre à gauche de l'écran, dès le premier tour ; jouer une signature coûte du Mana, puis elle se recharge quelques tours avant de revenir. » — EN : « Pick 5 cards from the common pool: they form your starting deck, the one you will play the rest of the tutorial with.\n\nYour class also brings its two **signatures**, which are not cards: never drawn, they never merge. In combat they wait in a bar on the left of the screen, from the first turn; playing a signature costs Mana, then it recharges for a few turns before it comes back. » |
| Étape « La Fusion de Cartes » (`tutorial_data.dart:281`, `:297-298`) | La phrase « Vos cartes de classe sont uniques, et une carte unique ne fusionne jamais. » / « Your class cards are unique, and unique cards never merge. » est retirée |

Rien d'autre du tutoriel n'est réécrit : la barre s'enseigne par cette prose seule (Q-P2, §1.2).

---

## 8. L'éditeur de contenu

| Élément | Changement |
|:---|:---|
| `EntityCategory` (`entity_descriptor.dart:23-32`) | Gagne `signature` : neuf catégories |
| Descripteur de signature | Le chemin `classes/<classe>/skills/<id>.json` — la propriété de classe (`supportsHeroClass`) passe de la carte à la signature, et la classe y est exigée ; `requiredKeys` `cost`, `cooldown`, `type` ; `forbiddenKeys` `heroClass`, `rarity`, `isExhaust`, `category` ; `enumKeys` `type` (sans `status`) et `target` ; prose `name`, `description` ; `sfx` en ressource ; même vocabulaire que la carte ; `construct: SignatureData.fromJson`. Gabarit : `cost` 1, `cooldown` 2, `type` attack, `target` singleEnemy, `animation` melee, un effet `damage` 6 |
| Descripteur de carte (`:206-238`) | Neutre seulement : plus de chemin sous une classe ; `enumKeys.rarity` suit l'enum à cinq valeurs ; `forbiddenKeys` reste `heroClass`, `category` (`:214`) — désormais aligné sur `CardData.fromJson`, qui les refuse aussi (A10) |
| Propriétaire d'un brouillon | `EntityDraft.heroClass` (`entity_draft.dart:19-40`), le choix du propriétaire à l'écran (`content_editor_screen.dart:265`, `entity_form.dart:284-298`) et sa validation (`entity_validator.dart:118-122`) restent : c'est la classe **du dossier**, jamais un champ du fichier. Ils ne servent plus qu'à la signature ; une carte n'a plus de propriétaire |
| Catalogue (`entity_catalog.dart:30-37`, `:63-68`) | Liste `classes/<c>/skills/` pour la signature, propriétaire la classe ; la carte, à plat |
| Validateur (`entity_validator.dart:482-532`) | `_signatureCards` devient `_signatures` : la bijection `skills` ↔ `classes/<id>/skills/` ; `_idsOf` gagne la catégorie (`registry.signatures`) |
| Construction (`entity_validator.dart:542-553`) | `_construct` passe à `construct` le document de `draft.compose()` **augmenté de `heroClass: draft.heroClass`** quand le descripteur porte la propriété de classe (`supportsHeroClass` — après E4, la seule signature) : `compose()` n'écrit jamais `heroClass` (`entity_draft.dart:47-80`), et `SignatureData.fromJson` l'exige. Le répertoire porte l'appartenance ; l'éditeur la tient comme le chargeur, qui l'injecte depuis le chemin (§3.3) — *tranché par l'orchestrateur au deuxième tour, T, filtre 5*. Le document **écrit** ne change pas : la clé reste interdite dans le fichier |
| Écrivain (`entity_writer.dart:263-290`) | `_registerSignatureCard` devient `_registerSignature` : écrire une signature neuve l'inscrit dans `skills` |
| Dossier d'une classe neuve (`entity_writer.dart:195-210`) | `_prepareFolder` crée `skills/` au lieu de `cards/`, **même vide** : le test d'intégrité y appelle `listSync()` sans garde |
| Recette de classe (`class_recipe.dart`) | `SignatureCardInput` devient `SignatureInput` ; les brouillons prennent le descripteur et le gabarit de la signature |
| Écran et formulaire | Les libellés « cartes de signature » deviennent « signatures » (`content_editor_screen.dart:372-378`, `entity_form.dart:521-523`) ; le tri des fautes de la recette reconnaît la signature et non plus la carte (`content_editor_screen.dart:362`) ; le compteur « et ses N cartes » devient « et ses N signatures » (`:936-942`) |

---

## 9. La sauvegarde

**Aucune migration, `schemaVersion` inchangé.** Aucun champ nouveau n'est écrit.

| Élément | Avant (`0.5.5`) | Avec E4 |
|:---|:---|:---|
| `masterDeck` | 5 cartes choisies + 2 signatures en `CardInstance` `unique` | **Les 5 cartes choisies** |
| `RunState.signatures` | — | `List<SignatureInstance>`, défaut `const []`. Rempli par `startNewRun`, qui gagne un troisième paramètre optionnel positionnel, `List<SignatureData> signatures = const []` — Dart n'admet pas un nommé à côté du positionnel `activePassive`, et la centaine d'appels de test reste inchangée ; l'unique appel de `lib/` (`starter_deck_draft_screen.dart:114-116`) passe `hero.getSignatures(registry)`. **Jamais sérialisé** : `fromJsonWithReport` le relit de la classe — `HeroData.getById(heroClassId)`, puis `getSignatures` —, comme `statRules` (`run_controller.dart:212-218`) |
| Recharge | — | Dans l'état de combat, jamais écrite (§4.2) |

**Une partie en cours sous `0.5.5` ne reprend pas** : `CardInstance.fromJson` relit la rareté par `firstWhere` sans
repli (`card_instance.dart:60`), lève sur `"unique"`, et `SaveService.load` efface la sauvegarde
(`save_service.dart:135-140`). Avant la `1.0.0`, c'est la règle ; ni test ni protection.

---

## 10. Tests

| Sujet | Fichier | Ce qu'il verrouille | Partie |
|:---|:---|:---|:---:|
| Donnée | `test/unit/signature_data_test.dart` *(nouveau)* | `cooldown` absent, 0 ou négatif refusé ; `cost` négatif refusé ; `type: status` refusé ; `rarity`, `isExhaust`, `category` refusés, nommés ; `effects` vide refusé ; une signature valide se lit entière | 1 |
| Vue de carte | `test/unit/signature_instance_test.dart` *(nouveau)* | `asCard` : id, type, cible, coût, effets de la signature ; rareté `common`, aucune rune, `exhaustsOnPlay` faux ; `effective` rend les valeurs du fichier | 1 |
| **Le jeu d'une signature** — tâche à risque | `test/unit/combat_signature_test.dart` *(nouveau)* | Paie le coût, résout (PV ennemis, armure), `signatureTurnsLeft` vaut 2 ; refusée au même tour, encore au suivant, prête au troisième ; `cooldown` 1 : refusée au même tour, prête au suivant ; mana insuffisant : `false`, mana et recharge intacts ; `singleEnemy` sans `enemyId` refusée malgré une `selectedEnemyId` restante ; refusée au tour ennemi ; **un `initializeCombat` neuf rend tout prêt** ; main, pioche, défausse et épuisement inchangés — `holy_shield` et `mana_surge` rejouables à T+2, jamais épuisés ; `smite` arme *Soif de Sang* ; `magic_missile` fait monter *Flux de Mana* et **ne pose pas** Vulnérable sous *Marque du Mage* ; les reliques voient la signature (Q-P1) — l'*Amulette du Mage* donne son Armure, le *Shuriken* compte `reckless_strike` comme une attaque | 1 |
| Jeu d'une carte | `test/unit/combat_controller_test.dart` | La suite commune extraite : ordre et événements inchangés | 1 |
| État de combat | `test/unit/combat_state_test.dart` *(nouveau ou existant)* | Table vide par défaut ; `copyWith` la porte ; `toJson` n'a aucune clé de signature | 1 |
| Intégrité | `test/unit/referential_integrity_test.dart:157-180`, `:211-229` | Réécrits sur `registry.signatures` et `classes/<id>/skills/` : chaque id de `skills` est une signature de la classe, rangée sous elle ; dossier `skills/` = `skills`. Neuf : **aucun id de signature n'est un id de carte** — ce qui garde à la fois les pools, le `masterDeck` et les sources de statut | 1 |
| Bundle réel | `test/unit/real_bundle_load_test.dart:35`, `:95` | `registry.cards` 17 ; `registry.signatures` 6 ; les 94 fichiers du manifeste | 1 |
| Lien de classe | `test/unit/hero_skills_link_test.dart` | `getSignatures` : ordre de `skills`, fail-fast | 1 |
| Raretés, offre | `card_rarity_test.dart:49-57`, `card_offer_filter_test.dart` | Cinq raretés ; plus d'`isAcquirable` ; `isOfferable` : vrai sauf pour un statut, sans rareté ni classe (A13) ; `CardData.fromJson` refuse `heroClass` et `category`, nommés (A10) | 1 |
| Catalogue des runes | `test/unit/forge_upgrades_catalog_test.dart:198-205`, `:218`, `:283-285`, `:302-305` | `_signatures` et ses cas « unique, ne recoit aucune rune » partent ; la matrice couvre les **17** cartes livrées | 1 |
| Catalogue audio | `test/unit/audio/audio_catalogue_test.dart:38-52` | Le filtre `/cards/` devient `/skills/` : le `sfx` des signatures reste contrôlé, le compte reste **55** | 1 |
| Sauvegarde — tâche à risque | `test/unit/save_service_test.dart` | Une run d'E4 sauvée puis rechargée : `masterDeck` sans signature ; `run.signatures` relues de la classe, ids égaux à `skills` ; le JSON écrit n'a pas de clé `signatures` | 1 |
| Persistance du deck | `test/unit/deck_state_persistence_test.dart:126-149` | Les deux cas partent : la réparation B5 (`:126`) et la signature restée `unique` au chargement (`:142`) | 1 |
| Draft de départ | `test/widget/starter_deck_draft_screen_test.dart` (dont `:306`) | Le deck fait 5 cartes, aucune signature ; le pool est celui d'`isOfferable` ; la run reçoit les signatures de la classe | 1 |
| Tutoriel | `test/tutorial/tutorial_engine_test.dart:461`, `:507` ; `tutorial_fixtures_test.dart` ; `test/widget/tutorial_starter_draft_test.dart:58-73` | Le deck fait 5 cartes, sans `holy_shield` ni `smite` ; la fixture `signature` résout les six | 1 |
| Transition E3 → E4 | `test/unit/signature_cards_transition_test.dart` | **Retiré** (A12) | 1 |
| Barre | `test/widget/signature_bar_test.dart` *(nouveau)* | Les cinq états de §5.2 et leur priorité ; le compte « 2 tours » ; un toucher n'appelle le rappel que sur une tuile disponible ; l'état armé affiche l'invite | 2 |
| Écrans | `card_dictionary_screen_test.dart`, `class_selection_screen_test.dart`, tutoriel (widget du deck de départ) | Les assertions neuves seulement : l'onglet « Signatures » par classe ; le bloc de la carte de classe ; le bandeau du tutoriel | 2 |
| Éditeur | `entity_descriptor_test.dart:12-35`, les tests de `content_editor/` dont `shipped_entities_round_trip_test.dart` (disque réel) | Neuf catégories, neuf sources ; chemin d'une signature sous `skills/` ; bijection `skills` ↔ `skills/` ; `_prepareFolder` crée `skills/` ; recette et écrivain ; chaque `class.json` **et chaque signature** livrés repassent la validation et se réécrivent à l'identique, sans `heroClass` dans le fichier ; dans `entity_validator_test.dart`, une signature valide passe `_construct`, et un descripteur sans propriété de classe ne reçoit pas `heroClass` | 1 |
| JSON de carte dans les tests | `test/unit/audio/audio_source_models_test.dart:18`, `:40` ; `test/unit/localization_test.dart:17` ; `test/unit/content_editor/fixtures.dart:21` (`fixtureCard`, lu par `entity_validator_test.dart:83`) | La clé `'category'` sort des maps : `CardData.fromJson` la refuse (A10) | 1 |
| **Retirés ou réécrits — leur objet disparaît** | `shop_controller_test.dart:805-858` (dont `:835`) | Filtre de classe de la boutique : **retiré** — plus de clause de classe ; `isOfferable` est gardé par `card_offer_filter_test` | 1 |
| | `shop_controller_test.dart:649` « sans carte copiable, pas de copie » | **Réécrit** : un deck vide n'a pas de copie — tout le deck est copiable | 1 |
| | `draft_screen_test.dart:253` (Miroir et carte unique) | **Retiré** — aucune carte n'est hors de la copie | 1 |
| | `reward_controller_test.dart:556-615` (lit `card.data.heroClass`, `:605`) | **Réécrit** : la trouvaille ne tire que des cartes `isOfferable` ; plus de clause de classe ni de rareté | 1 |
| | `deck_controller_test.dart:240-254` (`copyableCards` écarte `unique`) | **Réécrit** : `copyableCards` rend tout le `masterDeck` | 1 |
| | `shop_screen_test.dart:318-370` (« Le Miroir Magique ne propose jamais de copier une carte unique » ; `shop_screen.dart:209-211` mélange `copyableCards`) | **Retiré**, avec sa fixture `signatureCard` (`:87-100`), que lui seul lit — même motif que `draft_screen_test.dart:253` | 1 |
| | `shop_controller_test.dart:629-646` (le leurre `signature`, id `signature_paladin`, déclaré à `:618-627` et injecté à `:637` ; `copy.data.id == source` sur 50 tirages) | **Réécrit sans le leurre** : la fixture `signature` part avec `:637` et `:653` ; la propriété « même rareté, sans rune, id neuf » demeure | 1 |
| | `reward_controller_test.dart:302-319` (« ne propose jamais de carte unique au draft de boss » ; le draft de boss lit `copyableCards`, `reward_controller.dart:199`) | **Retiré** | 1 |
| | `reward_controller_test.dart:109-118` (fixture `c_unique`) ; `:617-632` (« un statut et une signature : aucune carte offerte ») | Fixture **retirée** ; `:617-632` **réécrit sur un statut seul** (`[allCards[1]]`) ; l'assertion de `:180-183` et celle de `:537` restent inchangées une fois la fixture partie ; le commentaire `:177-179` perd `c_unique` | 1 |
| | Assertions ou tests portant sur `unique` | **Retirés, avec leur objet** : `effective_card_test.dart:83-91` (« unique rend la base »), les deux cas de `deck_state_persistence_test.dart:126-149`, l'assertion `rune_eligibility_test.dart:169`. **Réécrits sur une commune** : `ui_card_rune_sockets_test.dart:69-74`, `deck_controller_test.dart:259-295` (la signature au rang 0), `tutorial_engine_test.dart:527` — sauf `tutorial_fixtures_test.dart:115`, qui asserte `category` et non `unique` : l'assertion part avec le champ | 1 |

**Partie 1** : hors des lignes « Retirés ou réécrits » ci-dessus, les tests qui construisent `CardCategory`, une
`unique` ou appellent `isOfferableTo` — **37 fichiers** sous `test/` au motif de §12 (`git grep -l … -- test | wc -l`),
`card_dictionary_screen_test.dart` et `card_dictionary_order_test.dart` compris —, plus ceux qui passent
`heroClass:` à un `CardData`, perdent ce paramètre sans changer ce qu'ils vérifient : la purge ne compile pas sans
eux. La glue Flame du ciblage (§5.3) n'a pas de banc de test
dans le dépôt : elle se garde au test manuel.

---

## 11. Le découpage

**Partie 1 — la donnée, le modèle, le moteur, la sauvegarde.** Les six fichiers et `sync_assets` ; `SignatureData`,
la source, le registre, `getSignatures` ; `SignatureInstance` ; `RunState.signatures` ; la recharge et
`playSignature` ; la purge de `unique`, `isAcquirable`, `CardCategory` et `CardData.heroClass`, interface comprise
(§3.4) ; **le draft de départ** et **les deux lectures du tutoriel** (`tutorial_engine.dart:183`,
`tutorial_starter_deck_widget.dart:41`) ; **l'éditeur de contenu** (§8) ; `CLAUDE.md` et `README.md` (§12) ; les
tests marqués 1.

**Partie 2 — ce que le joueur voit.** La barre, son ciblage et le jeu côté écran ; la sélection de classe ; le
dictionnaire ; la prose et le bandeau du tutoriel ; les clés ARB ; les tests marqués 2.

**L'invariant** : à la fin de la partie 1, **aucune signature n'est une carte** — ni dans le registre, ni dans un
deck, ni dans un pool, ni dans une sauvegarde — et le moteur sait les jouer, prouvé sans écran ; la partie 2 ne fait
que les montrer. Entre les deux, la suite est verte et le jeu se joue de bout en bout : les runs démarrent à
5 cartes, sans signature accessible. C'est pourquoi le draft et les deux lectures du tutoriel, que la fiche plaçait en
partie 2, sont en partie 1 : `getHeroCards` et `fixtures.card` lèveraient sur des ids qui ne sont plus des cartes, et
`category`, qu'ils filtrent, n'existe plus. L'éditeur aussi, bien qu'il n'existe qu'en debug : un de ses tests lit le
vrai disque (`shipped_entities_round_trip_test.dart:22-23`), et sa bijection `skills` ↔ dossier
(`entity_validator.dart:95`, `:514`) refuserait chaque `class.json` livré dès que `cards/` disparaît — un dossier
absent se lit vide (`content_file_system_io.dart:45`). Tout ce qui lit ou écrit la donnée est donc en partie 1.

---

## 12. Documentation et livraison

| Quoi | Où, par qui |
|:---|:---|
| ADR « signatures hors du deck » — **amende ADR-094** (D1 : `unique` hors échelle supprimée ; D2 : `isAcquirable` supprimé, `copyableCards` est le deck entier ; D6 : réparation B5 retirée), **ADR-101** (D1 : le prédicat devient `isOfferable`, sans clause de rareté ni de classe ; D3 : le draft de départ l'adopte), **ADR-084** (D3 : `HeroData.skills` liste des signatures, compétences à recharge avec un point d'entrée ; l'invariant de purge tient, aucun nom repris) ; complète ADR-086 (`skills/` injecte `heroClass` ; `category` et `CardData.heroClass` n'existent plus, une carte qui les déclare échoue) et ADR-100 (neuvième catégorie de l'éditeur) | `memory-bank-sync` |
| Fiches `_rules/02-3`, `02-2` (les cartes de signature), `07-00` ; `_patterns/20-00` (le script lit `classes/*/cards/`, qui n'existe plus) — un minimum : le diff périme aussi `_rules/02-4`, `03-8`, `06-00`, `08-00` et `_patterns/02-3`, `03-4`, `17-00`, `19-00`, `19-5` | `memory-bank-sync` |
| **P-43 se clôt** dans `docs/ROADMAP.md` | `memory-bank-sync` |
| `CLAUDE.md:47`, `:72`, `:80`, `:89` et `README.md:64`, `:69-74`, `:93` : l'arbre `classes/<id>/skills/` ; `CLAUDE.md:89` devient : « Never write a field the directory imposes: `heroClass` in a signature file fails the load, and so do `heroClass` and `category` in a card file. » | Partie 1, avec le déplacement |
| Note de version `0.5.6` | `patch-notes-writer`, à la fin de la vague |

**Ce que le joueur voit en `0.5.6`** : deux signatures par classe, hors du deck, toujours disponibles dès le premier
tour de chaque combat, dans une barre à gauche de l'écran, avec un temps de recharge de deux tours ; elles sont aussi
sur la carte de classe et dans un onglet du dictionnaire ; le deck de départ compte 5 cartes. **À dire dans la
note** : le Projectile Magique devient une Compétence et ne déclenche plus *Marque du Mage* ; Bouclier Sacré et
Surtension de Mana ne s'épuisent plus ; une signature jouée compte comme une carte de son type, pour les passifs
comme pour les reliques (Q-P1). À considérer : *Flux de Mana* compte désormais les deux signatures du Mage.

**Ce que le vérificateur contrôle** :

- `` git grep -nE "CardRarity\.unique|rarityUnique|isUnique|isAcquirable|characterSpecific|CardCategory|isOfferableTo|'unique'|\"unique\"|\`unique\`" -- lib test assets tool ':!tool/simulations' | grep -v "contains('single')" ``
  ne rend rien. `tool/simulations/` est écarté : le script est gelé (ADR-108 D5, §2) et cite `isOfferableTo` en
  commentaire (`d26_economy_sim.dart:751`). Le `grep -v` écarte la seule lecture légitime, le mot clé de cible de
  `ui_card_helpers.dart:17` (§3.4). *`git grep -w unique` ne peut pas rendre vide* : le mot est de la prose française
  du dépôt (`app_fr.arb:187` « Cible unique », des commentaires, l'historique de `patch_notes.json`) ;
- aucune signature dans le `masterDeck` ni dans un pool : le test d'intégrité (ids disjoints) et celui du draft de
  départ ;
- `git diff main -- assets/data/passives/mage_mark.json` est vide : le déclencheur reste `onAttackPlayed`.
