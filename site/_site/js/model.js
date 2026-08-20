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
   v0.0.9 -- absentes de patch_notes.json.

   Les cas v0.0.5 et v0.0.9 le montrent en positif : ces dossiers portent les
   notes 0.0.4 et 0.0.93, associations connues de l'auteur seul. Aucun calcul
   sur l'id ne les aurait trouvees, puisqu'il aurait cherche des notes 0.0.5
   et 0.0.9 qui n'existent pas. */
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
