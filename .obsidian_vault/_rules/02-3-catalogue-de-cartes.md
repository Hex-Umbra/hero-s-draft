### 2.3. Catalogue de Cartes

Le catalogue compte **58 cartes** : **9 neutres** sous `assets/data/cards/<id>.json` et **49 cartes
de lot** sous `assets/data/cards/<passif>/<id>.json`, neuf lots — 6, 6, 6 en tranche 1 ; 5, 5, 5 en
tranche 2 ; 5, 5, 6 en tranche 3 (D16) — **re-mesuré le 2026-11-18** (`find assets/data/cards
-maxdepth 1 -name '*.json' | wc -l` → 9, `find assets/data/cards -mindepth 2 -name '*.json' | wc -l`
→ 49, sur la branche `feat/v0.6.0-p42-tranche-3`).
Le nom du fichier est l'`id` ; le nom du dossier d'un lot est l'id de son passif. La forme C est de
la tranche 1 de P-42, vague 5, fusionnée dans `main` le 2026-11-09 —
[ADR-112](../_adr/ADR-112-forme-c-un-lot-de-cartes-par-passif.md) ; la tranche 2, vague 6, est fusionnée
dans `main` le 2026-11-15 —
[ADR-116](../_adr/ADR-116-canalisation-une-banque-de-mana.md) ; la tranche 3, vague 8, est **livrée sur
la branche `feat/v0.6.0-p42-tranche-3`, en attente du test, de la PR, de la fusion et du tag du
propriétaire** — [ADR-118](../_adr/ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md). Les signatures ne sont pas des
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

### Les lots de la tranche 2

Cinq cartes par lot, toutes communes ; les valeurs, dans chaque fichier et au
[plan](../../docs/superpowers/plans/2026-11-15-p42-tranche-2.md) §3.

| Lot | Passif, classe | Cartes | Mécanismes |
|:---|:---|:---|:---|
| **Croisé** | `fervor`, Paladin | *Riposte*, *Jugement*, *Marteau sacré*, *Fléau béni*, *Charge du croisé* | Cinq Attaques, trois qui donnent de l'Armure ; deux multi-coups à `mightRatio` 0,75 |
| **Vampire** | `bloodthirst`, Berserker | *Morsure*, *Lacération*, *Curée*, *Frénésie sanglante*, *Traque* | Cinq Attaques, trois qui piochent (D35) ; *Lacération* à 0, épuisable ; *Frénésie sanglante* à 1 mana, `scaleWith: cardsPlayedThisTurn` |
| **Voile** | `channeling`, Mage | *Barrière*, *Méditation*, *Sceau*, *Cataclysme*, *Bouclier d'éther* | Pouvoirs durables et Compétences à 3, courbe 1-2-3-3-3 ; *Méditation* pose `mana_regen` et s'épuise ; aucune carte à 0 (D11) |

### Les lots de la tranche 3

Toutes communes, aucune à épuisement ; les valeurs, dans chaque fichier et à la
[spec](../../docs/superpowers/specs/2026-11-18-p42-tranche-3-design.md) §3.2. Six cartes y changent de
dossier, contenu et id inchangés : les quatre élémentaires (qui restent des Attaques, Q12),
*Métallisation* et *Cri de Guerre*.

| Lot | Passif, classe | Cartes | Mécanismes |
|:---|:---|:---|:---|
| **Sanctifié** | `blessing`, Paladin | *Sommation*, *Édit*, *Réprimande*, *Prière*, *Métallisation* | La Faiblesse fait survivre l'Armure que *Bénédiction* convertit ; *Prière*, Pouvoir, pose la *Source de Vie* (`hp_regen` 2, 3 tours — D55) ; courbe 1-1-1-2-2. Les durées de Faiblesse ont un tour de plus que le brainstorm (A19) ; aucune carte « armure conservée » (D43, réponse du propriétaire) |
| **Carnage** | `frenzy`, Berserker | *Moulinet*, *Tourbillon*, *Coup de grâce*, *Exécution*, *Cri de Guerre* | Quatre Attaques de groupe pour enchaîner les morts ; *Exécution*, `scaleWith: targetMissingHp` × 0,2 ; courbe 1-1-2-2-3 ; à l'acte 1, un seul ennemi par combat |
| **Marque** | `mage_mark`, Mage | *Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, *Coup Empoisonné*, *Exploitation*, *Salve* | Les quatre élémentaires et leurs charges ; deux Compétences : *Exploitation*, `scaleWith: targetStatus` (`vulnerable`) × 1, et *Salve*, 2 × 3 à `mightRatio` 0,5 ; courbe 1-1-1-1-2-2 |

Les `feeds` ont suivi leurs lots (A11) : *Frénésie* gagne `damage`, *Bénédiction*
`status:hp_regen`. **Les neuf passifs ont leur lot** : aucun n'est plus masqué à la sélection
([`_rules/02-2`](02-2-systeme-de-heros.md) §Passifs). Les mécanismes sont en
[`_rules/03-14`](03-14-couts-combines-croissance-et-multi-coups.md) ; les valeurs de chaque carte,
dans son fichier — des ordres de grandeur que le test du propriétaire corrige.

- **Une carte de lot touche ce que son passif nourrit** (D45) : son type, un de ses effets, un
  statut posé, un coût ou une croissance figure dans le `feeds` du passif. **Elle ne coûte pas
  d'Armure sous une classe qui convertit la sienne** (A7). Les deux règles vivent dans `LotRules`,
  lu par le test du catalogue et par l'éditeur de contenu, où la carte de lot est la dixième
  catégorie.
- **Aucune neutre ne coûte autre chose que du mana** (D17), et toutes les cartes de lot sont
  communes. **Une seule carte de lot est à coût total nul**, *Lacération*, et elle s'épuise : sous
  *Soif de Sang*, les cartes gratuites offertes sont *Concentration* et elle, toutes deux
  épuisables (D50, le coût total compte `costs`). Seules *Lacération* et *Méditation* s'épuisent
  parmi les cartes de lot — re-vérifié le 2026-11-18 (`grep -l '"isExhaust": true'
  assets/data/cards/*/*.json`). Sous les trois passifs de la tranche 3, la seule carte gratuite
  offerte reste *Concentration*.
- **Le noyau neutre** : *Focalisation* (`focus`) est **supprimée** (D28) ; *Forme Démoniaque* a
  rejoint le lot Sang, contenu inchangé ; *Trait de Glace* pose 2 Gel au lieu de 1 (barème
  proportionnel). Depuis la tranche 3, les quatre élémentaires, *Métallisation* et *Cri de Guerre*
  l'ont quitté pour leur lot : sous les six autres passifs, ils ne sont plus offerts. Restent **neuf
  neutres**, celles que le brainstorm garde (§7.4) — *Frappe*, *Défense*, *Attaque Rapide*, *Frappe
  Lourde*, *Balayage*, *Mur de Fer*, *Éveil*, *Concentration*, *Potion de Soin* —, qui ne portent
  que du mana (D17).
- **Les cartes relues sur les charges élémentaires** (vague 7, fusionnée dans `main` le 2026-11-18
  par la PR #55 — [ADR-117](../_adr/ADR-117-les-charges-elementaires.md), réponses P-a et P-b) : le Gel, le Feu et
  la Foudre deviennent des charges ([`_rules/04-00`](04-00-alterations-d-etat-statuts.md) §4.5) ;
  la Brûlure se nomme le Feu, l'Électrocution la Foudre. *Embrasement* pose **3 Feu** (4 avant) ;
  *Boule de Feu* (2 Feu), *Trait de Glace* (2 Gel), *Coup de Tonnerre* (1 Foudre, après son coup),
  *Nova de givre* (2 Gel à tous) et *Rafale d'étincelles* (1 Foudre, puis 3 × 3) gardent leurs
  valeurs ; aucun `statusId` ne change, aucune durée ne s'affiche plus sous une charge.

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
