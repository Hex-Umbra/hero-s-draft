# Site vitrine & finalisation du CI/CD — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prouver automatiquement qu'une version déployée est réellement jouable, annoncer chaque release sur Discord, et remplacer la page de sélection écrite à la main par un site versionné et piloté par les données.

**Architecture:** Deux lots livrés sur deux releases. Le lot 1 ajoute deux jobs à `release.yml` (`smoke-test`, `notify-discord`) et deux scripts testables à `.github/scripts/`. Le lot 2 crée `site/`, un site statique sans build dont la source de vérité est `site/_site/versions.json` — écrit à la main, vérifié par `verify_version.sh`, jamais écrit par le pipeline — et un workflow `site.yml` appelé par `release.yml` après le smoke test.

**Tech Stack:** GitHub Actions (YAML), Bash, `jq`, `curl`, `rsync`/`rrsync` via SSH, HTML/CSS/JS statiques en modules ES natifs, `node --test` pour la logique de jointure.

**Spec de référence :** [2026-08-19-site-vitrine-et-finalisation-ci-cd-design.md](../specs/2026-08-19-site-vitrine-et-finalisation-ci-cd-design.md)

---

## Écarts assumés avec la spec

Quatre raffinements. À valider avant de commencer.

| # | Spec | Ce plan | Pourquoi |
|:---:|:---|:---|:---|
| 1 | Trois modules JS : `data.js`, `render.js`, `main.js` | **Quatre** : `model.js` extrait de `data.js` | `model.js` contient la **jointure** — exactement ce que le §3.3 de la spec identifie comme le piège du chantier. Séparé de tout accès réseau, il devient testable par `node --test` en une seconde. Mélangé au `fetch`, il n'est vérifiable qu'à l'œil dans un navigateur. |
| 2 | Pas de tests JS mentionnés | `node --test` lancé depuis `site/`, ajouté aux deux portes `quality` | Un test qui ne tourne jamais pourrit. **Aucune action tierce nouvelle** : Node est préinstallé sur `ubuntu-latest`, donc aucun SHA supplémentaire à épingler. |
| 3 | `<noscript>` avec les liens essentiels | **Repli statique inconditionnel** dans chaque `data-slot`, remplacé par le JS en cas de succès | Strictement supérieur : `<noscript>` ne couvre que « JS désactivé », le repli statique couvre aussi « JS actif mais `fetch` en échec » — le cas réellement probable. Le HTML livré est utilisable tel quel. |
| 4 | Étape 0 : sonde `rsync` depuis la machine de l'utilisateur | Sonde **depuis GitHub Actions**, via un `site.yml` inerte lancé à la main (Task 10) | `rsync` est **absent de la machine Windows** — vérifié le 19/08. Sans danger : ce chemin n'a aucun `--delete`, un refus de `rrsync` échoue sans rien écrire, et `release.yml` n'appelle pas encore `site.yml` à ce stade. |

---

## Global Constraints

Valables pour **toutes** les tâches, reprises verbatim de la spec et de celle du 17/08.

- **Le pipeline n'écrit JAMAIS dans le dépôt.** Il vérifie et échoue ; il ne corrige ni ne bump rien. `versions.json` ne fait pas exception.
- **`--delete` est INTERDIT sur le déploiement du site.** La cible est la racine confinée, où vivent les quinze dossiers de versions. Ne pas l'ajouter, sous aucun prétexte.
- **Actions tierces épinglées au SHA de commit complet**, jamais au tag, commentaire `# vX.Y.Z` en fin de ligne. Réutiliser **exactement** les SHA déjà en place :

| Action | Version | SHA |
|:---|:---|:---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` |
| `webfactory/ssh-agent` | v0.10.0 | `e83874834305fe9a4a2997156cb26c5de65a8555` |

- **`permissions: contents: read`** au niveau de chaque workflow. Aucun nouveau job n'obtient `contents: write`.
- **Aucun secret interpolé dans un corps de `run:`.** `DISCORD_WEBHOOK_URL` passe par `env:`.
- **Invoquer les scripts par `bash chemin/script.sh`**, jamais `./script.sh` — Git sous Windows ne peut pas positionner le bit exécutable.
- **Ne jamais ajouter de contournement Windows dans un script de production.** Si une assertion du harnais échoue à cause de `\r`, la normalisation va **dans le harnais** (`tr -d '\r'`), jamais dans le script. C'est une régression déjà commise et corrigée le 17/08.
- **Les attentes du harnais sont dérivées à l'exécution** avec `jq`, jamais figées en dur : le prochain bump de version ne doit rien casser.
- **Messages de commit sans accents**, préfixés `type(scope):`.
- **`dart analyze` doit rester à zéro issue.** Aucune tâche ne touche de code Dart, mais la règle `CLAUDE.md` reste applicable.
- **Le dépôt est public.** `site/` l'est aussi : aucune URL d'administration, aucun chemin serveur interne, aucun secret.

---

## Structure des fichiers

| Fichier | Responsabilité | Task |
|:---|:---|:---:|
| `.github/scripts/smoke_test.sh` | Quatre assertions HTTP sur une version déployée | 1 |
| `.github/scripts/discord_payload.sh` | Construit le JSON de l'embed Discord. **N'envoie rien** | 2 |
| `.github/scripts/test_scripts.sh` | *(modifié)* harnais des scripts CI | 1, 2, 5 |
| `.github/workflows/release.yml` | *(modifié)* +`smoke-test`, +`notify-discord`, +`deploy-site` | 3, 11 |
| `.github/scripts/verify_version.sh` | *(modifié)* + garde-fou `versions.json` | 5 |
| `site/package.json` | Déclare `site/` comme arbre de modules ES. **Non déployé** | 7 |
| `site/_site/versions.json` | **Source de vérité** : ce qui est en ligne et jouable | 5 |
| `site/_site/js/model.js` | Logique pure : jointure, groupement, URL dérivées, formats. **Aucune E/S** | 7 |
| `site/_site/js/model.test.js` | Tests `node --test` de `model.js`. **Non déployé** | 7 |
| `site/_site/js/data.js` | Accès réseau seul : `fetch` + gestion d'échec | 8 |
| `site/_site/js/render.js` | Fonctions pures données → `HTMLElement`. **Aucun `fetch`** | 8 |
| `site/_site/js/main.js` | Point d'entrée, aiguille sur `data-page` | 8 |
| `site/_site/style.css` | Feuille unique, tokens de la charte validée | 6 |
| `site/_site/fonts/` | Press Start 2P + VT323 en woff2, auto-hébergées | 6 |
| `site/index.html` | Accueil | 6, 8 |
| `site/versions.html` | Archive jouable | 6, 9 |
| `site/notes.html` | Historique des patch notes | 6, 9 |
| `site/nginx.reference.conf` | Contrat de service versionné. **Non déployé** | 12 |
| `.github/workflows/site.yml` | Déploiement du site | 10 |
| `.github/workflows/ci.yml` | *(modifié)* + `node --test` | 7 |
| `CLAUDE.md` | *(modifié)* périmètre de `patch-notes-writer` | 12 |
| `.claude/skills/patch-notes-writer/SKILL.md` | *(modifié)* écrit aussi `versions.json` | 12 |

---

## ⚠️ Contraintes GitHub à connaître avant de commencer

1. **`workflow_dispatch` n'apparaît dans l'interface que si le workflow est sur la branche par défaut.** `site.yml` doit être poussé sur `main` avant de pouvoir être lancé à la main. C'est sans risque tant qu'il n'a ni déclencheur `push` ni appelant (Task 10).
2. **`workflow_call` exige `secrets: inherit` côté appelant**, sinon le workflow appelé ne voit aucun secret.
3. **Un job `uses:` ne peut pas porter `continue-on-error`.** C'est pourquoi `deploy-site` est bloquant et `notify-discord` reste un job `run:` classique.

---

# LOT 1 — livré par la release 0.4.8

## Task 0 : Prérequis externes

**Fichiers :** aucun. Actions humaines, à faire avant la Task 3.

- [ ] **Étape 1 : créer le webhook Discord**

Salon voulu → Paramètres → Intégrations → Webhooks → Nouveau webhook → Copier l'URL.

- [ ] **Étape 2 : créer le secret GitHub**

Dépôt → Settings → Secrets and variables → Actions → New repository secret.
Nom exact : `DISCORD_WEBHOOK_URL`. Valeur : l'URL copiée.

- [ ] **Étape 3 : vérifier que le webhook répond**

Depuis une machine avec `curl`, sans jamais écrire l'URL dans un fichier du dépôt :

```bash
read -rs DISCORD_URL && curl -sS -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"content":"test"}' "$DISCORD_URL"
```

Attendu : `204`. Un `404` signifie que le webhook a été supprimé ou l'URL tronquée.

- [ ] **Étape 4 : confirmer les trois secrets existants**

`VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER` doivent toujours être présents (mis en place le 18/08). `VPS_KNOWN_HOSTS` également.

---

## Task 1 : `smoke_test.sh` — prouver qu'une version est servie

**Files:**
- Create: `.github/scripts/smoke_test.sh`
- Modify: `.github/scripts/test_scripts.sh`

**Interfaces:**
- Consumes: rien.
- Produces: `bash .github/scripts/smoke_test.sh <base-url> <version>` → exit `0` si les quatre assertions passent, `1` avec un message `::error::` sinon. Réglages `SMOKE_ATTEMPTS` (défaut 3) et `SMOKE_DELAY` (défaut 5) surchargeables.

- [ ] **Étape 1 : écrire les tests qui échouent**

Ajouter à la fin de `.github/scripts/test_scripts.sh`, **avant** le bloc final `echo "${PASS} ok, ${FAIL} echec(s)"` :

```bash
echo
echo "smoke_test.sh"

SMOKE="bash .github/scripts/smoke_test.sh"

# Validation d'arguments : aucun de ces cas n'atteint le reseau, ils sortent
# avant le premier curl.
assert_exit 1 "refuse une URL de base absente"    ${SMOKE}
assert_exit 1 "refuse une URL de base vide"       ${SMOKE} "" "${REAL_VER}"
assert_exit 1 "refuse une version absente"        ${SMOKE} "https://exemple.test"
assert_exit 1 "refuse une version non semver"     ${SMOKE} "https://exemple.test" "v${REAL_VER}"
assert_exit 1 "refuse une version incomplete"     ${SMOKE} "https://exemple.test" "${INCOMPLETE_VER}"

# Chemin d'echec reseau, sans internet : le port 1 de la boucle locale refuse
# la connexion immediatement. Une seule tentative, aucune attente.
assert_exit 1 "echoue sur un hote injoignable" \
  env "SMOKE_ATTEMPTS=1" "SMOKE_DELAY=0" ${SMOKE} "http://127.0.0.1:1" "9.9.9"
assert_contains "127.0.0.1:1" "nomme l'URL fautive dans l'erreur" \
  env "SMOKE_ATTEMPTS=1" "SMOKE_DELAY=0" ${SMOKE} "http://127.0.0.1:1" "9.9.9"
```

- [ ] **Étape 2 : lancer le harnais pour vérifier qu'il échoue**

```bash
bash .github/scripts/test_scripts.sh
```

Attendu : les 7 nouvelles assertions en `FAIL`, avec un message du type `bash: .github/scripts/smoke_test.sh: No such file or directory`. Les 25 existantes restent `ok`.

- [ ] **Étape 3 : écrire le script**

Créer `.github/scripts/smoke_test.sh` :

```bash
#!/usr/bin/env bash
# Verifie qu'une version deployee est REELLEMENT servie par le VPS.
#
# Usage : smoke_test.sh <base-url> <version>
#   exemple : smoke_test.sh https://heros-draft.vilarserver.com 0.4.8
#
# Sortie : 0 si les quatre assertions passent, 1 avec un message ::error:: sinon.
#
# L'assertion sur <base href> justifie ce script a elle seule : sans le flag
# --base-href du job build-web, l'application chercherait main.dart.js et
# CanvasKit a la racine du domaine et afficherait une page blanche. Les fichiers
# seraient pourtant tous sur le disque et le rsync serait vert.
#
# Reglages surchargeables (pour les tests) :
#   SMOKE_ATTEMPTS  defaut 3
#   SMOKE_DELAY     defaut 5 (secondes entre deux tentatives)

set -uo pipefail

ATTEMPTS="${SMOKE_ATTEMPTS:-3}"
DELAY="${SMOKE_DELAY:-5}"

BASE_URL="${1-}"
VERSION="${2-}"

if [[ -z "${BASE_URL}" ]]; then
  echo "::error::smoke_test.sh : URL de base manquante. Usage : smoke_test.sh <base-url> <version>"
  exit 1
fi

if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::smoke_test.sh : version '${VERSION}' non conforme a X.Y.Z (chiffres et points uniquement, ni prefixe v ni suffixe)."
  exit 1
fi

ROOT="${BASE_URL%/}/v${VERSION}"

PAGE="$(mktemp)"
trap 'rm -f "${PAGE}"' EXIT

# http_ok <url> [fichier de sortie]
# Reessaie ATTEMPTS fois, DELAY secondes d'ecart, pour absorber un alea TLS ou
# reseau. Un echec definitif nomme l'URL et le dernier code obtenu.
http_ok() {
  local url="$1" out="${2:-/dev/null}" i code
  for (( i = 1; i <= ATTEMPTS; i++ )); do
    code="$(curl -sS -o "${out}" -w '%{http_code}' --max-time 20 "${url}" 2>/dev/null)"
    if [[ "${code}" == "200" ]]; then
      return 0
    fi
    if (( i < ATTEMPTS )); then
      sleep "${DELAY}"
    fi
  done
  echo "::error::${url} a repondu '${code}' apres ${ATTEMPTS} tentative(s). Attendu 200."
  return 1
}

http_ok "${ROOT}/" "${PAGE}" || exit 1

EXPECTED_BASE="<base href=\"/v${VERSION}/\">"
if ! grep -qF "${EXPECTED_BASE}" "${PAGE}"; then
  echo "::error::${ROOT}/ ne contient pas ${EXPECTED_BASE}. Le flag --base-href du job build-web est absent ou mal forme : l'application chargerait ses assets depuis la racine du domaine et afficherait une page blanche."
  exit 1
fi

http_ok "${ROOT}/main.dart.js" || exit 1
http_ok "${ROOT}/assets/assets/data/patch_notes.json" || exit 1

echo "Smoke test OK : ${ROOT}/ est servi, <base href> correct, main.dart.js et patch_notes.json accessibles."
```

- [ ] **Étape 4 : relancer le harnais**

```bash
bash .github/scripts/test_scripts.sh
```

Attendu : `32 ok, 0 echec(s)`.

- [ ] **Étape 5 : vérifier le script contre la production, à la main**

```bash
bash .github/scripts/smoke_test.sh https://heros-draft.vilarserver.com 0.4.7
```

Attendu : `Smoke test OK : ...`. La version 0.4.7 est en ligne depuis le 18/08 ; si ce test échoue, le défaut est dans le script, pas sur le serveur.

- [ ] **Étape 6 : commit**

```bash
git add .github/scripts/smoke_test.sh .github/scripts/test_scripts.sh
git commit -m "feat(ci): script de smoke test post-deploiement"
```

---

## Task 2 : `discord_payload.sh` — construire l'annonce

**Files:**
- Create: `.github/scripts/discord_payload.sh`
- Modify: `.github/scripts/test_scripts.sh`

**Interfaces:**
- Consumes: `.github/scripts/release_body.sh` (existant), invoqué avec `PATCH_NOTES_PATH` hérité.
- Produces: `bash .github/scripts/discord_payload.sh <version>` → le JSON de l'embed sur stdout, exit `0`. Réglages `PATCH_NOTES_PATH`, `SITE_BASE_URL`, `REPO_URL`, `DESC_LIMIT` surchargeables. **Le script n'envoie rien** : l'appel HTTP est fait par le workflow.

- [ ] **Étape 1 : écrire les tests qui échouent**

Ajouter à la fin de `test_scripts.sh`, avant le bloc final :

```bash
echo
echo "discord_payload.sh"

PAYLOAD="bash .github/scripts/discord_payload.sh"

# Comme pour release_body.sh, la sortie est normalisee une fois : jq natif sous
# Windows ecrit \r\n. La normalisation est DANS LE HARNAIS, jamais dans le
# script de production.
RENDER_PAYLOAD=(sh -c "bash .github/scripts/discord_payload.sh '${REAL_VER}' | tr -d '\r'")

assert_exit 1 "refuse une version absente"        ${PAYLOAD}
assert_exit 1 "refuse une version non semver"     ${PAYLOAD} "v${REAL_VER}"
assert_exit 1 "refuse un PATCH_NOTES_PATH introuvable" \
  env "PATCH_NOTES_PATH=${FIXTURES}/missing/patch_notes.json" ${PAYLOAD} "${REAL_VER}"

assert_exit 0 "s'execute sur les patch notes reelles" ${PAYLOAD} "${REAL_VER}"

# La sortie doit etre du JSON valide -- c'est tout l'interet de passer par jq -n
# plutot que par une concatenation.
if ${PAYLOAD} "${REAL_VER}" 2>/dev/null | jq -e . >/dev/null 2>&1; then
  ok "produit du JSON valide"
else
  nok "produit du JSON valide"
fi

assert_contains "${REAL_TITLE}" "reprend le titre de la patch note" "${RENDER_PAYLOAD[@]}"
assert_contains "/v${REAL_VER}/" "contient l'URL de jeu" "${RENDER_PAYLOAD[@]}"
assert_contains "heros-draft-v${REAL_VER}-windows.zip" "contient l'URL du zip" "${RENDER_PAYLOAD[@]}"
assert_contains "releases/tag/v${REAL_VER}" "contient l'URL de la release" "${RENDER_PAYLOAD[@]}"

# La couleur de la charte, 0xEAF06A.
if [[ "$(${PAYLOAD} "${REAL_VER}" 2>/dev/null | jq -r '.embeds[0].color')" == "15396970" ]]; then
  ok "utilise la couleur 0xEAF06A"
else
  nok "utilise la couleur 0xEAF06A"
fi

# Troncature : la description ne doit jamais depasser la limite Discord.
TRUNCATED="$(env "DESC_LIMIT=80" ${PAYLOAD} "${REAL_VER}" 2>/dev/null | jq -r '.embeds[0].description')"
if [[ "${#TRUNCATED}" -le 200 && "${TRUNCATED}" == *"release GitHub"* ]]; then
  ok "tronque la description et renvoie vers la release"
else
  nok "tronque la description et renvoie vers la release (longueur ${#TRUNCATED})"
fi

# Sans troncature, la description porte la premiere entree en entier.
assert_contains "${FIRST_ENTRY}" "contient la premiere entree des patch notes" \
  sh -c "bash .github/scripts/discord_payload.sh '${REAL_VER}' | jq -r '.embeds[0].description' | tr -d '\r'"
```

- [ ] **Étape 2 : lancer le harnais pour vérifier qu'il échoue**

```bash
bash .github/scripts/test_scripts.sh
```

Attendu : les 12 nouvelles assertions en `FAIL` (fichier introuvable), les 32 précédentes en `ok`.

- [ ] **Étape 3 : écrire le script**

Créer `.github/scripts/discord_payload.sh` :

```bash
#!/usr/bin/env bash
# Construit le corps JSON du message Discord annoncant une release.
# Ecrit sur stdout. N'ENVOIE RIEN : l'appel HTTP est fait par le workflow, qui
# seul detient le secret. Ce script reste donc testable localement.
#
# Usage : discord_payload.sh <version>      exemple : discord_payload.sh 0.4.8
#
# Surchargeables (pour les tests) :
#   PATCH_NOTES_PATH  defaut assets/data/patch_notes.json
#   SITE_BASE_URL     defaut https://heros-draft.vilarserver.com
#   REPO_URL          defaut https://github.com/Hex-Umbra/hero-s-draft
#   DESC_LIMIT        defaut 4000 (la limite Discord est 4096)

set -uo pipefail

PATCH_NOTES_PATH="${PATCH_NOTES_PATH:-assets/data/patch_notes.json}"
SITE_BASE_URL="${SITE_BASE_URL:-https://heros-draft.vilarserver.com}"
REPO_URL="${REPO_URL:-https://github.com/Hex-Umbra/hero-s-draft}"
DESC_LIMIT="${DESC_LIMIT:-4000}"

VERSION="${1-}"

if [[ ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::discord_payload.sh : version '${VERSION}' non conforme a X.Y.Z." >&2
  exit 1
fi

if [[ ! -f "${PATCH_NOTES_PATH}" ]]; then
  echo "::error::Fichier introuvable : ${PATCH_NOTES_PATH}" >&2
  exit 1
fi

TITLE="$(jq -r '.[0].title' "${PATCH_NOTES_PATH}" 2>/dev/null)"

if [[ -z "${TITLE}" || "${TITLE}" == "null" ]]; then
  echo "::error::Impossible de lire .[0].title dans ${PATCH_NOTES_PATH} (JSON invalide ou fichier vide ?)." >&2
  exit 1
fi

# Le corps markdown est produit par le script deja en service pour la release
# GitHub : une seule mise en forme des patch notes dans tout le pipeline.
BODY="$(PATCH_NOTES_PATH="${PATCH_NOTES_PATH}" bash "$(dirname "$0")/release_body.sh")"

if [[ -z "${BODY}" ]]; then
  echo "::error::release_body.sh n'a rien produit a partir de ${PATCH_NOTES_PATH}." >&2
  exit 1
fi

EMBED_TITLE="Hero's Draft v${VERSION} — ${TITLE}"
PLAY_URL="${SITE_BASE_URL}/v${VERSION}/"
ZIP_URL="${REPO_URL}/releases/download/v${VERSION}/heros-draft-v${VERSION}-windows.zip"
RELEASE_URL="${REPO_URL}/releases/tag/v${VERSION}"

# jq fait l'echappement ET la troncature. Une concatenation shell produirait du
# JSON invalide des la premiere apostrophe des patch notes francaises.
jq -n \
  --arg embedTitle "${EMBED_TITLE}" \
  --arg body       "${BODY}" \
  --arg play       "${PLAY_URL}" \
  --arg zip        "${ZIP_URL}" \
  --arg release    "${RELEASE_URL}" \
  --argjson limit  "${DESC_LIMIT}" \
  '{
     embeds: [{
       title: $embedTitle,
       url: $play,
       color: 15396970,
       description: (
         if ($body | length) > $limit
         then ($body[0:$limit] + "\n\n(...)\n\nNotes complètes sur la release GitHub.")
         else $body
         end
       ),
       fields: [
         { name: "Jouer",        value: ("[Dans le navigateur](" + $play + ")"),   inline: true },
         { name: "Télécharger",  value: ("[Windows (.zip)](" + $zip + ")"),        inline: true },
         { name: "Détails",      value: ("[Release GitHub](" + $release + ")"),    inline: true }
       ]
     }]
   }'
```

- [ ] **Étape 4 : relancer le harnais**

```bash
bash .github/scripts/test_scripts.sh
```

Attendu : `44 ok, 0 echec(s)`.

- [ ] **Étape 5 : lire la sortie à l'œil**

```bash
bash .github/scripts/discord_payload.sh 0.4.7 | jq -r '.embeds[0].description'
```

Attendu : le markdown des patch notes 0.4.7, titre en `##`, cinq sections en `###`, puces en `-`. Les accents et apostrophes doivent être intacts.

- [ ] **Étape 6 : commit**

```bash
git add .github/scripts/discord_payload.sh .github/scripts/test_scripts.sh
git commit -m "feat(ci): construction du payload Discord d'annonce de release"
```

---

## Task 3 : câbler les deux jobs dans `release.yml`

**Files:**
- Modify: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: `smoke_test.sh` (Task 1), `discord_payload.sh` (Task 2), la sortie `version` du job `verify-version` existant.
- Produces: le job `smoke-test`, dont les tâches du lot 2 dépendront (`deploy-site` aura `needs: [verify-version, smoke-test]`).

- [ ] **Étape 1 : ajouter le job `smoke-test`**

Insérer dans `.github/workflows/release.yml`, **après** le job `deploy-web` et avant `release-windows` :

```yaml
  # Un rsync vert prouve que des fichiers sont sur le disque, pas que le jeu se
  # lance. Ce job fait la difference, et c'est lui qui autorise la suite : ni le
  # site ni Discord n'annoncent une version qui n'a pas passe cette porte.
  smoke-test:
    needs: [verify-version, deploy-web]
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.sha }}

      - name: La version deployee repond et porte le bon base href
        run: |
          set -euo pipefail
          bash .github/scripts/smoke_test.sh \
            "https://heros-draft.vilarserver.com" \
            "${{ needs.verify-version.outputs.version }}"
```

- [ ] **Étape 2 : ajouter le job `notify-discord`**

Ajouter **à la fin** du fichier :

```yaml
  # Un webhook muet ne doit jamais peindre en rouge une release par ailleurs
  # parfaite : continue-on-error laisse le job en avertissement sans invalider
  # le run. `if: success()` limite l'annonce aux releases reussies -- GitHub
  # envoie deja un e-mail en cas d'echec.
  notify-discord:
    needs: [verify-version, smoke-test, release-windows]
    if: success()
    continue-on-error: true
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.sha }}

      # Le payload est construit puis envoye en deux etapes distinctes : le
      # `cat` rend le JSON lisible dans les logs, donc diagnosticable sans
      # renvoyer de message. Le webhook, lui, n'apparait jamais dans les logs.
      - name: Construire le payload
        run: |
          set -euo pipefail
          bash .github/scripts/discord_payload.sh \
            "${{ needs.verify-version.outputs.version }}" > discord.json
          cat discord.json

      - name: Envoyer sur Discord
        env:
          DISCORD_WEBHOOK_URL: ${{ secrets.DISCORD_WEBHOOK_URL }}
        run: |
          set -euo pipefail
          if [[ -z "${DISCORD_WEBHOOK_URL}" ]]; then
            echo "::error::Le secret DISCORD_WEBHOOK_URL est absent ou vide."
            exit 1
          fi
          CODE="$(curl -sS -o /dev/null -w '%{http_code}' \
            -X POST -H 'Content-Type: application/json' \
            --data @discord.json \
            "${DISCORD_WEBHOOK_URL}")"
          if [[ "${CODE}" != "204" ]]; then
            echo "::error::Discord a repondu ${CODE}, attendu 204."
            exit 1
          fi
          echo "Annonce publiee."
```

- [ ] **Étape 3 : vérifier la syntaxe YAML**

```bash
python -c "import yaml,sys; d=yaml.safe_load(open('.github/workflows/release.yml',encoding='utf-8')); print(sorted(d['jobs']))"
```

Attendu exactement : `['build-web', 'build-windows', 'deploy-web', 'notify-discord', 'quality', 'release-windows', 'smoke-test', 'verify-version']`

- [ ] **Étape 4 : vérifier que le secret n'est jamais interpolé dans un corps de script**

```bash
grep -n 'secrets.DISCORD' .github/workflows/release.yml
```

Attendu : **une seule ligne**, sous une clé `env:`. Aucune occurrence dans un bloc `run:`.

- [ ] **Étape 5 : commit et push**

```bash
git add .github/workflows/release.yml
git commit -m "feat(ci): jobs de smoke test et d'annonce Discord"
git push
```

- [ ] **Étape 6 : vérifier que la CI reste verte**

Onglet Actions → le run `CI` déclenché par ce push doit être vert, harnais compris (44 assertions).

---

## Task 4 : valider le lot 1 sur la release 0.4.8

**Files:** `pubspec.yaml`, `assets/data/patch_notes.json` — via la compétence `patch-notes-writer`, jamais à la main.

**Interfaces:**
- Consumes: les jobs des Tasks 1 à 3.
- Produces: la version 0.4.8 en ligne, et la preuve que la chaîne complète fonctionne sur un tag réel — ce que le test `v9.9.9` du 18/08 n'avait pas prouvé, quatre jobs sur six ayant été sautés.

- [ ] **Étape 1 : écrire les patch notes 0.4.8**

Invoquer la compétence `patch-notes-writer`. Elle prépend l'entrée `0.4.8` et met `pubspec.yaml` en `0.4.8+1`. **Ne pas éditer ces fichiers à la main.**

- [ ] **Étape 2 : vérifier le garde-fou en local**

```bash
bash .github/scripts/verify_version.sh 0.4.8
```

Attendu : `Version 0.4.8 coherente : ...`

- [ ] **Étape 3 : relancer le harnais**

```bash
bash .github/scripts/test_scripts.sh
```

Attendu : `44 ok, 0 echec(s)`. Les attentes étant dérivées à l'exécution, le bump de version ne doit rien casser. **Si une assertion tombe ici, c'est le harnais qui est en défaut, pas le code.**

- [ ] **Étape 4 : commit, tag, push**

```bash
git add pubspec.yaml assets/data/patch_notes.json
git commit -m "chore(release): version 0.4.8"
git push
git tag v0.4.8
git push origin v0.4.8
```

- [ ] **Étape 5 : suivre le run**

Attendu, dans l'ordre : `quality` et `verify-version` verts, `build-web` et `build-windows` verts, `deploy-web` vert, **`smoke-test` vert**, `release-windows` vert, **`notify-discord` vert avec un message dans le salon Discord**.

- [ ] **Étape 6 : vérifier de l'extérieur, pas seulement dans les logs**

```bash
bash .github/scripts/smoke_test.sh https://heros-draft.vilarserver.com 0.4.8
```

Puis, dans Discord : les trois liens du message doivent aboutir — jeu, zip, release.

---

# LOT 2 — livré par la release 0.4.9

## Task 5 : `versions.json` et son garde-fou

**Files:**
- Create: `site/_site/versions.json`
- Modify: `.github/scripts/verify_version.sh`
- Modify: `.github/scripts/test_scripts.sh`

**Interfaces:**
- Consumes: rien.
- Produces: le schéma que `model.js` (Task 7) consomme — `{ id, label, channel, date, notes, windows }`. `id` est le nom du dossier sur le VPS, donc le segment d'URL. `channel` vaut `current`, `stable` ou `legacy`. `notes` est une clé de `patch_notes.json` **ou `null`**. `date` est ISO `YYYY-MM-DD` **ou `null`**.

- [ ] **Étape 1 : créer `site/_site/versions.json`**

Quinze entrées. Les quatorze dossiers legacy portent `notes: null` : leur `version.json` rapporte tous `0.1.0`, leurs noms sont des numéros de déploiement, et `patch_notes.json` n'a aucune entrée `0.0.5` à `0.0.9`. Les dates legacy sont inconnues et valent `null` tant que personne ne les a relevées sur le VPS — `null` est une valeur que le rendu gère, pas un trou à combler.

```json
[
  { "id": "v0.4.7", "label": "0.4.7", "channel": "current", "date": "2026-08-18", "notes": "0.4.7", "windows": true },
  { "id": "v0.0.9", "label": "0.0.9", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.8", "label": "0.0.8", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.7", "label": "0.0.7", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.6", "label": "0.0.6", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.5", "label": "0.0.5", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.4", "label": "0.0.4", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.3", "label": "0.0.3", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.2", "label": "0.0.2", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v0.0.1", "label": "0.0.1", "channel": "stable", "date": null, "notes": null, "windows": false },
  { "id": "v5", "label": "Prototype V5", "channel": "legacy", "date": null, "notes": null, "windows": false },
  { "id": "v4", "label": "Prototype V4", "channel": "legacy", "date": null, "notes": null, "windows": false },
  { "id": "v3", "label": "Prototype V3", "channel": "legacy", "date": null, "notes": null, "windows": false },
  { "id": "v2", "label": "Prototype V2", "channel": "legacy", "date": null, "notes": null, "windows": false },
  { "id": "v1", "label": "Prototype V1", "channel": "legacy", "date": null, "notes": null, "windows": false }
]
```

- [ ] **Étape 2 : écrire les tests du garde-fou**

Ajouter dans `test_scripts.sh`, dans le bloc `verify_version.sh`, **juste avant** la ligne `echo` qui précède `release_body.sh`.

D'abord les fixtures, à ajouter au bloc `mkdir -p` existant en le remplaçant par :

```bash
mkdir -p "${FIXTURES}/agree" "${FIXTURES}/disagree" "${FIXTURES}/no_version" "${FIXTURES}/invalid" "${FIXTURES}/versions"
```

puis, après les `printf` de fixtures existants :

```bash
# Fixtures versions.json. Le cas nominal correspond a FX_A, comme le couple
# pubspec/patch-notes du dossier "agree".
V="${FIXTURES}/versions"
printf '[{"id":"v%s","label":"%s","channel":"current","date":null,"notes":"%s","windows":true},{"id":"v0.0.1","label":"0.0.1","channel":"stable","date":null,"notes":null,"windows":false}]\n' "${FX_A}" "${FX_A}" "${FX_A}" > "${V}/ok.json"
printf 'pas du json {{{' > "${V}/invalid.json"
printf '[{"id":"v0.0.1","label":"0.0.1","channel":"stable","date":null,"notes":null,"windows":false}]\n' > "${V}/no_current.json"
printf '[{"id":"v%s","label":"a","channel":"current","date":null,"notes":"%s","windows":true},{"id":"v0.0.1","label":"b","channel":"current","date":null,"notes":null,"windows":false}]\n' "${FX_A}" "${FX_A}" > "${V}/two_current.json"
printf '[{"id":"v0.0.1","label":"x","channel":"current","date":null,"notes":"%s","windows":true}]\n' "${FX_A}" > "${V}/wrong_id.json"
printf '[{"id":"v%s","label":"x","channel":"current","date":null,"notes":"0.0.1","windows":true}]\n' "${FX_A}" > "${V}/wrong_notes.json"
printf '[{"id":"v%s","label":"a","channel":"current","date":null,"notes":"%s","windows":true},{"id":"v%s","label":"b","channel":"stable","date":null,"notes":null,"windows":false}]\n' "${FX_A}" "${FX_A}" "${FX_A}" > "${V}/dup_id.json"
```

Toujours dans le même bloc de fixtures, juste après, déclarer le raccourci qui évite de répéter les deux chemins d'accord à chaque ligne. **Il doit être défini ici**, avant sa première utilisation à l'étape suivante :

```bash
# AGREE = le couple pubspec/patch-notes qui concorde sur FX_A. Seul
# VERSIONS_PATH varie d'une assertion a l'autre.
AGREE=("PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/agree/patch_notes.json")
```

Ensuite les assertions, à placer juste avant le `echo` qui précède le bloc `release_body.sh` :

```bash
assert_exit 1 "refuse un VERSIONS_PATH introuvable" \
  env "${AGREE[@]}" "VERSIONS_PATH=${FIXTURES}/missing/versions.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse un versions.json invalide" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/invalid.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse zero entree current" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/no_current.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse deux entrees current" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/two_current.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse un id current qui ne correspond pas" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/wrong_id.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse un notes current qui ne correspond pas" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/wrong_notes.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse des id dupliques" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/dup_id.json" ${VERIFY} "${FX_A}"
assert_contains "versions" "nomme le fichier de versions dans l'erreur" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/no_current.json" ${VERIFY} "${FX_A}"
```

Enfin, remplacer **l'assertion nominale existante** — celle libellée « accepte `${FX_A}` quand les deux fixtures concordent », qui n'a pas de `versions.json` cohérent — par sa version à trois fichiers. C'est elle qui couvre le cas passant, il n'y a donc pas d'assertion supplémentaire à ajouter pour cela :

```bash
assert_exit 0 "accepte ${FX_A} quand les trois fixtures concordent" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/ok.json" ${VERIFY} "${FX_A}"
```

- [ ] **Étape 3 : lancer le harnais pour vérifier qu'il échoue**

```bash
bash .github/scripts/test_scripts.sh
```

Attendu : les 8 nouvelles assertions en `FAIL` — le script ne connaît pas encore `VERSIONS_PATH`, donc il ignore la fixture fautive et sort `0` là où on attend `1`. L'assertion nominale remplacée, elle, reste `ok` : elle attend `0` et l'obtient, pour la mauvaise raison. C'est l'étape 6 qui la qualifiera.

- [ ] **Étape 4 : ajouter le garde-fou au script**

Dans `.github/scripts/verify_version.sh`, ajouter la variable après les deux existantes :

```bash
VERSIONS_PATH="${VERSIONS_PATH:-site/_site/versions.json}"
```

Compléter le bloc de commentaire d'en-tête, sous « Chemins surchargeables » :

```
#   VERSIONS_PATH     defaut site/_site/versions.json
```

Puis ajouter, **à la fin du fichier, juste avant le `echo` final de succès** :

```bash
# --- Coherence avec la source de verite du site ---
#
# Oublier l'entree versions.json ne produit aucune erreur visible : le site se
# deploie, s'affiche, et ment simplement sur la version courante. C'est
# exactement la panne restee silencieuse entre le 18 et le 19/08, ou 0.4.7
# etait en ligne et jouable pendant que la page d'accueil mettait v0.0.9 en
# vedette. Ce bloc la transforme en echec de pipeline avant le moindre build.

if [[ ! -f "${VERSIONS_PATH}" ]]; then
  echo "::error::Fichier introuvable : ${VERSIONS_PATH}"
  exit 1
fi

CURRENT_COUNT="$(jq '[.[] | select(.channel == "current")] | length' "${VERSIONS_PATH}" 2>/dev/null)"

if [[ -z "${CURRENT_COUNT}" ]]; then
  echo "::error::Impossible de lire ${VERSIONS_PATH} (JSON invalide ou fichier vide ?)."
  exit 1
fi

if [[ "${CURRENT_COUNT}" != "1" ]]; then
  echo "::error::${VERSIONS_PATH} contient ${CURRENT_COUNT} entree(s) channel=current, il en faut exactement 1."
  exit 1
fi

CURRENT_ID="$(jq -r '.[] | select(.channel == "current") | .id' "${VERSIONS_PATH}")"
CURRENT_NOTES="$(jq -r '.[] | select(.channel == "current") | .notes' "${VERSIONS_PATH}")"

if [[ "${CURRENT_ID}" != "v${VERSION}" ]]; then
  echo "::error::${VERSIONS_PATH} : l'entree current a id='${CURRENT_ID}', attendu 'v${VERSION}'. Le skill patch-notes-writer doit ajouter l'entree de cette version et retrograder la precedente en 'stable'."
  exit 1
fi

if [[ "${CURRENT_NOTES}" != "${VERSION}" ]]; then
  echo "::error::${VERSIONS_PATH} : l'entree current a notes='${CURRENT_NOTES}', attendu '${VERSION}'."
  exit 1
fi

TOTAL_IDS="$(jq 'length' "${VERSIONS_PATH}")"
UNIQUE_IDS="$(jq '[.[].id] | unique | length' "${VERSIONS_PATH}")"

if [[ "${TOTAL_IDS}" != "${UNIQUE_IDS}" ]]; then
  echo "::error::${VERSIONS_PATH} : ${TOTAL_IDS} entrees pour ${UNIQUE_IDS} id distincts. Chaque id est un dossier du VPS, il doit etre unique."
  exit 1
fi
```

Enfin, remplacer la ligne de succès finale par :

```bash
echo "Version ${VERSION} coherente : tag == ${PUBSPEC_PATH} == ${PATCH_NOTES_PATH}[0].version == ${VERSIONS_PATH} (current)"
```

- [ ] **Étape 5 : relancer le harnais**

```bash
bash .github/scripts/test_scripts.sh
```

Attendu : `52 ok, 0 echec(s)`.

- [ ] **Étape 6 : vérifier contre les fichiers réels**

```bash
bash .github/scripts/verify_version.sh 0.4.8
```

Attendu : **échec**, avec `l'entree current a id='v0.4.7', attendu 'v0.4.8'`. C'est le comportement voulu : `versions.json` est amorcé sur 0.4.7 et sera mis à jour par la Task 13. Vérifier ensuite que le cas cohérent passe :

```bash
bash .github/scripts/verify_version.sh 0.4.7
```

Attendu : échec sur `pubspec.yaml` (qui est en 0.4.8), **pas** sur `versions.json` — la preuve que les messages nomment bien le bon fichier fautif.

- [ ] **Étape 7 : commit**

```bash
git add site/_site/versions.json .github/scripts/verify_version.sh .github/scripts/test_scripts.sh
git commit -m "feat(site): source de verite des versions et garde-fou associe"
```

---

## Task 6 : le squelette du site — HTML, CSS, polices

**Files:**
- Create: `site/index.html`, `site/versions.html`, `site/notes.html`
- Create: `site/_site/style.css`
- Create: `site/_site/fonts/press-start-2p-latin.woff2`, `site/_site/fonts/vt323-latin.woff2`, `site/_site/fonts/OFL-press-start-2p.txt`, `site/_site/fonts/OFL-vt323.txt`

**Interfaces:**
- Consumes: rien.
- Produces: trois pages qui s'affichent complètement **sans aucun JavaScript**, avec un repli statique dans chaque `[data-slot]`. Le JS des Tasks 8 et 9 remplacera le contenu de ces conteneurs par `replaceChildren()`. Les points d'ancrage sont `document.body.dataset.page` (`home`, `versions`, `notes`) et les attributs `data-slot`.

- [ ] **Étape 1 : télécharger les polices**

L'URL woff2 n'est pas devinable : Google Fonts la fait varier selon la version de la police et l'agent utilisateur. Elle est donc lue dans la feuille de style renvoyée par l'API, puis suivie — le tout en une commande, sans recopie manuelle :

```bash
mkdir -p site/_site/fonts
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
for pair in "Press+Start+2P:press-start-2p-latin" "VT323:vt323-latin"; do
  family="${pair%%:*}"
  target="${pair##*:}"
  url="$(curl -sS -A "$UA" "https://fonts.googleapis.com/css2?family=${family}&display=swap" | grep -o 'https://[^)]*\.woff2' | head -1)"
  if [[ -z "$url" ]]; then echo "Aucune URL woff2 trouvee pour ${family}" >&2; exit 1; fi
  curl -sS -o "site/_site/fonts/${target}.woff2" "$url"
done
```

- [ ] **Étape 2 : vérifier que ce sont bien des woff2**

```bash
ls -l site/_site/fonts/
file site/_site/fonts/*.woff2 2>/dev/null || head -c 4 site/_site/fonts/press-start-2p-latin.woff2 | xxd
```

Attendu : deux fichiers non vides, quelques dizaines de Ko chacun, commençant par les octets `wOF2`. Un fichier de quelques centaines d'octets signifie qu'une page d'erreur HTML a été téléchargée à la place.

- [ ] **Étape 3 : récupérer les licences**

L'OFL exige que le texte de licence accompagne les fichiers redistribués.

```bash
curl -sS -o site/_site/fonts/OFL-press-start-2p.txt https://raw.githubusercontent.com/google/fonts/main/ofl/pressstart2p/OFL.txt
curl -sS -o site/_site/fonts/OFL-vt323.txt https://raw.githubusercontent.com/google/fonts/main/ofl/vt323/OFL.txt
head -1 site/_site/fonts/OFL-press-start-2p.txt
head -1 site/_site/fonts/OFL-vt323.txt
```

Attendu : chaque première ligne commence par `Copyright`.

- [ ] **Étape 4 : écrire `site/_site/style.css`**

```css
/* Hero's Draft — feuille de style du site vitrine.
   Palette : #0B493A et #EAF06A, plus les variations validees le 18/08.
   Deux polices : Press Start 2P pour les titres et libelles, VT323 pour le
   corps -- Press Start 2P est a chasse fixe et illisible sur un paragraphe,
   or les patch notes sont de vraies phrases longues. */

@font-face {
  font-family: 'Press Start 2P';
  src: url('fonts/press-start-2p-latin.woff2') format('woff2');
  font-display: swap;
}

@font-face {
  font-family: 'VT323';
  src: url('fonts/vt323-latin.woff2') format('woff2');
  font-display: swap;
}

:root {
  --bg:    #062E24;
  --panel: #0B493A;
  --deep:  #041D17;
  --dim:   #083C2F;
  --line:  #0F5C48;
  --line2: #12705A;
  --y:     #EAF06A;
  --y2:    #C2C955;
  --pale:  #F5F8C4;
  --mut:   #7FAE99;
  --mut2:  #8FC4AC;

  --title: 'Press Start 2P', 'Courier New', monospace;
  --body:  'VT323', 'Courier New', monospace;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  padding: 0 0 3rem;
  background: var(--bg);
  color: var(--mut2);
  font-family: var(--body);
  font-size: 20px;
  line-height: 1.45;
}

a { color: var(--y); }

/* ---- barre de navigation ---- */
.nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  flex-wrap: wrap;
  background: var(--deep);
  border-bottom: 3px solid var(--line);
  padding: 15px 26px;
}
.nav__logo { font-family: var(--title); color: var(--y); font-size: 12px; letter-spacing: 1px; text-decoration: none; }
.nav__links { display: flex; gap: 22px; }
.nav__links a { font-family: var(--title); font-size: 9px; color: var(--mut); text-decoration: none; }
.nav__links a[aria-current='page'] { color: var(--y); }

/* ---- bloc d'identite ---- */
.hero { text-align: center; padding: 52px 26px 44px; }
.hero__title {
  font-family: var(--title);
  color: var(--y);
  font-size: clamp(20px, 6vw, 34px);
  letter-spacing: 3px;
  margin: 0;
  text-shadow: 0 0 18px rgba(234, 240, 106, .35), 4px 4px 0 var(--deep);
}
.hero__kicker { font-family: var(--title); color: var(--y2); font-size: 10px; letter-spacing: 4px; margin: 18px 0 0; }
.hero__pitch { max-width: 560px; margin: 20px auto 0; font-size: 21px; line-height: 1.5; }

.cta { display: flex; gap: 18px; justify-content: center; margin-top: 34px; flex-wrap: wrap; }
.btn {
  font-family: var(--title);
  font-size: 11px;
  padding: 16px 22px;
  border: 3px solid var(--y);
  text-decoration: none;
  display: inline-block;
}
.btn--primary { background: var(--y); color: var(--bg); box-shadow: 5px 5px 0 var(--deep), 0 0 18px rgba(234, 240, 106, .45); }
.btn--ghost   { background: transparent; color: var(--y); box-shadow: 5px 5px 0 var(--deep); }
.btn small    { display: block; font-family: var(--body); font-size: 15px; margin-top: 8px; opacity: .75; }

/* ---- structure ---- */
.wrap { max-width: 820px; margin: 0 auto; padding: 0 26px; }
.section-title {
  font-family: var(--title);
  color: var(--y2);
  font-size: 11px;
  letter-spacing: 2px;
  border-bottom: 2px solid var(--line);
  padding-bottom: 10px;
  margin: 44px 0 18px;
}

/* ---- panneau facon fenetre de menu RPG ---- */
.panel {
  position: relative;
  background: linear-gradient(180deg, var(--line2) 0%, var(--panel) 100%);
  border: 3px solid var(--y);
  padding: 26px;
  box-shadow:
    inset 0 0 0 3px var(--deep),
    inset 0 0 0 6px var(--line2),
    0 0 16px rgba(234, 240, 106, .40),
    0 0 34px rgba(234, 240, 106, .16);
}
.panel::before, .panel::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 10px;
  background: var(--y);
  box-shadow: 0 0 9px rgba(234, 240, 106, .75);
}
.panel::before { top: -3px; left: -3px; }
.panel::after  { bottom: -3px; right: -3px; }
/* Empilement des panneaux de notes.html, sans style en ligne cote JS. */
.panel + .panel { margin-top: 22px; }

.badge {
  display: inline-block;
  font-family: var(--title);
  background: var(--y);
  color: var(--bg);
  font-size: 9px;
  padding: 6px 10px;
  letter-spacing: 1px;
}
.note__version { font-family: var(--title); color: var(--y); font-size: clamp(14px, 4vw, 22px); margin-top: 16px; text-shadow: 0 0 12px rgba(234, 240, 106, .45); }
.note__date    { font-size: 18px; margin-top: 8px; }
.note__category { font-family: var(--title); color: var(--pale); font-size: 10px; letter-spacing: 1px; margin: 22px 0 8px; }
.note__list    { margin: 0; padding-left: 22px; font-size: 19px; line-height: 1.5; }
.note__list li { margin-bottom: 7px; }
.link-more {
  display: inline-block;
  font-family: var(--title);
  margin-top: 20px;
  font-size: 9px;
  border-bottom: 2px solid var(--y);
  padding-bottom: 4px;
  text-decoration: none;
}

/* ---- grille de versions ---- */
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 14px; }
.card {
  background: var(--panel);
  border: 3px solid var(--deep);
  box-shadow: inset 0 0 0 2px var(--line);
  padding: 18px 13px;
  text-align: center;
  text-decoration: none;
  display: block;
}
.card__label { font-family: var(--title); color: var(--y); font-size: 14px; }
.card__meta  { color: var(--mut); font-size: 17px; margin-top: 9px; }
.grid--legacy .card { background: var(--dim); }
.grid--legacy .card__label { color: var(--y2); font-size: 12px; }

.align-right { text-align: right; margin-top: 16px; }

/* ---- messages de repli ---- */
.fallback { font-size: 19px; }
.fallback p { margin: 0 0 .75rem; }

@media (max-width: 600px) {
  body { font-size: 18px; }
  .grid { grid-template-columns: 1fr; }
}
```

- [ ] **Étape 5 : écrire `site/index.html`**

Chaque `[data-slot]` contient un repli **utilisable tel quel**. Le JS le remplacera en cas de succès et le laissera intact en cas d'échec — ce qui couvre à la fois « JavaScript désactivé » et « JavaScript actif mais `fetch` en échec ».

```html
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Hero's Draft — roguelike deckbuilder</title>
  <meta name="description" content="Hero's Draft, un roguelike deckbuilder. Jouez dans le navigateur ou téléchargez la version Windows.">
  <link rel="stylesheet" href="/_site/style.css">
  <script type="module" src="/_site/js/main.js"></script>
</head>
<body data-page="home">

  <nav class="nav">
    <a class="nav__logo" href="/">&#9670; HERO'S DRAFT</a>
    <div class="nav__links">
      <a href="/" aria-current="page">ACCUEIL</a>
      <a href="/versions.html">VERSIONS</a>
      <a href="/notes.html">NOTES</a>
    </div>
  </nav>

  <header class="hero">
    <h1 class="hero__title">HERO'S DRAFT</h1>
    <p class="hero__kicker">ROGUELIKE DECKBUILDER</p>
    <p class="hero__pitch">Choisissez votre héros, forgez votre deck run après run, et affrontez une carte du monde qui ne se répète jamais.</p>
    <div class="cta" data-slot="cta">
      <a class="btn btn--primary" href="/v0.4.7/">JOUER MAINTENANT</a>
      <a class="btn btn--ghost" href="https://github.com/Hex-Umbra/hero-s-draft/releases">TÉLÉCHARGER</a>
    </div>
  </header>

  <main class="wrap">

    <h2 class="section-title">QUOI DE NEUF</h2>
    <section class="panel" data-slot="latest-note">
      <div class="fallback">
        <p>Les notes de version n'ont pas pu être chargées.</p>
        <p><a href="https://github.com/Hex-Umbra/hero-s-draft/releases">Consulter les notes sur GitHub</a></p>
      </div>
    </section>

    <h2 class="section-title">VERSIONS RÉCENTES</h2>
    <div class="grid" data-slot="recent">
      <a class="card" href="/v0.4.7/">
        <div class="card__label">0.4.7</div>
        <div class="card__meta">actuelle</div>
      </a>
    </div>
    <p class="align-right"><a class="link-more" href="/versions.html">VOIR TOUTES LES VERSIONS &rarr;</a></p>

  </main>

</body>
</html>
```

- [ ] **Étape 6 : écrire `site/versions.html`**

```html
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Versions — Hero's Draft</title>
  <meta name="description" content="Toutes les versions et prototypes de Hero's Draft jouables dans le navigateur.">
  <link rel="stylesheet" href="/_site/style.css">
  <script type="module" src="/_site/js/main.js"></script>
</head>
<body data-page="versions">

  <nav class="nav">
    <a class="nav__logo" href="/">&#9670; HERO'S DRAFT</a>
    <div class="nav__links">
      <a href="/">ACCUEIL</a>
      <a href="/versions.html" aria-current="page">VERSIONS</a>
      <a href="/notes.html">NOTES</a>
    </div>
  </nav>

  <header class="hero">
    <h1 class="hero__title">VERSIONS</h1>
    <p class="hero__kicker">ARCHIVE JOUABLE</p>
    <p class="hero__pitch">Chaque version reste en ligne indéfiniment. Les prototypes de recherche sont antérieurs au jeu actuel.</p>
  </header>

  <main class="wrap" data-slot="versions">
    <div class="fallback">
      <p>La liste des versions n'a pas pu être chargée.</p>
      <p><a href="/v0.4.7/">Jouer à la dernière version connue</a></p>
    </div>
  </main>

</body>
</html>
```

- [ ] **Étape 7 : écrire `site/notes.html`**

```html
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Notes de version — Hero's Draft</title>
  <meta name="description" content="Historique complet des notes de version de Hero's Draft.">
  <link rel="stylesheet" href="/_site/style.css">
  <script type="module" src="/_site/js/main.js"></script>
</head>
<body data-page="notes">

  <nav class="nav">
    <a class="nav__logo" href="/">&#9670; HERO'S DRAFT</a>
    <div class="nav__links">
      <a href="/">ACCUEIL</a>
      <a href="/versions.html">VERSIONS</a>
      <a href="/notes.html" aria-current="page">NOTES</a>
    </div>
  </nav>

  <header class="hero">
    <h1 class="hero__title">NOTES DE VERSION</h1>
    <p class="hero__kicker">HISTORIQUE COMPLET</p>
  </header>

  <main class="wrap" data-slot="notes">
    <div class="fallback">
      <p>L'historique n'a pas pu être chargé.</p>
      <p><a href="https://github.com/Hex-Umbra/hero-s-draft/releases">Consulter les notes sur GitHub</a></p>
    </div>
  </main>

</body>
</html>
```

- [ ] **Étape 8 : vérifier au navigateur**

```bash
python -m http.server 8000 --directory site
```

Ouvrir `http://localhost:8000/`, `http://localhost:8000/versions.html`, `http://localhost:8000/notes.html`.

Attendu : les trois pages s'affichent dans le style validé, polices pixel comprises. Les replis sont visibles — c'est normal, aucun JS n'existe encore, et la console signale un 404 sur `/_site/js/main.js`. **Vérifier explicitement que les deux polices sont chargées** : onglet Réseau, deux requêtes `.woff2` en 200. Si le texte est en Courier, le chemin des `@font-face` est faux.

- [ ] **Étape 9 : commit**

```bash
git add site/
git commit -m "feat(site): squelette des trois pages, feuille de style et polices"
```

---

## Task 7 : `model.js` — la logique de jointure, testée

**Files:**
- Create: `site/package.json`
- Create: `site/_site/js/model.js`
- Create: `site/_site/js/model.test.js`
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: le schéma `versions.json` de la Task 5.
- Produces: les exports que `data.js`, `render.js` et `main.js` consommeront —
  `REPO_SLUG: string`, `REPO_URL: string`, `API_URL: string`,
  `findCurrent(versions): entry|null`, `groupByChannel(versions): {current, stable, legacy}`,
  `noteFor(entry, notes): note|null`, `playUrl(entry): string|null`,
  `notesUrl(entry): string|null`, `downloadUrl(entry): string|null`,
  `releaseUrl(entry): string|null`, `formatBytes(n): string|null`, `formatDate(iso): string|null`.
  Toutes les fonctions renvoient `null` plutôt que de lever, pour qu'un champ absent dégrade l'affichage sans casser la page.

- [ ] **Étape 1 : déclarer `site/` comme arbre de modules ES**

Créer `site/package.json` :

```json
{
  "name": "heros-draft-site",
  "private": true,
  "type": "module"
}
```

Ce fichier n'est **pas déployé** : il sert uniquement à ce que Node traite les `.js` de `site/` comme des modules ES, exactement comme le fait le navigateur avec `<script type="module">`. Il est exclu du rsync en Task 10.

- [ ] **Étape 2 : écrire les tests qui échouent**

Créer `site/_site/js/model.test.js` :

```js
import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  REPO_URL,
  findCurrent,
  groupByChannel,
  noteFor,
  playUrl,
  notesUrl,
  downloadUrl,
  releaseUrl,
  formatBytes,
  formatDate,
} from './model.js';

const VERSIONS = [
  { id: 'v0.4.7', label: '0.4.7', channel: 'current', date: '2026-08-18', notes: '0.4.7', windows: true },
  { id: 'v0.0.9', label: '0.0.9', channel: 'stable', date: null, notes: null, windows: false },
  { id: 'v3', label: 'Prototype V3', channel: 'legacy', date: null, notes: null, windows: false },
];

/* Entree dont l'id ne contient AUCUN numero de version : la seule facon de lui
   trouver sa patch note est de passer par le champ `notes`. Le schema decouple
   volontairement les deux -- c'est la raison d'etre du champ. */
const DECOUPLED = { id: 'vtest', label: 'Build de test', channel: 'stable', date: null, notes: '0.4.6', windows: false };

/* L'entree 0.0.9 est un PIEGE deliberé, et le coeur de ce fichier de tests.
   Le dossier v0.0.9 existe sur le serveur mais n'a aucune patch note : son
   build rapporte version 0.1.0, son nom est un numero de deploiement. Une
   implementation qui joindrait sur l'id -- en retirant le "v" -- trouverait
   cette entree et l'afficherait. C'est exactement la fausse association que
   le champ `notes` existe pour empecher, et c'est le mutant que le test
   "noteFor renvoie null quand notes vaut null" doit tuer. */
const NOTES = [
  { version: '0.4.7', date: '2026-07-26', title: "L'Equilibre des Effectifs", sections: [] },
  { version: '0.4.6', date: '2026-07-20', title: 'Autre chose', sections: [] },
  { version: '0.0.9', date: '2026-01-01', title: 'FAUX POSITIF — ne doit jamais s afficher', sections: [] },
];

test('findCurrent isole l unique entree courante', () => {
  assert.equal(findCurrent(VERSIONS).id, 'v0.4.7');
});

test('findCurrent renvoie null quand aucune entree n est courante', () => {
  assert.equal(findCurrent(VERSIONS.filter((v) => v.channel !== 'current')), null);
});

test('groupByChannel repartit les trois canaux', () => {
  const g = groupByChannel(VERSIONS);
  assert.equal(g.current.length, 1);
  assert.equal(g.stable.length, 1);
  assert.equal(g.legacy.length, 1);
});

test('groupByChannel place chaque entree dans le bon canal', () => {
  // Compter ne suffit pas : avec une entree par canal, une implementation qui
  // intervertirait current et legacy donnerait les memes trois comptes.
  const g = groupByChannel(VERSIONS);
  assert.equal(g.current[0].id, 'v0.4.7');
  assert.equal(g.stable[0].id, 'v0.0.9');
  assert.equal(g.legacy[0].id, 'v3');
});

test('groupByChannel ignore un canal inconnu sans lever', () => {
  const g = groupByChannel([...VERSIONS, { id: 'vX', channel: 'inconnu' }]);
  assert.equal(g.current.length + g.stable.length + g.legacy.length, 3);
});

test('noteFor joint sur le champ notes, pas sur l id', () => {
  assert.equal(noteFor(VERSIONS[0], NOTES).title, "L'Equilibre des Effectifs");
  // Direction positive discriminante : l'id "vtest" ne ressemble a aucune
  // version, donc seule une jointure par `notes` peut trouver la 0.4.6.
  assert.equal(noteFor(DECOUPLED, NOTES).title, 'Autre chose');
});

test('noteFor renvoie null quand notes vaut null, MEME si l id correspond a une note', () => {
  // Le test qui compte. VERSIONS[1] a pour id "v0.0.9" et NOTES contient une
  // entree de version "0.0.9" : une implementation qui joindrait sur l'id
  // retournerait le FAUX POSITIF au lieu de null, et ce test echouerait.
  // C'est la seule assertion du fichier qui distingue les deux strategies de
  // jointure -- ne pas retirer l'entree piege de NOTES.
  assert.equal(noteFor(VERSIONS[1], NOTES), null);
  assert.equal(noteFor(VERSIONS[2], NOTES), null);
});

test('noteFor renvoie null quand la cle ne correspond a aucune note', () => {
  assert.equal(noteFor({ id: 'v9.9.9', notes: '9.9.9' }, NOTES), null);
});

test('noteFor tolere une entree absente ou des notes non chargees', () => {
  assert.equal(noteFor(null, NOTES), null);
  assert.equal(noteFor(VERSIONS[0], null), null);
  assert.equal(noteFor(VERSIONS[0], undefined), null);
});

test('findCurrent et groupByChannel tolerent une valeur non tableau', () => {
  // Le contrat du module est de degrader l'affichage, jamais de lever : un
  // versions.json illisible ne doit pas casser la page.
  assert.equal(findCurrent(null), null);
  assert.equal(findCurrent(undefined), null);
  const g = groupByChannel(undefined);
  assert.equal(g.current.length + g.stable.length + g.legacy.length, 0);
});

test('playUrl construit le chemin du dossier', () => {
  assert.equal(playUrl(VERSIONS[0]), '/v0.4.7/');
  assert.equal(playUrl(VERSIONS[2]), '/v3/');
});

test('notesUrl pointe vers les patch notes embarquees dans le build', () => {
  assert.equal(notesUrl(VERSIONS[0]), '/v0.4.7/assets/assets/data/patch_notes.json');
  assert.equal(notesUrl(VERSIONS[2]), '/v3/assets/assets/data/patch_notes.json');
});

test('playUrl et notesUrl renvoient null au lieu de lever sur une entree vide', () => {
  for (const bad of [null, undefined, {}]) {
    assert.equal(playUrl(bad), null);
    assert.equal(notesUrl(bad), null);
  }
});

test('downloadUrl se deduit du seul id', () => {
  assert.equal(
    downloadUrl(VERSIONS[0]),
    `${REPO_URL}/releases/download/v0.4.7/heros-draft-v0.4.7-windows.zip`,
  );
});

test('releaseUrl pointe sur le tag, pas sur le telechargement', () => {
  assert.equal(releaseUrl(VERSIONS[0]), `${REPO_URL}/releases/tag/v0.4.7`);
});

test('downloadUrl et releaseUrl renvoient null sans release GitHub', () => {
  assert.equal(downloadUrl(VERSIONS[1]), null);
  assert.equal(releaseUrl(VERSIONS[1]), null);
  assert.equal(downloadUrl(null), null);
  assert.equal(releaseUrl(undefined), null);
});

test('formatBytes arrondit en megaoctets', () => {
  assert.equal(formatBytes(58_600_000), '59 Mo');
});

test('formatBytes rejette les valeurs inexploitables', () => {
  assert.equal(formatBytes(0), null);
  assert.equal(formatBytes(null), null);
  assert.equal(formatBytes('58'), null);
  assert.equal(formatBytes(Number.NaN), null);
});

test('formatDate rend une date francaise lisible', () => {
  assert.equal(formatDate('2026-08-18'), '18 août 2026');
});

test('formatDate tolere null et une date invalide', () => {
  assert.equal(formatDate(null), null);
  assert.equal(formatDate('pas-une-date'), null);
});
```

- [ ] **Étape 3 : lancer les tests pour vérifier qu'ils échouent**

```bash
cd site && node --test
```

Attendu : échec au chargement, `Cannot find module .../model.js`.

- [ ] **Étape 4 : écrire `model.js`**

Créer `site/_site/js/model.js` :

```js
/* Logique pure du site : jointure, groupement, URL derivees, formats.
   AUCUN acces reseau, AUCUNE manipulation du DOM -- c'est ce qui rend ce
   module testable par `node --test` sans navigateur ni serveur.

   Toutes les fonctions renvoient null plutot que de lever : un champ absent
   doit degrader l'affichage, jamais casser la page. */

export const REPO_SLUG = 'Hex-Umbra/hero-s-draft';
export const REPO_URL = `https://github.com/${REPO_SLUG}`;
export const API_URL = `https://api.github.com/repos/${REPO_SLUG}`;

const CHANNELS = ['current', 'stable', 'legacy'];

/** L'unique entree marquee `current`, ou null. */
export function findCurrent(versions) {
  if (!Array.isArray(versions)) return null;
  return versions.find((v) => v && v.channel === 'current') ?? null;
}

/** Repartit les entrees par canal. Un canal inconnu est ignore. */
export function groupByChannel(versions) {
  const groups = { current: [], stable: [], legacy: [] };
  if (!Array.isArray(versions)) return groups;
  for (const v of versions) {
    if (v && CHANNELS.includes(v.channel)) groups[v.channel].push(v);
  }
  return groups;
}

/* La jointure se fait sur le champ `notes`, JAMAIS sur `id`.

   Les quatorze dossiers historiques du VPS rapportent tous version 0.1.0 dans
   leur version.json : leurs noms sont des numeros de deploiement, pas des
   numeros de version. Joindre sur l'id associerait v0.0.1 a v0.0.4 a des patch
   notes qui decrivent d'autres builds, et ne trouverait rien pour v0.0.5 a
   v0.0.9 -- absentes de patch_notes.json. */
export function noteFor(entry, notes) {
  if (!entry || entry.notes == null || !Array.isArray(notes)) return null;
  return notes.find((n) => n && n.version === entry.notes) ?? null;
}

export function playUrl(entry) {
  return entry?.id ? `/${entry.id}/` : null;
}

/** Les patch notes sont embarquees dans chaque build web par Flutter. */
export function notesUrl(entry) {
  return entry?.id ? `/${entry.id}/assets/assets/data/patch_notes.json` : null;
}

/* L'URL du zip n'est jamais stockee : le tag vaut l'id et release.yml nomme
   l'asset ainsi. Une donnee derivable n'est pas une donnee a maintenir. */
export function downloadUrl(entry) {
  if (!entry?.windows || !entry.id) return null;
  return `${REPO_URL}/releases/download/${entry.id}/heros-draft-${entry.id}-windows.zip`;
}

export function releaseUrl(entry) {
  if (!entry?.windows || !entry.id) return null;
  return `${REPO_URL}/releases/tag/${entry.id}`;
}

export function formatBytes(bytes) {
  if (typeof bytes !== 'number' || !Number.isFinite(bytes) || bytes <= 0) return null;
  return `${Math.round(bytes / 1_000_000)} Mo`;
}

export function formatDate(iso) {
  if (typeof iso !== 'string' || iso === '') return null;
  const date = new Date(`${iso}T00:00:00Z`);
  if (Number.isNaN(date.getTime())) return null;
  return new Intl.DateTimeFormat('fr-FR', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(date);
}
```

- [ ] **Étape 5 : relancer les tests**

```bash
cd site && node --test
```

Attendu : `pass 20`, `fail 0`.

- [ ] **Étape 6 : brancher les tests sur les deux portes de qualité**

Dans `.github/workflows/ci.yml`, ajouter après l'étape `flutter test` et avant `bash .github/scripts/test_scripts.sh` :

```yaml
      # Node est preinstalle sur ubuntu-latest : aucune action tierce
      # supplementaire a epingler. La version est affichee pour que la
      # moindre derive de l'image runner soit visible dans les logs.
      - run: node --version

      # Lance depuis site/ sans argument de chemin : c'est la decouverte par
      # defaut de Node, qui trouve tout *.test.js de l'arborescence. Passer le
      # repertoire en argument (`node --test site/_site/js/`) echoue -- Node
      # tente alors de charger le repertoire comme module d'entree.
      - name: Tests de la logique du site
        working-directory: site
        run: node --test
```

Ajouter **les mêmes deux étapes** au job `quality` de `.github/workflows/release.yml`, au même endroit.

- [ ] **Étape 7 : vérifier la syntaxe des deux workflows**

```bash
python -c "import yaml; [yaml.safe_load(open(p,encoding='utf-8')) for p in ('.github/workflows/ci.yml','.github/workflows/release.yml')]; print('YAML OK')"
```

- [ ] **Étape 8 : commit**

```bash
git add site/package.json site/_site/js/ .github/workflows/ci.yml .github/workflows/release.yml
git commit -m "feat(site): logique de jointure des versions, testee par node --test"
```

---

## Task 8 : `data.js`, `render.js`, `main.js` — l'accueil vivant

**Files:**
- Create: `site/_site/js/data.js`, `site/_site/js/render.js`, `site/_site/js/main.js`

**Interfaces:**
- Consumes: tous les exports de `model.js` (Task 7), les `[data-slot]` du HTML (Task 6).
- Produces: `data.js` exporte `loadVersions(): Promise<Array>`, `loadNotes(current): Promise<Array>`, `loadZipSize(entry): Promise<number|null>`. `render.js` exporte `versionCard(entry, note): HTMLElement`, `noteBlock(note, opts): HTMLElement`, `ctaButtons(current, size): DocumentFragment`, `sectionTitle(text): HTMLElement`. Ces noms sont réutilisés tels quels par la Task 9.

- [ ] **Étape 1 : écrire `data.js`**

```js
/* Acces reseau, et rien d'autre. Aucune logique metier ici : elle est dans
   model.js, ou elle est testable sans serveur. */

import { API_URL, notesUrl } from './model.js';

async function fetchJson(url) {
  const response = await fetch(url, { headers: { Accept: 'application/json' } });
  if (!response.ok) throw new Error(`${url} a repondu ${response.status}`);
  return response.json();
}

/** La source de verite du site. Un echec ici laisse le repli statique en place. */
export function loadVersions() {
  return fetchJson('/_site/versions.json');
}

/* Les patch notes sont lues dans le dossier de la version courante plutot que
   depuis une copie a la racine : le chemin est immuable pour une version
   donnee, donc le cache navigateur joue a plein sans invalidation a gerer, et
   le pipeline n'a aucune ligne a ajouter. */
export function loadNotes(current) {
  const url = notesUrl(current);
  if (!url) return Promise.reject(new Error('Aucune version courante.'));
  return fetchJson(url);
}

/* Amelioration progressive : le poids du zip n'existe pas au moment ou
   l'entree versions.json est ecrite, puisque le build n'a pas eu lieu. On le
   demande a l'API GitHub, et on s'en passe si elle ne repond pas -- le lien de
   telechargement, lui, est construit sans elle et fonctionne toujours.

   /releases/latest serait inutilisable : toutes nos releases sont des
   pre-releases, et cet endpoint les ignore. */
export async function loadZipSize(entry) {
  if (!entry?.windows || !entry.id) return null;
  try {
    const release = await fetchJson(`${API_URL}/releases/tags/${entry.id}`);
    const asset = (release.assets ?? []).find((a) => a?.name?.endsWith('-windows.zip'));
    return asset?.size ?? null;
  } catch {
    return null;
  }
}
```

- [ ] **Étape 2 : écrire `render.js`**

```js
/* Fonctions pures : donnees -> HTMLElement. Aucun fetch, aucun etat global.

   Le contenu textuel passe toujours par textContent, jamais par innerHTML :
   les patch notes viennent d'un JSON, et une donnee n'a pas a pouvoir devenir
   du balisage. */

import {
  downloadUrl,
  formatBytes,
  formatDate,
  playUrl,
  releaseUrl,
} from './model.js';

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text != null) node.textContent = text;
  return node;
}

function link(href, className, text) {
  const node = el('a', className, text);
  node.href = href;
  return node;
}

/** Une carte de version cliquable. `note` peut etre null. */
export function versionCard(entry, note) {
  const card = link(playUrl(entry), 'card');
  card.append(el('div', 'card__label', entry.label ?? entry.id));

  const meta = note?.title ?? (entry.channel === 'current' ? 'actuelle' : formatDate(entry.date));
  if (meta) card.append(el('div', 'card__meta', meta));

  return card;
}

/** Le panneau d'une patch note. `opts.limit` borne le nombre de sections. */
export function noteBlock(note, opts = {}) {
  const wrapper = document.createElement('div');

  if (opts.badge) wrapper.append(el('span', 'badge', opts.badge));

  wrapper.append(el('div', 'note__version', `V ${note.version} — ${note.title}`));

  const date = formatDate(note.date);
  if (date) wrapper.append(el('div', 'note__date', date));

  const sections = opts.limit ? note.sections.slice(0, opts.limit) : note.sections;
  for (const section of sections) {
    wrapper.append(el('div', 'note__category', `${section.emoji} ${section.category}`));
    const list = el('ul', 'note__list');
    for (const entry of section.entries) list.append(el('li', null, entry));
    wrapper.append(list);
  }

  if (opts.moreHref) {
    wrapper.append(link(opts.moreHref, 'link-more', opts.moreLabel ?? 'VOIR TOUT'));
  }

  return wrapper;
}

/** Les deux boutons d'appel a l'action de l'accueil. `size` peut etre null. */
export function ctaButtons(current, size) {
  const fragment = document.createDocumentFragment();

  const play = link(playUrl(current), 'btn btn--primary', 'JOUER MAINTENANT');
  play.append(el('small', null, `version ${current.label} · navigateur`));
  fragment.append(play);

  const zip = downloadUrl(current);
  if (zip) {
    const weight = formatBytes(size);
    const download = link(zip, 'btn btn--ghost', 'TÉLÉCHARGER');
    download.append(el('small', null, weight ? `Windows · ${weight}` : 'Windows'));
    fragment.append(download);
  } else {
    const release = releaseUrl(current) ?? 'https://github.com/Hex-Umbra/hero-s-draft/releases';
    fragment.append(link(release, 'btn btn--ghost', 'RELEASES'));
  }

  return fragment;
}

export function sectionTitle(text) {
  return el('h2', 'section-title', text);
}
```

- [ ] **Étape 3 : écrire `main.js`**

```js
/* Point d'entree unique des trois pages. Aiguille sur body[data-page].

   Regle de degradation : chaque [data-slot] du HTML contient deja un repli
   utilisable. On ne le remplace qu'en cas de succes. Un echec de fetch laisse
   donc une page complete et cliquable, sans avoir a ecrire le moindre message
   d'erreur -- et cela couvre aussi le cas ou JavaScript est desactive. */

import { loadNotes, loadVersions, loadZipSize } from './data.js';
import { findCurrent, noteFor } from './model.js';
import { ctaButtons, noteBlock, versionCard } from './render.js';

const RECENT_COUNT = 3;
const HOME_SECTIONS = 2;

function slot(name) {
  return document.querySelector(`[data-slot="${name}"]`);
}

async function renderHome(versions) {
  const current = findCurrent(versions);
  if (!current) return;

  const size = await loadZipSize(current);
  slot('cta')?.replaceChildren(ctaButtons(current, size));

  const recent = slot('recent');
  if (recent) {
    const cards = versions.slice(0, RECENT_COUNT).map((entry) => versionCard(entry, null));
    recent.replaceChildren(...cards);
  }

  // Le bloc de notes est traite a part : son echec ne doit pas emporter le
  // reste de la page, qui est deja rendu a ce stade.
  try {
    const notes = await loadNotes(current);
    const note = noteFor(current, notes);
    if (!note) return;
    slot('latest-note')?.replaceChildren(
      noteBlock(note, {
        badge: 'DERNIÈRE VERSION',
        limit: HOME_SECTIONS,
        moreHref: '/notes.html',
        moreLabel: `VOIR TOUTES LES NOTES (${notes.length} VERSIONS) →`,
      }),
    );
  } catch (error) {
    console.error(error);
  }
}

const PAGES = { home: renderHome };

async function boot() {
  const render = PAGES[document.body.dataset.page];
  if (!render) return;
  try {
    await render(await loadVersions());
  } catch (error) {
    console.error(error);
  }
}

boot();
```

- [ ] **Étape 4 : vérifier au navigateur**

```bash
python -m http.server 8000 --directory site
```

Sur `http://localhost:8000/` :

- le bouton principal porte « version 0.4.7 · navigateur » et pointe `/v0.4.7/` ;
- le panneau « quoi de neuf » affiche `V 0.4.7 — L'Équilibre des Effectifs`, la date, **deux** sections, et le lien « VOIR TOUTES LES NOTES (34 VERSIONS) » ;
- trois cartes de versions récentes ;
- la console ne montre **aucune** erreur autre qu'un éventuel échec de l'API GitHub.

Le chargement des patch notes passe par `/v0.4.7/assets/assets/data/patch_notes.json`, qui n'existe pas en local. Pour le tester réellement, créer l'arborescence à partir du fichier du dépôt :

```bash
mkdir -p site/v0.4.7/assets/assets/data
cp assets/data/patch_notes.json site/v0.4.7/assets/assets/data/
```

- [ ] **Étape 5 : provoquer les trois dégradations**

1. Renommer `site/_site/versions.json` → recharger. Attendu : **le repli statique reste affiché**, page complète, liens cliquables, une erreur en console. Restaurer le fichier.
2. Supprimer `site/v0.4.7/` → recharger. Attendu : boutons et cartes rendus normalement, **seul** le panneau de notes reste sur son repli GitHub.
3. Désactiver JavaScript dans le navigateur → recharger. Attendu : les trois replis, tous cliquables.

- [ ] **Étape 6 : nettoyer les fichiers de test local**

```bash
rm -rf site/v0.4.7
```

Ce dossier ne doit **jamais** être commité : il masquerait un vrai défaut de chemin.

- [ ] **Étape 7 : commit**

```bash
git status --short site/
git add site/_site/js/
git commit -m "feat(site): chargement, rendu et page d'accueil pilotee par les donnees"
```

Vérifier avant le commit que `git status` ne montre aucun `site/v0.4.7/`.

---

## Task 9 : les pages versions et notes

**Files:**
- Modify: `site/_site/js/main.js`

**Interfaces:**
- Consumes: `versionCard`, `noteBlock`, `sectionTitle` (Task 8), `groupByChannel`, `noteFor` (Task 7).
- Produces: rien de nouveau. Dernière tâche à toucher au JS.

- [ ] **Étape 1 : ajouter les deux fonctions de rendu**

Dans `site/_site/js/main.js`, insérer avant la constante `PAGES` :

```js
const CHANNEL_TITLES = {
  current: 'VERSION ACTUELLE',
  stable: 'VERSIONS STABLES',
  legacy: 'PROTOTYPES DE RECHERCHE',
};

async function renderVersions(versions) {
  const target = slot('versions');
  if (!target) return;

  const current = findCurrent(versions);
  const groups = groupByChannel(versions);

  // Les patch notes enrichissent les cartes quand elles sont disponibles, mais
  // leur absence ne doit rien empecher : quatorze des quinze entrees n'en ont
  // de toute facon aucune.
  let notes = [];
  try {
    if (current) notes = await loadNotes(current);
  } catch (error) {
    console.error(error);
  }

  const blocks = [];
  for (const [channel, title] of Object.entries(CHANNEL_TITLES)) {
    const entries = groups[channel];
    if (entries.length === 0) continue;

    blocks.push(sectionTitle(title));

    const grid = document.createElement('div');
    grid.className = channel === 'legacy' ? 'grid grid--legacy' : 'grid';
    grid.append(...entries.map((entry) => versionCard(entry, noteFor(entry, notes))));
    blocks.push(grid);
  }

  // Un resultat vide doit laisser le repli statique en place : une page vide
  // est pire qu'une page perimee.
  if (blocks.length === 0) return;

  target.replaceChildren(...blocks);
}

async function renderNotes(versions) {
  const target = slot('notes');
  const current = findCurrent(versions);
  if (!target || !current) return;

  const notes = await loadNotes(current);

  const blocks = notes.map((note) => {
    const panel = document.createElement('section');
    panel.className = 'panel';
    panel.append(noteBlock(note, {}));
    return panel;
  });

  if (blocks.length === 0) return;

  target.replaceChildren(...blocks);
}
```

- [ ] **Étape 2 : enregistrer les deux pages**

Remplacer la constante `PAGES` :

```js
const PAGES = { home: renderHome, versions: renderVersions, notes: renderNotes };
```

- [ ] **Étape 3 : compléter les deux lignes d'import**

Ces deux fonctions ne servaient à aucune des pages de la Task 8. Remplacer :

```js
import { findCurrent, noteFor } from './model.js';
import { ctaButtons, noteBlock, versionCard } from './render.js';
```

par :

```js
import { findCurrent, groupByChannel, noteFor } from './model.js';
import { ctaButtons, noteBlock, sectionTitle, versionCard } from './render.js';
```

- [ ] **Étape 4 : vérifier au navigateur**

Recréer les patch notes locales, puis servir :

```bash
mkdir -p site/v0.4.7/assets/assets/data && cp assets/data/patch_notes.json site/v0.4.7/assets/assets/data/
python -m http.server 8000 --directory site
```

Sur `http://localhost:8000/versions.html` :
- trois sections : version actuelle (1 carte), versions stables (9 cartes), prototypes (5 cartes) ;
- la carte `0.4.7` porte le titre de sa patch note ; **aucune** carte legacy ne porte de titre ;
- les cartes legacy ont le fond plus sourd de `.grid--legacy`.

Sur `http://localhost:8000/notes.html` : **34 panneaux**, du plus récent au plus ancien. Vérifier dans la console :

```js
document.querySelectorAll('main .panel').length
```

Attendu : `34`.

- [ ] **Étape 5 : vérifier le rendu mobile**

Outils de développement → largeur 375 px. Attendu : grilles sur une colonne, titre non tronqué, aucun débordement horizontal.

- [ ] **Étape 6 : nettoyer et commiter**

```bash
rm -rf site/v0.4.7
git status --short site/
git add site/_site/js/main.js
git commit -m "feat(site): pages d'archive des versions et d'historique des notes"
```

---

## Task 10 : `site.yml` inerte, et la sonde d'écriture en racine

**Files:**
- Create: `.github/workflows/site.yml`

**Interfaces:**
- Consumes: les secrets `VPS_SSH_KEY`, `VPS_KNOWN_HOSTS`, `VPS_USER`, `VPS_HOST`.
- Produces: un workflow appelable par `workflow_call`, que la Task 11 branchera dans `release.yml`.

> Cette tâche **est** l'étape 0 de la spec, déplacée sur GitHub Actions parce que `rsync` est absent de la machine Windows. Elle est sans danger : ce chemin n'a aucun `--delete`, aucun appelant, et un refus de `rrsync` échoue sans rien écrire.

- [ ] **Étape 1 : écrire le workflow**

Créer `.github/workflows/site.yml` :

```yaml
name: Deploy site

# Ni `push`, ni `pull_request` : le commit de preparation de release modifie
# versions.json, donc un declencheur `push` annoncerait la nouvelle version
# AVANT que son dossier existe. Un lien vers un dossier absent renvoie 500 --
# pas 404 -- a cause du try_files de nginx. `workflow_call` garantit l'ordre.
on:
  workflow_dispatch:
  workflow_call:

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          ref: ${{ github.sha }}

      - uses: webfactory/ssh-agent@e83874834305fe9a4a2997156cb26c5de65a8555 # v0.10.0
        with:
          ssh-private-key: ${{ secrets.VPS_SSH_KEY }}

      - name: Cle d'hote connue
        run: |
          set -euo pipefail
          mkdir -p ~/.ssh && chmod 700 ~/.ssh
          echo "${{ secrets.VPS_KNOWN_HOSTS }}" >> ~/.ssh/known_hosts
          chmod 600 ~/.ssh/known_hosts

      # AUCUN --delete SUR CE CHEMIN, JAMAIS.
      #
      # Contrairement a deploy-web, qui ecrit dans un dossier de version neuf,
      # ce job ecrit dans la RACINE CONFINEE elle-meme -- la ou vivent les
      # quinze dossiers de versions. Un --delete les effacerait tous en une
      # commande. Le cout de son absence est nul : un fichier de site supprime
      # du depot survit sur le serveur sans que personne ne le reference.
      #
      # Trois exclusions, toutes justifiees :
      #   nginx.reference.conf  document interne, ne doit pas etre servi
      #   package.json          n'existe que pour que Node lise les .js en ESM
      #   *.test.js             tests, sans utilite pour un visiteur
      - name: rsync du site vers la racine du VPS
        run: |
          set -euo pipefail
          rsync -avz \
            --exclude='nginx.reference.conf' \
            --exclude='package.json' \
            --exclude='*.test.js' \
            site/ \
            "${{ secrets.VPS_USER }}@${{ secrets.VPS_HOST }}:./"
```

- [ ] **Étape 2 : vérifier la syntaxe et l'absence de `--delete`**

```bash
python -c "import yaml; d=yaml.safe_load(open('.github/workflows/site.yml',encoding='utf-8')); print(sorted(d['jobs']))"
grep -n -- '--delete' .github/workflows/site.yml
```

Attendu : `['deploy']`, puis **deux lignes, toutes deux commençant par `#`** — les deux mentions du commentaire d'avertissement. Aucune ligne active ne doit contenir `--delete`.

- [ ] **Étape 3 : pousser sur `main`**

```bash
git add .github/workflows/site.yml
git commit -m "feat(ci): workflow de deploiement du site"
git push
```

`workflow_dispatch` n'apparaît dans l'interface que si le workflow est sur la branche par défaut. Le workflow reste **inerte** : aucun déclencheur automatique, aucun appelant.

- [ ] **Étape 4 : lancer la sonde**

Onglet Actions → `Deploy site` → « Run workflow » sur `main`.

**C'est ici que se joue le seul inconnu structurel du chantier** : la commande forcée est `rrsync -wo /var/www/prototypes`, et rien ne prouve encore qu'elle accepte une cible vide pour écrire dans la racine confinée.

Si le job échoue sur un refus de chemin, essayer dans l'ordre : `:.` puis `:""`. Si aucune forme ne passe, la commande forcée du VPS doit être revue — **s'arrêter et le signaler** plutôt que d'ajouter un contournement.

- [ ] **Étape 5 : vérifier de l'extérieur**

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://heros-draft.vilarserver.com/
curl -sS -o /dev/null -w '%{http_code}\n' https://heros-draft.vilarserver.com/_site/style.css
curl -sS -o /dev/null -w '%{http_code}\n' https://heros-draft.vilarserver.com/_site/versions.json
curl -sS -o /dev/null -w '%{http_code}\n' https://heros-draft.vilarserver.com/versions.html
curl -sS -o /dev/null -w '%{http_code}\n' https://heros-draft.vilarserver.com/nginx.reference.conf
```

Attendu : `200` sur les quatre premières, **`404` sur la dernière** — la preuve que l'exclusion fonctionne.

- [ ] **Étape 6 : vérifier que rien n'a été détruit**

```bash
for v in v0.4.8 v0.0.9 v0.0.1 v5 v1; do printf '%-8s ' "$v"; curl -sS -o /dev/null -w '%{http_code}\n' "https://heros-draft.vilarserver.com/$v/"; done
```

Attendu : `200` partout. **Un seul `404` ou `500` ici signifie qu'un `--delete` s'est glissé quelque part — arrêter immédiatement.**

- [ ] **Étape 7 : ouvrir le site dans un navigateur**

`https://heros-draft.vilarserver.com/` doit afficher l'accueil pixel, avec `0.4.7` en vedette et ses vraies patch notes — celles-ci étant maintenant réellement servies depuis `/v0.4.7/assets/assets/data/patch_notes.json`.

---

## Task 11 : brancher `deploy-site` dans `release.yml`

**Files:**
- Modify: `.github/workflows/release.yml`

**Interfaces:**
- Consumes: `site.yml` (Task 10), le job `smoke-test` (Task 3).
- Produces: la chaîne complète `verify-version → build → deploy-web → smoke-test → deploy-site → notify-discord`.

- [ ] **Étape 1 : ajouter le job `deploy-site`**

Insérer dans `.github/workflows/release.yml`, après le job `smoke-test` :

```yaml
  # Appele en workflow reutilisable plutot que duplique : une seule definition
  # du deploiement du site, partagee avec le lancement manuel.
  # `needs: smoke-test` garantit que le site n'annonce jamais une version dont
  # personne n'a verifie qu'elle se charge.
  deploy-site:
    needs: [verify-version, smoke-test]
    uses: ./.github/workflows/site.yml
    secrets: inherit
```

- [ ] **Étape 2 : rebrancher `notify-discord` derrière le site**

Remplacer la ligne `needs:` du job `notify-discord` par :

```yaml
    needs: [verify-version, deploy-site, release-windows]
```

`deploy-site` dépendant lui-même de `smoke-test`, la garantie du lot 1 est conservée et s'enrichit : quand le message part, la version est servie **et** listée sur le site.

- [ ] **Étape 3 : vérifier la syntaxe et le graphe**

```bash
python -c "
import yaml
d = yaml.safe_load(open('.github/workflows/release.yml', encoding='utf-8'))
for name, job in sorted(d['jobs'].items()):
    print(f\"{name:16} needs={job.get('needs', [])}\")
"
```

Attendu :

```
build-web        needs=['verify-version', 'quality']
build-windows    needs=['verify-version', 'quality']
deploy-site      needs=['verify-version', 'smoke-test']
deploy-web       needs=['verify-version', 'build-web']
notify-discord   needs=['verify-version', 'deploy-site', 'release-windows']
quality          needs=[]
release-windows  needs=['verify-version', 'build-windows']
smoke-test       needs=['verify-version', 'deploy-web']
verify-version   needs=[]
```

- [ ] **Étape 4 : commit et push**

```bash
git add .github/workflows/release.yml
git commit -m "feat(ci): deploiement du site dans la chaine de release"
git push
```

- [ ] **Étape 5 : vérifier que la CI reste verte**

Onglet Actions → le run `CI` doit être vert : `dart analyze`, `flutter test`, `node --test` et les 52 assertions du harnais.

---

## Task 12 : la documentation qui doit suivre

**Files:**
- Create: `site/nginx.reference.conf`
- Modify: `CLAUDE.md`
- Modify: `.claude/skills/patch-notes-writer/SKILL.md`
- Modify: `docs/INDEX.md`

**Interfaces:** aucune. Tâche documentaire, mais **bloquante avant la Task 13** : sans elle, la compétence `patch-notes-writer` n'écrira pas l'entrée `versions.json` et le garde-fou de la Task 5 fera échouer la release.

- [ ] **Étape 1 : versionner le contrat nginx**

Copier la configuration servie, avec un en-tête sans ambiguïté :

```bash
cp "../Prototypes/Web/nginx_prototypes.conf" site/nginx.reference.conf
```

Puis insérer en tête du fichier :

```
# MIROIR EN LECTURE SEULE -- NE PAS DEPLOYER, NE PAS EDITER POUR PRODUIRE UN EFFET.
#
# La verite est le fichier installe sur le VPS. Cette copie est versionnee
# parce que le site depend du comportement exact de deux blocs :
#
#   location /                    sert index.html, versions.html, notes.html et
#                                 tout /_site/ depuis la racine.
#   location ~ ^/(v[0-9][^/]*)    sert chaque dossier de version en SPA. Un
#                                 dossier ABSENT y produit un HTTP 500, pas un
#                                 404 : try_files boucle sur une cible de repli
#                                 qui n'existe pas non plus. C'est pourquoi
#                                 versions.json ne doit lister que des dossiers
#                                 reellement en ligne.
#
# Le job de deploiement exclut ce fichier du rsync.
```

- [ ] **Étape 2 : mettre à jour `CLAUDE.md`**

Dans la section « Repo-Specific Conventions », remplacer la phrase décrivant le périmètre de `patch-notes-writer` par :

```
- **`patch_notes.json` is agent-managed**: never hand-edit it. It is maintained by the `patch-notes-writer` skill (`.claude/skills/patch-notes-writer/SKILL.md`), which prepends a new semver entry, writes player-facing French only, keeps `pubspec.yaml`'s `version:` field in sync with it, and adds the matching `current` entry to `site/_site/versions.json` while demoting the previous one to `stable`. Those three files carry the version number and must always move together in a single commit: `verify_version.sh` fails the release if any of them disagrees. The skill also refreshes three hardcoded fallback links, in `site/index.html` and `site/versions.html`, to match.
```

Ajouter également, dans la section « Architecture », après le bloc « UI (Flutter) » :

```
- **Showcase site** — `site/` — a static site served from the VPS root, with no build step and no npm dependency. `site/_site/versions.json` is its source of truth; `site/_site/js/model.js` holds the pure logic and is tested with `node --test` run from `site/`. Deployed by `.github/workflows/site.yml`, never by hand. No link to the game code.
```

- [ ] **Étape 3 : mettre à jour la compétence**

Dans `.claude/skills/patch-notes-writer/SKILL.md`, étendre le périmètre à `site/_site/versions.json` avec la règle exacte :

```
Après avoir écrit l'entrée de patch notes et mis `pubspec.yaml` à jour, modifier `site/_site/versions.json` :

1. l'entrée qui porte `"channel": "current"` passe à `"channel": "stable"` ;
2. une nouvelle entrée est ajoutée **en tête** du tableau :

   { "id": "v<VERSION>", "label": "<VERSION>", "channel": "current",
     "date": "<AAAA-MM-JJ du jour>", "notes": "<VERSION>", "windows": true }

Vérifier ensuite `bash .github/scripts/verify_version.sh <VERSION>` : il doit
afficher la ligne de cohérence sur les trois fichiers. Ne jamais toucher aux
entrées `stable` ou `legacy` existantes : chaque `id` est un dossier réellement
présent sur le VPS.

**Rafraîchis aussi les liens de repli, dans le même geste.** Trois liens sont codés en
dur sur une version précise : `site/index.html` (bouton « JOUER MAINTENANT » et la carte
de version « actuelle ») et `site/versions.html` (lien « Jouer à la dernière version
connue »). Remplace leur `/v<ANCIENNE_VERSION>/` par `/v<VERSION>/`. Ils ne peuvent pas
être rendus indépendants de la version — aucune URL jouable n'existe sans numéro, le
symlink `latest` ayant été délibérément écarté — mais ils ne sont atteints que si
JavaScript est désactivé ou si les données échouent à charger : un lien resté sur
l'ancienne version reste au moins jouable, seulement pas à jour.
```

- [ ] **Étape 4 : indexer le plan**

Dans `docs/INDEX.md` §10, remplacer la ligne du lot 2 par celle-ci, qui porte les deux liens :

```markdown
| 📐🔨 | [P-04 lot 2 — Site vitrine & finalisation du CI/CD](superpowers/specs/2026-08-19-site-vitrine-et-finalisation-ci-cd-design.md) · [plan](superpowers/plans/2026-08-19-site-vitrine-et-finalisation-ci-cd.md) — smoke test, notification Discord, répertoire `site/` piloté par `versions.json` | 19/08/2026 |
```

- [ ] **Étape 5 : vérifier que le garde-fou est cohérent avec ce qui est écrit**

```bash
bash .github/scripts/verify_version.sh 0.4.8
```

Attendu : échec sur `pubspec.yaml`, pas sur `versions.json` :

```
::error::Version 0.4.8 != pubspec.yaml (0.4.7). Resynchronise pubspec.yaml, puis supprime et repousse le tag.
```

C'est le comportement correct, pas un défaut du garde-fou : les vérifications s'exécutent dans l'ordre — `pubspec.yaml`, puis `patch_notes.json`, puis `versions.json` — et s'arrêtent à la première divergence rencontrée. Tant que `pubspec.yaml` reste à 0.4.7, la divergence sur `versions.json` que ce garde-fou est censé attraper n'est simplement jamais atteinte par cet appel.

- [ ] **Étape 6 : commit**

```bash
git add site/nginx.reference.conf CLAUDE.md .claude/skills/patch-notes-writer/SKILL.md docs/INDEX.md
git commit -m "docs: perimetre a trois fichiers du skill patch-notes-writer et contrat nginx versionne"
git push
```

---

## Task 13 : valider le lot 2 sur la release 0.4.9

**Files:** `pubspec.yaml`, `assets/data/patch_notes.json`, `site/_site/versions.json` — via la compétence `patch-notes-writer`, jamais à la main.

- [ ] **Étape 1 : préparer la release**

Invoquer `patch-notes-writer`. Elle doit désormais toucher **trois** fichiers.

- [ ] **Étape 2 : vérifier les trois portes en local**

```bash
bash .github/scripts/verify_version.sh 0.4.9
bash .github/scripts/test_scripts.sh
cd site && node --test
```

Attendu : la ligne de cohérence sur les trois fichiers, `52 ok, 0 echec(s)`, et `pass 20`.

- [ ] **Étape 3 : commit, tag, push**

```bash
git add pubspec.yaml assets/data/patch_notes.json site/_site/versions.json
git commit -m "chore(release): version 0.4.9"
git push
git tag v0.4.9
git push origin v0.4.9
```

- [ ] **Étape 4 : suivre les neuf jobs**

Attendu, dans l'ordre : `quality`, `verify-version`, `build-web`, `build-windows`, `deploy-web`, `smoke-test`, `deploy-site`, `release-windows`, `notify-discord`.

- [ ] **Étape 5 : vérifier de l'extérieur**

```bash
bash .github/scripts/smoke_test.sh https://heros-draft.vilarserver.com 0.4.9
curl -sS https://heros-draft.vilarserver.com/_site/versions.json | jq -r '.[] | select(.channel=="current") | .id'
for v in v0.4.9 v0.4.8 v0.4.7 v0.0.9 v0.0.1 v5 v1; do printf '%-8s ' "$v"; curl -sS -o /dev/null -w '%{http_code}\n' "https://heros-draft.vilarserver.com/$v/"; done
```

Attendu : le smoke test vert, `v0.4.9`, et `200` sur les sept dossiers.

- [ ] **Étape 6 : vérifier à l'œil**

Sur `https://heros-draft.vilarserver.com/` : `0.4.9` en vedette avec ses patch notes. Sur `/versions.html` : dix-sept entrées. Sur `/notes.html` : trente-six panneaux. Dans Discord : un message dont les trois liens aboutissent.

---

## Après ce plan

À traiter hors de ce chantier, dans l'ordre :

1. **Supprimer les fichiers devenus morts.** `../Prototypes/Web/index.html` est remplacé par `site/`. Le supprimer ou l'archiver explicitement — le laisser en place invite à le rééditer par réflexe.
2. **Relever les dates des quatorze versions legacy** sur le VPS (`stat` sur chaque dossier de `/var/www/prototypes/`) et les renseigner dans `versions.json`, à la place des `null`.
3. **Trancher le sort de `/heros-draft/`.** Le BLOC 3 de nginx le sert encore ; il n'est listé nulle part. Soit une entrée `legacy` dans `versions.json`, soit un bloc nginx à retirer.
4. **Lancer `memory-bank-sync`.** `docs/ROADMAP.md` décrit encore P-04 avec « 1 modification nginx pour le symlink `latest` » et « 1 webhook Discord » dans ses prérequis — deux affirmations fausses depuis le 18/08.
5. **Supprimer l'espace de travail SDD** de P-04 : `.superpowers/sdd/2026-08-17-p04-ci-cd-github-actions/`.
6. **Régénérer le webhook Discord**, qui a transité en clair pendant la conception, puis mettre à jour le secret.
