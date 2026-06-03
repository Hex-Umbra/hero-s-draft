# Plan d'Implémentation Unifié - Refactoring de la Rareté, Équilibrage des Cartes & Système de Forge

Ce document définit un plan d'implémentation complet et harmonisé pour les systèmes de combat et de cartes de *Hero's Draft*. Il combine l'activation des effets élémentaires, le refactoring de la rareté dynamique (sans niveaux), l'application des rééquilibrages de cartes et la refonte complète du système de la Forge avec un mécanisme roguelike de sélection individuelle, de fusion d'améliorations, de tirage probabiliste et de relance.

---

## 🎯 1. Axe 1 : Activation et Résolution des Effets Élémentaires

Les statuts élémentaires (`burn`, `freeze`, `shock`) et le statut standard `vulnerable` doivent être pleinement intégrés dans les calculs de combat et nettoyés à chaque tour ou après résolution.

### A. Brûlure (`burn`)
* **Mécanique** : Inflige des dégâts de feu égaux à la valeur du statut au début du tour de la cible. Après l'application des dégâts, la valeur diminue de 1 et la durée diminue également de 1.
* **Code Cible - [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)** :
  * Dans `startEnemyTurn`, récupérer la somme des statuts `burn` actifs, l'appliquer comme dégâts (`updatedStats.takeDamage(burnDamage)`).
* **Code Cible - [entity_stats.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/entity_stats.dart)** :
  * Modifier `tickStatuses()` pour réduire de 1 la valeur du statut `burn` en plus de réduire sa durée.

### B. Gel (`freeze`)
* **Mécanique** : Réduit les dégâts de la prochaine attaque de l'ennemi de 50%. Après cette attaque, la durée du gel doit être décrémentée (et le statut retiré s'il tombe à 0).
* **Code Cible - [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)** :
  * Dans `resolveEnemyIntent`, sous le cas `IntentType.attack` :
    * Si l'ennemi possède le statut `freeze`, appliquer la réduction : `dmg = (intent.value * 0.5).round();`.
    * Décrémenter immédiatement la durée du gel de l'ennemi après cette résolution pour éviter que le gel n'affecte plusieurs attaques dans le même tour s'il n'avait qu'une durée de 1.

### C. Électrocution (`shock`)
* **Mécanique** : Ajoute la valeur du statut `shock` aux dégâts de chaque attaque directe subie par la cible. La durée diminue de 1 à la fin du tour.
* **Code Cible - [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart)** :
  * Dans `resolveCard`, case `damage` (pour cible unique et multi-cibles) :
    * Vérifier la présence de `shock` sur le défenseur et ajouter sa valeur : `dmg += shockStatus.value`.

### D. Vulnérable (`vulnerable`)
* **Mécanique** : Augmente les dégâts subis par la cible de 50% (+50% dégâts reçus).
* **Code Cible - [effect_resolver.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/services/effect_resolver.dart)** :
  * Lors du calcul des dégâts reçus par l'ennemi, appliquer le multiplicateur si l'ennemi est vulnérable : `dmg = (dmg * 1.5).round();`.
* **Code Cible - [combat_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/combat_controller.dart)** :
  * Dans `resolveEnemyIntent`, sous le cas `IntentType.attack`, si le héros possède le statut `vulnerable`, les dégâts infligés au héros sont augmentés : `dmg = (dmg * 1.5).round();`.

---

## 🧠 2. Axe 2 : Rareté Dynamique & Système de Fusion (Merge) Interactif

Le concept de **niveau de carte** (Lvl 1, 2, 3) est **complètement abandonné**. La rareté d'une carte devient l'unique facteur d'évolution et de multiplication statistique d'une instance.

### A. Rareté comme Multiplicateur de Statistique
Chaque carte possède des effets dont la valeur s'adapte directement à sa rareté d'instance :
$$\text{scaledValue} = \text{round}\left(\text{baseValue} \times \text{rarityMultiplier}\right)$$

| Rareté d'instance | Multiplicateur |
| :--- | :---: |
| **Commun (Common)** | `1.0x` |
| **Peu Commun (Uncommon)** | `1.2x` |
| **Rare** | `1.4x` |
| **Épique (Epic)** | `1.6x` |
| **Légendaire (Legendary)** | `2.0x` |

### B. Choix des Cartes à Fusionner (Merge Interactif)
Le joueur n'est plus forcé de fusionner n'importe quelles cartes automatiquement. Dans `DeckScreen`, cliquer sur le bouton de fusion d'un type de carte et d'une rareté :
1. **Dialogue de Sélection** : Affiche la liste de tous les exemplaires disponibles de cette carte à cette rareté, détaillant leurs améliorations de forge. Le joueur **coche précisément les 3 cartes** qu'il souhaite sacrifier pour la fusion.

### C. Fusion Automatique & Choix des Améliorations héritées
Lorsque 3 cartes sont fusionnées pour donner 1 carte de rareté supérieure :
1. **Auto-Fusion des Bonus Identiques (Cumul des stats)** :
   * Si plusieurs cartes parmi les 3 choisies possèdent la même amélioration (ex: deux cartes avec l'amélioration `sharp:1`), ces améliorations **fusionnent automatiquement en une amélioration de niveau supérieur** (ex: `sharp:2`), ne consommant qu'**une seule fente** sur la nouvelle carte.
   * *Règles d'évolution par palier ($k$)* :
     * `sharp:k` (Tranchant $k$) $\rightarrow$ $+2 \times k$ Dégâts.
     * `hardened:k` (Endurci $k$) $\rightarrow$ $+2 \times k$ Armure.
     * `quick:k` (Véloce $k$) $\rightarrow$ Pioche $+k$ cartes.
     * `eco:k` (Économe $k$) $\rightarrow$ $+k$ Mana à la pose.
     * `burning:k` / `freezing:k` / `shocking:k` $\rightarrow$ Applique statut élémentaire de valeur $k$.
2. **Choix de l'Héritage** :
   * Les améliorations uniques et auto-fusionnées sont rassemblées.
   * Si le nombre total d'améliorations résultantes est inférieur ou égal à la capacité de la rareté supérieure (ex: 2 fentes pour Peu Commun, 3 pour Rare), la carte hérite de **toutes** les améliorations.
   * Si ce nombre dépasse la capacité, un dialogue s'ouvre présentant la liste des améliorations consolidées. Le joueur **sélectionne quelles améliorations il souhaite conserver** pour la nouvelle carte, dans la limite de sa capacité de fentes. Les autres sont abandonnées.

---

## 🛠️ 3. Axe 3 : Système de Forge Découplé & Mécaniques Détaillées

La Forge n'augmente plus les statistiques de niveau des cartes. Elle sert uniquement à appliquer des **améliorations (bonifications) uniques et personnalisées** sur des fentes limitées.

### A. Capacité Limite d'Améliorations
Le nombre maximum d'améliorations (slots de forge) applicables à une instance de carte est dynamique et calculé comme suit :
$$\text{totalMaxForgeUpgrades} = \text{baseMaxForgeUpgrades} + \text{rarityIndex}$$
* **`baseMaxForgeUpgrades`** est défini dans le fichier JSON pour chaque carte (par défaut `1`).
* **`rarityIndex`** correspond à l'index de la rareté actuelle de l'instance de la carte (Commun = 0, Peu Commun = 1, Rare = 2, Épique = 3, Légendaire = 4).
* *Contrainte* : Si la carte a déjà rempli tous ses slots disponibles (ex: possède déjà 1 amélioration au stade Commun), le bouton d'amélioration à la Forge pour cette carte est verrouillé.

### B. Pools d'Améliorations par Rareté (Équilibrage)
Les améliorations sont regroupées en pools débloqués par la rareté de la carte sélectionnée :
1. **Pool Commun (Toutes Raretés)** :
   * **Tranchant (`sharp`)** : Ajoute $+2$ Dégâts directs par niveau de palier (ex: sharp:1 = +2, sharp:2 = +4).
   * **Endurci (`hardened`)** : Ajoute $+2$ Armure par niveau de palier (ex: hardened:1 = +2, hardened:2 = +4).
   * **Brûlant (`burning`)** : Applique statut Brûlure (+1 valeur, +1 durée par palier) (cartes d'Attaque uniquement).
   * **Congelant (`freezing`)** : Applique statut Gel (+1 valeur, +1 durée par palier) (cartes d'Attaque uniquement).
   * **Surchargé (`shocking`)** : Applique statut Électrocution (+1 valeur, +1 durée par palier) (cartes d'Attaque uniquement).
2. **Pool Peu Commun (Rareté $\ge$ Peu Commun)** :
   * Contient les options du pool Commun, plus :
   * **Véloce (`quick`)** : Pioche $+1$ carte lors du jeu (par niveau de palier).
3. **Pool Rare (Rareté $\ge$ Rare)** :
   * Contient les options des pools précédents, plus :
   * **Économe (`eco`)** : Restitue $+1$ cristal de Mana lors du jeu (par niveau de palier).
   * **Persistant (`enduring`)** : Force `isExhaust = false` pour la carte (palier unique, applicable uniquement sur les cartes possédant `isExhaust: true` d'origine et excluant les cartes de type `power`).

* *Règle d'Unicité* : Une carte ne peut pas posséder deux fois la même amélioration.

### C. Tirage Probabiliste Roguelike
Lorsqu'un joueur choisit d'améliorer une carte à la Forge, les propositions sont générées via trois couches successives de probabilités :

1. **Génération Probabiliste des Emplacements d'Options (1 à 5 options)** :
   * Le jeu détermine quels emplacements d'option apparaissent selon des probabilités indépendantes :
     * **Option 1** : `100%` (garantie, toujours au moins 1 option proposée).
     * **Option 2** : `50%` de chance.
     * **Option 3** : `25%` de chance.
     * **Option 4** : `10%` de chance.
     * **Option 5** : `2%` de chance.
2. **Tirage Pondéré du Pool d'Améliorations (Selon Rareté de la carte)** :
   * Pour chaque emplacement activé, la rareté du bonus proposé est tirée avec les poids suivants (clamped selon la rareté maximum débloquée par la carte) :
     * **Sur carte Commune** : `100%` Commun.
     * **Sur carte Peu Commune** : `75%` Commun / `25%` Peu Commun.
     * **Sur carte Rare ou supérieure** : `65%` Commun / `25%` Peu Commun / `10%` Rare.
   * Une fois le pool déterminé, une amélioration compatible et disponible y est tirée de manière équiprobable.
3. **Tirage Pondéré du Tier de Départ (Valeur du Bonus)** :
   * Pour les améliorations compatibles multi-paliers (ex: `sharp`, `hardened`, `quick`, `eco`, etc.), le tier de départ $k$ de l'option tirée est déterminé par le jet suivant :
     * **Tier I** (Standard — `80%` de chance) $\rightarrow$ `"id:1"` (ex: +2 dégâts, +1 pioche).
     * **Tier II** (Amélioré — `15%` de chance) $\rightarrow$ `"id:2"` (ex: +4 dégâts, +2 pioches).
     * **Tier III** (Légendaire — `5%` de chance) $\rightarrow$ `"id:3"` (ex: +6 dégâts, +3 pioches).
   * Les améliorations à palier unique (comme `enduring`) restent à 1.

### D. Relance (Re-roll) Individuelle des Fentes d'Option
Chaque fente d'option active dispose de son propre bouton **Relancer** indépendant :
* **Calcul du Coût Autonome** : Le coût de relance augmente de **25% cumulatifs** par emplacement, basé uniquement sur le nombre de relances effectuées sur cet emplacement spécifique :
  $$\text{coût}_i = \text{round}\left(20 \times 1.25^{n_i}\right)$$
  * $i$ : index de l'option (1 à 5).
  * $n_i$ : nombre de relances effectuées sur la fente $i$ (commence à 0, coût de départ = 20 Or).
* **Comportement UI & Inventaire** :
  * Si l'Or du joueur (suivi via `inventoryProvider`) est insuffisant pour la fente $i$, son bouton Relancer est grisé.
  * Cliquer sur le bouton déduit l'or, incrémente $n_i$, et génère une nouvelle option aléatoire pour la fente $i$ (en re-roulant son pool, son type et son tier) sans altérer les autres fentes actives.

---

## ⚖️ 4. Équilibrage des Cartes de Base (cards.json)

1. **`holy_shield`** (Paladin - Rare) : Cost 1, 8 Block, 2 Heal, starts with `"isExhaust": true`. (Can remove exhaust at Forge with *Persistant*).
2. **`warcry`** (Global - Epic) : Cost 2, 4 AOE damage, 4 Block.
3. **`mana_surge`** (Mage - Uncommon) : Cost 0, 1 Mana, 1 Draw, `"isExhaust": true`.
4. **`concentration`** (Global - Common) : Cost 0, 2 Draw, `"isExhaust": true`.
5. **`poison_stab`** (Global - Common) : Cost 1, 5 direct damage, 4 Poison (duration 3).

---

## 📂 5. Modifications Logiques et Modèles du Code

### Modèle `CardInstance` (`lib/models/card_instance.dart`)
* Supprimer `int level`.
* Ajouter `CardRarity rarity;` et `List<String> forgeUpgrades;` (stockant les chaînes `"id:tier"`).
* Getter `totalMaxForgeUpgrades` et calcul de capacité de fentes.

### Résolution des Effets (`lib/game/services/effect_resolver.dart`)
* Formule : `scaledValue = (baseValue * rarityMultiplier).round();`.
* Parser le format `"id:tier"` lors de la pose d'une carte :
  * Si `"sharp:k"` : ajouter $+2 \times k$ aux dégâts.
  * Si `"hardened:k"` : ajouter $+2 \times k$ à l'armure.
  * Si `"quick:k"` : piocher $k$ cartes.
  * Si `"eco:k"` : ajouter $k$ mana.
  * Si `"burning:k"` / `"freezing:k"` / `"shocking:k"` : appliquer le statut élémentaire correspondant de valeur $k$.

### Contrôleur de Deck (`lib/game/controllers/deck_controller.dart`)
* Dans `playCard` : non-exhaust si la carte contient `"enduring:1"`.
* Modifier `mergeCards` pour accepter une liste de 3 `uniqueId` sélectionnés, et une liste d'améliorations choisies à conserver.
* Gérer l'auto-fusion dans le contrôleur : grouper les améliorations par ID et sommer leurs tiers $k$.

### Écran de la Fusion (`lib/ui/screens/deck_screen.dart`)
* Modifier la confirmation de merge :
  * Ouvrir un modal de sélection permettant de cocher exactement 3 exemplaires du même ID et même rareté.
  * Après sélection, calculer les améliorations auto-fusionnées et consolidated.
  * Si la capacité de la rareté supérieure est dépassée, afficher un écran de sélection pour choisir les bonus à conserver.
  * Appeler le notifier pour exécuter la fusion.

---

## 🧪 6. Plan de Test et de Validation

1. **Vérification Statique** : `dart analyze`.
2. **Tests Unitaires** :
   * Tester la fusion probabiliste et l'auto-fusion des améliorations (ex: deux `"sharp:1"` devenant un `"sharp:2"`).
   * Tester le choix interactif d'héritage d'améliorations lors d'un merge en surcharge de capacité.
3. **Tests Manuels** :
   * Effectuer un merge dans le deck, sélectionner 3 cartes spécifiques et choisir ses améliorations.
   * Vérifier l'application en combat des tiers cumulés d'améliorations (ex: Tranchant II inflige bien +4 dégâts).
