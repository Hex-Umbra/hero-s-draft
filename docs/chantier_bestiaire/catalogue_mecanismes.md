# Le catalogue des mécanismes — ce qu'un ennemi peut savoir faire

> **Rôle** : la liste de tout ce qu'un ennemi pourra faire, et la vague qui le construit. Écrit le 22/11/2026 avec le propriétaire (B46), remis en ordre le 23/11 (B62, B68 à B71) ; il réunit le cadrage, les brainstorms du [27/07](../possible_upgrades/27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md) et du [28/07](../possible_upgrades/28-07-2026_roster_tier1_mecaniques_onhit_Sonnet5.md) — dont le champ `onHitEffect` est remplacé par B1 — et la ROADMAP (P-09, P-14, P-15, P-19, P-44 lot 2). Son pendant est le [catalogue des ennemis](catalogue_ennemis.md) : ici ce qu'un ennemi sait faire, là qui le fait.
>
> **Les règles** : une vague ne construit un mécanisme que si l'un de ses ennemis s'en sert, et c'est sa fiche qui le prend ici ; le propriétaire le teste en jeu sur cet ennemi (B46). Un mécanisme s'ajoute, se retire ou change de vague par une décision du propriétaire. **Ce qui est décrit ici est une intention, non une spec** : la forme exacte se fixe dans la spec de la vague qui le construit.
>
> **« Côté héros »** : le mécanisme existe déjà pour le héros. Une fois la résolution des effets rendue symétrique (B1, vague 3), il ne demande presque rien de plus pour un ennemi.
>
> **La colonne « Vague »** : 3 est le socle (`0.6.3`), 4 le tier 1, 5 le tier 2, 6 le tier 3, 7 la refonte de la difficulté, 8 le tier 4, 9 le tier 5, 10 les boss (`0.7.0`).

---

## 1. Les mécanismes et leur vague

| # | Mécanisme | Ce qu'il fait | Ennemis qui s'en servent | Côté héros | Vague | Décisions |
|:---:|:---|:---|:---|:---:|:---:|:---|
| 1 | **Le langage des intentions** | Une intention est une liste d'effets, celle des cartes ; un effet part d'un lanceur, héros ou ennemi, vers sa cible | tous | ✅ les cartes | **3** | B1, B6, B62 |
| 2 | **Le prix d'un effet** | Ce qu'un effet ajoute au coût d'un ennemi dans le budget d'un combat ; sans lui, un ennemi qui empoisonne « ne coûte rien » | tous les ennemis neufs | — | **4**, revu en **7** | B58 (+6), B64 |
| 3 | **La demi-place** | Un ennemi prend une part de place à la composition d'un combat : deux rats pour une place ; le plateau porte six cartes au plus | Rat | — | **4** | B3, B28, B7, B17, B30 |
| 4 | **Plusieurs coups** | Une attaque en N coups, chacun résolu à part | Loup des ombres | ✅ `hits` | **5** | B54 |
| 5 | **Poser un statut ou une charge** | Poison, Faiblesse, Vulnérable, Gel, Feu, Foudre, sur le héros | Araignée, slimes de givre, de braise et d'orage ; puis Squelette, Zombie, Harpie, Faucheuse, Sorcière ; Élémentaires, Aberration, Chimère | ✅ | **4** | B5, B53 |
| 6 | **Vol de vie** | L'ennemi se soigne d'une part des dégâts qu'il inflige | Corbeau | ✅ statut et rune | **4** | B53 |
| 7 | **Larcin** | L'ennemi vole de l'or au héros | Gobelin | — | **4** | B2, B49, B57 |
| 8 | **Esquive** | Un jet par coup avant le calcul des dégâts ; un coup esquivé ne pose ni charge ni statut ; le Poison et le Feu déjà posés ne s'esquivent pas | Kobold ; plus tard le Cavalier de la mort | — | **4** | B4, B55 |
| 9 | **Les traits** | Des effets permanents qu'un ennemi porte dès l'entrée en combat — l'esquive et la riposte en sont | Kobold, slimes élémentaires ; plus tard les boss et les affixes d'élite (P-14) | ~ les passifs | **4** | — |
| 10 | **Se renforcer** | Armure, Puissance, soin de soi | Golem, Gargouille, Orc ; Liche | ✅ | Armure et Puissance existent ; le soin de soi en **9**, avec la Liche | B68 |
| 11 | **L'invocation** | Un effet qui fait entrer un ennemi du bestiaire, au prix de l'action du tour | Rat alpha, puis Nécromancien | — | **5** | B20, B23 à B27, consigne du cadrage §1.3, §2 |
| 12 | **L'aura** | Un bonus qui dépend des alliés vivants ; le lien de meute en est un cas | Rat alpha et ses rats ; plus tard les soutiens | — | **5** | B22, B24, B29 |
| 13 | **Viser un allié** | Un effet d'ennemi qui vise un autre ennemi : armure, Puissance, soin | le Chaman orc, premier soutien | — | **8** | B68 |
| 14 | **Le perce-armure** | Le coup ignore l'armure, ou la détruit au lieu de toucher les PV | Voleur des cryptes, puis Chevalier déchu, Chevalier spectral, Liche | ✅ rune `piercing` | **5** | — |
| 15 | **Les phases** | Sous un seuil de PV, l'ennemi change de liste d'intentions | Ogre (la rage) ; le Dragon juvénile ; puis les boss | — | **6** | P-09 |
| 16 | **Le choix d'intention** | À côté du cycle fixe d'aujourd'hui : un tirage pondéré, ou une intention sous condition (« si le héros a de l'armure… ») | un ennemi du tier 2, à désigner ; un du tier 3 peut le reprendre ; puis les boss | — | **5** | B68, B70 |
| 17 | **L'ouverture d'un tier** | Relever `maxTierAuthored` et fixer l'acte où le tier se débloque (aujourd'hui un tier tous les cinq actes) | tout le tier 4, puis le tier 5 | — | **8**, puis **9** | B59, B60, B69, P-15 |
| 18 | **Les dégâts différés** | Une marque posée sur le héros, qui frappe plus tard | Cavalier de la mort | ~ le Feu, qui se résout au tour du héros | **9** | B59 |
| 19 | **Le tier boss** | Une réserve de boss à part, hors de l'échelle 1 à 5, sans les multiplicateurs des boss d'aujourd'hui (×3 en PV et en dégâts) | boss | — | **10** | B47 |
| 20 | **La riposte** | Un trait, comme l'esquive : quand le héros attaque son porteur, celui-ci a une chance de résoudre une liste d'effets sur lui — lui poser un statut ou une charge, ou contre-attaquer | slimes de givre, de braise et d'orage (50 %, 1 charge) ; la contre-attaque en dégâts avec son premier ennemi, à désigner | ~ les épines dues au lot Rempart en seraient le cas à 100 % | **4** | B71 |

Le code porte déjà deux coutures dormantes pour le #19 : un identifiant de boss sur le nœud de carte, toujours vide, et le préfixe `boss_`, qu'aucun fichier n'emploie et qui dispense des multiplicateurs.

---

## 2. Au catalogue, sans vague avant `0.7.0`

| Mécanisme | Ce qu'il fait | Qui s'en servirait | Où il est noté |
|:---|:---|:---|:---|
| **Les épines, l'étourdissement, les malédictions** | Symétriques héros / ennemis ; une malédiction est une carte posée dans le deck du héros. Les épines sont une riposte (#20) sûre, en dégâts | la Sorcière en serait candidate ; la carte d'épines due au lot Rempart | P-44 lot 2 |
| **Les affixes d'élite** | Une liste d'effets ajoutée aux intentions d'un ennemi tiré en élite | tout ennemi | P-14 — ils réutiliseront les traits (#9) |
| **Les intentions cachées** | En fin de partie, une intention ne se lit plus | tous | P-19 |
| **La fuite** | Un ennemi quitte le combat, avec ce qu'il a volé | le Gobelin, ou une forme plus haute de sa famille | écartée pour le tier 1 (B57) |
| **L'annonce à deux tours** | Une attaque annoncée deux tours avant, au lieu d'un | le Béhémoth de guerre | une question de la [fiche du tier 5](vague_9_tier_5.md) |
| **Les lieux** (biomes, P-12) | Un décor, des fonds de fenêtre et peut-être des ennemis propres à un lieu | — | après `0.7.0` (B69) ; la couture est posée en vague 2 (B66) |

---

## 3. Les ennemis

Tous les ennemis du programme, tier par tier, avec l'état de leur sprite, sont au [catalogue des ennemis](catalogue_ennemis.md). Concepts et premières valeurs : [27/07](../possible_upgrades/27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md), [28/07](../possible_upgrades/28-07-2026_roster_tier1_mecaniques_onhit_Sonnet5.md). Ce sont des propositions : un ennemi s'écrit dans le langage de B1, et ses valeurs sont au propriétaire.
