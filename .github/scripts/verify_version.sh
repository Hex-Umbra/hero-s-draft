#!/usr/bin/env bash
# Valide qu'une version est coherente entre le tag git, pubspec.yaml et patch_notes.json.
#
# Usage : verify_version.sh <version>      exemple : verify_version.sh 0.4.7
# Sortie : 0 si tout concorde, 1 avec un message ::error:: sinon.
#
# Ce script est LE garde-fou du pipeline de release. La validation de format
# n'est pas cosmetique : elle empeche une valeur vide ou malformee d'atteindre
# le `rsync --delete` du job deploy-web. La destination y est ":v${VERSION}/" ;
# une version vide donnerait ":v/", un dossier frere des versions publiees, pas
# la racine confinee. Le prefixe "v" litteral de la destination est un verrou
# de securite independant de ce script : il ne doit pas etre retire.
#
# Chemins surchargeables (pour les tests) :
#   PUBSPEC_PATH      defaut pubspec.yaml
#   PATCH_NOTES_PATH  defaut assets/data/patch_notes.json
#   VERSIONS_PATH     defaut site/_site/versions.json

set -uo pipefail

PUBSPEC_PATH="${PUBSPEC_PATH:-pubspec.yaml}"
PATCH_NOTES_PATH="${PATCH_NOTES_PATH:-assets/data/patch_notes.json}"
VERSIONS_PATH="${VERSIONS_PATH:-site/_site/versions.json}"

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

# --- Format des dates ---
#
# `date` reste nullable par contrat, mais une date PRESENTE et malformee ne
# leve rien : formatDate() renvoie null et la carte perd sa ligne de meta
# sans que rien ne le signale. Une faute de frappe effacerait donc en
# silence l'information qu'elle etait censee porter.

BAD_DATES="$(jq -r '[.[] | select(.date != null and ((.date | tostring) | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$") | not)) | .id] | join(", ")' "${VERSIONS_PATH}" 2>/dev/null)"

if [[ -n "${BAD_DATES}" ]]; then
  echo "::error::${VERSIONS_PATH} : date malformee sur ${BAD_DATES}. Attendu AAAA-MM-JJ, ou null."
  exit 1
fi

echo "Version ${VERSION} coherente : tag == ${PUBSPEC_PATH} == ${PATCH_NOTES_PATH}[0].version == ${VERSIONS_PATH} (current)"
