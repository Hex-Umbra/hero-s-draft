# Vague 6 — `0.6.6` — le tier 4

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1 ; le tier 4 entre au programme par B59. Écrite le 22/11, avant les vagues 2 à 5 : relis leurs specs, et revérifie chaque chemin.

**Poids** : moyen à lourd — une spec, deux parties (les mécanismes, puis les ennemis). La plupart des mécanismes du tier 4 existent déjà à son ouverture ; le poids est dans les ennemis.

## Ce qu'elle livre

- **L'ouverture du tier 4** ([catalogue](catalogue_mecanismes.md), #17) : `maxTierAuthored` passe de 3 à 4. La cadence ne change pas (B60) : un tier tous les cinq actes (`EncounterSystem.getUnlockedTier`), le tier 4 se débloque à l'acte 16.
- **Le cadre du tier 4**, un asset posé sur la géométrie que la vague 2 a codée pour les cinq tiers.
- **Le soutien** : le Chaman soigne ou renforce un autre ennemi. Viser un allié (#13) vient de la vague 4, et le soin de soi (#10) de son premier ennemi ; cette vague ne construit que ce qui manque encore.
- **Les ennemis de tier 4**, proposés le 27/07 — **la liste est à confirmer** (prérequis 1). Elle en compte cinq, quand les tiers 1 à 3 en ont sept :

| Ennemi | Mécanisme | Source |
|:---|:---|:---|
| Élémentaire de feu | pose du Feu à chaque coup | 27/07 |
| Élémentaire de givre | pose du Gel à chaque coup | 27/07 |
| Chevalier spectral | une attaque qui perce toujours l'armure | 27/07 |
| Chaman orc | soigne ou renforce les autres ennemis : le premier soutien | 27/07 |
| Aberration difforme | un coup qui pose à la fois Vulnérable et Faiblesse | 27/07 |

## Prérequis — avant l'ouverture

1. **La liste des ennemis**, confirmée, réduite ou complétée par le propriétaire.
2. **Les sprites, tous validés** (B51). Aucun n'existe : tous sont à produire. **Le cadre du tier 4** aussi, par `art_src/tools/frame_tier.py`, et les sprites se valident dessus.
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - **les familles** (B2) : les Élémentaires sont-ils les formes hautes des slimes du tier 1, qui posent les mêmes charges, ou une famille à part ; le Chaman est-il de la famille de l'Orc ;
   - **le soutien à l'écran** : quel allié le Chaman vise, et comment le joueur le lit avant qu'il agisse ;
   - les valeurs des ennemis, et les doses de charge par coup (au tier 1, une charge par coup ne fait presque rien sur le héros : voir B53 et le deck du tier 1).

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 5 : fusionnée, `v0.6.5` posé sur un commit de `main`, CI et release vertes ; la vague 5 passe à « close ».

## Fichiers

`p05-bestiaire-tier-4` pour la spec et le plan ; `bestiaire-vague-6` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions de la vague 3 ; viser un allié, le perce-armure et l'invocation de la vague 4 ; les phases et le choix d'intention de la vague 5 (leurs specs, leurs ADR) ; `lib/game/systems/encounter_system.dart` (`getUnlockedTier`, `maxTierAuthored`, la note d'un ennemi, 15 par tier, et le budget d'un combat) ; `lib/game/systems/charge_rules.dart` ; la ligne P-15 de `docs/ROADMAP.md` ; le cadrage §1.

## La spec doit fixer

1. **L'ouverture d'un tier** : le plafond, la cadence d'aujourd'hui gardée (B60), ce que la note et le budget donnent à l'acte 16. Elle s'écrit pour que la vague 7 n'ait qu'un nombre à changer.
2. **Le soutien** : l'effet qui vise un allié (soin, Armure, Puissance), le choix de cet allié, et ce qui arrête un combat sans fin entre deux ennemis qui se soignent l'un l'autre.
3. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; leurs familles, selon la réponse du propriétaire.
4. **Ce que le joueur lit** : le soutien annoncé, et sa cible.
5. **Les outils** : l'éditeur de contenu, le menu de debug (sauter à l'acte 16).
6. **Les tests** (ADR-113).

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

Le tier 5 et les dégâts différés (vague 7) ; le cadre du tier 5 (vague 7) ; les boss (vague 8) ; P-14, P-19, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes.

## Tâche à risque

**L'ouverture du tier 4** : elle change la composition de chaque combat à partir de l'acte 16, c'est-à-dire la note, le budget et le mélange des tiers. Le tirage doit rester capable de remplir un combat aux actes où le tier 4 apparaît.

## Pour `memory-bank-sync`

Un ADR pour l'ouverture d'un tier et le soutien ; les fiches `_rules` du bestiaire et du combat que le diff périme ; les lignes P-05 et P-15 de `docs/ROADMAP.md`.

## Ce que le joueur voit

À partir de l'acte 16 : des élémentaires qui brûlent ou gèlent à chaque coup, un chevalier spectral que l'armure n'arrête pas, un chaman qui soigne ses alliés, une aberration qui affaiblit et rend vulnérable d'un seul coup.
