<!-- last-sync: 2026-09-05 | commit: ac37596 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 120 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La couche de données est refaite.** P-48 est livré : les 8 catalogues JSON monolithiques
sont éclatés en **71 fichiers d'entité**, et le répertoire fait autorité sur l'appartenance —
une carte rangée dans `classes/paladin/cards/` *est* une carte du paladin, un JSON qui
prétendrait le contraire échoue au chargement. **Ajouter du contenu ne demande plus de code** :
un fichier au bon endroit suffit. Voir [ADR-085](../_adr/ADR-085-regle-de-partage-catalogue-configuration.md),
[ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md) et
[`_patterns/17-00`](../_patterns/17-00-chargeur-de-donnees-generique-et-motifs-de-che.md).

Deux chantiers en sont débloqués : le **devtool d'édition de contenu**, demande d'origine de
ce chantier, et **P-42** et ses ~25-30 cartes de classe, qui s'écrivent désormais un fichier
à la fois sans doubler le travail de relecture.

Cinq réserves à ne pas perdre de vue :

- **La note de version couvrant P-48 et P-40 bloc 1 est écrite** (« Chaque Chose à Sa Place »,
  le 2026-09-05) : un PATCH, les deux chantiers étant sans effet visible et seul le
  réordonnancement d'affichage des lots 1-2 se voyant. **Elle n'est pas encore taguée** — la
  publication reste à faire. Le numéro se lit dans `pubspec.yaml` et la 1ʳᵉ entrée de
  `assets/data/patch_notes.json`, jamais ici.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04). Les traiter comme non vérifiés. Inchangé
  depuis le 2026-08-06.
- **Le webhook Discord a transité en clair** pendant la conception du 19/08 et n'a pas été
  régénéré depuis.
- **Bouton de téléchargement mort** : si le build Windows échoue quand le build web
  réussit, le site affiche un lien vers un asset absent. Correctif identifié, non fait —
  voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).
- **`patch-notes-writer` ne rafraîchit que les `href` de repli, pas les libellés visibles**
  qui citent la version en toutes lettres — cause vivante dans le skill, non corrigée.
  Contournée à la main aux **deux** dernières publications (2026-08-23 puis 2026-08-28) :
  `site/index.html` porte le numéro en clair dans sa carte de version et doit être repris
  à chaque fois. Le contournement répété est le symptôme, pas le remède.

## 3 dernières livraisons

1. **Réorganisation des données, lot 3 — la migration** (2026-09-05, PR #35, 30 commits) —
   les catalogues deviennent **71 fichiers d'entité**, lus par un chargeur générique piloté
   par des **motifs de chemin** : `*` vaut un segment, et le comptage de segments sépare
   `classes/*/class.json` de `classes/*/cards/*.json` sans aucune expression régulière. Les
   fautes s'accumulent et lèvent en une fois. Le risque du chantier — une perte silencieuse
   d'entité ou de champ — a été traité par un **oracle comparant le JSON brut** avant/après,
   prouvé mordant par trois mutations, puis **refait depuis zéro par la revue de branche** :
   71/71 entités, 0 champ perdu, 8/8 images MD5-identiques. Une run sauvegardée sur `main` se
   recharge intacte : tout y est référencé par `id`. **53 ms** de démarrage en profile pour 72
   lectures de bundle, contre un seuil d'alerte à 200 ms.
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
   [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md) ; les deux
   fiches du vault qui le décrivaient sont archivées.
   ⚠️ **`applyLifestealBuff` est désormais sans appelant**, conservée sur avertissement
   explicite pour P-41. **P-26 perd un tiers de son périmètre.**

> [!NOTE]
> **Rotations.** Les trois livraisons sorties au 2026-09-05 (chemin de lecture audio, P-03,
> P-45) sont conservées verbatim dans
> `../_archive/2026-09-05-activeContext-livraisons.md`. Les rotations précédentes sont dans
> `../_archive/2026-09-01-activeContext-livraisons.md`,
> `../_archive/2026-08-25-activeContext-livraisons.md`,
> `../_archive/2026-08-23-activeContext-livraisons.md` et
> `../_archive/2026-08-20-activeContext-livraisons.md`.

## Prochaine étape

**Publier la note écrite** — poser le tag, ce qui déclenche `release.yml` — puis reprendre le
programme « Identité de classe & catalogue ». Le chemin le plus court est **P-40 blocs 2 et 3** — trois
bugs de gameplay confirmés et dix dérives documentaires, ~0,75-1 j restant — qui referme le
lot S1 avant d'ouvrir P-41 et P-42. **Le devtool d'édition de contenu** est débloqué et sans
spec : il ne bloque personne, mais c'est lui qui justifiait la réorganisation.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste par ailleurs ouvert : P-06 (lot P0
animations), P-07, le prototype de P-08, P-05. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de
toucher aux animations** : la frappe d'impact y est déjà posée, et `spawnImpactParticles`
l'attend, déclarée et jamais appelée.
