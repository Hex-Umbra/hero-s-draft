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
