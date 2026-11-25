# Vague 2 — `0.6.2` — les cadres de tier et les décors — compte rendu

**Branche** : `feat/v0.6.2-cadres-et-decors` · **Cadrage** : [bestiaire, P-05](../../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md) (B66 à B89) · **Spec** : [cadres et décors](../specs/2026-11-25-p05-cadres-et-decors-design.md) ([vérifications](../specs/2026-11-25-p05-cadres-et-decors-design-verifications.md)) · **Plan** : [cadres et décors](../plans/2026-11-25-p05-cadres-et-decors.md) ([vérifications](../plans/2026-11-25-p05-cadres-et-decors-verifications.md))

*Ouvert le 25/11, à la fin du plan. Méthode : le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) §3 à §6, lu pour ce chantier par son [README](../../chantier_bestiaire/README.md).*

## 0. Pour le propriétaire

*À compléter à la fin de la vague (§3.8).*

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

*À compléter à la fin de la vague (§3.8).*

## 4. Trouvé périmé, et pour la file

*À compléter à la fin de la vague (§3.8).*

## 5. Les leçons

*À compléter à la fin de la vague (§3.8).*

## 6. Les statistiques de la session

*À mesurer juste avant le commit de §3.8.*
