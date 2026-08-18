# Spec d'implémentation — P-04 · CI/CD GitHub Actions

**Date** : 17/08/2026
**Chantier roadmap** : [P-04](../../ROADMAP.md) — Jalon 1 « Socle »
**Brainstorm source** : [30-07-2026_ci_cd_pipeline_github_actions_Sonnet5.md](../../possible_upgrades/30-07-2026_ci_cd_pipeline_github_actions_Sonnet5.md)
**Statut** : spec validée, prête pour plan d'implémentation — **rien encore implémenté**

> [!IMPORTANT]
> Cette spec **remplace** le brainstorm du 30/07 sur tous les points où ils divergent. Le brainstorm reste la référence pour le *raisonnement* (pourquoi un CI/CD, pourquoi deux workflows) ; cette spec est la référence pour l'*exécution*. La section 9 liste les écarts et leurs causes.

---

## 1. Périmètre

### Dans le périmètre (v1)

| Livrable | Contenu |
|:---|:---|
| `.github/workflows/ci.yml` | 1 job — `dart analyze` + `flutter test` sur chaque push/PR vers `main` |
| `.github/workflows/release.yml` | 5 jobs — vérification de version, build web + Windows, déploiement VPS, release GitHub |

**6 jobs au total, 2 fichiers.**

### Hors périmètre (reporté)

- **`notify-discord`** — reporté *après* la mise en service complète du CI/CD (décision du 17/08). Supprime le webhook des prérequis et le secret `DISCORD_WEBHOOK_URL`. Le corps de release GitHub contient déjà les patch notes formatées, donc le travail d'extraction `jq` (§5.5) est fait et réutilisable tel quel le jour où le job Discord arrive.
- **Autres cibles de build** — Android, iOS, macOS, Linux. Les dossiers `android/` et `ios/` existent mais ne correspondent à aucun canal de distribution réel.
- **Notification sur succès partiel** — voir §7.
- **Génération automatique de la page de sélection de versions** — la racine du site reste éditée à la main (§3.2).

---

## 2. Décisions verrouillées

| Sujet | Décision |
|:---|:---|
| Déclencheur release | Tag `vX.Y.Z` uniquement (+ `workflow_dispatch` sur un tag, pour les re-runs) |
| Garde-fou continu | `dart analyze --fatal-infos` + `flutter test` sur chaque push/PR vers `main` |
| Source de vérité de version | Le **tag git**. Le pipeline *vérifie* et *échoue* — il n'écrit **jamais** dans le repo |
| Cibles de build | Web + Windows |
| URL web | Un dossier par version : `https://heros-draft.vilarserver.com/vX.Y.Z/` |
| Pas de `latest` | Aucun symlink, aucune modification nginx (§3.2) |
| Release GitHub | `prerelease: true`, corps = patch notes formatées, asset = zip Windows |
| Version Flutter | **3.41.6** stable (Dart 3.11.4) — pinnée à l'identique dans les deux workflows |
| Actions tierces | Pinnées au **SHA de commit complet**, jamais au tag (§6.3) |

---

## 3. État vérifié du terrain (17/08/2026)

### 3.1 Prérequis déjà satisfaits

| Vérification | Résultat |
|:---|:---|
| `.github/` | Absent — rien à migrer |
| `pubspec.yaml` vs `patch_notes.json` | `0.4.7+1` vs `0.4.7` → **alignés** (P-01 clos) |
| `dart analyze` | `No issues found!` → `--fatal-infos` est gratuit dès aujourd'hui |
| `flutter test` | **230 tests / 42 fichiers, tous verts** en ~24 s |
| Visibilité du repo | **Public** → minutes Actions gratuites (y compris `windows-latest`), releases téléchargeables par les testeurs sans compte |
| Tags existants | **Aucun** — le déclencheur `v*.*.*` est terrain vierge |

### 3.2 nginx — aucune modification requise

La config existante de `heros-draft.vilarserver.com` couvre déjà le besoin :

```nginx
root /var/www/prototypes;

location / {                              # BLOC 1 — page de sélection de versions
    try_files $uri $uri/ =404;
}
location ~ ^/(v[0-9][^/]*) {              # BLOC 2 — déjà exactement ce qu'il faut
    try_files $uri $uri/ /$1/index.html;
}
```

Le **BLOC 2** capture tout dossier `v` + chiffre et fournit le fallback SPA. `/v0.4.7/` fonctionnera au premier déploiement sans toucher à nginx.

Le brainstorm demandait de repointer `root` sur un symlink `latest`. **À ne pas faire** : la racine sert une *page de sélection de versions*, pas la dernière build. Ce changement aurait détruit cette page ainsi que le BLOC 3 (legacy `/heros-draft/`).

`/var/www/prototypes` n'héberge que Hero's Draft (confirmé le 17/08) — le confinement de la clé SSH (§6.1) est donc calibré sur ce dossier.

### 3.3 Prérequis manuels restants

Un seul, à réaliser **avant** d'écrire du YAML.

**Générer la paire de clés dédiée au CI** (nouvelle clé, pas celle d'un autre projet — cf. §6.1) :

```bash
ssh-keygen -t ed25519 -C "heros-draft-ci" -f ~/.ssh/heros_draft_ci -N ""
```

Sur le VPS, ajouter dans le `authorized_keys` du user devops :

```
restrict,command="rrsync -wo /var/www/prototypes" ssh-ed25519 AAAA...<clé publique> heros-draft-ci
```

Récupérer la clé d'hôte pour éviter le TOFU (§6.2) :

```bash
ssh-keyscan -H heros-draft.vilarserver.com
```

> `rrsync` est livré avec rsync mais n'est pas toujours dans le `PATH` — il peut résider sous `/usr/share/doc/rsync/scripts/rrsync`. À localiser et rendre exécutable une fois.

### 3.4 Secrets GitHub à créer

| Secret | Contenu |
|:---|:---|
| `VPS_SSH_KEY` | Clé **privée** `~/.ssh/heros_draft_ci` (contenu complet, en-têtes inclus) |
| `VPS_HOST` | Hôte SSH du VPS |
| `VPS_USER` | User devops existant |
| `VPS_KNOWN_HOSTS` | Sortie de `ssh-keyscan -H <host>` |

**Aucun token GitHub à créer.** Actions injecte un `GITHUB_TOKEN` éphémère, scopé au repo, détruit en fin de job. Les permissions sont déclarées explicitement par job (§6.4).

`VPS_WEB_ROOT` du brainstorm est **supprimé** : `rrsync` confine déjà le chemin côté serveur, la cible rsync devient relative (§5.4).

---

## 4. `ci.yml`

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          flutter-version: 3.41.6
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart analyze --fatal-infos
      - run: flutter test
```

**`--fatal-infos`** : `dart analyze` sort en échec sur les erreurs et warnings, mais **pas** sur les `info`. `CLAUDE.md` exige « zéro issue » — le flag est nécessaire pour que la CI applique réellement la règle écrite. Il ne coûte rien aujourd'hui (§3.1).

**`concurrency` + `cancel-in-progress`** : deux pushes rapprochés n'entrelacent plus leurs résultats. **Volontairement absent de `release.yml`** — on n'annule jamais un déploiement en cours.

---

## 5. `release.yml`

```yaml
name: Release

on:
  push:
    tags: ['v*.*.*']
  workflow_dispatch:

permissions:
  contents: read
```

```
                    verify-version
              tag == pubspec == patch_notes
                 + format semver validé
                          │
           ┌──────────────┴──────────────┐
           ▼                             ▼
       build-web                   build-windows
   --base-href /v{ver}/          Compress-Archive
           │                             │
           ▼                             ▼
      deploy-web                  release-windows
   rsync → v{ver}/              pre-release + zip + notes
```

`build-web` et `build-windows` ne dépendent que de `verify-version`, jamais l'un de l'autre : l'échec d'une cible laisse l'autre aller au bout de sa chaîne.

### 5.1 `verify-version` — ubuntu-latest

Porte unique du pipeline. Un échec ici signifie que **rien** n'est buildé, déployé ni publié.

```yaml
jobs:
  verify-version:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.check.outputs.version }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - id: check
        run: |
          set -euo pipefail

          if [[ "${GITHUB_REF}" != refs/tags/* ]]; then
            echo "::error::Ce workflow doit cibler un tag (refs/tags/vX.Y.Z), pas ${GITHUB_REF}."
            exit 1
          fi

          TAG="${GITHUB_REF#refs/tags/}"
          VERSION="${TAG#v}"

          if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "::error::Version '${VERSION}' non conforme à X.Y.Z (tag ${TAG})."
            exit 1
          fi

          PUBSPEC="$(grep -E '^version:' pubspec.yaml | sed -E 's/^version:[[:space:]]*//' | cut -d'+' -f1)"
          if [[ "${VERSION}" != "${PUBSPEC}" ]]; then
            echo "::error::Tag ${TAG} ≠ pubspec.yaml (${PUBSPEC}). Resynchronise pubspec.yaml, supprime et repousse le tag."
            exit 1
          fi

          NOTES="$(jq -r '.[0].version' assets/data/patch_notes.json)"
          if [[ "${VERSION}" != "${NOTES}" ]]; then
            echo "::error::Tag ${TAG} ≠ patch_notes.json[0].version (${NOTES}). Le skill patch-notes-writer doit avoir écrit l'entrée de cette version en tête de fichier."
            exit 1
          fi

          echo "version=${VERSION}" >> "$GITHUB_OUTPUT"
```

La **validation du format semver** n'est pas cosmétique : elle est le garde-fou structurel qui empêche une variable vide ou malformée d'atteindre le `rsync --delete` de `deploy-web` (§7). `jq` est préinstallé sur les runners `ubuntu-latest`.

### 5.2 `build-web` — ubuntu-latest

```yaml
  build-web:
    needs: verify-version
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          flutter-version: 3.41.6
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build web --release --base-href "/v${{ needs.verify-version.outputs.version }}/"
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: web-build
          path: build/web/
          retention-days: 7
```

> [!WARNING]
> **`--base-href` est obligatoire.** `web/index.html:17` contient `<base href="$FLUTTER_BASE_HREF">`, qui vaut `/` par défaut. Servi depuis `/v0.4.7/`, un build sans ce flag ferait chercher `main.dart.js`, CanvasKit et `assets/` **à la racine du domaine** → page blanche. Le brainstorme omettait ce flag.

Effet de bord voulu : chaque build est **épinglé à son URL de version**. C'est cohérent avec l'abandon de `latest`, et c'est la raison pour laquelle un symlink `latest` ne peut pas fonctionner sans build dédié.

### 5.3 `build-windows` — windows-latest

```yaml
  build-windows:
    needs: verify-version
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          flutter-version: 3.41.6
          channel: stable
          cache: true
      - run: flutter pub get
      - run: flutter build windows --release
      - name: Zip du build
        shell: pwsh
        run: |
          Compress-Archive `
            -Path "build/windows/x64/runner/Release/*" `
            -DestinationPath "heros-draft-v${{ needs.verify-version.outputs.version }}-windows.zip"
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: windows-build
          path: heros-draft-*-windows.zip
          retention-days: 7
```

**À confirmer au premier run** : le chemin `build/windows/x64/runner/Release/`. Flutter l'a déjà fait évoluer par le passé. Si le zip sort vide, c'est là qu'il faut regarder.

### 5.4 `deploy-web` — ubuntu-latest

```yaml
  deploy-web:
    needs: [verify-version, build-web]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: web-build
          path: web-build
      - uses: webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555 # v0.10.0
        with:
          ssh-private-key: ${{ secrets.VPS_SSH_KEY }}
      - name: Clé d'hôte connue
        run: |
          mkdir -p ~/.ssh && chmod 700 ~/.ssh
          echo "${{ secrets.VPS_KNOWN_HOSTS }}" >> ~/.ssh/known_hosts
      - name: rsync vers le VPS
        run: |
          set -euo pipefail
          rsync -avz --delete \
            web-build/ \
            "${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}:v${{ needs.verify-version.outputs.version }}/"
```

> [!IMPORTANT]
> **La cible est relative, pas absolue.** Avec la commande forcée `rrsync -wo /var/www/prototypes`, les chemins client sont interprétés **relativement à la racine confinée**. La cible est donc `:v0.4.7/` et non `:/var/www/prototypes/v0.4.7/`. Écrire le chemin absolu échouera.

**Atomicité** : aucune bascule de symlink n'est nécessaire. Écrire dans un dossier `v0.4.7/` neuf ne touche à aucune version existante ni à la page de sélection. Si le rsync échoue, le dossier reste incomplet mais **personne n'en possède l'URL** (la release n'est pas encore publiée), et un re-run le complète. C'est la même garantie que le symlink atomique du brainstorm, obtenue sans mécanisme.

### 5.5 `release-windows` — ubuntu-latest

```yaml
  release-windows:
    needs: [verify-version, build-windows]
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: windows-build
          path: .
      - name: Corps de release depuis les patch notes
        run: |
          set -euo pipefail
          jq -r '.[0] as $n
            | "## \($n.title)\n\n"
            + ( $n.sections
                | map("### \(.emoji) \(.category)\n" + (.entries | map("- \(.)") | join("\n")))
                | join("\n\n") )
          ' assets/data/patch_notes.json > RELEASE_BODY.md
          cat RELEASE_BODY.md
      - uses: softprops/action-gh-release@fe965f7af51af5f2602596916f38a38df2e33de0 # v3.0.2
        with:
          body_path: RELEASE_BODY.md
          prerelease: true
          files: heros-draft-*-windows.zip
```

**Schéma source vérifié** (stable sur toutes les entrées de `patch_notes.json`) :
`[{ version, date, title, sections: [{ category, emoji, entries: [string] }] }]`

**Sortie attendue.** `jq` n'étant pas installé sur la machine de développement, la transformation a été validée en exécutant son équivalent exact contre l'entrée `0.4.7` réelle — la *forme* ci-dessous est donc vérifiée, mais **le script `jq` lui-même reste à fumer au premier run** (d'où le `cat` ci-dessous). C'est le seul élément de cette spec qui n'a pas pu être exécuté tel quel localement.

```markdown
## L'Équilibre des Effectifs

### ✨ Nouvelles Fonctionnalités
- Une nouvelle relique légendaire, la Besace de l'Érudit, …

### ⚡ Améliorations
- Votre défausse retourne désormais dans la pioche …
- Un message vous signale le moment où …
```

`cat RELEASE_BODY.md` est laissé dans le job volontairement : le rendu est visible dans les logs, ce qui rend un problème de formatage diagnosticable sans republier.

**Idempotence** : `action-gh-release` met à jour la release existante au lieu d'échouer si le tag en a déjà une. Un re-run après échec transitoire ne demande aucun nettoyage manuel.

---

## 6. Sécurité

### 6.1 Une clé SSH par projet

Le user devops mutualisé est conservé — c'est la **clé** qui est l'unité de révocation, et elle doit être neuve et dédiée :

1. **Rotation indépendante** — révoquer pour Hero's Draft retire une ligne de `authorized_keys` sans casser les autres projets.
2. **Le repo est public** — le workflow expose host, user et chemins cibles en clair. La valeur du secret reste protégée, mais une clé mutualisée transformerait une erreur de config *ici* en exposition de *tous* les projets partageant la clé.
3. **Traçabilité** — on sait quelle clé a écrit quoi.

Le confinement `restrict,command="rrsync -wo /var/www/prototypes"` réduit le rayon d'explosion : pas de shell, pas de lecture, pas de port-forwarding, écriture seule dans un dossier web. Même exfiltré, le secret ne donne rien d'autre.

### 6.2 Pas de TOFU sur la clé d'hôte

`ssh-keyscan` exécuté *dans* le pipeline accepterait n'importe quelle clé d'hôte présentée, rendant tout MITM indétectable. La clé est donc capturée **une fois** à la main et stockée dans `VPS_KNOWN_HOSTS` (§3.3).

### 6.3 Actions tierces pinnées au SHA

Sur un repo public, un tag mutable (`@v3`) laisse le mainteneur — ou quiconque le compromet — remplacer le code exécuté avec accès aux secrets du job. Les SHA ci-dessous sont **résolus depuis les dépôts amont** (`git ls-remote --tags`) le 17/08/2026 :

| Action | Version | SHA |
|:---|:---|:---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `subosito/flutter-action` | v2.23.0 | `1a449444c387b1966244ae4d4f8c696479add0b2` |
| `actions/upload-artifact` | v7.0.1 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |
| `actions/download-artifact` | v8.0.1 | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` |
| `webfactory/ssh-agent` | v0.10.0 | `e83874834305fe9a4a2997156cb26c5de65a8555` |
| `softprops/action-gh-release` | v3.0.2 | `fe965f7af51af5f2602596916f38a38df2e33de0` |

`upload-artifact` (v7) et `download-artifact` (v8) sont sur des majeures différentes. Les deux utilisent le backend artifact v4+ et doivent interopérer ; si le téléchargement échoue au premier run, aligner les majeures est le premier réflexe.

### 6.4 Permissions minimales

`permissions: contents: read` au niveau de chaque workflow ; élevé à `contents: write` **uniquement** sur `release-windows`, seul job qui publie. Aucun autre job ne peut écrire dans le repo, ce qui rend structurellement impossible la dérive « le pipeline bump la version tout seul » que le brainstorm voulait éviter.

---

## 7. Gestion des erreurs et reprise

| Situation | Comportement |
|:---|:---|
| `verify-version` échoue | Arrêt net. Rien n'est buildé, déployé ni publié. Message d'erreur nommant le fichier à corriger. |
| Un build échoue | L'autre cible poursuit sa chaîne jusqu'au bout. |
| `deploy-web` échoue | Toutes les versions déjà en ligne restent intactes, page de sélection incluse. Le dossier de la nouvelle version reste incomplet, sans URL publiée. |
| `release-windows` échoue | Aucune release publiée, ou release existante inchangée. Re-run sûr (idempotent). |
| Tag erroné poussé | Seul cas nécessitant une action manuelle : supprimer le tag local et distant, corriger, repousser. |

**« Re-run failed jobs » est sûr sur tous les jobs** — aucun effet de bord destructeur.

**Risque `rsync --delete`, fermé structurellement.** La destination du rsync est `":v${VERSION}/"` : un `VERSION` vide donnerait `:v/`, un dossier frère des versions publiées, jamais la racine confinée elle-même — le préfixe `v` littéral de la destination agit comme un verrou de sécurité indépendant, à ne pas retirer au prétexte qu'il serait cosmétique. `verify-version` ferme le risque en amont : la version est validée `^[0-9]+\.[0-9]+\.[0-9]+$` avant de pouvoir atteindre ce job, et elle doit déjà correspondre à `pubspec.yaml` **et** à `patch_notes.json`. Une valeur vide ou malformée ne peut pas franchir la première porte.

**Limite connue et acceptée** : aucune notification n'existe en v1 (Discord reporté, §1). L'état d'une release se lit dans l'onglet Actions. Acceptable pour les premières releases, qui seront surveillées.

---

## 8. Validation

L'ordre est conçu pour que chaque étape élimine une source d'incertitude avant que la suivante n'en dépende.

**Étape 0 — valider la clé SSH à la main**, depuis la machine de l'utilisateur, avant tout YAML :

```bash
rsync -avz --delete ./un-dossier-de-test/ user@host:v0.0.0-test/
```

Cela vérifie d'un coup : la clé, le confinement `rrsync`, la relativité des chemins (§5.4) **et** que `rrsync` autorise bien `--delete`. Si `--delete` est refusé par le confinement, le retirer du job (§5.4) — il n'apporte presque rien puisque chaque version est déployée dans un dossier neuf. Supprimer `v0.0.0-test/` ensuite.

**Étape 1 — `ci.yml` seul.** Aucun effet de bord, vérifiable immédiatement. Les deux portes sont vertes localement (§3.1) : la CI **doit** être verte au premier push. Si elle est rouge, le défaut est dans le pipeline, pas dans le code — diagnostic sans ambiguïté.

**Étape 2 — `release.yml` via `workflow_dispatch`** sur le tag, pour itérer sans polluer l'historique des tags.

**Étape 3 — premier tag réel `v0.4.7`** (patch notes déjà prêtes) comme test d'intégration end-to-end. Sûr grâce aux propriétés du §7 : un échec partiel n'endommage rien.

Vérifications finales attendues : `https://heros-draft.vilarserver.com/v0.4.7/` charge et joue (assets compris — c'est le test réel du `--base-href`), et la pre-release GitHub expose le zip avec les patch notes en corps.

---

## 9. Écarts avec le brainstorm du 30/07

| # | Brainstorm | Cette spec | Cause |
|:---:|:---|:---|:---|
| 1 | Resynchroniser `pubspec.yaml` | Supprimé | Fait depuis (P-01, 03/08) |
| 2 | Repointer `root` nginx sur `latest` | **Supprimé** | Le BLOC 2 couvre déjà `/vX.Y.Z/` ; le changement aurait détruit la page de sélection et le legacy |
| 3 | Symlink `latest` + bascule atomique | **Supprimé** | Un dossier neuf par version donne la même garantie sans mécanisme |
| 4 | Secret `VPS_WEB_ROOT` | Supprimé | Cité deux fois mais jamais déclaré dans le brainstorm ; rendu inutile par le confinement `rrsync` |
| 5 | Créer un token GitHub | Supprimé | `GITHUB_TOKEN` éphémère + `permissions:` par job |
| 6 | `flutter build web --release` | **`--base-href` ajouté** | Bloquant : page blanche sans lui |
| 7 | `dart analyze` | `--fatal-infos` ajouté | Sans le flag, les `info` passent et la règle `CLAUDE.md` n'est pas appliquée |
| 8 | Format de version non validé | Regex semver ajoutée | Ferme le risque `rsync --delete` sur chemin vide |
| 9 | Clé SSH dédiée | + `restrict` et `rrsync -wo` | Réduction du rayon d'explosion, d'autant que le repo est public |
| 10 | `ssh-keyscan` implicite | `VPS_KNOWN_HOSTS` | Évite le TOFU |
| 11 | Actions tierces au tag | SHA complets résolus | Chaîne d'approvisionnement sur repo public |
| 12 | Pas de `concurrency` | Ajouté sur `ci.yml` seul | Runs concurrents entrelacés ; jamais sur les releases |
| 13 | `notify-discord` en v1 (7 jobs) | **Reporté** (6 jobs) | Décision du 17/08 : livrer le CI/CD complet d'abord |

---

## 10. Effort révisé

| Poste | Brainstorm | Révisé |
|:---|:---:|:---:|
| Code | 1,5-2 j | **~1,25 j** (un job de moins, plus de logique de symlink) |
| Configuration externe | 0,5 j | **~0,25 j** (1 prérequis au lieu de 4, aucune intervention nginx) |
