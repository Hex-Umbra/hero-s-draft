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

/* Entree dont l'id ne contient AUCUN numero de version : la seule facon de lui
   trouver sa patch note est de passer par le champ `notes`. Le schema decouple
   volontairement les deux -- c'est la raison d'etre du champ. */
const DECOUPLED = { id: 'vtest', label: 'Build de test', channel: 'stable', date: null, notes: '0.4.6', windows: false };

/* L'entree 0.0.9 est un PIEGE deliberé, et le coeur de ce fichier de tests.
   Le dossier v0.0.9 existe sur le serveur mais n'a aucune patch note : son
   build rapporte version 0.1.0, son nom est un numero de deploiement. Une
   implementation qui joindrait sur l'id -- en retirant le "v" -- trouverait
   cette entree et l'afficherait. C'est exactement la fausse association que
   le champ `notes` existe pour empecher, et c'est le mutant que le test
   "noteFor renvoie null quand notes vaut null" doit tuer. */
const NOTES = [
  { version: '0.4.7', date: '2026-07-26', title: "L'Equilibre des Effectifs", sections: [] },
  { version: '0.4.6', date: '2026-07-20', title: 'Autre chose', sections: [] },
  { version: '0.0.9', date: '2026-01-01', title: 'FAUX POSITIF — ne doit jamais s afficher', sections: [] },
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

test('groupByChannel place chaque entree dans le bon canal', () => {
  // Compter ne suffit pas : avec une entree par canal, une implementation qui
  // intervertirait current et legacy donnerait les memes trois comptes.
  const g = groupByChannel(VERSIONS);
  assert.equal(g.current[0].id, 'v0.4.7');
  assert.equal(g.stable[0].id, 'v0.0.9');
  assert.equal(g.legacy[0].id, 'v3');
});

test('groupByChannel ignore un canal inconnu sans lever', () => {
  const g = groupByChannel([...VERSIONS, { id: 'vX', channel: 'inconnu' }]);
  assert.equal(g.current.length + g.stable.length + g.legacy.length, 3);
});

test('noteFor joint sur le champ notes, pas sur l id', () => {
  assert.equal(noteFor(VERSIONS[0], NOTES).title, "L'Equilibre des Effectifs");
  // Direction positive discriminante : l'id "vtest" ne ressemble a aucune
  // version, donc seule une jointure par `notes` peut trouver la 0.4.6.
  assert.equal(noteFor(DECOUPLED, NOTES).title, 'Autre chose');
});

test('noteFor renvoie null quand notes vaut null, MEME si l id correspond a une note', () => {
  // Le test qui compte. VERSIONS[1] a pour id "v0.0.9" et NOTES contient une
  // entree de version "0.0.9" : une implementation qui joindrait sur l'id
  // retournerait le FAUX POSITIF au lieu de null, et ce test echouerait.
  // C'est la seule assertion du fichier qui distingue les deux strategies de
  // jointure -- ne pas retirer l'entree piege de NOTES.
  assert.equal(noteFor(VERSIONS[1], NOTES), null);
  assert.equal(noteFor(VERSIONS[2], NOTES), null);
});

test('noteFor renvoie null quand la cle ne correspond a aucune note', () => {
  assert.equal(noteFor({ id: 'v9.9.9', notes: '9.9.9' }, NOTES), null);
});

test('noteFor tolere une entree absente ou des notes non chargees', () => {
  assert.equal(noteFor(null, NOTES), null);
  assert.equal(noteFor(VERSIONS[0], null), null);
  assert.equal(noteFor(VERSIONS[0], undefined), null);
});

test('findCurrent et groupByChannel tolerent une valeur non tableau', () => {
  // Le contrat du module est de degrader l'affichage, jamais de lever : un
  // versions.json illisible ne doit pas casser la page.
  assert.equal(findCurrent(null), null);
  assert.equal(findCurrent(undefined), null);
  const g = groupByChannel(undefined);
  assert.equal(g.current.length + g.stable.length + g.legacy.length, 0);
});

test('playUrl construit le chemin du dossier', () => {
  assert.equal(playUrl(VERSIONS[0]), '/v0.4.7/');
  assert.equal(playUrl(VERSIONS[2]), '/v3/');
});

test('notesUrl pointe vers les patch notes embarquees dans le build', () => {
  assert.equal(notesUrl(VERSIONS[0]), '/v0.4.7/assets/assets/data/patch_notes.json');
  assert.equal(notesUrl(VERSIONS[2]), '/v3/assets/assets/data/patch_notes.json');
});

test('playUrl et notesUrl renvoient null au lieu de lever sur une entree vide', () => {
  for (const bad of [null, undefined, {}]) {
    assert.equal(playUrl(bad), null);
    assert.equal(notesUrl(bad), null);
  }
});

test('downloadUrl se deduit du seul id', () => {
  assert.equal(
    downloadUrl(VERSIONS[0]),
    `${REPO_URL}/releases/download/v0.4.7/heros-draft-v0.4.7-windows.zip`,
  );
});

test('releaseUrl pointe sur le tag, pas sur le telechargement', () => {
  assert.equal(releaseUrl(VERSIONS[0]), `${REPO_URL}/releases/tag/v0.4.7`);
});

test('downloadUrl et releaseUrl renvoient null sans release GitHub', () => {
  assert.equal(downloadUrl(VERSIONS[1]), null);
  assert.equal(releaseUrl(VERSIONS[1]), null);
  assert.equal(downloadUrl(null), null);
  assert.equal(releaseUrl(undefined), null);
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
