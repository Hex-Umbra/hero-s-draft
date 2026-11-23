# Vague 9 — `0.6.9` — le tier 5

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1. Écrite le 22/11 ; placée le 23/11 après la refonte de la difficulté et le tier 4 (B69). Écrite avant les vagues 2 à 8 : relis leurs specs, et revérifie chaque chemin.

**Poids** : lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **L'ouverture du tier 5** ([catalogue](catalogue_mecanismes.md), #17) : `maxTierAuthored` passe à 5, sur le format que la [vague 8](vague_8_tier_4.md) aura posé. Avec la cadence d'aujourd'hui (B60), le tier 5 se débloque à l'acte 21 ; la refonte de la difficulté (vague 7) aura dit si cette cadence tient.
- **Le cadre du tier 5**, un asset posé sur la géométrie de la vague 2.
- **Les dégâts différés** (#18) : une marque posée sur le héros, qui frappe plus tard.
- **Le soin de soi** (#10) : il se construit ici, avec la Liche, son premier ennemi (B46, B68).
- **Les ennemis de tier 5**, proposés le 27/07 comme des « quasi-boss » — **la liste est à confirmer** (prérequis 1) ; leurs lignes complètes sont au [catalogue des ennemis](catalogue_ennemis.md), §6 :

| Ennemi | Mécanisme | Source |
|:---|:---|:---|
| Liche mineure | un cycle de quatre intentions : se renforcer, une attaque lourde, se soigner, une attaque qui perce l'armure | 27/07 — son « attaque de zone » ne veut rien dire contre un héros seul |
| Béhémoth de guerre | des PV énormes, une attaque massive tous les deux tours, que le panneau annonce | 27/07 |
| Cavalier de la mort | la marque à dégâts différés, et une esquive occasionnelle | 27/07 |
| Chimère trifrons | trois intentions en alternance : Feu, Gel, Foudre | 27/07 |
| Dragon juvénile | la rage sous 50 % de ses PV, avec les phases du tier 3 | 27/07, P-09 |

## Prérequis — avant l'ouverture

1. **La liste des ennemis**, confirmée, réduite ou complétée par le propriétaire.
2. **Les sprites, tous livrés** (B51, B65) : les lignes du tier 5 du [catalogue des ennemis](catalogue_ennemis.md) à ✅. Aucun n'existe. **Le cadre du tier 5** aussi, par `art_src/tools/frame_tier.py`, et les sprites se valident dessus.
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - **un tier 5 ou un boss** : ce qui sépare un ennemi de tier 5, que le 27/07 appelait un « quasi-boss », d'un boss du tier à part (B47) ;
   - **la marque** : un statut à elle, ou une forme du Feu, qui se résout déjà au tour du héros ; combien de tours avant qu'elle frappe, et comment le compte à rebours se lit ; si elle survit à la mort du Cavalier, comme le Poison ;
   - **le Béhémoth** : l'attaque massive annoncée un tour avant, comme toute intention (vague 1), ou deux — une annonce à deux tours serait un mécanisme de plus, absent du catalogue ;
   - les valeurs des ennemis.

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 8 : fusionnée, `v0.6.8` posé sur un commit de `main`, CI et release vertes ; la vague 8 passe à « close ».

## Fichiers

`p05-bestiaire-tier-5` pour la spec et le plan ; `bestiaire-vague-9` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions (vague 3), l'esquive (vague 4), les phases (vague 6), l'ouverture d'un tier de la [vague 8](vague_8_tier_4.md) — leurs specs, leurs ADR ; ce que la refonte de la difficulté (vague 7) a changé ; `lib/game/systems/charge_rules.dart` et `lib/game/controllers/combat/status_effect_processor.dart` (le Feu, qui se résout au tour du héros ; le Poison, qui s'additionne) ; ADR-122 (un combat fini ne rouvre aucun tour) ; la ligne P-09 de `docs/ROADMAP.md` ; le cadrage §1.

## La spec doit fixer

1. **L'ouverture du tier 5** : le plafond, et ce que la note et le budget donnent à l'acte où il s'ouvre.
2. **Les dégâts différés** : l'effet qui pose la marque, son délai, le moment où elle frappe, ce qui l'efface ; ce qui arrive en fin de combat.
3. **Le soin de soi** : l'effet, et ce qui l'empêche d'allonger un combat sans fin.
4. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; la rage du Dragon, écrite comme une phase.
5. **Ce que le joueur lit** : la marque et son compte à rebours, la rage, l'attaque massive annoncée.
6. **Les outils** : l'éditeur de contenu, le menu de debug (sauter à l'acte d'ouverture, poser une marque).
7. **Les tests** (ADR-113).

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

Le tier boss, son cadre et les boss (`0.7.0`) ; aucune reprise de la formule de difficulté (vague 7) ; P-14, P-19, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes.

## Tâche à risque

**La marque et la fin du combat** : une marque qui frappe après la mort du dernier ennemi ne doit rouvrir aucun tour (ADR-122), et une marque qui tue le héros doit conclure le combat comme un coup ordinaire.

## Pour `memory-bank-sync`

Un ADR pour les dégâts différés ; les fiches `_rules` du bestiaire et du combat que le diff périme ; les lignes P-05 et P-15 de `docs/ROADMAP.md` ; le [catalogue des ennemis](catalogue_ennemis.md).

## Ce que le joueur voit

Un cavalier dont la marque frappe plus tard, un dragon qui enrage quand il faiblit, une chimère qui change d'élément à chaque tour, un béhémoth dont on voit venir le coup, une liche qui fait tout à la fois.
