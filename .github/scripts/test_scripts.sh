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
echo "release_body.sh"

BODY="bash .github/scripts/release_body.sh"

assert_exit 0 "s'execute sur les patch notes reelles" ${BODY}
# CR normalization for assert_contains: Windows native jq.exe uses text-mode stdout,
# converting \n to \r\n. This affects pattern matching on embedded newlines but not
# grep -c with line anchors.
assert_contains "## L'Équilibre des Effectifs" "reprend le titre en h2" sh -c "bash .github/scripts/release_body.sh | tr -d '\r'"
assert_contains "### ✨ Nouvelles Fonctionnalités" "rend emoji et categorie en h3" sh -c "bash .github/scripts/release_body.sh | tr -d '\r'"
assert_contains "- Une nouvelle relique légendaire" "rend les entrees en puces" sh -c "bash .github/scripts/release_body.sh | tr -d '\r'"
assert_contains "### 🔧 Technique" "rend la derniere section" sh -c "bash .github/scripts/release_body.sh | tr -d '\r'"

# Une ligne vide doit separer le titre de la premiere section.
assert_contains "Effectifs

###" "insere une ligne vide apres le titre" sh -c "bash .github/scripts/release_body.sh | tr -d '\r'"

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

echo
echo "${PASS} ok, ${FAIL} echec(s)"
[[ "${FAIL}" -eq 0 ]]
