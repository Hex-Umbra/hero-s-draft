# P-40 bloc 2 — Trois bugs de cartes et de forge

**Date** : 2026-09-15 · **Chantier** : `ROADMAP.md` P-40, bloc 2 (lot S1 du programme P-40→P-44)
**Branche** : `fix/p40-bloc-2` · **Plan** : [`2026-09-15-p40-bloc-2-cartes-et-forge.md`](../plans/2026-09-15-p40-bloc-2-cartes-et-forge.md)
**Diagnostic d'origine** : [état des lieux du 05/08](../../analysis_reports/05082026_etat_des_lieux_heros_et_cartes_Opus5.md), Partie III.B — relevé il y a six semaines, donc re-vérifié contre le code avant ouverture (`ROADMAP.md` §10.4).

---

## 1. Re-vérification du 2026-09-15

| # | Constat du 05/08 | Statut | Preuve dans le code actuel |
|:---:|:---|:---|:---|
| B1 | La rune `enduring` se casse dès le tier 2 | ✅ **confirmé** | `deck_controller.dart:254` teste `contains('enduring:1')` (la ligne 188 citée a glissé). Deux chemins produisent un tier supérieur : `forge_fusion_screen.dart:42-68` et `deck_controller.dart:303-311`. Un troisième recopie le second : le dialogue de fusion, `deck_screen.dart:228-245`. |
| B2 | Les cartes de classe se dupliquent | ✅ **confirmé**, trois voies | `reward_controller.dart:170-185` (draft de boss tiré du deck), `shop_screen.dart:204-216` (Miroir Magique), `draft_screen.dart:563-570` (Miroir de montée de niveau). Aucune ne filtre `unique`. |
| B4 | Capacité de forge 10 au lieu de 5 sur une carte de classe | ✅ **confirmé**, sept points et non six | Les six du diagnostic, plus `card_text_renderer.dart:514-516`, la carte dessinée par Flame en combat. L'index que reçoit `card_rune_sockets.dart:19` est lui-même retrouvé par `ui_card_helpers.dart:215` **à partir du libellé traduit** de la rareté. L'intention est 5 : ADR-026 D2, `_rules/03-8:8`, `_rules/02-3:13`. |
| B5 | *Nouveau* — trois légendaires fusionnent en une `unique` | ✅ **constaté en relisant B4** | `deck_controller.dart:299` calcule `min(index + 1, values.length - 1)` : légendaire (4) + 1 = 5 = `unique`. La carte passe d'un multiplicateur 2,0 à 1,0 et ne fusionne plus jamais. Atteignable : `deck_screen.dart:106` n'écarte que `unique` du bouton de fusion, et le Miroir Magique copie une légendaire avec sa rareté. |

## 2. Trois causes racines

### C1 — L'échelle de rareté n'existe qu'implicitement

ADR-026 a ajouté `unique` **à la suite** de `legendary` dans `enum CardRarity`. Tout le code qui calcule sur `rarity.index` suppose une échelle continue de six marches. Il donne donc cinq emplacements de rune de plus à une carte `unique` (B4), et fait de `unique` la rareté qui suit `legendary` (B5). Deux bugs, un même calcul, recopié dans neuf fichiers.

### C2 — La règle d'acquisition est réécrite à chaque source

« Une carte `unique` n'entre dans le deck qu'au draft de départ » (ADR-026 D3, ADR-051) est un filtre écrit en ligne à chaque source de cartes : l'étal de la boutique, la carte bonus de boss. Les trois sources ajoutées plus tard **copient depuis le deck** au lieu de tirer du catalogue, et aucune n'a reçu le filtre.

### C3 — Le caractère binaire d'`enduring` n'est modélisé nulle part

Une rune `enduring` retire l'épuisement ou ne le retire pas : son tier ne veut rien dire. Cette propriété n'existe qu'en creux, sous forme de comparaisons à `'enduring'` codées en dur (tirage ×2, affichage ×3) et d'un test d'égalité sur la chaîne exacte `'enduring:1'` au moment de jouer la carte. Les trois algorithmes qui additionnent des tiers l'ignorent.

## 3. Décisions

**D1 — `CardRarity` porte l'échelle.** Deux accesseurs sur l'enum : `next`, la rareté que produit une fusion 3→1 (`null` pour `legendary`, sommet de l'échelle, comme pour `unique`, qui n'en fait pas partie), et `forgeSlotBonus`, les emplacements qu'ajoute la rareté (0 à 4 le long de l'échelle, 0 pour `unique`). La capacité se lit à un seul endroit : `CardData.forgeCapacityAt(rarity)`, et `CardInstance.forgeCapacity` pour une carte en jeu. `index` ne sert plus qu'à l'ordre d'affichage (`CardData.compareByDisplayOrder`). `DeckNotifier.upgradeCard`, sans appelant et porteur du même calcul, est supprimée.

**D2 — `CardRarity.isAcquirable`** vaut faux pour `unique` seulement. Les cinq sources l'appliquent : les deux qui filtraient déjà, et les trois qui copient depuis le deck, via `DeckState.copyableCards`.

**D3 — Une rune se déclare non cumulable en donnée.** `ForgeUpgradeData.stackable`, vrai par défaut, faux dans `enduring.json`. Une rune non cumulable est tirée au tier 1, s'affiche sans tier, n'est jamais proposée par la Forge de Fusion (ce qu'affirme déjà `_rules/03-8:43`), et une fusion 3→1 n'en garde qu'un exemplaire, au tier 1. Le mécanisme est une clé de donnée et non l'id `enduring` : depuis P-30, l'éditeur de contenu crée des runes, et une rune binaire créée depuis le jeu doit pouvoir le dire.

**D4 — `CardInstance.exhaustsOnPlay`** est la seule règle d'épuisement : un pouvoir l'est toujours, une carte `isExhaust` l'est sauf si elle porte `enduring`, **quel que soit le tier**. Le tier est ignoré même après D3, parce qu'une sauvegarde peut déjà contenir `enduring:2` ou `enduring:3`.

**D5 — `ForgeRuneRules`** (`lib/game/services/forge_rune_rules.dart`) regroupe `isStackable`, `consolidate` et `fusionOptionsFor`. Les trois copies de l'algorithme de cumul — Forge de Fusion, fusion 3→1, dialogue de fusion — n'en forment plus qu'une, qui connaît D3.

## 4. Ce que le joueur verra

- Une carte de classe porte **5 runes au plus**, et non plus 10. C'est un affaiblissement réel, conforme à l'intention d'ADR-026.
- Persistant tient ses promesses à tout tier, et la Forge de Fusion ne le propose plus.
- Ni le draft de boss ni les deux Miroirs ne proposent plus de copier une carte de classe.
- Trois légendaires identiques n'affichent plus de bouton de fusion.

## 5. Sauvegardes

Aucune migration, `schemaVersion` inchangé.

- **Carte de classe portant plus de 5 runes** : elle les garde toutes, simplement elle n'en accepte plus. `card_rune_sockets.dart` n'ajoute que des emplacements vides, donc toutes s'affichent en dehors du combat. En combat, `card_text_renderer.dart` ne dessine que la capacité : les runes au-delà de 5 ne s'y voient plus, mais leurs effets s'appliquent toujours.
- **`enduring:2` ou `enduring:3` déjà sauvegardé** : la rune redevient active (D4) et s'affiche « Persistant » comme avant. La prochaine fusion 3→1 la ramène au tier 1.
- **Copies de cartes de classe, `unique` issue d'une fusion de légendaires** : conservées telles quelles.

## 6. Hors périmètre, relevé en chemin

- **Le badge « Usage unique », l'avertissement d'infobulle et les particules d'épuisement ignorent Persistant**, à tout tier (`ui_card.dart:121`, `card_text_renderer.dart:586`, `card_component.dart:338`, `card_animator.dart:157`) : la carte part en défausse mais le jeu l'annonce épuisée. `exhaustsOnPlay` (D4) est prêt à servir de source unique.
- **La forge peut proposer une rune non cumulable que la carte porte déjà** (`forge_upgrade_dialog.dart:81-101` n'exclut que les doublons du tirage en cours) : un emplacement gaspillé si le joueur la prend.
- **Le tirage de runes est écrit deux fois**, dans `forge_upgrade_dialog.dart` et `shop_controller.dart` : c'est ainsi que le test sur `'enduring'` existait en deux exemplaires.
- **Les textes de runes restent codés en dur par id** dans `card_component.dart` et `card_text_renderer.dart`, alors que noms et descriptions bilingues sont en donnée : une rune créée par l'éditeur n'y apparaît pas.
- Vérifié sans suite : aucun pouvoir ne porte `isExhaust`, Persistant n'est donc jamais proposé sur un pouvoir, où il ne ferait rien.

## 7. Stratégie de test

Chaque décision entre par un test qui échoue pour la bonne raison, et chaque bug par un test qui le reproduit dans le code de production, jamais dans une copie de son algorithme :

| Bug / décision | Test qui échoue avant la correction |
|:---|:---|
| B4 / D1 | Une carte `unique` de base 5 affiche 5 emplacements dans `UiCard` (10 aujourd'hui) |
| B5 / D1 | `mergeCards` sur trois légendaires laisse le deck intact ; `DeckScreen` n'affiche pas de bouton |
| B2 / D2 | Draft de boss, Miroir Magique et Miroir de montée de niveau ne proposent jamais la carte `unique` d'un deck |
| B1 / D4 | Une carte `isExhaust` portant `enduring:2` part en défausse |
| B1 / D3, D5 | Deux `enduring:1` ne rendent pas une carte éligible à la Forge de Fusion ; une fusion 3→1 de trois `enduring:1` donne `enduring:1` |
| D3 | La boutique ne tire une rune non cumulable qu'au tier 1 — avec un id autre que `enduring`, pour prouver que c'est la donnée qui décide |

## 8. Documentation — bloc 3 du même chantier

Les dix dérives de la Partie III.C sont re-vérifiées une à une par `memory-bank-sync`, qui est le propriétaire de ces fiches. Ce bloc 2 en change trois : `_rules/03-8:8` et `_rules/03-8:43` **deviennent vraies** par le code, sans retouche. `_rules/02-4:9` et `_patterns/10-00:88` portent l'ancienne formule `baseMaxForgeUpgrades + rarityIndex` et sont à corriger. L'affirmation d'ADR-051 sur le pool de boss est dépassée : un ADR est gelé, il lui faut donc un successeur plutôt qu'une réécriture.
