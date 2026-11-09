### 2.3. Catalogue de Cartes

Le catalogue compte **33 cartes** : **15 neutres** sous `assets/data/cards/<id>.json` et **18 cartes
de lot**, six par passif, sous `assets/data/cards/<passif>/<id>.json` — **re-mesuré le 2026-11-04**
(`find assets/data/cards -name '*.json'`). Le nom du fichier est l'`id` ; le nom du dossier d'un lot
est l'id de son passif. La forme C est de la tranche 1 de P-42, livrée sur la branche de la vague 5,
en attente du test, de la PR, de la fusion et du tag du propriétaire —
[ADR-112](../_adr/ADR-112-forme-c-un-lot-de-cartes-par-passif.md). Les signatures ne sont pas des
cartes : leur règle est en [`_rules/02-2`](02-2-systeme-de-heros.md) §Signatures
([ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md)).

> [!IMPORTANT]
> **Le répertoire dit à quel passif une carte appartient.** Le chargeur injecte `passive` — `null`
> pour une neutre, le nom du dossier pour une carte de lot ; un fichier qui écrit `passive`,
> `heroClass` ou `category` échoue au chargement
> ([ADR-086](../_adr/ADR-086-autorite-du-repertoire-avec-expiration-de-la-toler.md)). Un dossier de
> lot neuf exige sa ligne de `pubspec.yaml` (`dart run tool/sync_assets.dart`), comme un dossier de
> classe.

### Les lots de la tranche 1

| Lot | Passif, classe | Cartes | Mécanismes |
|:---|:---|:---|:---|
| **Rempart** | `regen_armor`, Paladin | *Muraille*, *Bastion*, *Rempart brisé*, *Fortification*, *Percée*, *Éclat de bouclier* | Armure en quantité, `scaleWith: armor`, `costs.armor` |
| **Sang** | `rage`, Berserker | *Sang versé*, *Pacte de sang*, *Dernier souffle*, *Fureur sanguine*, *Transe*, *Forme Démoniaque* | `costs.hp`, `scaleWith: missingHp`, l'Éveil de Puissance |
| **Arcaniste** | `mana_flux`, Mage | *Éclat*, *Onde*, *Embrasement*, *Rafale d'étincelles*, *Nova de givre*, *Décharge* | Compétences seulement : dégâts à 1, altération pure, multi-coups, statuts proportionnels |

Les six autres passifs n'ont pas encore de lot : ils ne sont pas proposés à la sélection
([`_rules/02-2`](02-2-systeme-de-heros.md) §Passifs). Les mécanismes sont en
[`_rules/03-14`](03-14-couts-combines-croissance-et-multi-coups.md) ; les valeurs de chaque carte,
dans son fichier — des ordres de grandeur que le test du propriétaire corrige.

- **Une carte de lot touche ce que son passif nourrit** (D45) : son type, un de ses effets, un
  statut posé, un coût ou une croissance figure dans le `feeds` du passif. **Elle ne coûte pas
  d'Armure sous une classe qui convertit la sienne** (A7). Les deux règles vivent dans `LotRules`,
  lu par le test du catalogue et par l'éditeur de contenu, où la carte de lot est la dixième
  catégorie.
- **Aucune neutre ne coûte autre chose que du mana** (D17), **aucun lot ne porte de carte à coût
  total nul**, et toutes les cartes de la tranche sont communes.
- **Le noyau neutre** : *Focalisation* (`focus`) est **supprimée** (D28) ; *Forme Démoniaque* a
  rejoint le lot Sang, contenu inchangé ; *Trait de Glace* pose 2 Gel au lieu de 1 (barème
  proportionnel). Les 14 autres sont inchangées.

### L'offre et le draft de départ

- **Un prédicat d'offre, au passif actif** : `CardData.isOfferable(activePassiveId)` — vrai pour une
  neutre et pour une carte du lot du passif de la run, jamais pour un statut. Le lisent l'étal de
  la boutique, la carte trouvée après chaque combat, **le draft de départ** et le pool du tutoriel.
  Les sources qui **copient le deck** (draft de boss, les deux Miroirs, la copie vendue en boutique)
  lisent `DeckState.copyableCards`, le deck entier.
- **Le draft de départ, deux quotas** (Q9, D63 ; `StarterDraft`) : **2 cartes du lot** du passif
  choisi et **3 neutres**, dans deux sections titrées, chacune avec son compteur. Un lot de moins de
  deux cartes cède sa part aux neutres, pour que le deck garde 5 cartes. Choisir au-delà d'un quota
  refuse et notifie ; « Valider » s'active quand les deux quotas sont remplis. Le deck de départ
  est **les 5 cartes choisies**, rien d'autre. Le tutoriel suit, et grise la carte d'un groupe plein
  comme le jeu.

### Règles Métier et Équilibrage des Cartes
- **Cinq raretés, une échelle** : `common` → `legendary` — ADR-109, qui amende
  [ADR-094](../_adr/ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md) D1 et D2.
  Toute carte fusionne jusqu'à `legendary` ([`_rules/02-4`](02-4-progression-de-rarete-dynamique-et-fusion-int.md)).
- **Valeurs par mana** : les neutres de rareté `common` sont calées sur des ratios de Valeur Par
  Mana standardisés (`heal_potion` 1 mana, Soin 3, Épuisement ; `iron_wall` 2 mana, Armure 10 ;
  `heavy_strike` 2 mana, Dégâts 12) ; les lots, sur 6 dégâts ou 5 Armure par mana, la prime d'un
  lot à 6 Armure.

**Types d'effets utilisés** : `damage`, `armor`, `draw`, `heal`, `apply_status`, `gain_mana`.

**Animations data-driven** : Chaque carte possède un champ `animation` optionnel parmi : `melee`, `magic`, `buff`, `poison`, `fire`, `ice`, `lightning`.

**Propriétés d'une carte** (`CardData`) — re-lues le 2026-11-04 :
- `id`, `nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`
- `cost` (mana seul) **ou** `costs` (`mana`, `hp`, `armor` — [`_rules/03-14`](03-14-couts-combines-croissance-et-multi-coups.md))
- `type` : attack, skill, power, status
- `rarity` : common, uncommon, rare, epic, legendary
- `target` : singleEnemy, allEnemies, self, none
- `isExhaust` : boolean (carte épuisée après usage)
- `effects` : List\<CardEffect\> avec `type`, `value`, `statusId?`, `duration?`, et sur un effet de
  dégâts `hits` et `mightRatio` ; `scaleWith` (`source`, `ratio`, `statusId?`)
- `passive` : **injecté** par le répertoire, jamais écrit ; ni `category` ni `heroClass`
