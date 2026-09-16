<!-- last-sync: 2026-09-16 | commit: fc93efc -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-40 est clos et fusionné** : la PR #37 a intégré `fix/p40-bloc-2` dans `main` le 2026-09-15
(`dc15184`). Les trois bugs de cartes et de forge relevés le 2026-08-05, re-vérifiés contre le code,
sont corrigés à leur cause —
[ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md) ; le **bloc 3**
(dérives documentaires) et le **bloc 4** (corpus de formation figé) sont livrés avec. `main` porte
811 tests au vert et `dart analyze` propre (Métriques de `progress.md`, vérifiées le 2026-09-16).

Le programme « Identité de classe & catalogue » reprend donc à **P-41** : spec révisée, plan du lot A
écrit et revu, pas encore exécuté.

Réserves à ne pas perdre de vue :

- **Les trois décisions du propriétaire du 2026-09-15 sont intégrées à `main`** par la PR #37 :
  changements visibles ajoutés à la note `0.5.1` (`2d19d42`), cartes abîmées par l'ancienne fusion
  de légendaires réparées au chargement (`71d97cb`), corpus `docs/formation-heros-draft/` figé en
  instantané daté (`69fef58`). Plus aucune branche de P-40 n'est en attente.
- **Un dossier de classe `gambler` vide**, laissé par une écriture de l'éditeur, faisait rougir deux
  tests sur `main`. Supprimé le 2026-09-15 ; `entity_writer.dart` tient ce cas pour « sans conséquence ».
- **Les changements visibles de P-30 ont rejoint la note `0.5.1`** (`d8d9319`, décision du
  propriétaire le 2026-09-14) : bouton « Quitter », retours arrière, fin du badge « NEW »,
  illustration de classe. Rien sur le menu de debug ni l'éditeur, absents des builds publiés.
- **⚠️ Les lots 1-2 de P-48 cassent les sauvegardes antérieures, sur le passif seulement.** Ids
  de passifs en `snake_case` (commit `7da5db2`), clé `run_save_v1` et `schemaVersion: 1`
  inchangées : une partie d'avant se recharge **et perd son passif de classe**, signalé par un
  `MissingSaveItem`. La note de version est le seul canal qui prévienne *avant*.
- **La note `0.5.1` est close et publiée** (décision du 2026-09-16). La version que visent P-42 et la
  suite est tenue dans `docs/ROADMAP.md` ; le numéro publié se lit dans `pubspec.yaml` et la 1ʳᵉ
  entrée de `assets/data/patch_notes.json`, jamais ici.
- **Les cartes de signature non `unique` fuient toujours entre classes** en boutique et sur le bonus
  de boss — [filtre de classe](../../docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md),
  à joindre à `CardRarity.isAcquirable`, avant ou avec P-42. **Re-vérifié contre le code le
  2026-09-16 : non fait.** Les deux prédicats fautifs ne testent que le type et la rareté
  (`shop_controller.dart:45-51`, `reward_controller.dart:189`), aucun des deux `Notifier` ne lit
  `runProvider.heroClassId`, et `CardData` ne porte aucun prédicat de proposabilité. Ce que P-40
  bloc 2 a fait à ces deux mêmes lignes, c'est y substituer `CardRarity.isAcquirable` au
  `rarity != unique` en ligne — la condition de classe n'y est jamais entrée, et le seul commit sur
  le sujet reste `39ac887`, qui documente le défaut sans le corriger.
- **La modification d'entité par l'éditeur** est testée (`47f6731`, `25b2945`), sans passe dédiée consignée.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **P-40 bloc 2 — cartes et forge** (2026-09-15, branche `fix/p40-bloc-2` **fusionnée par la
   PR #37**, 11 commits de code et de
   test, `b19b39a` → `9196a6e`) — une carte de classe porte 5 runes et non plus 10 ; trois
   légendaires ne fusionnent plus en une `unique`, et une carte ainsi abîmée redevient légendaire
   au chargement ; ni le draft de boss ni les deux Miroirs ne
   copient plus une carte de classe ; Persistant retire l'épuisement à tout tier et ne se fusionne
   plus. Trois causes plutôt que quatre symptômes : l'échelle de rareté devient `CardRarity.next` et
   `forgeSlotBonus` au lieu de l'ordre de l'enum, la règle d'acquisition `CardRarity.isAcquirable`,
   et une rune se déclare `stackable: false` en donnée, lue par un service unique, `ForgeRuneRules`
   ([ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md)). 811 tests,
   38 de plus ; la revue a vérifié que les tests de régression échouent sur l'ancien code.
2. **Éditeur de contenu — habillage « éditeur »** (2026-09-15, 14 commits, `78f342c` → `2c9ba6d`) —
   présentation seule, `lib/services/` intact. Onglets de type et segmenté Créer / Modifier
   remplacent les niveaux de l'arbre ; un explorateur groupe les entités par propriétaire en mode
   Modifier ; le formulaire devient en-tête de fichier et sections, la mécanique un inspecteur
   (grille de nombres, sous-panneaux numérotés) ; une barre d'actions fixe porte le bandeau d'issue,
   dont une faute ramène à son champ. **Toute couleur est un jeton nommé**, et **tout
   sélectionnable suit un contrat de choix** — fond opaque, 4,5:1, `selected`, indice hors couleur —
   porté par `ChoiceSurface` ([ADR-093](../_adr/ADR-093-habillage-editeur-jetons-nommes-et-contrat-de-choix.md)).
3. **Éditeur de contenu — formulaire inféré et ressources liées** (2026-09-14, 28 commits,
   `891351c` → `25b2945`) — l'état du formulaire devient un **document**, dont les champs sont
   inférés : plus de boîte JSON en modification, aucune clé du fichier perdue, et une saisie non
   convertible est une faute au lieu d'être remplacée en silence. Les gabarits n'écrivent plus de
   `sfx` vide, qui faisait rougir la suite à chaque création ; les types d'effet se valident contre
   l'usage du disque ; un son ou une image s'importe sous rollback, `audio.json` compris
   ([ADR-092](../_adr/ADR-092-formulaire-infere-du-document-et-ressources-liees.md), qui amende
   ADR-089). Au passage, Flame monte en 1.38.2 (`c155f50`).

> [!NOTE]
> **Rotations.** La livraison sortie en seconde rotation du 2026-09-15 (menu d'accueil et retours
> arrière) est conservée verbatim dans `../_archive/2026-09-15-activeContext-livraisons-2.md`. Les
> rotations précédentes :
> `../_archive/2026-09-15-activeContext-livraisons.md`,
> `../_archive/2026-09-14-activeContext-livraisons.md`,
> `../_archive/2026-09-05-activeContext-livraisons.md`,
> `../_archive/2026-09-01-activeContext-livraisons.md`,
> `../_archive/2026-08-25-activeContext-livraisons.md`,
> `../_archive/2026-08-23-activeContext-livraisons.md` et
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

**Exécuter le [plan du lot A de P-41](../../docs/superpowers/plans/2026-09-16-p41-lot-a-passage-unique-scission-migration.md)**,
Task 0 d'abord : la documentation se commite sur `main`, le code part sur `feat/p41-lot-a`. Lots,
chantier frère P-49 et ordre d'exécution : `docs/ROADMAP.md` §4, qui mène à la spec et à ses décisions
D1 à D8. Le filtre de classe des cartes de signature se traite avant ou avec P-42 — sa réserve
ci-dessus dit où et combien.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
