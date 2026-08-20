/* Fonctions pures : donnees -> HTMLElement. Aucun fetch, aucun etat global.

   Le contenu textuel passe toujours par textContent, jamais par innerHTML :
   les patch notes viennent d'un JSON, et une donnee n'a pas a pouvoir devenir
   du balisage. */

import {
  downloadUrl,
  formatBytes,
  formatDate,
  playUrl,
  releaseUrl,
} from './model.js';

function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text != null) node.textContent = text;
  return node;
}

function link(href, className, text) {
  const node = el('a', className, text);
  node.href = href;
  return node;
}

/** Une carte de version cliquable. `note` peut etre null. */
export function versionCard(entry, note) {
  const card = link(playUrl(entry), 'card');
  card.append(el('div', 'card__label', entry.label ?? entry.id));

  const meta = note?.title ?? (entry.channel === 'current' ? 'actuelle' : formatDate(entry.date));
  if (meta) card.append(el('div', 'card__meta', meta));

  return card;
}

/** Le panneau d'une patch note. `opts.limit` borne le nombre de sections. */
export function noteBlock(note, opts = {}) {
  const wrapper = document.createElement('div');

  if (opts.badge) wrapper.append(el('span', 'badge', opts.badge));

  wrapper.append(el('div', 'note__version', `V ${note.version} — ${note.title}`));

  const date = formatDate(note.date);
  if (date) wrapper.append(el('div', 'note__date', date));

  const sections = opts.limit ? note.sections.slice(0, opts.limit) : note.sections;
  for (const section of sections) {
    wrapper.append(el('div', 'note__category', `${section.emoji} ${section.category}`));
    const list = el('ul', 'note__list');
    for (const entry of section.entries) list.append(el('li', null, entry));
    wrapper.append(list);
  }

  if (opts.moreHref) {
    wrapper.append(link(opts.moreHref, 'link-more', opts.moreLabel ?? 'VOIR TOUT'));
  }

  return wrapper;
}

/** Les deux boutons d'appel a l'action de l'accueil. `size` peut etre null. */
export function ctaButtons(current, size) {
  const fragment = document.createDocumentFragment();

  const play = link(playUrl(current), 'btn btn--primary', 'JOUER MAINTENANT');
  play.append(el('small', null, `version ${current.label} · navigateur`));
  fragment.append(play);

  const zip = downloadUrl(current);
  if (zip) {
    const weight = formatBytes(size);
    const download = link(zip, 'btn btn--ghost', 'TELECHARGER');
    download.append(el('small', null, weight ? `Windows · ${weight}` : 'Windows'));
    fragment.append(download);
  } else {
    const release = releaseUrl(current) ?? 'https://github.com/Hex-Umbra/hero-s-draft/releases';
    fragment.append(link(release, 'btn btn--ghost', 'RELEASES'));
  }

  return fragment;
}

export function sectionTitle(text) {
  return el('h2', 'section-title', text);
}
