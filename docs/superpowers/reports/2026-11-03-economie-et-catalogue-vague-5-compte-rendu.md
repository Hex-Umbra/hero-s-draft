# Vague 5 — `0.5.7` — la tranche 1 et P-44 lot 1 — compte rendu

**Branche** : `feat/v0.5.7-p42-tranche-1-p44-lot-1` · **Spec** : [tranche 1 et P-44 lot 1](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md) ([vérifications](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design-verifications.md)) · **Plans** : [partie 1](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-1.md) ([vérifications](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-1-verifications.md)) · **Forme** : [README](README.md).

*Ouvert à la fin de la partie 1 (§3.5) ; §0, §3 et §6 s'écrivent en fin de vague.*

## 0. Pour le propriétaire

*À écrire en fin de vague.*

## 1. La branche et ses chiffres

| Version | Commits | Tests | `dart analyze` | Code (`lib/`, `test/`, `assets/`) | Superpowers | Claude Code |
|:---|---:|:---|:---|:---|:---|:---|
| `0.5.7` | 21 (`da233ba..`), partie 1 | 1701 → **1811** | `No issues found!` | partie 1 : 61 fichiers, +3394 / −298 | 7.0.0, `bb92a77` | 2.1.301 |

## 2. Les arbitrages

Une ligne chacun, ou un thème par ligne pour les arbitrages T de la spec (le plafond de 150 lignes) ; les options écartées sont dans les fichiers de vérifications.

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| Q6 · Q7 · Q8 | Pools d'évolutions ; majeures contradictoires ; cartes-pont | P | 3 mineures, 4 majeures, repli confirmé ; `excludes` en donnée ; pas de pont (propriétaire, prompt) | — |
| Q9 · Q11 · O5 | Draft de départ ; double bonus de Puissance ; masquage | P | 2 du lot + 3 neutres, lu comme deux quotas ; un bonus par carte ; masqué si aucune carte ne porte le passif (propriétaire) | — |
| Écran | L'écran d'évolution | P | Le carrousel, trois rouleaux, nom, description, palier, « 1 → 2 », signature en tête (propriétaire) | — |
| P-1 | Le barème des statuts proportionnels | P | (a) 25 % par point, plafonds 4 / 2 / 3 (propriétaire, 03/11) | — |
| P-2 · P-4 | L'affichage des évolutions ; l'icône sur le rouleau | P | (c) badge et icônes, « rien n'est caché » ; (a) l'icône sur le rouleau (propriétaire, 03/11) | — |
| P-3 | L'écho et les événements « carte jouée » | P | (a) aucun événement (propriétaire, 03/11) | — |
| D76 | Une vague pour les charges élémentaires | D | Vague 7, `0.5.9` ; la tranche 3 en vague 8 (propriétaire, 03/11 ; [étude](../../possible_upgrades/03-11-2026_charges_elementaires_Opus5.md)) | — |
| A1-A5 | Forme C : `passive` seul ; seconde source qui l'injecte ; `isOfferable(p)` ; masquage mesuré sur le registre ; `classes` à une classe | T | spec §1.3 | 5 |
| A6-A10 | `feeds` à préfixes ; validateur `costs.armor` par la `statRule` ; D17 au chargement ; forme de `costs` ; une règle `canAfford` | T | spec §1.3 | 1, 4, 5 |
| A11-A16 | `scaleWith` objet, arrondi bas ; compteur dérivé ; `mightRatio` arrondi bas ; A14 ; Q11 au résolveur ; `piercing` dans `takeDamage` | T | spec §1.3 | 1, 4, 5, 8 |
| A17-A23 | `splash` avant pipeline ; les deux vols de vie ; écho seconde résolution ; `transfusion` après l'écho ; `eligibleTargets` ; *Transcendance* et la saturation ; `freezing` sans plafond | T | spec §1.3 | 1, 4, 6, 7 |
| A24-A34 | Modèle `deltas` des évolutions ; gabarits ; mineures en repli ; attente dérivée ; `signatureEvolutions` ; quotas ; tutoriel ; `lotCard` ; rendu ; D38 et signatures ; découpage | T | spec §1.3 | 1, 5, 6, 7, 8 |
| A35-A38 | Icône en donnée ; badge sur la ligne du type ; rangée d'icônes ; barre centrée, réduite, plancher 0,75 | T | spec §1.3 | 4, 5, 6, 7 |
| C1.1-C1.3 | Q11 à la lettre, l'écho a son bonus ; *Transcendance* sur les runes neuves ; un coût touche `feeds` (lecture de D45) | T | orchestrateur, tour 1 | 1, 6 |
| C1.4-C2.2 | Plancher de D33 ; sauvegarde sans rapport ; clés du draft ; tranches de `scaleWith` ; ratio sous 1 ; textes de la galerie | T | rédactrice, confirmés | 1, 5, 6 |
| PL1-PL8 | Plan, partie 1 : id `lifesteal` exclu nommément ; écho et cible morte ; infobulle Flame sans contexte ; `statusId` ; son de refus ; dégâts « infligés » ; galerie ; tests de Q11 | T | rédacteur, confirmés | 1, 5, 6, 8 |

**Décisions de SDD — partie 1** (registre de SDD, recopiées avant sa suppression ; revue d'ensemble sur `54425f0..70dc230`, « prête », aucune correction) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S1 | Base de la revue d'ensemble : `54425f0`, le début du plan, et non la base de `main` — avant lui la branche ne porte que de la documentation | T | Aucun pour le code |
| S2 | Task 3, tri des mineurs visibles par l'orchestrateur (amendement 1) : le texte du Gel de la galerie n'est pas plus long que l'ancien (54 caractères contre 57), rien à corriger | T | Un texte coupé sur petit écran, au test |
| S3 | Task 5, un tour de correction : le test du critique de *Ricochant* fixait le critique du héros à 100 et ne prouvait plus le bonus de *Précis* ; réécrit sur 0 + *Précis*, mutation rouge constatée | T | — |
| S4 | Task 7, tâche à risque : revue sur le modèle le plus capable, deux mutations (borne stricte des PV, écriture unique) rougissent `card_costs_test` | T | — |
| S5 | Task 8 jouée par l'orchestrateur, sans agent (amendement 2) : analyse propre, 1811 verts, greps conformes | T | — |

## 3. Les tests manuels

*À écrire en fin de vague.*

## 4. Trouvé périmé, et pour la file

- **Pour la partie 2** (revues de la partie 1) : le descripteur de carte de l'éditeur exige `cost` et refuserait une carte à `costs` (`entity_descriptor.dart:214`) ; le tutoriel et la barre de signatures gardent leur propre règle de mana (`tutorial_engine.dart:368-374`, `signature_bar.dart:114`) ; `SignatureInstance` construit un `CardData` sans `hpCost` ni `armorCost` ; `scaleTerm` lit une cible morte pour `targetStatus` et `targetMissingHp` ; `ProportionalStatus` vit sous `lib/game/` mais `enemy_instance.dart` l'importe (la couche données dépend des services) ; les tests d'éclaboussure à plusieurs coups et d'une cible `allEnemies` qui meurt au premier coup.
- **Tests faibles** : `takeDamage` sans test direct (plafond à 100 %, Armure sur plusieurs coups) ; les gardes de D38 vides tant qu'aucune carte ne porte `hits` ; la ligne Flame vide sans contexte, au test manuel.
- **Polissage** : ordre des imports, lignes de plus de 80 colonnes, l'échafaudage de test recopié dans trois fichiers, quelques commentaires mal tournés (`saturatesAt`, `_payRuneLifesteal`).

## 5. Les leçons

1. **Les trois amendements de méthode du propriétaire** (prompt de lancement) : le tri des mineurs visibles à chaque tâche d'interface (S2), la tâche de vérification jouée par l'orchestrateur (S5), le contenu des écrans neufs tranché avant la vague — *bilan en fin de vague*.

## 6. Les statistiques de la session

*À mesurer avant le commit de §3.8.*
