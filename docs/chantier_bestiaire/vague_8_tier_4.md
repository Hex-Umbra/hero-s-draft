# Vague 8 — `0.6.8` — le tier 4

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11 ; placée le 23/11 après la refonte de la difficulté (B69) : **le tier 4 se construit sur la formule que la vague 7 aura revue**. Écrite avant les vagues 2 à 7 : relis leurs specs, et revérifie chaque chemin.

**Poids** : moyen à lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **L'ouverture du tier 4** ([catalogue](catalogue_mecanismes.md), #17) : `maxTierAuthored` passe de 3 à 4. Avec la cadence d'aujourd'hui (B60), un tier tous les cinq actes (`EncounterSystem.getUnlockedTier`), le tier 4 se débloque à l'acte 16 ; la refonte de la difficulté (vague 7) aura dit si cette cadence tient.
- **Le cadre du tier 4**, un asset posé sur la géométrie que la vague 2 a codée pour les cinq tiers.
- **Le soutien** : le Chaman soigne ou renforce un autre ennemi. **Viser un allié** (#13) se construit ici, avec lui, son premier ennemi (B46, B68).
- **Les ennemis de tier 4**, proposés le 27/07 — **la liste est à confirmer** (prérequis 1) ; leurs lignes complètes sont au [catalogue des ennemis](catalogue_ennemis.md), §5. Elle en compte cinq, quand le tier 1 en a neuf et les tiers 2 et 3 sept :

| Ennemi | Mécanisme | Source |
|:---|:---|:---|
| Élémentaire de feu | pose du Feu à chaque coup | 27/07 |
| Élémentaire de givre | pose du Gel à chaque coup | 27/07 |
| Chevalier spectral | une attaque qui perce toujours l'armure | 27/07 |
| Chaman orc | soigne ou renforce les autres ennemis : le premier soutien | 27/07 |
| Aberration difforme | un coup qui pose à la fois Vulnérable et Faiblesse | 27/07 |

## Prérequis — avant l'ouverture

1. **La liste des ennemis**, confirmée, réduite ou complétée par le propriétaire.
2. **Les sprites, tous livrés** (B51, B65) : les lignes du tier 4 du [catalogue des ennemis](catalogue_ennemis.md) à ✅. Aucun n'existe. **Le cadre du tier 4** aussi, par `art_src/tools/frame_tier.py`, et les sprites se valident dessus.
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - **les familles** (B2) : les Élémentaires sont-ils les formes hautes des slimes du tier 1, qui posent les mêmes charges, ou une famille à part ; le Chaman est-il de la famille de l'Orc ;
   - **le soutien à l'écran** : quel allié le Chaman vise, et comment le joueur le lit avant qu'il agisse ;
   - les valeurs des ennemis, et les doses de charge par coup (au tier 1, une charge par coup ne fait presque rien sur le héros : voir B53 et le deck du tier 1) ;
   - **le « +1 » de B6** (B56) : l'Aberration pose deux statuts en plus de ses dégâts, soit une intention à trois effets.

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 7 : fusionnée, `v0.6.7` posé sur un commit de `main`, CI et release vertes ; la vague 7 passe à « close ».

## Fichiers

`p05-bestiaire-tier-4` pour la spec et le plan ; `bestiaire-vague-8` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions (vague 3) ; le perce-armure, l'invocation et le choix d'intention (vague 5) ; les phases (vague 6) — leurs specs, leurs ADR ; ce que la refonte de la difficulté (vague 7) a changé ; `lib/game/systems/encounter_system.dart` (`getUnlockedTier`, `maxTierAuthored`, la note d'un ennemi, 15 par tier, et le budget d'un combat) ; `lib/game/systems/charge_rules.dart` ; la ligne P-15 de `docs/ROADMAP.md` ; le cadrage §1.

## La spec doit fixer

1. **L'ouverture d'un tier** : le plafond, la cadence, ce que la note et le budget donnent à l'acte où le tier s'ouvre. Elle s'écrit pour que le tier 5 n'ait qu'un nombre à changer.
2. **Viser un allié et le soutien** : la cible d'un effet d'ennemi parmi les autres ennemis (soin, Armure, Puissance), le choix de cet allié, et ce qui arrête un combat sans fin entre deux ennemis qui se soignent l'un l'autre.
3. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; leurs familles, selon la réponse du propriétaire.
4. **Ce que le joueur lit** : le soutien annoncé, et sa cible.
5. **Les outils** : l'éditeur de contenu, le menu de debug (sauter à l'acte d'ouverture).
6. **Les tests** (ADR-113).

## Pièges relevés à l'audit du 23/11

Calculés sur les formules du code, sous hypothèses : à revérifier.

- **Le budget croît linéairement, les prix géométriquement** : les PV et les dégâts d'un ennemi suivent `1,35` et `1,25` puissance le palier d'actes, le budget d'un combat une droite. Aux actes 16 et suivants, un ennemi à gros PV peut dépasser le budget et n'être jamais tiré ; le tirage se rabat alors sur le moins cher.
- **Le tirage est uniforme** parmi les candidats que le budget permet : cinq ennemis de tier 4 se diluent parmi tous ceux des tiers 1 à 3.
- **La table d'XP a quinze entrées** (`assets/data/xp_curve.json`) ; au-delà, la dernière se répète.

C'est la raison pour laquelle ce tier vient après la refonte de la difficulté : ces trois points y auront été traités, ou laissés en connaissance de cause.

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

Le tier 5, son cadre et les dégâts différés (vague 9) ; les boss (`0.7.0`) ; aucune reprise de la formule de difficulté (vague 7) ; P-14, P-19, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes.

## Tâche à risque

**L'ouverture du tier 4** : elle change la composition de chaque combat à partir de l'acte où il s'ouvre, c'est-à-dire la note, le budget et le mélange des tiers. Le tirage doit rester capable de remplir un combat aux actes où le tier 4 apparaît.

## Pour `memory-bank-sync`

Un ADR pour l'ouverture d'un tier et le soutien ; les fiches `_rules` du bestiaire et du combat que le diff périme ; les lignes P-05 et P-15 de `docs/ROADMAP.md` ; le [catalogue des ennemis](catalogue_ennemis.md).

## Ce que le joueur voit

Des élémentaires qui brûlent ou gèlent à chaque coup, un chevalier spectral que l'armure n'arrête pas, un chaman qui soigne ses alliés, une aberration qui affaiblit et rend vulnérable d'un seul coup.
