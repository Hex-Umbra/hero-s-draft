# Le catalogue des ennemis — le dictionnaire du bestiaire

> **Rôle** : la liste de tous les ennemis du programme, tier par tier, et **l'état de leur sprite**. Écrit le 23/11/2026 avec le propriétaire (B65) ; il réunit le cadrage (B2, B20, B43, B44, B48, B49, B52, B53, B57), les quatre fichiers `assets/data/enemies/*/enemy.json` et le brainstorm du [27/07](../possible_upgrades/27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md). Il est le pendant du [catalogue des mécanismes](catalogue_mecanismes.md) : là ce qu'un ennemi sait faire, ici qui le fait.
>
> **Les règles** :
> - **La porte des sprites (B51) se lit ici** : une vague d'ennemis ne s'ouvre que lorsque toutes les lignes de son tier sont à ✅.
> - Une ligne s'ajoute, se retire ou change de tier par une décision du propriétaire.
> - **Ce qui est écrit ici est une intention, non une spec** : les valeurs marquées « à fixer » se fixent dans les prérequis ou la spec de la vague.
> - **Une fois l'ennemi livré, sa donnée fait foi** (`assets/data/enemies/<id>/enemy.json`) : la vague remplace alors ses valeurs par un renvoi à ce fichier, et ne les recopie pas.

**La colonne « Sprite livré »** :

| Marque | Ce qu'elle dit |
|:---:|:---|
| ✅ | Le sprite neuf (128 × 192) est validé par le propriétaire : la vague peut s'en servir. La date de validation suit la marque. |
| 🟡 | Le sprite est produit dans `art_src/sprites/`, mais pas encore livré : en itération, ou sa validation n'est pas tracée. |
| ❌ | Le sprite est à produire, par `/workflow-creature`. |

Les quatre ennemis d'aujourd'hui ont un sprite en jeu, une peinture de 1696 × 2528 : il ne compte pas, tout le bestiaire est redessiné (B52).

---

## 1. Le compte

| Tier | Vague | Version | Apparaît à l'acte | Ennemis | Liste | Sprites livrés |
|:---:|:---:|:---|:---:|:---:|:---|:---:|
| 1 | 4 | `0.6.4` | 1 | 9 | fixée (B49, B53) | 0 / 9 |
| 2 | 5 | `0.6.5` | 6 | 7 | à confirmer | 0 / 7 — 2 produits |
| 3 | 6 | `0.6.6` | 11 | 7 | à confirmer | 0 / 7 — 1 produit |
| 4 | 8 | `0.6.8` | 16 (B60) | 5 | à confirmer | 0 / 5 |
| 5 | 9 | `0.6.9` | 21 (B60) | 5 | à confirmer | 0 / 5 |
| Boss | 10 | `0.7.0` | hors de l'échelle (B47) | aucun concept | — | — |
| **Total** | | | | **33**, hors boss | | **0 / 33** — 3 produits |

Compté le 23/11/2026. Les actes d'apparition sont ceux de la cadence d'aujourd'hui, un tier tous les cinq actes ; elle se réexamine avec la difficulté (B64), en vague 7, avant les tiers 4 et 5.

---

## 2. Tier 1 — dès l'acte 1 — vague 4

Liste fixée. Valeurs des ennemis neufs : B53, des valeurs de départ. Les mécanismes renvoient au [catalogue](catalogue_mecanismes.md).

| Ennemi | Famille (B2) | État | PV · dégâts · critique | XP · or | Intentions | Mécanismes | Sprite livré |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Slime** | Slime — les charges | Existant, redessiné (B52) | 18 · 4 · 5 % | 25 · 10 | Attaque 4 | — | ❌ |
| **Gobelin** | Gobelin — le larcin | Existant, redessiné (B52) ; gagne le larcin (B49) | 28 · 5 · 10 % | 35 · 12 | Attaque 5, qui vole 5 or par coup (B57) | #7 larcin | ❌ |
| **Rat** | Rat — la meute | Neuf | 8 · 3 · à fixer | à fixer | Attaque 3, un seul coup (B54) | #3 demi-place | ❌ |
| **Slime de givre** | Slime | Neuf, créature à part (B44) | 18 · 3 · à fixer | à fixer | Attaque 3, qui pose 2 Gel ; riposte : le héros qui l'attaque a 50 % de chance de prendre 1 Gel (B71) | #5 pose d'une charge, #20 riposte | ❌ |
| **Slime de braise** | Slime | Neuf, créature à part (B44) | 18 · 3 · à fixer | à fixer | Attaque 3, qui pose 1 Feu ; riposte : 50 % de chance de prendre 1 Feu (B71) | #5 pose d'une charge, #20 riposte | ❌ |
| **Slime d'orage** | Slime | Neuf, créature à part (B44) | 18 · 4 · à fixer | à fixer | Attaque 4, qui pose 1 Foudre ; riposte : 50 % de chance de prendre 1 Foudre (B71) | #5 pose d'une charge, #20 riposte | ❌ |
| **Araignée venimeuse** | Araignée — le Poison | Neuve | 16 · 2 · à fixer | à fixer | Morsure 2, qui pose Poison 1 | #5 pose d'un statut | ❌ |
| **Corbeau charognard** | à nommer | Neuf | 16 · 4 · à fixer | à fixer | Attaque 4 ; se soigne de 50 % des dégâts portés aux PV | #6 vol de vie | ❌ |
| **Kobold éclaireur** | à nommer | Neuf | 14 · 4 · à fixer | à fixer | Attaque 4 ; esquive 20 % par coup, en trait (B4, B55) | #8 esquive, #9 traits | ❌ |

---

## 3. Tier 2 — dès l'acte 6 — vague 5

**Liste à confirmer** par le propriétaire. Concepts : le 27/07, sauf le Rat alpha (cadrage §1.3) et le Squelette (B48). **Un ennemi de ce tier, à désigner, porte le choix d'intention** (#16, B70) : aucune ligne ne le dit encore.

| Ennemi | Famille (B2) | État | PV · dégâts · critique | XP · or | Intentions | Mécanismes | Sprite livré |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Rat alpha** | Rat — la meute | Neuf (B20) | à fixer | à fixer | Entre seul ; invoque ses rats un par un, deux au plus, au prix de son action (B23) ; lien de meute sur la Puissance (B22) | #11 invocation, #12 aura | 🟡 produit le 14/11 (`art_src/sprites/rat/tier_1/rat_geant.aseprite`, B43) — fait comme un tier 1 : le garder ou le retoucher reste à trancher |
| **Squelette** | Squelette — la Faiblesse | Existant, redessiné (B52) ; prend la Faiblesse (B48) | 22 · 8 · 10 % | 50 · 15 | Attaque 8, puis attaque 10 ; la Faiblesse est à placer dans ce cycle | #5 pose d'un statut | 🟡 produit, encore en itération (`art_src/sprites/squelette/tier_2/`) |
| **Zombie enragé** | à nommer | Neuf | à fixer | à fixer | Cycle à deux coups ; chaque coup pose du Poison | #5 pose d'un statut | ❌ |
| **Loup des ombres** | à nommer | Neuf | à fixer | à fixer | Cycle rapide, critique haut, plusieurs coups | #4 plusieurs coups | ❌ |
| **Voleur des cryptes** | à nommer | Neuf | à fixer | à fixer | Deux coups, dont un détruit l'armure au lieu de toucher les PV | #14 perce-armure | ❌ |
| **Golem d'argile** | à nommer | Neuf | à fixer | à fixer | Armure, puis coup lourd — le premier ennemi qui gagne de l'armure | #10 se renforcer | ❌ |
| **Harpie** | à nommer | Neuve | à fixer | à fixer | Deux coups, dont un pose le Vulnérable | #5 pose d'un statut | ❌ |

---

## 4. Tier 3 — dès l'acte 11 — vague 6

**Liste à confirmer** par le propriétaire. Concepts : le 27/07, sauf l'Orc (B48) et la Faucheuse (sprite existant).

| Ennemi | Famille (B2) | État | PV · dégâts · critique | XP · or | Intentions | Mécanismes | Sprite livré |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Orc Furieux** | Orc — la Puissance | Existant, redessiné (B52) ; sa forme est à fixer | 50 · 8 · 15 % | 100 · 25 | Attaque 8, puis Puissance +2, puis attaque 12 | #10 se renforcer | ❌ |
| **Squelette faucheuse** | Squelette — la Faiblesse | Neuve ; forme haute du Squelette ou ennemi à part : la lignée est à trancher | à fixer | à fixer | La Faiblesse, à la forme de tier 3 | #5 pose d'un statut | 🟡 produite (`art_src/sprites/squelette/tier_3/`) — sa validation n'est pas tracée |
| **Nécromancien novice** | à nommer | Neuf | à fixer | à fixer | Invoque le Squelette (B27) | #11 invocation | ❌ |
| **Chevalier déchu** | à nommer | Neuf | à fixer | à fixer | Attaque, puis Armure, puis frappe perce-armure | #10 se renforcer, #14 perce-armure | ❌ |
| **Sorcière des marais** | à nommer | Neuve | à fixer | à fixer | Poison et Gel en alternance | #5 pose d'un statut ou d'une charge | ❌ |
| **Ogre bourrin** | à nommer | Neuf | à fixer | à fixer | Attaque, attaque, frappe énorme ; la rage, une phase sous un seuil de PV | #15 phases | ❌ |
| **Gargouille animée** | à nommer | Neuve | à fixer | à fixer | Armure, puis deux attaques | #10 se renforcer | ❌ |

---

## 5. Tier 4 — dès l'acte 16 — vague 8

**Liste à confirmer** : [fiche de la vague 8](vague_8_tier_4.md). Concepts : le 27/07. Ses valeurs se fixent après la refonte de la difficulté (B69).

| Ennemi | Famille (B2) | État | PV · dégâts · critique | XP · or | Intentions | Mécanismes | Sprite livré |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Élémentaire de feu** | Slime, ou à part : à trancher | Neuf | à fixer | à fixer | Chaque coup pose du Feu | #5 pose d'une charge | ❌ |
| **Élémentaire de givre** | Slime, ou à part : à trancher | Neuf | à fixer | à fixer | Chaque coup pose du Gel | #5 pose d'une charge | ❌ |
| **Chevalier spectral** | à nommer | Neuf | à fixer | à fixer | Une attaque qui perce toujours l'armure | #14 perce-armure | ❌ |
| **Chaman orc** | Orc, ou à part : à trancher | Neuf | à fixer | à fixer | Soigne ou renforce les autres ennemis : le premier soutien | #13 viser un allié | ❌ |
| **Aberration difforme** | à nommer | Neuve | à fixer | à fixer | Un coup qui pose à la fois le Vulnérable et la Faiblesse | #5 pose d'un statut | ❌ |

---

## 6. Tier 5 — dès l'acte 21 — vague 9

**Liste à confirmer** : [fiche de la vague 9](vague_9_tier_5.md). Concepts : le 27/07, qui les appelait des « quasi-boss ». Ses valeurs se fixent après la refonte de la difficulté (B69).

| Ennemi | Famille (B2) | État | PV · dégâts · critique | XP · or | Intentions | Mécanismes | Sprite livré |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Liche mineure** | à nommer | Neuve | à fixer | à fixer | Cycle de quatre : se renforcer, attaque lourde, se soigner, attaque perce-armure | #10 se renforcer et soin de soi, #14 perce-armure | ❌ |
| **Béhémoth de guerre** | à nommer | Neuf | à fixer | à fixer | Des PV énormes ; une attaque massive tous les deux tours, annoncée | une annonce à deux tours serait un mécanisme hors catalogue : à trancher | ❌ |
| **Cavalier de la mort** | à nommer | Neuf | à fixer | à fixer | Une marque à dégâts différés ; une esquive occasionnelle | #18 dégâts différés, #8 esquive | ❌ |
| **Chimère trifrons** | à nommer | Neuve | à fixer | à fixer | Trois intentions en alternance : Feu, Gel, Foudre | #5 pose d'une charge | ❌ |
| **Dragon juvénile** | à nommer | Neuf | à fixer | à fixer | La rage sous 50 % de ses PV | #15 phases | ❌ |

---

## 7. Sans tier ni vague

- **Le Bandit de grand chemin** : son larcin est passé au Gobelin (B49) ; il pourrait revenir comme une forme plus haute de la famille Gobelin.
- **Les boss** : aucun concept encore. Ils forment un tier à part (B47), et leur fiche est à écrire.

---

## 8. Ce que ce dictionnaire ne sait pas encore

- **Le critique, l'XP et l'or des sept ennemis neufs du tier 1** : B53 fixe leurs PV, leurs dégâts et leur effet, pas le reste. À fixer avant la spec de la vague 4.
- **Les familles** : B2 en nomme six (Rat, Slime, Araignée, Gobelin, Squelette, Orc). Le Corbeau, le Kobold et tous les ennemis neufs des tiers 2 à 5 n'en ont pas ; or le chemin d'un sprite, `art_src/sprites/<famille>/tier_<n>/`, en demande une.
- **Les identifiants** : le nom du dossier de chaque ennemi neuf, fixé par la spec de sa vague.
- **Toutes les valeurs des tiers 2 à 5**, et la place de la Faiblesse dans le cycle du Squelette.
- **L'ennemi du tier 2 qui porte le choix d'intention** (B70), et **le premier ennemi qui contre-attaque en dégâts** par la riposte (B71).
