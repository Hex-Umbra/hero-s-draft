# Vague 5 — `0.5.7` — la tranche 1 et P-44 lot 1 — compte rendu

**Branche** : `feat/v0.5.7-p42-tranche-1-p44-lot-1` · **Spec** : [tranche 1 et P-44 lot 1](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md) ([vérifications](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design-verifications.md)) · **Plans** : [partie 1](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-1.md) ([vérifications](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-1-verifications.md)) · [partie 2](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-2.md) ([vérifications](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-2-verifications.md)) · [partie 3](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-3.md) ([vérifications](../plans/2026-11-03-p42-tranche-1-p44-lot-1-partie-3-verifications.md)) · **Tri D77** : [rapport](2026-11-04-vague-5-tri-des-tests-d-ecran.md) · **Forme** : [README](README.md).

*Ouvert à la fin de la partie 1 (§3.5), complété à la fin des parties 2 et 3 ; §0, §3 et §6 s'écrivent en fin de vague.*

## 0. Pour le propriétaire

*À écrire en fin de vague.*

## 1. La branche et ses chiffres

| Version | Commits | Tests | `dart analyze` | Code (`lib/`, `test/`, `assets/`) | Superpowers | Claude Code |
|:---|---:|:---|:---|:---|:---|:---|
| `0.5.7` | 21 (`da233ba..`), partie 1 | 1701 → **1811** | `No issues found!` | partie 1 : 61 fichiers, +3394 / −298 | 7.0.0, `bb92a77` | 2.1.301 |
| | 14 (`b271e85..d339ce6`), partie 2 | 1811 → **1916** | `No issues found!` | partie 2 : 116 fichiers, +4431 / −709 | 7.0.0, `bb92a77` | 2.1.301 |
| | 3 (`fa948c1a..5fbbe63f`), tri D77 | 1916 → **1524** | `No issues found!` | tri : 66 fichiers de test, +69 / −12536 | 7.0.0, `bb92a77` | 2.1.301 |
| | 15 (`e4be0236..f9f4da3f`), partie 3 | 1524 → **1612** | `No issues found!` | partie 3 : 62 fichiers, +5379 / −286 | 7.0.0, `bb92a77` | 2.1.301 |

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
| PN12 · PN13 | Les phrases d'évolution ; la couleur du badge | P | (d), une option du propriétaire : en combat, des icônes avec leur valeur à la place du texte, la description déroulée en liste par appui long ; l'ambre (propriétaire, 03/11, devant des [maquettes](../../presentations/2026-11-03_vague_5_pn12_pn13_maquettes.pptx)) | — |
| P-5 · P-6 | Les états où l'appui long ouvre la liste ; une seule table d'icônes en combat | P | (a) et (a), les recommandations : tous les états, inactive comprise ; la table alignée sur les faces des cartes (propriétaire, 04/11) | — |
| D77 · P-7 | Les tests gardent les calculs et les données, plus de tests d'écran ; les états d'évolution des tests manuels | D · P | D77 (propriétaire, 04/11) : 1916 → 1524 tests, tri vérifié deux fois, six règles regardées ([tri](2026-11-04-vague-5-tri-des-tests-d-ecran.md)) ; spec et plan de la partie 3 repris sans tests d'écran, 33 puis 34 points de tests manuels ; P-7 (a), une entrée de debug « Évolutions de la signature » (propriétaire, 04/11), partie 3 à 1612 | — |
| D76 | Une vague pour les charges élémentaires | D | Vague 7, `0.5.9` ; la tranche 3 en vague 8 (propriétaire, 03/11 ; [étude](../../possible_upgrades/03-11-2026_charges_elementaires_Opus5.md)) | — |
| A1-A5 | Forme C : `passive` seul ; seconde source qui l'injecte ; `isOfferable(p)` ; masquage mesuré sur le registre ; `classes` à une classe | T | spec §1.3 | 5 |
| A6-A10 | `feeds` à préfixes ; validateur `costs.armor` par la `statRule` ; D17 au chargement ; forme de `costs` ; une règle `canAfford` | T | spec §1.3 | 1, 4, 5 |
| A11-A16 | `scaleWith` objet, arrondi bas ; compteur dérivé ; `mightRatio` arrondi bas ; A14 ; Q11 au résolveur ; `piercing` dans `takeDamage` | T | spec §1.3 | 1, 4, 5, 8 |
| A17-A23 | `splash` avant pipeline ; les deux vols de vie ; écho seconde résolution ; `transfusion` après l'écho ; `eligibleTargets` ; *Transcendance* et la saturation ; `freezing` sans plafond | T | spec §1.3 | 1, 4, 6, 7 |
| A24-A34 | Modèle `deltas` des évolutions ; gabarits ; mineures en repli ; attente dérivée ; `signatureEvolutions` ; quotas ; tutoriel ; `lotCard` ; rendu ; D38 et signatures ; découpage | T | spec §1.3 | 1, 5, 6, 7, 8 |
| A35-A38 | Icône en donnée ; badge sur la ligne du type ; rangée d'icônes ; barre centrée, réduite, plancher 0,75 | T | spec §1.3 | 4, 5, 6, 7 |
| A25 · A39-A42 | Hors combat, la jointure (a) de PN12 ; l'icône d'un effet par sa sorte, `effect_icons.json` ; la bande, trois par ligne ; une phrase par sorte, 13 clés ; l'appui long en calque | T | spec §1.3 | 4, 5, 6, 8 |
| C1.1-C1.3 | Q11 à la lettre, l'écho a son bonus ; *Transcendance* sur les runes neuves ; un coût touche `feeds` (lecture de D45) | T | orchestrateur, tour 1 | 1, 6 |
| C1.4-C2.2 | Plancher de D33 ; sauvegarde sans rapport ; clés du draft ; tranches de `scaleWith` ; ratio sous 1 ; textes de la galerie | T | rédactrice, confirmés | 1, 5, 6 |
| PL1-PL8 | Plan, partie 1 : id `lifesteal` exclu nommément ; écho et cible morte ; infobulle Flame sans contexte ; `statusId` ; son de refus ; dégâts « infligés » ; galerie ; tests de Q11 | T | rédacteur, confirmés | 1, 5, 6, 8 |
| PM1-PM7 | Plan, partie 2 : médaillon rouge des trois ressources ; Puissance par coup dans l'infobulle Flame ; multi-coups `allEnemies` ; `{status}` de `createStatus` ; médaillons sous le mana ; groupe vide sans section ; emplacements et couleur des pastilles | T | rédacteur, confirmés | 5, 6, 7, 8 |

**Décisions de SDD — partie 1** (registre de SDD, recopiées avant sa suppression ; revue d'ensemble sur `54425f0..70dc230`, « prête », aucune correction) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S1 | Base de la revue d'ensemble : `54425f0`, le début du plan, et non la base de `main` — avant lui la branche ne porte que de la documentation | T | Aucun pour le code |
| S2 | Task 3, tri des mineurs visibles par l'orchestrateur (amendement 1) : le texte du Gel de la galerie n'est pas plus long que l'ancien (54 caractères contre 57), rien à corriger | T | Un texte coupé sur petit écran, au test |
| S3 | Task 5, un tour de correction : le test du critique de *Ricochant* fixait le critique du héros à 100 et ne prouvait plus le bonus de *Précis* ; réécrit sur 0 + *Précis*, mutation rouge constatée | T | — |
| S4 | Task 7, tâche à risque : revue sur le modèle le plus capable, deux mutations (borne stricte des PV, écriture unique) rougissent `card_costs_test` | T | — |
| S5 | Task 8 jouée par l'orchestrateur, sans agent (amendement 2) : analyse propre, 1811 verts, greps conformes | T | — |

**Décisions de SDD — partie 2** (revue d'ensemble sur `b271e85..0c15ffe`, le début du plan, « prête avec corrections » : une correction, aucun défaut fonctionnel) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S6 | Task 3 : le test du gabarit de passif reçoit `fixtureHero('paladin')`, le gabarit visant désormais le Paladin ; écart accepté | T | — |
| S7 | Task 4 : toute ligne d'effet portant `scaleWith` (dégâts, Armure, soin, statut) montre en combat la valeur jouée et son terme, la base hors combat — spec §5.2 et A32 contre la lettre du brief (dégâts seuls) ; un test de plus, les totaux du plan décalés de 1 | T | Un chiffre d'infobulle que le propriétaire voudrait autre |
| S8 | Task 4 : livrée en deux commits dont le premier ne compile pas seul ; gardés tels quels, l'`--amend` étant interdit | T | Un `git bisect` gêné sur un commit |
| S9 | Tri des mineurs visibles (amendement 1) — Tasks 4, 5, 7 : rien à corriger ; le 3e médaillon Flame, le titre long d'une section du draft et la largeur de téléphone vont aux tests manuels | T | Un chevauchement vu au test |
| S10 | Task 6, tâche à risque : revue sur le modèle le plus capable, la mutation « éligible seulement » rougit 4 tests ; le libellé « Passifs » et son chevron restent avec un seul passif (une version, code mort en `0.5.8`) | T | Un chevron sans choix pendant une version |
| S11 | Task 8, tri visible : **corrigé** — au tutoriel, la carte d'un groupe plein se grise comme au jeu ; un refus muet, à deux quotas, se lisait comme un bug | T | — |
| S12 | Task 9 : sans pastille « Neutre » pour la carte de lot ; `LotRules` reçoit une classe nulle quand celle du passif est introuvable (A7 sautée, le test du catalogue reste le filet) ; les dix onglets de l'éditeur passent à la ligne, sans débordement | T | Une carte à `costs.armor` sous un passif sans classe, acceptée par l'éditeur |
| S13 | Task 10 par l'orchestrateur (amendement 2) : 1916 verts, greps conformes ; 29 fichiers de données touchés, compte lu avec `--no-renames` (*Forme démoniaque* déplacée) | T | — |
| S14 | Revue d'ensemble : deux phrases du tutoriel, rendues fausses par O5 (« chaque classe en propose plusieurs », l'Armure « c'est votre passif »), réécrites sans compter les passifs pour rester vraies en `0.5.8` | T | Une formulation que le propriétaire réécrit (§0) |

**Décisions de SDD — partie 3** (revue d'ensemble sur `d125d597..052fa3b4`, le plan prêt, « prête avec corrections » : une passe, `f9f4da3f`, aucun défaut fonctionnel ; registre recopié avant sa suppression) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S15 | Task 1 : le code écrit avant ses tests, sans preuve rouge ; accepté, le relecteur a vérifié que les six tests discriminent ; la preuve rouge rendue obligatoire aux implémenteurs suivants | T | Un test qui ne garde rien |
| S16 | Task 4 : à égalité de niveau, l'ordre des attentes suit `HeroData.skills` ; le Paladin livre `[holy_shield, smite]`, donc *Bouclier Sacré* avant *Châtiment* — l'exemple inverse de la spec et du plan corrigé, et M10, M12 à M15 avec lui | T | L'ordre des deux écrans du Paladin au niveau 5 |
| S17 | Task 5, tâche à risque : revue sur le modèle le plus capable, dix mutations, neuf attrapées ; la dixième (clé `signatureEvolutions` omise quand vide, PN6) gardée par une assertion ajoutée, sans test neuf | T | — |
| S18 | Tri des mineurs visibles (amendement 1) — Tasks 2, 6 : rien à corriger ; durées absentes de quatre évolutions (texte de la spec), deux éclairs voisins et le bleu de l'Armure en début de tour (les faces des cartes, P-6 (a)) aux tests manuels | T | Une icône à changer dans `effect_icons.json` |
| S19 | Task 7 : **corrigé** — le retour système quittait l'écran d'évolution sans choisir et relançait le tirage ; `PopScope`, comme l'événement et le repos ; les rouleaux posés ne rejouent plus à l'orientation. Gardés, aux tests manuels : MINEURE et MAJEURE au même gris (spec §5.1), le glyphe d'une majeure dans son anneau | T | Un palier que le joueur ne distingue pas |
| S20 | Task 8 : **corrigé** — le chiffre de niveau des puces (5 px) écrit à leur droite, à la taille du badge ; le compte de recharge centré. Gardé : le médaillon bleu en recharge, comme avant (M23 précisé). L'échelle du calque de la Task 9 lue par la largeur transformée, `getMaxScaleOnAxis` rendant 1 sur la matrice (plan corrigé avant la Task 9) | T | — |
| S21 | Task 9 : deux ajouts de l'implémenteur gardés (la liste jamais plus courte que la tuile ; pas de soulèvement au survol, liste ouverte) ; **corrigé** — le repli sous garde, la tuile qui retombe d'un coup, les 13 phrases testées à la lettre | T | Deux lignes à retirer |
| S22 | Tasks 7 à 10 : revues sur le modèle le plus capable pour 7, 8 et 9 (le rideau, le `RenderBox`, le calque) ; Task 11 par l'orchestrateur (amendement 2) : 1612 verts, greps conformes sauf quatre « vague 5 » en commentaire, corrigés à la revue finale | T | — |
| S23 | Revue finale : `EvolutionIcon.level`, devenu mort, retiré ; une seule règle de pose, `SignatureEvolutionRules.take`, lue par le jeu et le debug ; `effectLines` au niveau 2 testé ; deux résidus de forme laissés (l'ordre de deux imports, une indentation) | T | Une réindentation plus tard |

## 3. Les tests manuels

*À écrire en fin de vague.* Points déjà renvoyés au test par les revues, à reprendre au fichier : le texte du Gel de la galerie sur petit écran ; le 3e médaillon Flame en (6, 58) face aux emplacements de runes, et la ligne Flame vide sans contexte ; le titre « Cartes de Régénération d'Armure » et la grille du draft à largeur de téléphone ; le chevron « Passifs » à un seul passif ; la barre de l'éditeur sur deux lignes ; les deux phrases du tutoriel réécrites (S14). Partie 3 : M7 à M34 de la spec §9.1 ; la lisibilité du bleu de l'Armure en début de tour et des deux éclairs (S18) ; une majeure assez distincte d'une mineure à l'écran d'évolution (S19).

## 4. Trouvé périmé, et pour la file

- **Pour la partie 2** (revues de la partie 1 ; le descripteur de l'éditeur et la règle de mana du tutoriel y sont résolus, Tasks 9 et 8, le reste passe à la partie 3 ou à la file) : le descripteur de carte de l'éditeur exige `cost` et refuserait une carte à `costs` (`entity_descriptor.dart:214`) ; le tutoriel et la barre de signatures gardent leur propre règle de mana (`tutorial_engine.dart:368-374`, `signature_bar.dart:114`) ; `SignatureInstance` construit un `CardData` sans `hpCost` ni `armorCost` ; `scaleTerm` lit une cible morte pour `targetStatus` et `targetMissingHp` ; `ProportionalStatus` vit sous `lib/game/` mais `enemy_instance.dart` l'importe (la couche données dépend des services) ; les tests d'éclaboussure à plusieurs coups et d'une cible `allEnemies` qui meurt au premier coup.
- **Tests faibles** : `takeDamage` sans test direct (plafond à 100 %, Armure sur plusieurs coups) ; les gardes de D38 vides tant qu'aucune carte ne porte `hits` ; la ligne Flame vide sans contexte, au test manuel.
- **Polissage** : ordre des imports, lignes de plus de 80 colonnes, l'échafaudage de test recopié dans trois fichiers, quelques commentaires mal tournés (`saturatesAt`, `_payRuneLifesteal`).
- **De la partie 2, pour la file** : le texte de croissance `targetStatus` nomme le statut en français dans la version anglaise (`card_rule_texts.dart:66-69` ; aucune carte livrée ne lit cette source) ; `draftDeckSubtitle` dit « 2 + 3 » quand le lot manque (texte de spec §6.1 ; atteignable seulement par une classe créée dans l'éditeur, sans lot) ; `CLAUDE.md`, étape 2 du flux de contenu, ne dit pas qu'un dossier de lot `cards/<passif>/` exige lui aussi sa ligne de `pubspec.yaml` (pour `memory-bank-sync`) ; l'éditeur accepte une carte à `costs.armor` sous un passif sans classe unique ; le singleton du registre remplacé par un groupe de `tutorial_engine_test` ; `lot_card_fixture.dart` rangé sous `test/unit/` et lu ailleurs ; pas de test de l'opacité par groupe au jeu, ni du draft à lot réduit en widget.
- **Pour la partie 3** : `ProportionalStatus`, importé par `enemy_instance.dart` depuis `lib/game/` (resté à la file) ; la règle de mana propre à `signature_bar.dart:114` (**résolue**, Task 8 : `canAfford` sur la signature évoluée).
- **De la partie 3, pour la file** : un `flatBonus` qui vise un effet absent de sa signature est accepté en silence ; `DraftScreen` se quitte par le retour système sans choisir ; le rideau de montée de niveau est en français en dur et ne dit pas ce qui attend ; la reprise des infobulles des cartes ; les faces des cartes, les émojis des statuts ennemis et la rune *Précis* à passer sur `effect_icons.json` ; `asCard` recalculé à chaque lecture (par construction, jamais par image) ; `effectLines` couplé par l'ordre sans `assert`.

## 5. Les leçons

- **Autonomie `continu`, amendement PN12 (d) et PN13 (c) de la spec** : trois tours sans convergence (0/5/9/6, 0/2/6/5, 0/3/5/5), constats de classe T seulement ; l'orchestrateur a appliqué les corrections recommandées du troisième (la face Flame rendue publique avec son type, le renversement de P-6 réécrit, les conséquences de P-5 sur le calque, cinq mineurs, cinq rédactions) ; le dernier tour différentiel rend **prête** (0/0/4/6, corrigés au passage).

1. **Les trois amendements de méthode du propriétaire** (prompt de lancement) : le tri des mineurs visibles à chaque tâche d'interface (S2), la tâche de vérification jouée par l'orchestrateur (S5), le contenu des écrans neufs tranché avant la vague — *bilan en fin de vague*.

## 6. Les statistiques de la session

*À mesurer avant le commit de §3.8.*
