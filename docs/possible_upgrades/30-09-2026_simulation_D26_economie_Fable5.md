# Simulation D26 — l'économie de deck du brainstorm v3, sur 15 actes

**Date** : 30/09/2026
**Objet** : la simulation que D26 demande avant la spec du chantier « Économie unifiée » — trouvaille, fusion, affûtage, Puits, Autel, boutique, XP, DDA, sur 15 actes, par classe **et par lot**.
**Règles simulées** : les décisions D1 à D55 de [`22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md`](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md) §1 ; les chiffres du jeu d'aujourd'hui, relus dans le code à `3b8c66f` (revue [`29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md`](29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §4 et annexe A).
**Script** : `tool/simulations/d26_economy_sim.dart` — conservé dans le dépôt, hors de `pubspec.yaml` (aucun asset), relancé à chaque changement de donnée (brainstorm §12) ; la première passe le disait jetable, la relance à k = 2 du soir même (§7) l'a fait durable. `dart run tool/simulations/d26_economy_sim.dart --out <fichier>` ; 8 à 10 minutes sur 22 cœurs ; graine fixée, sortie reproduite à l'identique sur deux passes.
**Statut** : Exploration. **Rien n'est tranché ici** : chaque chiffre sort d'une mesure du script, et les décisions que les chiffres contredisent (§6) sont signalées sans être modifiées — le propriétaire tranche.

---

## 0. Le verdict en six lignes

1. **La fusion va bien plus vite que le brainstorm ne l'estimait.** Première rare à l'acte 4 (A2–A6) — pas vers l'acte 23 —, atteinte dans 100 % des runs ; première épique à l'acte 10, dans 94 %. Le brainstorm comptait les copies d'une carte *donnée* ; avec un pool de 15 cartes, c'est une carte *quelconque* qui atteint trois copies — et la trouvaille seule donne encore une rare à l'acte 8.
2. **Le deck ne gonfle pas** : 35 cartes (30–41) à l'acte 15, pas ~100. Chaque fusion retire deux cartes, et 45 fusions en absorbent 90. Le puits de dilution qui motivait D52 est la fusion elle-même.
3. **L'or n'est jamais la contrainte, et la visite de feu non plus : c'est le repos.** 5 978 or dorment à l'acte 15, et `b` de 25 à 150 change à peine le nombre d'affûtages (5 à 4). Sur 20 visites de feu, 14 sont des repos : 5 affûtages par run, pas ~24. Seul le Berserker Sang, qui ne se repose jamais, affûte 16 fois.
4. **La courbe d'XP en table par acte tient D24 ; le palier constant diverge.** Le niveau des ennemis suit celui du héros et leur XP monte de 10 % par niveau : un palier constant emballe la boucle (niveau 57 à l'acte 5). La table calée donne 2 niveaux par acte, niveau 30 et 12 évolutions de signature à l'acte 15.
5. **Dans ce modèle, la survie cède vers l'acte 5.** Les dégâts ennemis passent de 45 à 154 par tour entre les actes 5 et 15, contre des héros de 60 à 100 PV au départ. Le repos mange alors les feux. C'est la plus grande réserve de ce rapport (§5) et un sujet à router hors du chantier E.
6. **Les leviers de D31, du Puits, de l'Autel et de `b` bougent peu ; trois leviers bougent beaucoup** : la deuxième carte garantie (+55 % de fusions), le Miroir en `draft` (épique à l'acte 7, mais −27 % de dégâts) et le coefficient de la DDA (+20 % de budget ennemi à k = 10).

---

## 1. Méthode, hypothèses, valeurs par défaut

### 1.1. Ce que le script modélise

| Bloc | Modèle | Source |
|:---|:---|:---|
| **Acte** | Le générateur porté tel quel : 10 étages de 2 à 5 nœuds, types 60/15/10/10/5, élite à l'étage 5, repos à l'étage 8, trois boss (cartes / XP / relique), connexions, quotas par type et anti-répétition, Autel | `map_generator_service.dart:14`, `map_node_generator.dart:6-83`, `map_connection_builder.dart:10-55`, `map_validator.dart`, `game_constants.dart:25-31`, `map_content_placer.dart:10-21` |
| **Puits** | Garanti tous les 3 actes, sur un combat ou un événement des étages 3 à 7 | D22 ; `map_content_placer.dart:24-36` |
| **Rencontres** | Budget, niveau, PV, dégâts et tirage des ennemis portés tels quels ; 5 ennemis actifs au plus | `encounter_system.dart:19-304`, `combat_controller.dart:151-169` |
| **XP, or, reliques** | Par ennemi × (1 + 0,1 × (niveau − 1)) ; boss « XP » ×3 ; tables de rareté des reliques ; tirage avec remise | `reward_controller.dart:83-165`, `event_controller.dart:80-100` |
| **Trouvaille** | 1 carte garantie par combat normal ; en élite, 1 plus 25 % d'une seconde ; tirage uniforme dans le pool offrable (9 neutres + 6 cartes de lot = 15), `common` ; reliques A, B, C | D1, D31, D16 |
| **Fusion** | Automatique dès trois copies identiques (id et rang), en cascade ; runes additionnées par id et bornées par `maxLevel` ; une rune neuve parmi 3 tirées | D3, D13, D27, D48, D51, §8 |
| **Affûtage** | Une rune, un niveau par visite, `b × niveau` ; boss « XP » : une rune tirée ; événement ; mythique `maxLevel` + 1 | D14, D20, D42 |
| **Boutique** | 3 cartes du pool à rareté selon l'acte, runes bornées par le rang ; copie d'une carte du deck (D46) ; Miroir magique 150 or doublé ; soin 30 or ; purge 75 or | `shop_controller.dart:20-225`, `shop_state.dart:16`, `shop_screen.dart:294-441` |
| **Niveau** | 3 récompenses du pool `draft` et un jet par mythique ; Sagesse en mythique | `level_up_reward_service.dart:38-148`, D11 |
| **DDA** | `PlayerPower` avec k × Σ `fusionRank` à la place de cartes × 2 | D47, `encounter_system.dart:97-120` |
| **Combat** | Abstrait, pas le moteur : main de 5, 3 mana, IA gloutonne, Puissance par `mightTargets`, conversion 0,5 arrondie au-dessus (Berserker), `mightRatio`, runes en pourcentage, passifs, reliques de stats, d'armure et de soin, signatures à recharge. Il donne les PV perdus et, contre un mannequin, les dégâts des tours 1 à 3 | D33, D36-D38, D41, D49 ; `passive_strategies.dart`, `damage_pipeline.dart` |

**Volume.** 9 configurations (3 classes × 3 lots) × 300 runs pour la référence ; 200 runs par configuration pour chaque variante de levier, **sur les mêmes graines** : l'écart entre deux lignes d'une table vient du levier, pas du hasard.

### 1.2. Les valeurs par défaut que le brainstorm laisse ouvertes

| Valeur | Défaut retenu | Pourquoi | Varié ? |
|:---|:---|:---|:---:|
| Cartes des lots | Les exemples de §7, complétés à 6 par des cartes génériques (6 dégâts ou 5-6 armure par mana) | D16 : 5 à 6 cartes ; §7 n'en écrit que 3 à 6 par lot | non |
| Noyau neutre | Les 9 neutres gardées par §7.4 (`focus` supprimée) | revue B.4 | non |
| Draft de départ | 5 cartes distinctes : 2 du lot et 3 neutres, dans un ordre fixe par classe | validé (point 2) | non |
| Signatures | Les six, hors du deck, recharge de 2 (esquisse de `smite`) | D49, §4.4 | non |
| Reliques D31 | A (+25 % en élite, rare), B (+1 % par exemplaire, épique), C (+1 garantie, rare), dans la réserve de reliques | D31 ; point 1 validé | **oui** |
| Relique légendaire de D42a | +1 rune affûtée par exemplaire | D42(a) | non |
| `b` d'affûtage, base du Puits | 50 or | « 50 or, par exemple », §4.2 | `b` : **oui** |
| Événement de fusion D29 | 10 % des PV max + 30 or × rang visé ; gagnante tirée | Q18, validé (point 5) | non |
| Échange de relique D23 | La plus faible contre 40 or × (rareté + 1), ou 20 % des PV sous 50 % des PV | Q15, validé | non |
| Événement d'affûtage D42b | +1 niveau contre 10 % des PV max | validé | non |
| Échange 3 → 1 | **Absent** de la référence | §1 ligne « Plus tard », D52 (P-16) ; validé (point 4) | **oui** |
| Courbe d'XP | **Table par acte** calée pour 2 niveaux par acte | le palier constant diverge (§3.9) — ce n'est plus le défaut annoncé dans le plan | **oui** |
| DDA | k = 5 *(relancé à k = 2 le soir même, après D59 — §7 ; le défaut du script est désormais 2)* | D47 laisse k à la simulation | **oui** |
| Éligibilité de `sharp` / `hardened` | Toute carte portant l'effet (dégâts / armure) | D33 ; sans quoi aucune Compétence de dégâts du Mage ne prend de rune de dégâts | non |
| Runes neuves du §8 | Poids 50, `minFusionRank` 1 | §8 ne les fixe pas | non |
| Exclusions D51 | `enduring` ↔ `eco`, `quick` dans les deux sens | D51 ne dit que le sens `enduring` → | non |
| Plafond de niveau | 999, garde-fou de la simulation | borne les courbes qui divergent | — |

### 1.3. Les politiques du joueur simulé

- **Chemin** : le chemin passe par le Puits quand l'acte en a un ; sinon Autel utilisable, événement, repos si PV < 50 %, combat, boutique, élite, repos. Le Berserker Sang ne choisit jamais le repos.
- **Feu de camp** : repos sous 50 % des PV ; sinon affûter la rune qui rapporte le plus ; sinon oublier la commune la moins utile. Sang affûte ou oublie, jamais ne se repose (D26).
- **Boutique** : compléter une fusion d'abord (carte, copie D46 ou Miroir), puis un soin sous 50 % des PV, puis former une paire en gardant l'or du prochain affûtage, puis une purge si le deck dépasse 25 cartes et que l'or déborde.
- **Niveau** : Sagesse ; la mythique `maxLevel` si une rune du deck est à son plafond ; le Miroir si le deck a une paire ; sinon la meilleure stat (Puissance d'abord).
- **Boss** : « cartes » si le deck a une paire, sinon XP et relique en alternance ; 2 clones pris parmi 5, ceux qui complètent une fusion d'abord.
- **Événements** : un choix par score (le gain si les PV le permettent, le soin sinon) ; D29 et D42b refusés sous 30 % des PV.

### 1.4. D50 à D55, apparues pendant le travail

La seconde passe de cohérence du 30/09 (revue §11) a ajouté D50 à D55 pendant que le script s'écrivait. Elles sont prises en compte : **D51** (`enduring` exclut `eco` et `quick` ; `cheap` exige un coût ≥ 1), **D55** (*Prière* : 2 mana, Pouvoir, `hp_regen` 2 pendant 3 tours) ; **D52** confirme le défaut « échange 3 → 1 absent » ; D50, D53, D54 ne touchent pas l'économie simulée. La seconde passe renvoie aussi deux questions à la simulation — **Q21** (§3.12) et **la chance de D42(c)** (§3.11).

---

## 2. La référence — ce que fait l'économie, acte par acte

### 2.1. Toutes configurations

Médiane (P10–P90) de 2 700 runs, en fin d'acte.

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (12–18) | 20 (16–24) | 26 (22–31) | 29 (25–34) | 32 (27–37) | 35 (30–41) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (4–8) | 11 (8–14) | 20 (16–26) | 27 (22–35) | 34 (29–45) | 45 (39–61) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) |
| Échanges 3 → 1 (cumul) | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–3) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 6 (4–9) | 12 (9–15) | 21 (17–27) | 28 (23–35) | 35 (29–44) | 45 (38–57) |
| Niveaux de rune, somme | 2 (0–4) | 9 (5–13) | 17 (12–24) | 31 (23–44) | 42 (31–59) | 54 (41–75) | 73 (55–102) |
| Niveau de rune, max | 1 (0–2) | 2 (1–4) | 4 (2–7) | 5 (3–12) | 6 (3–15) | 7 (4–19) | 9 (4–25) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 0 (0–2) | 2 (0–4) | 3 (1–5) | 4 (2–7) | 5 (3–8) |
| Visites de feu de camp (cumul) | 1 (1–2) | 3 (3–5) | 6 (5–8) | 10 (9–13) | 13 (11–16) | 16 (13–19) | 20 (17–23) |
| … dont repos | 0 | 1 (0–3) | 2 (0–6) | 6 (0–10) | 8 (0–13) | 11 (0–15) | 14 (0–19) |
| … dont oubli | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 (0–1) | 1 (0–3) | 3 (0–5) | 3 (0–8) | 4 (1–10) | 4 (1–12) | 5 (1–15) |
| … dont échange 3 → 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) |
| Or gagné (cumul) | 101 (70–188) | 544 (430–667) | 1388 (1155–1639) | 3432 (2883–4062) | 5065 (4254–5952) | 6908 (5794–8089) | 9473 (8008–10998) |
| Or dépensé (cumul) | 0 (0–75) | 275 (90–475) | 585 (225–1005) | 1245 (565–2180) | 1780 (885–3186) | 2395 (1245–4385) | 3333 (1790–6406) |
| Or en réserve | 136 (74–231) | 314 (92–553) | 834 (367–1298) | 2208 (1164–3135) | 3234 (1792–4540) | 4413 (2440–6142) | 5978 (2983–8262) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–12) | 15 (13–18) | 19 (16–23) | 23 (20–28) | 30 (25–35) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| XP gagnée dans l’acte | 223 (170–293) | 625 (455–801) | 1222 (859–1587) | 2257 (1657–2962) | 2509 (1789–3304) | 2867 (2082–3832) | 2268 (1602–3060) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 6 (6–8) | 8 (8–10) | 12 (10–14) |
| Mythique D42c offerte (cumul) | 0 | 0 | 0 | 0 | 0 | 0 (0–1) | 0 (0–1) |
| Mythique D42c prise (cumul) | 0 | 0 | 0 | 0 | 0 | 0 | 0 (0–1) |
| Reliques | 2 (1–3) | 5 (3–7) | 7 (5–10) | 12 (9–15) | 14 (10–18) | 17 (13–21) | 20 (16–25) |
| Exemplaires des reliques de D31 | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) |
| PlayerPower (DDA) | 133 (109–156) | 235 (185–292) | 345 (275–424) | 512 (415–620) | 623 (506–756) | 732 (597–881) | 907 (738–1082) |
| Budget ennemi d’un combat normal | 40 (36–44) | 146 (130–164) | 257 (230–286) | 427 (384–473) | 543 (488–601) | 655 (591–724) | 831 (751–915) |
| Budget sous la DDA actuelle (cartes × 2) | 56 (48–67) | 164 (145–186) | 270 (240–303) | 429 (384–479) | 534 (477–596) | 640 (575–714) | 801 (719–888) |
| Budget sous Σ rang × 2 | 53 (46–65) | 159 (140–181) | 264 (235–297) | 425 (379–475) | 532 (475–594) | 639 (575–714) | 805 (723–891) |
| Budget sous Σ rang × 5 | 54 (47–65) | 164 (145–186) | 276 (246–309) | 447 (401–497) | 562 (503–624) | 676 (610–750) | 852 (769–939) |
| Budget sous Σ rang × 10 | 55 (48–67) | 173 (154–195) | 294 (263–329) | 484 (436–535) | 610 (550–674) | 738 (669–813) | 930 (845–1021) |
| Ennemis par combat normal | 1,0 | 3,0 | 4,8 (4,0–5,0) | 5,0 (4,3–5,5) | 4,6 (4,0–5,0) | 3,5 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–27) | 38 (34–42) | 60 (55–66) | 104 (94–114) | 159 (142–177) | 291 (243–353) | 571 (462–726) |
| PV d’une rencontre normale | 23 (20–27) | 114 (103–126) | 286 (246–321) | 506 (431–586) | 731 (627–843) | 1029 (893–1179) | 1477 (1255–1689) |
| Dégâts par tour (tours 1-3, mannequin) | 30 (16–58) | 86 (41–179) | 180 (76–405) | 335 (148–901) | 479 (208–1487) | 573 (255–1886) | 754 (346–2596) |
| Tours pour vider un combat normal | 1,6 (1,0–2,5) | 3,0 (2,0–5,0) | 3,7 (1,8–6,7) | 3,5 (1,7–6,3) | 3,5 (1,7–6,3) | 3,8 (1,7–6,6) | 3,7 (1,8–6,2) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 45 (39–50) | 86 (76–97) | 112 (99–127) | 126 (110–144) | 154 (135–178) |
| PV perdus par combat normal (sans plancher) | 0 (0–3) | 8 (0–24) | 38 (11–79) | 82 (24–171) | 115 (33–240) | 129 (38–264) | 172 (51–352) |
| PV en fin d’acte (% du max) | 53 (2–92) | 47 (1–95) | 32 (1–89) | 7 (1–42) | 7 (1–48) | 8 (1–58) | 9 (1–74) |
| Quasi-morts (cumul) | 0 (0–1) | 0 (0–14) | 9 (0–58) | 74 (14–195) | 131 (32–320) | 184 (50–419) | 255 (72–559) |
| Cartes trouvées, D31 (cumul) | 6 (4–7) | 17 (14–20) | 28 (25–33) | 45 (40–58) | 56 (51–76) | 68 (61–95) | 86 (77–125) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 8 (4–10) | 12 (8–14) | 14 (10–18) | 18 (12–20) | 22 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 5 (2–9) | 7 (3–11) | 8 (4–14) | 11 (6–17) |
| … dont copie du deck, D46 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 2 (1–4) | 3 (1–5) | 3 (1–6) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–6) | 4 (1–7) | 5 (2–9) |
| Boutiques visitées (cumul) | 0 (0–1) | 1 (0–3) | 2 (1–4) | 3 (1–5) | 4 (2–7) | 5 (3–8) | 6 (4–9) |
| Événements (cumul) | 2 (1–3) | 5 (3–7) | 9 (6–11) | 14 (11–17) | 17 (14–21) | 21 (17–24) | 26 (21–30) |
| Puits visités (cumul) | 0 | 1 | 1 | 2 | 3 | 4 | 5 |
| Échanges au Puits (cumul) | 0 | 1 (0–1) | 1 (0–1) | 2 (1–2) | 3 (2–3) | 4 (3–4) | 5 (4–5) |
| Échanges à l’Autel (cumul) | 0 | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| Reliques échangées, D23 (cumul) | 0 | 0 (0–1) | 1 (0–2) | 1 (0–3) | 2 (0–4) | 2 (0–4) | 3 (1–5) |
| Purges payantes en boutique (cumul) | 0 | 0 | 0 | 0 (0–1) | 1 (0–2) | 1 (0–3) | 3 (1–5) |
| Combats normaux et élites (cumul) | 6 (4–7) | 16 (14–18) | 26 (23–29) | 41 (38–45) | 51 (47–55) | 61 (56–66) | 76 (71–81) |
| … dont élites | 1 (1–2) | 4 (3–5) | 7 (6–8) | 11 (9–13) | 14 (12–16) | 17 (15–19) | 21 (18–24) |
| Combats non finis en 40 tours (cumul) | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A2–A6) · 100 % |
| 1re épique | A10 (A6–A15) · 94 % |
| 1re légendaire | — (A13–—) · 20 % |
| 1re quasi-mort | A5 (A1–A6) · 100 % |
| 1re mythique D42c prise | — (A14–—) · 12 % |

### 2.2. Par classe × lot, à l'acte 15

| Configuration | Deck A15 | Fusions A15 | Meilleur rang A15 | 1re fusion | 1re rare | 1re épique | Σ niveaux A15 | Affûtages A15 | Or en réserve A15 | Niveau A15 | Dégâts / tour A15 | PV ennemi A15 | Tours A15 | Dégâts ennemis / tour A15 | PV perdus / combat A15 | PV % A15 | Quasi-morts A15 | 1re quasi-mort |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Paladin · Rempart | 35 (30–41) | 44 (39–59) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A11 (A6–A15) · 92 % | 73 (56–100) | 4 (2–8) | 6566 (4460–8762) | 30 (26–35) | 565 (365–862) | 572 (463–719) | 4,5 (3,3–6,0) | 158 (138–178) | 185 (84–283) | 7 (1–22) | 266 (166–401) | A6 (A5–A7) · 100 % |
| Paladin · Croisé | 35 (31–41) | 45 (38–61) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % | 78 (57–109) | 5 (2–9) | 6509 (3993–8616) | 30 (26–35) | 883 (587–1566) | 581 (471–740) | 3,3 (2,3–4,3) | 157 (137–180) | 157 (62–252) | 8 (1–48) | 199 (105–303) | A5 (A4–A7) · 100 % |
| Paladin · Sanctifié | 35 (30–41) | 43 (38–63) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A14) · 96 % | 69 (51–93) | 6 (3–10) | 6109 (3367–8323) | 30 (26–35) | 407 (249–663) | 582 (469–727) | 5,8 (4,2–8,0) | 157 (136–182) | 286 (167–440) | 7 (1–24) | 437 (265–631) | A5 (A5–A6) · 100 % |
| Berserker · Sang | 36 (30–41) | 46 (40–64) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A7–A15) · 94 % | 84 (68–112) | 16 (14–18) | 4025 (934–6470) | 31 (27–36) | 4390 (2266–8958) | 583 (479–758) | 1,5 (1,0–2,0) | 158 (138–181) | 47 (0–114) | 14 (1–100) | 63 (25–143) | A2 (A1–A5) · 100 % |
| Berserker · Vampire | 35 (29–41) | 45 (39–60) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A14) · 96 % | 80 (65–107) | 13 (6–16) | 5277 (1990–7736) | 30 (26–36) | 902 (546–1610) | 581 (462–735) | 3,0 (2,0–4,5) | 157 (140–181) | 178 (73–311) | 55 (19–100) | 107 (55–249) | A6 (A4–A7) · 100 % |
| Berserker · Carnage | 35 (30–41) | 45 (39–61) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A3–A6) · 100 % | A10 (A6–A15) · 93 % | 71 (57–98) | 3 (1–11) | 6132 (3452–7972) | 29 (25–34) | 793 (452–1529) | 565 (465–705) | 3,0 (1,8–4,4) | 154 (135–177) | 163 (58–312) | 7 (1–100) | 236 (94–416) | A2 (A1–A4) · 100 % |
| Mage · Voile | 35 (30–43) | 45 (39–61) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A3–A6) · 100 % | A10 (A6–A15) · 95 % | 62 (49–84) | 1 (0–4) | 6215 (4134–8377) | 28 (24–33) | 364 (224–636) | 551 (453–690) | 6,0 (4,0–8,0) | 149 (132–174) | 332 (203–514) | 7 (1–21) | 619 (426–843) | A2 (A1–A4) · 100 % |
| Mage · Marque | 35 (30–42) | 44 (38–61) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A7–A15) · 93 % | 68 (53–93) | 2 (0–5) | 6401 (4097–8391) | 29 (24–34) | 981 (557–1668) | 567 (454–712) | 3,7 (2,8–5,0) | 150 (128–173) | 135 (63–232) | 7 (1–20) | 357 (244–465) | A3 (A2–A5) · 100 % |
| Mage · Arcaniste | 35 (30–41) | 45 (39–60) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A3–A6) · 100 % | A10 (A6–A14) · 95 % | 73 (55–99) | 4 (1–10) | 5866 (3191–7986) | 29 (24–34) | 879 (534–1378) | 554 (452–708) | 3,3 (2,3–4,7) | 151 (131–173) | 134 (48–260) | 10 (1–47) | 214 (107–358) | A4 (A2–A6) · 100 % |
| **Toutes** | 35 (30–41) | 45 (39–61) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % | 73 (55–102) | 5 (1–15) | 5978 (2983–8262) | 30 (25–35) | 754 (346–2596) | 571 (462–726) | 3,7 (1,8–6,2) | 154 (135–178) | 172 (51–352) | 9 (1–74) | 255 (72–559) | A5 (A1–A6) · 100 % |

Les tables complètes par classe × lot, acte par acte, sont en annexe A.

### 2.3. Ce que la référence dit

**La fusion (P3 tient, et vite).** Première fusion à l'acte 1 (A1–A2), première rare à l'acte 4 (A2–A6), première épique à l'acte 10 (A6–A15, 94 %), légendaire dans 20 % des runs. Le meilleur rang médian vaut 2 à l'acte 5 et 3 à l'acte 10. Les neuf configurations fusionnent au même rythme (43 à 46 fusions à l'acte 15) : le pool de 15 cartes est le même pour toutes, et la politique de combat ne touche pas la trouvaille.

**Le deck se régule seul.** 9 cartes à l'acte 1, 20 à l'acte 5, 35 (30–41) à l'acte 15. Entrées cumulées à l'acte 15 : 86 cartes trouvées, 22 clones de boss, 11 achats (dont 4 copies D46), 5 clones du Miroir, plus les 5 de départ ; 45 fusions en retirent 90. L'oubli au feu ne sert presque pas (1 par run) : le feu va d'abord au repos et à l'affûtage.

**Les runes viennent de la fusion, pas du feu.** À l'acte 15, le deck porte 45 runes (38–57) pour 73 niveaux (55–102). Le feu en a donné 5, le boss « XP » 2, l'événement D42b 1 : environ 8 niveaux sur 73. Le reste est la rune neuve de chaque fusion et les niveaux additionnés par D13. La rune la plus haute atteint 9 (4–25) : c'est D13, pas l'affûtage, qui fait les hauts niveaux.

**`eco` et `quick` arrivent entre l'acte 5 et l'acte 8.** Aucune carte n'en porte à l'acte 5 (médiane ; P90 2), 2 à l'acte 8, 5 (3–8) à l'acte 15, sur un deck de 35.

**Le feu de camp est un lit.** 20 visites (17–23) sur 15 actes, soit 1,3 par acte : 14 repos, 5 affûtages, 1 oubli. Jusqu'à l'acte 5, le feu affûte autant qu'il soigne (2 repos, 3 affûtages) ; de l'acte 5 à l'acte 15, il soigne : environ 12 repos pour 2 affûtages.

**L'or déborde.** 9 473 or gagnés, 3 333 dépensés, 5 978 (2 983–8 262) en réserve à l'acte 15. La réserve grossit à chaque acte dès l'acte 3 : l'affûtage manque de visites, pas d'or, et la boutique n'est visitée que 6 fois en 15 actes (0,4 par acte).

**L'XP tient D24.** 2 niveaux par acte (1–3), niveau 10 à l'acte 5, 30 (25–35) à l'acte 15 ; 12 évolutions de signature, soit 3 mineures et 3 majeures par signature, ce que §4.4 annonçait.

**Le tour de dégâts suit les PV ennemis ; les PV du héros ne suivent pas.** Les dégâts d'un tour montent de 30 (acte 1) à 754 (acte 15), les PV d'une rencontre normale de 23 à 1 477 : il faut 3,5 à 3,8 tours pour vider un combat normal de l'acte 5 à l'acte 15, rythme stable. Mais les ennemis frappent 45 par tour à l'acte 5, 86 à l'acte 8, 154 à l'acte 15. Un combat normal coûte 38 PV à l'acte 5, 82 à l'acte 8, 172 à l'acte 15, pour ~100 PV de héros et 1,3 feu par acte. **Première quasi-mort à l'acte 5 (A1–A6) dans 100 % des runs ; PV en fin d'acte de 7 à 9 % du max dès l'acte 8.**

**Par classe.** Le Berserker Sang tape le plus (4 390 par tour à l'acte 15, 1,5 tour par combat), affûte le plus (16) et meurt le moins (63 quasi-morts) : il tue avant d'être tué. Le Mage Voile tape le moins (364, 6 tours par combat) et meurt le plus (619). Le Paladin Sanctifié est lent (5,8 tours) : son lot pose `weakness` et de l'armure qui survit, pas des dégâts.

---

## 3. Les leviers — une table par levier, le reste fixé

Médiane (P10–P90) des 9 configurations × 200 runs, sauf mention. La ligne **(réf.)** est la référence.

### 3.1. Trouvaille — cartes garanties et seconde carte en élite (D31)

| Variante | Deck A5 | Deck A10 | Deck A15 | Fusions A15 | Meilleur rang A15 | 1re fusion | 1re rare | 1re épique | Σ niveaux A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **1 garantie, élite 25 %** (réf.) | 20 (16–24) | 29 (25–34) | 35 (30–41) | 45 (39–61) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % | 73 (55–101) |
| 1 garantie, élite 0 % | 20 (16–23) | 28 (24–33) | 34 (29–41) | 42 (36–59) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A15) · 93 % | 71 (53–101) |
| 1 garantie, élite 50 % | 21 (17–25) | 30 (25–35) | 36 (30–42) | 47 (41–64) | 3 (3–4) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % | 75 (57–103) |
| 2 garanties, élite 25 % | 26 (22–30) | 35 (30–40) | 42 (36–48) | 70 (62–87) | 3 (3–4) | A1 (A1–A1) · 100 % | A3 (A2–A5) · 100 % | A10 (A6–A13) · 98 % | 96 (78–122) |

La chance d'élite ne pèse presque rien : de 0 à 50 %, les fusions de l'acte 15 vont de 42 à 47. La **deuxième carte garantie** change tout : +55 % de fusions (70 contre 45), rare à l'acte 3, 96 niveaux de rune contre 73, deck de 42.

### 3.2. Sources de doublon — la prémisse de D48 (§4.1)

| Variante | Fusions A5 | Fusions A15 | Meilleur rang A10 | Meilleur rang A15 | Deck A15 | 1re fusion | 1re rare | 1re épique |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| **toutes** (réf.) | 11 (8–14) | 45 (39–61) | 3 (2–3) | 3 (3–4) | 35 (30–41) | A1 (A1–A2) · 100 % | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % |
| trouvaille seule (ni boss « cartes », ni achat, ni Miroir) | 7 (5–10) | 31 (25–49) | 2 (1–2) | 2 | 34 (29–40) | A2 (A1–A2) · 100 % | A8 (A5–A12) · 100 % | — (—–—) · 6 % |

Sans boss « cartes », sans achat et sans Miroir, la trouvaille donne encore une rare à l'acte 8 (A5–A12) dans 100 % des runs ; l'épique ne passe plus que dans 6 % des runs. Les sources ciblées font la différence entre le rang 2 et le rang 3, pas entre le rang 1 et le rang 2.

### 3.3. Reliques de trouvaille (D31)

| Variante | Reliques D31 A5 | Reliques D31 A15 | Trouvées A15 | Deck A15 | Fusions A15 | 1re rare | 1re épique |
|:---|---:|---:|---:|---:|---:|---:|---:|
| **A +25 %, B +1 %, dans la réserve** (réf.) | 0 (0–1) | 1 (0–3) | 86 (77–124) | 35 (30–41) | 45 (39–61) | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % |
| A +15 % | 0 (0–1) | 1 (0–3) | 85 (77–124) | 35 (29–41) | 45 (39–60) | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % |
| A +50 % | 0 (0–1) | 1 (0–3) | 87 (78–126) | 35 (30–42) | 45 (39–61) | A4 (A2–A6) · 100 % | A10 (A6–A14) · 95 % |
| B +2 % par exemplaire | 0 (0–1) | 1 (0–3) | 86 (77–125) | 35 (29–42) | 45 (39–61) | A4 (A2–A6) · 100 % | A10 (A6–A15) · 95 % |
| A, B, C tenues dès l’acte 1 | 3 | 3 | 143 (133–153) | 41 (36–47) | 69 (63–76) | A3 (A2–A5) · 100 % | A10 (A6–A13) · 99 % |
| Reliques absentes | 0 | 0 | 81 (75–88) | 33 (29–38) | 42 (37–47) | A4 (A2–A6) · 100 % | A10 (A6–A15) · 93 % |

Les trois reliques sont trop rares pour peser : 1 exemplaire (0–3) à l'acte 15, parmi 20 reliques. La valeur de A (15, 25 ou 50 %) et celle de B (+1 ou +2 %) ne se voient pas. Tenues dès l'acte 1 (borne haute), elles font 143 cartes trouvées au lieu de 86 : l'écart, 57, est celui d'une carte de plus par combat normal — c'est C, la carte garantie de plus, qui le porte. Le levier de D31 est la rareté de C, pas les pourcentages.

### 3.4. Pool du Miroir (Q3)

| Variante | Clones Miroir A15 | Fusions A15 | Meilleur rang A15 | 1re rare | 1re épique | Budget A15 | Dégâts / tour A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| **mythique** (réf.) | 5 (2–9) | 45 (39–61) | 3 (3–4) | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % | 830 (751–913) | 758 (350–2551) |
| `draft` | 16 (11–21) | 49 (43–66) | 4 (3–4) | A3 (A2–A5) · 100 % | A7 (A5–A11) · 99 % | 756 (697–827) | 550 (247–1854) |

En `draft`, le Miroir triple les clones (16 contre 5), avance l'épique de trois actes (A7, 99 %) — et coûte 27 % des dégâts à l'acte 15 (550 contre 758), parce que chaque clone prend la place d'une stat, de Puissance le plus souvent. Le budget ennemi baisse d'autant (756 contre 830). C'est un vrai choix pour le joueur ; la simulation ne dit pas lequel est le bon, seulement ce qu'il coûte.

### 3.5. Échange 3 → 1 (§1 « Plus tard », Q4)

| Variante | Deck A5 | Deck A10 | Deck A15 | Échanges 3→1 A15 | Fusions A15 | Meilleur rang A15 | 1re rare | 1re épique | Affûtages A15 | Oublis A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| **absent** (réf.) | 20 (16–24) | 29 (25–34) | 35 (30–41) | 0 | 45 (39–61) | 3 (3–4) | A4 (A2–A6) · 100 % | A10 (A6–A15) · 94 % | 5 (1–15) | 1 (0–2) |
| événement | 19 (15–23) | 28 (23–33) | 34 (28–40) | 2 (1–4) | 43 (37–59) | 3 (3–4) | A4 (A2–A6) · 100 % | A9 (A6–A14) · 96 % | 5 (1–15) | 1 (0–2) |
| option du feu de camp | 20 (16–24) | 29 (25–34) | 35 (29–42) | 0 (0–1) | 45 (38–61) | 3 (3–4) | A4 (A2–A6) · 100 % | A10 (A6–A14) · 95 % | 5 (1–15) | 1 (0–2) |

En événement, il sert 2 fois par run et retire une carte ; au feu de camp, il ne sert jamais (0, P90 1), parce que le feu va au repos puis à l'affûtage. Sous la fusion telle qu'elle tourne, il n'est pas un puits nécessaire.

### 3.6. Rythme du Puits (D22)

| Variante | Puits A15 | Échanges Puits A15 | Or dépensé A15 | Or en réserve A15 | Σ niveaux A15 | Niveau max A15 | eco + quick A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| tous les 2 actes | 7 | 7 (6–7) | 3425 (1875–6376) | 5685 (2801–7837) | 73 (55–102) | 10 (4–26) | 5 (3–8) |
| **tous les 3 actes** (réf.) | 5 | 5 (4–5) | 3330 (1745–6297) | 5969 (3030–8229) | 73 (55–101) | 9 (4–25) | 5 (3–8) |
| tous les 4 actes | 3 | 3 | 3285 (1760–6426) | 6293 (3345–8512) | 74 (56–103) | 10 (4–24) | 5 (3–9) |
| aujourd’hui (25 % par carte) | 4 (2–6) | 3 (1–5) | 3300 (1735–6171) | 6198 (3347–8477) | 74 (55–102) | 9 (4–25) | 5 (3–9) |

Le joueur simulé échange à chaque visite. Le Puits ne consomme presque pas d'or (≈ 3 300 dépensés quel que soit son rythme) et ne change pas les niveaux de rune (73-74) : il réoriente des runes, il n'en fabrique pas. La ligne « aujourd'hui » passe par le Puits à chaque fois qu'il existe, ce que le jeu ne force pas.

### 3.7. Rythme de l'Autel (Q16)

| Variante | Autel A15 | Reliques A10 | Reliques A15 | Budget A15 | Reliques D23 A15 |
|:---|---:|---:|---:|---:|---:|
| **aujourd’hui** (réf.) | 1 (0–2) | 14 (10–18) | 20 (16–25) | 830 (751–913) | 3 (1–5) |
| tous les 3 actes (4, 7, 10, 13) | 1 (0–2) | 14 (10–18) | 20 (16–25) | 826 (750–912) | 3 (1–5) |
| absent | 0 | 15 (12–19) | 23 (18–27) | 843 (768–933) | 3 (1–5) |

L'Autel sert une fois par run au plus : il exige trois reliques d'une même rareté. Tous les 3 actes ou selon la règle d'aujourd'hui, le résultat est le même ; sans Autel, le héros garde 3 reliques de plus et le budget ennemi monte de 13.

### 3.8. Coût de base de l'affûtage `b` (D20)

| Variante | Affûtages A5 | Affûtages A10 | Affûtages A15 | Oublis A15 | Σ niveaux A15 | Niveau max A15 | Or en réserve A15 | Or dépensé A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|
| b = 25 | 3 (0–5) | 4 (1–10) | 5 (1–15) | 1 (0–2) | 74 (55–103) | 9 (4–26) | 6395 (4262–8426) | 3050 (1665–4901) |
| **b = 50** (réf.) | 3 (0–5) | 4 (1–10) | 5 (1–15) | 1 (0–2) | 73 (55–101) | 9 (4–25) | 5969 (3030–8229) | 3330 (1745–6297) |
| b = 100 | 2 (0–4) | 3 (0–9) | 4 (1–15) | 1 (0–3) | 72 (55–100) | 9 (4–23) | 5441 (1617–7929) | 3725 (1920–7981) |
| b = 150 | 2 (0–4) | 3 (0–9) | 4 (1–14) | 2 (1–3) | 71 (54–98) | 9 (4–21) | 5089 (990–7715) | 3980 (1920–8704) |

*Affûtages A15, par classe × lot :*

| Configuration | b = 25 | **b = 50** (réf.) | b = 100 | b = 150 |
|:---|---:|---:|---:|---:|
| Paladin · Rempart | 4 (2–8) | 4 (2–8) | 4 (2–7) | 4 (2–7) |
| Paladin · Croisé | 5 (2–9) | 5 (2–8) | 4 (1–8) | 4 (1–8) |
| Paladin · Sanctifié | 6 (3–10) | 6 (3–10) | 6 (2–10) | 5 (2–9) |
| Berserker · Sang | 16 (14–18) | 16 (14–18) | 15 (14–17) | 15 (13–17) |
| Berserker · Vampire | 13 (6–16) | 13 (6–16) | 13 (7–15) | 12 (6–16) |
| Berserker · Carnage | 3 (1–9) | 4 (1–11) | 3 (0–10) | 3 (0–9) |
| Mage · Voile | 1 (0–6) | 1 (0–4) | 1 (0–4) | 1 (0–4) |
| Mage · Marque | 2 (0–5) | 2 (0–5) | 2 (0–5) | 2 (0–5) |
| Mage · Arcaniste | 4 (1–11) | 4 (1–9) | 4 (1–8) | 3 (1–8) |

*Or en réserve A15, par classe × lot :*

| Configuration | b = 25 | **b = 50** (réf.) | b = 100 | b = 150 |
|:---|---:|---:|---:|---:|
| Paladin · Rempart | 6752 (4978–8937) | 6577 (4613–8753) | 6193 (3706–8270) | 5927 (3263–8087) |
| Paladin · Croisé | 6622 (4384–8513) | 6391 (4190–8623) | 6250 (3669–8418) | 6224 (3241–8143) |
| Paladin · Sanctifié | 6646 (4584–8625) | 6019 (3395–8070) | 5397 (2329–7927) | 5099 (1625–7592) |
| Berserker · Sang | 5601 (3389–7612) | 4114 (1282–6470) | 2077 (559–4484) | 1105 (272–3489) |
| Berserker · Vampire | 6359 (3985–8314) | 5226 (2020–7633) | 3305 (524–6963) | 2447 (361–5796) |
| Berserker · Carnage | 6387 (4026–8122) | 6116 (3573–7828) | 5703 (2850–7637) | 5551 (2007–7619) |
| Mage · Voile | 6365 (4585–8329) | 6241 (4089–8377) | 6174 (4070–8322) | 6045 (3572–7911) |
| Mage · Marque | 6336 (4456–8495) | 6414 (4246–8387) | 5844 (3928–8200) | 5941 (3738–8051) |
| Mage · Arcaniste | 6238 (4366–8360) | 5897 (3163–8044) | 5703 (2731–7905) | 4969 (1958–7824) |

De 25 à 150 or, le nombre d'affûtages ne bouge pas (5, 5, 4, 4). Seuls le Sang et le Vampire, qui affûtent à chaque feu, sentent l'or : leur réserve tombe de 4 114 à 1 105 (Sang) quand `b` passe de 50 à 150, sans que leur nombre d'affûtages baisse (16 → 15).

### 3.9. Forme de la courbe d'XP (D24, Q17)

| Variante | Niveaux / acte A1 | Niveaux / acte A5 | Niveaux / acte A15 | Niveau A5 | Niveau A10 | Niveau A15 | Évolutions A15 | PV ennemi A15 | Tours A15 | PV % A15 | Quasi-morts A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| actuelle, 100 × 1,5^(n−1) | 1 (1–2) | 1 (0–1) | 0 | 8 (7–8) | 11 (10–11) | 12 | 4 | 362 (310–431) | 4,8 (2,2–8,0) | 9 (1–50) | 324 (112–609) |
| **table par acte, 2 niv./acte** (réf.) | 1 (1–2) | 2 (1–3) | 2 (1–3) | 10 (8–11) | 20 (16–23) | 30 (25–34) | 12 (10–12) | 567 (461–728) | 3,7 (1,8–6,0) | 9 (1–77) | 255 (74–552) |
| table par acte, 3 niv./acte | 2 (2–3) | 3 (2–4) | 3 (2–4) | 14 (12–18) | 29 (24–35) | 45 (38–54) | 18 (14–20) | 741 (603–939) | 3,0 (1,5–5,5) | 9 (1–100) | 214 (48–510) |
| palier constant (115 XP), calé sur l’acte 1 | 1 (1–2) | 29 (19–43) | 0 | 57 (43–75) | 999 | 999 | 398 | 12537 (10116–16773) | 1,0 (1,0–1,3) | 100 (58–100) | 28 (2–230) |
| palier constant (105 XP), XP sans bonus de niveau | 1 (1–2) | 7 (5–9) | 4 (3–6) | 22 (19–25) | 65 (59–71) | 98 (90–107) | 38 (36–42) | 1402 (1136–1865) | 2,3 (1,2–4,0) | 7 (0–100) | 162 (29–468) |

*Niveau A15, par classe × lot :*

| Configuration | actuelle, 100 × 1,5^(n−1) | **table par acte, 2 niv./acte** (réf.) | table par acte, 3 niv./acte | palier constant (115 XP), calé sur l’acte 1 | palier constant (105 XP), XP sans bonus de niveau |
|:---|---:|---:|---:|---:|---:|
| Paladin · Rempart | 12 | 30 (26–35) | 45 (38–54) | 999 | 98 (89–106) |
| Paladin · Croisé | 12 | 30 (26–35) | 45 (38–54) | 999 | 98 (89–106) |
| Paladin · Sanctifié | 12 | 30 (26–34) | 46 (39–54) | 999 | 98 (91–106) |
| Berserker · Sang | 12 | 31 (27–36) | 49 (41–58) | 999 | 102 (93–109) |
| Berserker · Vampire | 12 | 31 (26–35) | 47 (38–55) | 999 | 100 (93–108) |
| Berserker · Carnage | 12 | 29 (25–34) | 44 (37–51) | 999 | 97 (88–107) |
| Mage · Voile | 12 | 28 (24–33) | 43 (36–52) | 999 | 96 (88–104) |
| Mage · Marque | 12 | 29 (24–34) | 44 (37–53) | 999 | 96 (88–104) |
| Mage · Arcaniste | 12 | 28 (25–34) | 46 (38–53) | 999 | 98 (90–105) |

*Quasi-morts A15, par classe × lot :*

| Configuration | actuelle, 100 × 1,5^(n−1) | **table par acte, 2 niv./acte** (réf.) | table par acte, 3 niv./acte | palier constant (115 XP), calé sur l’acte 1 | palier constant (105 XP), XP sans bonus de niveau |
|:---|---:|---:|---:|---:|---:|
| Paladin · Rempart | 379 (229–517) | 267 (163–417) | 231 (120–342) | 15 (2–33) | 168 (85–254) |
| Paladin · Croisé | 268 (148–403) | 203 (116–306) | 182 (96–277) | 24 (4–51) | 136 (79–216) |
| Paladin · Sanctifié | 497 (305–761) | 426 (265–606) | 391 (257–547) | 85 (32–155) | 338 (202–498) |
| Berserker · Sang | 103 (49–238) | 66 (25–131) | 37 (19–87) | 9 (1–24) | 25 (11–50) |
| Berserker · Vampire | 184 (97–396) | 106 (54–247) | 81 (42–172) | 1 (0–6) | 43 (16–85) |
| Berserker · Carnage | 317 (145–517) | 236 (95–418) | 175 (78–341) | 18 (2–50) | 107 (39–222) |
| Mage · Voile | 613 (419–867) | 623 (431–844) | 599 (413–818) | 242 (151–350) | 533 (382–721) |
| Mage · Marque | 403 (270–538) | 357 (241–474) | 344 (243–458) | 210 (142–272) | 311 (207–406) |
| Mage · Arcaniste | 264 (135–413) | 220 (110–360) | 159 (75–271) | 36 (7–77) | 158 (70–234) |

La table par acte calée pour 2 niveaux par acte :

| Forme | Cible | Valeur calée |
|:---|---:|---:|
| Table par acte (réf.) | 2 niv./acte | 115 · 200 · 310 · 485 · 620 · 800 · 985 · 1170 · 1060 · 1245 · 1455 · 1410 · 1395 · 1465 · 1120 |
| Table par acte | 3 niv./acte | 80 · 150 · 245 · 390 · 520 · 690 · 870 · 980 · 930 · 1075 · 1215 · 1210 · 1145 · 1215 · 915 |
| Palier constant | 2 niv. à l’acte 1 | 115 XP par niveau |
| Palier constant, XP sans bonus de niveau | 2 niv. à l’acte 1 | 105 XP par niveau |

**Le palier constant diverge.** Calé pour 2 niveaux à l'acte 1 (115 XP), il fait gagner 29 niveaux pendant l'acte 5 (niveau 57) et touche le garde-fou de 999 avant l'acte 10. La cause est dans le code d'aujourd'hui : l'ennemi a le niveau du héros (`encounter_system.dart:136-148`) et rapporte 10 % d'XP de plus par niveau (`reward_controller.dart:86`), donc chaque niveau en rapporte plus. Même sans ce bonus d'XP (105 XP), le palier constant accélère encore (7 niveaux par acte à l'acte 5, 98 à l'acte 15) : il y a plus d'ennemis, et plus forts, à chaque acte. **Seule la table par acte tient « au moins 2 niveaux par acte » sans s'emballer.** La courbe actuelle plafonne au niveau 12 (4 évolutions).

La table est calée sur les ennemis et les budgets d'aujourd'hui : elle se recale à chaque changement de l'XP ou du budget ennemi.

### 3.10. Coefficient de la DDA (D47)

| Variante | PlayerPower A5 | PlayerPower A15 | Budget A5 | Budget A10 | Budget A15 | PV rencontre A15 | Tours A15 | Quasi-morts A15 | Or gagné A15 | Niveau A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| actuelle, cartes × 2 | 333 (264–412) | 769 (609–943) | 254 (227–282) | 514 (463–575) | 773 (695–854) | 1362 (1129–1586) | 3,5 (1,7–6,0) | 237 (66–512) | 9030 (7628–10545) | 29 (24–33) |
| Σ rang × 2 | 314 (247–393) | 772 (616–951) | 248 (221–276) | 511 (458–567) | 773 (697–855) | 1366 (1144–1588) | 3,5 (1,7–6,0) | 228 (65–510) | 8936 (7607–10404) | 28 (24–33) |
| **Σ rang × 5** (réf.) | 345 (275–424) | 904 (738–1078) | 258 (230–285) | 542 (488–600) | 830 (751–913) | 1475 (1253–1687) | 3,7 (1,8–6,0) | 255 (74–552) | 9459 (7999–10938) | 30 (25–34) |
| Σ rang × 10 | 393 (318–476) | 1127 (956–1319) | 273 (244–302) | 595 (539–653) | 926 (847–1014) | 1637 (1439–1868) | 3,7 (1,7–6,5) | 287 (81–633) | 10370 (8894–11950) | 32 (27–37) |

*Budget A15, par classe × lot :*

| Configuration | actuelle, cartes × 2 | Σ rang × 2 | **Σ rang × 5** (réf.) | Σ rang × 10 |
|:---|---:|---:|---:|---:|
| Paladin · Rempart | 790 (724–857) | 783 (711–874) | 843 (781–919) | 940 (853–1016) |
| Paladin · Croisé | 777 (716–860) | 781 (714–853) | 841 (764–912) | 937 (860–1018) |
| Paladin · Sanctifié | 786 (708–858) | 784 (716–854) | 836 (773–923) | 936 (860–1029) |
| Berserker · Sang | 794 (720–886) | 794 (721–887) | 851 (782–932) | 946 (884–1029) |
| Berserker · Vampire | 780 (702–860) | 779 (709–867) | 840 (759–918) | 930 (856–1021) |
| Berserker · Carnage | 766 (694–843) | 765 (699–845) | 824 (747–907) | 917 (853–1003) |
| Mage · Voile | 755 (675–829) | 761 (685–841) | 805 (724–885) | 901 (823–994) |
| Mage · Marque | 749 (678–835) | 753 (670–829) | 814 (734–899) | 916 (821–1009) |
| Mage · Arcaniste | 754 (681–834) | 752 (676–830) | 810 (730–890) | 904 (836–996) |

*Tours A15, par classe × lot :*

| Configuration | actuelle, cartes × 2 | Σ rang × 2 | **Σ rang × 5** (réf.) | Σ rang × 10 |
|:---|---:|---:|---:|---:|
| Paladin · Rempart | 4,3 (3,0–5,8) | 4,5 (3,3–6,0) | 4,5 (3,3–6,0) | 5,0 (3,5–6,3) |
| Paladin · Croisé | 3,3 (2,3–4,3) | 3,3 (2,3–4,3) | 3,3 (2,3–4,5) | 3,3 (2,5–4,3) |
| Paladin · Sanctifié | 5,5 (4,0–7,5) | 5,7 (4,0–8,0) | 5,8 (4,3–8,0) | 5,7 (4,2–8,0) |
| Berserker · Sang | 1,5 (1,0–2,0) | 1,5 (1,0–2,0) | 1,5 (1,0–2,0) | 1,5 (1,0–2,0) |
| Berserker · Vampire | 3,0 (2,0–4,5) | 3,0 (2,0–4,3) | 3,0 (2,0–4,5) | 3,0 (2,0–5,0) |
| Berserker · Carnage | 3,0 (1,7–4,3) | 3,0 (1,7–4,3) | 3,0 (1,7–4,5) | 2,7 (1,7–4,3) |
| Mage · Voile | 5,6 (4,0–7,3) | 5,5 (4,0–7,5) | 6,0 (4,2–7,8) | 6,0 (4,3–8,3) |
| Mage · Marque | 3,5 (2,7–5,0) | 3,5 (2,7–4,8) | 3,7 (3,0–5,0) | 4,0 (3,0–5,0) |
| Mage · Arcaniste | 3,3 (2,3–4,7) | 3,0 (2,0–4,5) | 3,3 (2,3–4,7) | 3,3 (2,2–4,7) |

**k = 2 reproduit la courbe d'aujourd'hui** (budget 773 à l'acte 15 dans les deux cas, 248 contre 254 à l'acte 5). k = 5 monte le budget de 7 %, k = 10 de 20 % ; à k = 10, les rencontres de l'acte 15 font 1 637 PV au lieu de 1 362, et les quasi-morts passent de 237 à 287. Plus d'ennemis rapportent aussi plus d'or et d'XP (10 370 or contre 9 030). Le deck ne gonflant pas (§2.3), l'ancienne pénalité de taille ne coûtait presque rien.

### 3.11. Tirage des mythiques — la chance de D42(c) (D51)

| Variante | D42c offerte A15 | D42c prise A15 | 1re mythique D42c prise | eco + quick A15 |
|:---|---:|---:|---:|---:|
| **un jet par mythique, comme le code** (réf.) | 0 (0–1) | 0 (0–1) | — (A15–—) · 11 % | 5 (3–8) |
| le pool sort à 0,5 %, puis une mythique (lecture de D51) | 0 | 0 | — (—–—) · 3 % | 5 (3–8) |

Avec le tirage du code — un jet de 0,5 % par récompense mythique et par niveau (`level_up_reward_service.dart:127-145`) —, la mythique de D42(c) est prise dans **11 % des runs** avant l'acte 15, soit environ une sur neuf. « Une run sur 25-30 » (D51) suppose un autre tirage : le pool mythique sort une fois à 0,5 %, puis une mythique est tirée parmi quatre. Ce tirage donne 3 % des runs.

### 3.12. Budget de Puissance des cartes à 0 mana (Q21, D38)

Configurations : Paladin · Rempart, Berserker · Sang, Berserker · Vampire.

| Variante | Dégâts / tour A5 | Dégâts / tour A10 | Dégâts / tour A15 | Tours A15 | PV perdus / combat A15 | Quasi-morts A15 |
|:---|---:|---:|---:|---:|---:|---:|
| **≤ coût + 1, D38 tel qu’écrit** (réf.) | 192 (97–622) | 578 (263–3016) | 957 (468–5588) | 3,0 (1,3–5,0) | 132 (28–280) | 124 (42–327) |
| ≤ max(coût, 0,5) | 189 (97–642) | 572 (245–2950) | 913 (416–5710) | 3,0 (1,3–5,4) | 135 (29–284) | 131 (45–349) |

*Dégâts / tour A10, par classe × lot :*

| Configuration | **≤ coût + 1, D38 tel qu’écrit** (réf.) | ≤ max(coût, 0,5) |
|:---|---:|---:|
| Paladin · Rempart | 332 (209–559) | 337 (194–561) |
| Berserker · Sang | 2316 (1214–4592) | 2268 (1080–4087) |
| Berserker · Vampire | 541 (304–893) | 535 (279–886) |

*Dégâts / tour A15, par classe × lot :*

| Configuration | **≤ coût + 1, D38 tel qu’écrit** (réf.) | ≤ max(coût, 0,5) |
|:---|---:|---:|
| Paladin · Rempart | 569 (375–850) | 543 (337–832) |
| Berserker · Sang | 4401 (2266–8544) | 4320 (2242–8894) |
| Berserker · Vampire | 919 (551–1581) | 891 (486–1624) |

Borner la Puissance d'une carte à 0 mana à la moitié (`≤ max(coût, 0,5)`) retire 2 à 5 % des dégâts d'un tour, sur les trois lots qui en portent (*Percée*, *Sang versé*, *Lacération*). Le « + 1 » de D38 ne crée pas d'écart mesurable.

### 3.13. `minFusionRank` d'`eco` et `quick` (D48)

| Variante | eco + quick A10 | eco + quick A15 | Runes A15 | Dégâts / tour A15 | Tours A15 |
|:---|---:|---:|---:|---:|---:|
| **2, la rare** (réf.) | 3 (1–5) | 5 (3–8) | 45 (38–57) | 758 (350–2551) | 3,7 (1,8–6,0) |
| 3, l’épique | 0 (0–1) | 1 (0–3) | 45 (38–57) | 717 (321–2658) | 3,8 (1,8–6,7) |

Au rang 2, 5 cartes du deck portent `eco` ou `quick` à l'acte 15 ; au rang 3, une seule. L'écart de dégâts est de 5 %.

### 3.14. Table des `maxLevel` (§8, D27)

| Variante | Σ niveaux A15 | Niveau max A15 | Affûtages A15 | Oublis A15 | Or en réserve A15 | Dégâts / tour A15 |
|:---|---:|---:|---:|---:|---:|---:|
| **table du §8** (réf.) | 73 (55–101) | 9 (4–25) | 5 (1–15) | 1 (0–2) | 5969 (3030–8229) | 758 (350–2551) |
| sans plafond (sauf binaires) | 77 (58–115) | 10 (5–26) | 5 (1–15) | 1 (0–2) | 5905 (3525–8048) | 815 (361–3983) |
| plafond 5 partout | 68 (54–90) | 5 | 5 (1–15) | 1 (0–2) | 6363 (4486–8328) | 752 (341–2389) |

Sans plafond, les niveaux de rune montent de 5 % et les dégâts de 8 % ; au plafond 5 partout, les niveaux baissent de 7 % sans perte de dégâts mesurable. Les plafonds du §8 mordent peu : les niveaux sont bornés par les visites et par D13.

### 3.15. Ordre d'affûtage — pour information (§4.2, D32)

| Variante | Σ niveaux A15 | Niveau max A15 | Affûtages A15 | Or dépensé A15 | Or en réserve A15 | Dégâts / tour A15 |
|:---|---:|---:|---:|---:|---:|---:|
| **concentrer** (réf.) | 73 (55–101) | 9 (4–25) | 5 (1–15) | 3330 (1745–6297) | 5969 (3030–8229) | 758 (350–2551) |
| affûter avant de fusionner | 71 (53–98) | 7 (4–20) | 4 (1–14) | 2913 (1665–4656) | 6535 (4449–8484) | 738 (348–2354) |

« Affûter avant de fusionner » ne rapporte rien ici : un affûtage de moins (4 contre 5 ; les cartes d'une paire n'ont pas toujours de rune), niveau max plus bas (7 contre 9), 400 or de moins dépensés sur une réserve qui n'en manque pas. Le pari de §4.2 existe en or ; l'or ne manquant jamais, il n'a pas d'enjeu.

### 3.16. Bénédiction à `threshold: 3` — Sanctifié seul (D43)

Configurations : Paladin · Sanctifié.

| Variante | PV % A5 | PV % A15 | Repos A15 | Affûtages A15 | Quasi-morts A15 |
|:---|---:|---:|---:|---:|---:|
| **tranche de 5** (réf.) | 51 (8–100) | 8 (1–24) | 11 (7–17) | 6 (3–10) | 426 (265–606) |
| `threshold: 3`, plancher 2 | 43 (6–98) | 7 (1–24) | 14 (10–17) | 4 (2–7) | 450 (291–678) |

La proposition du designer (seuil 3, Maîtrise sur le seuil, plancher 2) fait **moins bien** que la tranche de 5 d'aujourd'hui : PV à 43 % contre 51 % à l'acte 5, 450 quasi-morts contre 426. Dès que l'Affinité monte la Maîtrise, le seuil bute sur son plancher de 2, alors que la valeur par tranche, elle, aurait continué de monter.

---

## 4. Valeurs recommandées pour la spec

| Levier | Valeur | La mesure qui la justifie | Ce qui casse si on s'en écarte |
|:---|:---|:---|:---|
| Cartes garanties après un combat normal (D31) | **1** | Rare à l'acte 4, épique à l'acte 10 (94 %), deck de 35 à l'acte 15 | 2 : +55 % de fusions (70), 96 niveaux de rune, deck de 42 — l'arbre de fusion est déjà vu en 15 actes, il le serait trop tôt |
| Seconde carte en élite (D31) | **25 %** | De 0 à 50 %, 42 à 47 fusions à l'acte 15 | Rien de mesurable : le curseur est libre |
| Relique A (D31) | **+25 %**, rare | 15, 25 ou 50 % : 85 à 87 cartes trouvées | Rien : A est trop rare pour peser |
| Relique B (D31) | **À revoir** : +1 % par exemplaire est invisible | +1 et +2 % : 86 cartes trouvées, comme sans | La valeur qui se voit n'a pas été mesurée au-delà de 2 % |
| Relique C (D31) | **Rare au moins** | Tenues dès l'acte 1 : 143 cartes trouvées au lieu de 86 — C porte cet effet | Commune ou peu commune, C ferait de la « deuxième carte garantie » une trouvaille fréquente |
| Pool du Miroir (Q3) | **Mythique** (inchangé) | La profondeur n'est pas rare (rare à l'acte 4 sans lui) | `draft` : épique à l'acte 7, mais −27 % de dégâts à l'acte 15 — le Miroir devient le choix par défaut contre la Puissance |
| Échange 3 → 1 (§1 « Plus tard », D52) | **P-16, comme D52** | Événement : 2 échanges par run ; au feu : 0 | Aucun gain mesuré ; au feu, il n'est jamais choisi |
| Puits (D22) | **Tous les 3 actes**, base 50 | 5 visites, 5 échanges ; niveaux de rune inchangés (73) | Tous les 2 actes : 7 échanges, sans effet sur l'or ni les niveaux — le rythme est un choix de variété, pas d'économie |
| Autel (Q16) | **Rythme d'aujourd'hui** | 1 usage par run, quel que soit le rythme | Le rythme ne change rien : c'est la règle des trois reliques de même rareté qui le borne |
| `b` d'affûtage (D20) | **50** | De 25 à 150 : 4 à 5 affûtages, réserve de 5 000 à 6 400 or | Au-dessus de 150, à mesurer : c'est là que l'or deviendrait une contrainte, pour le Sang d'abord (réserve 1 105 à `b` = 150) |
| Courbe d'XP (D24, Q17) | **Table par acte**, calée pour 2 niveaux par acte : 115 · 200 · 310 · 485 · 620 · 800 · 985 · 1170 · 1060 · 1245 · 1455 · 1410 · 1395 · 1465 · 1120 *(à k = 5 — recalée à k = 2 en §7, D67)* | 2 niveaux par acte (1–3), niveau 30 et 12 évolutions à l'acte 15 | Palier constant : diverge (niveau 999 avant l'acte 10). 3 niveaux par acte : niveau 45, 18 évolutions — les pools d'évolution de §4.4 s'épuisent plus tôt |
| DDA (D47) | **k = 2** | Budget à l'acte 15 : 773, comme la formule d'aujourd'hui *(relance à k = 2 : 786 contre 783, §7)* | k = 5 : +7 % ; k = 10 : +20 % de budget et 287 quasi-morts au lieu de 237 |
| `minFusionRank` d'`eco` et `quick` (D48) | **2** tient | 5 cartes sur 35 portent l'une ou l'autre à l'acte 15 | 3 : une seule à l'acte 15, les deux runes sortent presque du jeu |
| Tirage des mythiques (D42c, D51) | **À trancher** | Code : 11 % des runs ; « pool puis tirage » : 3 % | Garder le code et dire « une run sur neuf », ou changer le tirage pour tenir D51 |
| Budget de Puissance (Q21, D38) | **≤ coût + 1**, tel qu'écrit | Borne à 0,5 : −2 à −5 % de dégâts | Rien de mesurable |
| Table `maxLevel` (§8) | **Telle quelle** | Niveaux 73, max 9 | Sans plafond : +8 % de dégâts ; plafond 5 : −7 % de niveaux |
| Bénédiction (D43) | **Tranche de 5**, Maîtrise sur la valeur — le plancher de D43 ne mord alors que sur Flux de Mana | Seuil 3 : PV 43 % contre 51 % à l'acte 5 | Le seuil 3 plafonne Bénédiction dès que l'Affinité monte |

---

## 5. Ce que la simulation ne dit pas

- **Si le héros survit.** Il n'y a pas de mort : les PV restent au moins à 1, et chaque passage à 0 est compté (quasi-morts). Dans ce modèle, la première quasi-mort arrive à l'acte 5 et les PV restent sous 10 % du max dès l'acte 8. **Tout ce qui suit l'acte 5 décrit donc un héros que le jeu aurait tué** : les 14 repos sur 20 feux, les 5 affûtages, la réserve d'or en découlent. Le modèle est-il trop dur ? Il n'a ni joueur ni intentions détaillées ; mais la pente est celle du code — PV ennemis ×1,35 et dégâts ×1,25 tous les 2 actes, un ennemi de plus par acte jusqu'à 5, et un niveau ennemi qui suit le niveau du héros sous D24. À mesurer en jeu, et à router vers la difficulté (hors chantier E).
- **Le moteur de combat.** L'IA est gloutonne et ses poids sont des choix de politique. Les statuts booléens valent un multiplicateur moyen ; `freeze` vieillit après l'attaque qu'il réduit. Les reliques à charges (Kunaï, Shuriken, Plume, Encensoir) sont ignorées. Le « tour de dégâts » compte l'AoE sur chaque ennemi d'un mannequin : c'est un ordre de grandeur, pas un DPS.
- **Les cartes.** Les lots n'existent pas encore : ce sont les exemples du §7 et des cartes génériques. Le classement des lots (Sang devant, Voile derrière) dépend de ces valeurs, pas seulement des passifs.
- **Le joueur.** Les politiques sont fixes : pas d'apprentissage, pas de routage vers la boutique (0,4 par acte), passage forcé par le Puits. Un joueur qui chasse la boutique ou fuit les élites aurait d'autres chiffres de doublons et d'or.
- **Les évolutions de signature** sont comptées, pas jouées : leurs effets sur les dégâts n'entrent pas dans le tour.
- **Les valeurs de D23, D29 et D42b** sont des défauts (§1.2), pas des mesures ; leurs effets observés sont petits (1 fusion D29, 3 reliques échangées, 1 niveau de rune par run).
- **Au-delà de l'acte 15**, rien.

---

## 6. Les décisions que les chiffres contredisent

Signalées, pas modifiées par ce rapport. **Arbitrées par le propriétaire le 30/09 au soir** : les six lignes et les valeurs recommandées de §4 sont reportées dans le brainstorm en **D56 à D64** (§1), qui est la seule source des décisions — ce tableau reste la mesure qui les a motivées.

| # | Décision ou prémisse | Ce qu'elle dit | Ce que la simulation mesure |
|:---:|:---|:---|:---|
| 1 | **D52** et §4.1 (« conséquence de D31 ») | « Sous D31 le deck atteint ~100 cartes à l'acte 15 et l'oubli ne suit pas — E ne se livre pas sans un puits » | 35 cartes (30–41) à l'acte 15 : la fusion est le puits, 45 fusions absorbent 90 cartes. L'événement de fusion sert 1 fois par run, l'échange 3 → 1 2 fois. D52 peut rester pour d'autres raisons ; sa prémisse ne tient pas |
| 2 | **D48** et §4.1 (« la trouvaille seule fusionne peu ») | « Neuf copies d'une même carte n'arrivent que vers l'acte 23 par la trouvaille seule, atteindre la rare est déjà un effort » ; « un rang 1 vers l'acte 8, un rang 2 vers l'acte 23 » | Pour une carte quelconque : trouvaille seule, 1re fusion à l'acte 2, 1re rare à l'acte 8 (100 %) ; toutes sources, 1re rare à l'acte 4. La valeur de D48 (rang 2) tient ; son motif, non : la rare n'est pas un effort |
| 3 | §4.2, point 1 (et revue R2) | « ~24 niveaux d'affûtage au total par le feu sur 15 actes » ; « ~1 niveau d'affûtage par acte » | 5 (1–15) affûtages par run ; 16 pour le Sang, qui ne se repose jamais. Le repos prend 14 des 20 visites |
| 4 | **D51** | D42(c) : « une run sur 25-30 » | 11 % des runs (≈ une sur neuf) avec le tirage du code ; 3 % seulement si le pool mythique sort une fois, puis une mythique est tirée |
| 5 | **D31** (valeur de B) | « +1 % *(cumulatif par exemplaire)* de seconde carte en combat normal et de troisième en élite » | Aucun effet mesurable, à +1 comme à +2 % (86 cartes trouvées) : la relique est rare, et 1 % l'est plus encore |
| 6 | §4.1, table des nœuds | « ~4,6 combats, ~1,3 élite, ~1,6 feu de camp » par acte | 3,7 combats, 1,4 élite, 1,3 feu, 1,7 événement, 0,4 boutique — sous la politique « événement d'abord » ; le chiffre dépend du chemin choisi |

Deux résultats ne contredisent pas une décision mais répondent à une question ouverte : **Q17** (seule la table par acte tient D24, §3.9) et **Q21** (le « + 1 » de D38 n'a pas d'effet mesurable, §3.12). Un troisième est à router hors du brainstorm : **la survie** (§5, premier point).

---

## 7. Relance à k = 2 — 30/09, soir

**Pourquoi.** La table d'XP de §3.9 avait été calée avec le défaut du script, k = 5 (`Params.ddaK`), et D59 a retenu k = 2 : sous ce coefficient, la même table donnait 28 (24–33) à l'acte 15, soit 1,9 niveau par acte, sous D24 (revue §12, T1). Le défaut du script est passé à 2, la variante « Σ rang × 5 » remplace « Σ rang × 2 » dans le levier de la DDA, et tout a été relancé — calibration, référence, seize leviers, mêmes graines, 557 s. **Les §2 à §4 restent la première passe à k = 5** ; ce qui suit est ce que la relance change. **Aucune conclusion ne bouge** ; la table recalée est **D67**, et les chiffres de référence que le brainstorm cite (§4.1, §4.2, §11) sont désormais ceux-ci.

### 7.1. La table recalée

| Forme | Cible | k = 5 (§3.9) | k = 2 (D67) |
|:---|---:|:---|:---|
| Table par acte (réf.) | 2 niv./acte | 115 · 200 · 310 · 485 · 620 · 800 · 985 · 1170 · 1060 · 1245 · 1455 · 1410 · 1395 · 1465 · 1120 | **115 · 200 · 310 · 480 · 590 · 775 · 955 · 1100 · 1040 · 1185 · 1370 · 1370 · 1300 · 1375 · 1015** |
| Table par acte | 3 niv./acte | 80 · 150 · 245 · 390 · 520 · 690 · 870 · 980 · 930 · 1075 · 1215 · 1210 · 1145 · 1215 · 915 | 80 · 150 · 245 · 390 · 515 · 670 · 835 · 940 · 905 · 1030 · 1155 · 1095 · 1095 · 1170 · 835 |
| Palier constant | 2 niv. à l'acte 1 | 115 XP par niveau | 115 |
| Palier constant, XP sans bonus de niveau | 2 niv. à l'acte 1 | 105 XP par niveau | 105 |

Les paliers baissent de 0 à 8 % à partir de l'acte 4 : un budget ennemi plus bas rapporte moins d'XP. Au-delà de l'acte 15, le script répète la dernière valeur (`xpTable[min(act, length) − 1]`) : une convention, pas une mesure — à re-caler si la run cible s'allonge.

### 7.2. La référence, k = 5 → k = 2

Médiane (P10–P90) de 2 700 runs, fin d'acte 15.

| Mesure | k = 5 (§2.1) | k = 2 |
|:---|---:|---:|
| Taille du deck | 35 (30–41) | 35 (30–41) |
| Fusions de 3 copies | 45 (39–61) | 45 (39–61) |
| 1re rare · 1re épique · 1re légendaire | A4 · 100 % · A10 · 94 % · 20 % | A4 · 100 % · A10 · 94 % · 19 % |
| Niveaux de rune, somme · max | 73 (55–102) · 9 (4–25) | 73 (54–101) · 9 (4–24) |
| Feu : visites · repos · affûtages · oublis | 20 · 14 · 5 · 1 | 20 · 14 · 5 · 1 |
| Or gagné · dépensé · en réserve | 9 473 · 3 333 · 5 978 (2 983–8 262) | 9 100 · 3 358 · 5 596 (2 907–7 763) |
| Niveau du héros A5 · A15 | 10 (8–12) · 30 (25–35) | 10 (8–12) · 30 (25–35) |
| Évolutions de signature | 12 (10–14) | 12 (10–14) |
| PlayerPower · budget d'un combat normal | 907 · 831 | 793 · 787 |
| PV d'une rencontre normale | 1 477 | 1 400 |
| Dégâts par tour · tours par combat | 754 · 3,7 | 752 · 3,5 |
| Dégâts ennemis par tour · PV perdus par combat | 154 · 172 | 146 · 150 |
| Quasi-morts (cumul) · 1re quasi-mort | 255 (72–559) · A5 · 100 % | 233 (67–502) · A5 · 100 % |
| PV en fin d'acte 8 · 15 (% du max) | 7 · 9 | 7 · 9 |
| Mythique D42c prise avant l'acte 15 | 12 % (§2.1), 11 % (§3.11) | 12 % |

L'économie de deck ne bouge pas : trouvaille, fusion, runes et feu ne lisent pas la DDA. Le budget ennemi baisse de 5 %, l'or gagné de 4 %, les quasi-morts de 9 % ; la survie cède toujours à l'acte 5.

### 7.3. Les leviers — tout tient

| Levier | k = 5 | k = 2 | Conclusion |
|:---|:---|:---|:---|
| Trouvaille (§3.1) | 2 garanties : 70 fusions, +55 % | 70, +55 % | Tient — D57 |
| Sources de doublon (§3.2) | trouvaille seule : rare A8, épique 6 % | rare A8, épique 7 % | Tient — D48 |
| Reliques (§3.3) | A et B invisibles ; C : +57 cartes | idem ; +57 | Tient — D57 |
| Miroir (§3.4) | `draft` : épique A7, dégâts −27 % | épique A7, −28 % | Tient — mythique |
| Échange 3 → 1 (§3.5) | événement 2, feu 0 | 2, 0 | Tient — P-16 |
| Puits (§3.6) | ≈ 3 300 or quel que soit le rythme | ≈ 3 300-3 400 | Tient — D22 |
| Autel (§3.7) | 1 usage par run | 1 | Tient |
| `b` (§3.8) | affûtages 5 · 5 · 4 · 4 ; Sang 4 114 → 1 105 | 5 · 5 · 5 · 4 ; Sang 3 824 → 1 056 | Tient — `b` = 50 |
| Courbe d'XP (§3.9) | palier constant : 999 ; actuelle : 12 | 999 ; 12 | Tient — D58, D67 |
| DDA (§3.10) | k = 2 : 773, actuelle 773 ; k = 5 : +7 % ; k = 10 : +20 % | 786 contre 783 ; +7 % ; +20 % | Tient — D59 |
| Mythiques (§3.11) | 11 % contre 3 % | 12 % contre 3 % | Tient — D62, « une run sur huit à neuf » |
| Puissance à 0 mana (§3.12) | borne 0,5 : −2 à −5 % | −2 à −11 % selon l'acte et le lot, +8 % pour le Sang à l'acte 10 | Tient — du bruit, D38 telle qu'écrite |
| `minFusionRank` (§3.13) | rang 3 : 1 carte contre 5, −5 % de dégâts | 1 contre 5, −6 % | Tient — D48 |
| `maxLevel` (§3.14) | sans plafond +8 % de dégâts ; plafond 5 : −7 % de niveaux | +5 % ; −5 % | Tient |
| Ordre d'affûtage (§3.15) | 4 contre 5, max 7 contre 9, −400 or | 4 contre 5, 7 contre 9, −455 or | Tient — D32 |
| Bénédiction (§3.16) | seuil 3 : PV 43 contre 51 %, 450 contre 426 quasi-morts | 36 contre 49 %, 416 contre 388 | Tient — D60 |

---

## Annexe A — La référence par classe × lot, acte par acte

Médiane (P10–P90) de 300 runs par configuration, en fin d'acte.

### Paladin · Rempart

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–10) | 15 (12–18) | 20 (16–24) | 26 (22–30) | 29 (25–34) | 32 (27–37) | 35 (30–41) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (3–7) | 11 (8–14) | 20 (16–25) | 27 (22–32) | 33 (28–41) | 44 (39–59) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–3) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–3) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 6 (4–8) | 12 (9–15) | 21 (17–27) | 27 (23–34) | 34 (28–42) | 44 (37–54) |
| Niveaux de rune, somme | 2 (0–3) | 9 (6–12) | 18 (14–25) | 32 (25–44) | 42 (33–60) | 54 (41–76) | 73 (56–100) |
| Niveau de rune, max | 1 (0–2) | 3 (2–4) | 5 (3–8) | 7 (4–13) | 8 (4–17) | 9 (5–21) | 11 (6–30) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 1 (0–2) | 2 (1–4) | 3 (2–5) | 4 (2–7) | 6 (4–9) |
| Visites de feu de camp (cumul) | 1 (1–2) | 3 (3–4) | 6 (5–7) | 10 (9–12) | 13 (11–15) | 16 (14–18) | 20 (18–23) |
| … dont repos | 0 | 0 (0–1) | 1 (0–3) | 5 (2–8) | 8 (4–10) | 10 (6–14) | 14 (10–18) |
| … dont oubli | 1 (0–2) | 1 (0–3) | 1 (0–3) | 1 (1–3) | 1 (1–3) | 1 (1–3) | 1 (1–3) |
| … dont affûtage | 0 (0–1) | 2 (1–3) | 3 (2–5) | 4 (2–6) | 4 (2–7) | 4 (2–8) | 4 (2–8) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 2 (0–4) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–3) |
| Or gagné (cumul) | 111 (72–192) | 584 (452–720) | 1487 (1234–1720) | 3561 (3054–4196) | 5233 (4523–6115) | 7096 (6145–8344) | 9671 (8437–11290) |
| Or dépensé (cumul) | 0 (0–75) | 325 (125–525) | 725 (359–1121) | 1325 (705–2129) | 1760 (984–3088) | 2175 (1300–3809) | 2933 (1815–4919) |
| Or en réserve | 143 (87–235) | 286 (84–558) | 795 (331–1296) | 2274 (1350–3199) | 3403 (1977–4779) | 4815 (2912–6587) | 6566 (4460–8762) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–12) | 16 (13–19) | 20 (17–24) | 24 (21–28) | 30 (26–35) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 8 (6–8) | 8 (8–10) | 12 (10–14) |
| Reliques | 2 (1–3) | 5 (3–7) | 8 (5–10) | 12 (9–15) | 14 (11–17) | 17 (13–21) | 20 (16–25) |
| PlayerPower (DDA) | 151 (145–163) | 250 (210–313) | 362 (302–444) | 531 (443–638) | 643 (537–790) | 750 (627–901) | 930 (786–1099) |
| Budget ennemi d’un combat normal | 43 (40–46) | 148 (136–171) | 264 (240–291) | 438 (396–480) | 553 (503–616) | 667 (608–735) | 843 (777–919) |
| Ennemis par combat normal | 1,0 | 3,0 | 5,0 (4,5–5,0) | 5,0 (4,4–5,5) | 4,7 (4,2–5,0) | 3,5 (3,0–4,0) | 2,6 (2,3–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–27) | 38 (34–42) | 60 (55–67) | 106 (95–115) | 161 (144–180) | 294 (246–366) | 572 (463–719) |
| PV d’une rencontre normale | 23 (20–27) | 115 (103–127) | 293 (261–325) | 522 (443–597) | 750 (652–848) | 1056 (922–1209) | 1492 (1297–1712) |
| Dégâts par tour (tours 1-3, mannequin) | 23 (15–36) | 65 (41–110) | 131 (76–228) | 242 (150–382) | 334 (209–559) | 420 (262–636) | 565 (365–862) |
| Tours pour vider un combat normal | 2,0 (1,5–2,3) | 3,8 (2,6–5,5) | 4,7 (3,0–6,8) | 4,5 (3,0–6,2) | 4,4 (3,0–6,0) | 4,8 (3,5–6,3) | 4,5 (3,3–6,0) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 46 (42–50) | 88 (78–99) | 114 (101–131) | 128 (113–144) | 158 (138–178) |
| PV perdus par combat normal (sans plancher) | 0 | 1 (0–6) | 24 (6–44) | 73 (35–120) | 108 (59–173) | 125 (67–192) | 185 (84–283) |
| PV en fin d’acte (% du max) | 84 (66–100) | 74 (45–100) | 54 (14–98) | 4 (1–17) | 4 (1–15) | 6 (1–19) | 7 (1–22) |
| Quasi-morts (cumul) | 0 | 0 | 0 (0–13) | 62 (22–110) | 125 (65–204) | 184 (103–298) | 266 (166–401) |
| Cartes trouvées, D31 (cumul) | 6 (4–7) | 17 (14–19) | 28 (25–33) | 45 (41–54) | 57 (51–71) | 69 (62–88) | 86 (77–118) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 6 (4–10) | 10 (8–14) | 14 (10–18) | 16 (12–20) | 20 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 4 (2–8) | 7 (3–11) | 8 (4–13) | 11 (6–16) |
| … dont copie du deck, D46 | 0 (0–1) | 1 (0–2) | 1 (0–2) | 2 (1–3) | 3 (1–4) | 3 (1–5) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–3) | 2 (0–4) | 3 (1–6) | 4 (1–7) | 5 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A2–A6) · 100 % |
| 1re épique | A11 (A6–A15) · 92 % |
| 1re légendaire | — (A13–—) · 23 % |
| 1re quasi-mort | A6 (A5–A7) · 100 % |
| 1re mythique D42c prise | — (A14–—) · 12 % |

### Paladin · Croisé

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (12–18) | 20 (16–24) | 26 (22–31) | 29 (25–34) | 32 (27–37) | 35 (31–41) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (4–8) | 11 (8–14) | 20 (16–25) | 27 (23–34) | 34 (28–44) | 45 (38–61) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–3) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–3) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 7 (4–9) | 12 (9–16) | 22 (17–27) | 29 (24–36) | 35 (29–44) | 46 (38–57) |
| Niveaux de rune, somme | 2 (0–4) | 9 (6–14) | 19 (13–26) | 34 (25–47) | 45 (34–62) | 57 (43–80) | 78 (57–109) |
| Niveau de rune, max | 1 (0–2) | 3 (2–5) | 4 (3–8) | 6 (3–13) | 7 (4–19) | 8 (4–24) | 10 (4–29) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 0 (0–2) | 1 (0–3) | 2 (1–4) | 3 (1–5) | 5 (2–7) |
| Visites de feu de camp (cumul) | 1 (1–2) | 3 (3–4) | 6 (5–7) | 10 (9–12) | 13 (11–15) | 16 (14–19) | 20 (18–23) |
| … dont repos | 0 | 0 (0–1) | 2 (0–4) | 6 (3–8) | 8 (5–11) | 11 (7–14) | 14 (9–18) |
| … dont oubli | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 (0–1) | 2 (1–3) | 3 (1–5) | 3 (1–6) | 4 (2–7) | 4 (2–8) | 5 (2–9) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 1 (0–3) |
| Or gagné (cumul) | 98 (70–183) | 568 (461–699) | 1439 (1214–1649) | 3492 (2990–4031) | 5173 (4395–5952) | 7055 (6021–8113) | 9657 (8297–10943) |
| Or dépensé (cumul) | 0 (0–75) | 303 (125–500) | 643 (290–1015) | 1243 (655–2035) | 1770 (945–3101) | 2243 (1263–3760) | 2975 (1727–5233) |
| Or en réserve | 135 (66–217) | 317 (72–552) | 844 (383–1294) | 2280 (1379–3229) | 3432 (2079–4611) | 4740 (2987–6335) | 6509 (3993–8616) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–12) | 16 (13–18) | 20 (17–23) | 24 (20–28) | 30 (26–35) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 8 (6–8) | 8 (8–10) | 12 (10–14) |
| Reliques | 2 (1–3) | 5 (3–7) | 8 (5–10) | 12 (9–15) | 14 (10–18) | 17 (13–21) | 20 (15–24) |
| PlayerPower (DDA) | 153 (146–164) | 257 (218–305) | 369 (300–438) | 535 (444–633) | 650 (530–763) | 762 (626–899) | 925 (785–1092) |
| Budget ennemi d’un combat normal | 43 (40–46) | 152 (139–169) | 266 (240–292) | 437 (398–478) | 553 (499–604) | 667 (606–726) | 841 (772–912) |
| Ennemis par combat normal | 1,0 | 3,0 | 5,0 (4,4–5,0) | 5,0 (4,3–5,5) | 4,7 (4,2–5,3) | 3,6 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–28) | 38 (34–42) | 61 (56–66) | 105 (95–116) | 159 (144–175) | 293 (245–354) | 581 (471–740) |
| PV d’une rencontre normale | 23 (20–28) | 115 (103–126) | 294 (259–327) | 517 (440–607) | 748 (654–846) | 1040 (923–1199) | 1505 (1322–1715) |
| Dégâts par tour (tours 1-3, mannequin) | 34 (21–53) | 125 (84–206) | 273 (174–452) | 460 (292–779) | 618 (410–1027) | 701 (465–1235) | 883 (587–1566) |
| Tours pour vider un combat normal | 2,0 (1,5–2,3) | 2,6 (2,0–3,3) | 2,8 (2,0–4,0) | 2,8 (2,0–3,8) | 3,0 (2,0–4,0) | 3,3 (2,3–4,3) | 3,3 (2,3–4,3) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 46 (41–50) | 88 (78–99) | 114 (102–128) | 128 (113–147) | 157 (137–180) |
| PV perdus par combat normal (sans plancher) | 0 | 2 (0–8) | 24 (9–42) | 62 (29–103) | 94 (46–145) | 110 (51–178) | 157 (62–252) |
| PV en fin d’acte (% du max) | 80 (59–96) | 61 (33–89) | 42 (5–87) | 3 (1–23) | 6 (1–32) | 6 (1–38) | 8 (1–48) |
| Quasi-morts (cumul) | 0 | 0 | 1 (0–15) | 47 (14–93) | 94 (37–157) | 137 (67–223) | 199 (105–303) |
| Cartes trouvées, D31 (cumul) | 6 (4–7) | 17 (15–20) | 28 (25–33) | 45 (41–57) | 56 (51–74) | 68 (61–94) | 86 (77–121) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 6 (4–10) | 12 (8–14) | 14 (10–18) | 18 (12–20) | 22 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 4 (2–9) | 7 (3–12) | 8 (4–15) | 11 (5–19) |
| … dont copie du deck, D46 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 2 (0–4) | 3 (1–5) | 3 (2–6) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–6) | 4 (1–7) | 5 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A2–A6) · 100 % |
| 1re épique | A10 (A6–A15) · 94 % |
| 1re légendaire | — (A14–—) · 17 % |
| 1re quasi-mort | A5 (A4–A7) · 100 % |
| 1re mythique D42c prise | — (A15–—) · 11 % |

### Paladin · Sanctifié

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–10) | 14 (11–17) | 19 (16–23) | 26 (22–30) | 29 (25–34) | 31 (26–37) | 35 (30–41) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (4–8) | 11 (8–14) | 20 (16–25) | 26 (21–34) | 33 (28–44) | 43 (38–63) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–4) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 7 (4–9) | 12 (9–15) | 20 (17–26) | 26 (21–34) | 32 (27–41) | 41 (36–52) |
| Niveaux de rune, somme | 2 (0–3) | 9 (5–13) | 17 (12–24) | 30 (23–43) | 39 (29–54) | 49 (38–71) | 69 (51–93) |
| Niveau de rune, max | 1 (0–2) | 2 (1–4) | 5 (2–8) | 6 (3–12) | 8 (4–16) | 9 (4–24) | 11 (6–30) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 1 (0–3) | 3 (1–5) | 5 (2–7) | 6 (4–9) | 8 (6–11) |
| Visites de feu de camp (cumul) | 1 (1–2) | 3 (3–4) | 6 (5–7) | 10 (8–12) | 13 (11–15) | 16 (14–18) | 20 (17–23) |
| … dont repos | 0 | 0 (0–1) | 1 (0–2) | 5 (1–7) | 7 (3–10) | 9 (5–13) | 12 (7–17) |
| … dont oubli | 1 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| … dont affûtage | 0 | 2 (0–3) | 3 (1–5) | 4 (1–6) | 4 (2–7) | 5 (2–8) | 6 (3–10) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) |
| Or gagné (cumul) | 98 (71–195) | 574 (464–687) | 1447 (1234–1659) | 3519 (3003–4079) | 5190 (4433–5991) | 7065 (6004–8089) | 9729 (8355–11057) |
| Or dépensé (cumul) | 0 (0–50) | 250 (50–475) | 655 (249–1096) | 1305 (605–2226) | 1783 (895–3071) | 2500 (1354–4284) | 3373 (2030–6045) |
| Or en réserve | 138 (84–232) | 343 (108–612) | 824 (311–1315) | 2254 (1207–3192) | 3436 (1940–4655) | 4525 (2430–6242) | 6109 (3367–8323) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–12) | 16 (13–18) | 20 (17–23) | 24 (20–28) | 30 (26–35) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 8 (6–8) | 8 (8–10) | 12 (10–14) |
| Reliques | 2 (1–3) | 5 (3–7) | 8 (5–10) | 12 (9–15) | 14 (10–17) | 17 (13–20) | 20 (16–25) |
| PlayerPower (DDA) | 152 (146–165) | 255 (215–308) | 362 (303–442) | 529 (444–633) | 645 (537–778) | 751 (620–919) | 929 (771–1111) |
| Budget ennemi d’un combat normal | 43 (40–46) | 152 (138–169) | 264 (241–293) | 434 (399–480) | 551 (503–611) | 665 (605–738) | 840 (772–926) |
| Ennemis par combat normal | 1,0 | 3,0 | 5,0 (4,5–5,0) | 5,0 (4,4–5,5) | 4,7 (4,0–5,2) | 3,5 (3,0–4,3) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–27) | 38 (34–42) | 61 (55–66) | 105 (95–115) | 161 (145–178) | 290 (246–354) | 582 (469–727) |
| PV d’une rencontre normale | 23 (20–27) | 114 (103–127) | 297 (261–325) | 513 (446–602) | 746 (644–857) | 1041 (917–1184) | 1504 (1281–1710) |
| Dégâts par tour (tours 1-3, mannequin) | 16 (10–29) | 51 (24–91) | 105 (54–194) | 193 (102–356) | 263 (140–461) | 320 (182–594) | 407 (249–663) |
| Tours pour vider un combat normal | 2,7 (2,0–3,2) | 4,8 (3,0–7,7) | 6,0 (3,3–9,2) | 5,4 (3,4–8,4) | 5,5 (3,5–8,3) | 5,8 (4,0–8,5) | 5,8 (4,2–8,0) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 46 (42–50) | 87 (78–98) | 114 (102–127) | 128 (114–147) | 157 (136–182) |
| PV perdus par combat normal (sans plancher) | 0 | 5 (1–14) | 45 (24–79) | 128 (78–207) | 189 (102–285) | 208 (119–317) | 286 (167–440) |
| PV en fin d’acte (% du max) | 84 (52–100) | 84 (45–100) | 51 (8–99) | 5 (1–18) | 6 (1–16) | 7 (1–29) | 7 (1–24) |
| Quasi-morts (cumul) | 0 | 0 | 3 (0–22) | 107 (49–199) | 212 (112–354) | 310 (173–475) | 437 (265–631) |
| Cartes trouvées, D31 (cumul) | 6 (4–7) | 17 (15–20) | 28 (25–32) | 45 (40–56) | 56 (50–73) | 67 (61–92) | 85 (77–121) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 8 (4–10) | 12 (8–14) | 14 (10–18) | 18 (12–20) | 22 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 5 (2–9) | 7 (2–11) | 8 (4–14) | 11 (6–17) |
| … dont copie du deck, D46 | 0 (0–1) | 0 (0–2) | 1 (0–3) | 2 (0–4) | 3 (1–5) | 3 (1–6) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–6) | 4 (1–7) | 5 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A2–A6) · 100 % |
| 1re épique | A10 (A6–A14) · 96 % |
| 1re légendaire | — (A12–—) · 21 % |
| 1re quasi-mort | A5 (A5–A6) · 100 % |
| 1re mythique D42c prise | — (—–—) · 10 % |

### Berserker · Sang

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (12–19) | 21 (17–24) | 26 (22–31) | 29 (24–34) | 31 (27–37) | 36 (30–41) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (4–8) | 11 (8–14) | 20 (17–27) | 28 (24–38) | 35 (30–48) | 46 (40–64) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–3) | 2 (0–3) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–3) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 6 (5–9) | 12 (9–15) | 22 (18–28) | 29 (24–37) | 36 (30–46) | 46 (39–60) |
| Niveaux de rune, somme | 2 (0–4) | 9 (7–13) | 19 (15–26) | 35 (29–47) | 49 (39–64) | 63 (49–84) | 84 (68–112) |
| Niveau de rune, max | 1 (0–2) | 3 (2–4) | 4 (3–7) | 6 (4–12) | 8 (4–17) | 10 (6–21) | 14 (8–27) |
| Runes `eco` + `quick` dans le deck | 0 | 0 | 0 (0–1) | 1 (0–3) | 2 (1–4) | 3 (1–5) | 5 (3–7) |
| Visites de feu de camp (cumul) | 1 (1–2) | 3 (3–4) | 6 (5–7) | 9 (8–11) | 11 (10–13) | 14 (12–15) | 17 (16–19) |
| … dont repos | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| … dont oubli | 1 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 (0–1) | 2 (1–3) | 4 (3–6) | 8 (6–9) | 10 (9–12) | 12 (11–14) | 16 (14–18) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 2 (0–4) |
| Or gagné (cumul) | 106 (72–184) | 528 (423–626) | 1386 (1162–1617) | 3579 (3060–4188) | 5308 (4566–6153) | 7264 (6195–8312) | 9985 (8527–11574) |
| Or dépensé (cumul) | 0 (0–75) | 350 (150–480) | 748 (425–1071) | 1860 (1147–2636) | 2775 (1802–4096) | 3890 (2683–5685) | 6000 (4100–8384) |
| Or en réserve | 137 (69–222) | 231 (63–483) | 701 (288–1138) | 1734 (815–2857) | 2555 (1030–3932) | 3327 (1339–5141) | 4025 (934–6470) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (9–12) | 16 (14–19) | 20 (18–24) | 25 (21–29) | 31 (27–36) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (2–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 8 (6–8) | 10 (8–10) | 12 (10–14) |
| Reliques | 2 (1–3) | 5 (3–7) | 7 (5–10) | 12 (9–15) | 14 (11–17) | 17 (13–21) | 20 (16–25) |
| PlayerPower (DDA) | 133 (127–145) | 238 (197–290) | 353 (292–431) | 530 (437–639) | 654 (535–765) | 763 (625–893) | 935 (783–1131) |
| Budget ennemi d’un combat normal | 40 (38–43) | 148 (133–163) | 262 (237–292) | 438 (395–483) | 560 (503–609) | 674 (608–735) | 850 (776–935) |
| Ennemis par combat normal | 1,0 | 3,0 | 5,0 (4,3–5,0) | 5,0 (4,4–5,5) | 4,7 (4,2–5,0) | 3,5 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–27) | 38 (35–42) | 61 (56–67) | 106 (96–117) | 162 (147–182) | 297 (250–360) | 583 (479–758) |
| PV d’une rencontre normale | 23 (20–27) | 115 (104–126) | 291 (254–326) | 525 (447–599) | 756 (661–873) | 1055 (921–1202) | 1522 (1270–1727) |
| Dégâts par tour (tours 1-3, mannequin) | 57 (44–108) | 191 (102–358) | 469 (247–939) | 1341 (653–2617) | 2318 (1131–4592) | 2854 (1595–5717) | 4390 (2266–8958) |
| Tours pour vider un combat normal | 1,3 (1,0–1,5) | 1,8 (1,0–2,8) | 1,8 (1,3–3,0) | 1,7 (1,0–2,3) | 1,6 (1,0–2,3) | 1,5 (1,0–2,3) | 1,5 (1,0–2,0) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (20–22) | 46 (41–51) | 88 (78–99) | 116 (103–129) | 130 (115–147) | 158 (138–181) |
| PV perdus par combat normal (sans plancher) | 1 (0–2) | 8 (0–19) | 21 (4–53) | 27 (0–69) | 34 (0–84) | 37 (0–85) | 47 (0–114) |
| PV en fin d’acte (% du max) | 24 (1–50) | 3 (1–54) | 9 (1–62) | 9 (1–53) | 12 (1–81) | 15 (1–100) | 14 (1–100) |
| Quasi-morts (cumul) | 0 (0–1) | 5 (0–15) | 13 (1–46) | 32 (7–86) | 42 (13–107) | 51 (18–122) | 63 (25–143) |
| Cartes trouvées, D31 (cumul) | 6 (5–7) | 18 (15–20) | 29 (26–36) | 47 (42–62) | 58 (52–81) | 70 (64–101) | 89 (80–130) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 8 (4–10) | 12 (8–14) | 14 (10–18) | 18 (12–20) | 22 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–4) | 4 (2–8) | 7 (3–11) | 9 (4–14) | 12 (6–18) |
| … dont copie du deck, D46 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 2 (1–4) | 3 (1–5) | 4 (2–6) | 5 (3–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–5) | 4 (2–7) | 6 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A2–A6) · 100 % |
| 1re épique | A10 (A7–A15) · 94 % |
| 1re légendaire | — (A13–—) · 18 % |
| 1re quasi-mort | A2 (A1–A5) · 100 % |
| 1re mythique D42c prise | — (A13–—) · 14 % |

### Berserker · Vampire

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (12–18) | 20 (16–24) | 25 (21–30) | 29 (24–34) | 31 (26–37) | 35 (29–41) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (4–8) | 11 (8–14) | 20 (16–25) | 27 (23–33) | 34 (29–44) | 45 (39–60) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) | 2 (0–5) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–3) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 7 (5–9) | 13 (9–16) | 22 (18–28) | 29 (24–36) | 36 (31–46) | 46 (40–59) |
| Niveaux de rune, somme | 2 (0–4) | 10 (7–14) | 20 (14–26) | 35 (27–47) | 47 (37–62) | 59 (48–81) | 80 (65–107) |
| Niveau de rune, max | 1 (0–2) | 3 (2–4) | 4 (3–7) | 6 (3–12) | 7 (4–15) | 8 (4–19) | 11 (6–25) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 0 (0–2) | 2 (0–3) | 2 (1–4) | 3 (1–5) | 5 (2–7) |
| Visites de feu de camp (cumul) | 1 (1–2) | 3 (3–5) | 6 (5–7) | 10 (8–12) | 12 (11–14) | 15 (13–17) | 19 (16–22) |
| … dont repos | 0 | 0 (0–2) | 1 (0–4) | 2 (0–7) | 3 (0–9) | 3 (0–11) | 4 (0–13) |
| … dont oubli | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 (0–1) | 2 (1–3) | 4 (2–5) | 6 (3–8) | 8 (4–11) | 10 (5–13) | 13 (6–16) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) | 2 (1–4) |
| Or gagné (cumul) | 100 (69–192) | 557 (446–667) | 1430 (1201–1672) | 3581 (3066–4196) | 5282 (4553–6146) | 7198 (6261–8449) | 9993 (8657–11588) |
| Or dépensé (cumul) | 0 (0–75) | 325 (150–501) | 640 (350–1006) | 1515 (820–2497) | 2245 (1213–3780) | 3165 (1760–5226) | 4798 (2709–8042) |
| Or en réserve | 135 (60–224) | 281 (92–495) | 837 (367–1222) | 2081 (1073–3087) | 3081 (1437–4461) | 4067 (1879–5972) | 5277 (1990–7736) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–12) | 16 (13–19) | 20 (17–23) | 24 (21–28) | 30 (26–36) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) | 2 (2–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 8 (6–8) | 8 (8–10) | 12 (10–14) |
| Reliques | 2 (1–3) | 5 (3–7) | 7 (5–10) | 12 (9–15) | 14 (10–18) | 17 (13–21) | 20 (16–25) |
| PlayerPower (DDA) | 132 (125–143) | 233 (193–291) | 349 (284–423) | 522 (425–622) | 632 (521–748) | 752 (619–870) | 925 (773–1084) |
| Budget ennemi d’un combat normal | 40 (37–43) | 147 (131–164) | 257 (234–286) | 429 (390–478) | 547 (499–602) | 664 (605–724) | 840 (772–916) |
| Ennemis par combat normal | 1,0 | 3,0 | 5,0 (4,3–5,0) | 5,0 (4,3–5,5) | 4,6 (4,2–5,0) | 3,5 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–26) | 38 (34–42) | 61 (55–66) | 104 (95–116) | 160 (145–178) | 298 (251–351) | 581 (462–735) |
| PV d’une rencontre normale | 23 (20–26) | 115 (103–127) | 289 (249–323) | 512 (435–586) | 738 (641–850) | 1046 (914–1183) | 1497 (1293–1712) |
| Dégâts par tour (tours 1-3, mannequin) | 27 (20–39) | 79 (50–116) | 165 (101–262) | 350 (206–578) | 537 (299–919) | 646 (390–1190) | 902 (546–1610) |
| Tours pour vider un combat normal | 1,4 (1,0–1,8) | 3,0 (2,0–4,0) | 3,3 (2,3–5,0) | 3,0 (2,0–4,3) | 2,8 (1,8–4,0) | 3,1 (2,0–4,8) | 3,0 (2,0–4,5) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 45 (40–50) | 87 (77–99) | 113 (101–128) | 129 (113–144) | 157 (140–181) |
| PV perdus par combat normal (sans plancher) | 2 (0–4) | 21 (10–35) | 59 (30–96) | 91 (45–157) | 117 (46–197) | 131 (56–235) | 178 (73–311) |
| PV en fin d’acte (% du max) | 51 (19–76) | 71 (28–100) | 72 (27–100) | 41 (12–99) | 45 (14–100) | 46 (12–100) | 55 (19–100) |
| Quasi-morts (cumul) | 0 | 0 | 0 (0–11) | 21 (5–78) | 45 (18–133) | 70 (31–180) | 107 (55–249) |
| Cartes trouvées, D31 (cumul) | 6 (4–7) | 17 (15–20) | 29 (25–33) | 46 (41–58) | 57 (52–77) | 69 (62–94) | 87 (78–126) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 8 (4–10) | 12 (8–14) | 14 (10–18) | 18 (12–20) | 22 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 5 (1–9) | 6 (3–12) | 8 (4–14) | 11 (5–17) |
| … dont copie du deck, D46 | 0 (0–1) | 1 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–5) | 4 (1–6) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–6) | 4 (1–7) | 5 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A2–A6) · 100 % |
| 1re épique | A10 (A6–A14) · 96 % |
| 1re légendaire | — (A13–—) · 20 % |
| 1re quasi-mort | A6 (A4–A7) · 100 % |
| 1re mythique D42c prise | — (A13–—) · 13 % |

### Berserker · Carnage

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (13–19) | 20 (17–24) | 26 (23–31) | 29 (25–35) | 32 (27–37) | 35 (30–41) |
| Fusions de 3 copies (cumul) | 2 (0–2) | 6 (4–7) | 11 (9–14) | 20 (17–25) | 27 (23–34) | 34 (29–44) | 45 (39–61) |
| Fusions par l’événement D29 (cumul) | 0 | 0 | 0 (0–1) | 0 (0–1) | 0 (0–2) | 0 (0–2) | 1 (0–2) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–3) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 6 (4–8) | 12 (9–16) | 22 (18–27) | 28 (24–35) | 35 (30–45) | 47 (40–60) |
| Niveaux de rune, somme | 2 (0–4) | 8 (5–11) | 16 (12–22) | 30 (23–40) | 41 (31–55) | 53 (41–70) | 71 (57–98) |
| Niveau de rune, max | 1 (0–2) | 2 (1–3) | 3 (2–5) | 4 (3–8) | 4 (3–10) | 5 (3–13) | 6 (4–19) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 0 (0–1) | 1 (0–3) | 2 (1–4) | 3 (1–5) | 4 (2–6) |
| Visites de feu de camp (cumul) | 1 (1–2) | 4 (3–5) | 7 (5–9) | 11 (9–13) | 14 (12–17) | 16 (14–20) | 21 (18–24) |
| … dont repos | 0 (0–1) | 2 (1–4) | 5 (3–7) | 9 (4–11) | 11 (5–14) | 14 (6–17) | 16 (8–21) |
| … dont oubli | 1 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 (0–1) | 0 (0–2) | 1 (0–3) | 1 (0–5) | 2 (0–7) | 2 (0–9) | 3 (1–11) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 2 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–1) | 0 (0–2) | 0 (0–2) | 0 (0–2) | 1 (0–3) |
| Or gagné (cumul) | 100 (71–186) | 505 (409–627) | 1309 (1094–1526) | 3321 (2807–3910) | 4936 (4226–5790) | 6675 (5793–7862) | 9266 (7896–10784) |
| Or dépensé (cumul) | 0 (0–75) | 210 (75–405) | 463 (170–833) | 1040 (495–1933) | 1580 (795–2771) | 2138 (1239–3979) | 3090 (1834–5477) |
| Or en réserve | 135 (74–233) | 339 (131–554) | 887 (462–1283) | 2260 (1368–3179) | 3388 (2066–4475) | 4569 (2745–6132) | 6132 (3452–7972) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 9 (8–11) | 15 (13–18) | 19 (16–22) | 23 (20–27) | 29 (25–34) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 2 (2–4) | 6 (4–6) | 6 (6–8) | 8 (8–10) | 10 (10–12) |
| Reliques | 2 (1–3) | 5 (3–6) | 7 (5–10) | 12 (9–15) | 14 (10–18) | 17 (13–21) | 20 (15–25) |
| PlayerPower (DDA) | 133 (126–147) | 236 (195–282) | 343 (280–415) | 509 (416–609) | 619 (505–750) | 724 (598–876) | 900 (745–1078) |
| Budget ennemi d’un combat normal | 40 (37–43) | 145 (132–161) | 256 (232–282) | 423 (385–468) | 537 (488–597) | 652 (589–720) | 828 (752–913) |
| Ennemis par combat normal | 1,0 | 3,0 | 5,0 (4,3–5,0) | 5,0 (4,4–5,5) | 4,7 (4,2–5,0) | 3,5 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–27) | 38 (34–41) | 60 (54–66) | 103 (93–113) | 157 (141–174) | 290 (244–350) | 565 (465–705) |
| PV d’une rencontre normale | 23 (20–27) | 113 (103–123) | 283 (246–321) | 502 (427–571) | 722 (629–836) | 1012 (881–1172) | 1468 (1239–1632) |
| Dégâts par tour (tours 1-3, mannequin) | 28 (22–36) | 91 (62–136) | 230 (131–356) | 416 (244–723) | 592 (341–1060) | 632 (376–1178) | 793 (452–1529) |
| Tours pour vider un combat normal | 1,5 (1,2–1,8) | 2,3 (1,5–3,0) | 2,0 (1,3–3,0) | 2,0 (1,0–2,8) | 2,0 (1,3–3,0) | 2,6 (1,5–4,0) | 3,0 (1,8–4,4) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–21) | 45 (40–49) | 85 (76–96) | 111 (99–126) | 126 (112–141) | 154 (135–177) |
| PV perdus par combat normal (sans plancher) | 3 (1–4) | 16 (5–28) | 33 (4–60) | 50 (0–104) | 68 (18–135) | 97 (28–201) | 163 (58–312) |
| PV en fin d’acte (% du max) | 25 (1–53) | 3 (1–47) | 7 (1–50) | 5 (1–24) | 7 (1–35) | 7 (1–56) | 7 (1–100) |
| Quasi-morts (cumul) | 0 (0–1) | 10 (0–24) | 30 (4–68) | 82 (25–162) | 124 (47–235) | 174 (69–308) | 236 (94–416) |
| Cartes trouvées, D31 (cumul) | 6 (5–7) | 17 (14–20) | 28 (25–33) | 45 (40–58) | 56 (51–76) | 68 (61–95) | 85 (77–124) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 8 (4–10) | 12 (8–14) | 14 (10–18) | 16 (12–20) | 20 (16–26) |
| Cartes achetées (cumul) | 0 (0–2) | 1 (0–3) | 2 (0–5) | 5 (2–8) | 7 (3–11) | 9 (5–14) | 12 (7–17) |
| … dont copie du deck, D46 | 0 (0–1) | 0 (0–2) | 1 (0–3) | 2 (1–4) | 3 (1–5) | 3 (2–6) | 5 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–6) | 4 (2–7) | 5 (3–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A3–A6) · 100 % |
| 1re épique | A10 (A6–A15) · 93 % |
| 1re légendaire | — (A14–—) · 17 % |
| 1re quasi-mort | A2 (A1–A4) · 100 % |
| 1re mythique D42c prise | — (A13–—) · 13 % |

### Mage · Voile

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (12–18) | 20 (17–24) | 26 (23–31) | 29 (24–34) | 32 (27–37) | 35 (30–43) |
| Fusions de 3 copies (cumul) | 1 (0–3) | 6 (4–8) | 11 (8–14) | 20 (16–25) | 27 (22–36) | 34 (29–46) | 45 (39–61) |
| Fusions par l’événement D29 (cumul) | 0 | 0 | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–2) | 0 (0–2) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–3) | 3 (3–4) |
| Runes portées par le deck | 1 (0–3) | 6 (4–8) | 12 (9–15) | 21 (17–26) | 27 (22–34) | 34 (28–43) | 43 (37–55) |
| Niveaux de rune, somme | 2 (0–3) | 7 (5–11) | 14 (10–20) | 26 (20–36) | 36 (28–49) | 46 (36–63) | 62 (49–84) |
| Niveau de rune, max | 1 (0–1) | 2 (1–3) | 3 (1–6) | 4 (2–7) | 4 (3–10) | 5 (3–11) | 6 (4–18) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 0 (0–2) | 2 (0–4) | 3 (1–5) | 4 (2–6) | 6 (3–8) |
| Visites de feu de camp (cumul) | 1 (1–2) | 4 (3–5) | 7 (5–8) | 11 (9–13) | 14 (12–16) | 17 (14–19) | 21 (18–24) |
| … dont repos | 0 (0–1) | 2 (1–4) | 5 (2–7) | 9 (6–11) | 11 (8–14) | 14 (11–17) | 18 (15–21) |
| … dont oubli | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 | 0 (0–2) | 1 (0–3) | 1 (0–3) | 1 (0–4) | 1 (0–4) | 1 (0–4) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–2) |
| Or gagné (cumul) | 106 (69–190) | 519 (418–625) | 1309 (1079–1548) | 3221 (2697–3806) | 4766 (4029–5572) | 6454 (5519–7564) | 8810 (7645–10384) |
| Or dépensé (cumul) | 0 (0–50) | 200 (55–400) | 438 (125–871) | 960 (408–1748) | 1455 (699–2341) | 1838 (1053–3287) | 2518 (1459–4294) |
| Or en réserve | 142 (81–232) | 337 (143–549) | 904 (388–1337) | 2296 (1366–3092) | 3244 (2239–4501) | 4500 (3099–6147) | 6215 (4134–8377) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–11) | 15 (12–18) | 19 (16–22) | 22 (19–26) | 28 (24–33) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 6 (6–8) | 8 (6–10) | 10 (8–12) |
| Reliques | 2 (1–3) | 5 (3–7) | 8 (5–10) | 12 (8–15) | 14 (10–18) | 16 (13–21) | 20 (15–25) |
| PlayerPower (DDA) | 112 (105–125) | 210 (170–267) | 315 (250–394) | 471 (390–580) | 576 (474–705) | 678 (560–834) | 853 (698–1011) |
| Budget ennemi d’un combat normal | 37 (34–40) | 139 (124–156) | 246 (221–277) | 411 (372–455) | 519 (474–580) | 630 (578–702) | 803 (730–880) |
| Ennemis par combat normal | 1,0 | 3,0 | 4,6 (4,0–5,0) | 4,8 (4,3–5,3) | 4,5 (4,0–5,0) | 3,5 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–27) | 38 (34–42) | 60 (54–65) | 102 (92–112) | 155 (139–174) | 281 (236–338) | 551 (453–690) |
| PV d’une rencontre normale | 23 (20–27) | 113 (103–126) | 270 (232–312) | 482 (419–561) | 698 (604–809) | 982 (842–1125) | 1417 (1223–1626) |
| Dégâts par tour (tours 1-3, mannequin) | 21 (14–30) | 45 (30–76) | 79 (48–142) | 154 (89–264) | 221 (128–384) | 281 (168–477) | 364 (224–636) |
| Tours pour vider un combat normal | 2,3 (1,8–2,6) | 4,5 (3,3–6,0) | 6,3 (4,0–8,2) | 6,0 (4,3–8,3) | 6,0 (4,0–8,3) | 6,3 (4,5–8,3) | 6,0 (4,0–8,0) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 43 (37–48) | 82 (74–92) | 107 (96–122) | 122 (107–140) | 149 (132–174) |
| PV perdus par combat normal (sans plancher) | 3 (1–4) | 16 (5–27) | 71 (41–109) | 166 (109–246) | 241 (158–343) | 262 (163–400) | 332 (203–514) |
| PV en fin d’acte (% du max) | 21 (2–60) | 11 (1–57) | 6 (1–44) | 2 (1–16) | 4 (1–16) | 6 (1–18) | 7 (1–21) |
| Quasi-morts (cumul) | 0 (0–3) | 11 (0–30) | 59 (16–108) | 226 (124–330) | 362 (222–507) | 471 (316–665) | 619 (426–843) |
| Cartes trouvées, D31 (cumul) | 6 (4–7) | 16 (14–20) | 28 (24–33) | 45 (39–60) | 56 (50–77) | 67 (61–99) | 85 (77–127) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 6 (4–10) | 12 (8–14) | 14 (10–18) | 16 (12–20) | 20 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 5 (1–9) | 7 (3–12) | 8 (4–14) | 11 (6–18) |
| … dont copie du deck, D46 | 0 (0–1) | 1 (0–2) | 1 (0–2) | 2 (0–4) | 3 (1–4) | 3 (2–6) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–6) | 4 (1–7) | 5 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A3–A6) · 100 % |
| 1re épique | A10 (A6–A15) · 95 % |
| 1re légendaire | — (A13–—) · 25 % |
| 1re quasi-mort | A2 (A1–A4) · 100 % |
| 1re mythique D42c prise | — (A14–—) · 14 % |

### Mage · Marque

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (12–18) | 20 (17–24) | 26 (22–30) | 29 (25–33) | 32 (27–38) | 35 (30–42) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (4–8) | 11 (8–14) | 20 (17–27) | 27 (22–36) | 34 (28–46) | 44 (38–61) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–2) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–4) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 6 (4–8) | 12 (9–15) | 21 (17–28) | 28 (23–36) | 35 (29–45) | 45 (38–58) |
| Niveaux de rune, somme | 2 (0–3) | 8 (5–12) | 16 (11–23) | 29 (22–41) | 40 (30–56) | 51 (39–68) | 68 (53–93) |
| Niveau de rune, max | 1 (0–2) | 2 (1–4) | 3 (2–6) | 4 (2–9) | 5 (3–11) | 6 (3–14) | 7 (4–18) |
| Runes `eco` + `quick` dans le deck | 0 | 0 | 0 (0–2) | 2 (0–4) | 3 (1–5) | 4 (2–6) | 5 (3–8) |
| Visites de feu de camp (cumul) | 1 (1–2) | 4 (3–5) | 7 (5–8) | 11 (9–13) | 14 (12–16) | 17 (14–19) | 21 (18–24) |
| … dont repos | 0 (0–1) | 2 (0–3) | 4 (2–6) | 8 (5–11) | 11 (8–13) | 14 (10–17) | 17 (14–21) |
| … dont oubli | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 (0–1) | 1 (0–2) | 1 (0–3) | 1 (0–4) | 2 (0–4) | 2 (0–5) | 2 (0–5) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–1) | 0 (0–1) | 1 (0–2) |
| Or gagné (cumul) | 98 (68–195) | 529 (419–647) | 1332 (1097–1572) | 3281 (2766–3826) | 4840 (4055–5690) | 6535 (5535–7687) | 8978 (7591–10441) |
| Or dépensé (cumul) | 0 (0–75) | 225 (75–432) | 460 (155–812) | 973 (480–1726) | 1393 (695–2435) | 1898 (939–3155) | 2678 (1420–4187) |
| Or en réserve | 137 (75–234) | 343 (86–578) | 887 (487–1357) | 2293 (1368–3191) | 3466 (2122–4623) | 4654 (2905–6124) | 6401 (4097–8391) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–11) | 15 (12–18) | 19 (16–22) | 23 (19–27) | 29 (24–34) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–2) | 2 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 4 (2–4) | 6 (4–6) | 6 (6–8) | 8 (6–10) | 10 (8–12) |
| Reliques | 2 (1–3) | 5 (3–7) | 8 (5–10) | 11 (8–15) | 14 (10–18) | 17 (13–21) | 20 (16–25) |
| PlayerPower (DDA) | 112 (106–127) | 210 (170–268) | 320 (257–390) | 481 (387–587) | 590 (477–712) | 702 (563–845) | 876 (700–1028) |
| Budget ennemi d’un combat normal | 37 (35–40) | 138 (125–157) | 249 (223–273) | 415 (375–458) | 529 (474–582) | 639 (571–708) | 815 (730–896) |
| Ennemis par combat normal | 1,0 | 3,0 | 4,7 (4,0–5,0) | 4,8 (4,3–5,3) | 4,5 (4,0–5,0) | 3,5 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 24 (21–26) | 38 (34–42) | 60 (54–67) | 103 (92–113) | 156 (139–174) | 287 (237–354) | 567 (454–712) |
| PV d’une rencontre normale | 24 (21–26) | 114 (101–126) | 276 (233–313) | 491 (416–563) | 704 (610–811) | 1004 (868–1139) | 1438 (1236–1643) |
| Dégâts par tour (tours 1-3, mannequin) | 47 (31–78) | 99 (64–167) | 171 (108–312) | 322 (196–541) | 474 (270–770) | 623 (371–1063) | 981 (557–1668) |
| Tours pour vider un combat normal | 1,0 (1,0–1,3) | 3,0 (2,8–4,0) | 4,8 (4,0–5,8) | 4,8 (3,8–6,0) | 4,8 (3,7–6,0) | 4,5 (3,4–5,8) | 3,7 (2,8–5,0) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 44 (38–48) | 83 (75–94) | 109 (96–122) | 123 (109–142) | 150 (128–173) |
| PV perdus par combat normal (sans plancher) | 0 (0–1) | 12 (4–20) | 58 (36–81) | 124 (79–180) | 166 (107–232) | 145 (81–229) | 135 (63–232) |
| PV en fin d’acte (% du max) | 44 (5–78) | 39 (3–85) | 31 (1–64) | 3 (1–18) | 6 (1–19) | 7 (1–19) | 7 (1–20) |
| Quasi-morts (cumul) | 0 | 1 (0–11) | 32 (6–62) | 138 (81–197) | 223 (142–302) | 287 (189–380) | 357 (244–465) |
| Cartes trouvées, D31 (cumul) | 6 (4–7) | 17 (14–20) | 28 (24–34) | 45 (40–59) | 56 (50–77) | 67 (60–96) | 85 (76–126) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 8 (4–10) | 12 (8–14) | 14 (10–18) | 18 (12–22) | 22 (16–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 4 (1–8) | 6 (3–11) | 8 (4–13) | 11 (5–17) |
| … dont copie du deck, D46 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 2 (1–4) | 3 (1–4) | 3 (1–5) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–5) | 4 (1–7) | 5 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A2–A6) · 100 % |
| 1re épique | A10 (A7–A15) · 93 % |
| 1re légendaire | — (A12–—) · 20 % |
| 1re quasi-mort | A3 (A2–A5) · 100 % |
| 1re mythique D42c prise | — (A15–—) · 10 % |

### Mage · Arcaniste

| Mesure | A1 | A3 | A5 | A8 | A10 | A12 | A15 |
|:---|---:|---:|---:|---:|---:|---:|---:|
| Taille du deck | 9 (7–11) | 15 (12–18) | 20 (17–24) | 26 (22–31) | 29 (24–34) | 32 (27–37) | 35 (30–41) |
| Fusions de 3 copies (cumul) | 2 (0–3) | 6 (4–8) | 11 (8–14) | 20 (17–25) | 27 (23–34) | 34 (30–44) | 45 (39–60) |
| Fusions par l’événement D29 (cumul) | 0 | 0 (0–1) | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–3) |
| Rang de la meilleure carte (0 = commune) | 1 (0–1) | 1 (1–2) | 2 (1–2) | 2 (2–3) | 3 (2–3) | 3 (2–4) | 3 (3–4) |
| Runes portées par le deck | 2 (0–3) | 7 (4–8) | 12 (9–15) | 21 (17–26) | 28 (24–36) | 35 (29–43) | 45 (38–56) |
| Niveaux de rune, somme | 2 (0–4) | 8 (6–12) | 17 (12–23) | 31 (23–42) | 42 (32–57) | 55 (41–74) | 73 (55–99) |
| Niveau de rune, max | 1 (0–2) | 2 (1–4) | 3 (2–6) | 4 (3–11) | 5 (3–15) | 7 (4–18) | 9 (4–22) |
| Runes `eco` + `quick` dans le deck | 0 | 0 (0–1) | 1 (0–2) | 2 (0–3) | 3 (1–5) | 4 (2–6) | 6 (3–8) |
| Visites de feu de camp (cumul) | 1 (1–2) | 4 (3–5) | 6 (5–8) | 10 (9–13) | 13 (11–16) | 16 (14–19) | 20 (18–23) |
| … dont repos | 0 | 1 (0–3) | 3 (0–6) | 7 (2–10) | 9 (4–13) | 12 (6–16) | 15 (8–20) |
| … dont oubli | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–2) |
| … dont affûtage | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (0–7) | 3 (1–7) | 3 (1–8) | 4 (1–10) |
| Niveaux de rune du boss « XP » (D42a, cumul) | 0 | 0 (0–1) | 0 (0–2) | 1 (0–2) | 1 (0–3) | 1 (0–3) | 2 (0–4) |
| Niveaux de rune par événement (D42b, cumul) | 0 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 1 (0–2) | 1 (0–2) | 1 (0–3) |
| Or gagné (cumul) | 98 (69–184) | 541 (443–661) | 1344 (1154–1638) | 3324 (2761–3910) | 4848 (4091–5741) | 6566 (5554–7853) | 9075 (7641–10612) |
| Or dépensé (cumul) | 0 (0–75) | 233 (90–430) | 510 (190–906) | 1100 (435–1967) | 1648 (884–2992) | 2243 (1209–4063) | 3105 (1695–5790) |
| Or en réserve | 135 (74–228) | 357 (110–556) | 880 (424–1369) | 2282 (1162–3201) | 3156 (1745–4428) | 4293 (2682–6001) | 5866 (3191–7986) |
| Niveau du héros | 2 (2–3) | 6 (5–7) | 10 (8–11) | 15 (13–18) | 19 (16–22) | 23 (19–27) | 29 (24–34) |
| Niveaux gagnés dans l’acte | 1 (1–2) | 2 (1–3) | 2 (1–2) | 2 (1–2) | 2 (1–3) | 2 (1–3) | 2 (1–3) |
| Évolutions de signature (2 signatures) | 0 | 2 | 3 (2–4) | 6 (4–6) | 6 (6–8) | 8 (6–10) | 10 (8–12) |
| Reliques | 2 (1–3) | 5 (3–7) | 7 (5–10) | 12 (9–15) | 14 (10–17) | 16 (12–21) | 20 (15–25) |
| PlayerPower (DDA) | 112 (106–124) | 211 (172–275) | 322 (259–393) | 484 (378–605) | 589 (465–734) | 694 (555–856) | 858 (697–1034) |
| Budget ennemi d’un combat normal | 37 (35–40) | 139 (126–158) | 250 (226–274) | 416 (369–467) | 527 (472–591) | 637 (572–713) | 806 (731–897) |
| Ennemis par combat normal | 1,0 | 3,0 | 4,7 (4,0–5,0) | 4,8 (4,3–5,3) | 4,5 (4,0–5,0) | 3,5 (3,0–4,0) | 2,5 (2,0–3,0) |
| PV d’un ennemi moyen (combat normal) | 23 (20–26) | 38 (34–42) | 60 (55–66) | 103 (94–113) | 156 (140–175) | 286 (239–348) | 554 (452–708) |
| PV d’une rencontre normale | 23 (20–26) | 115 (103–126) | 278 (238–315) | 490 (420–563) | 705 (590–834) | 1000 (860–1152) | 1426 (1206–1638) |
| Dégâts par tour (tours 1-3, mannequin) | 35 (24–53) | 100 (64–161) | 196 (122–335) | 365 (221–639) | 538 (315–931) | 647 (394–1090) | 879 (534–1378) |
| Tours pour vider un combat normal | 1,3 (1,0–1,8) | 3,0 (2,0–3,6) | 3,3 (2,3–4,8) | 3,0 (2,3–4,7) | 3,2 (2,3–4,8) | 3,5 (2,5–5,0) | 3,3 (2,3–4,7) |
| Dégâts ennemis par tour, rencontre normale | 5 (4–5) | 20 (19–22) | 44 (38–49) | 83 (73–95) | 109 (96–124) | 122 (107–142) | 151 (131–173) |
| PV perdus par combat normal (sans plancher) | 0 (0–1) | 5 (0–13) | 28 (7–52) | 64 (27–109) | 94 (39–159) | 99 (37–174) | 134 (48–260) |
| PV en fin d’acte (% du max) | 50 (10–85) | 44 (2–87) | 35 (2–85) | 6 (1–32) | 8 (1–29) | 9 (1–28) | 10 (1–47) |
| Quasi-morts (cumul) | 0 | 0 (0–7) | 8 (0–35) | 64 (19–124) | 114 (40–208) | 158 (75–281) | 214 (107–358) |
| Cartes trouvées, D31 (cumul) | 6 (5–7) | 17 (15–20) | 28 (25–33) | 45 (40–58) | 56 (50–76) | 68 (61–94) | 85 (77–123) |
| Clones de boss (cumul) | 2 (0–2) | 4 (2–6) | 8 (4–10) | 12 (8–14) | 14 (10–18) | 18 (14–22) | 22 (18–26) |
| Cartes achetées (cumul) | 0 (0–1) | 1 (0–3) | 2 (0–5) | 4 (1–8) | 7 (3–11) | 9 (4–13) | 11 (6–17) |
| … dont copie du deck, D46 | 0 (0–1) | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–5) | 3 (2–6) | 4 (2–7) |
| Clones du Miroir, niveau + boutique (cumul) | 0 | 0 (0–1) | 1 (0–2) | 2 (0–4) | 3 (1–6) | 4 (1–7) | 5 (2–9) |

| Première fois | Acte médian (P10–P90) · part des runs |
|:---|---:|
| 1re fusion | A1 (A1–A2) · 100 % |
| 1re rare | A4 (A3–A6) · 100 % |
| 1re épique | A10 (A6–A14) · 95 % |
| 1re légendaire | — (A12–—) · 24 % |
| 1re quasi-mort | A4 (A2–A6) · 100 % |
| 1re mythique D42c prise | — (—–—) · 10 % |

## Annexe B — Reproduire

```
dart run tool/simulations/d26_economy_sim.dart --out sorties.md      # 8 à 10 min, 22 cœurs
dart run tool/simulations/d26_economy_sim.dart --quick --out test.md # ~1 min, 25 runs
```

Graine 26 000 000 ; la run *i* de la configuration *c* a la graine 26 000 000 + 100 000 × *c* + *i*, quel que soit le levier. Deux passes complètes ont produit des sorties identiques. Le script relit `assets/data/` à chaque lancement : un changement de donnée change les chiffres.

*Ajout du 01/10.* Une relance ne se compare pas aux tables de ce rapport — ses §2 à §4 sont à k = 5 — mais à la sortie complète du script, suivie par git : `tool/simulations/d26_reference_output.md`. La manière de comparer, en deux temps, est dans le [fichier d'orchestration](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), §3.6 (brainstorm, D70 et D73). La passe complète a pris 422 s puis 462 s ce jour-là.
