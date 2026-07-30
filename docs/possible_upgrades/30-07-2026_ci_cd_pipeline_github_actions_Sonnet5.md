# CI/CD Pipeline (GitHub Actions) — Hero's Draft

**Date** : 30/07/2026
**Contexte** : Premier document de la catégorie infrastructure/outillage — jusqu'ici tous les brainstorms archivés dans ce dossier portaient sur du contenu gameplay. Le projet n'a aujourd'hui **aucune CI/CD** : vérifié qu'il n'existe ni `.github/workflows/`, ni mention de CI/CD dans `docs/`, `.obsidian_vault/_memory_bank/`, ni brainstorm antérieur sur le sujet.
**Statut** : Brainstorm validé par échange (architecture complète en 5 sections : cadrage, architecture, jobs/data flow, gestion d'erreurs, tests) — **rien encore implémenté**. Volontairement **pas** poussé jusqu'à une spec d'implémentation (`docs/superpowers/specs/`) à ce stade — ce document capture la recherche et les décisions, à faire passer par le processus standard (spec → plan TDD) le jour où l'implémentation démarre.
**Déclencheur** : deux workflows manuels chronophages identifiés par l'utilisateur — build web déployé à la main sur un VPS perso, et build Windows zippé/partagé à la main via Google Drive pour des amis testeurs.

---

## 0. Pourquoi un CI/CD ici, et pourquoi pas tout de suite en full CD

Rappel des fondamentaux discutés avant le brainstorm proprement dit :

- **CI** (intégration continue : analyse statique + tests automatisés sur chaque push/PR) a un ratio valeur/coût élevé même pour un projet solo — elle applique automatiquement des règles déjà écrites dans `CLAUDE.md` (`dart analyze` doit être clean) au lieu de compter sur la discipline manuelle, et devient plus précieuse à mesure que du contenu est généré par des sub-agents (patch notes, brainstorms) qui réduisent la relecture ligne à ligne.
- **CD** (déploiement continu : build multi-cibles, signature, publication) est un investissement plus lourd (secrets, destination de déploiement, gestion de version) qui ne se justifie que si un canal de distribution réel existe déjà.

Ici, les deux canaux de distribution **existent déjà** et sont opérés manuellement : le site web (`heros-draft.vilarserver.com`, hébergé sur un VPS perso) et les builds Windows partagés à des amis testeurs. Le CI/CD ne crée donc pas un besoin artificiel — il automatise un processus manuel déjà en place, ce qui change le calcul de rentabilité : pas de coût d'amorçage "canal de distribution à créer", seulement le coût d'automatisation d'un canal existant.

---

## 1. Portée et décisions de cadrage

Décisions prises question par question pendant le brainstorm :

| Sujet | Décision | Raison |
|---|---|---|
| **Déclencheur build/déploiement/release** | Tag de version (`vX.Y.Z`) | Contrôle total sur le moment où une version "sort", séparé du rythme des commits |
| **Garde-fou qualité continu** | `dart analyze` + `flutter test` sur **chaque push/PR** vers `main`, indépendamment des releases | Applique automatiquement la règle déjà existante dans `CLAUDE.md`, attrape les régressions avant qu'elles n'atteignent un tag |
| **Dépôt des fichiers sur le VPS** | SSH/rsync avec une paire de clés dédiée au CI (pas les identifiants perso) | Révocable indépendamment du compte personnel, standard |
| **Conservation des anciens builds web** | Un dossier par version (`/vX.Y.Z/`) + lien symbolique `latest` mis à jour à chaque déploiement | Les anciennes versions restent accessibles (`/v0.4.6/`), la racine du site sert toujours la dernière |
| **Notification Discord** | Webhook à créer (n'existe pas encore), message incluant le **contenu des patch notes** (pas juste un lien) | Patch notes déjà rédigées en français par le sub-agent `patch_notes_writer` — autant les réutiliser directement |
| **Source de vérité de version** | Le tag git ; le pipeline **vérifie** que `pubspec.yaml` correspond et échoue sinon (pas de bump automatique par le pipeline) | Le pipeline ne doit pas écrire dans le repo à l'insu de l'utilisateur ; erreur explicite plutôt que magie |
| **Cibles de build** | Web + Windows uniquement (pas Android/iOS/macOS/Linux) | Ce sont les deux seuls canaux de distribution réels aujourd'hui ; extensible plus tard sans redesign |
| **Type de release GitHub** | Marquée **pre-release** | Signale clairement aux testeurs que ce n'est pas une sortie stable officielle |

**Point découvert pendant le brainstorm, à traiter avant toute implémentation** : `pubspec.yaml` est resté à `version: 0.1.0+1` alors que `patch_notes.json` en est déjà à la version `0.4.7`. Comme le tag doit désormais correspondre à `pubspec.yaml`, il faut resynchroniser manuellement `pubspec.yaml` (ex. `0.4.7+1`) avant de poser le premier tag — sans quoi le garde-fou `verify-version` (section 3) échouera systématiquement.

---

## 2. Architecture — deux workflows

Trois options comparées :

- **A — Deux workflows séparés** (retenue) : `ci.yml` (push/PR → analyze + test) et `release.yml` (tag → build, déploiement, release, Discord). Sépare clairement deux cycles de vie différents.
- **B — Un seul workflow avec jobs conditionnels** (rejetée) : mélange les deux logiques dans un seul YAML, plus dur à maintenir sans risque de casser l'une en modifiant l'autre.
- **C — Trois workflows, notification Discord en workflow réutilisable** (rejetée) : sur-ingénierie tant qu'il n'y a qu'un seul point d'usage du webhook (YAGNI).

### `ci.yml`
**Déclencheur** : push sur `main`, PR vers `main`.
**Job `quality`** : checkout → setup Flutter (version pinnée) → `flutter pub get` → `dart analyze` (0 issue) → `flutter test`. Aucun build ni déploiement.

### `release.yml`
**Déclencheur** : push d'un tag `v*.*.*`.

```
                    ┌──────────────────┐
                    │  verify-version   │  tag == pubspec.yaml version
                    │                   │  + une entrée existe dans
                    │                   │    patch_notes.json pour ce tag
                    └─────────┬─────────┘
                    (échoue → pipeline stoppé net, rien n'est buildé)
                              │
              ┌───────────────┴───────────────┐
              ▼                                 ▼
      ┌───────────────┐                ┌────────────────┐
      │   build-web    │                │  build-windows  │
      │ flutter build  │                │ flutter build   │
      │ web --release  │                │ windows --release│
      └───────┬────────┘                └────────┬────────┘
              ▼                                    ▼
      ┌───────────────┐                ┌────────────────────┐
      │  deploy-web    │                │  release-windows    │
      │ rsync → VPS    │                │ gh release (softprops│
      │ /vX.Y.Z/       │                │ /action-gh-release) │
      │ + symlink      │                │ pre-release + zip   │
      │   "latest"     │                │ + patch notes body  │
      └───────┬────────┘                └──────────┬──────────┘
              └───────────────┬────────────────────┘
                               ▼
                     ┌──────────────────┐
                     │  notify-discord   │
                     │ webhook → channel │
                     │ version + patch   │
                     │ notes + 2 liens   │
                     └──────────────────┘
```

`build-web` et `build-windows` sont **indépendants** l'un de l'autre (tous deux dépendent seulement de `verify-version`) : l'échec de l'un n'empêche pas l'autre de continuer sa propre chaîne jusqu'au bout.

---

## 3. Détail des jobs

**`verify-version`** *(ubuntu-latest)*
Extrait la version du tag (`v0.4.7` → `0.4.7`) → compare à `pubspec.yaml` (échoue si différent) → vérifie via `jq` que `patch_notes.json[0].version` correspond (échoue sinon, avec message explicite). Expose `version` en output pour tous les jobs suivants.

**`build-web`** *(ubuntu-latest, needs: verify-version)*
`subosito/flutter-action` (version Flutter **pinnée**, identique à `ci.yml`) → `flutter pub get` → `flutter build web --release` → upload artefact `web-build`.

**`build-windows`** *(windows-latest, needs: verify-version)*
Même setup Flutter pinné → `flutter build windows --release` → `Compress-Archive` du dossier `build/windows/x64/runner/Release/` en `heros-draft-v${version}-windows.zip` → upload artefact `windows-build`.

**`deploy-web`** *(ubuntu-latest, needs: build-web)*
Télécharge `web-build` → agent SSH avec `VPS_SSH_KEY` → `rsync -avz --delete` vers `${VPS_WEB_ROOT}/v${version}/` → bascule le symlink `latest` **de façon atomique** (`ln -sfn` sur un nom temporaire puis `mv -Tf`), et seulement **après** un rsync complet et réussi — aucun visiteur ne peut jamais voir un déploiement à moitié fait.

**`release-windows`** *(ubuntu-latest, needs: build-windows)*
Télécharge `windows-build` → extrait via `jq` les sections de `patch_notes.json[0]` (catégories + emoji + entrées), formatées en markdown → publie via `softprops/action-gh-release` (choisi pour son **idempotence** : met à jour la release existante plutôt que d'échouer si le tag en a déjà une, donc un re-run après échec transitoire ne demande aucun nettoyage manuel) avec `prerelease: true`.

**`notify-discord`** *(ubuntu-latest, needs: [deploy-web, release-windows])*
Reconstruit le markdown des patch notes → payload webhook Discord (titre version, patch notes, lien site `latest`, lien release GitHub) → `curl -X POST` vers `DISCORD_WEBHOOK_URL`. Ne se déclenche que si **les deux** jobs parents réussissent.

### Secrets requis (GitHub repo secrets)
- `VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER` — accès SSH dédié
- `DISCORD_WEBHOOK_URL`
- `GITHUB_TOKEN` — fourni automatiquement par Actions

---

## 4. Gestion des erreurs

- **`verify-version` échoue** → arrêt net, aucun build/déploiement/publication. Corriger (pubspec, patch_notes.json ou le tag) et repousser.
- **Build web/Windows indépendants** → un échec de compilation sur une cible ne bloque pas l'autre.
- **Échec `deploy-web`** (VPS down, réseau) → l'ancienne version reste servie, car le symlink `latest` n'est jamais basculé avant la fin d'un rsync réussi.
- **`release-windows` idempotent** (`softprops/action-gh-release`) → un re-run après échec transitoire ne casse rien.
- **Compromis assumé pour cette v1** : `notify-discord` ne se déclenche que si `deploy-web` **et** `release-windows` réussissent tous les deux. Un succès partiel (ex. site à jour mais release Windows en échec) ne génère **aucune** notification — visible seulement dans l'onglet Actions. Amélioration future possible mais non nécessaire au départ.
- **Recovery** : "Re-run failed jobs" est sûr sur tous les jobs de ce pipeline (aucun effet de bord destructeur, hors le cas d'un tag lui-même erroné, qui demande une suppression/repoussée manuelle).

---

## 5. Tests / validation

- **`ci.yml`** : testable immédiatement et sans risque (aucun effet de bord), dès le premier push/PR.
- **`release.yml`** : effets de bord réels (VPS de prod, release publique, message Discord) — pas de bac à sable évident. Deux mesures retenues :
  1. Ajouter aussi un déclencheur `workflow_dispatch` sur `release.yml`, pour pouvoir relancer un run ciblé sans repousser de tag.
  2. **Le premier tag réel (`v0.4.7`, patch notes déjà prêtes) sert directement de test d'intégration** — pas besoin de version factice, grâce aux propriétés de sécurité ci-dessus (symlink atomique, jobs indépendants, release idempotente) un échec partiel reste sans danger.
- Avant ce premier run : valider une fois manuellement (depuis la machine de l'utilisateur) que la clé SSH dédiée fonctionne vers le VPS, pour éliminer la variable la plus fragile (secret mal copié) avant d'en dépendre dans le pipeline.

---

## 6. Prérequis manuels (hors pipeline)

Trois changements ponctuels à faire **avant** le premier tag, aucun n'est automatisé par les workflows eux-mêmes :

1. **`pubspec.yaml`** : resynchroniser la version (actuellement `0.1.0+1`) sur celle de `patch_notes.json` (`0.4.7` au moment de ce brainstorm), sans quoi `verify-version` échoue systématiquement.
2. **VPS — clé SSH dédiée** : générer une paire de clés spécifique au CI, ajouter la clé publique à `authorized_keys` sur le VPS, stocker la clé privée dans les secrets GitHub Actions.
3. **VPS — configuration nginx** : la racine du site doit pointer sur `${VPS_WEB_ROOT}/latest` (le symlink) plutôt que sur un dossier fixe, pour que le mécanisme de bascule atomique (section 3, `deploy-web`) fonctionne. C'est une modification de configuration nginx à faire une fois, manuellement, sur le VPS — le pipeline ne la fait pas à sa place.
4. **Discord** : créer le webhook sur le channel cible du serveur (Paramètres du channel → Intégrations → Webhooks), récupérer l'URL, la stocker comme secret `DISCORD_WEBHOOK_URL`.

---

## 7. Effort & risque

- **Code : petit-moyen.** Deux fichiers YAML (`ci.yml`, `release.yml`), 7 jobs au total, en s'appuyant sur des actions tierces bien maintenues (`subosito/flutter-action`, `softprops/action-gh-release`, `webfactory/ssh-agent` ou équivalent) plutôt que des scripts maison partout où c'est possible.
- **Configuration : petite mais avec dépendances externes.** 4 secrets GitHub à créer, 1 clé SSH à générer, 1 modification nginx sur le VPS, 1 webhook Discord à créer — tout un travail ponctuel, hors code, à faire une seule fois.
- **Risque principal** : la fragilité est concentrée sur la configuration externe (secrets mal copiés, permissions VPS, symlink nginx mal branché) plutôt que sur la logique du pipeline elle-même, qui a été conçue pour rester sûre en cas d'échec partiel (section 4).

---

## 8. Prochaines étapes possibles

1. Resynchroniser `pubspec.yaml` sur la version de `patch_notes.json` (section 6, point 1) — préalable bloquant à toute implémentation.
2. Réaliser les 3 autres prérequis manuels (clé SSH, nginx, webhook Discord — section 6) avant d'écrire le moindre YAML.
3. Le moment venu, faire passer ce document par le processus standard : spec d'implémentation dédiée (`docs/superpowers/specs/`) pour figer les derniers détails (noms exacts des actions tierces, format précis du payload Discord, script `jq` d'extraction des patch notes), puis un plan d'implémentation.
4. Premier tag réel (`v0.4.7`) une fois le pipeline implémenté : sert de test d'intégration end-to-end (section 5).
5. Extension future possible, non traitée ici : notification Discord sur succès partiel (section 4), autres cibles de build (Android/iOS/macOS/Linux, section 1).
