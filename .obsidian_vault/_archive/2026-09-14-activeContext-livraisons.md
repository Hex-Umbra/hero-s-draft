# Archive — livraisons sorties de `activeContext.md` le 2026-09-14

Rotation FIFO. Trois livraisons **P-30 lot 1** (menu de debug), **P-30 lot 2 et création guidée**
(éditeur de contenu) et **menu d'accueil** entrent dans `activeContext.md` ; les trois ci-dessous
en sortent, conservées **verbatim**.

> [!WARNING]
> Lecture seule. Ces textes décrivent l'état du projet à la date où ils ont été écrits.

---

1. **Réorganisation des données, lot 3 — la migration** (2026-09-05, PR #35, 30 commits) —
   les catalogues deviennent **71 fichiers d'entité**, lus par un chargeur générique piloté
   par des **motifs de chemin** : `*` vaut un segment, et le comptage de segments sépare
   `classes/*/class.json` de `classes/*/cards/*.json` sans aucune expression régulière. Les
   fautes s'accumulent et lèvent en une fois. Le risque du chantier — une perte silencieuse
   d'entité ou de champ — a été traité par un **oracle comparant le JSON brut** avant/après,
   prouvé mordant par trois mutations, puis **refait depuis zéro par la revue de branche** :
   71/71 entités, 0 champ perdu, **7/7** images déplacées MD5-identiques (la 8ᵉ,
   `bg_dungeon.png`, n'a jamais bougé — c'est le 8 des clés du cache Flame, pas celui de la
   migration). **Ce lot seul** ne casse aucune sauvegarde : rien n'y change d'`id`. Coût de démarrage mesuré :
   voir `progress.md` §Architecture des Données.
   ⚠️ **Le préfixe d'images de Flame doit rester vide** — il ne fait pas partie des clés du
   cache, et un préfixe par dossier ferait s'écraser les trois `icon.png` de classes.
2. **Réorganisation des données, lots 1-2 — la préparation** (2026-09-04, PR #34) — quatre
   replis codés en dur supprimés, dont un second chargeur de JSON dans la couche Flame et des
   chemins d'images en dur ; `GameDataRegistry.imagesToPreload` devient l'unique source de la
   liste de préchargement. Tout **ordre d'affichage devient explicite** : le dictionnaire, le
   pool de draft de départ et la sélection de classe ne dépendent plus de l'ordre du
   catalogue — `AssetManifest.listAssets()` n'offrant aucune garantie d'ordre, le lot 3 aurait
   sinon changé l'affichage sans que rien ne le signale. Ids de passifs passés en
   `snake_case`, `PassiveData.fallback` supprimé.
3. **Suppression de la chaîne de compétences héroïques — P-40 bloc 1** (2026-09-04, commit
   `ced306e`) — un système présent depuis les premières versions, **sans aucun point
   d'entrée** : personne n'appelait `executeSkill`, aucun bouton n'existait, et les 6 entrées
   de `skills.json` ne correspondaient à aucun identifiant réel. **−544 lignes** sur 34
   fichiers, sans migration de sauvegarde — les trois lignes de `save_service.dart` partent
   ensemble, une sauvegarde existante garde une clé jamais relue. Voir
   [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md). **Une
   quinzaine de fiches du vault le décrivaient** : deux archivées, les autres corrigées sur
   place. Le décompte exact a été faux quatre fois de suite — l'ADR porte désormais un
   invariant `grep` à relancer, pas un nombre.
   ⚠️ **La façade `RunController.applyLifestealBuff` est sans appelant**, conservée sur
   avertissement explicite pour P-41. **P-26 perd un tiers de son périmètre.**
