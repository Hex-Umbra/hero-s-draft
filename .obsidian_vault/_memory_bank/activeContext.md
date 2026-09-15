<!-- last-sync: 2026-09-15 | commit: 5792b77 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-40 bloc 2 est livré sur la branche `fix/p40-bloc-2`, pas encore fusionnée** : les trois bugs de
cartes et de forge relevés le 2026-08-05, re-vérifiés contre le code, sont corrigés à leur cause —
[ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md). Une revue
indépendante a rendu « prête à fusionner après corrections », corrections faites dans la branche. Le
**bloc 3**, les dérives documentaires, est traité dans la même passe : P-40 n'a plus que son bloc 4,
une décision.

Réserves à ne pas perdre de vue :

- **Quatre décisions du propriétaire attendent** : fusionner la branche (PR, comme la #36) ; porter
  ses changements visibles dans la note `0.5.1`, dont les cartes de classe passées de 10 à 5 runes ;
  réparer au chargement une carte neutre devenue `unique` par l'ancienne fusion de légendaires
  (spec du bloc 2, §5) ; le sort du corpus `docs/formation-heros-draft/` (bloc 4).
- **Un dossier de classe `gambler` vide**, laissé par une écriture de l'éditeur, faisait rougir deux
  tests sur `main`. Supprimé le 2026-09-15 ; `entity_writer.dart` tient ce cas pour « sans conséquence ».
- **Les changements visibles de P-30 ont rejoint la note `0.5.1`** (`d8d9319`, décision du
  propriétaire le 2026-09-14) : bouton « Quitter », retours arrière, fin du badge « NEW »,
  illustration de classe. Rien sur le menu de debug ni l'éditeur, absents des builds publiés.
- **⚠️ Les lots 1-2 de P-48 cassent les sauvegardes antérieures, sur le passif seulement.** Ids
  de passifs en `snake_case` (commit `7da5db2`), clé `run_save_v1` et `schemaVersion: 1`
  inchangées : une partie d'avant se recharge **et perd son passif de classe**, signalé par un
  `MissingSaveItem`. La note de version est le seul canal qui prévienne *avant*.
- **La note `0.5.1` attend les cartes de P-42** (décision du propriétaire, 2026-09-05) et les
  accueillera en place, entrée rouverte. Le numéro se lit dans `pubspec.yaml` et la 1ʳᵉ entrée
  de `assets/data/patch_notes.json`, jamais ici.
- **Les cartes de signature non `unique` fuient entre classes** en boutique et sur le bonus de boss —
  [filtre de classe](../../docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md), à
  joindre à `CardRarity.isAcquirable`, avant ou avec P-42.
- **La modification d'entité par l'éditeur** est testée (`47f6731`, `25b2945`), sans passe dédiée consignée.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **P-40 bloc 2 — cartes et forge** (2026-09-15, branche `fix/p40-bloc-2`, 11 commits de code et de
   test, `b19b39a` → `9196a6e`) — une carte de classe porte 5 runes et non plus 10 ; trois
   légendaires ne fusionnent plus en une `unique` ; ni le draft de boss ni les deux Miroirs ne
   copient plus une carte de classe ; Persistant retire l'épuisement à tout tier et ne se fusionne
   plus. Trois causes plutôt que quatre symptômes : l'échelle de rareté devient `CardRarity.next` et
   `forgeSlotBonus` au lieu de l'ordre de l'enum, la règle d'acquisition `CardRarity.isAcquirable`,
   et une rune se déclare `stackable: false` en donnée, lue par un service unique, `ForgeRuneRules`
   ([ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md)). 809 tests,
   36 de plus ; la revue a vérifié que les tests de régression échouent sur l'ancien code.
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

**Trancher les quatre décisions ci-dessus**, puis reprendre le programme « Identité de classe &
catalogue » par **P-41**, dont la spec est prête ; P-42 peut ensuite passer par l'éditeur. Le filtre
de classe des cartes de signature se traite avant ou avec P-42.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
