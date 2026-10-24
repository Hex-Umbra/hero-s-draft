---
description: The six class signatures stop being cards — two per class, filed under classes/<id>/skills/, loaded as their own SignatureData into registry.signatures, never drawn, discarded, exhausted, offered, copied, merged or runed; playable from the first turn of every combat from a HUD bar at their current cost with a two-turn cooldown derived from the turn counter; resolved through a card view so passives and relics see them as a card of their type. The unique rarity, isAcquirable, CardCategory and CardData.heroClass disappear; the offer predicate becomes CardData.isOfferable and the starter draft adopts it. Amends ADR-094 (D1, D2, D6), ADR-101 (D1, D3) and ADR-084 (D3, ADR-084's name ban stands); completes ADR-086 and ADR-100
---

# ADR-109 — Les Signatures hors du Deck : des Compétences de Classe à Recharge, Jouées comme une Carte de leur Type

### Statut

✅ Accepté — 2026-10-16 (P-43, lot **E4**, le dernier des cinq lots E0 à E4 ; brainstorm v3,
décisions D49, D41, D53, D7 dans sa forme, D28). **Livré sur la branche
`feat/v0.5.6-p43-e4-signatures` — vague 4 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Rien n'en est dans `main`.
Spec `9b06f5c`, prête au quatrième tour de vérification, arrêtée sur deux questions de classe P
levées par le propriétaire le 2026-10-15 (`6cf2789`) ; plan de la partie 1 `15f2d89` (la donnée,
le modèle, le moteur, la sauvegarde) ; plan de la partie 2 `bb4a020`, arrêté sur une question P
levée le 2026-10-16 (`eeaa227`) ; code `e7abe74`..`2aa82d0` et le correctif de revue `a5a91ef`
(partie 1), `cd20752`..`3b5fd85` et le correctif `e434d0d` (partie 2) ; note de version `f42a25a`.
**Amende** [ADR-094](ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md) (D1, D2, D6),
[ADR-101](ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md) (D1, D3) et
[ADR-084](ADR-084-suppression-de-la-chaine-de-competences-heroiques.md) (D3).
**Complète** [ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md) et
[ADR-100](ADR-100-console-de-contenu-vocabulaire-du-moteur-et-ident.md). Chacun ne change que de
Statut. Conception : [spec E4](../../docs/superpowers/specs/2026-10-15-p43-e4-signatures-design.md)
— §1 porte les arbitrages A1 à A13 et les réponses du propriétaire, avec leurs motifs, que ce
fichier ne recopie pas ; plans [partie 1](../../docs/superpowers/plans/2026-10-15-p43-e4-signatures-partie-1.md)
et [partie 2](../../docs/superpowers/plans/2026-10-16-p43-e4-signatures-partie-2.md) ; arbitrages
d'exécution (PL1 à PL10, PM1 à PM19) et décisions de SDD (S1 à S12) au
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-16-economie-et-catalogue-vague-4-compte-rendu.md), §2.

### Contexte

Jusqu'à E3 ([ADR-107](ADR-107-trouvaille-et-progression.md)), les deux signatures de chaque classe
étaient des **cartes** : rangées sous `classes/<id>/cards/`, ajoutées d'office au deck de départ,
de rareté `unique` hors de l'échelle, marquées `characterSpecific`. Chaque système qui lit des
cartes devait les écarter un par un — `isAcquirable` pour les copies, `isOfferableTo` pour les
offres, `category == global` pour le draft de départ, une réparation au chargement pour les
légendaires que l'ancienne fusion avait rendues `unique` (ADR-094 D6), un test de transition pour
la trouvaille et le boss « XP ». D49 dit qu'elles ne sont plus des cartes : deux compétences par
classe, hors du deck, avec un coût et une recharge. Le mot « compétence » avait une histoire :
une chaîne entière, morte et inatteignable, supprimée par ADR-084, dont la purge interdit les noms.

### Décision

**D1 — Un modèle propre, une liste à part** (A1, A3). `SignatureData`
(`lib/models/data/signature_data.dart`) dans `registry.signatures`, hors de `registry.cards` :
les signatures sont absentes de tout pool **par construction**, aucun filtre n'est écrit pour les
écarter. Elles se jouent par une **vue de carte** construite à la volée,
`SignatureInstance.asCard` — une `CardInstance` commune, sans rune, qui n'entre dans aucune pile —
que `EffectResolver` et les stratégies lisent sans changer. `SignatureInstance` est la couture où
la vague 5 posera les évolutions.

**D2 — La donnée** (A11). `classes/<classe>/skills/<id>.json`, `heroClass` injecté depuis le
dossier et refusé dans le fichier ; `cost` ≥ 0 et `cooldown` ≥ 1 exigés ; `type` lu sur
`SignatureData.playableTypes`, sans `status` ; `rarity`, `isExhaust` et `category` **refusés,
nommés**. Les six fichiers ont été déplacés de `cards/` à `skills/` ; `magic_missile` passe au
type `skill` (D28). La source n° 9 du chargeur remplace celle des cartes de classe : le compte ne
bouge pas.

**D3 — La recharge, un tour de disponibilité** (A7 ; réponses du propriétaire, spec §1.2).
**Recharge de 2 tours pour les six, aux coûts d'aujourd'hui** ; **l'épuisement disparaît**.
`CombatState.signaturesReadyOn[id] = turnCount + cooldown` au jeu ; la lecture est une
soustraction, aucun décompte n'est écrit dans l'ouverture du tour. Un `CombatState` neuf à chaque
combat : toutes prêtes au premier tour (D41). Jamais sérialisée.

**D4 — Jouée comme une carte de son type** (réponses du propriétaire, dont Q-P1).
`CombatController.playSignature` refuse sans effet (tour ennemi, combat fini, pas prête, cible
unique sans ennemi choisi — jamais la sélection restante —, mana), puis résout la vue de carte,
pose la recharge, **ne touche aucune pile**, et appelle la **même suite commune** que la carte
(`_afterCardPlayed`) : **passifs et reliques** de son type la voient. *Marque du Mage* ne se
déclenche plus sur *Projectile Magique*, devenu Compétence — voulu, la note le dit.

**D5 — La liste de la run vit dans `RunState`, jamais sérialisée** (A8). `RunState.signatures`,
remplie par `startNewRun`, relue de la classe à la reprise comme `statRules`. Le deck de départ
est **les 5 cartes choisies, rien d'autre**.

**D6 — Amende ADR-094 D1, D2, D6** (A2, A10). `CardRarity.unique` disparaît : cinq raretés, une
échelle. `CardRarity.isAcquirable` disparaît : `DeckState.copyableCards` est **le deck entier**.
La réparation B5 au chargement est retirée — une instance `unique` ne peut plus exister.
`CardCategory`, `CardData.category` et `CardData.heroClass` disparaissent ; `CardData.fromJson`
refuse `heroClass` et `category`, nommés — l'appartenance d'une carte reviendra en vague 5 par un
champ injecté.

**D7 — Amende ADR-101 D1 et D3** (A9, A13). Le prédicat d'offre reste unique et devient
`CardData.isOfferable`, sans paramètre : `type != status`. Le motif qui tenait le draft de départ
dehors — les signatures ajoutées d'office, prenables deux fois — part avec elles : **le draft de
départ adopte le prédicat**, comme la boutique, la trouvaille et le pool du tutoriel. D2 d'ADR-101
(ne tester que `heroClass`) est sans objet ; D4 (aucun repli sur pool vide) tient.

**D8 — Amende ADR-084 D3 ; son interdit de noms n'est pas levé** (A3). `HeroData.skills` liste
désormais des **signatures**, compétences à recharge avec un point d'entrée — plus des cartes.
Aucun nom de l'ancienne chaîne n'est repris (`SkillData`, `SkillController`, `SkillState`,
`skillProvider`, `tickCooldowns`, `triggerSkill`, `executeSkill`) : `SignatureData`,
`SignatureInstance`, `playSignature`, `signaturesReadyOn`. L'invariant de purge d'ADR-084 reste
vrai tel quel — son motif `skills\.json` ne reconnaît pas `skills/<id>.json`. Seuls
`HeroData.skills` et le répertoire `skills/`, imposés par D49, portent le mot.

**D9 — L'interface** (A6, délégué par le propriétaire ; Q-P2, P-2). Une barre à gauche du HUD, à
mi-hauteur, en miroir du bouton de fin de tour ; cinq états par ordre de priorité (inactive, en
recharge, Mana insuffisant, armée, disponible), calculés par une fonction pure ; une signature à
cible unique **s'arme**, puis se joue sur l'ennemi touché — Flame rapporte l'ennemi par
`onSelectEnemy` et l'abandon par `onEnemyTargetCancelled`, sans connaître les signatures. Un bloc
sur la carte de classe, un onglet « Signatures » au dictionnaire (avec le type, réponse P-2). Le
tutoriel enseigne la barre **par la prose seule**.

**D10 — Complète ADR-086 et ADR-100** (A4). `skills/` injecte `heroClass` ; les champs que le
répertoire imposait aux cartes n'existent plus. L'éditeur de contenu gagne une **neuvième
catégorie**, `signature`, qui reprend la propriété de classe de la carte : neuf sources, neuf
descripteurs ; la carte devient neutre seulement.

### Preuves dans le code

| Quoi | Où |
|:---|:---|
| Le modèle et sa vue de carte | `lib/models/data/signature_data.dart` ; `lib/models/signature_instance.dart` (`asCard`) |
| Chargeur, registre, lien de classe | `lib/services/game_data_service.dart` (source `classes/*/skills/*.json`) ; `GameDataRegistry.signatures` ; `HeroSkillsLink.getSignatures` (`lib/models/data/hero_skills_link.dart`) |
| La recharge | `CombatState.signaturesReadyOn`, `signatureTurnsLeft`, `isSignatureReady` (`lib/models/combat_state.dart`) |
| Le jeu | `CombatController.playSignature` et `_afterCardPlayed` (`lib/game/controllers/combat_controller.dart`) |
| La run | `RunState.signatures`, `startNewRun(…, signatures)` (`lib/game/controllers/run_controller.dart`) |
| La purge | `CardRarity` à cinq valeurs, `CardData.isOfferable`, refus de `heroClass` et `category` (`lib/models/data/card_data.dart`) |
| L'interface | `lib/ui/widgets/hud/signature_bar.dart` (`signatureTileStateOf`) ; `lib/ui/widgets/signature_tile.dart` ; `HerosDraftGame.awaitingEnemyTarget` (`lib/game/heros_draft_game.dart`) |
| L'éditeur | `EntityCategory.signature` (`lib/services/content_editor/entity_descriptor.dart`) ; `ClassRecipe.signatures` |
| La donnée | `assets/data/classes/<classe>/skills/` — six fichiers |
| Tests neufs | `signature_data_test`, `signature_instance_test`, `combat_signature_test` (`test/unit/`) ; `signature_bar_test` (`test/widget/`) ; intégrité « aucun id de signature n'est un id de carte » (`test/unit/referential_integrity_test.dart`) ; `signature_cards_transition_test` retiré (A12) |

### Conséquences

- ✅ **Les signatures cessent d'encombrer chaque pool** : aucun filtre ne les écarte, elles n'y
  sont pas ; `isAcquirable`, `CardCategory`, la réparation B5 et le test de transition partent.
- ✅ **Un seul chemin « carte jouée »** : passifs et reliques voient une signature par la suite
  commune, extraite sans changer l'ordre du jeu d'une carte.
- ✅ **1694 tests** (+69 sur la base de 1625 de la porte d'entrée), `dart analyze` propre
  (**vérifié le 2026-10-16**).
- ⚠️ **Un deck de départ de 5 cartes pour 5 piochées par tour** : tout le deck en main au premier
  combat, un remélange chaque tour jusqu'à la première trouvaille — ce que la simulation a joué ;
  rien ne le corrige ici.
- ⚠️ **Une partie de la version précédente ne reprend pas** : `CardInstance.fromJson` lève sur la
  rareté `unique` de ses signatures et la sauvegarde est effacée — la règle avant la `1.0.0`.
- ⚠️ **La simulation ne tourne plus** : elle lit `classes/*/cards/` ; accepté (ADR-108 D5), aucune
  ligne de `tool/simulations/` n'a changé.
- ⚠️ **À la file** (compte rendu §2) : `playSignature` ne vérifie pas que l'ennemi visé est
  présent, comme une carte (S4) ; l'ennemi visé par la dernière carte garde sa bordure ambre
  pendant qu'une signature est armée (S12) ; la glue Flame du ciblage n'a pas de banc de test et
  se garde au test manuel. *Marque du Mage* attend D34, en vague 7.
