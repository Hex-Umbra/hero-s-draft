### Statut

✅ **Livré le 2026-09-05**, chantier P-48 lot 3, PR #35.
Complète [ADR-085](ADR-085-regle-de-partage-catalogue-configuration.md), qui décidait
*quels* fichiers éclater sans dire *ce que leur emplacement signifie*. Prolonge
[ADR-003](ADR-003-architecture-100-data-driven.md).

### Contexte

Une fois les catalogues éclatés, chaque entité devient un fichier. Restait la question de
l'**appartenance** : qu'est-ce qui fait d'une carte une carte du paladin ?

Dans les catalogues, c'était un champ. `hero_cards.json` portait `"heroClass": "paladin"` sur
chaque entrée, à côté de `"category": "characterSpecific"`. Rien n'empêchait une entrée d'être
rangée sous une classe et d'en déclarer une autre — le fichier était plat, il n'y avait pas de
rangement.

Avec un fichier par entité rangé dans `assets/data/classes/paladin/cards/`, deux sources
d'appartenance coexistent : le chemin, et le champ. Trois options se présentaient — le champ
fait foi (rien ne change, le rangement ne veut rien dire), le chemin fait foi et le champ est
interdit, ou le chemin fait foi et le champ peut confirmer.

### Décision

**D1 — Le répertoire fait autorité (option C).** Le chargeur **injecte** l'appartenance depuis
les segments capturés du chemin. Le fichier a le droit de **confirmer à l'identique** pour les
champs listés dans `EntitySource.redundantFields`. La **contradiction échoue au chargement**,
en nommant le fichier, le champ, la valeur imposée et la valeur trouvée.

L'option « champ interdit » aurait été plus pure, mais elle empêchait la migration : les 71
fichiers étaient produits par découpage des catalogues, champs compris.

**D2 — La tolérance sur `heroClass` et `category` a expiré**, à la tâche 9 du lot 3, une fois
le découpage terminé et vérifié. Les déclarer est désormais une **erreur de chargement**.
Une tolérance de migration qui survit à sa migration devient une seconde vérité.

**D3 — L'`id` reste redéclarable, à titre permanent.** C'est la seule exception, et elle est
délibérée : porter l'`id` dans le fichier le rend lisible hors contexte, et inspectable en
masse (`jq -s '.' assets/data/relics/*.json` rend des objets identifiés). Le nom du fichier
reste la source ; le champ doit être identique ou le chargement échoue.

**D4 — Les passifs sont exclus de l'injection d'appartenance.** `PassiveData` n'a pas de champ
`heroClass` : une injection y serait **silencieusement jetée par `fromJson`** — un no-op
qu'aucun test ne pourrait détecter, et donc une garantie fausse. Ils restent à plat sous
`assets/data/passives/`, liés à leur classe par `HeroData.passiveTrait`. P-41 refait
entièrement ce modèle.

**D5 — L'image de l'entité vit dans le dossier de l'entité.** Une classe est
`classes/<id>/{class.json, icon.png, cards/}`, un ennemi `enemies/<id>/{enemy.json,
sprite.png}`. Le dossier est auto-suffisant : ajouter un ennemi, c'est créer un dossier, pas
toucher quatre fichiers dispersés.

**D6 — Le préfixe d'images de Flame est vidé, les chemins sont complets.** `Images.prefix`
**ne fait pas partie des clés du cache** : sous un préfixe par dossier, les trois `icon.png`
de classes s'écraseraient mutuellement dans un espace de clés partagé. Les chemins complets
sont les clés.

### Preuves dans le code

- `EntitySource` et `GameDataLoader._applyInjection`
  (`lib/services/game_data_loader.dart`) — motif de chemin, injection, règle de conflit.
- `redundantFields` vaut `const {'id'}` par défaut ; **aucune source de production ne le
  surcharge** (`lib/services/game_data_service.dart`).
- Le commentaire de la source des passifs porte D4 en toutes lettres.
- `test/unit/entity_id_convention_test.dart` — le nom de fichier est l'`id`, en `snake_case`
  ASCII minuscule.
- `test/unit/flame_image_prefix_test.dart` — 8 clés distinctes égales aux chemins complets ;
  le test tombe sous un préfixe non vide.
- `test/unit/referential_integrity_test.dart` — aucun dossier de classe sans son `icon.png`.

### Conséquences

- ✅ **Une carte mal rangée ne se charge pas.** L'incohérence entre rangement et contenu, que
  les catalogues rendaient possible en silence, est devenue une erreur nommée.
- ✅ **Ajouter du contenu ne demande plus de code.** Un fichier au bon endroit suffit —
  procédure dans `CLAUDE.md` et `README.md`.
- ✅ **P-42 est débloqué** : ses ~25-30 cartes de classe s'écrivent directement sous
  `classes/<id>/cards/`, sans `heroClass` ni `category`.
- ⚠️ **Chaque nouveau dossier impose `dart run tool/sync_assets.dart`.** Les déclarations
  d'assets de Flutter ne sont récursives à aucun niveau, et un répertoire non déclaré ne
  produit **aucun message** : son contenu se charge en développement et disparaît en build.
  `test/unit/real_bundle_load_test.dart` est le garde-fou.
- ⚠️ **Le préfixe Flame doit rester vide.** Le remettre réintroduirait la collision de D6.
- ⚠️ `GameDataRegistry` expose toujours des `List<T>` en lookup linéaire : la conversion en
  `Map` reste au périmètre de P-26, 25 sites de construction dans 21 fichiers de test en
  dépendant.
