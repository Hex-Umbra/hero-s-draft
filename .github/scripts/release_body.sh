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
' "${PATCH_NOTES_PATH}" | tr -d '\r'
