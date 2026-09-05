### Statut

✅ **Livré le 2026-09-05**, chantier P-48, PR #35.
Prolonge [ADR-003](ADR-003-architecture-100-data-driven.md), qui posait le principe
data-driven sans dire **quelle forme** un fichier de données doit prendre. Complété par
[ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md), qui traite de
l'appartenance.

### Contexte

Les données du jeu vivaient dans huit catalogues JSON monolithiques : éditer une carte
voulait dire ouvrir le fichier des dix-sept, et deux ajouts simultanés se heurtaient
systématiquement. Le chantier P-48 les a éclatés en un fichier par entité.

Restait à trancher ce qui **ne** doit **pas** être éclaté. `assets/data/` contenait aussi
`audio.json` et `patch_notes.json`, formellement des tableaux JSON eux aussi. Les découper
« par cohérence » aurait été le réflexe, et une faute.

### Décision

**D1 — Le critère est la nature du fichier, pas sa forme syntaxique.**

| Nature | Forme | Exemples |
|:---|:---|:---|
| **Catalogue d'entités interchangeables** — chaque élément a une identité propre, se remplace, s'ajoute et se supprime indépendamment des autres | Un fichier par entité, le nom du fichier **est** l'`id` | `cards/`, `relics/`, `events/`, `forge_upgrades/`, `passives/`, `classes/`, `enemies/` |
| **Document de configuration unique** — un seul objet, dont les parties n'ont pas d'existence séparée | Reste à plat | `audio.json`, `patch_notes.json` |

**D2 — `audio.json` est une configuration, pas un catalogue.** C'est la table de résolution
d'un moment de jeu vers un son : ses entrées n'ont de sens que les unes par rapport aux
autres, et la chaîne de repli à quatre niveaux d'[ADR-082](ADR-082-directeur-audio-central-et-mapping-par-donnees.md)
se lit d'un coup d'œil sur un fichier unique. Éclatée, elle ne se lirait plus nulle part.

**D3 — `patch_notes.json` reste à plat parce que l'ordre du tableau *est* la sémantique.**
L'index 0 est la version courante. Éclaté en un fichier par version, cet ordre devrait être
reconstruit — par tri sémantique de numéros de version, ce qu'aucun consommateur ne fait
aujourd'hui.

**D4 — `patch_notes.json` a par ailleurs six consommateurs hors du jeu**, tous dépendants de
sa forme actuelle : `discord_payload.sh`, `release_body.sh`, `smoke_test.sh`,
`test_scripts.sh` et `verify_version.sh` sous `.github/scripts/`, plus
`site/_site/js/model.js`. Le découper aurait été un chantier de chaîne de release déguisé en
chantier de données.

**D5 — Le fichier reste agent-managed.** `patch_notes.json` n'est jamais édité à la main : il
appartient au skill `patch-notes-writer`, qui le déplace avec `pubspec.yaml` et
`site/_site/versions.json` — les trois fichiers portent le numéro de version et
`verify_version.sh` échoue si l'un diverge.

### Preuves dans le code

- `assets/data/` : deux fichiers à la racine (`audio.json`, `patch_notes.json`), sept
  répertoires de catalogue.
- `loadGameDataRegistry` (`lib/services/game_data_service.dart`) déclare **huit** `EntitySource`
  pour **sept catégories** — les cartes en ont deux, `cards/*.json` et
  `classes/*/cards/*.json` ; `loadAudioData` lit `audio.json` par son chemin littéral,
  **hors du chargeur générique**.
- `patch_notes.json` n'est lu par aucun chargeur de données : l'écran de notes de version
  le lit pour lui-même.
- Consommateurs hors jeu — `grep -rl 'patch_notes' .github/` : 5 fichiers ;
  `site/_site/js/model.js`.

### Conséquences

- ✅ **Le critère est décidable sans jugement** : un fichier dont on retire un élément sans
  rien casser d'autre est un catalogue.
- ✅ La chaîne de release n'a pas été touchée par un chantier de données.
- ✅ `CLAUDE.md` porte la règle sous forme d'arborescence commentée, et `README.md` la
  procédure d'ajout de contenu.
- ⚠️ **`patch_notes.json` reste la seule exception à « le fichier est l'entité »** dans
  `assets/data/`, et la seule dont l'ordre physique porte du sens. Un futur chantier qui
  voudrait le découper doit d'abord traiter ses six consommateurs.
- ⚠️ La règle ne dit rien des fichiers **non-JSON** de `assets/data/` : les images vivent
  dans le dossier de l'entité qu'elles illustrent, ce que dit
  [ADR-086](ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md).
