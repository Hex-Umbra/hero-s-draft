### Statut

✅ **Livré sur la branche `feat/p49-passifs-partages`** (chantier P-49, commits `a422544`..`4e937fa`),
**fusionnée dans `main` par la PR #39 le 2026-09-17** (merge `56be78d`). **Remplace la décision D4 d'[ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md).**
Prépare [P-13](../../docs/ROADMAP.md) (méta-progression) sans en construire aucune part. Précède le
lot B de P-41 (spec [S2](../../docs/superpowers/specs/2026-08-07-s2-identite-de-classe-design.md)),
qui en dépend.

### Contexte

ADR-086 D4 excluait les passifs de l'injection d'appartenance par répertoire (`PassiveData` n'a pas
de champ `heroClass`, une injection y serait silencieusement perdue) et les liait à leur classe par
`HeroData.passiveTrait` — un champ sur la classe, qui nomme un passif. Ce lien était **unidirectionnel
et à sens unique** : une classe ne pouvait porter qu'un seul passif nommé en dur, et rien ne filtrait
« quels passifs une classe peut prendre » autrement qu'en lisant ce champ à deux endroits distincts
(écran de sélection, tutoriel) — chacun avec sa propre requête sur `registry.passives`.

Séparément, la Maîtrise d'Armure (`EntityStats.armorMastery`) n'avait de sens que pour de l'armure :
une stat nommée sur une seule ressource, alors que P-41 prévoit neuf passifs aux effets disparates
(vol de vie, mana non dépensé, durée de statut…). Le gain de Maîtrise était appliqué **au moment du
gain d'armure**, par une règle spéciale de `StatGains.apply` qui reconnaissait `GainSource.passive`
et n'ajoutait la stat qu'à cette seule source — un couplage entre le point de passage générique des
gains et un concept propre aux passifs.

Enfin, `TraitSystem` exposait trois méthodes (`onTurnStart`, `onTurnEnd`, `onCardPlayed`), chacune
une cascade `if/else` sur l'`effectType` du passif actif — le passif n'était honoré que dans les
triggers que la cascade testait explicitement, indépendamment du `trigger` qu'il déclarait.

### Décision

**D1 — Le passif déclare lui-même les classes qui peuvent le prendre.** `PassiveData.classes`
(`List<String>?`) : absent = ouvert à toutes les classes, une liste = réservé à ces classes,
`[]` refusé au chargement (« réservé à personne » est presque toujours une erreur ; « à tous »
s'écrit en omettant le champ). Les passifs restent **à plat** sous `assets/data/passives/` — ADR-086
D4 sur ce point n'est pas remis en cause, seul le mécanisme de liaison change.

**D2 — Un point d'accès unique remplace les lectures directes de `registry.passives`.**
`availablePassivesFor(HeroData hero, GameDataRegistry registry)` (`lib/game/systems/passive_availability.dart`)
rend les passifs éligibles à une classe, triés par `id` — l'ordre ne dépend pas de l'ordre de lecture
des fichiers. Fonction pure, sans provider, appelable par le jeu comme par le tutoriel (ADR-081).
Elle **ne lit aucun déblocage** : tant que P-13 n'existe pas, « disponible » vaut « éligible ».
Le jour où P-13 filtrera par déblocage, ce sera **dans** cette fonction, sans toucher ses lecteurs
(écran de sélection, tutoriel — les deux seuls aujourd'hui).

**D3 — `HeroData.passiveTrait` et `RunState.passiveTrait` disparaissent, sans remplaçant.** Le lien
partait de la classe ; il part maintenant du passif (D1). `RunState.activePassive`/`activePassiveId`
reste : c'est le passif choisi pour la run en cours, pas un choix à refaire.

**D4 — La Maîtrise devient une stat hybride unique.** `EntityStats.armorMastery` devient `mastery`
(clé JSON `mastery`) ; `effectiveArmorMastery` devient `effectiveMastery`. **Chaque passif déclare
dans son fichier ce qu'un point de Maîtrise lui apporte**, via un bloc `mastery` optionnel :
`field` (le paramètre visé — `value`, seule valeur admise par P-49), `perPoint` (entier non nul,
négatif admis pour un paramètre qui baisse), et deux descriptions bilingues contenant `{amount}`.
`PassiveData.withMastery(int points)` rend une copie du passif avec le paramètre désigné augmenté
de `perPoint × points` — fonction pure, testée seule ; rend le passif tel quel sans `mastery` ou à
0 point.

**D5 — La Maîtrise s'applique au passif, avant la stratégie — jamais au résultat final.**
`TraitSystem.dispatch(RunController, PassiveEvent)` remplace les trois méthodes de trigger : il lit
le passif actif, compare son `trigger` déclaré à celui de l'événement (**c'est ce qui rend le
trigger réellement data-driven** — `gain_armor` suit désormais le `trigger` qu'il déclare, plus
la cascade qui ne le testait qu'à deux endroits), applique `withMastery(heroStats.effectiveMastery)`,
puis délègue à la stratégie de l'`effectType`. Une stratégie reçoit donc le passif **déjà
augmenté** et ne lit jamais la stat elle-même. **`StatGains` perd sa règle spéciale** : un gain
d'armure de source `passive` n'est plus traité différemment des autres, la Maîtrise étant déjà
dans la valeur que la stratégie calcule.

**Conséquence de jeu assumée** : *Armure du Berserker* passe de `tranches × valeur + Maîtrise` à
`tranches × (valeur + Maîtrise)` — un seul mode d'application dans tout le mécanisme, au prix d'un
changement d'échelle pour ce seul passif, annoncé en « Équilibrage » à la note de version. Il dure
jusqu'au lot B de P-41, qui remplace ce passif par *Rage*.

**D6 — Un registre de stratégies par `effectType`, sur le modèle d'ADR-061.** `PassiveStrategies.byEffectType`
(`lib/game/systems/passives/passive_strategies.dart`) est une `Map<String, PassiveStrategy>`
**constante** — une table de code, pas un état — associant `gain_armor`, `berserker_armor` et
`spell_armor` à leur classe (`GainArmorPassive`, `BerserkerArmorPassive`, `SpellArmorPassive`),
chacune implémentant `PassiveStrategy.resolve(PassiveData, PassiveEvent, RunController)`. Un
`effectType` absent de la table **ne fait rien** en jeu — jamais d'exception en plein combat — et
`referential_integrity_test` refuse qu'un passif livré soit dans ce cas. Alternative écartée : des
passifs composés d'effets de carte résolus par `EffectRegistry` (ADR-061) — la moitié des neuf
passifs du lot B (armure survivante en PV, vol de vie croissant…) exigerait un langage de
conditions et de formules en JSON, prématuré ici.

**D7 — Aucune étape de migration de sauvegarde.** Avant la `1.0.0`, une sauvegarde n'a pas à
survivre à un changement de version (décision du propriétaire) : `SaveMigrator.currentVersion`
reste à 2. Une sauvegarde antérieure relit `mastery` à 0 (la Maîtrise accumulée est perdue) et
ignore silencieusement `passiveTrait` ; `activePassiveId` reste lu, le passif actif est retrouvé.

### Preuves dans le code

- `lib/models/data/passive_data.dart` — `PassiveData.classes`, `PassiveMastery`, `.withMastery`,
  refus au chargement de `classes: []` et d'un bloc `mastery` invalide.
- `lib/game/systems/passive_availability.dart` — `availablePassivesFor`, seule fonction qui lit
  `PassiveData.classes`.
- `lib/game/systems/trait_system.dart` — `TraitSystem.dispatch`, seule méthode publique restante.
- `lib/game/systems/passives/passive_strategy.dart`, `passive_strategies.dart` — `PassiveEvent`,
  `PassiveStrategy`, `PassiveStrategies.byEffectType`.
- `lib/models/entity_stats.dart` — `mastery`, `effectiveMastery`.
- `lib/game/systems/stat_gains.dart` — la règle spéciale de Maîtrise sur `GainSource.passive` a
  disparu ; `test/unit/stat_gains_test.dart` verrouille qu'aucune source, `passive` comprise, n'en
  reçoit plus par ce chemin.
- `test/unit/passive_data_test.dart`, `passive_availability_test.dart`, `trait_system_test.dart` —
  les trois mécanismes testés séparément.
- `test/unit/referential_integrity_test.dart` — chaque `classes` désigne une classe existante,
  chaque classe a au moins un passif disponible, chaque `effectType` livré a sa stratégie.
- `lib/game/services/level_up_reward_service.dart`, `lib/ui/widgets/draft/` — récompense
  *Affinité* (`LevelUpRewardType.affinity`, `DraftChoice.masteryBoost`), remplace *Forge d'Acier*.
- Spec complète — [`docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md`](../../docs/superpowers/specs/2026-09-16-p49-passifs-partages-design.md).

### Conséquences

- ✅ **Ajouter un passif partagé entre classes ne demande plus de code.** Un fichier avec
  `"classes": ["paladin", "mage"]` (ou sans le champ, pour toutes) suffit.
- ✅ **La Maîtrise a un sens pour n'importe quel passif futur** : chacun déclare ce qu'un point lui
  apporte, sans neuvième récompense dédiée ni stat spécialisée par ressource.
- ✅ **Le trigger d'un passif est enfin data-driven** : `dispatch` l'honore quel que soit le trigger
  déclaré, sans dépendre d'une cascade qui ne le testait qu'à certains endroits.
- ✅ **P-13 est débranché de tout code futur** : ses deux points d'accroche (`classes`,
  `availablePassivesFor`) sont posés ; le stockage de profil et le filtre de déblocage restent
  entièrement à sa charge, dans cette même fonction.
- ⚠️ **Un seul passif actif par run reste supposé partout** (`RunState.activePassive` singulier) —
  plusieurs passifs actifs, si retenu par P-13, redemande une étape de migration.
- ⚠️ **Le changement d'échelle d'*Armure du Berserker* est un changement de jeu**, pas seulement de
  refactoring — annoncé en note de version, temporaire jusqu'au remplacement du passif au lot B.
- ⚠️ **La Maîtrise accumulée d'une run en cours ne survit pas à la mise à jour** (D7) — acceptable
  avant la `1.0.0`, non testé, non annoncé au joueur en dehors de la note de version.
- ⚠️ **`FieldKind.reference`/`referenceKeys` de l'éditeur n'ont plus de descripteur livré** depuis
  le retrait de `passiveTrait` ; `referenceListKeys`/`FieldKind.referenceList` les remplace pour
  `classes`. Le mécanisme à référence unique reste, vérifié sur un descripteur de test — à retirer
  ou à réutiliser selon ce que P-18/P-42 décident (`docs/ROADMAP.md`).
