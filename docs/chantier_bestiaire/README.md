# Chantier — le bestiaire, de `0.6.1` à `0.7.0`, vague par vague

> **Statut** : programme écrit le 22/11/2026 avec le propriétaire (décisions B45 à B52 et B59 à B61 du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1.5), **révisé le 23/11 après l'audit du chantier** (B62 à B74, §1.7). Dix vagues, de `0.6.1` à `0.7.0`. Les vagues 2 à 6, 8 et 9 ont leur fiche ; celle de la vague 7, la difficulté, attend son cadrage ; celle de la vague 10, les boss, est à écrire.
>
> **Ce répertoire fait foi pour le déroulé du chantier** : l'ordre des vagues, ce que chacune livre, sa version, son état. **Les décisions de conception n'y sont pas** : leur source de vérité est le cadrage, §1 (B1 à B74). Ce répertoire les cite sans les recopier ; en cas d'écart, le cadrage a raison sur le *quoi*, ce répertoire sur le *comment* et le *quand*. Le cadrage nomme les tiers ; **seul ce fichier leur donne un numéro de vague et une version**.
>
> **La méthode** est celle du chantier précédent — [ADR-102](../../.obsidian_vault/_adr/), ADR-103, [ADR-108](../../.obsidian_vault/_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md), ADR-113 et les amendements d'[ADR-120](../../.obsidian_vault/_adr/ADR-120-ce-que-le-chantier-economie-et-catalogue-legue-a-la-methode.md) D1 — avec le cycle, les gabarits, l'arbre de décision et les garde-fous du [fichier d'orchestration](../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) §3 à §6. **Son journal et ses fiches sont remplacés par ceux de ce répertoire** ; partout où il dit « le brainstorm v3 » et « D1 à D76 », lire « le cadrage » et « B1 à B74 ». Autonomie `strict` par défaut. R31 (pas de spec séparée) ne s'applique pas, sauf si une fiche le dit.

| Fichier | Ce qu'il tient |
|:---|:---|
| Ce `README.md` | Les vagues, l'ordre, les états transitoires, le journal, le prompt de lancement |
| [`catalogue_mecanismes.md`](catalogue_mecanismes.md) | Tout ce qu'un ennemi peut savoir faire, et la vague qui le construit — ou « au catalogue » |
| [`catalogue_ennemis.md`](catalogue_ennemis.md) | Tous les ennemis du programme, tier par tier : leur famille, leurs valeurs, leurs intentions, leurs mécanismes, et **si leur sprite est livré** (B65) |
| [`vague_2_visuel.md`](vague_2_visuel.md) · [`vague_3_socle.md`](vague_3_socle.md) · [`vague_4_tier_1.md`](vague_4_tier_1.md) · [`vague_5_tier_2.md`](vague_5_tier_2.md) · [`vague_6_tier_3.md`](vague_6_tier_3.md) · [`vague_7_difficulte.md`](vague_7_difficulte.md) · [`vague_8_tier_4.md`](vague_8_tier_4.md) · [`vague_9_tier_5.md`](vague_9_tier_5.md) | Une fiche par vague : ses prérequis, ce qu'elle livre, ce que sa spec doit fixer, les pièges relevés à l'audit |

---

## 0. Pour la session qui ouvre ce répertoire

**Tu es l'orchestrateur d'une vague. Une session, une vague, un orchestrateur.**

1. Lis `CLAUDE.md`, ce fichier en entier, le cadrage en entier, les deux catalogues, puis la fiche de ta vague.
2. **Trouve ta vague** comme le fichier d'orchestration §0.2 le dit, avec les motifs `'*feat/v0.6.*' '*feat/v0.7.*'` : sans branche de vague non fusionnée, ta vague est la première ligne du journal (§4) à l'état « à faire » ; une branche existante est une reprise ou une correction.
3. **Vérifie ses prérequis** (la section « Prérequis » de sa fiche) : les sprites livrés — toutes les lignes de son tier à ✅ au [catalogue des ennemis](catalogue_ennemis.md) —, les questions du propriétaire répondues. **Un prérequis manquant arrête la session avant la branche** : dis lequel, n'écris rien.
4. Passe la porte d'entrée (orchestration §3.1, plus celle de la fiche), déroule le cycle (§3) en déléguant (§4), arbitre selon §5, respecte §6, arrête-toi à la porte de sortie (§3.9).

**Ce répertoire doit être dans `main` avant qu'une vague ne s'ouvre** : la porte d'entrée part de `main`, et le prompt ci-dessous le lit de là.

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
| **2** | **`0.6.2`** | **Le visuel** : le cadre de tier, la règle d'échelle (B72), les fonds de fenêtre, le décor de combat, la couture de lieu (B66) | Chaque ennemi dans un cadre qui dit son tier, sur un fond de forêt, devant un décor de forêt redessiné | `feat/v0.6.2-cadres-et-decors` | [vague 2](vague_2_visuel.md) |
| **3** | **`0.6.3`** | **Le socle** : le langage des intentions (B1), seul (B62) | Rien de neuf : les ennemis frappent comme avant | `feat/v0.6.3-langage-des-intentions` | [vague 3](vague_3_socle.md) |
| **4** | **`0.6.4`** | **Le tier 1** : ses mécanismes, dont la riposte (B71), sept ennemis neufs, le Gobelin qui vole | Des ennemis de début de partie qui empoisonnent, gèlent, brûlent, volent, esquivent, se soignent en mordant, des slimes qui marquent celui qui les frappe, et des rats qui viennent par deux | `feat/v0.6.4-bestiaire-tier-1` | [vague 4](vague_4_tier_1.md) |
| **5** | **`0.6.5`** | **Le tier 2** : la meute du Rat alpha, l'invocation, l'aura, le perce-armure, plusieurs coups, le choix d'intention (B70) | Un chef de meute qui appelle ses rats, des ennemis qui affaiblissent et qui rongent l'armure, un ennemi dont le cycle ne se devine plus | `feat/v0.6.5-bestiaire-tier-2` | [vague 5](vague_5_tier_2.md) |
| **6** | **`0.6.6`** | **Le tier 3** : les phases | Des ennemis qui changent de comportement quand ils faiblissent, un nécromancien qui relève des squelettes | `feat/v0.6.6-bestiaire-tier-3` | [vague 6](vague_6_tier_3.md) |
| **7** | **`0.6.7`** | **La refonte de la difficulté** (B64, B69) : sa formule, sa mise à l'échelle | À dire par son cadrage | `feat/v0.6.7-difficulte` | [vague 7](vague_7_difficulte.md) — attend son cadrage |
| **8** | **`0.6.8`** | **Le tier 4** : l'ouverture du tier, viser un allié, le soutien | Des élémentaires, un chevalier que l'armure n'arrête pas, un chaman qui soigne ses alliés | `feat/v0.6.8-bestiaire-tier-4` | [vague 8](vague_8_tier_4.md) |
| **9** | **`0.6.9`** | **Le tier 5** : les dégâts différés, le soin de soi | Des quasi-boss : une marque qui frappe plus tard, un dragon qui enrage | `feat/v0.6.9-bestiaire-tier-5` | [vague 9](vague_9_tier_5.md) |
| **10** | **`0.7.0`** | **Le tier boss** (B47) | De vrais boss | à fixer | **à écrire** |

**Après `0.7.0`** : les lieux (biomes, P-12 — B69), dont la couture est posée en vague 2 et dont le système attend un cadrage propre ; et ce que le catalogue garde sans vague.

**Dans une vague, tout se déroule en série** : la spec ou le plan suivant s'écrit sur le code que le précédent a laissé sur la branche (orchestration §1).

---

## 2. Pourquoi cet ordre

- **Le visuel d'abord** (B61) : chaque sprite neuf se valide sur son vrai fond, dans son cadre ; la demi-place du Rat et la meute s'écrivent une seule fois, sur le placement définitif, où la largeur d'une carte suit son tier ; chaque vague d'ennemis se teste sur l'aspect final. Les cadres des tiers 4 et 5 se dessinent avec leurs tiers, celui des boss avec les boss.
- **Le socle seul, ensuite** (B62) : tout effet d'ennemi s'écrit dans le langage de B1, et rien ne migre deux fois. Il ne demande aucun sprite : il se code pendant que les neuf sprites du tier 1 se produisent, au lieu de les attendre.
- **Un tier par vague, et ses seuls mécanismes** (B45, B46). Chaque vague construit ce dont ses ennemis se servent, les branche, et le propriétaire les teste en jeu sur ces ennemis-là. Un mécanisme sans ennemi reste au catalogue : rien ne se construit qui ne se voie pas.
- **Le tier 2 avant le tier 3** : le Nécromancien du tier 3 invoque avec le mécanisme de la meute, et le Chevalier déchu perce l'armure avec celui du Voleur des cryptes.
- **Le tier 3 avant le tier 5 et les boss** : les phases, que l'Ogre étrenne, servent la rage du Dragon juvénile et sont le socle d'un boss (P-09).
- **Les ennemis d'aujourd'hui évoluent en chemin** (B48) : le Gobelin au tier 1, le Squelette au tier 2, l'Orc au tier 3. Aucune vague ne leur est consacrée.
- **La difficulté après le tier 3, avant le tier 4** (B69) : après, parce qu'elle se règle sur des ennemis qui existent, qui portent des effets et que le propriétaire a joués ; avant, parce que les tiers 4 et 5 s'ouvrent aux actes 16 et 21, là où la formule d'aujourd'hui tient le moins bien — un budget qui croît en ligne droite face à des prix qui croissent en puissance. Les construire d'abord, ce serait fixer leurs valeurs deux fois.
- **Les lieux après les boss** (B69) : leur système n'est pas conçu, et son coût est dans l'art — un décor et trois fonds de fenêtre par lieu.

---

## 3. Les états transitoires

| Frontière | État transitoire | Réglé par |
|:---|:---|:---|
| `0.6.2` → `0.6.5` | Les anciens sprites, des cartes peintes de 1696 × 2528 au rapport de la fenêtre, s'affichent dans les nouveaux cadres jusqu'à leur refonte (B52) : le Slime et le Gobelin en `0.6.2` et `0.6.3`, le Squelette jusqu'en `0.6.4`, l'Orc jusqu'en `0.6.5` | La vague de chaque tier, qui le redessine |
| `0.6.3` | Le langage des intentions existe, et seules les trois intentions d'aujourd'hui s'y écrivent | Voulu (B62) : la vague 4 |
| `0.6.4` | Le Rat existe seul, sans alpha ni meute : deux rats pour une place, jamais d'invocation | Voulu (B50) : la vague 5 |
| `0.6.3` → `0.6.9` | Un mécanisme du catalogue n'existe pas avant la vague qui le construit : le format d'intention de la vague 3 doit pouvoir les recevoir, et dit ce qu'il suppose de ceux dont la forme n'est pas tranchée | La spec de la vague 3 (sa fiche, point 1) |
| `0.6.4` → `0.6.6` | Les ennemis neufs entrent avec la formule d'aujourd'hui — le budget d'un combat, +6 par effet (B58). À stats brutes, ceux du tier 1 sont plus faibles que le Slime et le Gobelin : la difficulté peut baisser en début de partie | La refonte de la difficulté, en `0.6.7` |
| `0.6.6` → `0.6.9` | Les phases existent pour les ennemis ; les boss restent des ennemis ordinaires à ×3 en PV et ×3 en dégâts | Le tier boss, en `0.7.0` |
| jusqu'à `0.6.7` | Le tier le plus haut reste 3 (`maxTierAuthored`) | La vague 8 l'ouvre à 4, la vague 9 à 5 |
| `0.6.2` → après `0.7.0` | Un seul lieu : un décor de combat et un thème de fond de fenêtre pour tout le jeu (B66) | Les lieux, après `0.7.0` |

---

## 4. Le journal

| Vague | Version | Branche | Spec | Plan | Tests | État |
|:---|:---|:---|:---|:---|:---|:---|
| 1 — l'interface des ennemis | `0.6.1` | `feat/v0.6.1-interface-des-ennemis` | [spec](../superpowers/specs/2026-11-21-p05-interface-des-ennemis-design.md) — quatre tours | [plan](../superpowers/plans/2026-11-21-p05-interface-des-ennemis.md) — trois tours | 1866 → 1935 → **1939** (correction C1) | **fusionnée le 22/11** par la PR #57 (`32e2ad46`), **taguée `v0.6.1`** · [compte rendu](../superpowers/reports/2026-11-22-bestiaire-vague-1-compte-rendu.md) · [tests manuels](../superpowers/reports/2026-11-22-bestiaire-vague-1-tests-manuels.md) — passe à « close » à la porte d'entrée de la vague 2 |
| 2 — le visuel | `0.6.2` | `feat/v0.6.2-cadres-et-decors` | — | — | — | **à faire** — attend ses prérequis ([fiche](vague_2_visuel.md)) |
| 3 — le socle | `0.6.3` | `feat/v0.6.3-langage-des-intentions` | — | — | — | à faire — attend la vague 2 ; aucun autre prérequis |
| 4 — le tier 1 | `0.6.4` | `feat/v0.6.4-bestiaire-tier-1` | — | — | — | à faire — attend la vague 3 et ses prérequis |
| 5 — le tier 2 | `0.6.5` | `feat/v0.6.5-bestiaire-tier-2` | — | — | — | à faire — attend la vague 4 et ses prérequis |
| 6 — le tier 3 | `0.6.6` | `feat/v0.6.6-bestiaire-tier-3` | — | — | — | à faire — attend la vague 5 et ses prérequis |
| 7 — la difficulté | `0.6.7` | `feat/v0.6.7-difficulte` | — | — | — | à faire — attend la vague 6 et son cadrage ; fiche à compléter |
| 8 — le tier 4 | `0.6.8` | `feat/v0.6.8-bestiaire-tier-4` | — | — | — | à faire — attend la vague 7 et ses prérequis |
| 9 — le tier 5 | `0.6.9` | `feat/v0.6.9-bestiaire-tier-5` | — | — | — | à faire — attend la vague 8 et ses prérequis |
| 10 — le tier boss | `0.7.0` | — | — | — | — | fiche à écrire |
| la clôture | — | — | — | — | — | après la vague 10 : le bilan du [suivi](../suivi_vagues_chantier/bestiaire.md), et les lignes P-05, P-08, P-09 et P-15 de la ROADMAP |

**Arrêts** : la vague 1 en a eu deux, levés le 21/11 — voir le [cadrage, §4](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md).

---

## 5. Ce qui court en parallèle des vagues

- **Les sprites.** Une vague d'ennemis ne s'ouvre qu'une fois **tous** ses sprites livrés (B51) ; leur état se tient au [catalogue des ennemis](catalogue_ennemis.md) (B65), qui est la file de production : 33 sprites hors boss, aucun livré au 23/11. Ils se produisent par `/workflow-creature`, un ennemi à la fois, le propriétaire validant chaque étape ; le skill s'arrête au sprite, la vague fait l'ennemi. **C'est le chemin critique du chantier** : les neuf sprites du tier 1 se produisent pendant que les vagues 2 et 3 se codent, et se valident sur les cadres et les fonds de la vague 2 ; ceux du tier 2 pendant la vague 4, et ainsi de suite.
- **Les cadres et le décor de la vague 2.** Les cadres des tiers 1 à 3 se redessinent, moins pleins, à leurs nouvelles tailles (B73), et un décor de combat de forêt se produit en 640 × 360 (B74) : ce sont les prérequis qui ouvrent la vague 2.
- **Les questions du propriétaire.** Chaque fiche liste, sous « Prérequis », les questions visibles du joueur (classe P) à trancher avant l'ouverture, sur maquettes quand elles se voient. Elles se posent hors vague, dans une session de cadrage ; leurs réponses deviennent des décisions B du cadrage.
- **Le cadrage de la difficulté** (B64) : un brainstorm à tenir après la vague 6, sur les tests des tiers 1 à 3. Il donne sa matière à la vague 7.
- **Le cadrage des boss**, avant la fiche de la vague 10 ; et celui des lieux, pour après `0.7.0`.
