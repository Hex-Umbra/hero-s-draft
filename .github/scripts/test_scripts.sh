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

# Attentes derivees des fichiers reels a l'execution -- jamais figees, pour
# survivre a un bump de version (premiere etape de la procedure de release).
REAL_VER="$(jq -r '.[0].version' assets/data/patch_notes.json)"
INCOMPLETE_VER="${REAL_VER%.*}"

# Deux versions synthetiques, sans rapport avec le repo reel, pour tester la
# logique de desaccord en isolation complete.
FX_A="9.9.8"
FX_B="9.9.9"

# Fixtures : paires pubspec/patch-notes isolees du repo reel (sous-dossiers
# "agree"/"disagree"), plus les cas defensifs (version illisible, JSON
# invalide). Les patch-notes de fixture sont nommees patch_notes.json comme le
# fichier reel, pour que le message d'erreur -- qui interpole le chemin --
# contienne bien cette sous-chaine. Aucune fixture ne depend de la version en
# cours du repo.
mkdir -p "${FIXTURES}/agree" "${FIXTURES}/disagree" "${FIXTURES}/no_version" "${FIXTURES}/invalid" "${FIXTURES}/versions"
printf 'name: roguelike_card_game\nversion: %s+1\n' "${FX_A}" > "${FIXTURES}/agree/pubspec.yaml"
printf '[{"version":"%s","date":"2026-01-01","title":"T","sections":[]}]\n' "${FX_A}" > "${FIXTURES}/agree/patch_notes.json"
printf '[{"version":"%s","date":"2026-01-01","title":"T","sections":[]}]\n' "${FX_B}" > "${FIXTURES}/disagree/patch_notes.json"
printf 'name: roguelike_card_game\ndescription: pas de ligne version ici\n' > "${FIXTURES}/no_version/pubspec.yaml"
printf 'contenu invalide, pas du json {{{' > "${FIXTURES}/invalid/patch_notes.json"
# ${FIXTURES}/missing/pubspec.yaml et ${FIXTURES}/missing/patch_notes.json ne
# sont jamais crees : c'est le point des deux tests "introuvable" plus bas.

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
printf '[{"id":"v%s","label":"a","channel":"current","date":null,"notes":"%s","windows":true},{"id":"v0.0.1","label":"b","channel":"stable","date":"05/05/2026","notes":null,"windows":false}]\n' "${FX_A}" "${FX_A}" > "${V}/bad_date.json"
printf '[{"id":"v%s","label":"a","channel":"current","date":"2026-05-05","notes":"%s","windows":true},{"id":"v0.0.1","label":"b","channel":"stable","date":"2026-06-01","notes":null,"windows":false}]\n' "${FX_A}" "${FX_A}" > "${V}/good_dates.json"

# AGREE = le couple pubspec/patch-notes qui concorde sur FX_A. Seul
# VERSIONS_PATH varie d'une assertion a l'autre.
AGREE=("PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/agree/patch_notes.json")

echo "verify_version.sh"

# --- Cas nominal : les vrais fichiers du repo ---
assert_exit 0 "accepte ${REAL_VER} (pubspec et patch notes reels)" ${VERIFY} "${REAL_VER}"

# --- Formats invalides ---
assert_exit 1 "refuse une version absente"           ${VERIFY}
assert_exit 1 "refuse la chaine vide"                ${VERIFY} ""
assert_exit 1 "refuse X.Y (incomplet)"               ${VERIFY} "${INCOMPLETE_VER}"
assert_exit 1 "refuse un prefixe v"                  ${VERIFY} "v${REAL_VER}"
assert_exit 1 "refuse un suffixe -beta"              ${VERIFY} "${REAL_VER}-beta"
assert_exit 1 "refuse des metadonnees de build (+1)" ${VERIFY} "${REAL_VER}+1"
assert_exit 1 "refuse du texte libre"                ${VERIFY} abc

# --- Desaccord avec pubspec.yaml, isole sur fixtures (les deux fichiers) ---
assert_exit 1 "refuse quand seul pubspec diverge" \
  env "PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/agree/patch_notes.json" ${VERIFY} "${FX_B}"
assert_contains "pubspec.yaml" "nomme pubspec.yaml dans l'erreur de desaccord" \
  env "PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/agree/patch_notes.json" ${VERIFY} "${FX_B}"

# --- Desaccord avec patch_notes.json, isole sur fixtures (les deux fichiers) ---
assert_exit 1 "refuse quand seules les patch notes divergent" \
  env "PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/disagree/patch_notes.json" ${VERIFY} "${FX_A}"
assert_contains "patch_notes.json" "nomme patch_notes.json dans l'erreur" \
  env "PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/disagree/patch_notes.json" ${VERIFY} "${FX_A}"

# --- Cas nominal avec les deux fixtures alignees ---
assert_exit 0 "accepte ${FX_A} quand les trois fixtures concordent" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/ok.json" ${VERIFY} "${FX_A}"

# --- Branches defensives ---
assert_exit 1 "refuse un PUBSPEC_PATH introuvable" \
  env "PUBSPEC_PATH=${FIXTURES}/missing/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/agree/patch_notes.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse un PATCH_NOTES_PATH introuvable" \
  env "PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/missing/patch_notes.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse un pubspec sans ligne version: exploitable" \
  env "PUBSPEC_PATH=${FIXTURES}/no_version/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/agree/patch_notes.json" ${VERIFY} "${FX_A}"
assert_exit 1 "refuse des patch notes JSON invalides" \
  env "PUBSPEC_PATH=${FIXTURES}/agree/pubspec.yaml" "PATCH_NOTES_PATH=${FIXTURES}/invalid/patch_notes.json" ${VERIFY} "${FX_A}"

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
assert_exit 1 "refuse une date presente mais malformee" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/bad_date.json" ${VERIFY} "${FX_A}"
assert_contains "v0.0.1" "nomme l'entree fautive dans l'erreur de date" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/bad_date.json" ${VERIFY} "${FX_A}"
assert_exit 0 "accepte des dates ISO sur toutes les entrees" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/good_dates.json" ${VERIFY} "${FX_A}"
assert_contains "no_current.json" "nomme le fichier de versions dans l'erreur" \
  env "${AGREE[@]}" "VERSIONS_PATH=${V}/no_current.json" ${VERIFY} "${FX_A}"

echo
echo "release_body.sh"

BODY="bash .github/scripts/release_body.sh"

# CR normalization: Windows native jq.exe uses text-mode stdout, converting \n
# to \r\n. This affects pattern matching on embedded newlines but not grep -c
# with line anchors. Captured once here, reused below instead of repeating the
# same "sh -c ... | tr -d '\r'" five times.
RENDER=(sh -c "bash .github/scripts/release_body.sh | tr -d '\r'")

# Attentes derivees de l'entree la plus recente des vraies patch notes --
# jamais de titre, de prose ou de nombre de sections fige en dur.
REAL_TITLE="$(jq -r '.[0].title' assets/data/patch_notes.json)"
REAL_SECTIONS="$(jq '.[0].sections | length' assets/data/patch_notes.json)"
FIRST_CATEGORY="$(jq -r '.[0].sections[0].category' assets/data/patch_notes.json)"
FIRST_EMOJI="$(jq -r '.[0].sections[0].emoji' assets/data/patch_notes.json)"
FIRST_ENTRY="$(jq -r '.[0].sections[0].entries[0]' assets/data/patch_notes.json)"
LAST_CATEGORY="$(jq -r '.[0].sections[-1].category' assets/data/patch_notes.json)"
LAST_EMOJI="$(jq -r '.[0].sections[-1].emoji' assets/data/patch_notes.json)"

assert_exit 0 "s'execute sur les patch notes reelles" ${BODY}
assert_contains "## ${REAL_TITLE}" "reprend le titre en h2" "${RENDER[@]}"
assert_contains "### ${FIRST_EMOJI} ${FIRST_CATEGORY}" "rend emoji et categorie en h3 (premiere section)" "${RENDER[@]}"
assert_contains "- ${FIRST_ENTRY}" "rend les entrees en puces" "${RENDER[@]}"
assert_contains "### ${LAST_EMOJI} ${LAST_CATEGORY}" "rend la derniere section" "${RENDER[@]}"

# Une ligne vide doit separer le titre de la premiere section.
NEEDLE_BLANK_LINE="$(printf '## %s\n\n### %s %s' "${REAL_TITLE}" "${FIRST_EMOJI}" "${FIRST_CATEGORY}")"
assert_contains "${NEEDLE_BLANK_LINE}" "insere une ligne vide apres le titre" "${RENDER[@]}"

# Le corps ne doit contenir que l'entree la plus recente.
if [[ "$(${BODY} 2>/dev/null | grep -c '^## ')" -eq 1 ]]; then
  ok "ne rend qu'une seule entree (la plus recente)"
else
  nok "ne rend qu'une seule entree (la plus recente)"
fi

# Le nombre de sections attendu est celui de l'entree la plus recente,
# derive a l'execution (REAL_SECTIONS) au lieu d'etre fige en dur.
if [[ "$(${BODY} 2>/dev/null | grep -c '^### ')" -eq "${REAL_SECTIONS}" ]]; then
  ok "rend les ${REAL_SECTIONS} sections de l'entree ${REAL_VER}"
else
  nok "rend les ${REAL_SECTIONS} sections de l'entree ${REAL_VER} (obtenu $(${BODY} 2>/dev/null | grep -c '^### '))"
fi

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

echo
echo "${PASS} ok, ${FAIL} echec(s)"
[[ "${FAIL}" -eq 0 ]]
