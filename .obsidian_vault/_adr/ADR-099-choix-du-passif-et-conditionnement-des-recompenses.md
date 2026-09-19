## 🎯 ADR-099 : Le Choix du Passif à la Sélection, et le Conditionnement des Récompenses par la Donnée (P-41, lot C, partie 2)

### Statut

✅ Accepté — chantier **P-41, lot C, partie 2**, fusionné dans `main` par la **PR #43**
(2026-09-20, merge `2f850c4`, `2d167fa`..`0db8d4e`, 20 commits de code).

**Clôt le lot C**, et étend [ADR-098](ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md)
d'un champ `requires` sur le modèle qu'il a créé. Consomme le point d'accès unique posé par
[ADR-096](ADR-096-passifs-partages-eligibilite-et-maitrise-hybride.md) et rend atteignables les
neuf passifs livrés par [ADR-097](ADR-097-puissance-unique-orientee-par-la-classe.md).
Applique la règle d'[ADR-090](ADR-090-identite-visuelle-de-classe-portee-par-la-donnee.md) :
aucun écran ne compare un `hero.id`.

### Contexte

Deux mensonges cohabitaient à l'écran le plus structurant de la run.

**Le premier : six passifs sur neuf étaient inatteignables.** Le lot B a livré trois passifs par
classe et P-49 le point d'accès `availablePassivesFor()` qui les rend tous — mais l'écran de
sélection n'affichait que `passives.first`. Le point d'accès calculait une liste dont l'écran
jetait les deux tiers, et la note `0.5.2` avait promis au joueur l'écran de choix.

**Le second : `baseDamage`.** L'écran annonçait 5, 15 et 10 dégâts de base selon la classe, quand
toute run démarre à `might: 0` (`run_controller.dart:266`). Le chiffre n'avait aucun lecteur en
combat côté héros : il décorait un badge et rien d'autre.

S'y ajoutait une récompense inerte en puissance : *Affinité* rend de la Maîtrise, qui ne renforce
que ce que produit le passif actif. Un passif sans bloc `mastery` la rendrait sans effet, et le
tirage n'avait aucun moyen de le savoir.

### Décision

1. **Le conditionnement est un mécanisme, pas une propriété d'*Affinité*.** Un champ
   `requires` sur `LevelUpRewardData`, adossé à `enum RewardRequirement`, et un prédicat
   `isAvailableWith(PassiveData?)`. `generateChoices` filtre la liste avant de tirer.
   `affinity.json` déclare `"requires": "passiveMastery"` ; les sept autres récompenses ne
   déclarent rien. Un `if (reward.id == 'affinity')` aurait reconstruit, deux semaines après,
   le code en dur qu'ADR-098 venait de supprimer.

2. **Un passif absent compte comme « ne déclare pas de Maîtrise ».** Le prédicat est
   `passive?.mastery != null` : sans passif actif, *Affinité* n'est pas tirée. La récompense
   serait tout aussi inerte, et le cas est indiscernable du premier du point de vue du joueur.

3. **Le filtre lit `RunState.activePassive`, et non `availablePassivesFor()`.** La spec §8.2
   renvoyait au point d'accès de P-49 parce que sa conception d'origine tirait neuf récompenses
   dédiées, une par passif : il fallait alors savoir lesquels la classe pouvait prendre. Avec la
   récompense unique *Affinité*, la question n'est plus « lesquels sont disponibles » mais
   « celui qui est actif déclare-t-il une Maîtrise », et la réponse n'est que dans l'état de la
   run. Passer par le point d'accès lirait une liste dont aucun élément n'est celui qui compte.

4. **Le choix du passif ouvre le point d'accès, sans le borner.** L'écran affiche **tous** les
   passifs que `availablePassivesFor()` rend, dans leur ordre, et non les trois d'aujourd'hui :
   trois est un compte, pas une règle, et P-13 le fera varier par les déblocages. Un `take(3)`
   l'aurait trahi silencieusement. Le passif retenu part avec la run via
   `StarterDeckDraftScreen(passive:)`.

5. **Les trois textes de la carte de classe sont générés depuis la donnée**, dans
   `model_extensions.dart`, à côté de la forme courte écrite au lot B : `MightTargetsLabels`
   gagne `longLabel` et `sentence`, `StatRuleLabel` gagne `describe`. Les deux reposent sur des
   `switch` exhaustifs, que l'analyseur fait rougir si une valeur d'énumération arrive sans son
   libellé. La durée d'une règle passe par un **pluriel ICU** dans l'ARB — le premier du projet —
   parce que c'est la seule forme qui reste juste si une règle future dure trois tours.

6. **`baseDamage` quitte `HeroData` et les trois `class.json`.** Il reste sur `EnemyData`, où il
   a trois lecteurs réels. `sword_icon.dart` part avec lui, sans autre usage. L'écran montre à la
   place les PV et le mana **toujours**, et `mastery`, `critChance`, `luck` **seulement si > 0** :
   elles valent 0 pour au moins une classe, et n'ont rien à dire quand elles valent 0.

7. **La carte de classe se dimensionne à son contenu.** Elle porte désormais une phrase
   d'orientation, une éventuelle règle de stat et un bloc de passifs dépliant : une hauteur
   déduite de la largeur (`childAspectRatio`) ne pouvait plus tenir. Le mobile passe en
   `ListView.separated` à une colonne, le desktop en rangées à hauteur intrinsèque.

### Preuves dans le code

- `lib/models/data/level_up_reward_data.dart:36` — `enum RewardRequirement` ; `:93` le champ
  `requires` ; `:165-167` `isAvailableWith`, `passive?.mastery != null`.
- `lib/game/services/level_up_reward_service.dart:89-100` — `generateChoices({… PassiveData?
  activePassive})` filtre par `isAvailableWith` avant de tirer.
- `assets/data/level_up_rewards/affinity.json` — `"requires": "passiveMastery"`, seule des huit
  récompenses à déclarer le champ.
- `lib/models/data/model_extensions.dart:114-152` — `MightTargetsLabels.longLabel` / `.sentence` ;
  `:154-166` `StatRuleLabel.describe`, `switch` sur `(stat, mode, to)`.
- `lib/ui/screens/class_selection_screen.dart:377` — `availablePassivesFor(playerClass, gameData)`,
  seul appelant d'écran ; `:389-431` les cinq badges, trois sous condition `> 0`.
- `lib/ui/widgets/class_passive_list.dart` — le bloc dépliant, 307 lignes ; replié, il montre le
  passif retenu **en entier**, pour que les trois classes se comparent sans rien ouvrir.
- `lib/models/data/hero_data.dart` — aucune occurrence de `baseDamage` ; `lib/ui/widgets/sword_icon.dart`
  n'existe plus. Les huit fichiers de `lib/` qui nomment encore `baseDamage` sont tous du côté ennemi
  ou de l'éditeur.
- `test/unit/level_up_reward_requirement_test.dart`, `test/unit/stat_rule_label_test.dart`,
  `test/unit/might_targets_long_label_test.dart` — les trois suites neuves.

### Conséquences

**Acquises.**

- Les **neuf passifs sont atteignables**, et le point d'accès de P-49 a enfin un lecteur qui
  consomme toute sa liste. C'est le dernier verrou qui manquait à la méta-progression : P-13
  branchera l'état de déblocage derrière `availablePassivesFor()` sans toucher à l'écran.
- L'écran de sélection dit **ce qui sépare réellement les classes**, et ne dit plus de chiffre
  que la run ne reprend pas.
- Un futur passif sans `mastery` ne rendra plus une récompense sur six inerte.

**Assumées.**

- **La table de tirage effective passe de 6 à 5 types** pour un passif sans Maîtrise. Les neuf
  passifs livrés en déclarent tous une : **aucune run réelle n'est concernée aujourd'hui**. Le
  filtre est livré, testé sur un passif construit sans bloc `mastery`, et attend le premier passif
  qui n'en déclarera pas.
- Le gabarit `fallbackDescription` d'`affinity.json` devient **inatteignable par le tirage normal**.
  Il reste comme filet de rendu : un `DraftChoice` construit hors tirage ne doit jamais laisser
  fuir un `{passive}` à l'écran, ce qu'un test de la partie 1 vérifie sur les huit récompenses.
- **Le tutoriel garde son étape de choix de classe telle quelle** : elle ne propose pas encore les
  passifs disponibles, et `tutorial_fixtures.dart:58` suppose toujours un passif unique
  (`availablePassivesFor(...).first`). C'est le **lot D** (spec §9.1). Ce lot ne lui a passé que le
  passif actif au tirage, pour que le filtre y vaille aussi — ADR-081 intact.
- **L'éditeur de contenu n'apprend pas `statRules`** : sa validation est au lot D (spec §9.2). Ce
  lot n'y a retiré que `baseDamage`, devenu une clé obligatoire vers un champ disparu.
- `class_selection_screen.dart` atteint **857 lignes**. Le bloc des passifs en est déjà sorti
  (`class_passive_list.dart`) ; le reste est un candidat à la découpe si le lot D y revient.
