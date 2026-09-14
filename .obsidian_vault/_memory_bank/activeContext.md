<!-- last-sync: 2026-09-14 | commit: d8d9319 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**P-30, le menu de debug, est livré sur la branche `feat/menu-debug-lot-2`**, pas encore
fusionnée : 76 commits depuis `main`, dont les cinq derniers — lisibilité de l'éditeur
(`9b3ce82`), menu d'accueil (`97f1553`), suppression de `TutorialProgressService` (`b47f2e3`),
identité de classe (`ce60b39`) et note de version (`d8d9319`) — ont été découpés en lots le
2026-09-14. Deux outils, deux niveaux de conséquence : un **manipulateur de run**
en mémoire vive ([`_patterns/18-00`](../_patterns/18-00-menu-de-debug-run-declaree-et-tiroir-ancre.md)),
et un **éditeur de contenu** qui écrit dans `assets/data/`
([`_patterns/19-00`](../_patterns/19-00-editeur-de-contenu-seam-disque-validation-ecriture.md)).
C'est ce que la réorganisation des données de P-48 devait débloquer : les ~25-30 cartes de P-42
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
- **Une vérification manuelle due** : le geste réellement suffisant après une écriture de
  l'éditeur (le message reste conservateur). L'absence du menu de debug en build release a été
  vérifiée par le propriétaire le 2026-09-14.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Le webhook Discord a transité en clair** le 19/08 et n'a pas été régénéré depuis.
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Menu d'accueil et retours arrière** (2026-09-14, commits `97f1553`, `b47f2e3`, `ce60b39`) — menu joueur aligné à
   gauche, menu de debug dans sa colonne à droite, bouton **« Quitter »** qui passe par le moteur
   selon la plateforme (masqué sur web et iOS). Sélection de classe et draft de départ gagnent un
   retour, demandé pour le build Windows ; le draft post-boss, qui partage la mise en page, n'en
   reçoit délibérément pas. Le badge « NEW » du tutoriel part, et avec lui
   `TutorialProgressService`, dont il était le seul lecteur. Même passe : `systemPatterns.md`
   passe à **150 lignes** de plafond et perd ses en-têtes de sections à fiche unique, arbitrage
   du propriétaire en attente depuis le 2026-09-05. Dernier geste : plus aucun écran ne code
   l'identité de classe en dur ([ADR-090](../_adr/ADR-090-identite-visuelle-de-classe-portee-par-la-donnee.md) D14).
2. **Éditeur de contenu — lot 2 et création guidée** (2026-09-06 → 2026-09-09, 51 commits) —
   créer ou modifier une entité des 7 catégories, une classe entière et ses cartes en un geste.
   `dart:io` isolé derrière un seam (le jeu a un build web), racine déduite de l'exécutable,
   **9 contrôles avant toute écriture**, écriture transactionnelle avec rollback et
   `sync_assets` en fin de geste. Le risque — un fichier invalide casse **toute** sa catégorie —
   est tenu par la règle « Valider juge ce qu'Écrire écrira »
   ([ADR-089](../_adr/ADR-089-editeur-de-contenu-seam-disque-et-validation-totale.md)). Au
   passage, `iconPath` devient `classCard` et la classe gagne `themeColor`.
   ⚠️ Le rollback ne défait ni dossiers ni images placeholder.
3. **Menu de debug — lot 1, manipulateur de run** (2026-09-05 → 2026-09-06) — un tiroir ancré au
   bord gauche de la carte et du combat, jamais un dialogue. La première conception ne gardait que
   l'écriture : **tester une mort effaçait la vraie sauvegarde**. Le mode est désormais déclaré au
   lancement et le verrou vit dans `SaveService`
   ([ADR-087](../_adr/ADR-087-run-debug-declaree-au-lancement-et-verrou-de-persis.md)). Bug
   antérieur au menu corrigé en route : le combat sortait par le sommet de pile et laissait le
   joueur coincé sur un nœud résolu
   ([ADR-088](../_adr/ADR-088-tiroir-de-debug-ancre-et-sortie-de-combat-par-sa-pr.md)) — sans
   test automatisé, `GameScreen` exigeant Flame.

> [!NOTE]
> **Rotations.** Les trois livraisons sorties au 2026-09-14 (P-48 lot 3, P-48 lots 1-2, P-40
> bloc 1) sont conservées verbatim dans `../_archive/2026-09-14-activeContext-livraisons.md`.
> Les rotations précédentes : `../_archive/2026-09-05-activeContext-livraisons.md`,
> `../_archive/2026-09-01-activeContext-livraisons.md`,
> `../_archive/2026-08-25-activeContext-livraisons.md`,
> `../_archive/2026-08-23-activeContext-livraisons.md` et
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

**Fusionner la branche** — le travail est commité et la note de version complétée — puis établir
le geste suffisant après une écriture de l'éditeur. **Ensuite, reprendre le programme « Identité de classe &
catalogue »** : P-40 blocs 2 et 3 (trois bugs de gameplay confirmés, ~0,75-1 j) referment le
lot S1 avant P-41 et P-42 — et P-42 peut désormais passer par l'éditeur.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05. **P-07 doit lire [ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md)
D6 avant de toucher aux animations.**
