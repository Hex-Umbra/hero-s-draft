# Vague 6 — `0.6.6` — le tier 3

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11, avant les vagues 2 à 5 : relis leurs specs, et revérifie chaque chemin.

**Poids** : lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **Le mécanisme du tier 3** ([catalogue](catalogue_mecanismes.md), #15) : **les phases** — sous un seuil de PV, l'ennemi change de liste d'intentions. **Le choix d'intention** (#16) — un tirage pondéré, ou une intention sous condition — existe depuis la vague 5 (B70) : un ennemi de cette vague peut le reprendre, si le propriétaire le lui donne (prérequis 3).
- **Les ennemis de tier 3**, proposés le 22/11 — **la liste est à confirmer** (prérequis 1) ; leurs lignes complètes sont au [catalogue des ennemis](catalogue_ennemis.md), §4 :

| Ennemi | Mécanisme | Source |
|:---|:---|:---|
| Orc Furieux (existant) | la Puissance, signature de sa famille (B2, B48) — sa forme est à fixer | cadrage |
| Squelette faucheuse | la Faiblesse, forme de tier 3 de la famille Squelette | sprite existant |
| Nécromancien novice | invoque le Squelette (B27), avec l'invocation de la vague 5 | 27/07, cadrage |
| Chevalier déchu | Armure, puis frappe perce-armure | 27/07 |
| Sorcière des marais | Poison et Gel en alternance | 27/07 |
| Ogre bourrin | la rage : une phase sous un seuil de PV | 27/07 |
| Gargouille animée | Armure, puis deux attaques | 27/07 |

## Prérequis — avant l'ouverture

1. **La liste des ennemis**, confirmée ou réduite par le propriétaire.
2. **Les sprites, tous livrés** (B51, B65) : les lignes du tier 3 du [catalogue des ennemis](catalogue_ennemis.md) à ✅. Existe : la Squelette faucheuse (`art_src/sprites/squelette/tier_3/`). À produire : les autres, et l'Orc, redessiné (B52).
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - **la lignée** : la Faucheuse est-elle une forme qui succède au Squelette (une évolution d'une forme à l'autre, que B2 laissait en attente, et la [DA évolutive](../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md) §16.3 aussi), ou un ennemi à part de la même famille ;
   - **comment une phase se lit** : le seuil visible ou non, un signal au changement, ce que la fiche en dit ;
   - **le choix d'intention** : un ennemi de cette vague le reprend-il, et lequel ? Le mécanisme et sa lisibilité viennent de la vague 5 (B70) ;
   - **le Nécromancien** : combien de Squelettes il invoque, son prix dans le budget, et ce que rapporte un Squelette invoqué — B25 ne parle que des rats ;
   - l'Orc : ce que devient sa signature ;
   - les valeurs des ennemis.

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 5 : fusionnée, `v0.6.5` posé sur un commit de `main`, CI et release vertes ; la vague 5 passe à « close ».

## Fichiers

`p05-bestiaire-tier-3` pour la spec et le plan ; `bestiaire-vague-6` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions de la vague 3, l'invocation et le perce-armure de la vague 5 (leurs specs, leurs ADR) ; `lib/models/enemy_instance.dart` (l'intention courante et le cycle) ; `TurnPhaseManager` (le moment où l'intention suivante est choisie et annoncée) ; `enemy_intents_panel.dart`, `enemy_sheet_view.dart` ; la ligne P-09 de `docs/ROADMAP.md`, que les phases préparent ; le cadrage §1.

## La spec doit fixer

1. **Les phases** : le seuil en donnée, la liste d'intentions de chaque phase, le passage (une seule fois, et à quel moment du tour), ce qui arrive à l'intention déjà annoncée ; **le format se choisit en connaissant ses suites** : la rage du Dragon juvénile (tier 5) et un boss à plusieurs phases (P-09) devront s'y écrire — les boss n'ayant encore aucun concept, la spec écrit ce qu'elle en suppose.
2. **Le choix d'intention**, seulement si le propriétaire le donne à un ennemi de cette vague (prérequis 3) : son écriture pour cet ennemi, sur le mécanisme de la vague 5, et sa rencontre avec les phases — une liste d'intentions par phase peut-elle être tirée plutôt que cyclée.
3. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; l'Orc ; la Faucheuse et le Squelette selon la réponse sur la lignée.
4. **Ce que le joueur lit** : la phase, le changement, l'intention choisie.
5. **Les outils** : l'éditeur de contenu, le menu de debug (forcer un seuil de PV).
6. **Les tests** (ADR-113).

## Pièges relevés à l'audit du 23/11

Lus dans le code, sans exécution : à revérifier.

- **Le moment du tirage** : l'intention suivante se choisit à la fin de la phase ennemie, alors qu'un coup du héros peut faire franchir un seuil de PV entre l'annonce et l'action (la tâche à risque).
- **Le changement de comportement au seuil n'existe nulle part** : ni l'ennemi ni ses stats n'ont aujourd'hui de notion de comportement lié aux PV restants.

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

La refonte de la difficulté (vague 7) ; les tiers 4 et 5 (vagues 8 et 9) ; aucune reprise des cadres ni des fonds (vague 2) ; le tier boss et les boss (`0.7.0`) ; P-14, P-19, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes ; ni la refonte de la difficulté (B64).

## Tâche à risque

**Les phases et l'annonce** : l'intention que le panneau annonce doit être celle qui se résout, même quand un coup du héros fait franchir un seuil entre l'annonce et l'action.

## Pour `memory-bank-sync`

Un ADR pour les phases ; les fiches `_rules` du bestiaire et du combat que le diff périme ; les lignes P-05 et P-09 de `docs/ROADMAP.md` ; le [catalogue des ennemis](catalogue_ennemis.md), dont les lignes du tier 3 renvoient désormais à leurs données.

## Ce que le joueur voit

À partir de l'acte 11, des ennemis qui changent quand ils faiblissent — un ogre qui enrage —, un nécromancien qui relève des squelettes, une faucheuse, un chevalier qui perce l'armure.
