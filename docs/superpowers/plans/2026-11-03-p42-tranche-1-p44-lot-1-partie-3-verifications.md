# Vérifications — plan de la partie 3, tranche 1 et P-44 lot 1

**Plan** : [`2026-11-03-p42-tranche-1-p44-lot-1-partie-3.md`](2026-11-03-p42-tranche-1-p44-lot-1-partie-3.md) · **Spec** : [`2026-10-25-p42-tranche-1-p44-lot-1-design.md`](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §10 partie 3 · **Vague** : 5, `0.5.7` · **Base de tests** : 1524 (04/11, `5fbbe63f`) · **Tâche à risque** : la Task 5, la sauvegarde des évolutions (`SignatureInstance.evolutions`) · **Autonomie** : `continu`.
Tenu par l'orchestrateur (ADR-108 D4) : les questions nées à l'écriture, puis le journal des tours.

## Les questions nées à l'écriture

### Classe T — confirmées par l'orchestrateur

| # | Question | Choix du rédacteur | Filtre |
|:---:|:---|:---|:---:|
| PN1 | `flatBonus` dans `CardDelta.typeNames`, donc lisible par une rune et offert par l'éditeur de rune | Oui, un vocabulaire commun ; aucune rune ne l'emploie | 4 |
| PN2 | `flatBonus` vise chaque effet du type, ou le premier | Chaque effet, comme `percentBonus` ; aucune signature n'a deux effets du même type | 5 |
| PN3 | `deltas` exigée sur une évolution | Facultative : *Célérité* et *Rayonnement* n'ont qu'une `cooldown` ou une `target` | 8 |
| PN4 | Quand `SignatureData.fromJson` lit `evolutions` | Après les effets, que les règles de gabarit lisent | 5 |
| PN5 | Un id disparu répété dans la sauvegarde | Signalé une fois | 6 |
| PN6 | `signatureEvolutions` quand rien n'a évolué | Toujours écrit, en `{}` | 8 |
| PN7 | L'icône du carrousel | Un `Widget? icon` qui remplace l'emoji (`draft_choice_card.dart:131`), dessiné par un `EvolutionIcon` partagé entre rouleau et tuile | 5 |
| PN8 | L'habillage du rouleau | Recopié dans l'écran d'évolution ; `DraftScreen` ne change pas | 7 |
| PN9 | Son, musique, décor du rouleau | Ceux du carrousel, que la réponse du propriétaire désigne : variante `common` de `reelLand` (une évolution n'a pas de rareté), `MusicScene.map`, décor au niveau 1 | 8 |
| PN10 | A38 : `Flow` ou `RenderBox` propre | `Flow`, `Clip.none` : il mesure avant de peindre et porte le toucher à travers la transformation — **remplacé par PN18** à la reprise | 8 |
| PN11 | La règle d'accessibilité de la tuile | `EffectResolver.canAfford(signature.asCard, heroStats)` ; `SignatureBar` reçoit `heroStats` au lieu de `currentMana` — la règle de mana propre de `signature_bar.dart:114` disparaît (compte rendu §4) | 5 |
| PN14 | Où vivent le tirage et le choix | `SignatureEvolutionRules`, pur, sous `lib/game/systems/` ; `chooseSignatureEvolution` sur `RunController`, comme `raiseRuneCap` | 5 |
| PN15 | `evolutions` dans les `requiredKeys` du descripteur de signature | Oui | 5 |
| PN16 | Un choix refusé depuis l'écran (l'état a changé) | L'écran se ferme ; le rideau rouvre ce qui reste | 8 |
| PN17 | Quand change le gabarit d'éditeur de la signature | Dès la Task 2, avec une évolution verbale (`ardor`) ; le reste du descripteur en Task 10 (Task 8 avant la reprise) | 5 |

### Classe P — répondues par le propriétaire le 03/11

Le plan s'est écrit et vérifié sous l'option recommandée, marquée **(provisoire)** aux Tasks 3 et 7 (§5 : dans le doute entre T et P, P). Le propriétaire a répondu devant des [maquettes](../../presentations/2026-11-03_vague_5_pn12_pn13_maquettes.pptx) : **PN12 (d)**, une option à lui — des icônes à la place du texte sur la tuile de combat, la description complète déroulée en liste par appui long, avec les quatre précisions recommandées (la valeur sur l'icône, relâcher replie, la durée dans la liste seulement, le texte gardé hors combat) ; **PN13 (c)**, l'ambre. Réponses écrites en §1.2 de la spec, qui s'amende et se revérifie ; puis le plan se reprend.

| # | Question | Options | Recommandation |
|:---:|:---|:---|:---|
| PN12 | Comment la phrase d'une évolution verbale se joint à la description (A25 : « le gabarit rempli suivi des phrases verbales ») | (a) à la suite, après un espace : « Inflige 10 dégâts et donne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. » ; (b) chaque phrase à la ligne ; (c) jointes par « · » | (a), la lecture d'une description de carte |
| PN13 | La couleur du badge « Niv. n » quand la tuile est disponible ou armée (la spec le grise « comme le nom » en recharge et sans le mana) | (a) blanc gras, comme le nom ; (b) la couleur de la classe ; (c) `amberAccent`, comme la ligne coût / recharge | (a), le pendant du gris « comme le nom » |

### Classe T — nées à la reprise du plan sur la spec amendée (`571b881d`), confirmées par l'orchestrateur

| # | Question | Choix du rédacteur | Filtre |
|:---:|:---|:---|:---:|
| PN18 | Poser la barre (A38) quand le calque d'A42 doit lire la transformation de la tuile pendant la mise en page (`RenderFlow` ne l'établit qu'à la peinture) | Un `RenderBox` propre à la barre, la transformation calculée dans `performLayout` ; remplace PN10 | 5 |
| PN19 | Le mécanisme du calque, qu'A42 laisse au plan | `OverlayPortal.overlayChildLayoutBuilder`, puis `CustomSingleChildLayout`, puis `Transform.scale` ; vers le haut si la liste sortirait par le bas ; `CompositedTransformFollower` écarté, il ne voit pas la place sous la tuile | 5, 8 |
| PN20 | Où placer le document des icônes d'effet | Une tâche neuve (Task 6), avant l'écran ; le panneau des statuts en est le premier lecteur | 5, 7 |
| PN21 | La tuile en une tâche ou deux | Deux : la bande (Task 8), puis la liste et le calque (Task 9) | 8 |
| PN22 | Où vivent `EffectLine` et le vocabulaire des sortes | `EffectLine` dans `signature_instance.dart`, son producteur ; le vocabulaire dans `EffectKind` (`lib/models/data/effect_kind.dart`), créé en Task 3, complété en Task 6 | 5 |
| PN23 | `effect_icons.json` absent ou fautif | Le démarrage échoue, comme pour `xp_curve.json` ; un test de chargeur | 5 |
| PN24 | Où entrent les clés ARB | `effectValuePercent` avec la bande (Task 8), les 13 `effectLine…` avec la liste (Task 9) | 8 |
| PN25 | Une sorte absente de la table | `effectVisualsOf` retombe sur `help_outline` (bande, liste) ; `effectVisualsOrNull` rend `null` et le panneau garde son icône d'aujourd'hui | 5 |
| PN26 | Les tests existants passent-ils `effectIcons` | Non : le panneau, `CombatSidePanels` et `SignatureBar` reçoivent une table vide par défaut | 8 |

**Laissés hors de la partie 3** (rédacteur, confirmés, filtre 7) : `ProportionalStatus` importé par `enemy_instance.dart:3` et le nom de statut français de `card_rule_texts.dart:65-69` — aucune tâche n'ouvre ces fichiers ; à la file (compte rendu §4). `scaleTerm` et la cible morte : déjà traité (`effect_resolver.dart:235-238`, `scale_with_test.dart:305`).

## Le journal des tours

| Tour | Mode | Vérificateur | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté, tranché |
|:---:|:---|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet, Task 5 rejouée dans un clone (8 rouges sur 9 au Step 2, puis 1925 verts ; l'ordre de première prise, les niveaux, les exclusions et la clé absente tiennent ; A38 exécutée : les quatre placements recoupent le calcul à la main) | neuf, seul | 0 | 2 | 3 | 0 | Les cinq, par le rédacteur repris ; aucun contesté. Les deux moyens : aucun test ne gardait les nœuds fermés pendant une attente (`map_screen.dart:380`, `:403`) ; le test du gris de la tuile ne contrôlait ni le chiffre d'une mineure ni l'anneau d'une majeure. Mineurs : deux imports en double dans le code de la Task 5, le grep des documents à réécrire de la Task 2, deux attendus de PN12 non marqués provisoires. Total final 2002 → **2003** | — |
| 2 | différentiel | neuf, seul | 0 | 1 | 2 | 1 | Les quatre, par le rédacteur repris ; aucun contesté. Le moyen : le test des nœuds fermés ne pouvait pas rougir — le toucher tombait sur le rideau opaque, et `MapNodeWidget` n'appelle `onTap` que si le nœud est ouvert ; réécrit en deux assertions directes, `isAvailable` faux et `onTap()` appelé sans effet, une par garde (`map_screen.dart:380`, `:403`). Mineurs : le `Text '2'` cherché sous l'icône de *Zèle* ; les imports de la Task 3 nommés. Rédaction : les lignes d'`entity_descriptor_test`. Total inchangé, 2003 | — |
| 3 | différentiel | neuf, seul | 0 | 0 | 2 | 0 | **Prêt.** Les quatre corrections du tour 2 tiennent, prouvées sur le code : (a) et (b) rougiraient chacune sous l'ancienne garde (`map_screen.dart:380`, `:403`), `onTap` passé sans condition (`:263-269`). Deux mineurs, que le vérificateur classait D, reclassés T par l'orchestrateur — aucune décision acquise n'y est en jeu — et corrigés au passage : le finder du `MapNodeWidget` (`find.byWidgetPredicate`, aucune `Key` par nœud) ; l'import de `card_delta.dart`, seulement si le type est nommé | — |
| — | reprise du plan sur la spec amendée (PN12 (d), PN13 (c) ; `571b881d`) | rédacteur repris | — | — | — | — | Onze tâches au lieu de neuf (Task 6, les icônes d'effet ; Task 9, la liste de l'appui long), total 2003 → **2039** ; PN12 et PN13 ne sont plus provisoires ; P-5 et P-6 marqués provisoires (6 et 23 marques) ; la Task 5 inchangée hors son total (1972 → 1975) ; PN18 à PN26, de classe T | — |
| R · 1 | complet sur la reprise ; la Task 5 contrôlée par diff (bloc identique, seul le total change), non rejouée | neuf, seul | 0 | 5 | 7 | 2 | Les quatorze, par le rédacteur repris (PN17 par l'orchestrateur) ; aucun contesté. Les cinq moyens : la transformation de la barre sur un membre déprécié de `vector_math` (`..scale`, remplacé par `Matrix4.diagonal3Values`) ; la tuile déployée qui reprenait la clé de la tuile (`signature-overlay-<id>`) ; le test vers le haut qui ne créait pas son cas (vue `1280 × 260`, précondition) ; le test du calque prouvé par l'arbre de rendu, non par l'`Overlay` ; les totaux et les lignes de la Task 6 que P-6 et P-5 toucheraient, marqués. Mineurs : un test renommé, l'`IgnorePointer`, l'ouverture vers le bas, la colonne des puces, le registre du tutoriel reconstruit, deux icônes du panneau dans ce que voit le joueur, un grep robuste | — |
| R · 2 | différentiel, les quatorze corrections du tour R · 1 ; la Task 5 contrôlée par diff | neuf, seul | 0 | 0 | 6 | 3 | **Prêt.** Les quatorze corrections tiennent, prouvées sur le SDK (`Matrix4`, l'arbre de rendu du calque, `hitTestOnBinding`) et recalculées (le cas « vers le haut » à `1280 × 260`, les comptes −1 et −5 de P-6). Six mineurs et trois rédactions corrigés au passage (le rédacteur pour le plan, l'orchestrateur pour ce fichier) : la clé sur le `Container` du cadre, la *Bouclier Sacré* du test 5, sept marques P-6 et deux P-5 de plus, les signatures des tests 4 et 7, les clés de la bande sous `_tile(id)`, les références du panneau, une majuscule, la ligne R · 1 | — |
| — | réponses du propriétaire P-5 (a), P-6 (a), 04/11 | — | — | — | — | — | Les options sous lesquelles le plan s'est écrit ; les marques retirées, sans nouveau tour ; total final inchangé, 2039 | — |
| — | reprise sous D77, 04/11 (base **1524**, mesurée après le tri des tests d'écran, `5fbbe63f`) | rédacteur repris | — | — | — | — | 41 tests d'écran retirés (Task 2 : 1 ; Task 6 : 4 ; Task 7 : 11 ; Task 8 : 15 ; Task 9 : 10), avec les réécritures de `signature_bar_test` qu'ils portaient ; aucun fichier supprimé par le tri n'est recréé ; un réécrit en unitaire (Task 3, « canAfford lit le cout evolue ») ; `signatureBandPlacement` gardé, fonction pure ; les clés de test des widgets retirées ; une étape « Points de tests manuels » aux Tasks 2, 6, 7, 8 et 9 (M7 à M33 de spec §9.1) ; Global Constraints et Review Focus disent D77 ; Task 11 : tests nommés, grep D77, total. Totaux 1530, 1548, 1563, 1574, 1583, 1596, 1596, 1597, 1602, **1607** (+83) ; la Task 5 inchangée hors son total (1975 → 1583) | — |
| R · D77 · 1 | différentiel, la reprise sous D77 (`9c1a02a3`) | neuf, seul | 0 | 1 | 3 | 2 | Le moyen, de classe P, posé au propriétaire : plusieurs points M (M18 à M24, M27) demandent des états d'évolution qu'on n'atteint pas en jouant ; non appliqué ici. Les trois mineurs et les deux rédactions, corrigés par le rédacteur repris : la garde des nœuds, hors de portée du joueur sous le rideau opaque, vérifiée par un grep (`hasPendingChoice` trois fois dans `map_screen.dart`, Task 7 Step 2 et Task 11) et M9 reformulé ; M27 sur la fenêtre d'≈ 400 px de M31, sans « sans sortir de l'écran » ; M26 « Android seulement », M28 l'appui tenu pendant le tour ennemi ; l'en-tête de ce fichier (base 1524) et celui de spec §9.1 (l'onglet Run du menu de debug). Total inchangé, 1607 | — |
| — | P-7 (a), réponse du propriétaire, 04/11 | rédacteur repris | — | — | — | — | L'entrée de debug des évolutions dans la Task 7 (après les règles de la Task 4, avant les Tasks 8 et 9 qui s'en servent) : deux actions de `DebugActions` par `admissible` et `withChoice`, l'attente seule non exigée ; la section de l'onglet Héros ; cinq tests unitaires dans `debug_actions_test`, en TDD ; M34 neuf ; M18 à M25 et M27 préparés par elle, sur des ordres de prise que les règles admettent. Totaux 1601, 1602, 1607, **1612** (+88) ; la Task 5 inchangée | — |
