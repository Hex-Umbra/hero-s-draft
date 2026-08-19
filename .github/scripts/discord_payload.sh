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
         then ($body[0:$limit] + "\n\n(...)\n\nNotes completes sur la release GitHub.")
         else $body
         end
       ),
       fields: [
         { name: "Jouer",        value: ("[Dans le navigateur](" + $play + ")"),   inline: true },
         { name: "Telecharger",  value: ("[Windows (.zip)](" + $zip + ")"),        inline: true },
         { name: "Details",      value: ("[Release GitHub](" + $release + ")"),    inline: true }
       ]
     }]
   }'
