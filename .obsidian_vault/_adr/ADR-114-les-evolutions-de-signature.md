---
description: Signature evolutions — every five hero levels each signature gains a level, chosen among three draws from its own pool (three minors, four majors, minors at odd signature levels, majors at even ones, a major may exclude another), stored as id:level references on SignatureInstance and saved under signatureEvolutions; picked on a three-reel screen opened from the map curtain; in combat the signature tile shows its evolved effects as icons with their values, a level badge and evolution pips, and unfolds the full list on long press; one effect icon table, effect_icons.json, shared with the status panel
---

# ADR-114 — Les Évolutions de Signature : un Pool par Signature, un Tirage Pur, un Écran à Trois Rouleaux, une Tuile en Icônes

### Statut

✅ Accepté — 2026-11-04 ; **D3 (le tirage) et D4 (l'écran à trois rouleaux) amendés le 2026-11-07 par
[ADR-115](ADR-115-le-choix-libre-des-evolutions-et-les-rideaux-de-la-carte.md)** : plus de tirage, les
deux signatures sur un écran, trois rideaux. (P-42, **tranche 1**, partie 3 ; brainstorm v3, décisions D7, D19, D21, D54 ;
réponses du propriétaire Q6, Q7, P-2, P-4, PN12, PN13, P-5, P-6, P-7, du 2026-11-03 au 2026-11-04).
**Livré sur la branche `feat/v0.5.7-p42-tranche-1-p44-lot-1` — vague 5 du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Code `e4be0236`..`052fa3b4`
et le correctif de revue `f9f4da3f`, sur le plan `d125d597`, écrit sous D77
([ADR-113](ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md)) ; note de version `22da17b5`.
**Complète** [ADR-109](ADR-109-signatures-hors-du-deck.md) : `SignatureInstance` reçoit les
évolutions qu'ADR-109 lui destinait. Conception :
[spec](../../docs/superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §3.7, §4.10, §5.1,
§5.2, §5.4, §8 — arbitrages A24 à A42 ; décisions de SDD S15 à S23 au
[compte rendu](../../docs/superpowers/reports/2026-11-03-economie-et-catalogue-vague-5-compte-rendu.md), §2.

### Contexte

ADR-109 a sorti les signatures du deck sans leur donner de progression : une signature au niveau 30
du héros jouait comme au niveau 1. D7 et D19 veulent qu'elles évoluent avec le héros, par des
améliorations propres à chacune, choisies par le joueur ; D21 fixe le rythme. L'écran devait dire
tout ce que l'évolution change (P-2 : « rien n'est caché »), et la tuile de combat, déjà étroite,
ne pouvait pas porter en texte une description qui s'allonge à chaque évolution.

### Décision

**D1 — Un pool par signature, en donnée** (D7, Q6, Q7). Chaque `classes/<id>/skills/<id>.json`
porte `evolutions` : 3 mineures et 4 majeures, 42 en tout. Une évolution a un palier, un nom et une
description bilingues, des `deltas` (`flatBonus`, `addEffect`, `reduceCost`, `critBonus`), et, pour
une majeure, une `target: allEnemies`, un `cooldown` et des `excludes` lus dans les deux sens. Les
descriptions des signatures deviennent des gabarits (`{damage}`, `{armor}`…) remplis par les valeurs
évoluées. *Célérité* (`haste`, recharge −1, jamais sous 1) est une majeure (D54), absente du pool de
*Surtension de Mana*.

**D2 — Le rythme** (D19, D21). Tous les 5 niveaux du héros, chaque signature gagne un niveau ;
mineure aux niveaux impairs de signature (héros 5, 15, 25…), majeure aux pairs (10, 20…), sans
plafond. L'attente se dérive, jamais stockée : `pendingFor(heroLevel) = max(0, heroLevel ~/ 5 −
level)`. Deux signatures en attente : la plus basse d'abord, à égalité dans l'ordre de
`HeroData.skills` (S16).

**D3 — Le tirage et le choix, une règle pure** (A26). `SignatureEvolutionRules` : trois évolutions
sans poids ni remise, au palier dû ; au palier majeur, des mineures complètent quand il reste moins
de trois majeures éligibles. Une mineure reprise monte d'un niveau à sa place, toute autre entre à
`id:1`. Le jeu (`RunController.chooseSignatureEvolution`) et le menu de debug
(`DebugActions.takeSignatureEvolution`, P-7) posent par la même règle, `take` (S23).

**D4 — L'écran à trois rouleaux** (D19, P-4). `SignatureEvolutionScreen`, sur le patron du draft de
niveau : nom, description au prochain niveau, palier, « Niveau 1 → 2 » pour une mineure reprise,
l'icône de l'évolution sur le rouleau. Le rideau de la carte reste tant qu'un draft de niveau ou une
évolution attend, et ouvre l'un puis l'autre. Le retour système ne relance plus le tirage (S19).

**D5 — La tuile de combat en icônes** (PN12 (d), P-2 (c), PN13 (c), P-5 (a)). Au repos, une icône
par effet évolué avec sa valeur, trois par ligne ; un badge « Niv. n » en ambre d'accent ; une puce
par évolution prise. L'appui long déroule la liste complète, une phrase par icône, dans un calque
par-dessus les voisines, dans tous les états, inactive comprise ; il ne joue rien. Hors combat, la
tuile garde son texte.

**D6 — Une seule table d'icônes en combat** (P-6 (a), A39). `assets/data/effect_icons.json`, seize
sortes, chacune à l'icône et à la couleur que les faces des cartes lui donnent, un test gardant
l'égalité ; la bande, la liste, les puces et les panneaux des statuts du héros et du tutoriel la
lisent.

**D7 — La sauvegarde** : `signatureEvolutions`, une liste de références par signature, toujours
écrite, vide s'il n'y a rien (S17) ; `schemaVersion` inchangé. Une référence d'un id absent du pool
entre au rapport des éléments manquants.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Le modèle d'une évolution | `lib/models/data/signature_evolution_data.dart` ; les pools, `assets/data/classes/*/skills/*.json` |
| La vue évoluée, l'attente, la relecture | `lib/models/signature_instance.dart` (`taken`, `asCard`, `effectLines`, `pendingFor`, `nextTier`, `restore`) |
| Le tirage et le choix | `lib/game/systems/signature_evolution_rules.dart` ; `RunController.chooseSignatureEvolution`, `.nextPendingEvolution`, `.hasPendingChoice` |
| L'écran, le rideau | `lib/ui/screens/signature_evolution_screen.dart` ; `lib/ui/screens/map_screen.dart` ; `DraftCardReel`, `DraftChoiceCard` (icône facultative) |
| La tuile, la bande, le calque | `lib/ui/widgets/hud/signature_bar.dart` |
| La table d'icônes | `assets/data/effect_icons.json` ; `lib/models/data/effect_icon_table.dart`, `effect_kind.dart` ; `lib/ui/widgets/effect_style.dart` ; `StatusEffectsPanel` |
| L'entrée de debug | `lib/game/services/debug_actions.dart` ; `lib/ui/widgets/debug/tabs/debug_hero_tab.dart` |
| Les évolutions dans l'éditeur de contenu | `lib/services/content_editor/`, commit `052fa3b4` |

Règle de jeu : [`_rules/02-8`](../_rules/02-8-evolutions-de-signature.md). Patterns :
[`_patterns/03-8`](../_patterns/03-8-signatureevolutionrules-regles-pures-des-evolutions.md),
[`_patterns/05-12`](../_patterns/05-12-barre-de-signatures-bande-et-calque.md),
[`_patterns/05-13`](../_patterns/05-13-table-d-icones-d-effet.md).

### Conséquences

- **Aucun test d'écran ne garde la tuile ni l'écran** (D77) : les points M7 à M34 des tests manuels
  (spec §9.1), préparés par l'entrée de debug.
- **Les faces des cartes, les émojis des statuts ennemis et l'icône de la rune *Précis*** ne lisent
  pas encore `effect_icons.json` ; les infobulles des cartes, que le propriétaire veut revoir, ne sont
  pas touchées (PN12) — deux lignes de `docs/ROADMAP.md`.
- **Un `flatBonus` qui vise un effet absent de sa signature est accepté en silence** par le
  chargeur ; `asCard` est recalculé à chaque lecture ; `effectLines` est couplé par l'ordre sans
  `assert` (compte rendu §4).
- **Le rideau de la carte est en français en dur** et ne dit pas ce qui attend (draft ou évolution)
  — à la file.
- **Les signatures se lisent hors combat sans évolution** : carte de classe et dictionnaire montrent
  la donnée, jamais une instance.
