## 20. Simulation de l'Économie de Deck (`tool/simulations/`)

> [!IMPORTANT]
> **Une valeur mesurée ne se change pas à la main.** Les valeurs d'économie que le brainstorm v3
> a retenues — ses décisions D56 à D63 et D67 — sortent de ce script. Toute modification de l'une
> d'elles demande de le relancer d'abord (brainstorm §12, ligne 1). Et **le script lit
> `assets/data/` au lancement** : le lot qui change un schéma ou un dossier qu'il parse le
> réaligne et le relance dans le même plan.

`tool/simulations/d26_economy_sim.dart` est un programme Dart autonome, de 3 925 lignes
(**vérifié le 2026-10-01**, `wc -l`). Il n'est ni un test, ni un asset, ni déclaré dans
`pubspec.yaml`, et n'importe rien de `lib/` : Flame, donc Flutter, refuse `dart run`. Il doit
rester `dart analyze` propre (`CLAUDE.md`, § Tooling).

### 20.1. Ce qu'il fait

Il joue des runes entières de l'économie de deck telle que le brainstorm v3 la décide — trouvaille,
fusion, affûtage, Puits, boutique, XP, niveau, difficulté adaptative — par classe et par lot de
passif, puis fait varier un levier à la fois sur les mêmes graines. Les **formules** du jeu y sont
portées à la main, chacune avec le `fichier:ligne` d'où elle vient ; le combat, lui, est un modèle
abstrait, pas le moteur. Ses résultats, sa méthode et ses limites sont dans son
[rapport](../../docs/possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md) — ils ne sont
pas recopiés ici.

### 20.2. Ce qu'il lit dans `assets/data/`

Lu le 2026-10-01 dans le chargeur du script (`d26_economy_sim.dart:723-845`, `:2115`).

| Dossier | Champs lus | Ce que ça implique |
|:---|:---|:---|
| `enemies/*/enemy.json` | `id`, `maxHp`, `baseDamage`, `tier`, `xp`, `gold`, `critChance`, `intents` | Un champ renommé casse le chargement |
| `cards/` | chaque fichier, **à plat** | Un sous-dossier de `cards/` n'est pas vu comme un lot : ses cartes sont prises pour des neutres, ou ignorées |
| `relics/` | `id`, `rarity`, `trigger`, `effectType`, `value` | — |
| `level_up_rewards/` | chaque récompense et son pool | Un `effect` nouveau peut être refusé |
| `forge_upgrades/` | `id`, `weight`, `eligibleCardTypes` | `pools` n'est pas lu ; un fichier de rune neuf est pris par le cas par défaut |
| `passives/` | le bloc `mastery` | — |
| `classes/*/class.json` | `statRules` | Le chemin des signatures n'est pas lu : elles sont codées en dur |

### 20.3. Ce qui est codé en dur

Les lots de cartes par passif — les exemples du brainstorm, complétés par des cartes génériques —,
les runes que le brainstorm ajoute, et les six signatures : un `switch` par identifiant
(`d26_economy_sim.dart:825-845` pour les runes). Le coefficient de la difficulté adaptative vaut 2
par défaut (`:91`, `ddaK`), la valeur que le brainstorm a retenue.

Tant que les lots réels n'existent pas, le classement des lots que le script produit dépend de ces
cartes génériques, pas seulement des passifs.

### 20.4. Le lancer

```
dart run tool/simulations/d26_economy_sim.dart --out <fichier>
```

La graine est fixée : deux passes donnent la même sortie. Son rapport annonce de l'ordre de dix
minutes par passe — à lancer en arrière-plan.

### 20.5. Quand le relancer

Avant de changer une valeur qu'il a mesurée ; et dans tout lot qui touche ce qu'il lit (§20.2) ou
ce qu'il code en dur (§20.3). À valeurs inchangées, une relance doit retrouver les chiffres du
rapport : c'est alors un test de non-régression, et un écart arrête le lot. Le détail, vague par
vague, est tenu dans le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§7.3.

### 20.6. Ce qu'il ne dit pas

Il ne dit pas si le héros survit, ni ce que vaut une carte réelle : voir son rapport, §5. Ses
constats sur la survie, l'or et la boucle d'XP sont portés sur la ligne de P-16 dans
`docs/ROADMAP.md`.

> [!NOTE]
> **L'en-tête du fichier se dit encore « script jetable … ni committé ».** C'est périmé depuis le
> 2026-09-30 : le script est suivi par git et `CLAUDE.md` le décrit comme un outil durable. À
> corriger par le premier lot qui le modifie — cette fiche ne touche pas au code.
