## 20. Simulation de l'Économie de Deck (`tool/simulations/`)

> [!IMPORTANT]
> **Une valeur mesurée ne se change pas à la main.** Les valeurs d'économie que le brainstorm v3
> a retenues — ses décisions D56 à D62 et D67 — sortent de ce script. Toute modification de l'une
> d'elles demande de le relancer d'abord (brainstorm §12, ligne 1). Les valeurs de D63, et les
> défauts que le script joue sans qu'une décision les fixe, sont des valeurs de spec : jouées, non
> mesurées — elles se remplacent, en relançant. Et **le script lit `assets/data/` au lancement** :
> le lot qui change un schéma ou un dossier qu'il parse le réaligne dans une tâche de son plan ;
> c'est l'orchestrateur de la vague qui le relance et compare (§20.5).

`tool/simulations/d26_economy_sim.dart` est un programme Dart autonome, de 3 925 lignes
(**vérifié le 2026-10-01**, `wc -l`). Il n'est ni un test, ni un asset, ni déclaré dans
`pubspec.yaml`, et n'importe rien de `lib/` : Flame, donc Flutter, refuse `dart run`. Il doit
rester `dart analyze` propre (`CLAUDE.md`, § Tooling).

### 20.1. Ce qu'il fait

Il joue des runs entières de l'économie de deck telle que le brainstorm v3 la décide — trouvaille,
fusion, affûtage, Puits, boutique, XP, niveau, difficulté adaptative — par classe et par lot de
passif, puis fait varier un levier à la fois sur les mêmes graines. Les **formules** du jeu y sont
portées à la main, chacune avec le `fichier:ligne` d'où elle vient ; le combat, lui, est un modèle
abstrait, pas le moteur. Ses résultats, sa méthode et ses limites sont dans son
[rapport](../../docs/possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md) — ils ne sont
pas recopiés ici.

### 20.2. Ce qu'il lit dans `assets/data/`

Lu le 2026-10-01 dans le chargeur du script (`GameData.load`, `d26_economy_sim.dart:722-877` ; `:2115`).
Son lecteur de dossier ne descend pas dans les sous-dossiers et lève une exception sur un dossier
absent (`_jsonFiles`, `:413-421`). Il lit par clé : un champ neuf ne le dérange pas, un champ
attendu et absent le fait planter. **Chaque lot de runs relit les données dans son propre
isolate** (`:880-881`, `:3376`) : ni changement de branche ni écriture sous `assets/data/` tant
qu'une passe tourne.

| Dossier | Champs lus | Ce que ça implique |
|:---|:---|:---|
| `enemies/*/enemy.json` | `id`, `maxHp`, `baseDamage`, `tier`, `xp`, `gold`, `critChance`, `intents` | Un champ renommé casse le chargement |
| `cards/` | chaque fichier, **à plat** | Un sous-dossier de `cards/` n'est pas lu : ses cartes sont **ignorées**. Une carte que le script prend par son identifiant et qui a été déplacée le fait planter (`:501`) |
| `relics/` | `id`, `rarity`, `trigger`, `effectType`, `value` | — |
| `level_up_rewards/` | chaque récompense, son pool et ses `values` | Tout `effect` est accepté : un fichier neuf allonge la liste tirée, sans erreur |
| `forge_upgrades/` | `id`, `weight`, `eligibleCardTypes` | `pools` n'est pas lu ; un fichier de rune neuf est pris par le cas par défaut, **en plus** de sa définition en dur — doublon |
| `events/` | chaque événement (`:861-873`) | Trois événements du brainstorm s'y ajoutent en dur |
| `passives/` | `value`, `duration`, `threshold` et le bloc `mastery` (`:779-791`) | La tranche de Bénédiction et le plancher de Flux sont en dur |
| `classes/*/class.json` | `maxHp`, `maxMana`, `critChance`, `mastery`, `mightTargets`, et de `statRules` le seul mode `convert` (`:808-816`) | Le taux de conversion est en dur |
| `classes/*/cards/` | les signatures : coût, type, cible, effets de chaque fichier (`:797-807`) | Le dossier renommé ou absent fait planter le script ; seuls leur recharge et le type d'une d'elles sont en dur |

**Les listes se tirent par index**, dans l'ordre « fichiers triés par nom, puis entrées en dur » :
runes, reliques (`:2517-2522`), événements (`:2940-2947`), récompenses (`:2602-2626`). Un fichier
de plus se range au milieu des autres et décale tous les tirages qui suivent — chaque run n'a
qu'un générateur (`:3298`).

### 20.3. Ce qui est codé en dur

Les lots de cartes par passif — les exemples du brainstorm, complétés par des cartes génériques,
et les cartes survivantes prises par identifiant (`lotCards`, `:500` et suivantes) ; cinq des
runes d'aujourd'hui, redéfinies par un `switch` (`:830-846`), et les runes que le brainstorm
ajoute (`:848-859`) ; trois événements (`:2940-2945`), quatre reliques (`:693-696`) et une
récompense de niveau du brainstorm (`:2609-2615`) ; la recharge des signatures (`:803`) ; le taux
de conversion du Berserker et les plafonds de niveau des runes. Le coefficient de la difficulté
adaptative vaut 2 par défaut (`:91`, `ddaK`), la valeur que le brainstorm a retenue.

**La table d'XP n'est ni lue ni en dur : elle est recalée à chaque lancement** (`:3801-3806`).
Elle égale aujourd'hui celle que le brainstorm a retenue ; dès qu'une donnée change, le script en
joue une autre. Le lot qui écrit la table dans la donnée du jeu la lui fait lire.

Tant que les lots réels n'existent pas, le classement des lots que le script produit dépend de ces
cartes génériques, pas seulement des passifs.

### 20.4. Le lancer

```
dart run tool/simulations/d26_economy_sim.dart --out <fichier>
dart run tool/simulations/d26_economy_sim.dart --quick --out <fichier>
```

La graine est fixée (`seedBase`, `:3345`) et les fichiers sont lus triés : deux passes donnent la
même sortie. La passe complète a pris 422 secondes le 2026-10-01, puis 462 le même jour avec la
suite de tests lancée à côté — à lancer en arrière-plan ; `--quick` joue 25 runs par
configuration, en une minute environ : une fumée, pas une mesure. La sortie ne s'écrit qu'à la
toute fin (`:3919-3921`) : supprimer le fichier de sortie avant de lancer, et attendre la ligne
`écrit : <chemin>`.

### 20.5. Quand le relancer

Avant de changer une valeur qu'il a mesurée ; et dans tout lot qui touche ce qu'il lit (§20.2) ou
ce qu'il code en dur (§20.3).

**La relance se compare à une sortie de référence, pas au rapport.**
`tool/simulations/d26_reference_output.md` est la sortie complète du script, suivie par git — 798
lignes, produite le 2026-10-01 (**vérifié le 2026-10-01**, `wc -l`), et retrouvée octet pour
octet par une seconde passe le même jour (`sha256sum`). Son attribut `eol=lf` (`.gitattributes`)
l'empêche d'être convertie à l'extraction. La comparaison se fait **en deux temps**
([ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md), D5) :

1. **Le réalignement seul** — aucune valeur en dur ne change, chaque fichier neuf prend la place
   exacte de son entrée en dur : `git diff --no-index` est vide, hors la ligne « Données lues » de
   la sortie, qui compte les fichiers (`:3837-3841`).
2. **Chaque changement voulu** — une valeur jouée remplacée, une entrée retirée — relancé à
   part : l'écart est attribué, et la référence recommitée.

Un écart inexpliqué arrête le lot. Le diff vide est un test de non-régression du script, pas une
validation des données. Le rapport, lui, porte deux passes à deux réglages de la difficulté
adaptative : il se lit, il ne se compare pas. Le détail, vague par vague, est tenu dans le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§3.6 et §7.3.

### 20.6. Ce qu'il ne dit pas

Il ne dit pas si le héros survit, ni ce que vaut une carte réelle : voir son rapport, §5. Ses
constats sur la survie, l'or et la boucle d'XP sont portés sur la ligne de P-16 dans
`docs/ROADMAP.md`.

> [!NOTE]
> **L'en-tête du fichier se dit encore « script jetable … ni committé ».** C'est périmé depuis le
> 2026-09-30 : le script est suivi par git et `CLAUDE.md` le décrit comme un outil durable. À
> corriger par le premier lot qui le modifie — cette fiche ne touche pas au code. De même, il joue
> encore une relique et un événement que le brainstorm a depuis retirés du programme : le lot qui
> les en sort explique l'écart et recommite la référence.
