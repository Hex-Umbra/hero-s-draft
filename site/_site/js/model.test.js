import { test } from 'node:test';
import assert from 'node:assert/strict';

import {
  REPO_URL,
  findCurrent,
  groupByChannel,
  noteFor,
  playUrl,
  notesUrl,
  downloadUrl,
  releaseUrl,
  formatBytes,
  formatDate,
} from './model.js';

const VERSIONS = [
  { id: 'v0.4.7', label: '0.4.7', channel: 'current', date: '2026-08-18', notes: '0.4.7', windows: true },
  { id: 'v0.0.9', label: '0.0.9', channel: 'stable', date: null, notes: null, windows: false },
  { id: 'v3', label: 'Prototype V3', channel: 'legacy', date: null, notes: null, windows: false },
];

const NOTES = [
  { version: '0.4.7', date: '2026-07-26', title: "L'Equilibre des Effectifs", sections: [] },
  { version: '0.4.6', date: '2026-07-20', title: 'Autre chose', sections: [] },
];

test('findCurrent isole l unique entree courante', () => {
  assert.equal(findCurrent(VERSIONS).id, 'v0.4.7');
});

test('findCurrent renvoie null quand aucune entree n est courante', () => {
  assert.equal(findCurrent(VERSIONS.filter((v) => v.channel !== 'current')), null);
});

test('groupByChannel repartit les trois canaux', () => {
  const g = groupByChannel(VERSIONS);
  assert.equal(g.current.length, 1);
  assert.equal(g.stable.length, 1);
  assert.equal(g.legacy.length, 1);
});

test('groupByChannel ignore un canal inconnu sans lever', () => {
  const g = groupByChannel([...VERSIONS, { id: 'vX', channel: 'inconnu' }]);
  assert.equal(g.current.length + g.stable.length + g.legacy.length, 3);
});

test('noteFor joint sur le champ notes, pas sur l id', () => {
  assert.equal(noteFor(VERSIONS[0], NOTES).title, "L'Equilibre des Effectifs");
});

test('noteFor renvoie null quand notes vaut null', () => {
  // Les quatorze dossiers legacy rapportent tous version 0.1.0 dans leur
  // version.json : leurs noms sont des numeros de deploiement. Aucune jointure
  // n est possible, et une jointure sur l id produirait de FAUSSES
  // associations sur v0.0.1 a v0.0.4.
  assert.equal(noteFor(VERSIONS[1], NOTES), null);
  assert.equal(noteFor(VERSIONS[2], NOTES), null);
});

test('noteFor renvoie null quand la cle ne correspond a aucune note', () => {
  assert.equal(noteFor({ id: 'v9.9.9', notes: '9.9.9' }, NOTES), null);
});

test('noteFor tolere une entree absente', () => {
  assert.equal(noteFor(null, NOTES), null);
});

test('playUrl construit le chemin du dossier', () => {
  assert.equal(playUrl(VERSIONS[0]), '/v0.4.7/');
  assert.equal(playUrl(VERSIONS[2]), '/v3/');
});

test('notesUrl pointe vers les patch notes embarquees dans le build', () => {
  assert.equal(notesUrl(VERSIONS[0]), '/v0.4.7/assets/assets/data/patch_notes.json');
});

test('downloadUrl se deduit du seul id', () => {
  assert.equal(
    downloadUrl(VERSIONS[0]),
    `${REPO_URL}/releases/download/v0.4.7/heros-draft-v0.4.7-windows.zip`,
  );
});

test('downloadUrl et releaseUrl renvoient null sans release GitHub', () => {
  assert.equal(downloadUrl(VERSIONS[1]), null);
  assert.equal(releaseUrl(VERSIONS[1]), null);
});

test('formatBytes arrondit en megaoctets', () => {
  assert.equal(formatBytes(58_600_000), '59 Mo');
});

test('formatBytes rejette les valeurs inexploitables', () => {
  assert.equal(formatBytes(0), null);
  assert.equal(formatBytes(null), null);
  assert.equal(formatBytes('58'), null);
  assert.equal(formatBytes(Number.NaN), null);
});

test('formatDate rend une date francaise lisible', () => {
  assert.equal(formatDate('2026-08-18'), '18 août 2026');
});

test('formatDate tolere null et une date invalide', () => {
  assert.equal(formatDate(null), null);
  assert.equal(formatDate('pas-une-date'), null);
});
