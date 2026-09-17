# P-49 — Passifs partagés — Conception

Date : 2026-09-16
Statut : **Conçue, non implémentée**

Chantier ROADMAP : **P-49**, Tier B (`docs/ROADMAP.md` §4) — chantier frère de **P-41**, entre son lot A
(fusionné) et son lot B.
Sources amont :
- [Spec de P-41](2026-08-07-s2-identite-de-classe-design.md), §5 — frontière de P-49 et décisions P1 à
  P12, prises avant ce brainstorm ;
- brainstorm du 2026-09-16 avec le propriétaire, dont ce document consigne les décisions (§1).

> **Ce que P-49 livre, en une phrase.** Le passif déclare lui-même les classes qui peuvent le prendre ;
> un point d'accès unique dit quels passifs une classe peut choisir ; `TraitSystem` devient un
> répartiteur de stratégies ; et la Maîtrise d'Armure devient la **Maîtrise**, une stat unique dont
> chaque passif déclare l'effet — **les trois passifs existants gardent leur comportement**, à une
> exception d'équilibrage près, voulue (§6.4).

Toute référence `fichier:ligne` de ce document a été mesurée le 2026-09-16 sur `59a477e`.

---

## 1. Décisions

### 1.1. Décisions du brainstorm (2026-09-16)

| # | Décision | Motif |
|:---|:---|:---|
| N1 | **Maîtrise hybride** : une seule stat, *Maîtrise*, et une seule récompense ; **chaque passif déclare dans son fichier ce qu'un point de Maîtrise augmente** | Tranche la question ouverte D7 (spec P-41, §5.4). Une stat globale « +N » n'a pas de sens commun à neuf effets ; neuf récompenses dédiées doublaient le lot C. Ici, ajouter un passif reste un seul fichier, et la Maîtrise survit à un changement de passif |
| N2 | **Les triggers `onDamageTaken` et le comptage par tour et par combat quittent P-49 pour le lot B** | Leurs seuls consommateurs sont des passifs du lot B (*Ferveur*, *Flux de Mana*, *Marque du Mage*) et aucune relique ne les attend : livrés ici, ce serait du code sans lecteur |
| N3 | **La Maîtrise augmente un paramètre du passif**, jamais le résultat final. *Armure du Berserker* change donc d'échelle (§6.4) | Un seul mode dans le mécanisme. Le passif est remplacé par *Rage* au lot B ; le changement est annoncé en « Équilibrage » |
| N4 | Noms joueur : la stat s'appelle **Maîtrise**, sa récompense **Affinité** | La stat ne parle plus d'armure. « Forge d'Acier » disparaît |
| N5 | **L'éditeur de contenu apprend la liste de références** (`referenceList`) | Une classe mal orthographiée dans `classes` est refusée à la saisie. Le type resservira aux restrictions par classe de P-18 et P-42 |
| N6 | **Aucune étape de migration de sauvegarde** : la décision P11 est abandonnée | Avant la `1.0.0`, les sauvegardes ne se transfèrent pas d'une version à l'autre (décision du propriétaire, `docs/ROADMAP.md` §9). Le format change sans casser la lecture (§9) |
| N7 | **Moteur des passifs : registre de stratégies par `effectType`**, sur le modèle d'ADR-061 | Retenue contre des passifs composés des effets de cartes (§12) |

### 1.2. Les décisions P1 à P12 de la spec de P-41, relues

| # | Sort | Où |
|:---|:---|:---|
| P1 — passifs à plat sous `assets/data/passives/` | Conservée | §3 |
| P2 — le passif déclare ses classes, champ absent = toutes | Conservée, précisée : `[]` est refusé au chargement | §3.2 |
| P3 — `HeroData.passiveTrait` disparaît | Conservée, étendue à `RunState.passiveTrait` | §3.4 |
| P4 — point d'accès unique « éligibles et débloqués » | Conservée | §4 |
| P5 — tout lecteur passe par le point d'accès | Conservée | §4.2 |
| P6 — un seul passif actif par run | Conservée | — |
| P7 — `PassiveData` s'élargit, `TraitSystem` devient une Strategy | Conservée pour la Strategy ; **l'élargissement de `PassiveData` se limite ici à `classes` et `mastery`** — durée, seuil et ratio arrivent au lot B avec les passifs qui les lisent | §3, §5 |
| P8 — triggers de comptage | **Déplacée au lot B** (N2) | Spec P-41, §6.4 |
| P9 — `onDamageTaken`, dispatché aussi pour les reliques | **Déplacée au lot B** (N2), inchangée sur le fond | Spec P-41, §5.1 et §6.4 |
| P10 — l'appel de fin de tour quitte `game_screen.dart` | Conservée | §5.4 |
| P11 — étape de migration v2 → v3 | **Abandonnée** (N6) | §9 |
| P12 — un ADR remplace ADR-086 D4 | Conservée | §11 |

---

## 2. Périmètre

**Dans P-49**

- le champ `classes` et le bloc `mastery` des passifs, et le retrait de `passiveTrait` ;
- le point d'accès unique aux passifs disponibles, et le passage de ses deux lecteurs par lui ;
- `TraitSystem` en répartiteur de stratégies, avec les trois stratégies existantes ;
- la Maîtrise hybride : application au passif, retrait de la règle spéciale de `StatGains`, renommages,
  récompense *Affinité*, affichages ;
- `RunController.endTurn()` ;
- le type de champ `referenceList` de l'éditeur de contenu ;
- les textes joueur touchés, en français et en anglais.

**Hors de P-49**

| Sujet | Chantier |
|:---|:---|
| `onDamageTaken`, comptage par tour et par combat | P-41 lot B |
| Les neuf passifs, dont les paramètres durée, seuil, ratio | P-41 lot B |
| Le choix entre plusieurs passifs à la sélection | P-41 lot C |
| Filtrer *Affinité* quand le passif actif n'a pas de `mastery` | P-41 lot C (récompenses data-driven) |
| Stockage des déblocages, profil, interface de déblocage, plusieurs passifs actifs | P-13 |

**Aucun passif n'est ouvert à une autre classe par P-49.** Le modèle le permet sans code, mais chacun
des trois passifs actuels déclare sa seule classe : tant que l'écran de sélection prend le premier passif
disponible (§4.2), ouvrir `berserker_armor` à tous le donnerait au Paladin et au Mage.

---

## 3. Données

### 3.1. Le fichier d'un passif

```json
{
  "id": "regen_armor",
  "name_en": "Armor Regeneration",
  "name_fr": "Régénération d'Armure",
  "description_en": "Gain 2 Block automatically at the end of each turn.",
  "description_fr": "Gagne 2 points d'Armure automatiquement à la fin de chaque tour.",
  "classes": ["paladin"],
  "trigger": "endOfTurn",
  "effectType": "gain_armor",
  "value": 2,
  "mastery": {
    "field": "value",
    "perPoint": 1,
    "description_en": "+{amount} Block at end of turn",
    "description_fr": "+{amount} Armure en fin de tour"
  }
}
```

### 3.2. `classes`

| Valeur | Sens |
|:---|:---|
| Absent | Passif ouvert à **toutes** les classes |
| Liste non vide d'ids de classe | Passif réservé à ces classes |
| `[]` | **Refusé au chargement** : un passif réservé à personne est presque toujours une erreur, et « à tous » s'écrit en omettant le champ |

`PassiveData.classes` est une `List<String>?` : `null` pour « toutes ». Le chargeur ne vérifie pas que les
ids existent — il ne voit pas les classes quand il construit un passif ; ce contrôle est porté par
`referential_integrity_test` et par l'éditeur (§8, §10).

### 3.3. `mastery`

| Clé | Contrainte |
|:---|:---|
| `field` | Nom d'un paramètre entier du passif. **Seule valeur admise par P-49 : `value`.** Le lot B en ajoute une par paramètre qu'il crée. Une valeur inconnue est **refusée au chargement** |
| `perPoint` | Entier **non nul**, négatif admis — un seuil qui baisse avec la Maîtrise (*Rage*, lot B). Zéro est refusé |
| `description_fr`, `description_en` | Exigées, et **doivent contenir `{amount}`** — refusées au chargement sinon. `{amount}` est remplacé à l'affichage (§6.5) |

`mastery` est **optionnel** : un passif sans ce bloc ignore la Maîtrise. Les trois passifs actuels le
déclarent tous.

`PassiveData.fromJson` lève sur toute violation de §3.2 et §3.3 : le chargeur accumule l'erreur avec les
autres (`GameDataLoader.throwIfFailed`), et l'éditeur la voit par le `construct` du descripteur.

### 3.4. Ce qui disparaît

| Élément | Site |
|:---|:---|
| `"passiveTrait"` des trois `class.json` | `assets/data/classes/{berserker,mage,paladin}/class.json:13` |
| `HeroData.passiveTrait` | `lib/models/data/hero_data.dart:25`, `:46`, `:81` |
| `RunState.passiveTrait`, son écriture et sa lecture | `lib/game/controllers/run_controller.dart:28`, `:65`, `:83`, `:103`, `:125`, `:181`, `:212`, `:244` |
| « (+ Maîtrise) » / « (+ Mastery) » dans les descriptions des passifs | `assets/data/passives/*.json` — l'effet de la Maîtrise est désormais porté par `mastery` |

`RunState.passiveTrait` n'est lu par aucune règle : seul `activePassive` l'est. Le champ disparaît sans
remplaçant.

---

## 4. Le point d'accès unique

### 4.1. La fonction

```dart
// lib/game/systems/passive_availability.dart
List<PassiveData> availablePassivesFor(HeroData hero, GameDataRegistry registry)
```

- Rend les passifs dont `classes` est `null` ou contient `hero.id`.
- **Triés par `id`** : l'ordre ne dépend pas de l'ordre de lecture des fichiers.
- Pure, sans provider : le tutoriel l'appelle comme le jeu (ADR-081).
- **Ne lit aucun déblocage.** Tant que P-13 n'existe pas, « débloqué » vaut « tous ». P-13 ajoutera son
  filtre **dans** cette fonction, sans toucher à ses lecteurs.

### 4.2. Ses lecteurs

| Lecteur | Aujourd'hui | Avec P-49 |
|:---|:---|:---|
| Écran de sélection | `lib/ui/screens/class_selection_screen.dart:155` — filtre `passives` sur `passiveTrait` | Premier élément de `availablePassivesFor`, `null` si la liste est vide |
| Tutoriel | `lib/tutorial/tutorial_fixtures.dart:54` — `firstWhere` sur `passiveTrait` | Premier élément de `availablePassivesFor` |

Aucun autre code ne lit `registry.passives` pour choisir un passif. `PassiveData.getById`
(`lib/models/data/passive_data.dart:54`) reste : il retrouve **le** passif actif d'une sauvegarde par son
id, ce qui n'est pas un choix.

**Une classe sans passif disponible démarre sa run sans passif**, comme le permet déjà
`test/unit/passive_absent_test.dart`. Le jeu livré n'en a pas : §10 le vérifie.

---

## 5. Le moteur

### 5.1. La stratégie

```dart
// lib/game/systems/passives/passive_strategy.dart
class PassiveEvent {
  final RelicTrigger trigger;
  final CardInstance? card; // renseignée pour onCardPlayed
  const PassiveEvent(this.trigger, {this.card});
}

abstract class PassiveStrategy {
  const PassiveStrategy();
  void resolve(PassiveData passive, PassiveEvent event, RunController run);
}
```

Une stratégie reçoit le passif **après application de la Maîtrise** (§6.2) : elle ne lit jamais la stat.

### 5.2. Le registre

`lib/game/systems/passives/passive_strategies.dart` déclare les stratégies et la table `effectType` →
stratégie, **constante** : c'est une table de code, pas un état.

| `effectType` | Stratégie | Comportement, inchangé |
|:---|:---|:---|
| `gain_armor` | `GainArmorPassive` | Accorde `value` d'armure |
| `berserker_armor` | `BerserkerArmorPassive` | Accorde `(PV manquants ~/ 10) × value` d'armure, rien si le total est nul |
| `spell_armor` | `SpellArmorPassive` | Accorde `value` d'armure si la carte jouée est de type `skill` |

Chaque gain passe par `RunController.grant(StatGain(GainResource.armor, n, GainSource.passive))`, comme
aujourd'hui (`lib/game/systems/trait_system.dart:21`, `:26`, `:40`, `:55`).

Un `effectType` absent de la table **ne fait rien** en jeu : pas d'exception en plein combat. Un test
refuse qu'un passif livré soit dans ce cas (§10).

### 5.3. `TraitSystem`, répartiteur

`TraitSystem.onTurnStart`, `onTurnEnd` et `onCardPlayed` (`trait_system.dart:9`, `:34`, `:48`) sont
remplacés par une seule entrée :

```dart
static void dispatch(RunController run, PassiveEvent event)
```

1. lit `run.currentState.activePassive` — rien s'il est `null` ;
2. **compare le `trigger` du passif à celui de l'événement** — rien s'ils diffèrent ;
3. applique la Maîtrise : `passive.withMastery(heroStats.effectiveMastery)` ;
4. appelle la stratégie de l'`effectType`.

L'étape 2 est ce qui rend le trigger réellement data-driven : aujourd'hui, `gain_armor` n'est honoré
qu'en `startOfTurn` et `endOfTurn`, parce que la chaîne `if/else` ne le teste que là. Avec P-49, il suit
le `trigger` déclaré.

| Appel actuel | Devient |
|:---|:---|
| `run_controller.dart:394` (début de combat) et `:415` (début de tour) | `dispatch(this, PassiveEvent(RelicTrigger.startOfTurn))` |
| `combat_controller.dart:227` | `dispatch(runController, PassiveEvent(RelicTrigger.onCardPlayed, card: card))` |
| `game_screen.dart:522` | Dans `RunController.endTurn()` (§5.4) |

### 5.4. `RunController.endTurn()`

`lib/ui/screens/game_screen.dart:522-525` déclenche aujourd'hui, depuis l'écran, le passif puis les
reliques de fin de tour. Les deux appels passent dans une méthode du controller, **dans le même ordre** :

```dart
void endTurn() {
  TraitSystem.dispatch(this, const PassiveEvent(RelicTrigger.endOfTurn));
  applyRelics(RelicTrigger.endOfTurn);
}
```

L'écran appelle `endTurn()`, puis garde la défausse (`deckProvider`) et `_game.executeTurn()`, qui ne
relèvent pas de `RunController`. C'est le miroir de `startTurn()` (`run_controller.dart:397`).

---

## 6. La Maîtrise

### 6.1. La stat

| Aujourd'hui | Avec P-49 |
|:---|:---|
| `EntityStats.armorMastery`, clé JSON `armorMastery` (`lib/models/entity_stats.dart:11`, `:98`, `:119`) | `EntityStats.mastery`, clé `mastery` |
| `EntityStats.effectiveArmorMastery` (`entity_stats.dart:168`) | `effectiveMastery` |
| Statut de combat `armor_mastery` (`player_stats_manager.dart:265`) | `mastery`, nommé « Maîtrise (Relique) » |
| `HeroData.armorMastery`, clé `armorMastery` (`hero_data.dart:24`, `:80`) | `HeroData.mastery`, clé `mastery` — aucune classe ne la renseigne aujourd'hui |
| `applyHeroStatModifier(armorAcc:)` (`player_stats_manager.dart:48`) | `masteryAcc:` |

`effectiveMastery` garde la même définition : la stat permanente plus la valeur des statuts `mastery`.

### 6.2. Appliquer la Maîtrise au passif

```dart
// lib/models/data/passive_data.dart
PassiveData withMastery(int points)
```

- Rend une copie dont le paramètre désigné par `mastery.field` vaut `valeur + perPoint × points`.
- Rend le passif **tel quel** si `mastery` est absent ou si `points` vaut 0.
- Fonction pure, testée seule. Borner le résultat — un seuil qui ne doit pas descendre sous 1 — est
  l'affaire de la stratégie qui le lit, pas de cette fonction.

### 6.3. `StatGains` perd sa règle spéciale

Aujourd'hui, un gain d'armure de source `passive` reçoit la Maîtrise **au moment du gain**
(`lib/game/systems/stat_gains.dart:45`, `:66-67`). Avec P-49, la Maîtrise est déjà dans le passif quand
la stratégie calcule son gain : **la règle et `_masteryFor` disparaissent**, et `apply` traite l'armure
comme toute autre ressource.

`GainSource.passive` reste : c'est l'étiquette du gain, que `statRules` pourra viser au lot B. Seul son
commentaire, qui cite la Maîtrise d'Armure (`stat_gains.dart:6-7`), change.

Le garde du lot A, `test/unit/stat_gain_single_passage_test.dart`, n'est pas touché : aucun gain ne
quitte le point de passage unique.

### 6.4. Ce que le joueur voit changer au combat

| Passif | Aujourd'hui | Avec P-49 | Maîtrise 2, 40 PV manquants |
|:---|:---|:---|:---|
| Régénération d'Armure | `2 + M` | `2 + M` | 4 → 4 |
| Armure Magique | `1 + M` par Compétence | `1 + M` | 3 → 3 |
| **Armure du Berserker** | `tranches × 1 + M` | **`tranches × (1 + M)`** | **6 → 12** |

À pleine vie, le Berserker ne gagne toujours rien : `0 × (1 + M) = 0`, comme aujourd'hui où le gain nul
n'appelait pas `grant`.

**Le changement du Berserker est voulu** (N3) et annoncé en « Équilibrage » dans la note de version. Il
dure jusqu'au lot B, où *Rage* remplace ce passif.

### 6.5. Afficher l'effet de la Maîtrise

`{amount}` est remplacé par **`|perPoint × points|`** : le signe est porté par le texte, qui sait si
l'effet monte ou descend (« +{amount} Armure », « Seuil −{amount} »).

| Où | Texte affiché | `points` |
|:---|:---|:---|
| Carte de récompense *Affinité* | « {nom du passif actif} : {effet} » | La valeur tirée |
| Fiche des stats (`lib/ui/widgets/map/dialogs/stats_dialog.dart`), sous la description du passif | « Maîtrise : {effet} », si `effectiveMastery > 0` et que le passif actif déclare `mastery` | `effectiveMastery` |
| Écran de sélection, sous la description du passif, s'il déclare `mastery` | « Par point de Maîtrise : {effet} » | 1 |

**Sans passif actif, ou avec un passif sans `mastery`**, *Affinité* affiche « +{N} Maîtrise, sans effet
sur votre passif ». Aucun passif livré n'est dans ce cas ; la récompense reste donc tirée comme
aujourd'hui, et son filtrage relève du lot C (§2).

La tuile « Maîtrise +N » de la fiche des stats (`stats_dialog.dart:182-183`) et du mini-panneau
(`lib/ui/widgets/map/hero_mini_stats_panel.dart:108`) reste, sur `effectiveMastery`.

### 6.6. La récompense *Affinité*

| Aujourd'hui | Avec P-49 |
|:---|:---|
| `LevelUpRewardType.steelForge` (`lib/game/services/level_up_reward_service.dart:11`, `:185`) | `affinity` |
| `DraftChoice.armorBoost` (`level_up_reward_service.dart:23`, `:35`, `:186`) | `masteryBoost` |
| Consommation : `draft_screen.dart:644` | `masteryAcc: choice.masteryBoost` |
| ARB `draftChoiceSteelForge`, `draftChoiceSteelForgeDesc` | `draftChoiceAffinity`, `draftChoiceAffinityDesc`, `draftChoiceAffinityNoEffect` (§7) |
| Icône de la carte de draft, choisie sur le titre : `contains('FORGE')` → 🛡️ (`lib/ui/widgets/draft/draft_choice_card.dart:49-50`) | `contains('AFFINIT')` → 💠 — sans quoi *Affinité* retomberait sur l'icône par défaut ✨ |

**Les valeurs ne changent pas** : 1, 2, 3, 5, 7 selon la rareté. `test/unit/level_up_reward_values_test.dart`
les verrouille déjà ; il est seulement renommé en suivant l'enum.

`DraftChoiceLabels.getChoiceDescription` (`lib/ui/widgets/draft/draft_choice_labels.dart:59`) ne
connaît que le choix : il reçoit en plus le passif actif, pour composer le texte de §6.5.

### 6.7. La relique *Croc Kunaï*

`effectType` `charge_armor_mastery_combat` devient `charge_mastery_combat`, dans
`assets/data/relics/kunai.json` et dans son `case` (`player_stats_manager.dart:251`). Son effet est
inchangé : toutes les 3 attaques jouées dans un tour, +1 Maîtrise pour le combat — désormais valable
pour n'importe quel passif qui déclare `mastery`.

---

## 7. Textes joueur

| Élément | Français | English |
|:---|:---|:---|
| Stat | Maîtrise | Mastery |
| Récompense | Affinité | Affinity |
| `draftChoiceAffinityDesc` | `{passive} : {effect}` | `{passive}: {effect}` |
| `draftChoiceAffinityNoEffect` | `+{amount} Maîtrise, sans effet sur votre passif` | `+{amount} Mastery, no effect on your passive` |
| Ligne de la fiche des stats | `Maîtrise : {effect}` | `Mastery: {effect}` |
| Ligne de l'écran de sélection | `Par point de Maîtrise : {effect}` | `Per Mastery point: {effect}` |
| Statut de *Croc Kunaï* | Maîtrise (Relique) | — *(les noms de statut ne sont qu'en français aujourd'hui)* |

**Les trois passifs**

| Passif | `description_fr` | `mastery.description_fr` | `mastery.description_en` |
|:---|:---|:---|:---|
| `regen_armor` | Gagne 2 points d'Armure automatiquement à la fin de chaque tour. | +{amount} Armure en fin de tour | +{amount} Block at end of turn |
| `berserker_armor` | Gagne 1 point d'Armure au début du tour pour chaque tranche de 10 PV manquants. | +{amount} Armure par tranche de 10 PV manquants | +{amount} Block per 10 missing HP |
| `spell_armor` | Gagne 1 point d'Armure instantanément chaque fois que vous jouez une carte Compétence. | +{amount} Armure par Compétence jouée | +{amount} Block per Skill played |

Les `description_en` perdent de même « (+ Mastery) ».

**Croc Kunaï** — « Toutes les 3 attaques jouées dans un tour, gagne 1 Maîtrise pour le combat. » / « Every
3 Attacks played in a turn, gain 1 Mastery for combat. »

**Tutoriel** (`lib/tutorial/tutorial_data.dart:310-329`) — la liste des récompenses cite *Affinité* à la
place de *Forge d'Acier*, et le dernier paragraphe devient : « Attention à l'Affinité : elle donne de la
**Maîtrise**, qui renforce ce que produit votre passif — chaque passif indique ce qu'un point lui
apporte. » / « Careful with Affinity: it grants **Mastery**, which strengthens what your passive
produces — each passive states what one point adds. »

**Étape « Armure & Dégâts »** (`tutorial_data.dart:179-181`, `:189-191`) — sa dernière phrase affirme que la
Maîtrise d'Armure « s'ajoute à chaque gain d'Armure produit par votre passif », ce que P-49 rend faux.
Elle devient : « La Maîtrise, statistique permanente, renforce ce que produit votre passif — chaque passif
indique ce qu'un point lui apporte. » / « Mastery, a permanent stat, strengthens what your passive
produces — each passive states what one point adds. »

Le reste de la prose du tutoriel n'est pas réécrit : c'est le lot D.

---

## 8. L'éditeur de contenu

### 8.1. Le type de champ `referenceList`

| Élément | Changement |
|:---|:---|
| `FieldKind` (`lib/services/content_editor/field_kind.dart:5`) | Nouvelle valeur `referenceList` |
| `EntityDescriptor` (`entity_descriptor.dart:98-99`) | Nouveau champ `referenceListKeys`, clé → catégorie, à côté de `referenceKeys` |
| `inferFieldKind` (`field_kind.dart:34`) | Un motif de `referenceListKeys` rend `referenceList`, juste après `reference` |
| Validateur, famille 6 (`entity_validator.dart:313`, `_references` `:318`) | Pour `referenceListKeys` : la valeur est une liste de chaînes, **non vide**, dont chaque élément désigne une entité existante. Registre indisponible : on ne devine pas, comme pour `referenceKeys` |
| Formulaire (`lib/ui/widgets/content_editor/document_form.dart`) | Une case à cocher par entité de la catégorie, lues dans le registre. Aucune case cochée retire la clé — « toutes les classes » —, puisque `[]` est refusé |

### 8.2. Les descripteurs

**Passif** (`entity_descriptor.dart:240-255`)

- `referenceListKeys: {'classes': EntityCategory.heroClass}` ;
- `enumKeys` gagne `'mastery.field': ['value']` ;
- le gabarit gagne `mastery` complet — `field`, `perPoint`, les deux descriptions — et **pas** `classes`,
  dont l'absence vaut « toutes » ;
- les descriptions de `mastery` sont exigées par `PassiveData.fromJson` (§3.3), donc refusées par le
  `construct` du descripteur : pas de nouvelle famille bilingue.

**Classe** (`entity_descriptor.dart:317-347`)

- `referenceKeys` perd `passiveTrait` et devient vide ;
- le gabarit remplace `"armorMastery": 0` par `"mastery": 0`.

Les commentaires qui citent `passiveTrait` en exemple de référence (`entity_descriptor.dart:98`,
`entity_validator.dart:315`, `lib/ui/screens/content_editor_screen.dart:489`) sont mis à jour.

---

## 9. La sauvegarde

**Aucune étape de migration, et `SaveMigrator.currentVersion` reste à 2** (N6).

| Écrit avant P-49 | Relu après P-49 |
|:---|:---|
| `heroStats.armorMastery` | Ignoré : `mastery` est absent, lu à 0. **La Maîtrise accumulée est perdue** |
| `passiveTrait` | Ignoré |
| `activePassiveId` | Relu, inchangé : le passif actif est retrouvé |

La partie reste jouable. Avant la `1.0.0`, perdre la Maîtrise d'une partie en cours entre deux versions
est acceptable, et ce n'est ni testé ni annoncé.

Aucun statut n'est sérialisé en cours de combat : `SaveService` n'est jamais appelé en combat, et le
statut `armor_mastery` de *Croc Kunaï* ne survit pas au combat.

---

## 10. Tests

| Sujet | Fichier | Ce qu'il verrouille |
|:---|:---|:---|
| Données | `test/unit/passive_data_test.dart` *(nouveau)* | `classes` absent → `null` ; `[]` refusé ; `mastery` absent ; `field` inconnu, `perPoint` nul, description vide ou sans `{amount}` refusés ; `withMastery` : paramètre augmenté, `perPoint` négatif, `points` à 0, `mastery` absent |
| Point d'accès | `test/unit/passive_availability_test.dart` *(nouveau)* | Éligibilité par `classes`, passif ouvert à toutes, tri par `id`, classe sans passif → liste vide |
| Répartiteur | `test/unit/trait_system_test.dart` *(nouveau)* | Trigger différent → rien ; pas de passif actif → rien ; Maîtrise appliquée avant la stratégie ; `effectType` inconnu → rien |
| Comportement | `test/unit/stat_gains_characterization_test.dart:154-199` | Réécrit sur `dispatch`, passifs avec `mastery` : régénération et Armure Magique **à valeurs identiques** ; Berserker `2 × (1 + 3)` au lieu de `2 × 1 + 3`, **nommé comme un changement voulu** ; Berserker à pleine vie toujours à 0 |
| `StatGains` | `test/unit/stat_gains_test.dart:25-55` | Les trois tests de la Maîtrise sur un gain de passif (`:31`, `:36`, `:50`) partent : la règle n'est plus là. Le test « jamais de Maîtrise » (`:25`) couvre désormais **toutes** les sources, `passive` comprise. La prise en compte du statut est reprise par `trait_system_test`, sur `effectiveMastery` |
| Fin de tour | `test/unit/run_controller_test.dart` | `endTurn()` exécute le passif **avant** les reliques de fin de tour |
| Intégrité | `test/unit/referential_integrity_test.dart:35-48` | Le test `passiveTrait` est remplacé par trois : chaque id de `classes` désigne une classe ; chaque classe a au moins un passif disponible ; chaque `effectType` de passif a sa stratégie |
| Récompense | `test/unit/level_up_reward_values_test.dart` | Valeurs inchangées sous `affinity` |
| Éditeur | `test/unit/content_editor/field_kind_test.dart`, `entity_validator_test.dart`, `entity_descriptor_test.dart`, `test/widget/content_editor/document_form_test.dart` | `referenceList` inféré ; liste vide et id inconnu refusés ; cases à cocher rendues et écrites |
| Écrans | `test/widget/class_selection_screen_test.dart`, `test/widget/draft_screen_test.dart` | Ligne « Par point de Maîtrise » ; texte d'*Affinité* composé avec le passif actif, et sa variante sans effet |
| Tutoriel | `test/tutorial/tutorial_fixtures_test.dart:30` | Le passif du tutoriel est le premier passif disponible de la classe |

Les autres tests qui construisent `armorMastery: 0` ou `passiveTrait:` — une vingtaine de fichiers
sous `test/` — suivent les renommages sans changer ce qu'ils vérifient.

`dart analyze` propre et suite verte, comme chaque lot du programme.

---

## 11. Documentation et livraison

| Quoi | Où |
|:---|:---|
| Spec de P-41 : §5.1 (P8, P9, P11), §5.4 tranchée, §6.3 et §6.4, §8.2 — renvoient à ce document | Même commit que cette spec |
| `docs/ROADMAP.md` et `docs/INDEX.md` : lien vers cette spec | Même commit que cette spec |
| ADR qui **remplace ADR-086 D4** et consigne la Maîtrise hybride | À la livraison, par `memory-bank-sync` |
| Note de version : **`0.5.2` rouverte en place** (décision du propriétaire, `docs/ROADMAP.md` §4) — *Équilibrage* : Armure du Berserker ; *Améliorations* : Maîtrise et Affinité, effet de la Maîtrise affiché | À la livraison, par `patch-notes-writer` |

---

## 12. Alternatives écartées

| Idée | Motif |
|:---|:---|
| **Maîtrise en stat globale, « +N » uniforme** | Un même +N n'a pas de sens pour de l'armure, de la Force, du mana et une durée de statut (spec P-41, §5.4) |
| **Maîtrise par passif, neuf récompenses dédiées** | Neuf récompenses à écrire et à équilibrer, dont une seule éligible par run ; la Maîtrise perdue au changement de passif. Remplacé par N1 |
| **Garder le comportement exact d'*Armure du Berserker*** | Aurait demandé un second mode, « bonus sur le résultat final », pour un passif remplacé au lot B (N3) |
| **Passifs composés des effets de cartes** (`effects` résolus par `EffectRegistry`) | La moitié des passifs du lot B — armure survivante en PV, vol de vie croissant, mana non dépensé en armure — exigerait conditions et formules dans le JSON. Un langage à concevoir, trop tôt |
| **`TraitSystem` en `switch`, nettoyé** | Neuf branches de plus au lot B : exactement ce que P7 évite |
| **Poser `onDamageTaken` et le comptage dans P-49** | Code sans lecteur jusqu'au lot B (N2) |
| **Étape de migration v2 → v3** | Protège une compatibilité de sauvegarde que le propriétaire exclut avant la `1.0.0` (N6) |
| **`classes` en texte libre dans l'éditeur** | Une classe mal orthographiée n'aurait été vue que par la suite de tests (N5) |
| **`{amount}` signé** | Un seuil qui baisse s'afficherait « Seuil −−1 » ou obligerait chaque texte à gérer le signe |
| **Ouvrir les trois passifs actuels à toutes les classes** | Tant que la sélection prend le premier passif disponible, tout le monde recevrait `berserker_armor` (§2) |
