# 🎯 Contexte Produit & Règles Métier (Product Context)

Ce document synthétise la boucle de gameplay (Core Loop) de **Hero's Draft**, son économie, ses systèmes de progression procédurale, ses règles métier fondamentales, et le schéma complet des données de jeu.

---

## 1. Boucle de Gameplay Principale (Core Loop)

La progression dans **Hero's Draft** est structurée autour d'une boucle classique de roguelike deckbuilder enrichie d'une mécanique de draft tactique de héros et de cartes.

```
[Écran d'Accueil (HomeScreen)]
       │
       ▼
[Sélection de Classe (HeroSelectionScreen)]
  Paladin (100 HP, 3 Mana, 5 Atk, passif: regenArmor)
  Berserker (80 HP, 3 Mana, 15 Atk, passif: berserkerArmor)
  Mage (60 HP, 3 Mana, 10 Atk, passif: spellArmor)
       │
       ▼
[Draft Deck Initial (StarterDeckDraftScreen)]
  Constitution du deck : vagues de 3 cartes à choisir
       │
       ▼
[Carte Stratégique (MapScreen)] ◄─── Graphe Acyclique Dirigé (10 étages)
  Types de nœuds : Combat / Élite / Shop / Événement / Repos / Boss
       │
       ├─────────────────────────┐
       ▼                         ▼
[Combat (GameScreen)]      [Écrans Spécifiques]
 Flame Canvas + HUD         ├─ Boutique (ShopScreen)
       │                     ├─ Feu de Camp (CampfireScreen)
       │                     └─ Événement (EventScreen)
       ▼
[Draft de Récompense (DraftScreen)]
  3 choix de cartes post-victoire
       │
       ▼
[Évaluation Auto-Merge (3→1)]
  3× cartes identiques (même rareté) → 1× carte de rareté supérieure (upgrades cumulés)
       │
       ▼
[Passage à l'Étage Suivant] ── Si Boss complété → Acte+1 → Nouvelle carte
```

---

## 2. Systèmes de Progression

### 2.1. Génération Procédurale de Carte (`MapGeneratorService`)

Le service statique `MapGeneratorService.generateMap({floors = 10, maxWidth = 5})` génère un **Graphe Acyclique Dirigé (DAG)**.

**Phase 1 — Création des nœuds** :
- Itère de l'étage 0 à `floors-1` (0 à 9).
- Chaque étage a 2 à `maxWidth` nœuds (aléatoire), sauf cas spéciaux.
- Positionnement : X réparti sur 1000px de largeur, Y = `(floors - 1 - y) * 200` (bottom-to-top).

**Règles spéciales par étage** :
| Étage | Contrainte |
|:---|:---|
| 0 | 100% Combat (entrée obligatoire) |
| 5 | **Chokepoint** : exactement 1 nœud, type = `elite` OU `rest` (50/50) |
| 8 (`floors-2`) | 100% `rest` (repos garanti avant boss) |
| 9 (`floors-1`) | Exactement 1 nœud `boss` |

**Distribution probabiliste** (pour les étages 1-4, 6-7) :
| Type de Nœud | Probabilité |
|:---|:---|
| Combat standard | 60% |
| Événement narratif | 15% |
| Boutique (Shop) | 10% |
| Repos (Campfire/Rest) | 10% |
| Combat Élite | 5% |

**Phase 2 — Câblage des connexions (DAG)** :
- Pour chaque nœud de l'étage `y`, calcule un index de base proportionnel dans l'étage `y+1`.
- Connecte à 1 ou 2 nœuds (offset -1, 0, ou +1 par rapport à la base).
- **Garantie d'accessibilité** : Vérifie que chaque nœud de `nextFloor` est ciblé par au moins un nœud de `currentFloor`. Sinon, connecte la source proportionnellement la plus proche.

**Modèle `MapNode`** : `id` (ex: "node_0_0"), `type` (MapNodeType), `connections` (List\<String\>), `position` (Vector2 Flame), `isCompleted` (bool mutable).

### 2.2. Système de Héros

Trois classes de héros définis dans `heroes.json` :

| Héros | HP | Mana | Attaque | Luck | Armor Mastery | Passif | Compétences |
|:---|:---|:---|:---|:---|:---|:---|:---|
| **Paladin** | 100 | 3 | 5 | 0 | 0 | `regenArmor` (gain armure fin de tour) | `paladin_shield` (15 armure, 3 mana), `paladin_rage` (2 atk buff, 5 mana) |
| **Berserker** | 80 | 3 | 15 | 0 | 0 | `berserkerArmor` (armure ∝ HP manquants, début tour) | `berserker_leech` (vampirisme 3, 0 mana), `berserker_pierce` (15 dégâts perce-armure, 3 mana) |
| **Mage** | 60 | 3 | 10 | 0 | 0 | `spellArmor` (armure quand skill jouée) | `mage_nova` (20 dégâts AoE, 4 mana), `mage_strike` (150 dégâts ciblés, 8 mana) |

**Passifs** (gérés par `TraitSystem`, données dans `passives.json`) :
| ID | Trigger | EffectType | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|
| `regenArmor` | `endOfTurn` | `gain_armor` | 2 | +2 armure (+armorMastery) à chaque fin de tour |
| `berserkerArmor` | `startOfTurn` | `berserker_armor` | 1 | +1 armure par tranche de 10 HP manquants (+armorMastery) |
| `spellArmor` | `onCardPlayed` | `spell_armor` | 1 | +1 armure quand une carte Skill est jouée (+armorMastery) |

### 2.3. Catalogue de Cartes

**23 cartes** définies dans `cards.json`, réparties en :
- **15 cartes globales** (neutres, accessibles à tous les héros)
- **2 cartes Paladin** (`holy_shield`, `smite`)
- **2 cartes Berserker** (`reckless_strike`, `rage_form`)
- **2 cartes Mage** (`magic_missile`, `mana_surge`)

**Types d'effets utilisés** : `damage`, `armor`, `draw`, `heal`, `apply_status`, `gain_mana`.

**Animations data-driven** : Chaque carte possède un champ `animation` optionnel parmi : `melee`, `magic`, `buff`, `poison`, `fire`, `ice`, `lightning`.

**Propriétés d'une carte** (`CardData`) :
- `id`, `nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`, `cost` (0-3 mana)
- `type` : attack, skill, power, status
- `category` : global, characterSpecific
- `rarity` : common, uncommon, rare, epic, legendary
- `target` : singleEnemy, allEnemies, self, none
- `isExhaust` : boolean (carte épuisée après usage)
- `effects` : List\<CardEffect\> avec `type`, `value`, `statusId?`, `duration?`
- `heroClass?` : null (global) ou "paladin"/"berserker"/"mage"

### 2.4. Progression de Rareté Dynamique et Fusion Interactive

La progression des cartes s'effectue via des raretés dynamiques (`common` → `uncommon` → `rare` → `epic` → `legendary`), chacune appliquant un coefficient multiplicateur sur les statistiques de base de dégâts et d'armure de la carte.

La fusion de cartes 3-en-1 est gérée par `DeckNotifier.mergeCards(selectedIds, inheritedUpgrades)` :
1. Le joueur sélectionne 3 exemplaires d'une carte ayant la même rareté active.
2. Les 3 copies sont supprimées du `masterDeck`.
3. Une nouvelle copie de rareté directement supérieure est ajoutée au `masterDeck`.
4. **Héritage des Améliorations de Forge** : Les upgrades de même ID voient leurs Tiers additionnés (ex: deux upgrades `sharp:1` fusionnent en un unique `sharp:2`). Le nombre d'améliorations final est limité par la capacité maximale de la nouvelle rareté (`baseMaxForgeUpgrades + rarityIndex`). Le joueur choisit de manière interactive les upgrades qu'il souhaite hériter en cas de dépassement de la capacité.

### 2.5. Bestiaire

**4 ennemis** définis dans `enemies.json` :

| ID | Nom | HP | Dégâts Base | Tier | Pattern d'Intentions |
|:---|:---|:---|:---|:---|:---|
| `slime` | Slime | 18 | 4 | 1 | [attack:4] — attaque unique répétée |
| `gobelin` | Gobelin | 28 | 5 | 1 | [attack:5] — attaque unique |
| `squelette` | Squelette | 22 | 8 | 2 | [attack:8, attack:10] — cycle 2 attaques |
| `orc` | Orc Furieux | 50 | 8 | 3 | [attack:8, buff:2, attack:12] — cycle 3 phases |

**Scaling de combat** (`CombatController.initializeCombat`) :
| Type | Multiplicateur HP | Multiplicateur Attaque | Nombre |
|:---|:---|:---|:---|
| Normal (level ≤5) | ×1.0 | ×1.0 | 1-2 |
| Normal (level >5) | ×1.0 | ×1.0 | 1-3 |
| Élite | ×1.5 | ×1.5 | 2-3 |
| Boss | ×3.0 | ×2.0 | 1 |

---

## 3. Règles Métier Majeures

### 3.1. 🔋 Gestion du Mana

- **Réinitialisation** : Au début de chaque tour (`startTurn()`), le mana actuel est restauré à `maxMana`.
- **Gains exceptionnels** : Les reliques `gain_mana` et les cartes comme `Focalisation` ajoutent du mana qui peut **temporairement dépasser** le maximum pour le tour en cours.
- **Coût des cartes** : Chaque carte a un coût de 0 à 3 cristaux. `canPlayCard()` vérifie `currentMana >= card.currentCost`.
- **Coût temporaire** : `CardInstance.temporaryCost` peut override le coût de base (non utilisé activement).
- **Compétences** : Les skills héroïques ont leurs propres coûts mana (3 à 8), consommés via `SkillController.triggerSkill()` → `RunController.consumeResource()`.

### 3.2. 🛡️ Gestion de l'Armure

**Absorption des dégâts** (`EntityStats.takeDamage(amount)`) :
```dart
if (armure >= amount) {
  armure -= amount;          // Armure absorbe tout
} else {
  int remaining = amount - armure;
  armure = 0;                // Armure brisée
  currentPv = (currentPv - remaining).clamp(0, maxPv);
}
```

**Maîtrise d'Armure (`armorMastery`)** : Statistique cumulative et permanente. Tous les gains d'armure dans `RunController` et `TraitSystem` ajoutent systématiquement `armorMastery` au montant.

**Persistance** : L'armure accumulée est **transitoire** — remise à 0 à la fin de chaque combat (`completeCurrentNode()`). La Maîtrise d'Armure reste permanente.

### 3.3. ⚔️ Pipeline de Dégâts

**Dégâts du joueur** (`EffectResolver._calculateDamage`) :
```
Dégâts Finaux = (Dégâts base carte + effectiveAttaque) × Modificateur Faiblesse
```
Où :
- `effectiveAttaque` = `attaque` permanente + Σ valeurs status `strength` actifs.
- **Faiblesse** : Si l'attaquant possède le statut `weakness`, les dégâts sont multipliés par **0.75** (réduction de 25%, arrondi).

**Dégâts ennemis** (`CombatController.resolveEnemyIntent`) :
- Attack : `runController.takeDamage(intent.value)` — valeur brute de l'intention.
- `effectiveIntent` (getter sur `EnemyInstance`) : scale la valeur d'attaque en fonction du ratio `baseDamage` du spawn et du bonus `strength` de l'ennemi.

### 3.4. 🃏 Système de Piles de Cartes

Cinq piles logiques gérées par `DeckNotifier` :

```
[Master Deck]  ── Persistant entre combats. Source de vérité.
      │
      ▼ (initializeCombat: copie + shuffle)
[Draw Pile]  ──  Pioche: drawCards(amount)
      │                    │
      ▼                    ▼
   [Hand]  ────────►  [Discard Pile]  (playCard → si non-Power/non-Exhaust)
      │                    │
      │              shuffleDiscardIntoDraw() ──► [Draw Pile]
      │
      └──────────►  [Exhaust Pile]  (Power cards, isExhaust cards)
                      Retiré définitivement du combat en cours
```

> ⚠️ **Note critique** : `drawCards()` ne reshuffle PAS automatiquement la défausse quand la pioche est vide. `shuffleDiscardIntoDraw()` doit être appelé explicitement.

### 3.5. 🎒 Système de Reliques

**12 reliques** définies dans `relics.json`, organisées par trigger :

| ID | Nom | Rareté | Trigger | Effet | Valeur |
|:---|:---|:---|:---|:---|:---|
| `iron_talisman` | Talisman de Fer | Common | startOfTurn | gain_armor | 2 |
| `ancestral_shield` | Bouclier Ancestral | Uncommon | startOfCombat | gain_armor | 5 |
| `protection_rune` | Rune de Protection | Uncommon | endOfTurn | gain_armor | 3 |
| `mage_amulet` | Amulette du Mage | Rare | onCardPlayed | gain_armor | 1 |
| `cursed_blade` | Lame Maudite | Uncommon | startOfCombat | gain_strength | 2 |
| `mana_crystal` | Cristal de Mana | Rare | startOfCombat | gain_mana | 1 |
| `spirit_essence` | Essence Spirituelle | Rare | onEnemyKilled | gain_mana | 1 |
| `energy_stone` | Pierre d'Énergie | Epic | startOfTurn | gain_mana | 1 |
| `regen_ring` | Anneau Régénérant | Rare | endOfTurn | heal | 2 |
| `vampiric_fang` | Croc Vampirique | Uncommon | onEnemyKilled | heal | 8 |
| `lucky_clover` | Trèfle Chanceux | Epic | startOfRun | gain_luck | 1 |
| `fortune_dice` | Dés de Fortune | Legendary | startOfRun | gain_luck | 2 |

**Cycle de vie des triggers** :
- `startOfRun` : Appliqué immédiatement à l'ajout (`InventoryController.addRelic()`).
- `startOfCombat` : Via `RunController.startCombat()`.
- `startOfTurn` / `endOfTurn` : Via `RunController.startTurn()` / `TraitSystem.onTurnEnd()`.
- `onCardPlayed` : Via `CombatController.applyPlayerCardPlay()`.
- `onEnemyKilled` : Via `CombatController._cleanDeadEnemies()` → `RunController.onEnemyKilled()`.

### 3.6. 🎪 Système d'Événements

**2 événements** dans `events.json`, chacun avec 3 choix narratifs :

| Événement | Choix | Actions |
|:---|:---|:---|
| `mysterious_altar` (Autel Mystérieux) | Sacrifier du sang | `take_damage: 15`, `gain_strength: 3` |
| | Offrande d'or | `spend_gold: 30`, `gain_max_hp: 10` |
| | Prier et partir | aucune action |
| `goblin_merchant` (Marchand Gobelin) | Acheter un sac | `spend_gold: 25`, `gain_relic` (tirage influencé par luck) |
| | Voler le gobelin | `take_damage: 10`, `gain_gold: 50` |
| | Aider à se cacher | `gain_gold: 15` |

**Algorithme de rareté pour `gain_relic`** (influencé par `luck`) :
| Rareté | Proba base (luck=0) | Bonus par point de luck |
|:---|:---|:---|
| Legendary | 1% | +0.5% |
| Epic | 5% | +1.0% |
| Rare | 14% | +2.0% |
| Uncommon | 20% | +3.0% |
| Common | Reste | — |

### 3.7. 🏕️ Feu de Camp / Repos (`RestScreen`)

Trois options interactives s'offrent au joueur sur l'écran `RestScreen` :
1. **Repos** : Soigne 30% du HP maximum.
2. **Forge** : Ouvre la boîte de dialogue `ForgeUpgradeDialog` pour appliquer des améliorations probabilistes permanentes à une carte, consommant de l'or.
3. **Oubli** : Sélectionne une carte pour la supprimer définitivement du Master Deck.

---

### 3.10. 🔨 Système de Forge Découplé

La forge permet d'ajouter des améliorations permanentes (upgrades) aux cartes du Master Deck en échange d'or :
- **Limite de Capacité** : Une carte peut accueillir au maximum $baseMaxForgeUpgrades + rarityIndex$ améliorations (la capacité augmente avec la rareté de la carte).
- **Génération Probabiliste de Slots** : À chaque entrée en forge pour une carte, 1 à 5 slots d'options d'upgrades sont générés indépendamment selon les chances suivantes :
  - Slot 1 : 100%
  - Slot 2 : 50%
  - Slot 3 : 25%
  - Slot 4 : 10%
  - Slot 5 : 2%
- **Pools d'Améliorations Clamps** : Les améliorations proposées sont tirées depuis des pools liés à la rareté de la carte :
  - *Common* : Améliorations de stats (`sharp` pour les dégâts, `hardened` pour l'armure) et statuts élémentaires (`burning`, `freezing`, `shocking`) limités aux cartes Attaque.
  - *Uncommon* : Pioche de cartes supplémentaires (`quick`).
  - *Rare* : Gains de mana (`eco`) et retrait d'épuisement (`enduring` persistant, retirant `exhaust`), réservé aux cartes non-pouvoir exhaustibles.
- **Pondération et Tiers** : Le tirage des pools est pondéré par l'index de rareté de la carte. Les Tiers des upgrades suivent la distribution : Tier I (80%), Tier II (15%), Tier III (5%).
- **Relance Individuelle (Reroll)** : Le joueur peut relancer le tirage d'un slot spécifique. Le coût augmente exponentiellement par slot :
  $$\text{Coût} = \text{round}(20 \times 1.25^n)$$
  où $n$ est le nombre de relances déjà appliquées à ce slot. Consomme l'or de l'inventaire via `inventoryProvider`.

### 3.8. 🛒 Boutique (Shop)

Gérée par `ShopController` :
- **Inventaire initial** : 3 + `bonusShopCards` cartes aléatoires (filtrage des cartes status).
- **Prix** : Common = 25 or, Uncommon = 50, Rare/Epic/Legendary = 100.
- **Services additionnels** :
  - Soin (achat unique par visite)
  - Expansion de boutique (+1 carte permanent, via `InventoryController.buyShopExpansion()`)
  - Reroll des cartes
  - Purge de carte (suppression définitive du deck)
  - Clone de carte (duplication au même level)

### 3.9. 🃏 Poli Visuel et Sélection de Récompenses (Draft Screen Polish)

Le système de draft (que ce soit pour le draft de récompense de combat dans `DraftScreen` ou dans le module d'apprentissage du tutoriel `TutorialDraftWidget`) intègre un feedback visuel et tactile premium pour guider les sélections du joueur :
- **Survol (Hover)** : Le passage du curseur sur une carte déclenche un gonflement d'échelle fluide à `1.05x` (`AnimatedScale` combiné à un `MouseRegion`) pour indiquer sa mise au point.
- **Sélection (Selection)** : Cliquer/taper sur une carte de récompense la sélectionne activement, ce qui la fait grossir à `1.12x` et projette un halo lumineux doré tout autour de la carte (`BoxShadow` couleur ambre `Colors.amber` avec un rayon de flou de 16px et une extension de 3px).
- **Consistance** : Ces animations de scale et de lueur partagent la même identité visuelle pour assurer la cohérence entre la phase d'apprentissage guidée et les combats réels du jeu.

---

## 4. Altérations d'État & Statuts (Status Effects)

Les combattants accumulent des altérations d'état. Le décompte (`tickStatuses()`) s'opère au début de leur tour respectif.

### 4.1. Statuts Implémentés

| Statut (`id`) | Type | Empilable | Effet Mécanique | Tick |
|:---|:---:|:---:|:---|:---|
| `poison` | Debuff | Oui | Inflige dégâts directs = valeur au début du tour | Durée -1 chaque tour |
| `strength` | Buff | Oui | Ajoute sa valeur à `effectiveAttaque` pour les dégâts physiques | Durée -1 chaque tour |
| `weakness` | Debuff | Oui | Réduit les dégâts physiques infligés de **25%** (`×0.75`) | Durée -1 chaque tour |
| `strength_regen` | Buff | Oui | Ajoute sa valeur au statut `strength` au début du tour | Durée -1 chaque tour |
| `armor_regen` | Buff | Oui | Génère de l'armure = valeur au début du tour | Durée -1 chaque tour |
| `burn` | Debuff | Oui | Inflige des dégâts de feu = valeur active au début du tour. Le tick réduit la valeur et la durée de 1. | Durée -1 chaque tour |
| `freeze` | Debuff | Oui | Réduit les dégâts offensifs du prochain coup de l'ennemi de **50%** et décrémente immédiatement la durée du gel. | Durée -1 chaque tour |
| `shock` | Debuff | Oui | Ajoute sa valeur active cumulée à tout dégât d'attaque direct subi par la cible. | Durée -1 chaque tour |
| `vulnerable` | Debuff | Oui | Augmente universellement tous les dégâts reçus de **50%** (arrondi). Affecte autant le Héros que les Ennemis. | Durée -1 chaque tour |

### 4.2. Statuts Partiellement Implémentés
Aucun. Tous les statuts décrits ci-dessus sont 100% implémentés et opérationnels dans le calcul des dégâts.

### 4.3. Mécanique de Stacking (`StatusEffect.combine`)

```dart
if (isStackable) {
  value += other.value;
  duration = max(duration, other.duration);
} else {
  value = max(value, other.value);
  duration = max(duration, other.duration);
}
```

---

## 5. Compétences Héroïques (Skills)

**6 compétences** (2 par héros) dans `skills.json` :

| ID | Héros | Nom | Coût Mana | Type d'Effet | Valeur | Mécanisme |
|:---|:---|:---|:---|:---|:---|:---|
| `paladin_shield` | Paladin | Bouclier | 3 | `armor_buff` | 15 | Gain d'armure (+armorMastery) |
| `paladin_rage` | Paladin | Rage | 5 | `attack_buff` | 2 | Buff force (15% maxPv, durée 2) |
| `mage_nova` | Mage | Nova | 4 | `damage_aoe` | 20 | Dégâts à tous les ennemis |
| `mage_strike` | Mage | Frappe Foudre | 8 | `damage_targeted` | 150 | Dégâts massifs ciblés |
| `berserker_leech` | Berserker | Vampirisme | 0 | `lifesteal_buff` | 3 | Buff lifesteal (durée 3) |
| `berserker_pierce` | Berserker | Perce-Armure | 3 | `damage_pierce` | 15 | Dégâts perçants (ignore armure) |

**Cooldown** : Chaque compétence a un cooldown qui se décrémente de 1 par tour (`SkillController.tickCooldowns()`). Utilisable quand `cooldown <= 0`.

---

## 6. Économie de Jeu

### 6.1. Or

- **Or initial** : 50 (défini dans `InventoryController.reset(initialGold: 50)`).
- **Sources** : Victoires combat (via `completeCurrentNode`), événements (`gain_gold`), reliques.
- **Dépenses** : Boutique (cartes, services), événements (`spend_gold`).

### 6.2. Récompenses Post-Combat

Le système de récompenses par statistiques (Vitalité, Aiguisage, Forge, Sagesse) est géré par `RunController.applyHeroStatModifier()` avec des multiplicateurs de rareté.

| Attribut | Bonus base | Note |
|:---|:---|:---|
| `maxPvAcc` | +X PV Max | Soigne aussi le delta |
| `attackAcc` | +X Attaque permanente | Additionné à `effectiveAttaque` |
| `armorAcc` | +X Maîtrise d'Armure | Bonus permanent sur tous les gains d'armure |
| `maxManaAcc` | +X Mana Max | Augmente le plafond régénéré chaque tour |
| `luckAcc` | +X Chance | Influence rareté des récompenses et reliques |

---

## 7. Architecture des Données (100% Data-Driven)

### 7.1. Chaîne de Chargement

```
assets/data/*.json  →  rootBundle.loadString()  →  jsonDecode()
    →  *.fromJson()  →  GameDataRegistry  →  gameDataLoaderProvider (FutureProvider)
```

`GameDataService.loadAll()` charge les 7 fichiers JSON via `Future.wait()` (chargement parallèle).

### 7.2. Graphe de Relations entre Modèles

```
HeroData.passiveTrait ──────────► PassiveData.id
CardData.heroClass ──────────────► HeroData.id (nullable = global)
PassiveData.trigger ─────────────► RelicTrigger (enum partagé avec RelicData)
CardInstance.data ───────────────► CardData
EnemyInstance.data ──────────────► EnemyData
EnemyInstance.stats ─────────────► EntityStats
EntityStats.statuses ────────────► List<StatusEffect>
CombatState.enemies ─────────────► List<EnemyInstance>
EventState.activeEvent ──────────► EventData
EventState.selectedChoice ───────► EventChoice
InventoryState.relics ───────────► List<RelicData>
ShopState.cardsForSale ──────────► List<CardData>
GameDataRegistry ────────────────► List<T> pour chaque type de données
```

### 7.3. Internationalisation (i18n)

- **UI Flutter** : 100% via `AppLocalizations` (fichiers ARB `app_en.arb`, `app_fr.arb`). Zéro chaîne codée en dur.
- **Données JSON** : Double-champs bilingues (`nameEn`/`nameFr`, `descriptionEn`/`descriptionFr`) sur tous les modèles Data.
- **Méthodes d'accès** : `getName(locale)`, `getDescription(locale)` sur chaque modèle.
- **Exception** : `SkillData` n'a qu'un champ `name` unique (pas de support bilingue).
- **Statuts de combat** : Traduits à la volée par `StatusEffectsPanel` à partir d'identifiants techniques neutres.

---

## 8. Système de Tutoriel Autonome (Tutorial System)

Pour accompagner les nouveaux joueurs sans alourdir ou impacter le moteur de combat principal et l'état Riverpod global du jeu, un système de tutoriel entièrement autonome et auto-suffisant a été implémenté.

### 8.1. Architecture découplée et autonome

- **Emplacement dédié** : Le dossier `lib/tutorial/` regroupe l'intégralité du code du tutoriel (moteur, données, écran d'accueil, et widgets d'étapes).
- **Zéro dépendance Riverpod** : Pour éliminer le risque d'effets de bord avec la run de production, le tutoriel n'utilise aucun provider Riverpod (pas de `runProvider`, `deckProvider` ou `combatProvider`).
- **Moteur local (`TutorialEngine`)** : Un simple `ChangeNotifier` Dart gère l'état courant et la transition pas-à-pas.
- **État simulé (`TutorialMockState`)** : L'état contient des POJOs simplifiés (`TutorialCard`, `TutorialEnemy`) simulant les PV du héros (80/80), son mana (3/3), son armure, sa main, son deck, et un ennemi factice avec ses intentions. L'état est réinitialisé et préparé différemment pour chaque étape spécifique du tutoriel.

### 8.2. Déroulement en 13 Étapes Progressives

Le tutoriel se présente sous la forme d'un `PageView` non-swipeable, où la progression est bloquée ou validée par des interactions spécifiques :
1. **Accueil (Welcome)** : Introduction avec logo animé et résumé du jeu.
2. **Carte (World Map)** : Présentation de la carte sous forme de mini-carte interactive avec des bulles d'aide explicatives.
3. **Nœuds (Node Types)** : Explication didactique des 6 types de salles (Combat, Élite, Boutique, Repos, Événement, Boss).
4. **Combat (Combat Overview)** : Visualisation statique annotée d'une zone de combat (Héros, Ennemis, Deck, Compétences).
5. **Mana & Cartes (Cards & Mana)** : Apprentissage des coûts en mana et des types de cartes. Le joueur doit toucher les cartes pour voir les modifications de focus.
6. **Jouer une Carte (Play Card)** : Première phase active. Le joueur doit jouer des cartes (Frappe Basique) pour entamer les points de vie d'un Slime d'entraînement, avec déclenchement de textes flottants de dégâts.
7. **Dégâts & Armure (Armor & Damage)** : Démo comparative. Le joueur subit des dégâts avec et sans armure pour voir l'impact visuel de l'absorption par l'armure.
8. **Statuts Élémentaires (Status Effects)** : Galerie interactive détaillant le Poison, la Brûlure, le Gel, et l'Électrocution.
9. **Intentions Ennemies (Enemy Intents)** : Décryptage des icônes d'intentions affichées au-dessus des ennemis (Attaque, Défense, Buff).
10. **Fusion de Cartes (Merge)** : Démo interactive de la fusion 3-en-1. Le joueur fusionne 3 cartes identiques pour obtenir une version de rareté supérieure avec transfert d'améliorations.
11. **XP & Niveaux (XP & Level Up)** : Accumulation d'expérience interactive jusqu'au passage de niveau du héros.
12. **Draft (Reward Draft)** : Simulation de draft de fin de combat avec effets de survol/sélection dorée et scale-up (identique au jeu de production).
13. **Reliques (Relics Carousel)** : Présentation des reliques passives de combat avec défilement de carrousel.

### 8.3. Internationalisation et Persistance

- **i18n Intégrée** : Pour respecter les règles de bilinguisme, le modèle `TutorialStepData` intègre ses propres champs doublés (`titleEn`/`titleFr`, `bodyEn`/`bodyFr`). La sélection de la langue est résolue dynamiquement à l'affichage via `Localizations.localeOf(context).languageCode`.
- **Persistance (`SharedPreferences`)** : L'état de complétion du tutoriel est stocké par le service `TutorialProgressService` sous la clé `tutorial_completed`.
- **Badge "NEW" sur l'Accueil** : L'écran d'accueil (`HomeScreen`) affiche un badge "NEW" rouge et brillant à côté du bouton "TUTORIEL" tant que le joueur ne l'a pas terminé. Une fois le tutoriel complété au moins une fois, le badge disparaît définitivement. Le tutoriel reste rejouable à l'infini pour réviser les bases.
