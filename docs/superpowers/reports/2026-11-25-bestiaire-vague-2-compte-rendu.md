# Vague 2 — `0.6.2` — les cadres de tier et les décors — compte rendu

**Branche** : `feat/v0.6.2-cadres-et-decors` · **Cadrage** : [bestiaire, P-05](../../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md) (B66 à B89) · **Spec** : [cadres et décors](../specs/2026-11-25-p05-cadres-et-decors-design.md) ([vérifications](../specs/2026-11-25-p05-cadres-et-decors-design-verifications.md)) · **Plan** : [cadres et décors](../plans/2026-11-25-p05-cadres-et-decors.md) ([vérifications](../plans/2026-11-25-p05-cadres-et-decors-verifications.md))

*Ouvert le 25/11, à la fin du plan. Méthode : le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) §3 à §6, lu pour ce chantier par son [README](../../chantier_bestiaire/README.md).*

## 0. Pour le propriétaire

**À tester d'abord**, par risque (le détail est au [cahier des tests manuels](2026-11-25-bestiaire-vague-2-tests-manuels.md), T1 à T22) :

1. **L'appui sur un ennemi** (T1) : la barre et les languettes n'ont plus leur propre appui, c'est la carte qui le reçoit ; toucher une épine, une vrille, le haut de la barre, une languette au repos et une languette déroulée — chez un ennemi et chez le héros : aucun test automatique ne le couvre.
2. **La fenêtre maximisée et le plateau qui suit la fenêtre** (T2, T3) : ouverture, « Restaurer », relance ; sur ce poste, **Smart App Control a bloqué l'exécutable fraîchement construit** : rien n'a été vu sous Windows, le build web seulement.
3. **La fiche doublée** (T4) et **les cadres des tiers 2 et 3** (T8) : le coup d'œil n'a croisé que des Gobelins de tier 1.

**Vu dans le jeu lancé** (build web de debug, 1920 × 1080 et 1280 × 720, un à trois Gobelins) : cadre net à ×2, illustration bien recadrée, plus de liseré blanc, décor net, autres écrans inchangés, aucune erreur ; et trois points d'aspect, conformes à la spec, que vous êtes le premier à juger : le contour cyan (6 px à ×2) et surtout l'ambre de la fiche ouverte (16 px) couvrent le trait intérieur du cadre ; la gangue de gel est une bordure blanche de 8 px dans la fenêtre, qui peut rappeler l'ancien liseré ; la carte ouverte d'un ennemi seul descend sur la moitié haute du héros estompé (B40).

**Les arbitrages que le joueur verra** : vos réponses B83 à B89 ; aucun autre. **Faits sans vous** : rien en autonomie `continu` ; la retouche de `CLAUDE.md` n'est pas faite, ses trois textes sont au §4.

**Risques connus** : le tout premier palier se calcule avec un rapport de pixels de 1 (corrigé à la reconstruction suivante, à voir sur un écran à 125 %, T3) ; le héros apparaît un instant à 0,6 de la hauteur avant 0,51 (antérieur à la vague, T22) ; un fichier caché de Windows (`Thumbs.db`, `desktop.ini`) dans `assets/data/locations/forest/` fait échouer le démarrage, comme la spec le veut. Le fond de forêt propre à chaque ennemi existe mais ne se voit pas : les peintures d'aujourd'hui le couvrent (T21).

**Un écart de méthode** : la phrase fausse de la note de version (la forêt « ne se voit pas ») a été corrigée directement dans `patch_notes.json` par l'agent, et non par le skill — une ligne, juste, la version n'étant pas taguée.

**Rejouer l'essentiel** : `flutter test test/unit/board_scale_test.dart test/unit/enemy_row_test.dart test/unit/heros_draft_game_targeting_test.dart` · `dart analyze` · `bash .github/scripts/verify_version.sh 0.6.2`.

## 1. La branche et ses chiffres

| Plan | Commits de code | Tests | `dart analyze` | Superpowers | Claude Code |
|:---|:---|:---|:---|:---|:---|
| Cadres et décors | 10 (`589917be..4b108dfe`, après le plan `54e8a1ab`) ; base de la branche : `e2a96432` | 1939 → **2023** | `No issues found!` | 7.0.0, `bb92a77` | 2.1.319 |

## 2. Les arbitrages

Une ligne chacun ; les options écartées sont dans les fichiers de vérifications de la spec et du plan.

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| B83 à B89 | Six questions nées de la spec : le palier en 1440p et en 4K, la fiche au-delà de ×2, le plateau sous le 1080p, la fenêtre au lancement, le décor hors 16:9, le fond de fenêtre, la carte ouverte au bord | D (3), P (3) | Vos réponses du 25/11, sur maquettes, toutes selon la recommandation ; la vague s'est arrêtée à la spec pour les attendre | — |
| A1, A3, A4 | Les couches ; le lieu ; le lieu courant | T | Fonctions pures sous `lib/game/systems/`, modèles sous `lib/models/data/`, Flame qui reçoit et ne lit aucun provider ; un dossier `locations/<id>/` sans JSON, lu dans le manifeste ; le seul lieu du catalogue, zéro ou deux refusés au chargement | 5, 7, 8 |
| A2, A7 | La table des cadres ; le refus d'un tier sans cadre | T | `tier_frames.json`, images sous `assets/data/frames/` (l'identité visuelle §4.1 et §7.2 écartée, motivée) ; le refus au chargement, avec les autres fautes | 4, 5 |
| A5, A6 | Le repli du décor ; les autres écrans | T | `combat.png` obligatoire, `bg_dungeon.png` et `assets/images/` supprimés ; un paramètre de `ScreenScaffold`, déclaré par six écrans, dormant | 1, 8 |
| A8 à A10 | Le palier ; la place d'une carte ; la hauteur des fenêtres | T | En pixels physiques, sur une rangée de référence de six cartes ; 146 pixels de cadre par place, écart de 7, largeur utile 0,95 ; centre des fenêtres à 0,21 de la hauteur | 1, échelle existante |
| A11, A12 | La taille de la carte ; reconnaître un ancien sprite | T | Le canevas de son tier, ancré au centre ; la taille de l'image, recadrée sur x 308–1388, y 329–1949 | 5, 7 |
| A13 | Le fond de fenêtre | T | Tiré à la naissance de la carte, tenu par elle, non sauvegardé (B87) | 5 |
| A14 à A17 | Le contour ; la gangue et le halo ; les ancres ; la zone | T | Le contour à l'extérieur de la fenêtre, avec sa lueur ; gangue et halo sur la fenêtre (identité visuelle §4.2.3) ; les ancres au gabarit ; une seule zone, test d'appui de la carte, coins compris (constat moyen du tour 1 de la spec) | 1, 6 |
| A18, A19 | La fiche ; l'export | T | Doublée, descente de 77 pixels de cadre × le palier ; `export_jeu.py`, par `aseprite --batch --save-as` | B84, 8 |
| A20 à A22 | L'éditeur ; le découpage ; la fenêtre maximisée | T | L'éditeur ne change pas ; un plan, sept tâches et une vérification ; `SW_SHOWMAXIMIZED` | 7, 1 |
| — | Une fenêtre décentrée ; le décalage de la carte ouverte ; le lissage sous ×2 | T | Refusée au chargement ; `inspectionShift`, fonction pure, arrondi vers l'intérieur ; `FilterQuality.medium` | 8, 5, 8 |
| D1 à D15 | Les décisions du plan | T | Plan, « Décisions du plan » ; D1 : le rejeu sur cartes montées est un test jetable, faute de pouvoir monter un jeu sans membres `@internal` de Flame ; D3 : la rangée de quatre places fait 1270 et non 1271, l'arrondi au pixel ; D7 : l'option `-I` du premier jet venait du brief de l'orchestrateur, retirée | 1, 5, 6, 8 |

**L'arrêt.** Un, à la spec, après son tour 1 : trois questions de classe D et trois de classe P, posées sur maquettes à la taille réelle de l'écran ; levé le même jour par vos réponses (B83 à B89). Deux tours de spec, deux tours de plan, tous deux conclus « prête » et « prêt ».

**Décisions de SDD** (registre recopié avant sa suppression ; sept tâches et la vérification finale ; trois tours de correction de tâche, une passe de revue d'ensemble, toutes relues) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S1 | Pas de worktree, le checkout principal sur la branche ; `finishing-a-development-branch` non invoqué | T | — |
| S2 | La retouche de `CLAUDE.md` (Task 1, Step 7) n'est pas jouée : le précédent de la vague 1 vous laisse ce fichier ; ses trois textes sont au §4 | T | `CLAUDE.md` reste faux sur trois points jusqu'à votre retouche |
| S3 | Le RED non joué de la Task 2 se prouve par six mutations des trois algorithmes ; une mutation qu'aucun test ne prenait (l'arrondi du pas de la rangée) a son test | T | Un écart de méthode TDD, tracé |
| S4 | La couture Flame du décor, sans test permanent possible (D1), est mesurée au rejeu monté jetable de la Task 6 ; son filtrage `none` est fixé explicitement et testé | T | La pose du décor n'a de test que jetable et manuel |
| S5 | Le champ `_frameSprite` naît à la Task 5, son premier lecteur, et non à la Task 4 | T | — |
| S6 | Trois tests de plus que le plan (deux corrections, une revue d'ensemble) : 2023 au lieu de 2020 | T | — |
| S7 | La revue d'ensemble : un mineur corrigé (le bloc « états visuels » sans effet de `EnemyCard.onLoad`, qui privait de lueur une carte chargée en plein ciblage), tous les autres laissés, chacun avec sa raison | T | Voir §4 |

## 3. Les tests manuels

[2026-11-25-bestiaire-vague-2-tests-manuels.md](2026-11-25-bestiaire-vague-2-tests-manuels.md) — 22 tests. Résultat : à remplir par vous.

## 4. Trouvé périmé, et pour la file

- **`CLAUDE.md`, trois descriptions fausses** depuis la Task 1, laissées à vous : l'arbre de « Data-Driven Content Workflow » gagne `tier_frames.json` parmi les documents plats, `frames/tier_<n>.png` et `locations/<id>/{combat.png, window_<1-3>.png}` ; la couche de données gagne `tier_frame_data.dart` et `location_data.dart`, le lieu et les cadres étant lus dans le manifeste sans JSON ; `GameDataLoader` expose `assetsMatching(pattern)` et `fault(message)`.
- L'identité visuelle §4.1, §7.2 et §9.3 (table `const`, `assets/art/`, migration `assets/images/` → `assets/art/`) est écartée par A2, A3 et A5 : à annoter, ADR-123 le consigne. La DA évolutive §16.2 (3 pixels d'écran par pixel de créature en 1080p) est périmée par B72 : c'est 1.
- Antérieurs, relevés par les revues : un `onGameResize` à taille égale coupe la fin d'une réaction aux coups (`_snapScale`) ; `OpacityEffect` à la mort d'un ennemi n'estompe pas ses enfants ; `_rules/09-1` cite des lignes de `combat_entity.dart` déjà périmées.
- Pour la vague 4 : une languette née sur la carte ouverte ne relance pas son décalage (sans effet en `0.6.2`) ; le choix de carte du repos sert aussi au Rémouleur, qui prendrait le décor du repos.
- Mineurs laissés par la revue d'ensemble, chacun avec sa raison, dans le registre recopié du §2 : gardes de `boardScaleFor` sous 295 px de haut, littéraux 28, 128 et 192, la pose du décor écrite dans Flame et dans Flutter.

## 5. Les leçons

1. **Les exemples d'une décision ont contredit sa règle, et seul le calcul l'a montré.** B72 donnait ×4 en 1440p, que la règle de la même décision refusait : la spec l'a trouvé en posant les nombres. *Amendement proposé : une décision qui donne une règle et des exemples chiffrés est recalculée par l'agent qui la propose, avant qu'elle soit tranchée.*
2. **Des maquettes à la taille réelle de l'écran ont permis de trancher six questions en deux messages**, toutes selon la recommandation. *Amendement : rien — A3 et A5 d'ADR-120 tiennent.*
3. **Un plan écrit avant ses tâches porte des noms qui dérivent** (`_frameSprite`, `_background`) : la tâche à risque, écrite en entier, a dû se recaler sur les noms réels des Tasks 4 et 5. *Amendement proposé : l'envoi d'une tâche à code complet liste les symboles réels que les tâches précédentes ont laissés, relevés dans le code.*
4. **La preuve par mutation a trouvé un trou qu'aucun RED n'aurait vu** : l'arrondi du pas de la rangée n'était distingué par aucun test. *Amendement proposé : pour un algorithme imposé ligne à ligne, la revue demande une mutation par opération d'arrondi ou de borne.*
5. **Le coup d'œil dans le jeu lancé, proposé par la vague 1, a coûté un agent et confirmé l'essentiel** sans trouver de défaut, mais seulement sur le tier 1 et sans Windows. *Amendement proposé : le garder, et lui donner par le menu de debug un combat aux tiers mêlés.*

## 6. Les statistiques de la session

**Mesuré le 25/11/2026 à 14:16**, avant le commit de §3.8 — sessions : 1 · arrêts : 1 · durée : 3 h 48 de bout en bout (25/11 10:27 → 14:15), dont 2 h 24 de travail de l'orchestrateur · tours de spec : 2 · tours de plan : 2
Prix lus le 25/11 sur https://platform.claude.com/docs/en/about-claude/pricing · 1 € = 1,0963 $ (BCE, 24/11/2026) · suppléments : aucun (`server_tool_use`, `speed`, `inference_geo` vérifiés)

| | Spec | Plans | Implémentation | Fin de vague | Orchestrateur(s) | **Total** |
|:---|---:|---:|---:|---:|---:|---:|
| Temps actif | 1 h 23 | 59 min | 1 h 23 | 11 min | 2 h 24 | 6 h 21 |
| Agents — Opus / Sonnet | 4 / 0 | 3 / 0 | 5 / 14 | 0 / 4 | Opus 5.5 | 12 / 18 |
| Appels au modèle | 290 | 205 | 349 | 60 | 171 | 1 075 |
| Jetons traités, dont hors cache | 87,60 M, dont 2,26 M | 50,27 M, dont 1,61 M | 47,43 M, dont 2,06 M | 9,39 M, dont 0,39 M | 63,33 M, dont 0,52 M | 258,02 M, dont 6,84 M |
| Sortie (minimum) | 417 283 | 318 980 | 330 890 | 79 563 | 164 234 | 1 310 950 |
| Coût API — $ / € | 36,61 / 33,40 | 24,09 / 21,97 | 19,72 / 17,99 | 2,67 / 2,43 | 19,98 / 18,23 | **103,07 / 94,02** |

La vague commence à sa porte d'entrée. « Spec » compte les maquettes des questions et l'arrêt ; « Implémentation », le coup d'œil dans le jeu lancé ; « Fin de vague », la note de version, la mémoire, les tests manuels et la mesure elle-même, incomplète à sa propre lecture.
