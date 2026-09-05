### 2.8. `RewardController` (`rewardProvider`) — Pilote des Récompenses de Combat

**Provider** : `NotifierProvider<RewardController, RewardState>`

**État `RewardState`** : `goldGained` (int), `xpGained` (int), `rolledRelic` (RelicData?), `rolledCards` (List\<CardData\>), `isGoldXpCollected` (bool), `isRelicCollected` (bool), `isRelicSkipped` (bool), `isCardsProcessed` (bool), `selectedCards` (List\<CardData\>), `isResolved` (bool).

**Responsabilités** :
- **Initialisation** : `handleVictory(...)` — Déclenché lors de la victoire. 
  - Somme l'XP de base de chaque ennemi battu, indexé sur son niveau : `(enemy.data.xp * levelMultiplier).round()` où `levelMultiplier = 1.0 + 0.10 * (enemy.stats.level - 1)`. Triple (x3) le gain total d'XP si le nœud est de type boss central (`bossRewardType == BossRewardType.doubleXp`), et attribue en plus une carte aléatoire du jeu hors uniques et statuts.
  - Somme l'or de base de chaque ennemi battu (`assets/data/enemies/<id>/enemy.json`) avec le même coefficient de niveau : `(enemy.data.gold * levelMultiplier).round()`. Triple (x3) le gain total d'Or si le nœud est de type boss central (`bossRewardType == BossRewardType.doubleXp`).
  - **Tirage de Reliques Boss 3 (`improvedRelic`)** : Effectue le tirage de Reliques si combat de type Élite ou Boss. Si le nœud présente `bossRewardType == BossRewardType.improvedRelic`, les probabilités de drop sont dynamiques et calculées par Act :
    - La chance Légendaire de base est fixée à **10.0%** (augmentable via la chance `luck` du joueur : `legChance = 10.0 + luck * 0.5`).
    - La chance Commune de base démarre à **40.0%** et diminue de **10% par acte** : `commonChance = max(0.0, 40.0 - (act - 1) * 10.0)`.
    - Si `commonChance > 0.0` (Actes 1 à 4) : la portion de probabilité restante (90.0 - `commonChance`) est répartie proportionnellement entre Atypique (Uncommon), Rare et Épique :
      - `uncommonChance = (20.0 / 85.0) * baseRemaining + luck * 3.0`
      - `rareChance = (35.0 / 85.0) * baseRemaining + luck * 2.0`
      - `epicChance = (30.0 / 85.0) * baseRemaining + luck * 1.0`
    - Si `commonChance == 0.0` (Acte 5+) : la chance d'Atypique de base commence à décroître de **10% par acte** à partir de sa base max théorique : `baseUncommonChance = max(0.0, maxUncommonBase - (act - 5) * 10.0)` où `maxUncommonBase = (20.0 / 85.0) * 90.0`.
      - Si `baseUncommonChance > 0.0` (Actes 5 à 7), la portion restante (90.0 - `baseUncommonChance`) est répartie entre Rare et Épique :
        - `rareChance = (35.0 / 65.0) * baseRemaining + luck * 2.0`
        - `epicChance = (30.0 / 65.0) * baseRemaining + luck * 1.0`
        - `uncommonChance = baseUncommonChance + luck * 3.0`
      - Si `baseUncommonChance == 0.0` (Acte 8+) : Uncommon tombe à 0%, et la totalité des chances restantes (90.0%) est partagée entre Rare et Épique :
        - `rareChance = (35.0 / 65.0) * 90.0 + luck * 2.0`
        - `epicChance = (30.0 / 65.0) * 90.0 + luck * 1.0`
        - `uncommonChance = 0.0`
  - **Tirage de Cartes Boss 1 (`cards`)** : Propose 5 cartes aléatoires du deck actuel du joueur, lui permettant de choisir 2 d'entre elles pour les cloner (copier).
- **Collecte & Résolution** :
  - `collectGoldAndXp()` : Crédite l'or accumulé à `InventoryController` et l'XP à `RunController` (détermine si le héros monte de niveau).
  - `collectRelic()` / `skipRelic()` : Ajoute ou ignore la relique de l'inventaire.
  - `chooseCards(cards)` / `skipCards()` : Ajoute les cartes choisies dans le master deck via `DeckNotifier` ou ignore le tirage.
  - La méthode interne `_checkResolution()` marque l'état global `isResolved` à vrai une fois que toutes les récompenses valides ont été collectées ou sautées.
