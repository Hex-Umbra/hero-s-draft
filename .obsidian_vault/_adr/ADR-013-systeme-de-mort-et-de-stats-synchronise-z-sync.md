## 💀 ADR-013 : Système de Mort et de Stats Synchronisé Z-Sync (Z-Sync Death & Stats System)

### Statut
✅ Accepté & Implémenté

### Contexte
Dans la version initiale, lorsqu'un joueur jouait une carte infligeant des dégâts ou tuant un ennemi, l'état Riverpod du combat était immédiatement mis à jour (déclenchant instantanément `_cleanDeadEnemies()` et modifiant les points de vie / armure dans le `CombatState`).

Par conséquent, via le double-buffering dans Flame (`_applyCombatState`), l'entité visuelle `EnemyCard` correspondante voyait sa barre de vie (`HealthBar`) se vider et son badge d'armure s'actualiser, ou l'ennemi était purement supprimé du canvas pendant que l'animation physique de la carte (mouvement de mêlée ou projectile) était encore en cours de déplacement. L'impact de la carte frappait ainsi une cible déjà diminuée ou disparue, créant des désynchronisations visuelles majeures (race conditions visuelles de mort et de statistiques).

### Décision
- **Introduire un état de temporisation des morts et des statistiques (Z-Sync)** :
  - Ajouter un drapeau booléen central `isCardAnimating` dans `HerosDraftGame` pour indiquer qu'une animation de carte de combat est active.
  - Ajouter un drapeau booléen local `isPendingDeath` et un champ d'instance temporaire `EnemyInstance? _pendingVisualInstance` dans `EnemyCard`.
- **Différer la mise à jour des statistiques visuelles tout en gardant un feedback réactif** :
  - Lors de la réception de `updateStats(EnemyInstance newInstance)`, les effets d'impact physiques immédiats (secousses haute fréquence de la carte, flashs sprite de couleur, apparition de nombres flottants de dégâts `FloatingText` et jaillissement radial de particules `spawnDamageParticles`) sont **déclenchés instantanément** pour conserver une réactivité visuelle immédiate et extrêmement dynamique.
  - Cependant, si `game.isCardAnimating` est actif, la mise à jour réelle des indicateurs visuels du HUD de l'ennemi (la barre de vie `HealthBar`, le badge d'armure `StatBadge`, et la liste des icônes de buffs/debuffs) est **différée** : les données sont stockées temporairement dans `_pendingVisualInstance` et les badges ne sont pas rafraîchis. Si `isCardAnimating` est faux, la mise à jour est directe.
- **Différer le nettoyage des ennemis morts** :
  - Dans `_applyCombatState`, si un ennemi visuel Flame a été logiquement supprimé de l'état du combat Riverpod :
    - Si `game.isCardAnimating == true`, il n'est **PAS** supprimé immédiatement. Il est marqué `isPendingDeath = true` et reste pleinement dessiné sur le board.
    - Si faux, il disparaît immédiatement.
- **Résolution synchrone à l'impact** :
  - Lorsque l'animation de la carte (physique ou magique) arrive à son terme (impact sur la cible), son callback `onComplete` appelle `game.resolvePendingDeaths()`.
  - Cette méthode désactive le verrouillage en passant `isCardAnimating = false`, puis itère sur toutes les `EnemyCard` pour :
    1. Appeler `card.resolvePendingVisualStats()` : cela applique le `_pendingVisualInstance` mis en réserve, mettant à jour de façon synchrone les barres de vie, les badges d'armure et les indicateurs à la frame exacte de l'impact physique.
    2. Déclencher enfin l'animation de disparition (rétrécissement `ScaleEffect` et fondu d'opacité `OpacityEffect`) de toutes les `EnemyCard` marquées `isPendingDeath == true`.
- **Bypass pour le hors-combat** :
  - Si les statistiques ou la mort changent de façon passive hors de l'animation d'une carte (par exemple, les dégâts de poison ou brûlure au début du tour ennemi), le système Z-Sync contourne le délai pour mettre à jour les jauges et appliquer la mort visuelle instantanément.

### Preuves dans le code
- `HerosDraftGame.isCardAnimating` (verrouillage central).
- `EnemyCard.isPendingDeath` et `EnemyCard._pendingVisualInstance` (conservation d'état local différé).
- `EnemyCard.resolvePendingVisualStats()` : applique `_pendingVisualInstance`, appelle `_refreshBadges()` et met à jour les icônes de statuts.
- `HerosDraftGame.resolvePendingDeaths()` qui coordonne l'appel séquentiel de `resolvePendingVisualStats()` sur toutes les cartes ennemies avant de déclencher l'effet de mort sur les ennemis en attente de destruction.

### Conséquences
- ✅ **Game Feel Premium Exceptionnel** : Les cartes frappent toujours une cible solide dont la barre de vie se vide et dont l'armure se brise à la microseconde exacte de l'impact, maximisant la satisfaction sensorielle du joueur.
- ✅ **Éradication complète des race conditions visuelles** : Zéro modification de jauge prématurée ou disparition d'ennemi avant la rencontre physique réelle du projectile ou du coup de mêlée.
- ✅ **Respect de l'architecture découplée** : La couche Riverpod conserve la maîtrise absolue de l'état logique exact du combat, la couche Flame n'agissant que comme un cache graphique différé réaligné à l'impact.
- ⚠️ **Rigueur d'orchestration** : Toute action de carte de combat doit impérativement basculer `game.isCardAnimating = true` au lancement de l'effet et appeler `resolvePendingDeaths()` à sa complétion pour déverrouiller la synchronisation visuelle.
