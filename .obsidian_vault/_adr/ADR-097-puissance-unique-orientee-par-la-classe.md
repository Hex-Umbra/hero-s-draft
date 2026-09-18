## 🧮 ADR-097 : La Puissance Unique, Orientée par la Classe (P-41, lot B)

### Statut
✅ Accepté & Implémenté — **lot B fusionné dans `main` en entier** : partie 1 par la PR #40
(2026-09-17, merge `e2cc24b`, branche `feat/p41-lot-b-puissance`, 6 commits `f20c353`..`e9b193d`) ;
**partie 2 par la PR #41** (2026-09-18, merge `5086272`, branche `feat/p41-lot-b-identite`,
18 commits `74c54cf`..`83e65b9`, section « Partie 2 » ci-dessous) — **amende [ADR-095](ADR-095-passage-unique-des-gains-scission-des-puissances-et.md)**
(décision 2, scission de `attaque` en trois puissances).

### Contexte
Le lot A ([ADR-095](ADR-095-passage-unique-des-gains-scission-des-puissances-et.md)) avait
scindé `attaque` en trois stats numériques — `attackPower`, `skillPower`, `alterationPower` —
en anticipant que la spec [S2 — Identité de classe](../../docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md)
§4 ferait viser des cartes différentes à des classes différentes. La conception du lot B,
reprise le 2026-09-17 (§7 de la spec, partie 1 = §7.6), a tranché autrement : trois champs
numériques dont deux valent 0 pour tout le monde ne modélisent pas mieux l'identité de classe
qu'un seul champ assorti de ce qu'il renforce. Une seule **Puissance**, `might`, remplace les
trois ; chaque classe déclare vers quelles cibles elle l'oriente. Aucun changement de jeu : les
trois classes actuelles orientent leur Puissance vers `attack`, exactement le comportement
d'aujourd'hui. Plan détaillé —
[`docs/superpowers/plans/2026-09-17-p41-lot-b-partie-1-puissance.md`](../../docs/superpowers/plans/2026-09-17-p41-lot-b-partie-1-puissance.md).

### Décision
1. **`enum MightTarget { attack, skill, alteration }`** (`lib/models/might_target.dart`),
   ordre = ordre d'affichage. `MightTarget.parseAll(Object?)` lit une liste JSON et lève
   `FormatException` sur une valeur qui n'est pas une liste, une liste vide, ou une cible
   inconnue — une classe dont la Puissance ne renforcerait rien est une faute de donnée.
2. **`HeroData.mightTargets`** (`Set<MightTarget>`) : champ **obligatoire** dans `class.json`,
   lu par `MightTarget.parseAll(json['mightTargets'])`, donc une classe sans cette clé ne se
   charge pas. Les trois classes (`berserker`, `mage`, `paladin`) déclarent `["attack"]`.
   L'éditeur de contenu (`entity_descriptor.dart`) l'expose en cases à cocher via
   `enumListKeys`, au même gabarit que `eligibleCardTypes`.
3. **`EntityStats.might`** remplace `attackPower`/`skillPower`/`alterationPower` ; **`EntityStats.mightTargets`**
   (`Set<MightTarget>`, défaut `{attack}` si absent en JSON) porte une **copie** de
   l'orientation de la classe. `RunController.startNewRun` et `TutorialMockState` la
   remplissent depuis `chosenClass.mightTargets`/`hero.mightTargets` à la création du héros.
   `EntityStats.effectiveMight` (renommage d'`effectiveAttackPower`) additionne `might` et le
   bonus du statut `might` (renommage du statut `strength`).
4. **`PowerRules`** (`lib/game/systems/power_rules.dart`) devient un unique point de lecture :
   `damageBonusFor`/`statusBonusFor` délèguent à `_mightFor(MightTarget target) => mightTargets.contains(target) ? effectiveMight : 0`.
   La forme des huit appels existants ne change pas ; seule la règle interne fusionne.
5. **`GainResource`** (`lib/game/systems/stat_gains.dart`) perd `attackPower`/`skillPower`/`alterationPower`
   au profit d'un seul `might`.
6. **Le statut `strength` devient `might`**, et les effets de relique associés :
   `gain_strength` → `gain_might`, `charge_strength_turn` → `charge_might_turn`,
   `charge_strength_combat` → `charge_might_combat`. La chaîne morte `applyAttackBuff`
   (`RunController` et `PlayerStatsManager`) est supprimée, façade et implémentation.
7. **Tous les textes joueur disent Puissance / Might** : cartes, reliques, événements portant
   `_fr`/`_en`, ARB régénérés. Le sous-titre de la carte « Puissance » de la fiche de stats liste
   ce qu'elle renforce via `Set<MightTarget>.shortLabel(l10n)`
   (`lib/models/data/model_extensions.dart`), qui itère `MightTarget.values` pour un ordre
   d'affichage stable quel que soit l'ordre interne du `Set`.
8. **Aucune migration de sauvegarde** (spec §7.5) : `SaveMigrator.currentVersion` reste à 2.
   L'étape v1→v2 du lot A continue d'écrire `attackPower` — format v2 gelé — que
   `EntityStats.fromJson` ignore désormais (`might` lu à défaut `0`, `mightTargets` à défaut
   `{attack}` si absent). Une sauvegarde du lot A se recharge donc sans étape supplémentaire et
   sans perte visible.

### Preuves dans le code
- `lib/models/might_target.dart` (`MightTarget`, `parseAll`).
- `lib/models/data/hero_data.dart` (`mightTargets`, requis dans `fromJson`).
- `lib/models/entity_stats.dart` (`might`, `mightTargets`, `effectiveMight`).
- `lib/game/systems/power_rules.dart` (`_mightFor`).
- `lib/game/systems/stat_gains.dart` (`GainResource.might`).
- `lib/game/controllers/run_controller.dart` (`mightTargets: chosenClass.mightTargets`),
  `lib/tutorial/tutorial_engine.dart` (`TutorialMockState`).
- `lib/game/controllers/run/player_stats_manager.dart` (`gain_might`, `charge_might_turn`,
  `charge_might_combat` ; `applyAttackBuff` supprimée).
- `lib/models/data/model_extensions.dart` (`MightTargetsLabels.shortLabel`).
- `lib/services/content_editor/entity_descriptor.dart` (`mightTargets` en `enumListKeys`).
- `assets/data/classes/{berserker,mage,paladin}/class.json` (`"mightTargets": ["attack"]`).
- Tests : `test/unit/might_target_test.dart`, `test/unit/might_orientation_test.dart`,
  `test/unit/might_targets_label_test.dart` — remplacent `test/unit/power_split_test.dart`
  (supprimé).

### Conséquences
- ✅ **Une seule stat numérique remplace trois**, dont deux valaient 0 pour tout le monde : le
  modèle colle enfin à l'identité de classe que la spec vise, sans les porter à vide.
- ✅ **Comportement de jeu strictement inchangé** : les trois classes orientent vers `attack`,
  938 tests au vert, `dart analyze` propre.
- ✅ **`PowerRules` reste l'unique règle** lue par la résolution de carte, les runes, le tutoriel
  (ADR-081) et l'aperçu de dégâts — la fusion ne recrée pas de copie parallèle.
- ⚠️ **`EntityStats.mightTargets` est un `Set` mutable** sur un modèle par ailleurs immuable —
  la partie 2 du lot B doit l'envelopper en non-modifiable (`docs/ROADMAP.md`, P-41 B).
- ⚠️ **L'icône d'épée à côté d'`effectiveMight` reste unique** quelle que soit l'orientation ; à
  différencier quand Mage et Paladin s'écarteront réellement d'`attack` (partie 2).
- ⚠️ **`docs/formation-heros-draft/` (ch08, 11, 13, 15, 16, 17)** montre encore les noms d'API
  d'avant renommage (`attackPower`, etc.) — instantané figé et daté, non corrigé par ce lot.

### Partie 2 — l'orientation devient réelle (2026-09-18)

La partie 1 posait la stat et le mécanisme sans que rien ne s'en serve : les trois classes visaient
`attack`. La partie 2 déclare les orientations, ajoute la seule règle qui s'applique **au gain**, et
livre les neuf passifs — [plan](../../docs/superpowers/plans/2026-09-17-p41-lot-b-partie-2-identite-de-classe.md).

**D1 — Les règles de stat vivent sur `RunState`, redérivées de la classe au chargement, jamais
sérialisées.** Seule décision de portée architecturale de la partie 2. `StatRule`
(`lib/models/data/stat_rule.dart` : `RuleStat`, `RuleMode`, `RuleTarget`) est lue de `class.json` par
`HeroData.statRules` ; `RunState.statRules` la porte pour la run, et `fromJsonWithReport` la **relit
du registre** par `heroClassId` (`HeroData.getById(...)?.statRules ?? const []`) — une règle est du
**contenu**, la figer dans les sauvegardes empêcherait le JSON de la changer. Précédent suivi :
`cardsPerTurn`, et la relecture du passif actif déjà faite là. `StatRule` porte une égalité **par
valeur**, sans quoi les tests de ce chemin passent par identité d'objet sans rien vérifier.

**D2 — `StatGains.apply(stats, gain, rules)` prend les règles en troisième paramètre positionnel
obligatoire.** Une valeur par défaut laisserait un site de gain oublié échapper aux règles en
silence — ce qui était arrivé à la Maîtrise d'Armure. Un ennemi reçoit `const []`.

**D3 — *Bénédiction* lit l'armure par une charge utile, pas en déplaçant le dispatch.** `startTurn`
**capture** l'armure avant la remise à `0` et la passe en `PassiveEvent.survivingArmor` ; déplacer
le dispatch aurait masqué l'armure de tout passif `startOfTurn` qui en donne.

**D4 — Un passif compte par un statut caché `<id>_count`** (`PassiveCounters`, `CounterScope`) :
durée 1 pour le tour, 99 pour le combat — l'idiome des charges de reliques. La portée vient de la
durée, **aucun état nouveau n'est à sérialiser**.

**D5 — `PassiveData.displayOrder`, et `availablePassivesFor` trie par `(displayOrder, id)`.** L'écran
de choix appartient au lot C : d'ici là le joueur reçoit `passives.first`. Sans rang explicite
l'ordre alphabétique déciderait, et le Berserker démarrerait sur *Soif de Sang*, le plus intriqué
des neuf. Le premier de chaque classe remplace le passif d'hier : `regen_armor`, `rage`, `channeling`.

**D6 — Le tutoriel n'hérite pas du `critChance` du Berserker** : `TutorialMockState.baseStatsForHero`
ne le recopie pas, un tutoriel aux dégâts aléatoires serait une régression. Ses règles viennent des
mêmes fonctions pures que le jeu — **aucune recopie** dans `lib/tutorial/`
([ADR-081](ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md)).

**Correctif d'ordre tiré de l'implémentation.** `StatusEffectProcessor.processPlayerStatuses`
terminait par `tickStatuses()`, qui décrémente **tout** statut, y compris un créé dans le même appel :
une Puissance convertie en `duration: 1` était annihilée avant usage — la conversion marchait depuis
une carte, pas depuis le statut `armor_regen`. Le tic passe **avant** le gain d'armure ; poison et
`might_regen` restent en place, ce dernier délibérément vieilli 3 → 2.

### Preuves dans le code (partie 2)
- `lib/models/data/stat_rule.dart`, `hero_data.dart` (`statRules`, `critChance`, `getById`).
- `lib/game/systems/stat_gains.dart` (`apply(..., rules)`, `_convert`).
- `lib/game/controllers/run_controller.dart` (`RunState.statRules`, capture de `survivingArmor`, dispatches `onEnemyKilled`/`onDamageTaken`) ; `combat/status_effect_processor.dart` (ordre du tic).
- `lib/game/systems/passives/` : `passive_counters.dart`, `passive_strategy.dart` (`PassiveEvent` enrichi), `passive_strategies.dart` (neuf stratégies).
- `assets/data/classes/{paladin,berserker,mage}/class.json` ; `assets/data/passives/` — neuf fichiers, `berserker_armor.json` et `spell_armor.json` supprimés.

### Conséquences (partie 2)
- ✅ **Les trois classes ne jouent plus pareil** : 1021 tests au vert, `dart analyze` propre.
- ⚠️ **Le Mage ne renforce plus aucun de ses dégâts** : toutes les cartes de dégâts sont de type
  Attaque, *Projectile Magique* compris. Sa Puissance renforce l'intensité de ses altérations
  jusqu'à ce que P-42 écrive des Compétences offensives — assumé, confirmé par le propriétaire.
- ⚠️ **Le Berserker n'a plus jamais d'armure** : toute source devient une Puissance d'un tour.
  *Mur de Fer* (10 armure, carte neutre) lui donne 10 de Puissance — l'échange voulu, à équilibrer.
- ⚠️ **Six passifs sur neuf sont inatteignables** tant que l'écran de choix du lot C n'existe pas.
- ⚠️ **`processEnemyStatuses` porte le même défaut d'ordre**, laissé hors périmètre : Puissance
  ajoutée en `duration: 1` puis tiquée, donc `might_regen` d'ennemi mort. Branche inatteignable —
  aucune donnée n'applique `might_regen` à un ennemi.
