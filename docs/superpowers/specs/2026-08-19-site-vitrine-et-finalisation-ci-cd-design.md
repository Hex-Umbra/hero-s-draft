# Spec d'implémentation — Site vitrine & finalisation du CI/CD

**Date** : 19/08/2026
**Chantier roadmap** : [P-04](../../ROADMAP.md) — lot 2 (le lot 1 est livré et en production depuis le 18/08)
**Spec précédente** : [P-04 — CI/CD GitHub Actions](2026-08-17-p04-ci-cd-github-actions-design.md)
**Statut** : spec validée, prête pour plan d'implémentation — **rien encore implémenté**

> [!IMPORTANT]
> Cette spec **complète** celle du 17/08, elle ne la remplace pas. Tout ce qui y est décrit — les six jobs, le confinement `rrsync`, le garde-fou de version, le pinning SHA — reste vrai et en vigueur. Ce document ajoute trois jobs, un répertoire et un workflow, et modifie deux fichiers existants : `release.yml` et `verify_version.sh`.

---

## 1. Périmètre

### Dans le périmètre

| # | Livrable | Livré en |
|:---:|:---|:---|
| 1 | Job `smoke-test` — prouve que la version déployée est réellement servie | **0.4.8** |
| 2 | Job `notify-discord` — annonce la release sur Discord | **0.4.8** |
| 3 | Répertoire `site/` — site vitrine pixel, piloté par les données | **0.4.9** |
| 4 | `site.yml` — workflow de déploiement du site | **0.4.9** |
| 5 | Garde-fou `versions.json` dans `verify_version.sh` | **0.4.9** |

Le découpage n'est pas cosmétique : **le lot 1 durcit le pipeline, le lot 2 s'appuie dessus**. Le job `deploy-site` du lot 2 dépend de `smoke-test`, qui n'existe qu'après le lot 1. Livrer dans l'ordre inverse publierait une page annonçant une version dont personne n'a vérifié qu'elle se charge.

### Hors périmètre

- **Notification Discord en cas d'échec.** GitHub envoie déjà un e-mail à l'auteur du run. Une alerte rouge sur Discord ajouterait du bruit sans ajouter d'information, et doublerait la surface à tester.
- **Site bilingue.** `patch_notes.json` est le seul JSON du projet exempté de la règle `_fr`/`_en` — la compétence `patch-notes-writer` n'écrit qu'en français. Un site bilingue n'aurait rien à afficher côté anglais.
- **Illustrations du jeu.** Aucune capture ni artwork n'est fourni ; la maquette validée tient entièrement en CSS.
- **Analytics, page 404 personnalisée, favicon animé.**
- **Migration des dossiers `Prototypes/Web/v*` dans le dépôt.** Ce sont des centaines de Mo de builds compilés. Ils restent hors dépôt.
- **Suppression ou archivage des prototypes legacy sur le VPS.** Ils sont listés, pas touchés.

---

## 2. Décisions verrouillées

| Sujet | Décision |
|:---|:---|
| Emplacement du site | `site/` à la racine du dépôt. `web/` est déjà pris par la coquille Flutter |
| Rendu | HTML/CSS/JS statiques, **aucun build**, aucune dépendance npm. Les données sont lues à l'exécution par `fetch()` |
| Source de vérité du site | `site/_site/versions.json`, **écrit à la main, jamais par le pipeline** — même philosophie que le tag git : le pipeline *vérifie* et *échoue* |
| Contenu éditorial | `patch_notes.json`, lu depuis le dossier de la version courante. Zéro duplication |
| Polices | Press Start 2P (titres) + VT323 (corps), **auto-hébergées** en woff2. Licence OFL, redistribution autorisée |
| Palette | `#0B493A` et `#EAF06A` plus les variations validées le 18/08 |
| Déclencheur du déploiement site | `workflow_dispatch` + `workflow_call`. **Jamais `push`** (§7.2) |
| `--delete` sur le déploiement site | **Interdit.** La cible est la racine confinée ; `--delete` y détruirait les quinze dossiers de versions |
| Notification Discord | Sur succès uniquement, `continue-on-error: true` — un webhook muet ne doit jamais invalider une release réussie |

---

## 3. État vérifié du terrain (19/08/2026)

### 3.1 Le site existe déjà, hors dépôt

La source du site vit dans `../Prototypes/Web/`, **à côté du dépôt et non dedans** : `index.html`, `nginx_prototypes.conf`, `DEPLOYMENT_GUIDE.md`, plus un miroir local des quatorze dossiers déployés. Rien de tout cela n'est versionné.

`index.html` fait 182 lignes, entièrement écrites à la main : palette indigo/slate, `Segoe UI`, quatorze cartes en dur. Chaque nouvelle version demande d'éditer le HTML, de le remonter par `scp`, et de ne pas se tromper.

### 3.2 La version 0.4.7 n'est pas listée

Le pipeline a déployé `/v0.4.7/` le 18/08. La page de sélection n'en parle pas : elle met encore `v0.0.9` en vedette. **La version courante du jeu est en ligne, jouable, et invisible depuis la page d'accueil.** C'est exactement le manque qui déclenche ce chantier.

### 3.3 Les dossiers legacy ne sont joignables à aucune patch note par calcul

Vérifié en lisant le `version.json` que Flutter écrit dans chaque build :

```
v0.0.1 … v0.0.9, v1 … v5   →   "version":"0.1.0" pour les quatorze
```

Les quatorze dossiers rapportent **la même version applicative `0.1.0`**. Leurs noms sont des **numéros de déploiement**, pas des numéros de version : `pubspec.yaml` n'a jamais été incrémenté à cette époque, ce que P-01 a corrigé le 03/08.

Conséquence directe sur la conception : `patch_notes.json` contient 34 entrées de `0.0.1` à `0.4.7`, **mais aucune `0.0.5` à `0.0.9`**. Les quatre collisions de noms (`v0.0.1` à `v0.0.4`) sont des coïncidences : les builds déployés dans ces dossiers étaient tous des `0.1.0`.

> [!WARNING]
> Une jointure automatique « nom de dossier → patch note » produirait des associations **fausses** sur quatre entrées et vides sur dix. Le lien doit être **déclaré explicitement** par entrée, et pouvoir être nul. C'est la raison d'être du champ `notes` du §5.

**Suite, 20/08/2026.** Une association a bien été rétablie depuis — non par calcul, mais par déclaration : le dossier `v0.0.5` porte la note `0.0.4`. L'auteur l'a confirmée, et la date la corrobore, la note étant datée du 15/05, jour exact du build de `v0.0.5`. C'est la démonstration en positif du champ `notes` : aucune dérivation depuis l'`id` n'aurait trouvé ce lien, puisqu'elle aurait cherché une note `0.0.5` qui n'existe pas.

### 3.4 Un lien vers un dossier inexistant renvoie 500, pas 404

Le BLOC 2 de nginx est `try_files $uri $uri/ /$1/index.html`. Si `/v9.9.9/` n'existe pas, la cible de repli n'existe pas non plus et nginx boucle : `rewrite or internal redirection cycle`, **HTTP 500**. Constaté en production le 17/08.

C'est pourquoi `versions.json` ne doit lister que des dossiers réellement en ligne, et pourquoi le `smoke-test` du §8 vaut la peine.

### 3.5 Le contrat de service nginx

| Bloc | Portée | Ce qu'il garantit |
|:---|:---|:---|
| BLOC 1 | `location /` | `try_files $uri $uri/ =404` — sert les fichiers de la racine. **Le site vitrine passe par là** |
| BLOC 2 | `location ~ ^/(v[0-9][^/]*)` | Sert chaque dossier de version en SPA. `_site` et `versions.html` ne matchent pas : pas de chiffre après le `v` |
| BLOC 3 | `location /heros-draft/` | Legacy. Présence sur le VPS **non vérifiée** — voir §12 |
| Sécurité | `location ~ /\.` | `deny all`. Le répertoire `_site` commence par un souligné, pas un point : servi normalement |

**Aucune modification nginx n'est requise.** Comme pour P-04, c'est une propriété vérifiée, pas une chance.

### 3.6 Les patch notes sont déjà publiées

`https://heros-draft.vilarserver.com/v0.4.7/assets/assets/data/patch_notes.json` renvoie **200 avec les 34 entrées** — vérifié le 18/08. Flutter embarque `assets/data/` dans chaque build web, donc l'historique complet est déjà en ligne, même origine, sans CORS.

**L'historique des patch notes est un sous-produit gratuit du déploiement existant.** Il ne demande aucune modification du pipeline.

---

## 4. Le répertoire `site/`

```
site/
├── index.html              # accueil
├── versions.html           # archive jouable
├── notes.html              # historique des patch notes
├── nginx.reference.conf    # copie lecture seule, jamais déployée (§4.3)
└── _site/
    ├── style.css
    ├── js/
    │   ├── data.js         # chargement + jointure — aucune manipulation du DOM
    │   ├── render.js       # fonctions pures : données → fragment DOM
    │   └── main.js         # point d'entrée unique, aiguille sur data-page
    ├── versions.json       # source de vérité (§5)
    └── fonts/
        ├── press-start-2p-latin.woff2
        ├── vt323-latin.woff2
        └── OFL.txt
```

### 4.1 Pourquoi trois modules JS et pas un seul

`data.js` ne touche jamais au DOM ; `render.js` ne fait jamais de requête réseau. La frontière permet de vérifier la jointure sans navigateur, et de retoucher le rendu sans risquer de casser le chargement. `main.js` lit `document.body.dataset.page` et appelle le rendu correspondant — une quinzaine de lignes.

Modules ES natifs, `<script type="module">`. Ils exigent un serveur HTTP : en développement, `python -m http.server` depuis `site/`. Ouvrir `index.html` en `file://` ne fonctionnera pas, et c'est le seul inconvénient de ce choix.

### 4.2 Les trois pages

| Page | Répond à | Source |
|:---|:---|:---|
| `index.html` | « C'est quoi, et j'y joue comment ? » | `versions.json` (entrée `current`) + première entrée de `patch_notes.json` |
| `versions.html` | « Quelles versions puis-je lancer ? » | `versions.json` en entier, groupé par `channel` |
| `notes.html` | « Qu'est-ce qui a changé depuis le début ? » | `patch_notes.json` en entier, 34 entrées |

La maquette d'accueil validée le 19/08 porte deux liens distincts — « voir toutes les notes (34 versions) » et « voir les 14 versions ». Ils mènent à deux pages différentes parce qu'ils répondent à deux questions différentes : *ce qui a changé* n'est pas *ce qui est jouable*. Sur les quinze dossiers en ligne aujourd'hui, **un seul** a une patch note, et `patch_notes.json` décrit trente-quatre versions dont trente-trois ne sont plus jouables nulle part. Les deux listes ne se recouvrent presque pas.

### 4.3 `nginx.reference.conf`

Copie versionnée de la configuration servie, **jamais déployée**. Le site dépend du comportement exact des BLOC 1 et BLOC 2 (§3.5) ; laisser ce contrat dans un fichier non versionné à côté du dépôt, c'est accepter qu'il dérive sans que personne le voie. Un en-tête de commentaire indique qu'il s'agit d'un miroir en lecture seule et que la vérité est sur le VPS.

### 4.4 Typographie et dégradation

Deux polices, validées le 19/08 : **Press Start 2P** pour les titres, badges, numéros et libellés ; **VT323** pour tout le corps de texte. Press Start 2P est à chasse fixe et illisible sur un paragraphe — or les patch notes sont de vraies phrases longues, 150 caractères pour celle de la Besace de l'Érudit.

Auto-hébergées en woff2, sous-ensemble latin, avec `font-display: swap` et une pile de repli `monospace`. Aucune requête vers Google.

**Sans JavaScript**, les trois pages affichent un `<noscript>` renvoyant vers la version courante et vers la page des releases GitHub. Le site reste utilisable, seulement moins joli. Acceptable pour une vitrine de jeu.

**Responsive** : grille en `repeat(auto-fit, minmax(...))`, une colonne sous 600 px.

---

## 5. `versions.json` — la source de vérité

### 5.1 Schéma

```json
{
  "id":      "v0.4.7",
  "label":   "0.4.7",
  "channel": "current",
  "date":    "2026-08-18",
  "notes":   "0.4.7",
  "windows": true
}
```

| Champ | Rôle |
|:---|:---|
| `id` | **Nom du dossier sur le VPS, donc segment d'URL.** Clé primaire, unique. Le lien est `/{id}/` |
| `label` | Ce que lit le joueur. Découplé de `id` parce que les dossiers legacy s'appellent `v3` |
| `channel` | `current` \| `stable` \| `legacy`. Pilote le groupement et la mise en vedette |
| `date` | Date de mise en ligne, ISO, **ou `null`**. Affichée quand elle existe. L'ordre d'affichage est celui du fichier, pas celui des dates. Le format est vérifié par le garde-fou (§5.4) |
| `notes` | Clé de jointure dans `patch_notes.json`, **ou `null`** (§3.3) |
| `windows` | Une release GitHub existe. L'URL de téléchargement se déduit de `id` |

L'URL du zip Windows n'est jamais stockée : elle vaut toujours
`https://github.com/Hex-Umbra/hero-s-draft/releases/download/{id}/heros-draft-{id}-windows.zip`,
puisque le tag est `id` et que `release.yml` nomme l'asset ainsi. Une donnée dérivable n'est pas une donnée à maintenir.

### 5.2 Le poids du zip

La maquette affiche « Windows · 58 Mo ». Ce poids n'est **pas** dans `versions.json` : il n'existe pas encore au moment où l'entrée est écrite, puisque le build n'a pas eu lieu.

Il est obtenu par **amélioration progressive** : `data.js` interroge `https://api.github.com/repos/Hex-Umbra/hero-s-draft/releases/tags/{id}` et lit la taille de l'asset. L'API GitHub autorise le CORS. En cas d'échec — quota de 60 requêtes/heure atteint, réseau coupé, release absente — le libellé se réduit à « Windows » et **le lien de téléchargement fonctionne quand même**, parce qu'il est construit sans l'API.

À noter : `/releases/latest` serait inutilisable ici. Toutes nos releases sont `prerelease: true` et cet endpoint les ignore.

### 5.3 Amorçage

Quinze entrées, écrites une fois :

| `channel` | Entrées |
|:---|:---|
| `current` | `v0.4.7` — `notes: "0.4.7"`, `windows: true` |
| `stable` | `v0.0.9` à `v0.0.1` — neuf entrées, `windows: false`. Huit ont `notes: null` ; `v0.0.5` porte `notes: "0.0.4"` (§3.3) |
| `legacy` | `v5` à `v1` — cinq entrées, `notes: null`, `windows: false` |

`v0.0.9` perd sa vedette au profit de `v0.4.7` : c'est la correction du §3.2.

Les dates des quatorze anciennes entrées ont d'abord valu `null`, puis ont été relevées le 20/08/2026. La source retenue n'est pas le VPS mais l'archive locale des builds (`Prototypes/Web/`), dont les fichiers portent encore l'horodatage de compilation Flutter : dans chaque dossier, `flutter_bootstrap.js`, `main.dart.js`, `version.json` et `.last_build_id` se suivent à la minute, dans l'ordre où Flutter les émet. C'est la date de construction, pas celle d'une copie ultérieure.

Ces dates confirment le §3.3 par un second chemin, indépendant du `version.json` : le dossier `v0.0.1` date du 05/05, quand la patch note `0.0.1` date du 01/02 — trois mois d'écart. Pour `0.0.4`, la note (15/05) est même postérieure au dossier `v0.0.4` (09/05). Joindre sur l'`id` aurait donc bien produit quatre associations fausses, dont une antidatée.

Le champ reste nullable par contrat : une entrée future peut légitimement arriver sans date. C'est le format, et non la présence, que le garde-fou vérifie (§5.4).

### 5.4 Le garde-fou

`verify_version.sh` gagne cinq assertions sur `site/_site/versions.json`, avec un `VERSIONS_PATH` surchargeable comme les deux chemins existants :

1. le fichier est du JSON valide ;
2. **exactement une** entrée porte `channel: "current"` ;
3. cette entrée a `id == "v${VERSION}"` **et** `notes == "${VERSION}"` ;
4. tous les `id` sont uniques ;
5. toute `date` **présente** respecte `AAAA-MM-JJ` (une `date` à `null` reste valide).

La cohérence avec `patch_notes.json` est alors transitive : le script vérifie déjà que `patch_notes[0].version == VERSION`, donc l'assertion 3 suffit à garantir que la jointure de l'accueil aboutira.

L'assertion 5 couvre une panne du même genre, un cran plus bas : `formatDate()` renvoie `null` sur une date malformée, la carte perd sa ligne de méta, et rien ne signale que l'information a disparu. Une faute de frappe effacerait donc en silence ce qu'elle était censée porter.

**Ce que ce garde-fou achète.** Oublier l'entrée `versions.json` ne produit aucune erreur visible : le site déploie, s'affiche, et ment simplement sur la version courante — exactement la panne silencieuse du §3.2. Le garde-fou la transforme en échec de pipeline avant le moindre build.

### 5.5 Qui écrit l'entrée

La compétence `patch-notes-writer` (`.claude/skills/patch-notes-writer/SKILL.md`) maintient déjà `patch_notes.json` et le champ `version:` de `pubspec.yaml` de façon synchrone. **Son périmètre passe de deux fichiers à trois** : elle ajoute désormais la nouvelle entrée `current` dans `versions.json` et rétrograde l'ancienne en `stable`.

C'est le bon foyer : ce sont les trois fichiers qui doivent changer ensemble à chaque release, dans le même commit, juste avant le tag. `CLAUDE.md` doit être mis à jour en conséquence — c'est le seul endroit du dépôt qui décrit ce périmètre.

---

## 6. Flux de données

```
                    site/_site/versions.json      (dépôt, écrit à la main)
                               │
                               ▼
index.html ─── data.js ─── jointure sur `notes` ─── render.js ─── DOM
                               ▲
                               │
    /v{current}/assets/assets/data/patch_notes.json   (déjà en ligne, §3.6)
```

`data.js` expose deux fonctions et rien d'autre :

- `loadVersions()` → le tableau de `versions.json`, trié, avec l'entrée `current` isolée ;
- `loadNotes(currentId)` → les 34 entrées de patch notes, lues sous `/{currentId}/assets/assets/data/patch_notes.json`.

**Pourquoi lire les patch notes depuis le dossier de version plutôt que d'en copier un exemplaire à la racine.** Le chemin est immuable pour une version donnée, donc le cache navigateur joue à plein sans invalidation à gérer ; le fichier servi est exactement celui embarqué dans le build correspondant, sans risque de dérive ; et surtout le pipeline n'a **aucune ligne à ajouter**. Le prix est une dépendance : si le dossier de la version courante disparaît du VPS, l'accueil perd sa section « quoi de neuf ». Elle se replie alors sur un lien vers les releases GitHub, et le reste de la page est intact.

### Gestion des échecs, côté page

| Échec | Comportement |
|:---|:---|
| `versions.json` illisible | Message d'erreur explicite dans le cadre, lien de secours écrit en dur dans le HTML |
| `patch_notes.json` illisible | La section « quoi de neuf » se remplace par un lien vers les releases GitHub. Le reste s'affiche |
| API GitHub indisponible | Le poids du zip disparaît, le lien de téléchargement reste (§5.2) |
| JavaScript désactivé | `<noscript>` avec les deux liens essentiels (§4.4) |
| Entrée `notes` sans patch note correspondante | La carte s'affiche sans description. Aucune erreur — c'est le cas nominal des quatorze legacy |

Aucun de ces échecs ne produit une page blanche.

---

## 7. Déploiement du site

### 7.1 `site.yml`

```yaml
on:
  workflow_dispatch:
  workflow_call:
```

Un seul job, `deploy`, `timeout-minutes: 10` :

1. `checkout` avec `ref: ${{ github.sha }}` — même règle que les cinq checkouts de `release.yml` : un run doit toujours porter sur le commit qui l'a déclenché ;
2. `webfactory/ssh-agent` avec `VPS_SSH_KEY`, SHA pinné à l'identique ;
3. `VPS_KNOWN_HOSTS` dans `~/.ssh/known_hosts` — pas de `ssh-keyscan`, pas de TOFU ;
4. `rsync -avz --exclude='nginx.reference.conf' site/ "${VPS_USER}@${VPS_HOST}:./"` — **sans `--delete`**.

L'exclusion n'est pas cosmétique : `nginx.reference.conf` est un document interne (§4.3), pas un fichier de site. Sans elle il serait servi en clair à la racine du domaine.

`release.yml` l'appelle :

```yaml
deploy-site:
  needs: [verify-version, smoke-test]
  uses: ./.github/workflows/site.yml
  secrets: inherit
```

### 7.2 Pourquoi pas de déclencheur `push`

Un `on: push: paths: ['site/**']` semblerait naturel — le site se redéploierait quand son contenu change. Il produirait une fenêtre de mensonge : le commit de préparation de release modifie `versions.json`, donc le site annoncerait `v0.4.9` **avant** que `/v0.4.9/` n'existe. Le visiteur qui clique tombe sur un HTTP 500 (§3.4), et le site se redéploierait deux fois par release.

`workflow_call` garantit l'ordre : le site n'est mis à jour qu'après que `smoke-test` a prouvé que la version est servie. Une retouche CSS isolée demande un clic sur « Run workflow » — un geste manuel, rare, contre une classe entière de liens morts.

### 7.3 Pourquoi jamais `--delete`

`deploy-web` écrit dans `:v{VERSION}/`, un dossier neuf : `--delete` y est sans danger et le préfixe `v` littéral verrouille la cible. **Le déploiement du site écrit dans la racine confinée elle-même**, où vivent les quinze dossiers de versions. Un `--delete` les effacerait tous en une commande.

Sans `--delete`, un fichier de site supprimé du dépôt survit sur le serveur. Le coût est nul : personne ne le référence. Le bénéfice est qu'aucun verbe destructeur n'existe sur ce chemin, donc aucune régression future ne peut l'y réintroduire par inadvertance.

Le rangement sous `_site/` sert le même objectif : la racine du VPS ne reçoit que trois fichiers HTML, tout le reste est isolé dans un sous-dossier qui ne peut entrer en collision ni avec un dossier de version, ni avec la règle `deny all` sur les fichiers cachés (§3.5).

> [!CAUTION]
> **À valider à la main avant d'en dépendre**, exactement comme la clé SSH l'a été pour P-04 : la commande forcée est `rrsync -wo /var/www/prototypes`, et rien ne prouve encore qu'elle accepte une cible **vide** (`host:./`) pour écrire dans la racine confinée. Le §12 en fait l'étape 0.

---

## 8. `smoke-test`

Nouveau job, `needs: [verify-version, deploy-web]`, `timeout-minutes: 5`. Il appelle `.github/scripts/smoke_test.sh "${BASE_URL}" "${VERSION}"`.

Quatre assertions sur la version fraîchement déployée :

| # | Vérification | Ce qu'elle attrape |
|:---:|:---|:---|
| 1 | `GET /v{V}/` → 200 | Le rsync n'a rien écrit, ou nginx ne sert pas le dossier |
| 2 | La page contient `<base href="/v{V}/">` | `--base-href` oublié ou mal formé — la panne « page blanche » du §6 de la spec P-04, attrapée automatiquement |
| 3 | `GET /v{V}/main.dart.js` → 200 | Build web incomplet |
| 4 | `GET /v{V}/assets/assets/data/patch_notes.json` → 200 | Le chemin dont dépend l'accueil (§6) |

Trois tentatives espacées de cinq secondes avant de conclure à l'échec, pour absorber un aléa TLS ou réseau. Un échec est **rouge et bloquant** : ni `deploy-site` ni `notify-discord` ne partiront, donc rien n'annoncera une version cassée.

L'assertion 2 justifie le job à elle seule. C'est la vérification faite à la main le 18/08 pour déclarer P-04 réellement en service, et la seule qui distingue « les fichiers sont sur le disque » de « le jeu se lance ».

**Testabilité.** Le script est appelable localement et `test_scripts.sh` couvre sa validation d'arguments — URL manquante, version manquante, version non semver — sans toucher au réseau. Son comportement réseau, lui, n'est pas simulé : ce serait reconstruire un serveur pour tester un `curl`.

---

## 9. `notify-discord`

Nouveau job, `if: success()`, `continue-on-error: true`. Ses dépendances **changent entre les deux lots**, parce que `deploy-site` n'existe pas encore au lot 1 :

| Lot | `needs` |
|:---|:---|
| 1 — release 0.4.8 | `[verify-version, smoke-test, release-windows]` |
| 2 — release 0.4.9 | `[verify-version, deploy-site, release-windows]` |

Dans les deux cas, l'annonce ne part qu'une fois la version **prouvée servie**. Au lot 2, `deploy-site` dépendant lui-même de `smoke-test`, la garantie est conservée et s'enrichit : la version est aussi **listée sur le site** quand le message tombe, donc le lecteur qui clique trouve une page à jour.

`continue-on-error: true` parce qu'un webhook expiré ne doit pas peindre en rouge une release par ailleurs parfaite. Le job apparaît en avertissement, la release reste valide.

`.github/scripts/discord_payload.sh` construit le corps :

| Champ | Contenu |
|:---|:---|
| titre | `Hero's Draft v0.4.8 — <titre de la patch note>` |
| url | `https://heros-draft.vilarserver.com/v0.4.8/` |
| couleur | `15396970` — soit `0xEAF06A`, le jaune de la charte |
| description | les patch notes markdown, tronquées à 4000 caractères |
| champs | ▶ Jouer dans le navigateur · ⬇ Télécharger pour Windows · 📄 Release GitHub |

Trois contraintes non négociables :

- **Le JSON est construit par `jq -n`, jamais par concaténation.** Les patch notes contiennent apostrophes, guillemets, emojis et sauts de ligne ; un `printf` produirait du JSON invalide dès la première apostrophe française.
- **`DISCORD_WEBHOOK_URL` passe par `env:`, jamais par `${{ }}` dans le corps d'un `run:`.** C'est la règle d'injection de script déjà appliquée à `inputs.version` dans `release.yml`.
- **La description est tronquée à 4000 caractères** — la limite Discord est 4096 — avec un suffixe renvoyant vers la release GitHub. La patch note 0.4.7 fait déjà environ 1 800 caractères ; le plafond sera atteint un jour.

`release_body.sh` produit déjà ce markdown et est réutilisé tel quel — c'était l'intention notée au §1 de la spec P-04 en reportant ce job.

**Prérequis utilisateur** : créer le webhook sur le salon Discord voulu, puis le secret `DISCORD_WEBHOOK_URL` dans le dépôt.

---

## 10. Sécurité

Les quatre règles de la spec P-04 s'appliquent sans exception aux nouveaux fichiers de workflow et de script.

| Règle | Application ici |
|:---|:---|
| Actions tierces pinnées au SHA complet | `site.yml` réutilise les **mêmes SHA** que `release.yml` pour `checkout` et `ssh-agent`. Un SHA divergent entre deux workflows est une dérive silencieuse |
| Permissions minimales | `site.yml` : `permissions: contents: read`. Les nouveaux jobs de `release.yml` n'obtiennent aucune permission supplémentaire — `contents: write` reste l'apanage de `release-windows` |
| Aucune valeur externe interpolée dans un corps de script | `DISCORD_WEBHOOK_URL` passe par `env:`. Les arguments de `smoke_test.sh` sont un littéral et une sortie de `verify-version` déjà validée en semver, jamais une saisie utilisateur |
| Pas de TOFU | `site.yml` réutilise `VPS_KNOWN_HOSTS` |

Un point nouveau : le dépôt est **public**, donc `site/` l'est aussi. Il ne doit contenir ni URL d'administration, ni chemin serveur interne, ni adresse. `nginx.reference.conf` ne contient que ce qui est déjà déductible d'une requête HTTP — nom de domaine et chemins Certbot standard.

---

## 11. Gestion des erreurs et reprise

| Situation | Comportement |
|:---|:---|
| `smoke-test` échoue | Le dossier de version reste en ligne, potentiellement cassé. **Ni le site ni Discord ne l'annoncent.** La page de sélection continue de pointer la version précédente |
| `deploy-site` échoue | Le site reste dans son état antérieur, complet et cohérent — il liste une version de moins. Aucune page cassée. Re-run sûr |
| `notify-discord` échoue | Run vert, job en avertissement. Aucun impact |
| Garde-fou `versions.json` en défaut | Arrêt avant tout build, message nommant le fichier et l'invariant violé |
| `versions.json` référence un dossier absent | **Non détecté par le pipeline** : `rrsync -wo` est en écriture seule, la CI ne peut pas lister le serveur. Le visiteur reçoit un 500 (§3.4). Seule la validation manuelle du §12 le couvre |

**« Re-run failed jobs » reste sûr sur tous les jobs**, y compris les trois nouveaux : aucun n'a d'effet de bord destructeur.

---

## 12. Validation

Même principe qu'au §8 de la spec P-04 : chaque étape élimine une incertitude avant que la suivante n'en dépende.

**Étape 0 — prouver l'écriture en racine, à la main, avant tout YAML.** C'est le seul inconnu structurel de cette spec (§7.3) :

```bash
echo ok > /tmp/_probe.txt && rsync -avz /tmp/_probe.txt user@host:./
curl -sS https://heros-draft.vilarserver.com/_probe.txt
```

Si `rrsync` refuse la cible vide, essayer `host:.` puis, en dernier recours, revoir la commande forcée. **Ne pas écrire `site.yml` avant d'avoir vu `ok`.** Supprimer la sonde ensuite — ce qui exige un accès SSH normal, `rrsync -wo` ne permettant pas d'effacer.

**Étape 0 bis — relever l'état réel du VPS.** Lister `/var/www/prototypes/` : confirmer les quinze dossiers, relever leurs dates pour `versions.json` (§5.3), et trancher le sort de `/heros-draft/` (§3.5) — listé, ou BLOC 3 devenu mort.

**Étape 1 — lot 1 sur la release 0.4.8.** `smoke-test` et `notify-discord` sur un tag réel. C'est le premier passage complet du pipeline sur une vraie version depuis sa mise en service : le test `v9.9.9` du 18/08 n'avait prouvé que le déclencheur et le garde-fou, quatre jobs sur six ayant été sautés.

**Étape 2 — le site en local.** `python -m http.server` depuis `site/`, avec un `versions.json` amorcé. Les trois pages doivent s'afficher, et les cinq modes de dégradation du §6 doivent être provoqués un par un : renommer `versions.json`, couper le réseau, désactiver JavaScript.

**Étape 3 — `site.yml` en `workflow_dispatch` seul.** Le site part en ligne sans qu'aucune release ne soit en jeu. L'accueil doit alors afficher `0.4.8` en vedette avec ses vraies patch notes, et `versions.html` doit lister seize entrées dont les quatorze legacy restées cliquables.

**Étape 4 — lot 2 sur la release 0.4.9.** Chaîne complète : garde-fou → build → déploiement → smoke test → site → Discord.

Vérification finale attendue : la racine du domaine affiche le nouveau site, `0.4.9` en vedette, les quinze anciennes versions toujours accessibles, et un message Discord dont chacun des trois liens aboutit.

---

## 13. Effort

| Poste | Estimation |
|:---|:---:|
| `smoke_test.sh` + job + assertions du harnais | 0,25 j |
| `discord_payload.sh` + job + assertions du harnais | 0,25 j |
| **Lot 1 — release 0.4.8** | **≈ 0,5 j** |
| `site/` — trois pages, CSS, trois modules JS, polices | 0,75 j |
| `versions.json` — schéma, amorçage, garde-fou, harnais | 0,25 j |
| `site.yml` + intégration dans `release.yml` | 0,25 j |
| Validation manuelle (étapes 0, 0 bis, 2) | 0,25 j |
| **Lot 2 — release 0.4.9** | **≈ 1,5 j** |
| **Total** | **≈ 2 j** |

Aucun sourcing d'asset : les deux polices sont sous OFL.

---

## 14. Ce que ce chantier ferme

| Manque | Fermé par |
|:---|:---|
| La version courante est en ligne mais invisible depuis l'accueil (§3.2) | §5, l'entrée `current` |
| Chaque release exige une édition HTML à la main et un `scp` | §7, `site.yml` |
| La source du site n'est pas versionnée (§3.1) | §4, le répertoire `site/` |
| Un déploiement peut réussir en livrant une page blanche | §8, assertion 2 |
| Une release réussie n'est annoncée nulle part | §9 |
| Rien ne relie le site au contrat nginx dont il dépend | §4.3 |
