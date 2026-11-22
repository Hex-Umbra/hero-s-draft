# Chantier — le bestiaire, de `0.6.1` à `0.7.0`, vague par vague

> **Statut** : programme écrit le 22/11/2026 avec le propriétaire (décisions B45 à B52 et B59 du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1.5). Les vagues 2 à 7 ont leur fiche ; la vague 8, les boss, n'en a pas encore.
>
> **Ce répertoire fait foi pour le déroulé du chantier** : l'ordre des vagues, ce que chacune livre, sa version, son état. **Les décisions de conception n'y sont pas** : leur source de vérité est le cadrage, §1 (B1 à B59). Ce répertoire les cite sans les recopier ; en cas d'écart, le cadrage a raison sur le *quoi*, ce répertoire sur le *comment* et le *quand*.
>
> **La méthode** est celle du chantier précédent — [ADR-102](../../.obsidian_vault/_adr/), ADR-103, [ADR-108](../../.obsidian_vault/_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md), ADR-113 et les amendements d'[ADR-120](../../.obsidian_vault/_adr/ADR-120-ce-que-le-chantier-economie-et-catalogue-legue-a-la-methode.md) D1 — avec le cycle, les gabarits, l'arbre de décision et les garde-fous du [fichier d'orchestration](../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) §3 à §6. **Son journal et ses fiches sont remplacés par ceux de ce répertoire** ; partout où il dit « le brainstorm v3 » et « D1 à D76 », lire « le cadrage » et « B1 à B59 ». Autonomie `strict` par défaut. R31 (pas de spec séparée) ne s'applique pas, sauf si une fiche le dit.

| Fichier | Ce qu'il tient |
|:---|:---|
| Ce `README.md` | Les vagues, l'ordre, les états transitoires, le journal, le prompt de lancement |
| [`catalogue_mecanismes.md`](catalogue_mecanismes.md) | Tout ce qu'un ennemi peut savoir faire, et la vague qui le construit — ou « au catalogue » |
| [`vague_2_tier_1.md`](vague_2_tier_1.md) · [`vague_3_tier_2.md`](vague_3_tier_2.md) · [`vague_4_tier_3.md`](vague_4_tier_3.md) · [`vague_5_tier_4.md`](vague_5_tier_4.md) · [`vague_6_tier_5.md`](vague_6_tier_5.md) · [`vague_7_visuel.md`](vague_7_visuel.md) | Une fiche par vague : ses prérequis, ce qu'elle livre, ce que sa spec doit fixer |

---

## 0. Pour la session qui ouvre ce répertoire

**Tu es l'orchestrateur d'une vague. Une session, une vague, un orchestrateur.**

1. Lis `CLAUDE.md`, ce fichier en entier, le cadrage en entier, le catalogue, puis la fiche de ta vague.
2. **Trouve ta vague** comme le fichier d'orchestration §0.2 le dit, avec les motifs `'*feat/v0.6.*' '*feat/v0.7.*'` : sans branche de vague non fusionnée, ta vague est la première ligne du journal (§4) à l'état « à faire » ; une branche existante est une reprise ou une correction.
3. **Vérifie ses prérequis** (la section « Prérequis » de sa fiche) : les sprites validés, les questions du propriétaire répondues. **Un prérequis manquant arrête la session avant la branche** : dis lequel, n'écris rien.
4. Passe la porte d'entrée (orchestration §3.1, plus celle de la fiche), déroule le cycle (§3) en déléguant (§4), arbitre selon §5, respecte §6, arrête-toi à la porte de sortie (§3.9).

**Le prompt qui lance une vague** — le même pour toutes, à coller dans une session neuve :

````
Tu travailles dans le dépôt Hero's Draft (Flutter, Flame, Riverpod, 100 % data-driven). Lis `CLAUDE.md` d'abord, puis `docs/chantier_bestiaire/README.md` en entier : ce répertoire fait foi pour le déroulé du bestiaire, le cadrage qu'il cite pour ses décisions. Tu es l'orchestrateur d'une vague : trouve laquelle comme son §0 le dit, vérifie ses prérequis, puis déroule son cycle en orchestrant des sous-agents — la délégation est demandée, y compris par un workflow si tu en as l'outil —, arbitre seul selon le §5 du fichier d'orchestration, respecte ses garde-fous (§6) et arrête-toi à la porte de sortie. Réponds et écris en français.
````

La session de correction garde le prompt de l'orchestration §3.10, en remplaçant le chemin du fichier d'orchestration par celui de ce `README.md`.

---

## 1. Les vagues et les versions

| Vague | Version | Ce qu'elle livre | Ce que le joueur voit | Branche | Fiche |
|:---:|:---|:---|:---|:---|:---|
| **1** | **`0.6.1`** | L'interface des ennemis | Le panneau des intentions, la barre de PV et son voile, la fiche de l'ennemi, les languettes | `feat/v0.6.1-interface-des-ennemis` | [cadrage §4.2](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md) |
| **2** | **`0.6.2`** | **Le tier 1** : le langage des intentions (B1), les mécanismes du tier 1, sept ennemis neufs, le Gobelin qui vole | Des ennemis de début de partie qui empoisonnent, gèlent, brûlent, volent, esquivent, se soignent en mordant, et des rats qui viennent par deux | `feat/v0.6.2-bestiaire-tier-1` | [vague 2](vague_2_tier_1.md) |
| **3** | **`0.6.3`** | **Le tier 2** : la meute du Rat alpha, l'invocation, l'aura, le perce-armure, plusieurs coups | Un chef de meute qui appelle ses rats, des ennemis qui se renforcent entre eux et qui rongent l'armure | `feat/v0.6.3-bestiaire-tier-2` | [vague 3](vague_3_tier_2.md) |
| **4** | **`0.6.4`** | **Le tier 3** : les phases, le choix d'intention | Des ennemis qui changent de comportement quand ils faiblissent, et dont on ne devine plus tout le cycle | `feat/v0.6.4-bestiaire-tier-3` | [vague 4](vague_4_tier_3.md) |
| **5** | **`0.6.5`** | **Le tier 4** : l'ouverture du tier, le soutien | Des élémentaires, un chevalier que l'armure n'arrête pas, un chaman qui soigne ses alliés | `feat/v0.6.5-bestiaire-tier-4` | [vague 5](vague_5_tier_4.md) |
| **6** | **`0.6.6`** | **Le tier 5** : les dégâts différés | Des quasi-boss : une marque qui frappe plus tard, un dragon qui enrage | `feat/v0.6.6-bestiaire-tier-5` | [vague 6](vague_6_tier_5.md) |
| **7** | **`0.6.7`** | **Le visuel** : le cadre de tier, les fonds de fenêtre, le décor de combat | Chaque ennemi dans un cadre qui dit son tier, sur un fond, dans une salle redessinée | `feat/v0.6.7-cadres-et-decors` | [vague 7](vague_7_visuel.md) |
| **8** | **`0.7.0`** | **Le tier boss** (B47) | De vrais boss | à fixer | **à écrire** |

**Après `0.7.0`** : ce que le catalogue garde sans vague.

**Dans une vague, tout se déroule en série** : la spec ou le plan suivant s'écrit sur le code que le précédent a laissé sur la branche (orchestration §1).

---

## 2. Pourquoi cet ordre

- **Un tier par vague, et ses seuls mécanismes** (B45, B46). Chaque vague construit ce dont ses ennemis se servent, les branche, et le propriétaire les teste en jeu sur ces ennemis-là. Un mécanisme sans ennemi reste au catalogue : rien ne se construit qui ne se voie pas.
- **B1 d'abord, dans la vague 2** : tout effet d'ennemi s'écrit dans ce langage, et rien ne migre deux fois (B42).
- **Le tier 2 avant le tier 3** : le Nécromancien du tier 3 invoque avec le mécanisme de la meute, et le Chevalier déchu perce l'armure avec celui du Voleur des cryptes.
- **Le tier 3 avant le tier 5 et les boss** : les phases, que l'Ogre étrenne, servent la rage du Dragon juvénile et sont le socle d'un boss (P-09).
- **Les cinq tiers avant le visuel** (B59) : le cadre se pose une fois sur tout le bestiaire des tiers 1 à 5, dessiné entre-temps.
- **Le visuel avant les boss** : les boss arrivent directement dans leur cadre.
- **Les ennemis d'aujourd'hui évoluent en chemin** (B48) : le Gobelin au tier 1, le Squelette au tier 2, l'Orc au tier 3. Aucune vague ne leur est consacrée.

---

## 3. Les états transitoires

| Frontière | État transitoire | Réglé par |
|:---|:---|:---|
| `0.6.2` → `0.6.6` | Les sprites neufs (128 × 192, détourés) s'affichent dans la carte d'aujourd'hui, sans cadre de tier ni fond de fenêtre ; à côté d'eux, ce qui garde encore un ancien sprite | La vague 7. Chaque fiche dit quels anciens sprites sa vague remplace |
| `0.6.2` | Le Rat existe seul, sans alpha ni meute : deux rats pour une place, jamais d'invocation | Voulu (B50) : la vague 3 |
| `0.6.2` → `0.6.6` | Un mécanisme du catalogue n'existe pas avant la vague qui le construit : le format d'intention de la vague 2 doit pouvoir les recevoir sans reprise | La spec de la vague 2 (sa fiche, point 1) |
| `0.6.4` → `0.7.0` | Les phases existent pour les ennemis ; les boss restent des ennemis ordinaires à ×3 en PV et ×2 en dégâts | La vague 8 |
| jusqu'à `0.6.4` | Le tier le plus haut reste 3 (`maxTierAuthored`) | La vague 5 l'ouvre à 4, la vague 6 à 5 |

---

## 4. Le journal

| Vague | Version | Branche | Spec | Plan | Tests | État |
|:---|:---|:---|:---|:---|:---|:---|
| 1 — l'interface des ennemis | `0.6.1` | `feat/v0.6.1-interface-des-ennemis` | [spec](../superpowers/specs/2026-11-21-p05-interface-des-ennemis-design.md) — quatre tours | [plan](../superpowers/plans/2026-11-21-p05-interface-des-ennemis.md) — trois tours | 1866 → 1935 → **1939** (correction C1) | **fusionnée le 22/11** par la PR #57 (`32e2ad46`), **taguée `v0.6.1`** · [compte rendu](../superpowers/reports/2026-11-22-bestiaire-vague-1-compte-rendu.md) · [tests manuels](../superpowers/reports/2026-11-22-bestiaire-vague-1-tests-manuels.md) — passe à « close » à la porte d'entrée de la vague 2 |
| 2 — le tier 1 | `0.6.2` | `feat/v0.6.2-bestiaire-tier-1` | — | — | — | **à faire** — attend ses prérequis ([fiche](vague_2_tier_1.md)) |
| 3 — le tier 2 | `0.6.3` | `feat/v0.6.3-bestiaire-tier-2` | — | — | — | à faire — attend la vague 2 et ses prérequis |
| 4 — le tier 3 | `0.6.4` | `feat/v0.6.4-bestiaire-tier-3` | — | — | — | à faire — attend la vague 3 et ses prérequis |
| 5 — le tier 4 | `0.6.5` | `feat/v0.6.5-bestiaire-tier-4` | — | — | — | à faire — attend la vague 4 et ses prérequis |
| 6 — le tier 5 | `0.6.6` | `feat/v0.6.6-bestiaire-tier-5` | — | — | — | à faire — attend la vague 5 et ses prérequis |
| 7 — le visuel | `0.6.7` | `feat/v0.6.7-cadres-et-decors` | — | — | — | à faire — attend la vague 6 et ses prérequis |
| 8 — le tier boss | `0.7.0` | — | — | — | — | fiche à écrire |

**Arrêts** : la vague 1 en a eu deux, levés le 21/11 — voir le [cadrage, §4](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md).

---

## 5. Ce qui court en parallèle des vagues

- **Les sprites.** Une vague d'ennemis ne s'ouvre qu'une fois **tous** ses sprites validés (B51). Ils se produisent par `/workflow-creature`, un ennemi à la fois, le propriétaire validant chaque étape ; le skill s'arrête au sprite, la vague fait l'ennemi. **C'est le chemin critique du chantier** : les sprites de la vague 3 peuvent se produire pendant que la vague 2 se code.
- **Les questions du propriétaire.** Chaque fiche liste, sous « Prérequis », les questions visibles du joueur (classe P) à trancher avant l'ouverture, sur maquettes quand elles se voient. Elles se posent hors vague, dans une session de cadrage ; leurs réponses deviennent des décisions B du cadrage.
