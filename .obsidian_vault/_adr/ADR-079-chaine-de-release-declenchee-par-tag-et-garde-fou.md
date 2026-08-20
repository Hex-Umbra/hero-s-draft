### Statut

✅ **Livré le 2026-08-18** — branche `feat/p04-ci-cd`, mergée via PR #25.
Lot 1 du chantier **P-04** de `docs/ROADMAP.md` (Tier S). Conception :
`docs/superpowers/specs/2026-08-17-p04-ci-cd-github-actions-design.md`.
Lot 2 (site vitrine) : [ADR-080](ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

### Contexte

Deux workflows manuels tournaient à chaque version : le déploiement web sur le VPS
personnel et la construction du zip Windows envoyé aux testeurs. Aucun des deux n'était
outillé, et le dépôt ne portait **aucun** `.github/workflows/`.

Le coût réel n'était pas le temps passé mais l'absence de garde-fou. Trois fichiers
portent le numéro de version — `pubspec.yaml`, `assets/data/patch_notes.json` et, depuis
le lot 2, `site/_site/versions.json` — et rien ne vérifiait qu'ils s'accordaient. P-01
avait déjà eu à réparer un écart `0.1.0` / `0.4.7` resté invisible plusieurs semaines.

Une release qui se déploie avec des versions désaccordées ne casse pas : elle **ment**,
silencieusement, jusqu'à ce que quelqu'un le remarque.

### Décision

**1. Trois workflows, un seul déclencheur humain.** `ci.yml` sur push et PR ; `release.yml`
sur tag `v*.*.*` ; `site.yml` en `workflow_dispatch` **et** `workflow_call`, appelé par
`release.yml`. Publier une version se réduit à poser un tag — à condition que le skill
`patch-notes-writer` ait d'abord déplacé ensemble les trois fichiers de version.

**2. `verify-version` est la première porte, avant tout build.** Le job compare le tag aux
trois fichiers et échoue en quelques secondes si l'un diverge. Aucun artefact n'est
construit tant que la cohérence n'est pas établie. Le garde-fou est un script testable
(`verify_version.sh`), pas une étape inline : son harnais `test_scripts.sh` porte
**55 assertions**, dont les attentes sont dérivées à l'exécution par `jq` plutôt que
figées, pour qu'il ne fige pas la version courante du dépôt.

**3. Un smoke test post-déploiement.** `smoke_test.sh` vérifie en HTTP que la version
fraîchement déployée répond réellement : page d'accueil à 200, `--base-href` correct dans
le HTML (sans quoi la page est blanche), `main.dart.js` et les patch notes embarquées
accessibles. Le déploiement du site n'a lieu qu'**après** ce test.

**4. Le pipeline échoue fermé, l'annonce échoue ouvert.** Tous les jobs bloquent la release
en cas d'échec, sauf `notify-discord`, en `continue-on-error` : une annonce ratée ne doit
pas invalider une version par ailleurs saine.

**5. Sécurité de la chaîne.** Chaque action tierce est épinglée sur un SHA de commit, jamais
sur un tag mobile. Aucun secret n'est interpolé dans un corps `run:` — ils transitent
exclusivement par `env:`. L'accès SSH au VPS passe par une commande forcée `rrsync -wo`,
donc en écriture seule : la CI ne peut pas lister le serveur. `--delete` est **interdit**
sur le chemin de déploiement du site, dont la racine confinée héberge tous les dossiers
de version.

### Preuves dans le code

| Élément | Chemin |
|:---|:---|
| Intégration continue | `.github/workflows/ci.yml` |
| Release (9 jobs) | `.github/workflows/release.yml` |
| Déploiement du site | `.github/workflows/site.yml` |
| Garde-fou de version | `.github/scripts/verify_version.sh` |
| Extraction des notes en markdown | `.github/scripts/release_body.sh` |
| Smoke test post-déploiement | `.github/scripts/smoke_test.sh` |
| Payload d'annonce Discord | `.github/scripts/discord_payload.sh` |
| Harnais des scripts (55 assertions) | `.github/scripts/test_scripts.sh` |

Les neuf jobs de `release.yml` : `verify-version` et `quality` sans dépendance, puis
`build-web` et `build-windows`, puis `deploy-web`, `smoke-test`, `deploy-site`,
`release-windows` et `notify-discord`.

### Conséquences

**Acquis.** Le désaccord de version devient un échec de pipeline en trente secondes au lieu
d'un mensonge silencieux en production. `dart analyze` et `flutter test` s'appliquent sur
chaque push, ce qui prend de la valeur à mesure que du contenu est produit par sub-agents.
Le zip Windows et le déploiement web ne demandent plus aucun geste manuel.

**Coût.** La fragilité s'est déplacée vers la configuration externe : secrets GitHub, clé
SSH dédiée, confinement `rrsync`. Ces éléments vivent hors du dépôt et ne sont donc
couverts par aucun test — leur validation reste manuelle.

**Piège de lecture connu.** Un run déclenché par un tag est attribué à la **ref du tag**,
pas à une branche : il n'apparaît pas dans la liste filtrée sur `main`. Filtrer sur
*Event : push* sans filtre de branche, ou ouvrir directement l'onglet du workflow.

**Prérequis périmés.** Le diagnostic du 31/07 dans `docs/ROADMAP.md` annonçait « 1
modification nginx pour le symlink `latest` » et « 1 webhook Discord » comme prérequis
externes. Le symlink a été abandonné au profit de dossiers versionnés explicites
([ADR-080](ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md)), et le webhook
a été créé le 2026-08-20.
