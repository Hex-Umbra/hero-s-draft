# Vague 5 — `0.6.5` — le tier 2

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11, avant les vagues 2 à 4 : **la spec de la vague 3 aura fixé le format des intentions** sur lequel celle-ci s'écrit, celle de la vague 2 le placement où la meute se pose, celle de la vague 4 la demi-place — relis-les avant tout, et revérifie chaque chemin.

**Poids** : lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **Les mécanismes du tier 2** ([catalogue](catalogue_mecanismes.md), #4, #11, #12, #14 et #16) : plusieurs coups (B54), l'invocation, l'aura, le perce-armure, et **le choix d'intention** — un tirage pondéré, ou une intention sous condition, à côté du cycle fixe —, qui entre dès ce tier pour y préparer le joueur (B70). « Viser un allié » (#13) n'en est plus : il se construit avec son premier ennemi, le Chaman orc du tier 4 (B46, B68).
- **La famille du Rat entière** : le Rat alpha (tier 2, B20), qui entre seul et invoque ses rats un par un, deux au plus ; le lien de meute (B22, B29), écrit comme une aura.
- **Les ennemis de tier 2**, proposés le 22/11 — **la liste est à confirmer** (prérequis 1) ; leurs lignes complètes sont au [catalogue des ennemis](catalogue_ennemis.md), §3 :

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

1. **La liste des ennemis**, confirmée ou réduite par le propriétaire, et **l'ennemi qui porte le choix d'intention** (B70) : aucun n'est désigné.
2. **Les sprites, tous livrés** (B51, B65) : les lignes du tier 2 du [catalogue des ennemis](catalogue_ennemis.md) à ✅. Existent : le Rat alpha (`art_src/sprites/rat/tier_1/rat_geant.aseprite`, B43) et le Squelette de tier 2, en refonte en 128 × 192 dans `art_src/sprites/squelette/tier_2/` — le Squelette est redessiné ici (B52). **À trancher** : le Rat alpha a été produit comme un tier 1 (son dossier, son brief) alors qu'il est de tier 2 — la direction artistique veut plus de détail au tier 2 ([DA évolutive](../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md), §16.1) : il se garde tel quel, ou se retouche. Les autres sprites sont à produire.
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - les questions de la meute (cadrage §2) : l'invocation s'annonce-t-elle comme une intention, un tour avant ; un rat invoqué n'agit-il qu'au tour suivant ; la meute compte-t-elle pour 2 dès l'entrée de l'alpha ; le prix de l'alpha dans le budget, qui doit couvrir des rats entrant sans rien coûter ;
   - les pourcentages du lien de meute (+20 % par rat, +25 % pour le rat : des exemples, B22, B29) ;
   - **la durée d'un statut posé sur le héros pendant la phase ennemie** : aujourd'hui, une Faiblesse d'un tour expirerait avant d'avoir réduit une seule attaque (voir « Pièges ») — la règle se fixe avant les valeurs ;
   - les valeurs des ennemis, et la Faiblesse du Squelette ;
   - le perce-armure : ignorer l'armure, la détruire, ou les deux ;
   - ce que le joueur lit d'une invocation et d'une aura (pastille, languette, fiche) ;
   - **le choix d'intention et la lisibilité** : le panneau annonce l'intention un tour avant (vague 1) — une intention tirée au hasard reste-t-elle annoncée, et une intention sous condition dit-elle sa condition ;
   - le « +1 » de B6, si une intention du tier 2 a trois effets (B56).

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 4 : fusionnée, `v0.6.4` posé sur un commit de `main`, CI et release vertes ; la vague 4 passe à « close ».

## Fichiers

`p05-bestiaire-tier-2` pour la spec et le plan ; `bestiaire-vague-5` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions et la résolution symétrique tels que la vague 3 les a livrés (sa spec, son ADR) ; `lib/game/systems/encounter_system.dart` et la demi-place de la vague 4 ; `lib/game/systems/layout_system.dart` (le placement de la vague 2) ; `lib/game/controllers/combat_controller.dart` (la liste des ennemis d'un combat, la victoire) et `TurnPhaseManager` (l'ordre des actions ennemies) ; `lib/game/services/damage_pipeline.dart` et la rune `assets/data/forge_upgrades/piercing.json` (le perce-armure du héros) ; la récompense d'un combat (`RewardController`) ; ADR-122 (un combat fini ne rouvre aucun tour) ; le cadrage §1.3 et §2.

## La spec doit fixer

1. **L'invocation** : l'effet qui la porte, l'ennemi invoqué (un ennemi du bestiaire, B26, B27), le prix de l'action (B23), le plafond (deux rats), la réinvocation d'un rat tué, la place des invoqués de part et d'autre de l'alpha (B18) ; ce qui arrive à la mort de l'alpha (B24) ; les récompenses (B25) ; **le marqueur d'invoqué**, qui écarte un rat invoqué des récompenses et des déclencheurs de mort (voir « Pièges ») ; la meute à l'écran, qui compte pour 2 cartes, et le second alpha qui attend en réserve (B21, B30, B19) ; l'invocation écrite pour toute famille — le Nécromancien du tier 3 invoquera le Squelette.
2. **L'aura** : un bonus en donnée, qui dépend des alliés vivants ; le lien de meute comme son premier cas (la Puissance seule, B22) ; ce qu'un rat libre n'y gagne pas.
3. **Le perce-armure** : ignorer l'armure, ou la détruire ; sa place dans le calcul partagé ; ce que la rune du héros en garde.
4. **Plusieurs coups** (B54) : chaque coup résolu à part, avec ce qu'il déclenche — esquive, Foudre, statuts.
5. **Le choix d'intention** (B70) : le tirage pondéré, la condition, et ce que le panneau annonce ; le cycle fixe reste le cas par défaut, et aucun autre ennemi ne change de comportement.
6. **La durée d'un statut posé en phase ennemie**, selon la réponse du propriétaire.
7. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; le Squelette qui prend la Faiblesse.
8. **Ce que le joueur lit** : l'invocation annoncée, l'aura et sa source, l'armure détruite, l'intention choisie.
9. **Les outils** : l'éditeur de contenu, le menu de debug.
10. **Les tests** (ADR-113).

## Pièges relevés à l'audit du 23/11

Lus dans le code, sans exécution : à revérifier.

- **Un rat réinvocable nourrit les effets « à chaque ennemi abattu »** : chaque mort déclenche aujourd'hui les effets de mort — le passif *Frénésie* donne de la Puissance et une pioche par ennemi abattu, et des reliques s'y déclenchent aussi. Un rat que l'alpha réinvoque à volonté (B23) deviendrait une ressource pour le héros. D'où le marqueur d'invoqué : ni récompense (B25), ni déclencheur de mort.
- **Une Faiblesse d'un tour expire avant d'agir** : un statut posé sur le héros pendant la phase ennemie vieillit dès le début de son tour. Le Poison n'est pas touché : il frappe avant.
- **La place d'un invoqué** : une carte neuve s'ajoute aujourd'hui en fin de liste, quand B18 demande une place de part et d'autre de l'alpha ; et le voisinage du Feu suit l'ordre de cette liste.
- **L'intention d'un invoqué** : la fin de la phase ennemie fait avancer l'intention de tous ; un rat invoqué pendant cette phase sauterait un pas de son cycle.
- **Le perce-armure côté héros** : il existe pour les ennemis, mais le chemin des dégâts reçus par le héros ne le transmet pas.
- **Une intention conditionnelle lirait une armure périmée** : l'intention suivante se tire à la fin de la phase ennemie, et l'armure du héros est remise à zéro juste après. Une condition « si le héros a de l'armure » lue au tirage lirait donc l'armure d'avant. Deux sorties : tirer l'intention après la remise à zéro, ou lire délibérément l'armure d'avant et le dire au joueur.
- **Une branche de tirage aléatoire existe déjà** dans le contrôleur du combat, à côté du cycle fixe, et aucun ennemi ne s'en sert.

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

Les phases (vague 6), viser un allié et le soutien (le Chaman, vague 8), aucune reprise des cadres ni des fonds (vague 2), P-14, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes ; ni la refonte de la difficulté (B64).

## Tâche à risque

**L'invocation** : un ennemi qui entre en plein combat touche la liste des ennemis, le placement, l'ordre des actions, la victoire et la récompense. Un combat gagné ne doit rouvrir aucun tour (ADR-122).

## Pour `memory-bank-sync`

Un ADR pour l'invocation et l'aura, un pour le choix d'intention ; les fiches `_rules` du bestiaire et du combat que le diff périme ; la ligne P-05 de `docs/ROADMAP.md` ; le [catalogue des ennemis](catalogue_ennemis.md), dont les lignes du tier 2 renvoient désormais à leurs données.

## Ce que le joueur voit

À partir de l'acte 6, un chef de meute qui appelle ses rats et les rend plus forts tant qu'il vit ; des squelettes qui affaiblissent ; des ennemis qui empoisonnent, rendent vulnérable, rongent l'armure.
