# P-04 · CI/CD GitHub Actions — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatiser les deux canaux de distribution manuels de Hero's Draft (déploiement web sur VPS, zip Windows pour testeurs) et appliquer automatiquement `dart analyze` + `flutter test` sur chaque push/PR.

**Architecture:** Deux workflows GitHub Actions. `ci.yml` (1 job) tourne sur chaque push/PR vers `main` sans aucun effet de bord. `release.yml` (5 jobs) se déclenche sur un tag `vX.Y.Z` : une porte de vérification de version, puis deux chaînes de build indépendantes (web → rsync vers le VPS, Windows → pre-release GitHub). La logique shell non triviale est extraite dans `.github/scripts/` pour être testable localement.

**Tech Stack:** GitHub Actions (YAML), Bash, `jq`, `rsync`/`rrsync` via SSH, Flutter 3.41.6.

**Spec de référence :** [2026-08-17-p04-ci-cd-github-actions-design.md](../specs/2026-08-17-p04-ci-cd-github-actions-design.md)

---

## Écarts assumés avec la spec

Trois raffinements, tous motivés par la **testabilité**. À valider avant de commencer ; ils ne changent aucun comportement de production.

| # | Spec | Ce plan | Pourquoi |
|:---:|:---|:---|:---|
| 1 | Bash inline dans le YAML | Extrait dans `.github/scripts/*.sh` | `verify-version` est **le seul garde-fou** protégeant contre un `rsync --delete` destructeur. Un garde-fou jamais testé n'est pas un garde-fou. Inline dans du YAML, il est intestable ; en script, il se teste localement en 2 secondes. |
| 2 | `workflow_dispatch` sans entrée, doit cibler un tag | `workflow_dispatch` avec entrée `version` optionnelle | Tester en ciblant un tag oblige à déplacer le tag (`git tag -f`) à chaque correction. Avec l'entrée, on itère depuis `main`. **Aucun affaiblissement** : la version fournie doit toujours correspondre à `pubspec.yaml` *et* à `patch_notes.json`, donc elle ne peut valoir que `0.4.7`. |
| 3 | `push: tags` présent dès l'écriture | Ajouté seulement en Task 6 | Tant que le déclencheur par tag est absent, `release.yml` est **inerte** : il ne peut pas se déclencher accidentellement pendant qu'on le met au point. |

---

## Global Constraints

Valables pour **toutes** les tâches, reprises verbatim de la spec.

- **Version Flutter : `3.41.6`**, channel `stable` (Dart 3.11.4). Identique dans les deux workflows.
- **Actions tierces pinnées au SHA de commit complet**, jamais au tag. Commentaire `# vX.Y.Z` obligatoire en fin de ligne :

| Action | Version | SHA à utiliser |
|:---|:---|:---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `subosito/flutter-action` | v2.23.0 | `1a449444c387b1966244ae4d4f8c696479add0b2` |
| `actions/upload-artifact` | v7.0.1 | `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` |
| `actions/download-artifact` | v8.0.1 | `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` |
| `webfactory/ssh-agent` | v0.10.0 | `e83874834305fe9a4a2997156cb26c5de65a8555` |
| `softprops/action-gh-release` | v3.0.2 | `fe965f7af51af5f2602596916f38a38df2e33de0` |

- **`permissions: contents: read`** au niveau de chaque workflow. Élevé à `contents: write` **uniquement** sur le job `release-windows`.
- **Le pipeline n'écrit JAMAIS dans le repo.** Il vérifie et échoue ; il ne corrige ni ne bump rien.
- **La cible rsync est RELATIVE** (`:v0.4.7/`), jamais absolue — la commande forcée `rrsync -wo /var/www/prototypes` interprète les chemins depuis la racine confinée.
- **Invoquer les scripts par `bash chemin/script.sh`**, jamais `./script.sh` — Git sous Windows ne peut pas positionner le bit exécutable.
- **Messages de commit sans accents**, préfixés `type(scope):` — convention du repo (voir `git log`).
- **`dart analyze` doit rester à zéro issue.** Aucune tâche de ce plan ne touche du code Dart, mais la règle `CLAUDE.md` reste applicable.

---

## Structure des fichiers

| Fichier | Responsabilité | Task |
|:---|:---|:---:|
| `.gitattributes` | **Créer.** Forcer LF sur les fichiers `.github/` | 1 |
| `.github/scripts/verify_version.sh` | **Créer.** Valider la cohérence tag ↔ `pubspec.yaml` ↔ `patch_notes.json`. Le garde-fou. | 1 |
| `.github/scripts/release_body.sh` | **Créer.** Transformer `patch_notes.json[0]` en markdown | 2 |
| `.github/scripts/test_scripts.sh` | **Créer.** Harnais de test local des deux scripts ci-dessus | 1, 2 |
| `.github/workflows/ci.yml` | **Créer.** Job `quality` — analyze + test | 3 |
| `.github/workflows/release.yml` | **Créer** (Task 4), **étendre** (Tasks 5, 6) | 4, 5, 6 |

**Séparation des responsabilités** : les scripts valident et transforment, le YAML fait la plomberie (variables GitHub, artefacts, `GITHUB_OUTPUT`). Aucun script ne lit une variable propre à Actions — c'est ce qui les rend exécutables sur un poste de dev.

---

## ⚠️ Contrainte GitHub à connaître avant de commencer

**Le bouton « Run workflow » (`workflow_dispatch`) n'apparaît que si le fichier de workflow est présent sur la branche par défaut.** Conséquence sur l'ordre des tâches :

- Tasks 1→4 se font sur la branche `feat/p04-ci-cd`, puis **PR → merge dans `main`**. La PR elle-même valide `ci.yml` (Task 3). `release.yml` arrive dans `main` **inerte** (pas de déclencheur par tag).
- Tasks 5→6 itèrent **sur `main`**, par petits commits, en déclenchant manuellement. C'est inévitable : sans le fichier sur `main`, pas de bouton.

---

## Task 0 : Prérequis externes

> [!CAUTION]
> **Tâche humaine, non déléguable à un agent.** Elle demande un accès SSH au VPS et à l'interface des secrets GitHub. **Bloquante pour la Task 5 uniquement** — les Tasks 1 à 4 peuvent se faire en parallèle sans elle.

**Files:** aucun (configuration externe)

**Interfaces:**
- Consumes: rien
- Produces: 4 secrets GitHub (`VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER`, `VPS_KNOWN_HOSTS`) consommés par le job `deploy-web` (Task 5)

- [ ] **Step 1: Générer la paire de clés dédiée**

Une clé **neuve**, propre à ce projet — pas celle d'un autre projet (justification : spec §6.1).

```bash
ssh-keygen -t ed25519 -C "heros-draft-ci" -f ~/.ssh/heros_draft_ci -N ""
```

- [ ] **Step 2: Localiser `rrsync` sur le VPS**

```bash
command -v rrsync || find /usr/share/doc/rsync -name 'rrsync*'
```

S'il n'est pas dans le `PATH`, le copier et le rendre exécutable :

```bash
sudo cp /usr/share/doc/rsync/scripts/rrsync /usr/local/bin/rrsync && sudo chmod +x /usr/local/bin/rrsync
```

*(Si le fichier est en `.gz`, le décompresser avec `gunzip -c … | sudo tee /usr/local/bin/rrsync`.)*

- [ ] **Step 3: Autoriser la clé, confinée en écriture seule**

Ajouter cette ligne au `~/.ssh/authorized_keys` du user devops sur le VPS, en y collant le contenu de `~/.ssh/heros_draft_ci.pub` :

```
restrict,command="rrsync -wo /var/www/prototypes" ssh-ed25519 AAAA...<clé publique> heros-draft-ci
```

- [ ] **Step 4: Capturer la clé d'hôte**

Évite le TOFU (spec §6.2). Conserver la sortie complète :

```bash
ssh-keyscan -H <VPS_HOST>
```

- [ ] **Step 5: Test de fumée — la validation la plus importante de ce plan**

Depuis la machine de dev. Vérifie **d'un seul coup** : la clé, le confinement `rrsync`, la relativité des chemins, et si `--delete` franchit le confinement.

```bash
mkdir -p /tmp/hd-test && echo "ok" > /tmp/hd-test/index.html
rsync -avz --delete -e "ssh -i ~/.ssh/heros_draft_ci" /tmp/hd-test/ <VPS_USER>@<VPS_HOST>:v0.0.0-test/
```

**Attendu :** transfert réussi. Vérifier ensuite dans un navigateur que `https://heros-draft.vilarserver.com/v0.0.0-test/` renvoie `ok` — cela prouve que le BLOC 2 nginx sert bien les dossiers versionnés sans modification.

**Si `--delete` est refusé** par le confinement : le retirer de la commande rsync en Task 5, Step 3. Il n'apporte presque rien (chaque version va dans un dossier neuf). Noter la décision.

**Si le chemin absolu a été utilisé par réflexe** (`:/var/www/prototypes/v0.0.0-test/`) : c'est normal que ça échoue. La cible est relative.

- [ ] **Step 6: Nettoyer le dossier de test**

```bash
ssh -i ~/.ssh/heros_draft_ci <VPS_USER>@<VPS_HOST> "rm -rf /var/www/prototypes/v0.0.0-test"
```

Le confinement `rrsync` bloque cette commande — c'est **attendu et c'est la preuve que le confinement fonctionne**. Utiliser une connexion SSH normale (clé personnelle) pour supprimer le dossier.

- [ ] **Step 7: Créer les 4 secrets GitHub**

Dans *Settings → Secrets and variables → Actions → New repository secret* :

| Secret | Valeur |
|:---|:---|
| `VPS_SSH_KEY` | Contenu **complet** de `~/.ssh/heros_draft_ci` (clé privée, lignes `-----BEGIN/END-----` incluses) |
| `VPS_HOST` | L'hôte SSH |
| `VPS_USER` | Le user devops |
| `VPS_KNOWN_HOSTS` | Sortie complète du Step 4 |

---

## Task 1 : Le garde-fou de version, testé

**Files:**
- Create: `.gitattributes`
- Create: `.github/scripts/verify_version.sh`
- Create: `.github/scripts/test_scripts.sh`

**Interfaces:**
- Consumes: rien
- Produces: `bash .github/scripts/verify_version.sh <version>` — exit `0` si `<version>` correspond au format `X.Y.Z` **et** à `pubspec.yaml` **et** à `patch_notes.json[0].version` ; exit `1` avec un message `::error::` sinon. Surcharge des chemins par les variables d'environnement `PUBSPEC_PATH` et `PATCH_NOTES_PATH` (pour les tests). Consommé par le job `verify-version` (Task 4).

- [ ] **Step 1: Créer la branche de travail**

```bash
git checkout -b feat/p04-ci-cd
```

- [ ] **Step 2: Installer `jq` localement**

Nécessaire pour exécuter les tests. `jq` est déjà préinstallé sur les runners `ubuntu-latest` — c'est uniquement le poste de dev qui en manque.

```bash
winget install --id jqlang.jq -e
```

Vérifier dans un **nouveau** terminal (le `PATH` doit être rechargé) :

```bash
jq --version
```

*Repli si `winget` échoue : `choco install jq`, ou télécharger `jq.exe` depuis les releases de `jqlang/jq` et le placer dans un dossier du `PATH`.*

- [ ] **Step 3: Créer `.gitattributes`**

`core.autocrlf` vaut `true` sur ce poste. Sans cette protection, un script shell peut arriver sur le runner Linux avec des fins de ligne CRLF et échouer sur `$'\r': command not found` — une erreur classique et pénible à diagnostiquer.

```
# Les fichiers consommes par les runners Linux doivent rester en LF.
# Portee volontairement limitee a .github/ : un `* text=auto` renormaliserait
# tout le repo Flutter, ce qui n'est pas le sujet de ce chantier.
.github/scripts/*.sh text eol=lf
.github/workflows/*.yml text eol=lf
```

- [ ] **Step 4: Écrire le harnais de test avec les cas d'échec**

Créer `.github/scripts/test_scripts.sh`. À ce stade, il ne teste que `verify_version.sh` ; la Task 2 y ajoutera les tests de `release_body.sh`.

```bash
#!/usr/bin/env bash
# Tests des scripts CI. Lancer depuis la racine du repo :
#   bash .github/scripts/test_scripts.sh
# Volontairement sans `set -e` : le harnais doit survivre a un test qui echoue.
set -uo pipefail

PASS=0
FAIL=0
FIXTURES="$(mktemp -d)"
trap 'rm -rf "${FIXTURES}"' EXIT

ok()  { PASS=$((PASS + 1)); echo "  ok   - $1"; }
nok() { FAIL=$((FAIL + 1)); echo "  FAIL - $1"; }

# assert_exit <code attendu> <description> <commande...>
assert_exit() {
  local expected="$1" desc="$2"
  shift 2
  local out code
  out="$("$@" 2>&1)"
  code=$?
  if [[ "${code}" -eq "${expected}" ]]; then
    ok "${desc}"
  else
    nok "${desc} (attendu exit ${expected}, obtenu ${code}) :: ${out}"
  fi
}

# assert_contains <sous-chaine attendue> <description> <commande...>
assert_contains() {
  local needle="$1" desc="$2"
  shift 2
  local out
  out="$("$@" 2>&1)"
  if [[ "${out}" == *"${needle}"* ]]; then
    ok "${desc}"
  else
    nok "${desc} (sortie sans '${needle}') :: ${out}"
  fi
}

VERIFY="bash .github/scripts/verify_version.sh"

# Fixtures : un pubspec et des patch notes en 0.4.8, pour isoler chaque comparaison.
printf 'name: roguelike_card_game\nversion: 0.4.8+1\n' > "${FIXTURES}/pubspec_048.yaml"
printf '[{"version":"0.4.8","date":"2026-01-01","title":"T","sections":[]}]\n' > "${FIXTURES}/notes_048.json"

echo "verify_version.sh"

# --- Cas nominal : les vrais fichiers du repo sont en 0.4.7 ---
assert_exit 0 "accepte 0.4.7 (pubspec et patch notes reels)" ${VERIFY} 0.4.7

# --- Formats invalides ---
assert_exit 1 "refuse une version absente"        ${VERIFY}
assert_exit 1 "refuse la chaine vide"             ${VERIFY} ""
assert_exit 1 "refuse 0.4 (incomplet)"            ${VERIFY} 0.4
assert_exit 1 "refuse v0.4.7 (prefixe v)"         ${VERIFY} v0.4.7
assert_exit 1 "refuse 0.4.7-beta (suffixe)"       ${VERIFY} 0.4.7-beta
assert_exit 1 "refuse 0.4.7+1 (build metadata)"   ${VERIFY} 0.4.7+1
assert_exit 1 "refuse du texte libre"             ${VERIFY} abc

# --- Desaccord avec pubspec.yaml ---
assert_exit 1 "refuse 0.4.8 face au pubspec reel (0.4.7)" ${VERIFY} 0.4.8
assert_contains "pubspec.yaml" "nomme pubspec.yaml dans l'erreur de desaccord" ${VERIFY} 0.4.8

# --- Desaccord avec patch_notes.json, pubspec neutralise par une fixture ---
assert_exit 1 "refuse quand seules les patch notes divergent" \
  env "PUBSPEC_PATH=${FIXTURES}/pubspec_048.yaml" ${VERIFY} 0.4.8
assert_contains "patch_notes.json" "nomme patch_notes.json dans l'erreur" \
  env "PUBSPEC_PATH=${FIXTURES}/pubspec_048.yaml" ${VERIFY} 0.4.8

# --- Cas nominal avec les deux fixtures alignees ---
assert_exit 0 "accepte 0.4.8 quand les deux fixtures concordent" \
  env "PUBSPEC_PATH=${FIXTURES}/pubspec_048.yaml" \
      "PATCH_NOTES_PATH=${FIXTURES}/notes_048.json" ${VERIFY} 0.4.8

echo
echo "${PASS} ok, ${FAIL} echec(s)"
[[ "${FAIL}" -eq 0 ]]
```

- [ ] **Step 5: Lancer le harnais et vérifier qu'il échoue**

```bash
bash .github/scripts/test_scripts.sh
```

**Attendu :** tous les tests en `FAIL`, parce que `verify_version.sh` n'existe pas encore. Les messages contiendront `No such file or directory`. C'est le point de départ correct.

- [ ] **Step 6: Écrire `verify_version.sh`**

Créer `.github/scripts/verify_version.sh` :

```bash
#!/usr/bin/env bash
# Valide qu'une version est coherente entre le tag git, pubspec.yaml et patch_notes.json.
#
# Usage : verify_version.sh <version>      exemple : verify_version.sh 0.4.7
# Sortie : 0 si tout concorde, 1 avec un message ::error:: sinon.
#
# Ce script est LE garde-fou du pipeline de release. La validation de format
# n'est pas cosmetique : elle empeche une valeur vide ou malformee d'atteindre
# le `rsync --delete` du job deploy-web, ou elle porterait sur la racine du
# dossier web au lieu du sous-dossier de version.
#
# Chemins surchargeables (pour les tests) :
#   PUBSPEC_PATH      defaut pubspec.yaml
#   PATCH_NOTES_PATH  defaut assets/data/patch_notes.json

set -uo pipefail

PUBSPEC_PATH="${PUBSPEC_PATH:-pubspec.yaml}"
PATCH_NOTES_PATH="${PATCH_NOTES_PATH:-assets/data/patch_notes.json}"

VERSION="${1-}"

if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::Version '${VERSION}' non conforme a X.Y.Z (chiffres et points uniquement, ni prefixe v ni suffixe)."
  exit 1
fi

if [[ ! -f "${PUBSPEC_PATH}" ]]; then
  echo "::error::Fichier introuvable : ${PUBSPEC_PATH}"
  exit 1
fi

if [[ ! -f "${PATCH_NOTES_PATH}" ]]; then
  echo "::error::Fichier introuvable : ${PATCH_NOTES_PATH}"
  exit 1
fi

# `version: 0.4.7+1` -> `0.4.7`
PUBSPEC_VERSION="$(grep -E '^version:' "${PUBSPEC_PATH}" | head -1 | sed -E 's/^version:[[:space:]]*//' | cut -d'+' -f1 | tr -d '[:space:]')"

if [[ -z "${PUBSPEC_VERSION}" ]]; then
  echo "::error::Aucune ligne 'version:' exploitable dans ${PUBSPEC_PATH}."
  exit 1
fi

if [[ "${VERSION}" != "${PUBSPEC_VERSION}" ]]; then
  echo "::error::Version ${VERSION} != ${PUBSPEC_PATH} (${PUBSPEC_VERSION}). Resynchronise pubspec.yaml, puis supprime et repousse le tag."
  exit 1
fi

NOTES_VERSION="$(jq -r '.[0].version' "${PATCH_NOTES_PATH}" 2>/dev/null)"

if [[ -z "${NOTES_VERSION}" || "${NOTES_VERSION}" == "null" ]]; then
  echo "::error::Impossible de lire .[0].version dans ${PATCH_NOTES_PATH} (JSON invalide ou fichier vide ?)."
  exit 1
fi

if [[ "${VERSION}" != "${NOTES_VERSION}" ]]; then
  echo "::error::Version ${VERSION} != ${PATCH_NOTES_PATH}[0].version (${NOTES_VERSION}). Le skill patch-notes-writer doit avoir ecrit l'entree de cette version en tete de fichier."
  exit 1
fi

echo "Version ${VERSION} coherente : tag == ${PUBSPEC_PATH} == ${PATCH_NOTES_PATH}[0].version"
```

- [ ] **Step 7: Lancer le harnais et vérifier qu'il passe**

```bash
bash .github/scripts/test_scripts.sh
```

**Attendu :** `13 ok, 0 echec(s)`, et exit 0.

Si `accepte 0.4.7` échoue avec un souci de `jq`, revérifier le Step 2 dans un terminal neuf.

- [ ] **Step 8: Commit**

```bash
git add .gitattributes .github/scripts/verify_version.sh .github/scripts/test_scripts.sh
git commit -m "feat(ci): garde-fou de version verifie et son harnais de test

Valide le format semver, la concordance avec pubspec.yaml et avec
patch_notes.json. La validation de format ferme structurellement le risque
d'un rsync --delete sur chemin vide dans le job de deploiement.

.gitattributes force LF sur .github/ : core.autocrlf vaut true sur le poste
de dev, et un script en CRLF echoue sur un runner Linux.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 2 : L'extraction des patch notes, testée

**Files:**
- Create: `.github/scripts/release_body.sh`
- Modify: `.github/scripts/test_scripts.sh` (ajout d'une section de tests)

**Interfaces:**
- Consumes: rien
- Produces: `bash .github/scripts/release_body.sh` — écrit sur **stdout** le markdown de `patch_notes.json[0]`. Chemin surchargeable par `PATCH_NOTES_PATH`. Consommé par le job `release-windows` (Task 5).

**Schéma source** (vérifié stable sur toutes les entrées) :
`[{ version, date, title, sections: [{ category, emoji, entries: [string] }] }]`

- [ ] **Step 1: Ajouter les tests au harnais**

Insérer dans `.github/scripts/test_scripts.sh`, **juste avant** le bloc final `echo` / `${PASS} ok` :

```bash
echo
echo "release_body.sh"

BODY="bash .github/scripts/release_body.sh"

assert_exit 0 "s'execute sur les patch notes reelles" ${BODY}
assert_contains "## L'Équilibre des Effectifs" "reprend le titre en h2" ${BODY}
assert_contains "### ✨ Nouvelles Fonctionnalités" "rend emoji et categorie en h3" ${BODY}
assert_contains "- Une nouvelle relique légendaire" "rend les entrees en puces" ${BODY}
assert_contains "### 🔧 Technique" "rend la derniere section" ${BODY}

# Une ligne vide doit separer le titre de la premiere section.
assert_contains "Effectifs

###" "insere une ligne vide apres le titre" ${BODY}

# Le corps ne doit contenir que l'entree la plus recente.
if [[ "$(${BODY} 2>/dev/null | grep -c '^## ')" -eq 1 ]]; then
  ok "ne rend qu'une seule entree (la plus recente)"
else
  nok "ne rend qu'une seule entree (la plus recente)"
fi

# Cinq sections dans l'entree 0.4.7.
if [[ "$(${BODY} 2>/dev/null | grep -c '^### ')" -eq 5 ]]; then
  ok "rend les 5 sections de l'entree 0.4.7"
else
  nok "rend les 5 sections de l'entree 0.4.7 (obtenu $(${BODY} 2>/dev/null | grep -c '^### '))"
fi
```

- [ ] **Step 2: Lancer le harnais et vérifier que les nouveaux tests échouent**

```bash
bash .github/scripts/test_scripts.sh
```

**Attendu :** les 13 tests de `verify_version.sh` toujours `ok`, les 8 nouveaux en `FAIL` (`release_body.sh` n'existe pas).

- [ ] **Step 3: Écrire `release_body.sh`**

Créer `.github/scripts/release_body.sh` :

```bash
#!/usr/bin/env bash
# Transforme l'entree la plus recente de patch_notes.json en markdown, pour le
# corps de la release GitHub. Ecrit sur stdout.
#
# Usage : release_body.sh > RELEASE_BODY.md
#
# Chemin surchargeable (pour les tests) :
#   PATCH_NOTES_PATH  defaut assets/data/patch_notes.json
#
# Schema attendu :
#   [{ version, date, title, sections: [{ category, emoji, entries: [string] }] }]

set -uo pipefail

PATCH_NOTES_PATH="${PATCH_NOTES_PATH:-assets/data/patch_notes.json}"

if [[ ! -f "${PATCH_NOTES_PATH}" ]]; then
  echo "::error::Fichier introuvable : ${PATCH_NOTES_PATH}" >&2
  exit 1
fi

jq -r '.[0] as $n
  | "## \($n.title)\n\n"
  + ( $n.sections
      | map("### \(.emoji) \(.category)\n" + (.entries | map("- \(.)") | join("\n")))
      | join("\n\n") )
' "${PATCH_NOTES_PATH}"
```

- [ ] **Step 4: Lancer le harnais et vérifier qu'il passe**

```bash
bash .github/scripts/test_scripts.sh
```

**Attendu :** `21 ok, 0 echec(s)`.

- [ ] **Step 5: Contrôler le rendu à l'œil**

```bash
bash .github/scripts/release_body.sh
```

**Attendu**, exactement cette forme (accents et emoji compris) :

```markdown
## L'Équilibre des Effectifs

### ✨ Nouvelles Fonctionnalités
- Une nouvelle relique légendaire, la Besace de l'Érudit, …

### ⚡ Améliorations
- Votre défausse retourne désormais dans la pioche …
- Un message vous signale le moment où …
```

Si les accents sortent en mojibake, c'est l'encodage de la console Windows, pas le script — le runner Linux est en UTF-8. Confirmer avec `bash .github/scripts/release_body.sh | od -c | head` (chercher les séquences UTF-8 multi-octets) plutôt qu'en lisant le terminal.

- [ ] **Step 6: Commit**

```bash
git add .github/scripts/release_body.sh .github/scripts/test_scripts.sh
git commit -m "feat(ci): extraction des patch notes en markdown de release

Rend l'entree la plus recente de patch_notes.json (titre, sections avec
emoji, entrees en puces) pour alimenter le corps de la release GitHub.
Teste contre l'entree 0.4.7 reelle.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

## Task 3 : `ci.yml`

**Files:**
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: rien
- Produces: un check de statut `quality` sur chaque PR vers `main`

- [ ] **Step 1: Établir la référence locale**

Les deux portes doivent être vertes **avant** d'être automatisées, sinon on ne saura pas si un échec CI vient du pipeline ou du code.

```bash
dart analyze --fatal-infos
```

**Attendu :** `No issues found!`

```bash
flutter test
```

**Attendu :** `All tests passed!` (230 tests au 17/08/2026)

Si l'une des deux échoue : **arrêter et corriger le code avant de continuer**. Ce plan suppose une base saine.

- [ ] **Step 2: Écrire `ci.yml`**

Créer `.github/workflows/ci.yml` :

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

# Deux pushes rapproches ne doivent pas produire deux runs concurrents aux
# resultats entrelaces. Volontairement absent de release.yml : on n'annule
# jamais un deploiement en cours.
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

      # --fatal-infos est necessaire : sans lui, `dart analyze` sort en 0 sur les
      # diagnostics de niveau `info`, et la CI n'appliquerait pas la regle
      # "zero issue" de CLAUDE.md.
      - run: dart analyze --fatal-infos

      - run: flutter test

      # Les scripts de release sont utilises par release.yml ; les tester ici
      # evite qu'ils pourrissent sans que personne s'en apercoive.
      - run: bash .github/scripts/test_scripts.sh
```

- [ ] **Step 3: Pousser la branche et ouvrir la PR**

```bash
git add .github/workflows/ci.yml
git commit -m "feat(ci): workflow d'integration continue

Applique dart analyze --fatal-infos, flutter test et les tests des scripts
de release sur chaque push et PR vers main.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push -u origin feat/p04-ci-cd
```

Ouvrir la PR vers `main` depuis l'interface GitHub (le CLI `gh` n'est pas installé sur ce poste).

- [ ] **Step 4: Vérifier que la CI passe au vert sur la PR**

Onglet *Checks* de la PR, ou onglet *Actions*.

**Attendu :** job `quality` vert. Comparer sa durée à celle du run suivant : le second doit être nettement plus court, preuve que `cache: true` fonctionne.

**Si `test_scripts.sh` échoue ici alors qu'il passait localement** → c'est très probablement le problème de fins de ligne. Vérifier que `.gitattributes` est bien dans le commit et que le blob est en LF :

```bash
git show HEAD:.github/scripts/verify_version.sh | file -
```

**Attendu :** aucune mention de `CRLF`.

- [ ] **Step 5: Ne pas encore merger**

La Task 4 ajoute `release.yml` sur la même branche, pour ne merger qu'une fois.

---

## Task 4 : `release.yml` — la partie sans effet de bord

Vérification de version et deux builds. **Aucun déploiement, aucune publication.** On peut la lancer autant de fois qu'on veut sans rien casser.

**Files:**
- Create: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: `bash .github/scripts/verify_version.sh <version>` (Task 1)
- Produces:
  - Job `verify-version`, output `version` (ex. `0.4.7`), consommé par tous les jobs suivants
  - Artefact `web-build` — contenu de `build/web/`, construit avec `--base-href "/v<version>/"`
  - Artefact `windows-build` — `heros-draft-v<version>-windows.zip`

- [ ] **Step 1: Écrire `release.yml` sans les jobs à effet de bord**

Créer `.github/workflows/release.yml`. **Noter l'absence délibérée de `push: tags`** — le workflow reste inerte jusqu'à la Task 6.

```yaml
name: Release

# Pas de declencheur `push: tags` a ce stade : tant qu'il est absent, ce
# workflow ne peut pas partir tout seul pendant sa mise au point.
# Il est ajoute en fin de chantier, une fois la chaine prouvee.
on:
  workflow_dispatch:
    inputs:
      version:
        description: "Version a publier (X.Y.Z). Vide = deduite du tag cible."
        required: false
        type: string

permissions:
  contents: read

jobs:
  verify-version:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.resolve.outputs.version }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # Deux sources possibles : l'entree manuelle, ou le tag qui a declenche le
      # run. Dans les deux cas la valeur passe ensuite par le meme garde-fou.
      - id: resolve
        run: |
          set -euo pipefail

          VERSION="${{ inputs.version }}"

          if [[ -z "${VERSION}" ]]; then
            if [[ "${GITHUB_REF}" != refs/tags/* ]]; then
              echo "::error::Aucune version fournie et ${GITHUB_REF} n'est pas un tag. Fournis l'entree 'version', ou cible un tag vX.Y.Z."
              exit 1
            fi
            TAG="${GITHUB_REF#refs/tags/}"
            VERSION="${TAG#v}"
          fi

          bash .github/scripts/verify_version.sh "${VERSION}"

          echo "version=${VERSION}" >> "${GITHUB_OUTPUT}"

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

      # --base-href est OBLIGATOIRE : web/index.html contient
      # <base href="$FLUTTER_BASE_HREF">, qui vaut "/" par defaut. Servi depuis
      # /v0.4.7/ sans ce flag, l'app chercherait main.dart.js et CanvasKit a la
      # racine du domaine -> page blanche.
      - run: flutter build web --release --base-href "/v${{ needs.verify-version.outputs.version }}/"

      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: web-build
          path: build/web/
          retention-days: 7

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

- [ ] **Step 2: Commit, pousser, merger la PR**

```bash
git add .github/workflows/release.yml
git commit -m "feat(ci): workflow de release, jobs de verification et de build

Verification de version (tag ou entree manuelle, meme garde-fou dans les
deux cas) puis build web et Windows en parallele. Pas encore de declencheur
par tag ni de job a effet de bord : le workflow ne peut pas partir seul.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push
```

Vérifier que la CI est verte sur la PR, puis **merger dans `main`**. C'est nécessaire pour que le bouton *Run workflow* apparaisse (voir la contrainte GitHub en tête de plan).

- [ ] **Step 3: Vérifier que le garde-fou refuse une mauvaise version**

*Actions → Release → Run workflow*, branche `main`, entrée `version` = `9.9.9`.

**Attendu :** `verify-version` **échoue**, `build-web` et `build-windows` sont *skipped*. Le log doit afficher :
`::error::Version 9.9.9 != pubspec.yaml (0.4.7)…`

C'est la vérification la plus importante de cette tâche : elle prouve en conditions réelles que rien ne peut être buildé sur une version incohérente.

- [ ] **Step 4: Vérifier le cas nominal**

*Run workflow* avec `version` = `0.4.7`.

**Attendu :** les trois jobs verts, et deux artefacts téléchargeables en bas de la page du run — `web-build` et `windows-build`.

- [ ] **Step 5: Contrôler les deux artefacts**

Télécharger `web-build` et ouvrir son `index.html` dans un éditeur.

**Attendu :** `<base href="/v0.4.7/">` — la substitution a bien eu lieu. C'est la preuve statique que le bug de page blanche est évité.

Télécharger `windows-build`, dézipper.

**Attendu :** un `.exe` à la racine, accompagné de ses DLL et d'un dossier `data/`.

**Si le zip est vide ou ne contient qu'un dossier** : le chemin `build/windows/x64/runner/Release/` a changé de forme. Ajouter temporairement une étape de diagnostic avant le zip pour retrouver la bonne arborescence :

```yaml
      - shell: pwsh
        run: Get-ChildItem -Recurse build/windows -Depth 4 | Select-Object FullName
```

---

## Task 5 : `release.yml` — déploiement et publication

Les deux jobs à effet de bord réel. **Task 0 doit être terminée.**

**Files:**
- Modify: `.github/workflows/release.yml` (ajout de deux jobs en fin de fichier)

**Interfaces:**
- Consumes: output `version` de `verify-version` ; artefacts `web-build` et `windows-build` (Task 4) ; `bash .github/scripts/release_body.sh` (Task 2) ; les 4 secrets de Task 0
- Produces: `https://heros-draft.vilarserver.com/v<version>/` en ligne, et une pre-release GitHub taguée avec le zip Windows en asset

- [ ] **Step 1: Vérifier que Task 0 est bien terminée**

Confirmer que les 4 secrets existent (*Settings → Secrets and variables → Actions*) et que le test de fumée du Step 5 de la Task 0 est passé. **Ne pas continuer sinon** : c'est là qu'est concentrée toute la fragilité du chantier.

- [ ] **Step 2: Ajouter `deploy-web`**

Ajouter à la fin de `.github/workflows/release.yml` :

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

      # La cle d'hote est capturee une fois a la main et stockee en secret.
      # Un `ssh-keyscan` execute ici accepterait n'importe quelle cle presentee,
      # ce qui rendrait tout MITM indetectable.
      - name: Cle d'hote connue
        run: |
          set -euo pipefail
          mkdir -p ~/.ssh && chmod 700 ~/.ssh
          echo "${{ secrets.VPS_KNOWN_HOSTS }}" >> ~/.ssh/known_hosts
          chmod 600 ~/.ssh/known_hosts

      # La cible est RELATIVE. La commande forcee `rrsync -wo /var/www/prototypes`
      # cote serveur resout les chemins depuis la racine confinee : un chemin
      # absolu echouerait.
      #
      # Pas de symlink "latest" a basculer : ecrire dans un dossier de version
      # neuf ne touche a aucune version deja en ligne ni a la page de selection
      # servie a la racine. L'atomicite est acquise sans mecanisme.
      - name: rsync vers le VPS
        run: |
          set -euo pipefail
          rsync -avz --delete \
            web-build/ \
            "${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}:v${{ needs.verify-version.outputs.version }}/"
```

> Si le test de fumée de la Task 0 a montré que `--delete` ne franchit pas le confinement `rrsync`, le retirer de la commande ci-dessus.

- [ ] **Step 3: Commit et pousser — obligatoirement avant de lancer**

> [!IMPORTANT]
> `workflow_dispatch` exécute **la version du workflow présente sur `main`**, pas les modifications locales. Lancer avant de pousser testerait l'ancien fichier, sans job `deploy-web`, en donnant l'illusion d'un succès. Cette règle vaut pour chaque itération de cette tâche.

```bash
git add .github/workflows/release.yml
git commit -m "feat(ci): deploiement web vers le VPS

rsync du build web vers un dossier par version, via une cle SSH dediee
confinee en ecriture seule par rrsync. Cible relative a la racine confinee.
Cle d'hote lue depuis un secret plutot que via ssh-keyscan, pour ne pas
rendre un MITM indetectable.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push
```

- [ ] **Step 4: Lancer et vérifier le déploiement**

*Run workflow*, `version` = `0.4.7`.

**Attendu :** `deploy-web` vert, et `https://heros-draft.vilarserver.com/v0.4.7/` **charge et joue**.

C'est le test réel du `--base-href` : ouvrir la console du navigateur et vérifier l'absence de 404 sur `main.dart.js`, CanvasKit ou `assets/`. Une page blanche ici renvoie au Step 5 de la Task 4.

Vérifier aussi que la **racine** `https://heros-draft.vilarserver.com/` sert toujours sa page de sélection de versions, et qu'une **ancienne** version (ex. `/v0.0.9/`) répond encore. C'est la preuve qu'un déploiement n'abîme pas l'existant.

- [ ] **Step 5: Ajouter `release-windows`**

Ajouter à la fin de `.github/workflows/release.yml` :

```yaml
  release-windows:
    needs: [verify-version, build-windows]
    runs-on: ubuntu-latest
    # Seul job du pipeline autorise a ecrire dans le repo, et uniquement pour
    # publier une release. Aucun autre ne peut y toucher.
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: windows-build
          path: .

      # Le `cat` est volontaire : il rend le markdown visible dans les logs,
      # donc diagnosticable sans republier la release.
      - name: Corps de release depuis les patch notes
        run: |
          set -euo pipefail
          bash .github/scripts/release_body.sh > RELEASE_BODY.md
          cat RELEASE_BODY.md

      # action-gh-release est idempotent : il met a jour une release existante
      # au lieu d'echouer, donc un re-run apres incident ne demande aucun
      # nettoyage manuel.
      - uses: softprops/action-gh-release@fe965f7af51af5f2602596916f38a38df2e33de0 # v3.0.2
        with:
          tag_name: v${{ needs.verify-version.outputs.version }}
          body_path: RELEASE_BODY.md
          prerelease: true
          files: heros-draft-*-windows.zip
```

> `tag_name` est explicite parce qu'un run déclenché par `workflow_dispatch` n'a pas de tag dans `github.ref` — sans lui, l'action ne saurait pas à quel tag rattacher la release. Le tag `v0.4.7` doit donc exister avant le Step 6.

- [ ] **Step 6: Créer le tag `v0.4.7`**

Le workflow n'a **pas** de déclencheur `push: tags` à ce stade : créer le tag ne lance rien.

```bash
git tag v0.4.7
git push origin v0.4.7
```

- [ ] **Step 7: Commit et pousser — à nouveau avant de lancer**

```bash
git add .github/workflows/release.yml
git commit -m "feat(ci): pre-release GitHub avec le zip Windows

Corps de release genere depuis patch_notes.json. Marquee pre-release pour
signaler aux testeurs qu'il ne s'agit pas d'une sortie stable. Permission
contents:write portee a ce seul job.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push
```

- [ ] **Step 8: Lancer et vérifier la release**

*Run workflow*, `version` = `0.4.7`.

**Attendu :**
- `release-windows` vert
- Onglet *Releases* : une release `v0.4.7` marquée **Pre-release**
- Son corps affiche les patch notes formatées (titre en h2, sections avec emoji, entrées en puces)
- `heros-draft-v0.4.7-windows.zip` est attaché et téléchargeable

Le repo étant public, ce lien est utilisable directement par les testeurs sans compte GitHub.

- [ ] **Step 9: Vérifier l'idempotence**

Relancer *Run workflow* à l'identique, `version` = `0.4.7`.

**Attendu :** le job passe encore au vert et **met à jour** la release existante au lieu d'échouer. C'est la propriété qui rend tout re-run sûr.

---

## Task 6 : Activer le déclencheur par tag

Le pipeline est prouvé de bout en bout par dispatch. Reste à brancher le déclencheur de production.

**Files:**
- Modify: `.github/workflows/release.yml` (bloc `on:`)

**Interfaces:**
- Consumes: tout ce qui précède
- Produces: pousser un tag `vX.Y.Z` déclenche seul la chaîne complète

- [ ] **Step 1: Ajouter le déclencheur par tag**

Remplacer le bloc `on:` de `.github/workflows/release.yml` par :

```yaml
on:
  push:
    tags: ['v*.*.*']
  workflow_dispatch:
    inputs:
      version:
        description: "Version a publier (X.Y.Z). Vide = deduite du tag cible."
        required: false
        type: string
```

Le commentaire expliquant l'absence du déclencheur peut être supprimé — il n'a plus d'objet.

- [ ] **Step 2: Commit et pousser**

```bash
git add .github/workflows/release.yml
git commit -m "feat(ci): activer le declencheur de release par tag

La chaine complete a ete validee par workflow_dispatch. Pousser un tag
vX.Y.Z declenche desormais verification, builds, deploiement et release.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push
```

- [ ] **Step 3: Test end-to-end par le vrai chemin**

Le tag `v0.4.7` existe déjà, il faut donc le repousser pour exercer le déclencheur. Comme il s'agit d'une pre-release et que la publication est idempotente, l'opération est sans danger.

```bash
git push --delete origin v0.4.7
git tag -f v0.4.7
git push origin v0.4.7
```

**Attendu :** un run de `Release` démarre **tout seul**, sans intervention manuelle, et les 5 jobs passent au vert.

- [ ] **Step 4: Vérification finale**

| Contrôle | Attendu |
|:---|:---|
| `https://heros-draft.vilarserver.com/v0.4.7/` | Charge et joue, aucun 404 en console |
| Racine du site | Sert toujours la page de sélection de versions |
| Une ancienne version (`/v0.0.9/`) | Répond toujours |
| Onglet *Releases* | `v0.4.7` en Pre-release, patch notes en corps, zip attaché |
| Onglet *Actions* | Un run `Release` déclenché par le tag, 5 jobs verts |
| Une PR quelconque | Le check `quality` de `ci.yml` tourne |

- [ ] **Step 5: Documenter la procédure de release**

Le pipeline est en service, mais rien n'indique encore comment s'en servir. Ajouter à `README.md`, dans une section `## Publier une version` :

```markdown
## Publier une version

1. Faire rédiger les patch notes par le skill `patch-notes-writer` — il écrit
   l'entrée dans `assets/data/patch_notes.json` et synchronise `pubspec.yaml`.
2. Committer et pousser sur `main`.
3. Poser le tag correspondant :

   git tag v0.4.8
   git push origin v0.4.8

Le pipeline vérifie que le tag, `pubspec.yaml` et `patch_notes.json`
concordent, puis déploie le web sur `/v0.4.8/` et publie une pre-release
GitHub avec le build Windows.

En cas d'échec, « Re-run failed jobs » est sûr sur tous les jobs. Si le tag
lui-même est erroné, le supprimer (`git push --delete origin v0.4.8`), corriger,
et le reposer.
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: procedure de publication d'une version

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
git push
```

---

## Après ce plan

Hors périmètre, à traiter séparément :

1. **`notify-discord`** — reporté volontairement (spec §1). Le script `release_body.sh` est déjà réutilisable tel quel pour le payload du webhook.
2. **`memory-bank-sync`** — `ROADMAP.md` porte deux faits devenus faux sur P-04 : « 7 jobs » (c'est 6) et l'effort « 1,5-2 j *(+0,5 j)* » (révisé à ~1,25 j *(+0,25 j)*). Le fichier appartient à ce skill, à ne pas éditer à la main.
3. **`patch-notes-writer`** — ce chantier est de l'outillage, invisible pour le joueur : **aucune patch note à écrire**.
4. **En-têtes de cache nginx** — non nécessaires avec un dossier par version (chaque URL est immuable). Le sujet ne reviendrait qu'avec une URL `latest`.
