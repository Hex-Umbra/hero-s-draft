### 2.3. Catalogue de Cartes

Le catalogue de cartes comprend un total de **21 cartes** réparties sur deux fichiers d'assets distincts :
- **15 cartes globales (neutres)** définies dans `assets/data/cards.json`.
- **6 cartes de classe spécifiques** définies dans `assets/data/hero_cards.json` (2 par classe : `holy_shield` et `smite` pour le Paladin, `reckless_strike` et `rage_form` pour le Berserker, `magic_missile` et `mana_surge` pour le Mage).

### Règles Métier et Équilibrage des Cartes
- **Rareté Unique pour les cartes de classe** : Les 6 cartes de classe ont la rareté `unique` (définie dans l'enum `CardRarity`). Le multiplicateur de statistiques de base de cette rareté est de `1.0` (défini dans `card_instance.dart`).
- **Capacité de Forge Fixe** : Les cartes de classe possèdent un maximum d'upgrades `baseMaxForgeUpgrades` fixé à 5.
- **Interdiction de Fusion & Achat** : Les cartes uniques ne peuvent pas être fusionnées (bouton grisé dans l'UI et validation bloquée dans `deck_controller.dart`). De plus, elles n'apparaissent pas dans les tirages de récompenses post-combat (draft), dans le menu de sélection de cartes post-boss, ou en boutique pendant la run, afin de garantir un contrôle strict des récompenses de classe.
- **Association par les compétences (Skills)** : Le fichier `heroes.json` associe chaque héros à ses cartes de classe de départ par le champ `"skills"`. La méthode d'extension `HeroSkillsLink.getHeroCards(gameData)` résout dynamiquement ces cartes basées sur les compétences du héros.
- **Harmonisation des Cartes Globales** : Toutes les cartes globales du fichier `cards.json` possèdent la rareté de base `common` et ont été rééquilibrées autour de ratios de Valeur Par Mana (VPM) standardisés :
  - `heal_potion` : Coût 1 mana, Soin 4, Épuisement (`isExhaust: true`).
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
