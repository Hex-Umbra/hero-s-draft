# Vague 4 — `0.6.4` — le tier 3

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11, avant les vagues 2 et 3 : relis leurs specs, et revérifie chaque chemin.

**Poids** : lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **Les mécanismes du tier 3** ([catalogue](catalogue_mecanismes.md), #15 et #16) : **les phases** — sous un seuil de PV, l'ennemi change de liste d'intentions — et **le choix d'intention** — un tirage pondéré, ou une intention sous condition, à côté du cycle fixe.
- **Les ennemis de tier 3**, proposés le 22/11 — **la liste est à confirmer** (prérequis 1) :

| Ennemi | Mécanisme | Source |
|:---|:---|:---|
| Orc Furieux (existant) | la Puissance, signature de sa famille (B2, B48) — sa forme est à fixer | cadrage |
| Squelette faucheuse | la Faiblesse, forme de tier 3 de la famille Squelette | sprite existant |
| Nécromancien novice | invoque le Squelette (B27), avec l'invocation de la vague 3 | 27/07, cadrage |
| Chevalier déchu | Armure, puis frappe perce-armure | 27/07 |
| Sorcière des marais | Poison et Gel en alternance | 27/07 |
| Ogre bourrin | la rage : une phase sous un seuil de PV | 27/07 |
| Gargouille animée | Armure, puis deux attaques | 27/07 |

## Prérequis — avant l'ouverture

1. **La liste des ennemis**, confirmée ou réduite par le propriétaire.
2. **Les sprites, tous validés** (B51). Existe : la Squelette faucheuse (`art_src/creatures/squelette/tier_3/`). À produire : les autres, et l'Orc, redessiné (B52).
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - **la lignée** : la Faucheuse est-elle une forme qui succède au Squelette (une évolution d'une forme à l'autre, que B2 laissait en attente, et la [DA évolutive](../possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md) §16.3 aussi), ou un ennemi à part de la même famille ;
   - **comment une phase se lit** : le seuil visible ou non, un signal au changement, ce que la fiche en dit ;
   - **le choix d'intention et la lisibilité** : le panneau annonce l'intention un tour avant (vague 1) — une intention tirée au hasard reste-t-elle annoncée, et une intention sous condition dit-elle sa condition ;
   - l'Orc : ce que devient sa signature ;
   - les valeurs des ennemis.

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 3 : fusionnée, `v0.6.3` posé sur un commit de `main`, CI et release vertes ; la vague 3 passe à « close ».

## Fichiers

`p05-bestiaire-tier-3` pour la spec et le plan ; `bestiaire-vague-4` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions de la vague 2, l'invocation et le perce-armure de la vague 3 (leurs specs, leurs ADR) ; `lib/models/enemy_instance.dart` (l'intention courante et le cycle) ; `TurnPhaseManager` (le moment où l'intention suivante est choisie et annoncée) ; `enemy_intents_panel.dart`, `enemy_sheet_view.dart` ; la ligne P-09 de `docs/ROADMAP.md`, que les phases préparent ; le cadrage §1.

## La spec doit fixer

1. **Les phases** : le seuil en donnée, la liste d'intentions de chaque phase, le passage (une seule fois, et à quel moment du tour), ce qui arrive à l'intention déjà annoncée ; **le format se choisit en connaissant les vagues 6 et 8** : la rage du Dragon juvénile (tier 5) et un boss à plusieurs phases (P-09) devront s'y écrire sans reprise.
2. **Le choix d'intention** : le tirage pondéré, la condition, et ce que le panneau annonce ; le cycle fixe reste le cas par défaut, et aucun ennemi existant ne change de comportement.
3. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; l'Orc ; la Faucheuse et le Squelette selon la réponse sur la lignée.
4. **Ce que le joueur lit** : la phase, le changement, l'intention choisie.
5. **Les outils** : l'éditeur de contenu, le menu de debug (forcer un seuil de PV).
6. **Les tests** (ADR-113).

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

Les tiers 4 et 5 (vagues 5 et 6) ; le cadre et les fonds (vague 7) ; le tier boss et les boss (vague 8) ; P-14, P-19, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes.

## Tâche à risque

**Les phases et l'annonce** : l'intention que le panneau annonce doit être celle qui se résout, même quand un coup du héros fait franchir un seuil entre l'annonce et l'action.

## Pour `memory-bank-sync`

Un ADR pour les phases et le choix d'intention ; les fiches `_rules` du bestiaire et du combat que le diff périme ; les lignes P-05 et P-09 de `docs/ROADMAP.md`.

## Ce que le joueur voit

À partir de l'acte 11, des ennemis qui changent quand ils faiblissent — un ogre qui enrage —, d'autres dont le cycle ne se devine plus, un nécromancien qui relève des squelettes, une faucheuse, un chevalier qui perce l'armure.
