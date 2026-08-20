/* Acces reseau, et rien d'autre. Aucune logique metier ici : elle est dans
   model.js, ou elle est testable sans serveur. */

import { API_URL, notesUrl } from './model.js';

async function fetchJson(url, options = {}) {
  const response = await fetch(url, { headers: { Accept: 'application/json' }, ...options });
  if (!response.ok) throw new Error(`${url} a repondu ${response.status}`);
  return response.json();
}

/** La source de verite du site. Un echec ici laisse le repli statique en place.
    `cache: 'no-cache'` force une revalidation reseau a chaque visite : nginx ne
    sert ce fichier qu'avec Last-Modified/ETag, sans Cache-Control ni Expires, donc
    le navigateur appliquerait sinon une fraicheur heuristique de plusieurs jours et
    continuerait d'afficher la version precedente apres une release recente. Le cout
    est une requete conditionnelle, qui repond 304 le plus souvent. */
export function loadVersions() {
  return fetchJson('/_site/versions.json', { cache: 'no-cache' });
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
