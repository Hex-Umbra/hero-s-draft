# Le catalogue des mécanismes — ce qu'un ennemi peut savoir faire

> **Rôle** : la liste de tout ce qu'un ennemi pourra faire, et la vague qui le construit. Écrit le 22/11/2026 avec le propriétaire (B46) ; il réunit le cadrage, les brainstorms du [27/07](../possible_upgrades/27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md) et du [28/07](../possible_upgrades/28-07-2026_roster_tier1_mecaniques_onhit_Sonnet5.md) — dont le champ `onHitEffect` est remplacé par B1 — et la ROADMAP (P-09, P-14, P-15, P-19, P-44 lot 2).
>
> **Les règles** : une vague ne construit un mécanisme que si l'un de ses ennemis s'en sert, et c'est sa fiche qui le prend ici ; le propriétaire le teste en jeu sur cet ennemi (B46). Un mécanisme s'ajoute, se retire ou change de vague par une décision du propriétaire. **Ce qui est décrit ici est une intention, non une spec** : la forme exacte se fixe dans la spec de la vague qui le construit.
>
> **« Côté héros »** : le mécanisme existe déjà pour le héros. Une fois la résolution des effets rendue symétrique (B1, vague 2), il ne demande presque rien de plus pour un ennemi.

---

## 1. Les mécanismes et leur vague

| # | Mécanisme | Ce qu'il fait | Ennemis qui s'en servent | Côté héros | Vague | Décisions |
|:---:|:---|:---|:---|:---:|:---:|:---|
| 1 | **Le langage des intentions** | Une intention est une liste d'effets, celle des cartes ; un effet part d'un lanceur, héros ou ennemi, vers sa cible | tous | ✅ les cartes | **2** | B1, B6, B42 |
| 2 | **Le prix d'un effet** | Ce qu'un effet ajoute au coût d'un ennemi dans le budget d'un combat ; sans lui, un ennemi qui empoisonne « ne coûte rien » | tous les ennemis neufs | — | **2** | B58 (+6) |
| 3 | **La demi-place** | Un ennemi prend une part de place à la composition d'un combat : deux rats pour une place ; le plateau porte six cartes au plus | Rat | — | **2** | B3, B28, B7, B17, B30 |
| 4 | **Plusieurs coups** | Une attaque en N coups, chacun résolu à part | Loup des ombres | ✅ `hits` | **3** | B54 |
| 5 | **Poser un statut ou une charge** | Poison, Faiblesse, Vulnérable, Gel, Feu, Foudre, sur le héros | Araignée, slimes de givre, de braise et d'orage ; puis Squelette, Zombie, Harpie, Sorcière | ✅ | **2** | B5 |
| 6 | **Vol de vie** | L'ennemi se soigne d'une part des dégâts qu'il inflige | Corbeau | ✅ statut et rune | **2** | — |
| 7 | **Larcin** | L'ennemi vole de l'or au héros | Gobelin | — | **2** | B2, B49, B57 |
| 8 | **Esquive** | Un jet par coup avant le calcul des dégâts ; un coup esquivé ne pose ni charge ni statut ; le Poison et le Feu déjà posés ne s'esquivent pas | Kobold | — | **2** | B4, B55 |
| 9 | **Les traits** | Des effets permanents qu'un ennemi porte dès l'entrée en combat — l'esquive en est un | Kobold ; plus tard les boss et les affixes d'élite (P-14) | ~ les passifs | **2** | — |
| 10 | **Se renforcer** | Armure, Puissance, soin de soi | Golem, Gargouille, Orc | ✅ | existe (Armure, Puissance) ; le soin de soi avec son premier ennemi | — |
| 11 | **L'invocation** | Un effet qui fait entrer un ennemi du bestiaire, au prix de l'action du tour | Rat alpha, puis Nécromancien | — | **3** | B20, B23 à B27, consigne du cadrage §1.3, §2 |
| 12 | **L'aura** | Un bonus qui dépend des alliés vivants ; le lien de meute en est un cas | Rat alpha et ses rats ; plus tard les soutiens | — | **3** | B22, B24, B29 |
| 13 | **Viser un allié** | Un effet d'ennemi qui vise un autre ennemi : armure, Puissance, soin | meute, soutiens | — | **3** | — |
| 14 | **Le perce-armure** | Le coup ignore l'armure, ou la détruit au lieu de toucher les PV | Voleur des cryptes, puis Chevalier déchu | ✅ rune `piercing` | **3** | — |
| 15 | **Les phases** | Sous un seuil de PV, l'ennemi change de liste d'intentions | Ogre (la rage) ; puis les boss | — | **4** | P-09 |
| 16 | **Le choix d'intention** | À côté du cycle fixe d'aujourd'hui : un tirage pondéré, ou une intention sous condition (« si le héros a de l'armure… ») | tier 3, boss | — | **4** | — |
| 17 | **Le tier boss** | Une réserve de boss à part, hors de l'échelle 1 à 5, sans le ×3 des boss d'aujourd'hui | boss | — | **6** | B47 |

---

## 2. Au catalogue, sans vague avant `0.7.0`

| Mécanisme | Ce qu'il fait | Qui s'en servirait | Où il est noté |
|:---|:---|:---|:---|
| **Les dégâts différés** | Une marque qui frappe plus tard | Cavalier de la mort (tier 5) | brainstorm du 27/07 |
| **Ouvrir les tiers 4 et 5** | Relever `maxTierAuthored` et la cadence de déblocage | tout le tier 4 et 5 | brainstorm du 27/07, P-15 |
| **Les épines, l'étourdissement, les malédictions** | Symétriques héros / ennemis ; une malédiction est une carte posée dans le deck du héros | la Sorcière en serait candidate ; la carte d'épines due au lot Rempart | P-44 lot 2 |
| **Les affixes d'élite** | Une liste d'effets ajoutée aux intentions d'un ennemi tiré en élite | tout ennemi | P-14 — ils réutiliseront les traits (#9) |
| **Les intentions cachées** | En fin de partie, une intention ne se lit plus | tous | P-19 |
| **La fuite** | Un ennemi quitte le combat, avec ce qu'il a volé | le Gobelin, ou une forme plus haute de sa famille | écartée pour le tier 1 (B57) |

---

## 3. Les ennemis au catalogue

Les ennemis prévus par tier sont dans les fiches des vagues 2 à 4. Restent sans vague :

- **le Bandit de grand chemin** : son larcin passe au Gobelin (B49) ; il pourrait revenir comme une forme plus haute de la famille Gobelin ;
- **le tier 4** : Élémentaires de feu et de givre, Chevalier spectral, Chaman orc (le premier soutien), Aberration difforme ;
- **le tier 5** : Liche mineure, Béhémoth de guerre, Cavalier de la mort, Chimère trifrons, Dragon juvénile (la rage, que les phases de la vague 4 serviront) ;
- **les boss** : aucun concept encore — la fiche de la vague 6 les cadrera.

Concepts et premières valeurs : [27/07](../possible_upgrades/27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md), [28/07](../possible_upgrades/28-07-2026_roster_tier1_mecaniques_onhit_Sonnet5.md). Ce sont des propositions : un ennemi s'écrit dans le langage de B1, et ses valeurs sont au propriétaire.
