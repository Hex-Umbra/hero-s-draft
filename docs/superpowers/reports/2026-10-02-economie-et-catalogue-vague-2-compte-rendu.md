# Vague 2 — `0.5.4` — E2, fusion = forge — compte rendu

**Chantier** : « Économie unifiée et catalogue » — déroulé par le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md), fiche §8.2.
**Branche** : `feat/v0.5.4-p43-e2-fusion-forge`, ouverte le 02/10/2026 depuis `main` à `559df08`.
**Ouvert le** : 02/10/2026, à la fin du plan de la partie 1 (§3.5). Complété à la fin de la vague (§3.8).
**État** : **en cours** — les deux parties sont implémentées et la simulation relancée ; restent la note de version et la mémoire (§3.7), puis le cahier de test et les statistiques (§3.8).

---

## 1. La branche et ses chiffres

| | |
|:---|:---|
| Porte d'entrée (02/10) | `main` propre et à jour à `559df08` (fusion de la vague 1) ; `v0.5.3` posé sur `main`, release publiée ; trois porteurs de version à `0.5.3` ; `dart analyze` propre ; **1375 tests** — la base de la vague (`a9e2db6`) |
| Arrêt et reprise | Spec non convergée au troisième tour, vague arrêtée (`6e94be7`) ; arrêt levé par le propriétaire le 02/10, reprise sans `stash` (arbre propre, `dart analyze` propre, 1375 tests verts) |
| Spec E2 | Convergée au quatrième tour, `90dd137` |
| E2, partie 1 | Plan `7a071b6` ; cinq commits de code `3eafb5e`..`d6e6cd5` et un correctif de la revue d'ensemble `1407e2e` ; **1426 tests** (+51), `dart analyze` propre |
| E2, partie 2 | Plan `017aa4c` ; neuf commits de code `bcc5b36`..`bff3078` (dont un correctif de revue de tâche, `cd967cf`) et un correctif de la revue d'ensemble `0010ca2` ; **1480 tests** (+54), `dart analyze` propre |
| Simulation (§3.6) | Premier temps sur `9f1f203` : diff vide contre la référence ; second temps sur `bff3078` : 477 lignes, l'écart expliqué au §4 ; référence recommitée |

---

## 2. La table des arbitrages

Chaque question tranchée, ses options, le filtre de l'arbre (orchestration §5) qui a départagé, et le choix. Le propriétaire les lit au moment de son test ; un arbitrage qu'il renverse se corrige sur la branche avant la fusion (§3.10).

### 2.1. Spec E2 — [`2026-10-02-p43-e2-fusion-forge-design.md`](../specs/2026-10-02-p43-e2-fusion-forge-design.md), §1.2

Les vingt arbitrages de la rédaction, tels que la spec les récapitule — le détail de chacun, ses options écartées et ses motifs, est à sa place dans la spec :

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | Le geste de fusion | fusion puis choix obligatoire · choix différable · aperçu puis fusion ; offre tirée par `mergeCards` · par `drawRunes` depuis l'écran ; offre vide | 5 ; 5 (orchestrateur, tour 2) ; 6 (orchestrateur, tour 2) | Fusion, puis un dialogue qui ne se ferme que par un choix ; l'offre tirée par la fonction pure `drawRunes`, appelée par l'écran de deck ; sans rune éligible, la fusion, `deckMergeSuccess`, puis `forgeNoEligibleRune` |
| A2 | Ce que propose le dialogue | 3 au niveau 1 · niveau au rang · fentes tirées ; tirage pondéré · `pools` ; relances et fentes gardées ou non | 1 puis 7 ; 1 ; 1 puis 7 | Trois runes (moins si moins), niveau 1, tirage pondéré sans remise, ni relance ni fente achetée |
| A3 | `forgeTargetCardId` | rien · carte en attente · carte affûtée | 5 | Supprimé, avec `forgeSlots`, `forgeTargetSessions`, `bonusForgeSlots` et leur API |
| A4 | Écran d'affûtage, une fois par visite | exclusivité du feu · compteur · en plus ; sélection + dialogue · dialogue de forge · écran des paires ; état local · Notifier | 1 puis 5 ; 5 puis 6 ; 5 puis 7 (orchestrateur) | L'affûtage remplace la forge parmi trois options exclusives ; sélection puis dialogue des runes de la carte ; état de visite local à l'écran ; après une action, le retour système résout le nœud comme « Continuer » (orchestrateur) |
| A5 | Écran du Puits | réécrit en place · dialogue de carte · sélection du feu ; carte sans la rune donnée · telle quelle ; un échange · plusieurs ; état local · Notifier | 5 ; 6 ; 7 ; 5 puis 7 (orchestrateur) | `ForgeFusionScreen` réécrit ; offre jugée sans la rune donnée ; un échange par visite, état local à l'écran ; après un échange, le retour système résout le nœud, sans échange il ne le résout pas (orchestrateur) |
| A6 | Base du Puits | 50 à part · 50 partagé avec `b` · autre | 5 puis 7 | 50, constante distincte de `b` — pas de second temps |
| A7 | `minFusionRank` des six | 1 · `enduring` à 2 · déduit des pools | 7 | 1 — pas de second temps |
| A8 | Forme de `minFusionRank` | obligatoire ≥ 1 · facultatif · 0 admis | 5 puis 6 | Obligatoire, entier ≥ 1 |
| A9 | Éligibilité de `precise`, `spectral` | dégâts seuls · `precise` sur le soin · `spectral` hors épuisement | 7 | `eligibleEffects: ["damage"]` — pas de second temps ; deux cas latents à la vague 5 |
| A10 | Effet des runes neuves | sortes neuves ; D33 · modèle du script ; préséances ; second temps · exception | 1 ; 1 ; 1 puis 7 ; 2 (orchestrateur) | `reduceCost`, `critBonus`, `addExhaust` ; `spectral` sur la base à la rareté ; l'épuisement l'emporte ; le `spectral` du script aligné, second temps |
| A11 | Copie du deck | prix de boutique · prime · prix du Miroir ; relance ; retirage par le retour : étal tiré une fois par nœud · retour qui résout le nœud · consigné ; l'étal entier : tout `ShopState` · le Miroir vidé au retour ; l'identité du nœud : oubli au changement de nœud courant · clé (acte, id) · id seul | 1 puis 7 ; 1 ; 1 puis 5 (propriétaire, 02/10/2026) ; décision du propriétaire puis 5 (orchestrateur) ; 1 puis 5 (orchestrateur) | 25 · 50 · 100 · 150 · 200, tirée dans `copyableCards`, intouchée par la relance ; **l'étal entier — cartes, copie, soin, Miroir — tiré une fois par nœud de boutique et retenu, achats compris, jusqu'à ce que le nœud courant change** (propriétaire ; le Miroir et l'identité du nœud tranchés par l'orchestrateur) |
| A12 | Pré-forgées | prédicat au rang + niveau tiré · niveau 1 · `pools` | 1 puis 7 | ≤ `fusionRank` runes, prédicat au rang, niveau 80 · 15 · 5 borné |
| A13 | Badge « Usage unique » | `exhaustsOnPlay` · donnée | 5 | Les quatre lecteurs lisent `exhaustsOnPlay` — maintenu par l'orchestrateur ; ferme la conséquence d'ADR-094 pour *Persistant* |
| A14 | `{val}` | toute sorte chiffrée · placeholder par sorte · littéral | 4 | `{val}` général ; cinq descriptions passent à `{val}` |
| A15 | Coût courant du prédicat | applicateur sur le catalogue reçu · `currentCost` | 5 | Sur le catalogue reçu ; en partie 2 (orchestrateur) |
| A16 | Affûtage et échange payants | `GoldManager` · `DeckNotifier` · écrans | 5 | `GoldManager`, formules dans `ForgeRuneRules` |
| A17 | Noms | gardés · renommés | 7 | Gardés |
| A18 | Tutoriel | offre jouée · rune d'office · prose | 5 puis 6 | Offre tirée par la fonction du jeu, choix par le joueur |
| A19 | Icône, couleur | tables étendues · noms repris · emoji seul | 6 | Deux tables `const` publiques, `runeIcons` et `runeColors` (`rune_style.dart`), lues par la ligne de rune et par le test d'intégrité |
| A20 | Découpage | voir §10 | 8 | Deux parties ; `minFusionRank` et « une rune par type » en partie 1 |

**La boucle de vérification de la spec** : quatre tours, chacun par un vérificateur neuf.

| Tour | Constats | Suite |
|:---|:---|:---|
| 1 | 1 moyen (`spectral` du script), 11 mineurs, 1 de rédaction | Corrigés ; cinq arbitrages de l'orchestrateur |
| 2 | 2 moyens (ordre du calcul flottant du script ; un affûtage qui ne fermait pas son dialogue), 7 mineurs, 5 de rédaction | Corrigés ; trois arbitrages de l'orchestrateur |
| 3 | **2 moyens** (le découpage des tests laissait la partie 1 rouge ; la copie du deck se retirait gratuitement par un retour puis une nouvelle entrée), 8 mineurs, 1 de rédaction | **Vague arrêtée** (§3.3, §6) ; arrêt levé par le propriétaire, qui retient les arbitrages recommandés ; les onze constats corrigés ; six questions apparues à la correction, tranchées par l'orchestrateur |
| 4 | 0 bloquant, 0 moyen, 5 mineurs, 4 de rédaction | Corrigés au passage, sans nouveau tour ; **prête** |

**Tranchés par l'orchestrateur au tour 1** :

| N° | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| 1 | `spectral` dans la simulation | relance de second temps · exception consignée | 2 | Second temps : le script aligné sur la forme de D33 dans une tâche à part, après le réalignement ; l'orchestrateur relance, explique l'écart, recommite la référence | A10, §9, §10 |
| 2 | Le motif d'A6 | filtre 2 · filtre 5 | 5 puis 7 | A6 tranchée par le filtre 5 (deux prix que la mesure fait varier séparément sont deux faits), puis 7 ; choix inchangé : 50, constante distincte de `b` | A6 |
| 3 | La partie d'A15 | partie 1 · partie 2 | — | Partie 2, avec `reduceCost` | A15, §10 |
| 4 | L'état « une fois par visite » | état local de l'écran · la règle entière dans un Notifier | 5 puis 7 | État local de l'écran, au feu comme au Puits | A4, A5 |
| 4 bis *(apparue à la correction)* | Le retour système après une action, qui laisse le nœud non résolu | toute sortie après une action résout le nœud · drapeau de visite dans `RunState` · tel quel | Feu : 1 (D14) puis 5, puis 8. Puits : (c) déferait A5 (p) — aucune décision acquise n'y fixe l'échange unique, D14 ne vaut qu'au feu —, puis 5, puis 8 | Toute sortie après une action — au feu un repos, un affûtage ou un oubli ; au Puits un échange — résout le nœud, par le chemin de « Continuer » ; avant toute action, inchangé ; ferme au passage le second repos et le second oubli d'aujourd'hui | A4, A5, §4.7, §4.8, §8, §10, §11 |
| 5 | Les arbitrages apparus à la rédaction | — | — | Consignés par l'orchestrateur ; A13 maintenu (filtre 5 : `spectral` ajoute l'épuisement) | A13 |

**Tranchés par l'orchestrateur au tour 2** :

| N° | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| 5 | Qui tire les trois runes de la fusion | `DeckNotifier.mergeCards` tire et rend l'offre (prose du brainstorm §4.2 `:200`, §11 `:491`) · la fonction pure `drawRunes`, appelée par l'écran de deck, l'écriture par `addForgeUpgrade` | 5 | La fonction pure, appelée par l'écran ; la prose du brainstorm n'est pas suivie à la lettre — une proposition, pas une décision acquise | A1, §4.5 |
| 8 | Les textes joueur qui nomment encore la forge | renommés · laissés | 6 | Un texte que le joueur lit et qui nomme une forge disparue est renommé (« Runes » ou l'équivalent juste), en `_fr` et `_en` ; un texte jamais affiché au joueur ne change pas ; les noms de code restent (A17) | §5.7 |
| 4 | L'offre vide | la fusion, `deckMergeSuccess`, puis `forgeNoEligibleRune` · la fusion et `deckMergeSuccess` seule · la fusion et `forgeNoEligibleRune` seul | 6 | La fusion se fait ; `deckMergeSuccess`, puis `forgeNoEligibleRune` ; `_MergeDialog` se ferme sur la `CardInstance` rendue | A1, §4.5, §8 |

**Tranchés à la levée de l'arrêt (tour 3)** — la ligne 2 est la décision du propriétaire :

| N° | Question | Options | Filtre | Choix | Où |
|:---|:---|:---|:---|:---|:---|
| 2 | La copie — et l'étal entier — retirée gratuitement : le retour système quitte la boutique sans résoudre le nœud, et l'écran retire l'étal à chaque entrée | l'étal tiré une fois par nœud de boutique · le retour système résout le nœud · consigner | 1 écarte « consigner » (D46, « tirée et non choisie ») ; 5 retient l'étal tiré une fois contre le retour qui résout : l'étal est déjà l'état du Notifier de la boutique, et sortir sans acheter doit rester possible, comme au Puits sans échange — ce qui rouvrirait le tirage | **Décidé par le propriétaire le 02/10/2026** : l'étal tiré une fois par nœud de boutique, **étendu à l'étal entier** — la boutique retient le nœud pour lequel elle a tiré son étal, copie comprise, et ne le retire pas tant que ce nœud n'est pas résolu ; ferme au passage le retirage gratuit de tout l'étal, un défaut antérieur, dit dans la note. Trois points apparus à sa mesure sont tranchés ci-dessous (2 bis, 2 ter, 2 quater) | A11, §2, §3.4, §4.9, §4.14, §7, §8, §9, §10, §11 |
| 2 bis *(apparue à la correction ; tranchée par l'orchestrateur)* | Ce que « l'étal entier » comprend : le retour système vide aujourd'hui le Miroir — options et prix — par `clearCloneOptions` (point 5 d'ADR-067) | tout `ShopState`, Miroir compris · les cartes, la copie et le soin, le Miroir vidé au retour comme aujourd'hui | La décision du propriétaire (« l'étal entier », « ce qui a été acheté reste acheté ») écarte le second, puis 5 : un état, une seule remise à zéro ; le point 5 d'ADR-067 rouvre ce que son point 4 ferme — le prix ramené à 150 par un aller-retour —, et la remise à zéro au nœud sert l'intention même d'ADR-067, limiter le clonage abusif | Tout `ShopState`, Miroir compris ; `clearCloneOptions` et le `PopScope` de `ShopScreen` supprimés ; le Miroir repart au nœud suivant. Le point 5 d'ADR-067 est amendé par l'ADR neuf de la vague, à `memory-bank-sync` — un ADR publié ne se réécrit pas | A11, §4.9, §4.14, §8, §10, §11 |
| 2 ter *(apparue à la correction ; tranchée par l'orchestrateur)* | L'identité du nœud : son id, `node_<étage>_<colonne>`, revient à chaque acte et à chaque run | l'état oublié dès que le nœud courant change · la clé (acte, id) et une remise à zéro dans `startNewRun` · l'id seul | 1 écarte l'id seul (D46 : la copie d'un autre deck) ; 5 retient le premier contre la clé (une règle, à un endroit) | L'état de `ShopController` revient à `const ShopState()` dès que `currentNodeId` change. La spec fixe le mécanisme, pas la tournure Riverpod : le plan choisit entre `ref.listen` sur un `select` et `ref.watch` sur un `select` dans `build`, qui reconstruit l'état, et dit la forme retenue ; un test garde la remise à zéro au changement de nœud | A11, §4.9, §8, §10 |
| 2 quater *(apparue à la correction ; tranchée par l'orchestrateur)* | `initializeShop` appelé sans nœud courant — les tests unitaires qui tirent l'étal en boucle | chaque appel tire · l'étal gardé aussi pour un nœud nul | 8 | Chaque appel tire ; l'étal n'est gardé que si `nodeId` est non nul et égal au nœud courant | §4.9, §8 |
| 5 | La partie où se supprime un test qui garde un comportement encore vivant — le groupe `stackable` de `forge_rune_rules_test.dart:58-84`, qui lit des runes sans `minFusionRank` | supprimé dès la partie 1 · gardé, avec la clé qui lui manque, jusqu'à la partie qui supprime ce qu'il garde | 5, puis 8 | **Tranché par l'orchestrateur** : un test qui garde un comportement encore vivant n'est supprimé que dans la partie qui supprime ce comportement — prolongement, aux tests, de l'invariant de §10 ; le groupe `stackable` gagne `minFusionRank` en partie 1 et disparaît en partie 2, avec `stackable` ; la règle vaut pour chaque suppression de §8 | §8, §10 |
| 5 bis *(apparue à la correction ; tranchée par l'orchestrateur)* | Les cas « non cumulable » de `forge_rune_rules_test.dart:94-104`, que la spec disait supprimés : avec `maxLevel: 1` (n° 4), ils passent sans changer d'attente | supprimés en partie 2 · gardés en partie 2 comme cas de plafond 1 | La règle du n° 5 : ils gardent un comportement encore vivant, `enduring` plafonné à 1 | Ils deviennent, en partie 2, des cas de plafond 1, leurs attentes inchangées | §8 |
| 9 | Où tourne la relance du premier temps, quand le code de la vague est fini et que la branche a dépassé le commit de réalignement | un clone jetable hors du dépôt · l'archive du commit (`git archive`) extraite dans le dossier temporaire de la session · le commit extrait dans le checkout principal · un worktree | 5, puis 8 | **Tranché par l'orchestrateur** : un état extrait hors du dépôt, au commit de réalignement, sans changer de branche dans le checkout principal ni ouvrir de worktree — `git archive <commit> tool/simulations assets/data`, extrait dans le dossier temporaire de la session, puis `dart run` lancé de là | §9, §10 |
| 9 bis *(apparue à la correction ; tranchée par l'orchestrateur)* | Où tourne la relance du second temps | de même, extraite au commit `spectral` · dans le checkout principal | — | Elle **peut** tourner de même, sans que la spec l'impose : la tâche `spectral` est la dernière à toucher le script, et aucune tâche ne touche `assets/data/` après elle | §9, §10 |
| 10 bis *(apparue à la correction ; tranchée par l'orchestrateur)* | La ligne de niveau d'une rune au plafond, dans le dialogue d'affûtage | pas de ligne · une seconde clé « Niveau {level} » · `runeMaxLevel` sur la ligne | 6, puis 8 | Pas de ligne de niveau : le bouton dit déjà « Niveau maximal » | §4.7, §8 |

**Au tour 4**, un seul choix de l'orchestrateur : les options écartées des trois tableaux ci-dessus ne sont pas recopiées dans les alternatives écartées de la spec (§12), qui y renvoie — un fait à un seul endroit.

### 2.2. Plan E2, partie 1 — [`2026-10-02-p43-e2-fusion-forge-partie-1.md`](../plans/2026-10-02-p43-e2-fusion-forge-partie-1.md)

Deux tours de vérification. Le premier vérificateur a rejoué le plan tâche par tâche sur une extraction de `90dd137` hors du dépôt : un constat moyen, sept mineurs. Le second l'a rejoué en entier sur sa propre extraction — chaque tâche verte et propre, totaux mesurés égaux aux annoncés (1398 · 1398 · 1404 · 1421 · 1426) : prêt, deux mineurs corrigés au passage par l'orchestrateur (la commande de contrôle de la session de forge ne voyait pas `resetForgeTarget…` ; `shop_controller_test.dart` manquait à la carte des fichiers).

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| P1 | Un test de la Task 3 rouge : le premier dialogue de fusion, qu'on ne ferme que par un choix, restait sur le Navigator *(constat moyen du tour 1)* | vider l'écran avant la seconde ouverture · scinder le cas en deux | 8 | `await tester.pumpWidget(const SizedBox());` avant la seconde ouverture ; totaux inchangés |
| P2 | Deux tests sur une carte qui porterait deux exemplaires d'une même rune, venus d'une sauvegarde d'avant E2, et un point de revue sur une rune absente du catalogue | les garder · les retirer | Garde-fou de l'orchestration §6 (la compatibilité des sauvegardes n'est jamais un sujet avant la `1.0.0`), puis « pas de code sans lecteur » | Les deux tests et la branche de `replaceRune` qui ne servait qu'à réunir des doublons sont retirés ; `replaceRune` prend sa forme la plus simple ; le test du cas `null` de `hasSharpenableRune` reste, sans cadrage « sauvegarde » ; la Task 4 passe de +21 à +19 tests |
| P3 | La forge du feu pendant la Task 3, et `gold_manager.dart` *(point 1 du plan)* | le feu sur le dialogue réduit le temps d'une tâche, le fichier supprimé puis recréé · fusionner les Tasks 3 et 4 · avancer `sharpenRune` d'une tâche | 7 (une tâche démesurée), puis « pas de code sans lecteur » | Gardé tel que le plan l'écrit : le moindre mal, jugé par le vérificateur du tour 1 ; sans effet sur le code final |
| P4 | Le tutoriel : SUIVANT attend le choix de la rune ; la carte semée devient *Éveil* (sa fusion offre *Endurci*) au lieu de *Concentration* *(point 12 du plan, hors spec)* | attendre le choix · libérer SUIVANT dès la fusion | 6, cohérent avec A1 et A18 (l'étape enseigne un choix) | Consigné ; un test le garde depuis la revue d'ensemble (S5) |
| P5 | L'assistant de test `_cardWith` gagne un lecteur en Task 4, alors que la spec le disait supprimé en partie 2 avec `fusionOptionsFor` *(point 11 du plan)* | — | — | Consigné : la partie 2 le garde |

Les treize points par lesquels le plan précise ou corrige la spec sont dans sa section « Ce que le plan précise ou corrige de la spec » ; aucun n'amende un arbitrage.

### 2.3. Les décisions de SDD — exécution du plan de la partie 1

Recopiées du registre de SDD avant la suppression de son espace de travail, dans l'ordre où elles ont été prises, chacune avec ce qu'elle coûte si elle est fausse. Implémenteurs Sonnet, relecteurs Sonnet (Opus pour les Tasks 3 et 4, les plus grosses), revue d'ensemble Opus. Chaque revue de tâche a approuvé au premier passage : aucun tour de correction.

| # | Décision | Motif | Si elle est fausse |
|:---|:---|:---|:---|
| S1 | Contrôle préalable : `gold_manager.dart` supprimé en Task 3 puis recréé en Task 4, et le chemin provisoire du feu en Task 3, gardés tels que le plan les écrit | Jugés le moindre mal au premier tour de vérification du plan ; l'autre ordre laisserait `sharpenRune` sans lecteur pendant un commit | Un aller-retour de fichier dans l'historique ; aucun effet sur le code final |
| S2 | Task 3 : le `Random()` construit dans l'écran de deck (`deck_screen.dart:186`) gardé | La spec (A1, §4.5) écrit `drawRunes(carte, registre.forgeUpgrades, Random(), count: 3)` ; `deckRandomProvider` existe et rendrait l'offre fixable en test | Des tests d'écran en `isIn([...])` au lieu d'une offre fixée |
| S3 | Task 3 : le chemin provisoire du feu (titre de fusion, sans Annuler, niveau 1) gardé pour la seule Task 3 | Imposé par le plan, retiré par la Task 4 ; `CLAUDE.md` redevient exact à la Task 4 | Aucun : la branche n'est pas testée à ce commit |
| S4 | Task 4 : des références en double d'une même rune (`sharp:1`, `sharp:1`) s'affûtent ensemble en deux `sharp:3` — laissé | Elles ne naissent que d'une sauvegarde d'avant E2 : la condition 8 et `consolidate` les empêchent dans une partie neuve ; arbitrage P2 | Une ancienne sauvegarde surévalue une rune affûtée — les sauvegardes sont jetables avant la `1.0.0` |
| S5 | Revue d'ensemble : deux mineurs corrigés aussitôt (`1407e2e`) — le solde d'or dans le dialogue d'affûtage (l'ancien dialogue du feu le montrait), et une assertion qui garde SUIVANT verrouillé tant que l'offre de rune du tutoriel attend | Peu coûteux ; le premier est ce que le joueur lit (filtre 6), le second garde le comportement que P4 a ajouté | Quelques lignes de plus dans la partie 1 |
| S6 | Revue d'ensemble : renvoyés à la partie 2 — une garde « carte de rang ≥ 2 » dans le test des pré-forgées (réécrit avec `drawRunes`) ; les refus de `sharpenRune` pour une rune non portée ou absente du registre, à côté des refus d'`exchangeRune` ; « ⚙️ Upgrades: » en anglais dans les deux langues (`ui_card_helpers.dart:423`) ; le débordement des prises en combat quand une carte dépasse cinq runes (`card_text_renderer.dart:366`, badge `:415`) | Chacun touche ce que la partie 2 réécrit, ou n'arrive qu'avec elle (plus de runes par carte) | Un plan de partie 2 un peu plus long |
| S7 | Revue d'ensemble : renvoyés à la file (§5) — trois mineurs | Antérieurs à la branche, ou durcissements sans effet en jeu | Rien en `0.5.4` |

Mineurs différés pendant les revues de tâche, triés par la revue d'ensemble : résolus par les tâches suivantes — le niveau porté passé à `boundLevel` dans l'ancien dialogue, la forme imbriquée de `mergeCards`, le `pop(true)` après un trio invalide ; laissés — une offre vide ouvrirait un dialogue qu'on ne ferme pas (impossible : l'appelant teste l'offre vide), des ids en double dans `mergeCards` (l'écran passe un ensemble), `_removeCard` qui lit `ref` avant de tester `mounted` (antérieur, inatteignable), le niveau recalculé par le message d'affûtage, l'offre vide du tutoriel testée au seul niveau du widget, le bouton de rune du tutoriel trouvé par sa clé en texte.

### 2.4. Plan E2, partie 2 — [`2026-10-02-p43-e2-fusion-forge-partie-2.md`](../plans/2026-10-02-p43-e2-fusion-forge-partie-2.md)

Écrit sur le code que la partie 1 a laissé, et rejoué par son rédacteur sur une extraction hors du dépôt. Un tour de vérification : le vérificateur l'a rejoué tâche par tâche sur sa propre extraction. Résultat : chaque tâche verte et propre, totaux mesurés égaux aux annoncés (1435 · 1435 · 1450 · 1450 · 1453 · 1475 · 1480 · 1480 · 1480), tests aléatoires rejoués huit fois, fumée `--quick` après le réalignement identique à l'octet. **Prêt** ; sept mineurs corrigés au passage par le rédacteur, sans qu'aucun total bouge.

Questions que le plan a tranchées sans que la spec les pose, jugées conformes par le vérificateur et consignées par l'orchestrateur :

| # | Question | Choix | Motif |
|:---|:---|:---|:---|
| P6 | La tournure Riverpod de l'étal retenu (la spec, 2 ter, la laissait au plan) | `ref.listen` sur un `select` de `currentNodeId` dans `ShopController.build` | Avec `ref.watch`, le Notifier devient périmé au changement de nœud et `initializeShop` lève l'assertion de Riverpod « Cannot use ref functions after the dependency of a provider changed » — mesuré : sept tests rouges |
| P7 | Le cas `steadfast` de `shop_controller_test`, que le tableau du tour 3 de la spec (n° 4) disait réécrit en `maxLevel: 1` | Supprimé, dans la tâche qui retire la lecture d'`isStackable` par la boutique | Réécrit, il doublait le cas `capped` voisin ; le plafond 1 en boutique reste gardé par `capped` — rien n'est perdu |
| P8 | Comment des tests gardent l'absence de `pools` et `stackable` | Ils comparent l'ensemble exact des clés (`toJson`, les clés de chaque fichier), sans nommer les deux mots | Les commandes de contrôle de la spec (§4.11) ne rendent alors que les trois homonymes ; les tests sont plus forts que ceux que §8 demandait |
| P9 | « ⚙️ Upgrades: », en anglais dans les deux langues (S6) | Une clé ARB `tooltipRunes` (« Runes : » / « Runes: ») | La règle de §5.3 pour `lib/ui` |
| P10 | Le débordement des prises en combat (S6) — mesuré : 9 runes au plus, sur un *Cri de Guerre* épique ou mieux, deux rangées de prises | La fonction pure `CardTextRenderer.centerBlockTop`, qui garde le bloc central sous l'en-tête, les prises et le badge | Écartés : des prises plus petites, plus de prises par rangée |
| P11 | La mise en page de l'écran du Puits | Une colonne défilante : les cartes, la rune à donner, les remplaçantes | A5 fixe l'ordre, pas la mise en page |
| P12 | `ShopScreen.build` | Remplacé en entier ; l'état vide garde son centrage | Retirer le `PopScope` sans `dart format` laissait 170 lignes mal indentées |
| P13 | Les particules d'épuisement | `exhaustsOnPlay && type != power` | La lettre d'A13 : les pouvoirs restent ignorés |
| P14 | Le commentaire d'en-tête du script de simulation (« jetable … ni committé ») | Corrigé dans la tâche de réalignement | Le script est suivi par git depuis le 01/10, sa sortie de référence aussi |

### 2.5. Les décisions de SDD — exécution du plan de la partie 2

Même méthode que pour la partie 1 : implémenteurs Sonnet, relecteurs Sonnet (Opus pour les Tasks 1, 3 et 6), revue d'ensemble Opus, base de la revue d'ensemble `017aa4c` — le commit où le plan commence (§3.5). Une seule revue de tâche a demandé un tour de correction (Task 1).

| # | Décision | Motif | Si elle est fausse |
|:---|:---|:---|:---|
| S8 | Task 1 : un constat important, imposé par le code du plan — la couleur blanche forcée du titre masquait l'état choisi et l'état inactif de la rune à donner au Puits — **corrigé** (`cd967cf`) | La spec §4.8 veut qu'une rune sans remplaçante « se montre inactive » ; filtre 6, sur un échange payant et irréversible | Trois lignes de style |
| S9 | Task 6 : le coût courant d'une carte passe désormais par l'applicateur, et le rendu Flame le relit à chaque image pour chaque carte en main — gardé | La spec §4.2 impose ce passage ; aucun blocage de la boucle, seulement des allocations, qu'une mémorisation supprimerait plus tard | Des allocations par image, à mesurer si le combat ralentit |
| S10 | Revue d'ensemble : quatre mineurs corrigés aussitôt (`0010ca2`) — le test de couleur du Puits, qui passait sur l'ancien code ; le test bout à bout de *Précis*, qui ne détectait une rupture du câblage qu'une fois sur deux ; la ligne du tutoriel « Même coût, rareté supérieure. », qui contredisait la carte quand *Allégé* venait d'être choisi — elle ne s'affiche plus que tant qu'aucune rune n'est choisie ; la doc de `ForgeSlotRow.detail` | Peu coûteux ; le troisième est ce que le joueur lit (filtre 6) | Une quinzaine de lignes |
| S11 | Revue d'ensemble : la phrase du §7 de la spec — l'étal retiré « après tout chargement de sauvegarde » — contredisait 2 ter, que le code suit ; corrigée dans la spec | Sans effet en jeu : une sauvegarde prise sur un nœud de boutique l'a résolu | Aucun |
| S12 | Revue d'ensemble : renvoyés à la file (§5) — sept mineurs de test et de forme | Aucun ne change le jeu | Rien en `0.5.4` |

Mineurs différés pendant les revues de tâche, triés par la revue d'ensemble — laissés : `exchangeRune` et `sharpenRune` partagent une recherche et une fin presque identiques (à factoriser à la troisième copie) ; le journal de débogage que le test d'une rune absente du registre imprime ; la rune relue par `firstWhere` après `drawRunes` ; le bloc de tirage de l'étal répété par `initializeShop` et `rerollCards` ; le prix de la copie calculé deux fois à l'écran ; le message d'achat de la copie, recopié de celui d'une carte ; la liste des clés du modèle tenue deux fois dans le test du catalogue ; un `percentBonus` sans effet correspondant qui arrêterait la recherche de `{val}` (aucune rune livrée n'a cette forme) ; la hauteur du badge écrite deux fois ; `centerBlockTop`, qui descend aussi une carte sans rune à description très haute (voulu) ; deux commentaires du script et un du test de mise en page.

---

## 4. La simulation

`tool/simulations/d26_economy_sim.dart`, relancé en deux temps (§3.6, D73), chaque fois sur une extraction hors du dépôt (`git archive <commit> tool/simulations assets/data`, spec §9), sortie vers `.superpowers/`, comparée par `git diff --no-index` à la référence suivie, `tool/simulations/d26_reference_output.md`.

**Premier temps — le réalignement seul** (`9f1f203`, Task 8 de la partie 2). Le script lit ses runes par une liste d'ordre explicite des 17 ids ; les trois fichiers neufs prennent la place exacte de leurs entrées en dur. Mesure complète en 467 s : **diff vide** contre la référence, ligne « Données lues » comprise — elle compte les runes, 17, et non les fichiers (§5). La fumée `--quick` de la tâche l'avait déjà montré : même empreinte md5 avant et après.

**Second temps — le `spectral` du script suit D33** (`bff3078`, Task 9, changement voulu, A10). Avant, le script multipliait la valeur par coup par `1 + 0,4 × niveau`, Puissance et part de `sharp` comprises. Désormais, comme dans le jeu, la rune ajoute 40 % de la valeur de base à la rareté par niveau, au moins +1, sans jamais multiplier la Puissance. Mesure complète en 406 s : **477 lignes sur 798 changent**, dans toutes les tables qui mesurent un combat. L'écart s'explique entièrement par ce changement :

- **Les dégâts baissent là où la Puissance est forte.** Dégâts par tour à l'acte 15, toutes configurations : 752 → 659. Le Berserker, dont la Puissance s'applique aux Attaques et qui convertit son armure, perd le plus : Sang 4285 → 2543, Vampire 933 → 610, Carnage 778 → 574. Le Paladin et le Mage bougent peu (Croisé 853 → 836, Arcaniste 875 → 834, Marque 933 → 938).
- **L'or et l'affûtage suivent.** L'IA du script valorise moins `spectral`, affûte un peu moins (Σ niveaux à l'acte 15 : 73 → 71) et garde plus d'or (5596 → 5900). Le constat de P-16 sur l'or qui dort se renforce.
- **Ce que les décisions mesurées supposent ne bouge pas.** Le deck fait 35 cartes à l'acte 15, les fusions sont 45 et le héros est niveau 30 avec 12 évolutions (D56, D67). La DDA à k = 2 reproduit toujours la courbe d'aujourd'hui : budget à l'acte 15 de 786 contre 785 pour la formule actuelle (D59). Les quasi-morts à l'acte 15 restent à 233 → 234.
- **La table d'XP que le script recale à chaque lancement bouge de −25 à +40 XP selon l'acte** (115 · 200 · 310 · 475 · 590 · 770 · 955 · 1080 · 1050 · 1190 · 1410 · 1345 · 1275 · 1380 · 1040, contre la table de D67). C'est une sortie de calibration, pas une valeur du jeu : D67 reste acquise et la vague 3 l'écrira telle quelle. La fiche de la vague 3 prévoit que le script lise alors la table du jeu, la calibration restant affichée à côté (§5).

La référence est recommitée sur la sortie du second temps : la vague 3 se comparera à elle.

---

## 5. Trouvé périmé, et pour la file

*Ouvert à la fin de la partie 1 ; complété à la fin de la vague.*

**Prémisses de la spec que le plan de la partie 1 a corrigées en re-mesurant** : l'assistant `_cardData` de `card_rarity_test.dart` et son import ne servaient que le groupe de capacité, supprimés avec lui ; la rune du `setUp` de `run_state_persistence_test.dart` ne servait que `forgeSlots` ; le repli du tirage des pré-forgées (`shop_controller.dart:135-136`) devenait mort avec la condition 8, retiré avec son commentaire ; `_isStepActionComplete` (`tutorial_screen.dart`), que la spec ne nommait pas, devait attendre le choix (P4) ; `_cardWith` survit en partie 2 (P5).

**Ce que la revue d'ensemble apprend de la méthode** : le plan a ajouté un comportement (P4) sans le test qui le garde ; ni la spec ni le plan n'ont reporté le solde d'or que montrait le dialogue remplacé ; le relevé des textes de la spec (§5.7), qui cherchait « forge », a manqué « Upgrades ».

**Trouvé périmé en partie 2** :
- **le fichier d'orchestration, §3.6 et §7.3, dit que la ligne « Données lues » de la simulation compte les fichiers** : elle compte les entrées que le script joue (`data.runes.length`, `d26_economy_sim.dart:3840`) — 17 runes avant comme après le réalignement, 20 avec le script non réaligné. La spec (§9) le disait déjà. Pour la vague 3, l'écart « attendu d'avance » sur cette ligne est donc probablement nul, et un réalignement correct rend un diff entièrement vide ;
- **la table d'XP que le script recale** dérive de −25 à +40 XP par acte sous le `spectral` aligné (§4) : la vague 3, qui fait lire au script la table du jeu, aura les deux sous les yeux ;
- le relevé de la spec (§8) ne listait pas trois tests que la partie 2 change (`entity_id_convention_test`, qui compte les fichiers ; un cas de `deck_screen_test` qui rougissait au hasard avec sept runes offertes au lieu de quatre ; un commentaire de `tutorial_engine_test`), et des références que la partie 1 avait déplacées — le plan de la partie 2 les a re-mesurées.

**Pour la file** :
- la copie du deck testée avec une seule carte copiable : un retour à `copyable.first` passerait ;
- le test des pré-forgées nommé « à leur poids » ne vérifie pas les poids ; le cas « la rareté sans effet » de `reduceCost` n'applique pas le delta ;
- pas de test d'écran pour « Quitter le Puits » sans échange, « Échanger » inactif faute d'or, ni une boutique sans carte en vente mais avec une copie ;
- un `_drawCardsForSale` partagé par `initializeShop` et `rerollCards` ; `exchangeRune` et `sharpenRune` à factoriser à la troisième copie ;
- le coût courant recalculé à chaque image (S9) : une mémorisation sur `CardInstance` si le combat ralentit ;
- l'en-tête de la carte Flutter (`UiCard`) a une position de description fixe : deux rangées de prises et le badge pourraient la serrer, sur une carte épique de six runes ou plus — non mesuré ;
- les textes français en dur du dialogue de fusion (`deck_screen.dart:266`, `:327`), antérieurs à la branche — un joueur anglais les voit quand il tient plus de trois exemplaires ;
- une garde `selectedIds.toSet().length != 3` dans `DeckNotifier.mergeCards`, qui vérifierait elle-même son entrée ;
- l'emoji d'une rune calculé deux fois, en Flame et en Flutter (`ui_card_helpers.dart:221`, `card_text_renderer.dart:535`) — une fonction du modèle le dirait une fois.

**À signaler au propriétaire** :
- le libellé anglais « SHARPEN » du feu côtoie la récompense de niveau « Sharpening » (`level_up_rewards/sharpening.json`, « Aiguisage » en français) ;
- *Précis* au niveau 10 ajoute 50 points de critique : sur le Berserker (10 de base) et avec des récompenses de critique, une carte peut devenir critique à coup sûr — c'est la donnée du brainstorm (§8, `maxLevel` 10), à regarder au test.
