/* Point d'entree unique des trois pages. Aiguille sur body[data-page].

   Regle de degradation : chaque [data-slot] du HTML contient deja un repli
   utilisable. On ne le remplace qu'en cas de succes. Un echec de fetch laisse
   donc une page complete et cliquable, sans avoir a ecrire le moindre message
   d'erreur -- et cela couvre aussi le cas ou JavaScript est desactive. */

import { loadNotes, loadVersions, loadZipSize } from './data.js';
import { findCurrent, groupByChannel, noteFor } from './model.js';
import { ctaButtons, noteBlock, sectionTitle, versionCard } from './render.js';

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
        badge: 'DERNIÈRE VERSION',
        limit: HOME_SECTIONS,
        moreHref: '/notes.html',
        moreLabel: `VOIR TOUTES LES NOTES (${notes.length} VERSIONS) →`,
      }),
    );
  } catch (error) {
    console.error(error);
  }
}

const CHANNEL_TITLES = {
  current: 'VERSION ACTUELLE',
  stable: 'VERSIONS STABLES',
  legacy: 'PROTOTYPES DE RECHERCHE',
};

async function renderVersions(versions) {
  const target = slot('versions');
  if (!target) return;

  const current = findCurrent(versions);
  const groups = groupByChannel(versions);

  // Les patch notes enrichissent les cartes quand elles sont disponibles, mais
  // leur absence ne doit rien empecher : quatorze des quinze entrees n'en ont
  // de toute facon aucune.
  let notes = [];
  try {
    if (current) notes = await loadNotes(current);
  } catch (error) {
    console.error(error);
  }

  const blocks = [];
  for (const [channel, title] of Object.entries(CHANNEL_TITLES)) {
    const entries = groups[channel];
    if (entries.length === 0) continue;

    blocks.push(sectionTitle(title));

    const grid = document.createElement('div');
    grid.className = channel === 'legacy' ? 'grid grid--legacy' : 'grid';
    grid.append(...entries.map((entry) => versionCard(entry, noteFor(entry, notes))));
    blocks.push(grid);
  }

  // Un resultat vide doit laisser le repli statique en place : une page vide
  // est pire qu'une page perimee.
  if (blocks.length === 0) return;

  target.replaceChildren(...blocks);
}

async function renderNotes(versions) {
  const target = slot('notes');
  const current = findCurrent(versions);
  if (!target || !current) return;

  const notes = await loadNotes(current);

  const blocks = notes.map((note) => {
    const panel = document.createElement('section');
    panel.className = 'panel';
    panel.append(noteBlock(note, {}));
    return panel;
  });

  if (blocks.length === 0) return;

  target.replaceChildren(...blocks);
}

const PAGES = { home: renderHome, versions: renderVersions, notes: renderNotes };

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
