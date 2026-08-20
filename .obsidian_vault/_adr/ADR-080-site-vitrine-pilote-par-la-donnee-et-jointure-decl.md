### Statut

✅ **Livré le 2026-08-20** — branche `feat/site-vitrine-ci-cd`, mergée via PR #26,
publiée en `0.4.8`. Lot 2 du chantier **P-04** de `docs/ROADMAP.md`. Conception :
`docs/superpowers/specs/2026-08-19-site-vitrine-et-finalisation-ci-cd-design.md`.
Lot 1 (chaîne CI/CD) : [ADR-079](ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md).

### Contexte

La page de sélection des versions vivait **hors du dépôt**, dans `../Prototypes/Web/`, et
se maintenait à la main. Le 18/08, `0.4.7` était en ligne et jouable pendant que la page
d'accueil mettait toujours `v0.0.9` en vedette : la version courante était **invisible
depuis la seule porte d'entrée du joueur**. Une page hors du dépôt ne peut pas être mise à
jour par le pipeline qui déploie le jeu ; elle diverge par construction.

**Relevé de terrain décisif.** Avant toute conception, lecture du `version.json` que Flutter
écrit dans chacun des quatorze dossiers déployés :

```
v0.0.1 … v0.0.9, v1 … v5   →   "version":"0.1.0" pour les quatorze
```

Les quatorze rapportent la **même version applicative**. Leurs noms sont des numéros de
**déploiement**, pas de version — `pubspec.yaml` n'était pas incrémenté à l'époque, ce que
P-01 a corrigé. Les collisions de noms (`v0.0.1` à `v0.0.4`) sont donc des coïncidences.

### Décision

**1. `site/_site/versions.json` est la source de vérité, et il vit dans le dépôt.** Une
entrée par dossier déployé : `id` (nom du dossier, donc segment d'URL), `label`, `channel`
(`current` / `stable` / `legacy`), `date`, `notes`, `windows`.

**2. La jointure version → patch note est déclarée, jamais dérivée.** Le champ `notes` est
une clé explicite vers `patch_notes.json`, et il est **nullable**. Dériver la note du nom
de dossier aurait produit quatre associations fausses et dix vides. Les dates relevées
depuis l'archive locale des builds le confirment par un second chemin, indépendant du
`version.json` : la note `0.0.1` date du 01/02 quand le dossier `v0.0.1` date du 05/05, et
la note `0.0.4` (15/05) est **postérieure** au dossier `v0.0.4` (09/05).

**3. Aucune étape de build, aucune dépendance npm.** Modules ES natifs chargés directement
par le navigateur, polices auto-hébergées en woff2. La logique pure vit dans `model.js`,
sans réseau ni DOM, et se teste par `node --test` — **20 tests**, exécutés par la porte de
qualité de `ci.yml` et de `release.yml`.

**4. Contrat de dégradation.** Chaque conteneur `[data-slot]` porte un repli statique dans
le HTML livré ; le JavaScript ne le remplace **qu'en cas de succès**. Une donnée
introuvable laisse une page utilisable plutôt qu'une page blanche. Corollaire appris à
l'exécution : un rendu produisant zéro bloc doit **renoncer** plutôt qu'écraser le repli.

**5. Le garde-fou de version couvre le fichier.** `verify_version.sh` gagne cinq assertions
sur `versions.json` : JSON valide, exactement une entrée `current`, cohérence `id`/`notes`
de cette entrée avec la version publiée, unicité des `id`, et format `AAAA-MM-JJ` de toute
`date` présente. C'est ce qui interdit à la panne du 18/08 de se reproduire.

### Preuves dans le code

| Élément | Chemin |
|:---|:---|
| Source de vérité des versions | `site/_site/versions.json` |
| Logique pure (jointure, groupement, formats) | `site/_site/js/model.js` |
| Tests de la logique (20) | `site/_site/js/model.test.js` |
| Accès réseau isolé | `site/_site/js/data.js` |
| Rendu données → DOM | `site/_site/js/render.js` |
| Orchestration par page | `site/_site/js/main.js` |
| Pages | `site/index.html`, `site/versions.html`, `site/notes.html` |
| Contrat nginx (miroir en lecture seule) | `site/nginx.reference.conf` |
| Déploiement | `.github/workflows/site.yml` |

Seize fichiers suivis sous `site/`. `nginx.reference.conf`, `package.json` et `*.test.js`
sont exclus du rsync : ils servent au dépôt, pas au serveur.

### Conséquences

**Acquis.** La page d'accueil ne peut plus mentir sur la version courante : la donnée qui
la pilote est vérifiée avant le moindre build. L'archive des quatorze versions historiques
devient consultable au lieu d'être une liste de liens sans contexte.

**Enrichissement du 2026-08-20.** Les quatorze dates, longtemps à `null`, ont été relevées
sur l'archive locale des builds — dont les fichiers portent encore l'horodatage de
compilation Flutter, là où le nom du dossier ne dit rien. Deux jointures ont ensuite été
**déclarées** sur confirmation de l'auteur : `v0.0.5` → note `0.0.4` (corroborée au jour
près) et `v0.0.9` → note `0.0.93` (trois jours d'écart, donc plus faible). Aucune
dérivation depuis l'`id` ne les aurait trouvées : elle aurait cherché des notes `0.0.5` et
`0.0.9` qui n'existent pas. C'est la démonstration en positif du champ `notes`.

**Piège d'exploitation.** Le `try_files` de nginx renvoie **HTTP 500**, pas 404, sur un
dossier de version inexistant : la cible de repli n'existe pas non plus et le serveur
boucle. Un lien mort sur ce site se manifeste donc en erreur serveur.

**Dette connue.** Si le build Windows échoue pendant que la branche web réussit, le site
publie `windows: true` et affiche un lien de téléchargement vers un asset absent. Le
correctif — classer le résultat de la requête de taille dans `model.js` pour masquer le
bouton — reste à faire.
