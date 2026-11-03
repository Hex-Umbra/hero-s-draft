# Vérifications — plan de la partie 3, tranche 1 et P-44 lot 1

**Plan** : [`2026-11-03-p42-tranche-1-p44-lot-1-partie-3.md`](2026-11-03-p42-tranche-1-p44-lot-1-partie-3.md) · **Spec** : [`2026-10-25-p42-tranche-1-p44-lot-1-design.md`](../specs/2026-10-25-p42-tranche-1-p44-lot-1-design.md), §10 partie 3 · **Vague** : 5, `0.5.7` · **Base de tests** : 1916 (03/11, `d339ce6`) · **Tâche à risque** : la Task 5, la sauvegarde des évolutions (`SignatureInstance.evolutions`) · **Autonomie** : `continu`.
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
| PN10 | A38 : `Flow` ou `RenderBox` propre | `Flow`, `Clip.none` : il mesure avant de peindre et porte le toucher à travers la transformation | 8 |
| PN11 | La règle d'accessibilité de la tuile | `EffectResolver.canAfford(signature.asCard, heroStats)` ; `SignatureBar` reçoit `heroStats` au lieu de `currentMana` — la règle de mana propre de `signature_bar.dart:114` disparaît (compte rendu §4) | 5 |
| PN14 | Où vivent le tirage et le choix | `SignatureEvolutionRules`, pur, sous `lib/game/systems/` ; `chooseSignatureEvolution` sur `RunController`, comme `raiseRuneCap` | 5 |
| PN15 | `evolutions` dans les `requiredKeys` du descripteur de signature | Oui | 5 |
| PN16 | Un choix refusé depuis l'écran (l'état a changé) | L'écran se ferme ; le rideau rouvre ce qui reste | 8 |
| PN17 | Quand change le gabarit d'éditeur de la signature | Dès la Task 2, avec une évolution verbale (`ardor`) ; le reste du descripteur en Task 8 | 5 |

### Classe P — répondues par le propriétaire le 03/11

Le plan s'est écrit et vérifié sous l'option recommandée, marquée **(provisoire)** aux Tasks 3 et 7 (§5 : dans le doute entre T et P, P). Le propriétaire a répondu devant des [maquettes](../../presentations/2026-11-03_vague_5_pn12_pn13_maquettes.pptx) : **PN12 (d)**, une option à lui — des icônes à la place du texte sur la tuile de combat, la description complète déroulée en liste par appui long, avec les quatre précisions recommandées (la valeur sur l'icône, relâcher replie, la durée dans la liste seulement, le texte gardé hors combat) ; **PN13 (c)**, l'ambre. Réponses écrites en §1.2 de la spec, qui s'amende et se revérifie ; puis le plan se reprend.

| # | Question | Options | Recommandation |
|:---:|:---|:---|:---|
| PN12 | Comment la phrase d'une évolution verbale se joint à la description (A25 : « le gabarit rempli suivi des phrases verbales ») | (a) à la suite, après un espace : « Inflige 10 dégâts et donne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. » ; (b) chaque phrase à la ligne ; (c) jointes par « · » | (a), la lecture d'une description de carte |
| PN13 | La couleur du badge « Niv. n » quand la tuile est disponible ou armée (la spec le grise « comme le nom » en recharge et sans le mana) | (a) blanc gras, comme le nom ; (b) la couleur de la classe ; (c) `amberAccent`, comme la ligne coût / recharge | (a), le pendant du gris « comme le nom » |

**Laissés hors de la partie 3** (rédacteur, confirmés, filtre 7) : `ProportionalStatus` importé par `enemy_instance.dart:3` et le nom de statut français de `card_rule_texts.dart:65-69` — aucune tâche n'ouvre ces fichiers ; à la file (compte rendu §4). `scaleTerm` et la cible morte : déjà traité (`effect_resolver.dart:235-238`, `scale_with_test.dart:305`).

## Le journal des tours

| Tour | Mode | Vérificateur | Bloquants | Moyens | Mineurs | Rédaction | Corrigé | Contesté, tranché |
|:---:|:---|:---|---:|---:|---:|---:|:---|:---|
| 1 | complet, Task 5 rejouée dans un clone (8 rouges sur 9 au Step 2, puis 1925 verts ; l'ordre de première prise, les niveaux, les exclusions et la clé absente tiennent ; A38 exécutée : les quatre placements recoupent le calcul à la main) | neuf, seul | 0 | 2 | 3 | 0 | Les cinq, par le rédacteur repris ; aucun contesté. Les deux moyens : aucun test ne gardait les nœuds fermés pendant une attente (`map_screen.dart:380`, `:403`) ; le test du gris de la tuile ne contrôlait ni le chiffre d'une mineure ni l'anneau d'une majeure. Mineurs : deux imports en double dans le code de la Task 5, le grep des documents à réécrire de la Task 2, deux attendus de PN12 non marqués provisoires. Total final 2002 → **2003** | — |
| 2 | différentiel | neuf, seul | 0 | 1 | 2 | 1 | Les quatre, par le rédacteur repris ; aucun contesté. Le moyen : le test des nœuds fermés ne pouvait pas rougir — le toucher tombait sur le rideau opaque, et `MapNodeWidget` n'appelle `onTap` que si le nœud est ouvert ; réécrit en deux assertions directes, `isAvailable` faux et `onTap()` appelé sans effet, une par garde (`map_screen.dart:380`, `:403`). Mineurs : le `Text '2'` cherché sous l'icône de *Zèle* ; les imports de la Task 3 nommés. Rédaction : les lignes d'`entity_descriptor_test`. Total inchangé, 2003 | — |
| 3 | différentiel | neuf, seul | 0 | 0 | 2 | 0 | **Prêt.** Les quatre corrections du tour 2 tiennent, prouvées sur le code : (a) et (b) rougiraient chacune sous l'ancienne garde (`map_screen.dart:380`, `:403`), `onTap` passé sans condition (`:263-269`). Deux mineurs, que le vérificateur classait D, reclassés T par l'orchestrateur — aucune décision acquise n'y est en jeu — et corrigés au passage : le finder du `MapNodeWidget` (`find.byWidgetPredicate`, aucune `Key` par nœud) ; l'import de `card_delta.dart`, seulement si le type est nommé | — |
