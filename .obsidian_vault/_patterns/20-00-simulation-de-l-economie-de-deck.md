## 20. Simulation de l'Économie de Deck (`tool/simulations/`)

> [!IMPORTANT]
> **Une valeur mesurée ne se change pas à la main.** Les valeurs d'économie que le brainstorm v3
> a retenues — ses décisions D56 à D62 et D67 — sortent de ce script. Toute modification de l'une
> d'elles demande de le relancer d'abord (brainstorm §12, ligne 1). Les valeurs de D63, et les
> défauts que le script joue sans qu'une décision les fixe, sont des valeurs de spec : jouées, non
> mesurées — elles se remplacent, en relançant. Et **le script lit `assets/data/` au lancement** :
> le lot qui change un schéma ou un dossier qu'il parse le réaligne dans une tâche de son plan ;
> c'est l'orchestrateur de la vague qui le relance et compare (§20.5).

`tool/simulations/d26_economy_sim.dart` est un programme Dart autonome, de 4 053 lignes
(**vérifié le 2026-10-04**, `wc -l`, sur la branche de la vague 3). Il n'est ni un test, ni un
asset, ni déclaré dans `pubspec.yaml`, et n'importe rien de `lib/` : Flame, donc Flutter, refuse
`dart run`. Il doit rester `dart analyze` propre (`CLAUDE.md`, § Tooling). Son en-tête compte la
courbe d'XP parmi les données relues à chaque lancement.

### 20.1. Ce qu'il fait

Il joue des runs entières de l'économie de deck telle que le brainstorm v3 la décide — trouvaille,
fusion, affûtage, Puits, boutique, XP, niveau, difficulté adaptative — par classe et par lot de
passif, puis fait varier un levier à la fois sur les mêmes graines. Les **formules** du jeu y sont
portées à la main, chacune avec le `fichier:ligne` d'où elle vient ; le combat, lui, est un modèle
abstrait, pas le moteur. Ses résultats, sa méthode et ses limites sont dans son
[rapport](../../docs/possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md) — ils ne sont
pas recopiés ici.

### 20.2. Ce qu'il lit dans `assets/data/`

Re-lu le 2026-10-04, sur la branche de la vague 3, dans le chargeur du script (`GameData.load`,
`d26_economy_sim.dart:755-1013`). Son lecteur de dossier ne descend pas dans les sous-dossiers et
lève une exception sur un dossier absent (`_jsonFiles`, `:408-416`). Il lit par clé : un champ neuf
ne le dérange pas, un champ attendu et absent le fait planter. **Chaque lot de runs relit les
données dans son propre isolate** (`_dataCache`, `:1016-1017` ; `Isolate.run`, `:3503`) : ni
changement de branche ni écriture sous `assets/data/` tant qu'une passe tourne.

| Dossier ou fichier | Champs lus | Ce que ça implique |
|:---|:---|:---|
| `enemies/*/enemy.json` | `id`, `maxHp`, `baseDamage`, `tier`, `xp`, `gold`, `critChance`, `intents` | Un champ renommé casse le chargement |
| `cards/` | chaque fichier, **à plat** | Un sous-dossier de `cards/` n'est pas lu : ses cartes sont **ignorées**. Une carte que le script prend par son identifiant (`lotCards`, `:495` et suivantes) et qui a été déplacée le fait planter |
| `relics/` | `id`, `rarity`, `trigger`, `effectType`, `value` | **Les trois reliques du brainstorm sont des fichiers depuis la vague 3** — *Registre des primes*, *Sacoche du glaneur*, *Meule* — reconnues à leur `effectType` (`brainstormRelicFiles`, `:700-704`), sorties de la liste tirée et construites à la place exacte de leur entrée en dur (`placedRelic`, `:812`, `:1005-1007`). Un autre fichier qui jouerait l'un de ces effets fait planter le script |
| `level_up_rewards/` | chaque récompense, son `effect`, sa `stat`, son pool et ses `values` | La mythique de D42(c), `transcendence.json` (`ceilingRewardId`, `:717`), sort de la liste et prend la place du `null` qui la jouait ; *Sagesse* lit sa valeur `mythic`. Tout autre `effect` est accepté : un fichier neuf allonge la liste tirée, sans erreur |
| `forge_upgrades/` | `id`, `weight`, `eligibleCardTypes` | **Lus dans l'ordre d'une liste explicite de 17 ids** (`runeOrder`, `:896-900`), pas dans celui des fichiers : un fichier de rune dont l'id n'y figure pas fait planter le script, qui demande de lui donner sa place. Une rune qui a son fichier n'a plus d'entrée en dur ; sa condition et ses exclusions restent données par le `switch` (`:920-941`). `minFusionRank`, `maxLevel` et `binary` ne sont pas lus |
| `events/` | chaque événement, les types et valeurs de ses actions (`:949-984`) | **Les événements de D23 et de D42(b) sont des fichiers depuis la vague 3** — le *Colporteur*, le *Rémouleur* —, reconnus au type d'action qu'ils portent (`trade_relic`, `sharpen_rune` ; `brainstormEventFiles`, `:710-713`), sortis de la liste et résolus par le script à la place de leur entrée en dur ; leur fichier absent le fait planter |
| `passives/` | `value`, `duration`, `threshold` et, du bloc `mastery`, `field` et `perPoint` (`:847-858`) | Le `floor` de *Flux* et le `threshold` de *Bénédiction*, en donnée depuis la vague 3, ne sont pas lus : le script joue déjà le plancher 2 (`fluxThreshold`, `:2266`) et la tranche de 5 (`blessingThreshold`, `:2271`) en dur — sortie inchangée |
| `classes/*/class.json` | `maxHp`, `maxMana`, `critChance`, `mastery`, `mightTargets`, et de `statRules` le seul mode `convert` (`:862-889`) | Le taux de conversion est en dur |
| `classes/*/cards/` | les signatures : coût, type, cible, effets de chaque fichier | Le dossier renommé ou absent fait planter le script ; seuls leur recharge (`:871`) et le type d'une d'elles sont en dur |
| `xp_curve.json` | `xpPerLevelByAct` (`:986-995`) | **Depuis la vague 3** : refusé comme le jeu le refuse — une liste non vide d'entiers ≥ 1 ; la référence joue cette table (`:3933`) |

**Les listes se tirent par index.** Reliques (`relicPool`, `:2620-2624`), événements
(`visitEvent`, `:3086-3103`) et récompenses (`levelUp`, `:2751-2782`) le sont dans l'ordre
« fichiers triés par nom, puis entrées du brainstorm » : un fichier de plus se range au milieu des
autres et décale tous les tirages qui suivent — chaque run n'a qu'un générateur (`Random(seed)`,
`:3425`). **Les runes, depuis la vague 2, suivent `runeOrder`**, et **les entrées du brainstorm,
depuis la vague 3, gardent leur place** : leur fichier les remplace là où était leur entrée en dur,
sans rien décaler.

### 20.3. Ce qui est codé en dur

Les lots de cartes par passif — les exemples du brainstorm, complétés par des cartes génériques,
et les cartes survivantes prises par identifiant (`lotCards`, `:495` et suivantes) ; la condition
et les exclusions des runes à fichier, redonnées par un `switch` (`:920-941`), et les six runes du
brainstorm qui n'ont pas encore de fichier (`hardRunes`, `:902-909`) ; la recharge des signatures
(`:871`) ; le taux de conversion du Berserker, les plafonds de niveau des runes, la tranche de
*Bénédiction* et le plancher de *Flux*. Le coefficient de la difficulté adaptative vaut 2 par
défaut (`ddaK`, `:91`), la valeur que le brainstorm a retenue — `2 × Σ fusionRank`, que le jeu
joue depuis la vague 3 ; la variante qui rejoue la formule d'avant E3 (`cartes × 2`) s'appelle
« d'avant E3 » dans la sortie. **Le `spectral` du script suit D33 depuis la vague 2** (`bff3078`) —
comme le jeu ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md)).

**Retirés à la vague 3** ([ADR-107](../_adr/ADR-107-trouvaille-et-progression.md), A28) : la
relique B de D31, que D57 supprime (`8c558bc`), et l'événement de fusion de D29, que D56 renvoie à
P-16 (`2acfa6c`). **Aucune relique, aucun événement ni aucune récompense du brainstorm ne reste en
dur** : les six entrées que la vague 3 a écrites en fichiers y sont relues (§20.2).

**La table d'XP est lue, et la calibration reste affichée** (vague 3, `d8b2aef`). La référence joue
`xp_curve.json` ; la table que la mesure recale à chaque lancement s'imprime à côté, dans la
calibration de la sortie (`:3971-3979`) — une ligne « Table par acte (réf., `xp_curve.json`) »,
une ligne « Table par acte, calée » —, pour voir de combien la donnée du jeu s'écarte du calage. Au
recommit de la vague 3, quelques dizaines d'XP par acte : le palier du jeu donne toujours deux
niveaux par acte.

Tant que les lots réels n'existent pas, le classement des lots que le script produit dépend de ces
cartes génériques, pas seulement des passifs.

### 20.4. Le lancer

```
dart run tool/simulations/d26_economy_sim.dart --out <fichier>
dart run tool/simulations/d26_economy_sim.dart --quick --out <fichier>
```

La graine est fixée (`seedBase`, `:3472`) et les fichiers sont lus triés : deux passes donnent la
même sortie. La passe complète a pris 422 secondes le 2026-10-01, 467 et 406 secondes aux deux
relances de la vague 2, de 381 à 415 secondes aux quatre de la vague 3 — à lancer en
arrière-plan ; `--quick` joue 25 runs par configuration, en une minute environ : une fumée, pas une
mesure. La sortie ne s'écrit qu'à la toute fin (`:4046-4049`) : supprimer le fichier de sortie
avant de lancer, et attendre la ligne `écrit : <chemin>`. La vague 3 a lancé chaque mesure sur
une **extraction hors du dépôt** du commit mesuré (`git archive <commit> tool/simulations
assets/data`) — ce qui laisse travailler la branche pendant la passe.

### 20.5. Quand le relancer

Avant de changer une valeur qu'il a mesurée ; et dans tout lot qui touche ce qu'il lit (§20.2) ou
ce qu'il code en dur (§20.3).

**La relance se compare à une sortie de référence, pas au rapport.**
`tool/simulations/d26_reference_output.md` est la sortie complète du script, suivie par git — 788
lignes (**vérifié le 2026-10-04**, `wc -l`, sur la branche de la vague 3). Produite le 2026-10-01,
recommitée le 2026-10-02 (`cba147c`) sur le second temps de la vague 2, elle l'est de nouveau sur
la branche de la vague 3 (`11410f3`, sur la sortie de `d8b2aef`) : la vague 4 se comparera à elle.
Son attribut `eol=lf` (`.gitattributes`) l'empêche d'être convertie à l'extraction. La comparaison
se fait **en deux temps**
([ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md), D5) :

1. **Le réalignement seul** — aucune valeur en dur ne change, chaque fichier neuf prend la place
   exacte de son entrée en dur : `git diff --no-index` est **entièrement vide**. La ligne
   « Données lues » de la sortie (`:3964-3968`) compte les listes que le script a chargées — les
   fichiers retenus, plus des littéraux « (+ 3 du brainstorm) », « (+ 2 du brainstorm) » —, pas
   les fichiers : un réalignement la laisse inchangée. Vague 2 (`9f1f203`) et vague 3 (`ca0ba2f`) :
   diff vide.
2. **Chaque changement voulu** — une valeur jouée remplacée, une entrée retirée — relancé à
   part : l'écart est attribué, et la référence recommitée. Un retrait d'une liste tirée par index
   décale tous les tirages qui suivent : l'écart touche presque toutes les lignes, mais les
   grandeurs que les décisions supposent restent dans le bruit. La vague 2 l'a fait une fois — le
   `spectral` aligné sur D33, 477 lignes sur 798 ; la vague 3 trois fois — la relique B (497 lignes
   sur 798), l'événement de D29 (498 sur 797), la table d'XP du jeu (479 sur 787) —, chaque écart
   expliqué au compte rendu de sa vague
   ([vague 2](../../docs/superpowers/reports/2026-10-02-economie-et-catalogue-vague-2-compte-rendu.md),
   [vague 3](../../docs/superpowers/reports/2026-10-04-economie-et-catalogue-vague-3-compte-rendu.md),
   §4 chacun). **Un écart de libellé dit d'avance** n'est pas un écart de valeur : à la troisième
   relance de la vague 3, les libellés qui appelaient « actuelle » la formule d'avant E3 disent
   « d'avant E3 », et la calibration gagne sa ligne neuve.

Un écart inexpliqué arrête le lot. Le diff vide est un test de non-régression du script, pas une
validation des données. Le rapport, lui, porte deux passes à deux réglages de la difficulté
adaptative : il se lit, il ne se compare pas. Le détail, vague par vague, est tenu dans le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§3.6 et §7.3.

### 20.6. Ce qu'il ne dit pas

Il ne dit pas si le héros survit, ni ce que vaut une carte réelle : voir son rapport, §5. Ses
constats sur la survie, l'or et la boucle d'XP sont portés sur la ligne de P-16 dans
`docs/ROADMAP.md` — l'or qui dort à l'acte 15 a encore monté à la vague 3, de 5 900 à 6 023 en
médiane (compte rendu de la vague 3, §4).

> [!NOTE]
> **Plus rien de ce que le brainstorm a retiré du programme ne se joue** : la relique B et
> l'événement de fusion de D29 ont quitté le script à la vague 3, chacun par sa relance. L'en-tête
> du fichier ne se dit plus « script jetable … ni committé » depuis la vague 2 (`9f1f203`).
