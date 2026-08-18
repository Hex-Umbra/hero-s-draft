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
