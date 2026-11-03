# Les charges élémentaires — Gel, Feu, Foudre : un seuil plutôt qu'un pourcentage

**Date** : 03/11/2026 — étude née pendant l'arrêt de la vague 5 (`0.5.7`), sur la question P-1 de sa spec.
**Statut** : **exploré, orienté par le propriétaire, programmé le 03/11 par D76** (brainstorm v3, §1) : **vague 7, `0.5.9`**. Les points marqués *tranché par le propriétaire* sont ses orientations du 02-03/11 ; ils ne sont pas des décisions acquises du brainstorm v3 et ne s'appliqueront qu'une fois le chantier spécifié. Rien n'est implémenté. Chantier **P-53** de [`docs/ROADMAP.md`](../ROADMAP.md) ; fiche 8.7 du [fichier d'orchestration](01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md).
**Calendrier** : **pas en `0.5.7`** (option T3, §8) — la vague 5 ne porte que les cartes et le joueur ; les charges élémentaires touchent le gameplay fondamental des cartes. **Une vague à elles, la vague 7, `0.5.9`** (D76, 03/11) : la tranche 3 passe en vague 8, `0.6.0`.
**Vérifié contre** : la branche `feat/v0.5.7-p42-tranche-1-p44-lot-1` à `4377a0a` (code de `main` à `d99cd81`, `0.5.6`). Chaque constat de code porte le `fichier:ligne` qui l'établit.
**Sources** : la spec de la vague 5, [`2026-10-25-p42-tranche-1-p44-lot-1-design.md`](../superpowers/specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §1.4 (P-1) et §4.4 ; sa présentation, [`2026-10-26_vague_5_trois_questions_p.pptx`](../presentations/2026-10-26_vague_5_trois_questions_p.pptx) ; le [brainstorm v3](22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §7, §8, §9.2.

---

## 0. Le constat — deux statuts qui font la même chose

En jouant la question P-1 (« combien vaut un point de Vulnérable, de Faiblesse, de Gel ? »), le propriétaire a relevé que **Gel et Faiblesse ont le même effet, décrit de deux manières** : tous deux réduisent ce que l'ennemi inflige.

| Statut | Ce qu'il fait aujourd'hui | Où |
|:---|:---|:---|
| Faiblesse | −25 % sur chaque attaque du porteur | `damage_pipeline.dart:19` |
| Gel | L'intention du porteur divisée par deux | `enemy_instance.dart:28` |
| — | Seule différence, invisible au joueur : la Faiblesse s'use au tour, le Gel à l'attaque | `turn_phase_manager.dart:106-128`, `entity_stats.dart:145` |

Le barème proportionnel de P-1 garde ce doublon, il ne fait que le chiffrer. Un second doublon existe à côté : **Brûlure et Poison** sont deux dégâts sur la durée (`status_effect_processor.dart`), l'un qui baisse de 1 par tour, l'autre non. Et l'Électrocution ajoute sa valeur à chaque coup reçu (`damage_pipeline.dart:35`), ce que Vulnérable fait déjà en pourcentage.

## 1. L'idée — une charge, un seuil, une rupture

**Une charge élémentaire** est un statut qui s'accumule en points sur son porteur et qui, à un **seuil**, provoque une **rupture** — un effet propre à l'élément. Chaque élément devient un verbe distinct :

| Statut | Son verbe | Forme |
|:---|:---|:---|
| **Gel** | ôte une action | charge élémentaire (§3) |
| **Feu** | explose sur le porteur et ses voisins | charge élémentaire (§4) |
| **Foudre** | amplifie chaque coup reçu | charge élémentaire (§5), à approfondir |
| Poison | use sur la durée | inchangé — devient **le** dégât sur la durée |
| Vulnérable | fait subir plus, en % | inchangé — barème de P-1 |
| Faiblesse | fait infliger moins, en % | inchangé — barème de P-1 (§6) |

## 2. Le cadre commun — *tranché par le propriétaire* : un système extensible et symétrique

**Une seule mécanique, en donnée**, sur le modèle des runes (ADR-105 : une sorte de delta écrite une fois en Dart, ses valeurs en donnée) : chaque charge déclare ses paramètres, et seule sa **rupture** est un comportement écrit une fois en code, réutilisable par une charge future. Ajouter un élément — l'Ombre, l'Acide — c'est un fichier et, au besoin, une sorte de rupture.

**Symétrique joueur / ennemis** *(exigence du propriétaire)*. Aucun ennemi élémentaire n'existe aujourd'hui (aucun fichier d'`assets/data/enemies/` ne pose `burn`, `shock` ou `freeze`), mais il en viendra, et ils poseront ces charges sur le héros. Le système vit donc sur le porteur, quel qu'il soit, jamais sur « l'ennemi ». Le terrain est prêt : `EntityStats` est partagé par le héros et les ennemis et porte déjà la liste des statuts (`entity_stats.dart` ; `power_rules.dart`, commentaire d'en-tête) ; ce qui diffère est le moment de traitement — `processPlayerStatuses` et `processEnemyStatuses` (`status_effect_processor.dart`) —, qui devient « au tour du porteur ».

Les paramètres d'une charge, esquisse :

| Paramètre | Gel | Feu | Foudre |
|:---|:---|:---|:---|
| Seuil de départ | 3 | 3 | 3 *(à confirmer)* |
| Seuil après chaque rupture | +1, pour le combat | inchangé | *à discuter* |
| Pose au-delà du seuil | **plafonnée** au restant | **libre** (surcharge) | *à discuter* |
| Déclin | −1 au tour du porteur s'il n'a pas rompu | sans objet (la charge se résout à chaque tour du porteur) | *à discuter* |
| Moment de la rupture | à l'atteinte du seuil (le porteur gèle aussitôt) | au tour du porteur | *à discuter* |
| Rupture | perd sa prochaine action | dégâts au porteur et explosion aux voisins | chaque coup reçu fait plus |

Deux faits de code que la spec devra traiter :
- **les points se lisent sur la somme des entrées de même id** : depuis E0, `addStatus` ne fusionne que même statut *et* même source (ADR-104) ; deux cartes qui posent du Gel font deux entrées ;
- **la Puissance « altération » ajoute des points** à un statut posé sur un ennemi (`power_rules.dart:27-32`), une fois par carte (réponse Q11 de la vague 5) : le Mage et le Paladin chargent plus vite.

## 3. Le Gel — *tranché par le propriétaire*

**Règles.**
1. Le Gel s'accumule en points ; au **seuil, 3**, le porteur **gèle** : il perd sa prochaine action, puis le Gel retombe à 0.
2. **Déclin** : un porteur qui n'a pas été gelé dans le tour perd 1 point de Gel à son propre tour. *Nova de givre* (2 Gel) laisse un ennemi à 2/3 ; après son tour, il est à 1/3. Le combo se fait dans un tour, et un reste passe au suivant.
3. **Le seuil monte de 1 à chaque gel**, pour le reste du combat (3, puis 4, puis 5) : l'équilibre se règle de lui-même, sans gel en chaîne d'un boss à chaque tour — et il se lit (« ❄ 1/4 »).
4. **Pas de surcharge** : on ne pose jamais plus de points que le porteur ne peut en recevoir avant son seuil. Un porteur déjà gelé n'en reçoit plus.

**Écarté** — le Gel au hasard (10 à 15 % par point de perdre son tour, une animation « gelé » ou « brisé » selon le jet) : une idée du propriétaire, écartée par lui au profit du seuil, plus jouable dans un jeu où l'on voit les intentions et où l'on planifie son tour. Le hasard faisait aussi baisser la force moyenne du Gel (20 % de chance à 2 points contre −50 % garanti aujourd'hui) et imposait un plafond.

**Ouvert.**
- **Le Gel posé sur le héros** par un futur ennemi élémentaire : « perdre son action » veut dire perdre un tour entier, trop dur. À trancher : un seuil plus haut, ou une rupture adaptée au héros (perdre du Mana, ne pas pouvoir jouer d'Attaque au tour suivant).
- « Perd sa prochaine action » s'entend de toute action — attaque, défense, renforcement : « gelé, il ne fait rien ». À confirmer.
- Le seuil d'un boss : le même, ou plus haut au départ.
- Les valeurs : *Nova de givre* à 2 points plus un peu de Puissance gèle toute une salle pour 2 Mana ; *Trait de Glace* (1 point aujourd'hui, `cards/ice_bolt.json`) ; la rune *Gel* (`forge_upgrades/freezing.json`, « +1 pile par niveau » — D33 le garde).

## 4. Le Feu — *orienté par le propriétaire* : l'option F3, avec surcharge

**Règles proposées par le propriétaire**, telles que l'étude les lit :
1. **Surcharge libre** : le joueur pose autant de points de Feu qu'il veut ; le seuil, 3, **ne monte pas**.
2. **Au tour du porteur** — et non au moment où le seuil est atteint —, deux choses se produisent :
   - **le porteur** prend **4 dégâts par point** : 5 points font 20 ;
   - **une explosion** touche **les ennemis voisins** du porteur seulement (à sa gauche et à sa droite dans la rangée), de **12 dégâts par seuil complet** — soit 4 × 3 par tranche de 3 points : 5 points font 12 (une tranche), 6 font 24, 9 font 36.
3. La charge est consommée par la rupture *(lecture de l'étude, à confirmer)*.

Exemple du propriétaire : une salle de 5 ennemis, celui du milieu porte 5 points de Feu ; à son tour il prend 20, ses deux voisins 12 chacun.

**Ce que ça apporte.** Le Feu devient du dégât de zone ciblé, qu'on place : charger l'ennemi central d'une salle pleine paie plus que charger celui du bout. C'est un rôle que personne n'a — *Onde* et *Ricochant* touchent tout le monde ou à l'aveugle — et il sépare enfin Feu et Poison.

**Faisabilité.** « Voisin » demande un ordre des ennemis, et il existe : la rangée Flame place les ennemis dans l'ordre de `enemyCards` (`layout_system.dart:121`), qu'elle remplit dans l'ordre de l'état du combat (`state_sync_system.dart:138`). *À fixer en spec* : ce que devient le voisinage quand un ennemi meurt (les survivants se resserrent-ils ?). Les dégâts passent par le pipeline existant (`DamagePipeline.calculate`), une fois par cible.

**Ouvert.**
- **Sous le seuil** (1 ou 2 points) : le porteur prend-il ses 4 par point à son tour, sans explosion ? La lecture de l'exemple dit oui.
- **La charge se consomme-t-elle** entièrement à la rupture, ou garde-t-elle le reste au-delà des tranches complètes (5 points : une tranche explose, 2 restent) ?
- **Réaction en chaîne** : l'explosion pose-t-elle du Feu sur les voisins ? À écarter d'abord, sauf envie contraire.
- **Le héros porteur** (ennemi élémentaire) : pas de voisin, donc les 4 par point seulement.
- **L'échelle** : avec la surcharge et la Puissance qui ajoute des points (§2), le Feu du Mage grandit vite — c'est voulu, à mesurer. *Embrasement* (4 Brûlure en vague 5) et *Boule de Feu* (2 Brûlure, `cards/fireball.json`) se relisent ; la rune *Brûlant* garde ses piles par niveau (D33).

**Écartées** :
- **F1 — Embrasement seul** (au seuil, une explosion sur le porteur, plus de dégâts sur la durée) : un seul verbe, mais sans le placement que F3 donne ;
- **F2 — Combustion** (la Brûlure garde ses dégâts sur la durée et explose en plus au seuil) : deux effets à lire sur un statut, et le doublon avec le Poison demeure.

## 5. La Foudre — *orientée par le propriétaire* : l'option L1, à approfondir

**L1 — Surcharge** : au seuil, le porteur est « chargé » pendant un tour : **chaque coup** qu'il reçoit fait +3, un bonus fixe. C'est la plus proche de l'Électrocution d'aujourd'hui (+valeur par coup, `damage_pipeline.dart:35`) et elle garde la synergie Foudre × multi-coups que le brainstorm a voulue (§7.3, ligne Arcaniste ; §9.2 n° 2 : « `shock` par coup ») et que porte *Rafale d'étincelles* (vague 5). Elle se distingue de Vulnérable par la forme : Vulnérable sert les gros coups (+ %), la Surcharge les petits coups nombreux (+ fixe).

**Le propriétaire veut en discuter davantage** : pas d'idée aussi nette que pour le Feu. Les questions à porter :
- la durée de la charge (un tour ? jusqu'à un nombre de coups ?) ;
- la surcharge : plafonnée comme le Gel, libre comme le Feu, ou chaque point au-delà du seuil ajoute-t-il +1 par coup ?
- le déclin et la montée du seuil ;
- le héros porteur : +3 par coup reçu face à des ennemis multi-coups.

**Écartées pour l'instant** :
- **L2 — Retour de foudre** (le porteur chargé prend des dégâts quand il attaque) : c'est la règle des **Épines**, prévues pour Rempart en P-44 lot 2, et *Rafale d'étincelles* y perdrait sa raison ;
- **L3 — Court-circuit** (le porteur perd toute son Armure et n'en gagne pas à son prochain tour) : un verbe neuf, mais nul contre un porteur sans Armure, et la carte multi-coups de l'Arcaniste serait à refaire.

## 6. La Faiblesse — inchangée

Le propriétaire a envisagé de la changer en « +5 % de dégâts subis ». **Écarté** : c'est le verbe de Vulnérable, et le doublon passerait de Gel/Faiblesse à Faiblesse/Vulnérable. La Faiblesse est en outre la pièce du lot *Sanctifié* (brainstorm §7.1) : des ennemis qui frappent moins, donc une Armure qui survit pour *Bénédiction*. Une fois que le Gel ne réduit plus les dégâts, la Faiblesse est déjà unique : elle garde le barème de P-1.

## 7. Faisabilité — ce que le chantier touche

| Couche | Ce qui change | Difficulté |
|:---|:---|:---|
| **Donnée** | Une catégorie de charges, un fichier par élément, ses paramètres (§2) ; les cartes et runes qui posent `burn`, `shock`, `freeze` se relisent — `fireball`, `thunder_clap`, `ice_bolt`, les runes `burning`, `shocking`, `freezing`, et les cartes de vague 5 (*Nova de givre*, *Embrasement*, *Rafale d'étincelles*). Rien chez les ennemis aujourd'hui | Faible |
| **Moteur** | Un compteur par porteur et par élément (somme des entrées, §2) ; le seuil, le déclin, la montée du seuil, le plafond de pose ; trois sortes de rupture. Remplace trois lectures en dur dispersées : `enemy_instance.dart:28`, `turn_phase_manager.dart:106-128`, `entity_stats.dart:145` (Gel) ; le tic de Brûlure de `status_effect_processor.dart` ; `damage_pipeline.dart:35` (Électrocution). Entièrement déterministe : aucun tirage, des tests simples | Moyenne |
| **Ordre du tour** | La rupture du Feu et le déclin se jouent au tour du porteur ; le gel retire une action. Aujourd'hui Flame lance l'animation d'une action *avant* que le contrôleur la résolve (`heros_draft_game.dart:381-393`) : l'état doit dire d'abord si l'ennemi est gelé, pour que Flame joue la bonne animation. Les couches restent séparées : le contrôleur décide, Flame lit | Faible à moyenne |
| **Affichage** | La charge sur le porteur, « ❄ 2/3 », « 🔥 5 » (`status_indicator.dart`) ; l'intention d'un ennemi gelé ; côté héros, le panneau des statuts (`hud/status_effects_panel.dart`) ; les infobulles et les textes des cartes ; le tutoriel (`tutorial_data.dart`, `tutorial_elements_widget.dart`) | Faible à moyenne |
| **Animations** | Une par rupture : le gel qui fige, l'explosion qui touche les voisins, la charge électrique. Aucun effet élémentaire n'existe dans `lib/game/components/visual_effects/` ; les particules Flame sont déjà employées par les cartes | **Moyenne — le plus gros morceau** |
| **Tests** | Le cycle de chaque charge (pose, plafond, déclin, seuil qui monte, rupture), la symétrie héros / ennemi, les voisins du Feu (bords, mort d'un voisin) | Moyenne |

## 8. Le calendrier — *tranché par le propriétaire* : T3

| | Quand | Retenu ? |
|:---|:---|:---|
| T1 | Gel, Feu et Foudre en vague 5 | Non — alourdit la vague la plus lourde |
| T2 | Le cadre et le Gel en vague 5, Feu et Foudre en vague 7 avec le lot *Marque* | Non |
| **T3** | **Hors de la vague 5** : un chantier à part, P-53, plus tard — au plus tôt pendant le développement de `0.6.0` | **Oui** |

**Ce que T3 implique pour la vague 5.** La spec de `0.5.7` garde ses statuts proportionnels : **P-1 est répondue (a) le 03/11** — 25 % par point, plafonnés —, et le Gel de `0.5.7` suit ce barème. Ce barème sera remplacé pour le Gel par la charge élémentaire quand P-53 sera spécifié ; *Trait de Glace*, *Nova de givre*, *Embrasement*, *Rafale d'étincelles* et les runes élémentaires écrites ou recalibrées en vague 5 seront relues à ce moment.

**Où P-53 se loge — tranché le 03/11 (D76)** : une vague à lui, la vague 7, `0.5.9`, avant la tranche 3, qui devient la vague 8, `0.6.0`. Le lot *Marque* s'écrit ainsi sur les charges. Les deux formes envisagées avant D76 :
- avec la vague 7 (`0.6.0`), dont le lot *Marque* rassemble les quatre cartes élémentaires — mais la fiche de la vague 7 (orchestration, §8.7) ne le prévoit pas, et l'y ajouter élargit une vague, ce que seul le propriétaire décide ;
- après `0.6.0`, comme un lot propre, à côté de P-44 lot 2 (étourdissement, épines), avec lequel il se croise : le gel est un étourdissement à seuil, L2 rejoignait les épines.

## 9. Les décisions acquises qu'il croise

Aucune n'est amendée par cette étude :
- **D33** — `burning`, `shocking`, `freezing` « restent en piles » : la charge compte en points, les runes en posent par niveau ;
- **D12** — les mécanismes de P-44 sont retenus ; « statuts proportionnels » couvre une charge à seuil ;
- **Q11** (vague 5) — un seul bonus de Puissance de statut par carte : il ajoute des points de charge comme aujourd'hui ;
- **§9.2 n° 2** — `shock` par coup sur les multi-coups : L1 le garde ;
- **le barème de P-1** (vague 5) pour le Gel : remplacé quand P-53 sera spécifié — une décision du propriétaire, à écrire alors comme amendement.

Quand P-53 sera ouvert, ses arbitrages s'écriront comme des décisions numérotées, par un brainstorm ou une spec.

## 10. Les questions ouvertes

| # | Question | Section |
|:---:|:---|:---:|
| C1 | Le Gel sur le héros : seuil plus haut, ou une autre rupture que la perte du tour ? | §3 |
| C2 | Un ennemi gelé perd-il toute action, ou seulement son attaque ? | §3 |
| C3 | Le seuil de départ d'un boss | §3 |
| C4 | Le Feu sous le seuil : 4 par point au porteur, sans explosion ? | §4 |
| C5 | Le Feu après la rupture : consommé en entier, ou le reste au-delà des tranches complètes demeure ? | §4 |
| C6 | Le Feu et la réaction en chaîne | §4 |
| C7 | Le voisinage quand un ennemi meurt | §4 |
| C8 | La Foudre : durée, surcharge, déclin, seuil | §5 |
| C9 | ~~Où loger P-53~~ — ✅ tranché le 03/11 (D76) : vague 7, `0.5.9`, avant la tranche 3 | §8 |
| C10 | Les valeurs — seuils, 4 par point, 12 par tranche, +3 par coup : des ordres de grandeur, que le test du propriétaire corrigera | §3 à §5 |

---

*Étude. Rien n'est implémenté ; ce document ne vaut décision que pour les points que le propriétaire a tranchés, et seulement une fois P-53 spécifié. Prochaine étape : poursuivre la discussion sur la Foudre (§5) et trancher C1 à C10, pour écrire les décisions et compléter la fiche 8.7 du fichier d'orchestration avant la vague 7.*
