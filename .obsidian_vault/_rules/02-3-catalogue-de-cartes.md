### 2.3. Catalogue de Cartes

Le catalogue comprend **23 cartes**, un fichier par carte, le nom du fichier étant l'`id` —
**re-mesuré le 2026-09-05** (cette fiche annonçait 21 cartes dont 15 globales) :
- **17 cartes globales (neutres)** sous `assets/data/cards/`.
- **6 cartes de classe spécifiques** sous `assets/data/classes/<classe>/cards/` (2 par classe : `holy_shield` et `smite` pour le Paladin, `reckless_strike` et `rage_form` pour le Berserker, `magic_missile` et `mana_surge` pour le Mage).

Une carte de classe **ne déclare ni `heroClass` ni `category`** : son répertoire les impose, et
les écrire fait échouer le chargement — [ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md).

### Règles Métier et Équilibrage des Cartes
- **Rareté Unique pour les cartes de classe** : Les 6 cartes de classe ont la rareté `unique` (définie dans l'enum `CardRarity`). Le multiplicateur de statistiques de base de cette rareté est de `1.0` (défini dans `card_instance.dart`).
- **Capacité de Forge Fixe** : une carte de classe porte **5 runes au plus** (`baseMaxForgeUpgrades: 5`), la rareté `unique` n'ajoutant aucun emplacement — [ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md). Jusqu'au 2026-09-15, le code lui en accordait 10.
- **Interdiction de Fusion & Acquisition** : Les cartes uniques ne peuvent pas être fusionnées (aucun bouton dans l'UI, `CardRarity.next` nul dans `deck_controller.dart`). Aucune source ne les fait entrer dans le deck en cours de run : ni l'étal ni le Miroir Magique de la boutique, ni le draft ni la carte bonus de boss, ni le Miroir de montée de niveau (`CardRarity.isAcquirable`). Avant le 2026-09-15, les trois sources qui **copient depuis le deck** les proposaient.
- **Association par le champ `skills`** : `assets/data/classes/<classe>/class.json` associe chaque héros à ses cartes de classe de départ par le champ `"skills"`, une liste d'`id` de cartes. La méthode d'extension `HeroSkillsLink.getHeroCards(gameData)` les résout dynamiquement. ⚠️ **Homonyme sans rapport** avec le système de compétences héroïques, supprimé du jeu — [ADR-084](../_adr/ADR-084-suppression-de-la-chaine-de-competences-heroiques.md). L'intégrité de ce lien est gardée par `test/unit/referential_integrity_test.dart`.
- **Harmonisation des Cartes Globales** : Les 17 cartes globales possèdent toutes la rareté de base `common` — vérifié le 2026-09-05 — et ont été rééquilibrées autour de ratios de Valeur Par Mana (VPM) standardisés :
  - `heal_potion` : Coût 1 mana, Soin 3, Épuisement (`isExhaust: true`) — re-mesuré le 2026-09-15, la fiche annonçait Soin 4.
  - `iron_wall` : Coût 2 mana, Blocage 10.
  - `heavy_strike` : Coût 2 mana, Dégâts 12.

**Types d'effets utilisés** : `damage`, `armor`, `draw`, `heal`, `apply_status`, `gain_mana`.

**Animations data-driven** : Chaque carte possède un champ `animation` optionnel parmi : `melee`, `magic`, `buff`, `poison`, `fire`, `ice`, `lightning`.

**Propriétés d'une carte** (`CardData`) :
- `id`, `nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`, `cost` (0-3 mana)
- `type` : attack, skill, power, status
- `category` : global, characterSpecific
- `rarity` : common, uncommon, rare, epic, legendary, unique
- `target` : singleEnemy, allEnemies, self, none
- `isExhaust` : boolean (carte épuisée après usage)
- `effects` : List\<CardEffect\> avec `type`, `value`, `statusId?`, `duration?`
- `heroClass?` : null (global) ou "paladin"/"berserker"/"mage"
