### 2.3. Catalogue de Cartes

Le catalogue comprend **17 cartes**, toutes neutres, un fichier par carte sous `assets/data/cards/`,
le nom du fichier étant l'`id` — **re-mesuré le 2026-10-16** (`ls assets/data/cards | wc -l`).
Les six cartes de classe qu'il comptait jusqu'au lot E4 de P-43 **ne sont plus des cartes** : ce
sont les **signatures**, rangées sous `assets/data/classes/<classe>/skills/`, hors du deck — leur
règle est en [`_rules/02-2`](02-2-systeme-de-heros.md) §Signatures (branche de la vague 4,
[ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md)).

Une carte **ne déclare ni `heroClass` ni `category`** : `CardData.fromJson` refuse les deux clés,
nommées, et le chargeur ne les injecte plus — `CardData.heroClass` et `CardCategory` ont disparu
avec les cartes de classe (ADR-109, qui complète
[ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md)). L'appartenance
d'une carte à un passif reviendra à la vague 5, par un champ injecté.

### Règles Métier et Équilibrage des Cartes
- **Cinq raretés, une échelle** : `common` → `legendary` ; la rareté `unique`, hors échelle, a
  disparu avec les cartes de classe, et avec elle `CardRarity.isAcquirable` — ADR-109, qui amende
  [ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md) D1 et D2.
  Toute carte fusionne jusqu'à `legendary` ([`_rules/02-4`](02-4-progression-de-rarete-dynamique-et-fusion-int.md)).
- **Un prédicat d'offre, sans paramètre** : `CardData.isOfferable` — vrai sauf pour un statut —
  dit quelles cartes un joueur peut recevoir : l'étal de la boutique, la carte trouvée après chaque
  combat, **le draft de départ** et le pool du tutoriel. ADR-109 amende
  [ADR-101](../_adr/ADR-101-predicat-de-proposabilite-unique-et-draft-de-depart.md) D1 et D3. Les
  sources qui **copient depuis le deck** (draft de boss, les deux Miroirs, la copie vendue en
  boutique) lisent `DeckState.copyableCards`, désormais le deck entier.
- **Harmonisation des Cartes Globales** : Les 17 cartes globales possèdent toutes la rareté de base `common` — vérifié le 2026-09-05 — et ont été rééquilibrées autour de ratios de Valeur Par Mana (VPM) standardisés :
  - `heal_potion` : Coût 1 mana, Soin 3, Épuisement (`isExhaust: true`) — re-mesuré le 2026-09-15, la fiche annonçait Soin 4.
  - `iron_wall` : Coût 2 mana, Blocage 10.
  - `heavy_strike` : Coût 2 mana, Dégâts 12.

**Types d'effets utilisés** : `damage`, `armor`, `draw`, `heal`, `apply_status`, `gain_mana`.

**Animations data-driven** : Chaque carte possède un champ `animation` optionnel parmi : `melee`, `magic`, `buff`, `poison`, `fire`, `ice`, `lightning`.

**Propriétés d'une carte** (`CardData`) — re-lues le 2026-10-16 :
- `id`, `nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`, `cost` (0-3 mana)
- `type` : attack, skill, power, status
- `rarity` : common, uncommon, rare, epic, legendary
- `target` : singleEnemy, allEnemies, self, none
- `isExhaust` : boolean (carte épuisée après usage)
- `effects` : List\<CardEffect\> avec `type`, `value`, `statusId?`, `duration?`
- ni `category` ni `heroClass` : refusés au chargement (ADR-109)
