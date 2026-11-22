# Vague 6 — `0.6.6` — le tier 5

> Fiche de vague du [chantier du bestiaire](README.md). Les décisions citées sont celles du [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1 ; le tier 5 entre au programme par B59. Écrite le 22/11, avant les vagues 2 à 5 : relis leurs specs, et revérifie chaque chemin.

**Poids** : lourd — une spec, deux parties (les mécanismes, puis les ennemis).

## Ce qu'elle livre

- **L'ouverture du tier 5** ([catalogue](catalogue_mecanismes.md), #17) : `maxTierAuthored` passe à 5, sur le format de la vague 5.
- **Les dégâts différés** (#18) : une marque posée sur le héros, qui frappe plus tard.
- **Les ennemis de tier 5**, proposés le 27/07 comme des « quasi-boss » — **la liste est à confirmer** (prérequis 1) :

| Ennemi | Mécanisme | Source |
|:---|:---|:---|
| Liche mineure | un cycle de quatre intentions : se renforcer, une attaque lourde, se soigner, une attaque qui perce l'armure | 27/07 — son « attaque de zone » ne veut rien dire contre un héros seul |
| Béhémoth de guerre | des PV énormes, une attaque massive tous les deux tours, que le panneau annonce | 27/07 |
| Cavalier de la mort | la marque à dégâts différés, et une esquive occasionnelle | 27/07 |
| Chimère trifrons | trois intentions en alternance : Feu, Gel, Foudre | 27/07 |
| Dragon juvénile | la rage sous 50 % de ses PV, avec les phases de la vague 4 | 27/07, P-09 |

## Prérequis — avant l'ouverture

1. **La liste des ennemis**, confirmée, réduite ou complétée par le propriétaire.
2. **Les sprites, tous validés** (B51). Aucun n'existe : tous sont à produire.
3. **Les réponses du propriétaire** (classe P), sur maquettes quand elles se voient :
   - **un tier 5 ou un boss** : ce qui sépare un ennemi de tier 5, que le 27/07 appelait un « quasi-boss », d'un boss du tier à part (B47) ;
   - **la marque** : un statut à elle, ou une forme du Feu, qui se résout déjà au tour du héros ; combien de tours avant qu'elle frappe, et comment le compte à rebours se lit ; si elle survit à la mort du Cavalier, comme le Poison ;
   - **le Béhémoth** : l'attaque massive annoncée un tour avant, comme toute intention (vague 1), ou deux ;
   - les valeurs des ennemis.

## Porte d'entrée

Celle de l'orchestration §3.1, sur la vague 5 : fusionnée, `v0.6.5` posé sur un commit de `main`, CI et release vertes ; la vague 5 passe à « close ».

## Fichiers

`p05-bestiaire-tier-5` pour la spec et le plan ; `bestiaire-vague-6` pour le compte rendu et les tests manuels.

## À lire

Le format des intentions de la vague 2, les phases et le choix d'intention de la vague 4, l'ouverture d'un tier de la vague 5 (leurs specs, leurs ADR) ; `lib/game/systems/charge_rules.dart` et `lib/game/controllers/combat/status_effect_processor.dart` (le Feu, qui se résout au tour du héros ; le Poison, qui s'additionne) ; ADR-122 (un combat fini ne rouvre aucun tour) ; la ligne P-09 de `docs/ROADMAP.md` ; le cadrage §1.

## La spec doit fixer

1. **L'ouverture du tier 5** : le plafond, et ce que la note et le budget donnent à l'acte 21.
2. **Les dégâts différés** : l'effet qui pose la marque, son délai, le moment où elle frappe, ce qui l'efface ; ce qui arrive en fin de combat.
3. **Les ennemis** : leurs fichiers, leurs sprites, leurs valeurs, leurs textes en français et en anglais ; la rage du Dragon, écrite comme une phase.
4. **Ce que le joueur lit** : la marque et son compte à rebours, la rage, l'attaque massive annoncée.
5. **Les outils** : l'éditeur de contenu, le menu de debug (sauter à l'acte 21, poser une marque).
6. **Les tests** (ADR-113).

## À arbitrer

Les questions P ont leur réponse dans les prérequis. Le reste est de classe T.

## Ne pas absorber

Le cadre et les fonds (vague 7) ; le tier boss et les boss (vague 8) ; P-14, P-19, P-44 lot 2 ; aucun ennemi hors de la table ; aucun équilibrage des ennemis des vagues précédentes.

## Tâche à risque

**La marque et la fin du combat** : une marque qui frappe après la mort du dernier ennemi ne doit rouvrir aucun tour (ADR-122), et une marque qui tue le héros doit conclure le combat comme un coup ordinaire.

## Pour `memory-bank-sync`

Un ADR pour les dégâts différés ; les fiches `_rules` du bestiaire et du combat que le diff périme ; les lignes P-05 et P-15 de `docs/ROADMAP.md`.

## Ce que le joueur voit

À partir de l'acte 21, si la cadence reste celle d'aujourd'hui : un cavalier dont la marque frappe plus tard, un dragon qui enrage quand il faiblit, une chimère qui change d'élément à chaque tour, un béhémoth dont on voit venir le coup, une liche qui fait tout à la fois.
