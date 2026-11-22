---
description: The last P-42 tranche — Mage's Mark now fires on the first damage card of the turn, Attack or Skill, signatures included, through a new onDamagingCardPlayed trigger and a single EffectiveCard.dealsDamage predicate that no relic listens to; it marks only a single, still-living target (an area card neither marks nor consumes the mark, a card that kills its target does not count); the hp_regen status (Life Spring) heals after the tick, capped at max HP, never on a dead bearer, symmetric for enemies; the targetStatus growth line names the status in the player's language; three lots unmask the last three passives by data; completes ADR-112, ADR-111 and ADR-116, closes what ADR-109 said about the Mark lost by Magic Missile
---

# ADR-118 — La Tranche 3 : la Carte de Dégâts, la Marque, la Source de Vie

### Statut

✅ Accepté — 2026-11-18 (P-42, **tranche 3**, la dernière ; brainstorm v3, décisions **D34** et
**D55**, tenues avec D10, D16, D17, D43, D45, D50, D60 et D83 à D86 ; réponses du propriétaire du
2026-11-18 : Q12, D43 « armure conservée » non retenue, **A3 (c)** et **A4 (ii)**, arbitrages A19 et
A20 acceptés). **Livré sur la branche `feat/v0.6.0-p42-tranche-3` — vague 8 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Rien n'en est dans `main`.
[Spec](../../docs/superpowers/specs/2026-11-18-p42-tranche-3-design.md) arrêtée au premier tour sur A3
et A4 (`83cea776`), arrêt levé le 18/11 (`6788bfd5`) ; [plan](../../docs/superpowers/plans/2026-11-18-p42-tranche-3.md)
prêt au deuxième tour (`0e704f7e`) ; code `9a0f6c3d`..`a65bf4c7`, revue d'ensemble « prête avec
corrections » et sa passe ; note de version `147f564c`. Arbitrages A1 à A20, décisions du plan D1 à
D10 et de SDD S0 à S5 au
[compte rendu de la vague](../../docs/superpowers/reports/2026-11-18-economie-et-catalogue-vague-8-compte-rendu.md),
§2 — leurs motifs, et les options écartées, ne se recopient pas ici.

**Complète [ADR-112](ADR-112-forme-c-un-lot-de-cartes-par-passif.md)** (forme C : neuf lots, aucun
passif masqué — la règle d'O5 reste, sans plus rien masquer), **[ADR-111](ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md)**
(les premières cartes à `targetMissingHp` et `targetStatus` ; la Faiblesse posée par des cartes) et
**[ADR-116](ADR-116-canalisation-une-banque-de-mana.md)** (`hp_regen` sur le modèle de `mana_regen`).
**Clôt ce qu'[ADR-109](ADR-109-signatures-hors-du-deck.md) disait de la Marque perdue par
*Projectile Magique*** (D4 et Conséquences : « *Marque du Mage* attend D34 ») : la signature marque de
nouveau. Chacun de ces ADR ne change que de Statut. **Clôt P-42** dans `docs/ROADMAP.md`.

**Complété le 2026-11-19 par [ADR-119](ADR-119-les-corrections-de-fin-de-vague-8.md)** : six corrections de fin de vague, sur la même branche, avant la fusion.

**Fusionné dans `main` le 2026-11-19 par la PR #56** (commit de fusion `84a1ee34`), tagué `v0.6.0` sur ce commit ; CI de tête `44548499546` et `release.yml` run `44556736195` verts, release `v0.6.0` publiée le 2026-11-19 — constaté par la session de clôture du chantier et re-vérifié par `gh` le 2026-11-19. **Clôt le chantier** « Économie unifiée et catalogue » ; méthode léguée : [ADR-120](ADR-120-ce-que-le-chantier-economie-et-catalogue-legue-a-la-methode.md).

**Sa réserve S9 close le 2026-11-22 par [ADR-122](ADR-122-un-combat-fini-ne-rouvre-aucun-tour.md)**
(livré sur la branche `feat/v0.6.1-interface-des-ennemis`, test du propriétaire passé le 2026-11-22, en attente de la PR, de la fusion
et du tag du propriétaire) : la *Source de Vie* ne soigne plus un tour de trop après une victoire.

### Contexte

Depuis le lot E4 de P-43 (`0.5.6`), *Projectile Magique* est une Compétence, et *Marque du Mage*,
sur `onAttackPlayed`, ne le voyait plus — voulu en attendant D34, que D76 a placée en vague 8
([ADR-110](ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md)). Depuis la vague 5, un passif
sans lot n'est pas proposé (O5) : *Bénédiction*, *Frénésie* et *Marque du Mage* attendaient leurs lots.
D55 demandait pour *Prière* un soin **dans le temps**, distinct de *Potion de Soin*. Et la ligne de
croissance de `targetStatus` nommait le statut en français dans la version anglaise — un défaut que
le compte rendu de la vague 5 avait mis à la file, sans carte pour le montrer jusqu'ici.

### Décision

**D1 — Un déclencheur neuf, `onDamagingCardPlayed`, et un seul prédicat de carte de dégâts** (D34 ;
A1, A2, A5). `RelicTrigger` gagne `onDamagingCardPlayed` ; `passives/mage_mark.json` le déclare.
`CombatController._afterCardPlayed`, la suite commune de la carte et de la signature, l'envoie aux
passifs **après** `onCardPlayed` et l'événement du type, si `card.effective.dealsDamage`. Le prédicat
vit sur `EffectiveCard` : vrai si un effet `damage` figure parmi `effects` ou `addedEffects` — rune ou
évolution de signature comprises ; il ne lit **ni la cible, ni les dégâts infligés** (une carte
entièrement absorbée par l'Armure reste une carte de dégâts). Aucun champ en donnée : un drapeau
pourrait mentir sur les effets. **Aucune relique ne l'écoute** — pas d'`applyRelics`, sur le
précédent d'`onDamageTaken` ; les trois `switch` d'affichage le nomment par la clé ARB
`relicTriggerDamagingCardPlayed`. L'écho de *Résonant* n'émet aucun de ces événements.

**D2 — La Marque, sur une cible unique et vivante** (réponses du propriétaire, A3 (c) et A4 (ii)).
La première carte de dégâts du tour, Attaque ou Compétence, signature comprise, marque sa cible —
2 Vulnérable, 2 tours, valeur et Maîtrise inchangées. **Une carte de groupe ne marque personne et ne
consomme pas la marque** : `enemyId` n'est renseigné que pour une carte ou une signature
`singleEnemy`, et `MageMarkPassive` rend la main sans compter ; *Nova*, l'évolution de groupe de
*Projectile Magique*, suit la même règle. **Une carte qui tue sa cible ne compte pas** : la
stratégie tient pour absente une cible à `currentPv <= 0` — encore dans `enemies` avant
`cleanDeadEnemies` —, et la carte de dégâts suivante marque. La marque se pose après la résolution :
la carte qui la déclenche ne profite pas de son propre Vulnérable. Texte fixé par le propriétaire :
« À chaque tour, la première carte de dégâts, Attaque ou Compétence, qui vise un seul ennemi sans le
tuer lui applique 2 Vulnérable pendant 2 tours. »

**D3 — `hp_regen`, la Source de Vie, symétrique et bornée** (D55 ; A6, A7, A20 ; complète ADR-116).
`EffectResolver.createStatus` la fabrique — buff, « Source de Vie » / « Life Spring ».
`StatusEffectProcessor` somme ses valeurs avant le tic et rend ces PV après lui, avec la
Métallisation et la Source de Mana, **chez le héros comme chez l'ennemi**, bien qu'aucun ennemi n'en
pose (le précédent des charges, D83). Le soin est **borné aux PV max** et **ne relève jamais un porteur
à 0 PV** — le Poison ou le Feu du même début de tour l'a tué. Il ne passe ni par `StatGains`, ni par le
critique, ni par le vol de vie. Statut de combat : jamais sauvegardé. Icône et couleur du soin
(`favorite_rounded`, `pinkAccent`), dix-huitième sorte d'`effect_icons.json`. *Prière* (Pouvoir, 2
mana) la pose : 2 PV au début des trois tours suivants ; *Résonant* la prend, l'exclusion de
`mana_regen` venant de D44 (mana et pioche), dont elle n'est pas (D10 du plan).

**D4 — Le nom du statut de `targetStatus`, dans la langue du joueur** (A10). `CardRuleTexts._statusName`
lit le nom de la charge, sinon la clé ARB à sélection `statusName`, qui nomme chaque statut que
fabrique `createStatus`, `hp_regen` compris ; l'id à défaut. Le nom français que pose la fabrique ne
sert plus à cet affichage.

**D5 — Trois lots, la forme C au complet** (A11 à A16, A19 ; complète ADR-112 et ADR-111). Sanctifié
(*Bénédiction*), Carnage (*Frénésie*), Marque (*Marque du Mage*) : 5, 5 et 6 cartes, toutes communes,
aucune à épuisement, aucune à coût total nul ; dix fichiers neufs et six `git mv` sans retouche — les
quatre élémentaires, qui restent des Attaques (Q12), *Métallisation*, *Cri de Guerre*. **Le
démasquage est la donnée** : `availablePassivesFor` ouvre les trois passifs sans code, trois par
classe dans l'ordre de `displayOrder`, le premier de chaque classe toujours choisi par défaut. Les
`feeds` suivent leurs lots : *Frénésie* + `damage`, *Bénédiction* + `status:hp_regen`. *Exécution* et
*Exploitation* écrivent leurs règles avec les sources livrées, `targetMissingHp` et `targetStatus`
(somme brute, celle que l'ennemi affiche), sans mécanisme neuf ; les cartes de Sanctifié sont les
premières à poser la Faiblesse depuis une carte. **La Faiblesse garde son moteur** (A19, D83) : un
ennemi décompte ses statuts avant d'agir, une Faiblesse de N tours réduit N − 1 attaques ; les durées
des cartes ont donc un tour de plus que le brainstorm. Neuf neutres restent, qui ne portent que du
mana (D17).

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Le déclencheur | `RelicTrigger.onDamagingCardPlayed` (`lib/models/data/relic_data.dart`) ; `CombatController._afterCardPlayed` (`lib/game/controllers/combat_controller.dart`) ; `PassiveEvent.card` (`lib/game/systems/passives/passive_strategy.dart`) |
| Le prédicat | `EffectiveCard.dealsDamage` (`lib/models/effective_card.dart`) |
| La Marque | `MageMarkPassive` (`lib/game/systems/passives/passive_strategies.dart`) ; `assets/data/passives/mage_mark.json` |
| La Source de Vie | `EffectResolver.createStatus` (`lib/game/services/effect_resolver.dart`) ; `StatusEffectProcessor._heal`, `processPlayerStatuses`, `processEnemyStatuses` (`lib/game/controllers/combat/status_effect_processor.dart`) ; `status:hp_regen` dans `assets/data/effect_icons.json` |
| Le nom du statut | `CardRuleTexts._statusName` (`lib/game/services/card_rule_texts.dart`) ; clés `statusName`, `statusHpRegen`, `cardDescStatusHpRegen`, `relicTriggerDamagingCardPlayed` (`lib/l10n/app_en.arb`, `app_fr.arb`) |
| Les lots | `assets/data/cards/blessing/`, `frenzy/`, `mage_mark/` ; `feeds` de `passives/blessing.json` et `frenzy.json` ; trois lignes de `pubspec.yaml` |
| Les gardes | `test/unit/passive_triggers_test.dart`, `passives_mage_test.dart` (« une Compétence ne marque jamais » renversé), `combat_signature_test.dart` (*Projectile Magique* marque, *Nova* non), `hp_regen_test.dart`, `tranche_3_cards_test.dart`, `card_rule_texts_test.dart`, `card_catalog_test.dart` (D45 et D50 sur neuf lots), `referential_integrity_test.dart` (chaque passif livré disponible pour sa classe), `real_bundle_load_test.dart` |

Règles de jeu : [`_rules/02-2`](../_rules/02-2-systeme-de-heros.md) §Passifs,
[`_rules/02-3`](../_rules/02-3-catalogue-de-cartes.md), [`_rules/04-00`](../_rules/04-00-alterations-d-etat-statuts.md)
§4.1 et §4.4, [`_rules/03-14`](../_rules/03-14-couts-combines-croissance-et-multi-coups.md). Patterns :
[`_patterns/02-2`](../_patterns/02-2-combatcontroller-pilote-de-combat.md),
[`_patterns/03-3`](../_patterns/03-3-traitsystem-passifs-de-heros.md),
[`_patterns/07-00`](../_patterns/07-00-flux-complet-d-un-tour-de-combat.md).

### Conséquences

- **Les neuf passifs sont jouables, trois par classe** ; P-42 est clos. 58 cartes, 9 neutres et 49 de
  lot ; 143 fichiers d'entité (re-mesuré le 2026-11-18, sur la branche).
- **La Faiblesse n'a pas changé** : `git diff main...HEAD -- lib/game/services/proportional_status.dart
  lib/game/services/damage_pipeline.dart` ne rend rien ; **aucune règle des charges non plus**
  (`assets/data/charges`, `lib/game/systems/charge_rules.dart`) — re-mesuré le 2026-11-18.
- **Les quatre élémentaires, *Métallisation* et *Cri de Guerre* quittent le noyau neutre** : sous les
  six autres passifs, ni le draft de départ, ni la trouvaille, ni la boutique ne les offrent. Le
  tutoriel montre toujours *Boule de Feu*, par son id, comme exemple de face.
- **Aucun test d'écran** ([ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)) : faces,
  panneaux et tutoriel sont les points M1 à M16 des tests manuels (spec §9.1).
- **Laissé pour la file** (spec §2, compte rendu §2) : le décalage « une Faiblesse de N tours réduit
  N − 1 attaques », antérieur (*Sentence*) ; l'ennemi affiche Vulnérable et Faiblesse au-delà du
  plafond du barème ; la face en main d'une carte à source de cible montre sa base ; la phase ennemie
  jouée après une victoire par les statuts (S9 de la vague 7) fait soigner *Prière* d'un tour de
  trop, comme *Bénédiction* — non bloquant, aucune carte du lot ne pose de Feu ni de Poison sur le
  héros ; l'accord des noms anglais de `statusName` n'a pas de test (S4). **La calibration** —
  *Exécution* face aux boss, le Vulnérable qui s'accumule (M7, M10) — va à P-16.
- **Dû à P-44, hors de la tranche** : les épines de Rempart, la carte `retain` de Voile, *Forge de
  guerre* de Carnage ; la session de clôture du programme les porte en `docs/ROADMAP.md`.
