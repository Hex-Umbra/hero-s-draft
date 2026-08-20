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
        badge: 'DERNIERE VERSION',
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
