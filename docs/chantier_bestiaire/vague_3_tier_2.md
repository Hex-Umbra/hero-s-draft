# Vague 3 — `0.6.3` — le tier 2

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11, avant la vague 2 : **la spec de la vague 2 aura fixé le format des intentions** sur lequel celle-ci s'écrit — relis-la avant tout, et revérifie chaque chemin.

**Poids** : lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **Les mécanismes du tier 2** ([catalogue](catalogue_mecanismes.md), #4 et #11 à #14) : plusieurs coups, venu de la vague 2 (B54), l'invocation, l'aura, viser un allié, le perce-armure.
- **La famille du Rat entière** : le Rat alpha (tier 2, B20), qui entre seul et invoque ses rats un par un, deux au plus ; le lien de meute (B22, B29), écrit comme une aura.
- **Les ennemis de tier 2**, proposés le 22/11 — **la liste est à confirmer** (prérequis 1) :

| Ennemi | Mécanisme | Source |
|:---|:---|:---|
| Rat alpha | invocation, aura | cadrage §1.3 |
| Squelette (existant) | prend la Faiblesse, signature de sa famille (B2, B48) | cadrage |
| Zombie enragé | pose du Poison à chaque coup | 27/07 |
| Loup des ombres | critique haut, plusieurs coups | 27/07 |
| Voleur des cryptes | un coup qui détruit l'armure au lieu de toucher les PV | 27/07 |
| Golem d'argile | Armure, puis coup lourd | 27/07 |
| Harpie | pose du Vulnérable | 27/07 |

## Prérequis — avant l'ouverture

1. **La liste des ennemis**, confirmée ou réduite par le propriétaire.
2. **Les sprites, tous validés** (B51). Existent : le Rat alpha (`art_src/creatures/rat/tier_1/rat_geant.aseprite`, B43) et le Squelette de tier 2, en refonte en 128 × 192 dans `art_src/creatures/squelette/tier_2/` — le Squelette est redessiné ici (B52). **À trancher** : le Rat alpha a été produit comme un tier 1 (son dossier, son brief) alors qu'il est de tier 2 — la direction artistique veut plus de détail au tier 2 ([DA évolutive](../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.1) : il se garde tel quel, ou se retouche. Les autres sprites sont à produire.
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - les questions de la meute (cadrage §2) : l'invocation s'annonce-t-elle comme une intention, un tour avant ; un rat invoqué n'agit-il qu'au tour suivant ; la meute compte-t-elle pour 2 dès l'entrée de l'alpha ; le prix de l'alpha dans le budget, qui doit couvrir des rats entrant sans rien coûter ;
   - les pourcentages du lien de meute (+20 % par rat, +25 % pour le rat : des exemples, B22, B29) ;
   - les valeurs des ennemis, et la Faiblesse du Squelette ;
   - le perce-armure : ignorer l'armure, la détruire, ou les deux ;
   - ce que le joueur lit d'une invocation et d'une aura (pastille, languette, fiche) ;
   - le « +1 » de B6, si une intention du tier 2 a trois effets (B56).

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 2 : fusionnée, `v0.6.2` posé sur un commit de `main`, CI et release vertes ; la vague 2 passe à « close ».

## Fichiers

`p05-bestiaire-tier-2` pour la spec et le plan ; `bestiaire-vague-3` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions et la résolution symétrique tels que la vague 2 les a livrés (sa spec, son ADR) ; `lib/game/systems/encounter_system.dart` et la demi-place de la vague 2 ; `lib/game/systems/layout_system.dart` ; `lib/game/controllers/combat_controller.dart` (la liste des ennemis d'un combat, la victoire) et `TurnPhaseManager` (l'ordre des actions ennemies) ; `lib/game/services/damage_pipeline.dart` et la rune `assets/data/forge_upgrades/piercing.json` (le perce-armure du héros) ; la récompense d'un combat (`RewardController`) ; ADR-122 (un combat fini ne rouvre aucun tour) ; le cadrage §1.3 et §2.

## La spec doit fixer

1. **L'invocation** : l'effet qui la porte, l'ennemi invoqué (un ennemi du bestiaire, B26, B27), le prix de l'action (B23), le plafond (deux rats), la réinvocation d'un rat tué, la place des invoqués de part et d'autre de l'alpha (B18) ; ce qui arrive à la mort de l'alpha (B24) ; les récompenses (B25) ; la meute à l'écran, qui compte pour 2 cartes, et le second alpha qui attend en réserve (B21, B30, B19) ; l'invocation écrite pour toute famille — le Nécromancien du tier 3 invoquera le Squelette.
2. **L'aura** : un bonus en donnée, qui dépend des alliés vivants ; le lien de meute comme son premier cas (la Puissance seule, B22) ; ce qu'un rat libre n'y gagne pas.
3. **Viser un allié** : la cible d'un effet d'ennemi parmi les autres ennemis, et le choix de cette cible.
4. **Le perce-armure** : ignorer l'armure, ou la détruire ; sa place dans le calcul partagé ; ce que la rune du héros en garde.
5. **Plusieurs coups** (B54) : chaque coup résolu à part, avec ce qu'il déclenche — esquive, Foudre, statuts.
6. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; le Squelette qui prend la Faiblesse.
7. **Ce que le joueur lit** : l'invocation annoncée, l'aura et sa source, l'armure détruite.
8. **Les outils** : l'éditeur de contenu, le menu de debug.
9. **Les tests** (ADR-113).

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

Les phases et le choix d'intention (vague 4), les soutiens de tier 4 (le Chaman), le cadre et les fonds (vague 5), P-14, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes.

## Tâche à risque

**L'invocation** : un ennemi qui entre en plein combat touche la liste des ennemis, le placement, l'ordre des actions, la victoire et la récompense. Un combat gagné ne doit rouvrir aucun tour (ADR-122).

## Pour `memory-bank-sync`

Un ADR pour l'invocation et l'aura ; les fiches `_rules` du bestiaire et du combat que le diff périme ; la ligne P-05 de `docs/ROADMAP.md`.

## Ce que le joueur voit

À partir de l'acte 6, un chef de meute qui appelle ses rats et les rend plus forts tant qu'il vit ; des squelettes qui affaiblissent ; des ennemis qui empoisonnent, rendent vulnérable, rongent l'armure.
