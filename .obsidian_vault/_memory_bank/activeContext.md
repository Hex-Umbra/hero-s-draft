<!-- last-sync: 2026-09-15 | commit: 5d62709 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-30, le menu de debug, est livré et fusionné dans `main`** : PR #36, merge `5d62709` du
2026-09-15, 124 commits de `feat/menu-debug-lot-2`, les deux derniers lots donnant à l'éditeur son
formulaire inféré puis son habillage. Deux outils, deux niveaux de conséquence : un **manipulateur
de run** en mémoire vive ([`_patterns/18-00`](../_patterns/18-00-menu-de-debug-run-declaree-et-tiroir-ancre.md)),
et un **éditeur de contenu** qui écrit dans `assets/data/` — moteur en
[`_patterns/19-00`](../_patterns/19-00-editeur-de-contenu-seam-disque-validation-ecriture.md), écran
en [`_patterns/19-5`](../_patterns/19-5-editeur-de-contenu-interface.md). Les ~25-30 cartes de P-42
peuvent désormais s'écrire depuis le jeu.

Réserves à ne pas perdre de vue :

- **Les changements visibles de la branche ont rejoint la note `0.5.1`** (`d8d9319`, décision du
  propriétaire le 2026-09-14) : bouton « Quitter », retours arrière, fin du badge « NEW »,
  illustration de classe. Rien sur le menu de debug ni l'éditeur, absents des builds publiés.
- **⚠️ Les lots 1-2 de P-48 cassent les sauvegardes antérieures, sur le passif seulement.** Ids
  de passifs en `snake_case` (commit `7da5db2`), clé `run_save_v1` et `schemaVersion: 1`
  inchangées : une partie d'avant se recharge **et perd son passif de classe**, signalé par un
  `MissingSaveItem`. La note de version est le seul canal qui prévienne *avant*.
- **La note `0.5.1` attend les cartes de P-42** (décision du propriétaire, 2026-09-05) et les
  accueillera en place, entrée rouverte. Le numéro se lit dans `pubspec.yaml` et la 1ʳᵉ entrée
  de `assets/data/patch_notes.json`, jamais ici.
- **Les cartes de signature fuient entre classes** en boutique et sur le bonus de boss —
  documenté, volontairement non corrigé pendant l'outillage :
  [filtre de classe](../../docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md).
  À traiter avant ou avec P-42.
- **La modification d'entité a reçu ses corrections** (commit `47f6731`) et chaque fichier livré
  en fait l'aller-retour en test (`25b2945`). La création est vérifiée à la main le 2026-09-14 ;
  le 2026-09-15, le propriétaire a vérifié à l'œil l'habillage et l'import de ressources. Aucune
  passe dédiée à la modification d'une entité existante n'est consignée.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Éditeur de contenu — habillage « éditeur »** (2026-09-15, 14 commits, `78f342c` → `2c9ba6d`) —
   présentation seule, `lib/services/` intact. Onglets de type et segmenté Créer / Modifier
   remplacent les niveaux de l'arbre ; un explorateur groupe les entités par propriétaire en mode
   Modifier ; le formulaire devient en-tête de fichier et sections, la mécanique un inspecteur
   (grille de nombres, sous-panneaux numérotés) ; une barre d'actions fixe porte le bandeau d'issue,
   dont une faute ramène à son champ. **Toute couleur est un jeton nommé**, et **tout
   sélectionnable suit un contrat de choix** — fond opaque, 4,5:1, `selected`, indice hors couleur —
   porté par `ChoiceSurface` ([ADR-093](../_adr/ADR-093-habillage-editeur-jetons-nommes-et-contrat-de-choix.md)).
2. **Éditeur de contenu — formulaire inféré et ressources liées** (2026-09-14, 28 commits,
   `891351c` → `25b2945`) — l'état du formulaire devient un **document**, dont les champs sont
   inférés : plus de boîte JSON en modification, aucune clé du fichier perdue, et une saisie non
   convertible est une faute au lieu d'être remplacée en silence. Les gabarits n'écrivent plus de
   `sfx` vide, qui faisait rougir la suite à chaque création ; les types d'effet se valident contre
   l'usage du disque ; un son ou une image s'importe sous rollback, `audio.json` compris
   ([ADR-092](../_adr/ADR-092-formulaire-infere-du-document-et-ressources-liees.md), qui amende
   ADR-089). Au passage, Flame monte en 1.38.2 (`c155f50`).
3. **Menu d'accueil et retours arrière** (2026-09-14, commits `97f1553`, `b47f2e3`, `ce60b39`) — menu joueur aligné à
   gauche, menu de debug dans sa colonne à droite, bouton **« Quitter »** qui passe par le moteur
   selon la plateforme (masqué sur web et iOS). Sélection de classe et draft de départ gagnent un
   retour, demandé pour le build Windows ; le draft post-boss, qui partage la mise en page, n'en
   reçoit délibérément pas. Le badge « NEW » du tutoriel part, et avec lui
   `TutorialProgressService`, dont il était le seul lecteur. Même passe : `systemPatterns.md`
   passe à **150 lignes** de plafond et perd ses en-têtes de sections à fiche unique, arbitrage
   du propriétaire en attente depuis le 2026-09-05. Dernier geste : plus aucun écran ne code
   l'identité de classe en dur ([ADR-090](../_adr/ADR-090-identite-visuelle-de-classe-portee-par-la-donnee.md) D14).

> [!NOTE]
> **Rotations.** Les deux livraisons sorties au 2026-09-15 (éditeur de contenu lot 2 et création
> guidée, menu de debug lot 1) sont conservées verbatim dans
> `../_archive/2026-09-15-activeContext-livraisons.md`. Les rotations précédentes :
> `../_archive/2026-09-14-activeContext-livraisons.md`,
> `../_archive/2026-09-05-activeContext-livraisons.md`,
> `../_archive/2026-09-01-activeContext-livraisons.md`,
> `../_archive/2026-08-25-activeContext-livraisons.md`,
> `../_archive/2026-08-23-activeContext-livraisons.md` et
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

**Reprendre le programme « Identité de classe & catalogue »** : P-40 blocs 2 et 3 (trois bugs de
gameplay, ~0,75-1 j) referment le lot S1 avant P-41 et P-42 — et P-42 peut désormais passer par
l'éditeur. Ces bugs ont été relevés le 2026-08-05 : les re-vérifier contre le code avant d'ouvrir le
chantier (`docs/ROADMAP.md` §10.4). Le filtre de classe des cartes de signature se traite avant ou
avec P-42.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
