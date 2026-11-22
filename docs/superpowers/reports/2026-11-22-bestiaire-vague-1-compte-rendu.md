# Vague 1 — `0.6.1` — l'interface des ennemis en combat — compte rendu

**Branche** : `feat/v0.6.1-interface-des-ennemis` · **Cadrage** : [bestiaire, P-05](../../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md) · **Spec** : [interface des ennemis](../specs/2026-11-21-p05-interface-des-ennemis-design.md) ([vérifications](../specs/2026-11-21-p05-interface-des-ennemis-design-verifications.md)) · **Plan** : [interface des ennemis](../plans/2026-11-21-p05-interface-des-ennemis.md) ([vérifications](../plans/2026-11-21-p05-interface-des-ennemis-verifications.md))

*Ouvert et fermé le 22/11, à la fin du plan. La méthode est celle du chantier précédent, lue dans son [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) §3 à §6 ; les trois écarts décidés par le propriétaire sont au cadrage §4.*

## 0. Pour le propriétaire

**À tester d'abord**, par risque (le détail est au [cahier des tests manuels](2026-11-22-bestiaire-vague-1-tests-manuels.md), T1 à T25) :

1. **La fiche d'un ennemi** (T1 à T6, T11, T12) : elle s'ouvre au toucher de la carte, de sa barre ou de sa languette ; tout appui ailleurs la ferme, un bouton du HUD compris ; à la fermeture la carte reste claire jusqu'au bout ; ouverte pendant un coup, elle revient à sa taille exacte.
2. **Le ciblage, qui ne doit pas avoir régressé** (T7 à T10) : carte focalisée, signature armée, glisser-déposer — en visant la carte, sa barre et sa languette.
3. **Les languettes** (T13 à T18) : à plusieurs ennemis, et aux deux bords de l'écran à cinq ennemis.
4. **La barre, le panneau, le tutoriel, S9** (T19, T21 à T25).

**Ce que vous ne pouvez pas tester en jeu : le voile d'armure d'un ennemi (T20).** Aucun ennemi ne gagne d'armure en `0.6.1`, et le menu de debug n'en donne qu'au héros. Vos décisions B12, B15 et B16 sont livrées et dormantes. Le voile a été vu fonctionner (plein, entamé, parti) par un point d'entrée jetable, hors du dépôt. Deux voies si vous voulez le voir : une ligne d'armure par ennemi au menu de debug, par une session de correction ; ou attendre la vague qui donnera de l'armure à un ennemi.

**Ce qu'un coup d'œil dans le jeu lancé a vu, et que je laisse à votre jugement** (build web de debug, 1280 × 800, un seul ennemi ; ni plusieurs ennemis, ni l'anglais, ni le tactile, ni un boss, ni la version Windows n'ont été vus) : le coin du cadre de la fiche passe de quelques pixels sous le bouton Son quand l'ennemi est au centre ; un ennemi qu'on vient de frapper garde la bordure ambre de la sélection, la même que celle de la fiche ouverte (c'était déjà le cas) ; à un seul ennemi, la carte agrandie recouvre le haut de la carte du héros, et le dégât d'un coup porté fiche ouverte s'affiche sur le héros ; le chiffre d'armure cyan se lit mal sur le rouge ; la Puissance et la Foudre ont le même émoji ⚡ ; au bord de l'écran, une languette déroulée vers l'intérieur peut recouvrir l'autre languette de la même carte.

**Les arbitrages que le joueur verra** : vos réponses B31 à B41 ; un seul changement que vous n'avez pas tranché (V1) — carte focalisée visant les ennemis, les ennemis non sélectionnés gardent une bordure cyan sous leur halo, au lieu de retomber au blanc ; l'ennemi déjà frappé garde son ambre, comme avant. La note de version porte une seconde correction, tirée du commit S9 : un héros vaincu pendant le tour des ennemis n'est plus ranimé par un soin de début de tour.

**Faits sans vous** : rien en autonomie `continu` — les deux arrêts de la spec ont attendu votre réponse. Les arbitrages techniques sont au §2.

**Risques connus**, laissés par la passe de corrections unique : au bord de l'écran, une languette peut se retourner brièvement si la souris bouge pendant la secousse d'un coup ; fermer une fiche puis en ouvrir une autre en moins de 0,15 s laisse la carte fermée claire un instant au-dessus du voile ; le cadre de la fiche n'a pas de hauteur maximale (un petit écran et beaucoup de statuts le couperaient en bas). **Sur ce poste, Smart App Control a bloqué l'exécutable Windows fraîchement construit** : si votre test en dépend, vérifiez-le d'abord.

**Rejouer l'essentiel** : `flutter test test/unit/heros_draft_game_targeting_test.dart test/unit/status_readout_test.dart test/unit/enemy_sheet_view_test.dart` · `dart analyze` · `bash .github/scripts/verify_version.sh 0.6.1`.

## 1. La branche et ses chiffres

| Plan | Commits de code | Tests | `dart analyze` | Superpowers | Claude Code |
|:---|:---|:---|:---|:---|:---|
| Interface des ennemis | 9 (`a356cabc..23c9823a`, après le plan `86a0f9db`) ; base de la branche : `8d544a3d`, le correctif S9 | 1866 → **1935** | `No issues found!` | 7.0.0, `bb92a77` | 2.1.319 |

## 2. Les arbitrages

Une ligne chacun ; les options écartées sont dans les fichiers de vérifications de la spec et du plan.

| # | Question | Classe | Choix | Filtre |
|:---|:---|:---:|:---|:---:|
| B31 à B41 | Onze questions visibles du joueur nées de la spec : la pastille de Puissance, la Foudre chargée, l'ennemi gelé, la fiche (sections vides, tour des ennemis, estompage, hauteur de la carte), le tutoriel, le panneau du héros, la languette du bord, deux icônes | P | Vos réponses du 21/11, sur maquettes ; B32 amende B14 | — |
| A1, A13 | La couche de chaque élément | T | Règles d'affichage en fonctions pures ; barre, languettes, agrandissement, estompage en Flame ; panneau et cadre de la fiche en Flutter ; la fiche ouverte appartient au jeu, l'écran la reflète en différé ; aucun état Riverpod neuf | 5, 6 |
| A2 à A4 | Le plus haut montant d'armure ; le badge ; la géométrie de la barre | T | Sur la carte de l'ennemi, par une règle pure ; badge et jauge circulaire supprimés avec neuf textes sans lecteur ; en unités de la carte | 5, 6, 7, 8 |
| A5 à A7 | Les pastilles, les colonnes, l'infobulle | T | Les icônes d'aujourd'hui (B31) ; 40, le reste, 96 ; une infobulle par rangée, contenu inchangé | 1, 5, 6, 8 |
| A8, A9 | Les languettes et le survol | T | Un composant pour ennemis et héros, lu sur une vue pure ; un arbitre géométrique, qu'un doigt ne déclenche jamais | 5, 6, 7, 8 |
| A10 à A12 | Le toucher, le premier plan, la fermeture | T | Carte focalisée, puis signature, puis fiche ; ×1,25, voile à 55 % ; la fiche reste ouverte si et seulement si l'appui est celui que le jeu vient de retenir | 1, 5, 6, 8 |
| — | Le « +1 » de B6 | T | Hors du lot : aucune intention n'a deux effets ; il se fixe avec B1 | 7 |
| — | Six noms de statut et le compteur de passif, écrits en français seul | T | Traduits : la languette du héros les montre | 4 |
| V1 | L'ordre de la bordure d'un ennemi | T | Fiche, sélection, surbrillance, blanc — contesté avec preuve par le rédacteur du plan, confirmé ligne à ligne | 6, 8 |
| V2, V3 | Le son d'une carte prise fiche ouverte ; le niveau du panneau | T | Un seul son, comme avant ; le texte « Niv. » existant | 5, 7 |
| V4, D1 à D16 | Les décisions du plan : tests de la fiche, garde d'un ennemi mort, écarts relatifs de place et d'échelle, réémission seulement si le cadre a bougé | T | Plan, « Décisions du plan » ; quatre écarts à la spec confirmés et reportés | 1, 5, 8 |

**Les arrêts.** Deux, à la spec : au troisième tour (un constat moyen technique, autonomie `strict`, et onze questions P), levé par vos réponses ; au quatrième tour, qui rendait encore « à corriger » — vous avez choisi de passer au plan, où la règle de fermeture a été rejouée sur du code.

**Décisions de SDD** (registre recopié avant sa suppression ; sept tâches, une passe de correction en tâche 2, une décision avant revue en tâche 4 ; revue d'ensemble sur `86a0f9db..726ebaa5`, « prête avec corrections », 0 critique, 1 important, une passe, relue) :

| # | Décision | Classe | Coût si fausse |
|:---|:---|:---:|:---|
| S0 | Balayage préalable : huit paires de tâches et sept tâches, sans contradiction ; cinq lignes de la tâche 5 jamais rejouées, à surveiller | T | — |
| S1 | Pas de worktree ; `finishing-a-development-branch` non invoqué ; la tâche 7 jouée par l'orchestrateur | T | — |
| S2 | Les tâches 2 et 6, d'écran, sans test automatique (ADR-113) | T | Un défaut d'écran n'est vu qu'à votre test |
| S3 | La revue d'ensemble sur Opus, non sur le modèle de la session | T | Un défaut subtil de plus peut passer |
| S4 | Le contrôle « plus de `_visuals` » du plan rend le fichier des pastilles, qui porte le sien : l'intention est tenue | T | — |
| S5 | Tâche 4 : une languette déroulée vers l'intérieur garde sa bande de repos dans la zone de sa carte, pour le survol **et** pour l'appui (spec amendée) | T | Une bande de 29 unités au bord de l'écran où un appui vise l'ennemi sans rien de dessiné dessous |
| S6 | La passe unique corrige le clignotement de la carte à la fermeture et neuf mineurs ; le cadre sans hauteur maximale reste pour votre test | T | Une fiche coupée en bas sur un petit écran |
| S7 | Le menu de debug n'est pas modifié : le voile d'armure reste dormant | T | Vous ne pouvez pas tester B12, B15, B16 de vos mains |
| S8 | Trois résidus de la passe de corrections laissés (§0, risques connus) ; un quatrième inatteignable | T | Un éclat d'une demi-image |

## 3. Les tests manuels

[2026-11-22-bestiaire-vague-1-tests-manuels.md](2026-11-22-bestiaire-vague-1-tests-manuels.md) — 25 tests. Résultat : à remplir par le propriétaire.

## 4. Trouvé périmé, et pour la file

- `lib/game/components/entities/health_bar.dart` : sans lecteur, déjà avant la vague.
- `CLAUDE.md`, table « Documentation Map » : la ligne « The programme in progress, wave by wave » pointe encore le fichier d'orchestration du chantier clos ; à faire pointer vers le cadrage du bestiaire — laissé au propriétaire, c'est son fichier d'instructions.
- `docs/ROADMAP.md` : la ligne S9 se dit encore ouverte, P-55 cite `status_indicator.dart`, supprimé, et le schéma, le Gantt, P-14 et P-15 s'appuient encore sur `onHitEffect`, que B1 remplace.
- Les seuils 6, 12 et 20 des paliers d'attaque sont écrits trois fois, dont une sous `lib/models/`, gelé pour ce lot : à réunir avec B1.
- Le menu de debug ne pose ni armure ni statut sur un ennemi, seulement des charges.
- Les sprites du Slime, du Gobelin et du héros portent une fine bande d'une autre image sur leur bord droit, dans les fichiers PNG eux-mêmes.
- L'infobulle d'une carte focalisée qui cible le héros recouvre le centre de sa carte : y toucher le héros ne joue pas la carte (antérieur).
- `onGameResize`, rappelé à chaque reconstruction de l'écran, coupe aussi les secousses et l'effet de mort d'un ennemi (antérieur ; la vague n'en protège que la fiche).
- B39 ne dit rien d'une languette intérieure plus large que sa carte, qui recouvre l'autre languette.

## 5. Les leçons

1. **La spec d'un geste d'interface n'a pas convergé sur le papier ; le plan, si.** Quatre tours de spec, chacun avec un constat moyen né de la correction du précédent, tous sur l'ouverture et la fermeture de la fiche ; trois tours de plan, clos « prêt », parce que le code y était écrit et rejoué. *Amendement proposé : pour une tâche à risque d'interface, la spec fixe l'intention et les cas, deux tours au plus ; le mécanisme se vérifie au plan.*
2. **La mesure sur des cartes montées a trouvé ce que la lecture ne voyait pas** : une échelle à 1,04 au lieu de 1,25, un écran reconstruit 29 fois en 30 images, une carte décalée de 21 px, un voile resté à 0,49. *Amendement proposé : le vérificateur de plan d'une tâche à risque Flame mesure sur un composant monté, par un test jetable.*
3. **Personne n'avait vu l'écran avant la revue d'ensemble.** Un coup d'œil dans le jeu lancé a coûté un agent et rendu six observations — et le rédacteur des tests manuels a découvert, à la fin, que le voile d'armure n'était pas atteignable. *Amendement proposé : la fiche d'une vague d'interface dit, avant la vague, comment chaque élément livré s'atteint en jeu ou par le debug ; et la vague finit par un coup d'œil dans le jeu lancé avant sa passe de corrections.*
4. **Onze questions visibles du joueur sont nées en écrivant la spec**, après un cadrage de trente questions sur maquettes. Posées en une fois, avec leurs maquettes, elles ont eu leur réponse en un message (A3 et A5 d'ADR-120 tiennent). *Amendement : rien.*
5. **L'orchestrateur a annoncé comme « geste ordinaire » un défaut que la revue d'ensemble a ramené à une fenêtre d'une image.** *Amendement proposé : la portée d'un défaut relevé par une revue de tâche ne se rapporte au propriétaire qu'après la revue d'ensemble.*

## 6. Les statistiques de la session

**Mesuré le 22/11/2026 à 02:16**, avant le commit de §3.8 — sessions : 1 · arrêts : 2 · durée : 5 h 57 de bout en bout (21/11 20:19 → 22/11 02:15), dont 3 h 23 de travail de l'orchestrateur · tours de spec : 4 · tours de plan : 3
Prix lus le 22/11 sur https://platform.claude.com/docs/en/about-claude/pricing · 1 € = 1,0990 $ (BCE, 20/11/2026) · suppléments : aucun (`server_tool_use`, `speed`, `inference_geo` vérifiés)

| | Spec | Plans | Implémentation | Fin de vague | Orchestrateur(s) | **Total** |
|:---|---:|---:|---:|---:|---:|---:|
| Temps actif | 1 h 34 | 1 h 35 | 1 h 37 | 54 min | 3 h 23 | 9 h 03 |
| Agents — Opus / Sonnet | 5 / 0 | 4 / 0 | 7 / 9 | 3 / 2 | Fable 5.2 | 19 / 11 |
| Appels au modèle | 358 | 319 | 415 | 363 | 152 | 1 607 |
| Jetons traités, dont hors cache | 94,80 M, dont 3,92 M | 83,33 M, dont 2,53 M | 62,33 M, dont 2,38 M | 70,40 M, dont 1,10 M | 75,12 M, dont 0,72 M | 385,97 M, dont 10,64 M |
| Sortie (minimum) | 458 564 | 488 847 | 475 485 | 202 077 | 218 088 | 1 843 061 |
| Coût API — $ / € | 44,63 / 40,61 | 36,12 / 32,87 | 27,99 / 25,47 | 21,20 / 19,29 | 31,65 / 28,79 | **161,59 / 147,04** |

La vague commence à sa porte d'entrée : les deux séances de cadrage qui la précèdent dans la même session ne sont pas comptées. « Fin de vague » compte le coup d'œil dans le jeu lancé, les tests manuels, les deux skills et la mesure elle-même, incomplète à sa propre lecture.
