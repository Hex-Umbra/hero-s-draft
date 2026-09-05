### 15. Chaîne de Release et Site Vitrine (`.github/` et `site/`)

Deux domaines hors du jeu, livrés par le chantier P-04. Les arbitrages qui les ont
produits vivent dans [ADR-079](../_adr/ADR-079-chaine-de-release-declenchee-par-tag-et-garde-fou.md)
(chaîne CI/CD) et [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md)
(site) ; cette fiche décrit la structure, pas les raisons.

#### 15.1. Les trois workflows

| Workflow | Déclencheur | Rôle |
|:---|:---|:---|
| `ci.yml` | push, pull request | `dart analyze`, `flutter test`, tests JS du site, harnais des scripts |
| `release.yml` | tag `v*.*.*`, `workflow_dispatch` | Neuf jobs : vérification, qualité, builds web et Windows, déploiements, smoke test, pré-release GitHub, annonce Discord |
| `site.yml` | `workflow_dispatch`, `workflow_call` | rsync de `site/` vers la racine du VPS. Appelé par `release.yml`, ou lancé seul pour une modification de contenu du site |

> [!IMPORTANT]
> **Publier une version = poser un tag, mais seulement après le patch note.**
> `verify-version` compare le tag à `pubspec.yaml`, `assets/data/patch_notes.json` et
> `site/_site/versions.json`. Le skill `patch-notes-writer` déplace ces trois fichiers
> ensemble ; taguer avant qu'il soit passé fait échouer la release avant tout build.
> Une modification qui ne touche que le site n'a pas besoin de version : lancer `site.yml`
> seul suffit.

#### 15.2. Les cinq scripts

Toute la logique de la chaîne vit dans des scripts shell testables, jamais dans des étapes
`run:` inline — c'est ce qui rend le pipeline vérifiable sans le déclencher.

| Script | Rôle |
|:---|:---|
| `verify_version.sh` | Le garde-fou. Cinq assertions sur `versions.json`, plus l'accord `pubspec` / patch notes. `PUBSPEC_PATH`, `PATCH_NOTES_PATH` et `VERSIONS_PATH` sont surchargeables pour les tests |
| `release_body.sh` | Rend la patch note la plus récente en markdown de release |
| `smoke_test.sh` | Quatre assertions HTTP sur la version fraîchement déployée, avec réessais |
| `discord_payload.sh` | Construit l'embed d'annonce avec `jq -n`, jamais par concaténation. N'envoie rien |
| `test_scripts.sh` | Harnais des quatre précédents — décompte vivant dans [`_memory_bank/progress.md`](../_memory_bank/progress.md) §Métriques |

> [!NOTE]
> Les attentes de `test_scripts.sh` sont **dérivées à l'exécution** par `jq` sur les
> fichiers réels, jamais figées en dur. Un harnais qui gèle la version courante du dépôt
> devient rouge à la release suivante.

#### 15.3. Structure du site

```
site/
├── index.html            data-page="home"      slots : cta, latest-note, recent
├── versions.html         data-page="versions"  slot  : versions
├── notes.html            data-page="notes"     slot  : notes
├── nginx.reference.conf  miroir en lecture seule du contrat serveur
├── package.json          {"type":"module"} — exclu du rsync
└── _site/
    ├── style.css
    ├── versions.json     source de vérité
    ├── fonts/            woff2 auto-hébergées, sous-ensemble latin
    └── js/  model.js · model.test.js · data.js · render.js · main.js
```

Séparation en quatre couches, dans cet ordre de dépendance :

| Module | Contrat |
|:---|:---|
| `model.js` | Logique pure : jointure, groupement, URL dérivées, formats. **Aucun réseau, aucun DOM.** Toute fonction renvoie `null` plutôt que de lever |
| `data.js` | Accès réseau **uniquement**. `loadVersions()` force la revalidation (`cache: 'no-cache'`), nginx n'envoyant aucun `Cache-Control` |
| `render.js` | Données → `HTMLElement`. Texte toujours par `textContent`, jamais `innerHTML` |
| `main.js` | Orchestration par page, pilotée par l'attribut `data-page` |

`model.js` est la seule couche testée, et c'est délibéré : sans réseau ni DOM, elle se teste
par `node --test` sans navigateur ni serveur.

#### 15.4. Conventions à respecter

- **Aucune étape de build, aucune dépendance npm.** Modules ES natifs. Ce que le dépôt
  contient est ce que le serveur sert.
- **Une donnée dérivable n'est pas une donnée à maintenir.** L'URL du zip Windows se déduit
  de l'`id` — elle n'est jamais stockée.
- **La jointure version → patch note passe par le champ `notes`, jamais par l'`id`.**
  Voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).
- **Chaque `[data-slot]` porte un repli statique.** Le JS ne le remplace qu'en cas de
  succès, et un rendu produisant zéro bloc doit renoncer plutôt qu'écraser le repli.
- **`--delete` est interdit** sur le rsync du site : sa cible est la racine confinée qui
  héberge tous les dossiers de version.
- **Aucun secret dans un corps `run:`** — uniquement par `env:`. Actions tierces épinglées
  sur un SHA de commit.
