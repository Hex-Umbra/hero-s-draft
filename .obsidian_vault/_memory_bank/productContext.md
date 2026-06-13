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
  Constitution du deck : choix de 5 cartes globales + cartes de classe uniques chargées via compétences
       │
       ▼
[Carte Stratégique (MapScreen)] ◄─── Graphe Acyclique Dirigé (10 étages)
  │   ▲ (Si pendingDrafts > 0 : Overlay Level Up bloquant → DraftScreen)
  │   │
  ├─► [Écrans Spécifiques] : Boutique (ShopScreen), Feu de Camp (CampfireScreen), Événement (EventScreen)
  │
  └─► [Combat (GameScreen)]
        │
        ▼
      [Draft de Récompense (DraftScreen)] (Choix de carte de combat normal)
        │
        ▼
      [Évaluation Auto-Merge (3→1)] (Fusion 3× identiques → 1× de rareté supérieure)
        │
        ▼
      [Retour à la Carte (MapScreen)] (Si montée de niveau : pendingDrafts > 0)
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
| `floors ~/ 2` (ex: 5) | **Chokepoint** : exactement 1 nœud de type `elite` (étage central dynamique) |
| 8 (`floors-2`) | 100% `rest` (tous les nœuds de l'étage 8 sont de type repos) |
| 9 (`floors-1`) | 3 nœuds de type `boss` distincts (permettant un choix de Boss par récompense selon la position x) |

**Distribution probabiliste initiale** (pour les étages 1-4, 6-7) :
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

**Phase 3 — Optimisations et Contraintes Algorithmiques** :
- **Solver de Quotas de Nœuds** (`_balanceQuotas`) : Ajuste itérativement les types de nœuds générés pour respecter les quotas globaux de la carte :
  - Combat : 12 à 22 nœuds
  - Élite : 3 à 6 nœuds
  - Repos : 3 à 6 nœuds
  - Boutique (Shop) : 2 à 5 nœuds
  - Événement (Event) : 4 à 9 nœuds
- **Algorithme Anti-Répétition de Chemin** (`_hasThreeConsecutive`) : Parcourt tous les chemins du graphe de l'entrée aux boss. Garantit qu'aucun chemin ne comporte 3 nœuds consécutifs du type Élite ou du type Repos. Si une violation est détectée, le troisième nœud est converti en un type alternatif (Combat, Boutique ou Événement).

**Mécanique de Récompenses Spécifiques des Boss (Étage 9) selon la position** :
- **Position gauche (x = 0)** : Présente un dialogue interactif affichant 3 cartes globales aléatoires, permettant au joueur d'en sélectionner entre 1 et 3 pour les ajouter gratuitement à son deck (icône Cartes).
- **Position centrale (x = 1)** : Multiplie par 2 toute l'expérience (XP) cumulée par le joueur lors du combat (icône Magie/XP).
- **Position droite (x = 2)** : Garantit l'obtention d'une relique de rareté supérieure (minimum Uncommon, excluant totalement les communes, icône Diamant). Les chances de rareté sont : Legendary 15%, Epic 30%, Rare 35%, Uncommon 20%.

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

### 2.4. Progression de Rareté Dynamique et Fusion Interactive

La progression des cartes s'effectue via des raretés dynamiques (`common` → `uncommon` → `rare` → `epic` → `legendary`), chacune appliquant un coefficient multiplicateur sur les statistiques de base de dégâts et d'armure de la carte.

La fusion de cartes 3-en-1 est gérée par `DeckNotifier.mergeCards(selectedIds, inheritedUpgrades)` :
1. Le joueur sélectionne 3 exemplaires d'une carte ayant la même rareté active.
2. Les 3 copies sont supprimées du `masterDeck`.
3. Une nouvelle copie de rareté directement supérieure est ajoutée au `masterDeck`.
4. **Héritage des Améliorations de Forge** : Les upgrades de même ID voient leurs Tiers additionnés (ex: deux upgrades `sharp:1` fusionnent en un unique `sharp:2`). Le nombre d'améliorations final est limité par la capacité maximale de la nouvelle rareté (`baseMaxForgeUpgrades + rarityIndex`). Le joueur choisit de manière interactive les upgrades qu'il souhaite hériter en cas de dépassement de la capacité.
5. **Restriction de la Rareté Unique** : Les cartes de rareté `unique` (de classe) ne peuvent pas être fusionnées. La logique de fusion est bloquée dans `deck_controller.dart` et l'interface utilisateur n'affiche pas l'option de fusion pour ces cartes.

### 2.5. Bestiaire

**4 ennemis** définis dans `enemies.json` :

| ID | Nom | HP | Dégâts Base | Tier | Pattern d'Intentions | Crit Chance |
|:---|:---|:---|:---|:---|:---|:---|
| `slime` | Slime | 18 | 4 | 1 | [attack:4] — attaque unique répétée | 5% |
| `gobelin` | Gobelin | 28 | 5 | 1 | [attack:5] — attaque unique | 10% |
| `squelette` | Squelette | 22 | 8 | 2 | [attack:8, attack:10] — cycle 2 attaques | 10% |
| `orc` | Orc Furieux | 50 | 8 | 3 | [attack:8, buff:2, attack:12] — cycle 3 phases | 15% |

**Scaling de combat** (`CombatController.initializeCombat`) :
Le niveau d'un ennemi ($EnemyLevel$) est calculé comme suit : $EnemyLevel = \max(1, PlayerLevel + (Act - 1) \times 2 + NodeModifier)$, où $NodeModifier$ est de $+2$ pour un Boss et $+1$ pour un Élite.
Les multiplicateurs de caractéristiques appliqués aux statistiques de base de l'ennemi sont :
- **Multiplicateur HP** : $(1.0 + 0.06 \times (EnemyLevel - 1)) \times (1.0 + 0.20 \times (Act - 1)) \times NodeMultiplier$
- **Multiplicateur Dégâts** : $(1.0 + 0.04 \times (EnemyLevel - 1)) \times (1.0 + 0.15 \times (Act - 1)) \times NodeMultiplier$

Où $NodeMultiplier$ vaut $3.0$ pour un Boss, $1.5$ pour un Élite, et $1.0$ sinon.

> [!IMPORTANT]
> **Règle de Détermination de Boss (`isBoss`)** :
> Un ennemi ou un combat est classifié comme de type Boss si et seulement si :
> 1. Le nœud de la carte est explicitement de type Boss (`nodeType == MapNodeType.boss`).
> 2. Le type de nœud n'est pas spécifié/null (`nodeType == null`) **ET** le niveau/floor de la run est supérieur à 0 et divisible par 10 (`level > 0 && level % 10 == 0`).
> 
> *Raison de la correction* : Auparavant, toute rencontre au floor 10 (ou multiple de 10) était tagguée comme Boss, même si le joueur se trouvait sur un nœud de combat standard (`MapNodeType.combat`), appliquant à tort un multiplicateur massif de statistiques ($3.0 \times$ HP / $2.0 \times$ Dégâts). La correction garantit que les modificateurs de boss ne s'appliquent pas aux nœuds de combat classiques, préservant ainsi l'équilibrage de la courbe de difficulté.


| Type | Multiplicateur HP de Base | Multiplicateur Attaque de Base | Nombre |
|:---|:---|:---|:---|
| Normal (level ≤5) | ×1.0 | ×1.0 | 1-2 |
| Normal (level >5) | ×1.0 | ×1.0 | 1-3 |
| Élite | ×1.5 | ×1.5 | 2-3 |
| Boss | ×3.0 | ×2.0 | 1 |

### 2.6. Équilibrage Hybride, Budget de Menace et Réserve de Vagues

Pour offrir un défi adapté aux choix stratégiques du joueur tout en évitant la trivialisation ou le blocage, le jeu utilise un système d'équilibrage hybride :

1. **Mécanique de Difficulté Dynamique (DDA Hybride)** :
   La difficulté ajuste la composition des combats selon un budget de menace calculé en comparant la puissance réelle du joueur avec celle théoriquement attendue :
   - **Puissance Réelle du Joueur (`PlayerPower`)** : Évaluée en agrégeant ses PV max, son attaque permanente, son mana maximum et son nombre de reliques :
     $$\text{PlayerPower} = \text{maxHP} + (\text{attaque} \times 10) + (\text{maxMana} \times 15) + (\text{relicsCount} \times 5)$$
   - **Puissance Attendue (`ExpectedPower`)** : Modèle de progression théorique basé sur le niveau du joueur et l'acte en cours :
     $$\text{ExpectedPower} = 145 + [(\text{playerLevel} - 1) \times 15] + [(\text{act} - 1) \times 20]$$
   - **Ajustement Amorti (`PowerModifier`)** : Un ratio de puissance amorti à $0.5$ pour éviter les sauts brusques de difficulté :
     $$\text{PowerRatio} = \frac{\text{PlayerPower}}{\text{ExpectedPower}}$$
     $$\text{PowerModifier} = 1.0 + (\text{PowerRatio} - 1.0) \times 0.5$$

2. **Budget de Menace du Combat (`FinalBudget`)** :
   Le budget théorique de base (`BaseBudget`) augmente avec le niveau du joueur et l'acte :
   $$\text{BaseBudget} = 40 + [(\text{playerLevel} - 1) \times 10] + [(\text{act} - 1) \times 25]$$
   Le budget final alloué au combat combine le budget de base, le modificateur de puissance dynamique, et un multiplicateur lié au type de nœud :
   $$\text{FinalBudget} = \text{BaseBudget} \times \text{PowerModifier} \times \text{NodeMultiplier}$$
   *(Avec `NodeMultiplier` = 1.0 pour un combat normal, 1.5 pour un combat élite, et 2.0 pour un boss)*

3. **Système de Score de Menace (`CombatRating`)** :
   Chaque ennemi est doté d'une valeur de menace dynamique reflétant sa puissance réelle après application des multiplicateurs de scaling (niveau, acte, modificateur de nœud) :
   $$\text{CombatRating} = (\text{tier} \times 10) + \text{HP\_Scalé} + \text{Armure\_Scalée} + \text{Dégâts\_Scalés} \times \left(1.0 + \frac{\text{critChance}}{100.0}\right)$$
   Le générateur choisit des candidats aléatoires dont la `CombatRating` est inférieure ou égale au budget restant, et déduit cette note du budget jusqu'à ce que plus aucun ennemi disponible ne rentre dans l'enveloppe budgétaire. Un fallback garantit au moins un ennemi si le budget est trop faible.

4. **Système de Réserve de Vagues (`pendingEnemies`)** :
   Pour éviter de surcharger le board visuel de Flame et limiter les calculs de ciblage, le nombre d'ennemis actifs affichés simultanément est limité à **5 slots maximum**.
   - Si le budget de menace permet de générer plus de 5 ennemis, les 5 premiers sont instanciés en tant qu'ennemis actifs sur le board (`enemies`), tandis que le reste est placé dans une file d'attente de réserve (`pendingEnemies`).
   - Lorsqu'un ennemi actif meurt en combat, le système vérifie s'il y a des ennemis en réserve. Si c'est le cas et que le nombre d'ennemis actifs est inférieur à 5, le premier ennemi de la file de réserve est immédiatement extrait, transféré sur le board actif, et doté de sa première intention de combat.
   - Le combat ne se termine par une victoire que lorsque la liste des ennemis actifs **ET** la liste de réserve sont entièrement vides.

### 2.7. 🔄 Autel d'Échange de Reliques (Relic Exchange Shrine)

L'Autel d'Échange de Reliques est un type de nœud spécifique sur la carte stratégique permettant de sacrifier 3 reliques d'une rareté donnée pour obtenir 1 relique de rareté supérieure.

1. **Règles de Génération de la Carte** :
   - Le nœud `relicExchange` (emoji `🔄`) n'apparaît qu'à partir de l'**Acte 5**.
   - **Tous les 5 actes** (Acte 5, 10, 15, etc.), un nœud d'échange est **garanti à 100%** sur la carte.
   - Pour les autres actes ($\ge 5$), il y a **10% de chances** qu'un nœud d'échange apparaisse.
   - Le nœud est positionné aléatoirement sur un étage intermédiaire (étage 2, 3, 4, 6 ou 7) pour ne pas perturber les nœuds de départ, de repos obligatoire ou de boss.

2. **Algorithme d'Offre Déterministe** :
   - Pour éviter de stocker la relique offerte dans la base de données du nœud, le système utilise un générateur pseudo-aléatoire seedable basé sur l'identifiant du nœud et l'acte en cours : `Random((node.id.hashCode ^ act).abs())`.
   - La relique offerte est choisie parmi les raretés `Uncommon` (40%), `Rare` (35%), `Epic` (20%), et `Legendary` (5%). Les reliques communes sont exclues de l'offre (car il n'y a pas de rareté inférieure à sacrifier).

3. **Règle d'Échange (3 pour 1)** :
   - Pour obtenir la relique proposée de rareté $R$, le joueur doit sacrifier **exactement 3 reliques** de la rareté directement inférieure $R-1$ de son inventaire (par exemple, 3 reliques Peu Communes pour obtenir une relique Rare offerte).
   - Lors de la transaction, les effets permanents de run (comme l'Attaque, le Critique, la Chance ou le Mana max permanent) associés aux reliques sacrifiées sont **inversés et retirés** de la fiche de personnage du héros avant d'appliquer les effets de la nouvelle relique acquise.

4. **Interface Utilisateur (`RelicExchangeScreen`)** :
   - L'écran propose une ambiance immersive d'autel magique en parchemin.
   - Il affiche la relique offerte ainsi que la liste des reliques possédées de la rareté requise pour le sacrifice.
   - Le joueur peut sélectionner les 3 reliques à détruire (décoration avec lueur dorée pour les éléments sélectionnés).
   - Le bouton d'échange n'est activé que lorsque 3 reliques valides sont cochées.
   - Le joueur peut choisir de quitter l'autel à tout moment sans procéder à l'échange.

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

**Maîtrise d'Armure (`armorMastery`)** : Statistique cumulative et permanente. Tous les gains d'armure dans `RunController` et `TraitSystem` ajoutent systématiquement l'Armor Mastery effective (obtenue via le getter dynamique `effectiveArmorMastery` sur `EntityStats`, qui combine la base `armorMastery` et les bonus temporaires de combat issus du statut `'armor_mastery'`) au montant.

**Persistance et Cycle de Reset** :
- **Reset de Tour** : L'armure accumulée par le joueur est réinitialisée à `0` au début de son tour (au lancement de `startTurn()` dans `RunController`, avant l'application des reliques et effets de statut de début de tour). Cela évite l'accumulation infinie d'armure d'un tour à l'autre et garantit l'équilibrage des reliques ou effets générateurs d'armure.
- **Suppression d'Animation** : Lors de cette réinitialisation en début de tour, les animations visuelles de perte d'armure (popup textuel négatif comme "-X" et animation de secousse de bouclier) sont désactivées via un drapeau transitoire (`suppressArmorChangeAnimation` sur `HeroCard`) pour éviter d'indiquer à tort que le joueur a subi des dégâts.
- **Fin de Combat** : L'armure restante est également remise à 0 à la fin de chaque combat (`completeCurrentNode()`).
- **Maîtrise d'Armure** : La Maîtrise d'Armure (`effectiveArmorMastery`), quant à elle, reste persistante tout au long de la partie ou du combat selon son origine.

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

**24 reliques** définies dans `relics.json` (au lieu de 14 initialement, équilibrant le pool commun), organisées par déclencheurs et types d'effets :

| ID | Nom | Rareté | Trigger | Effet | Valeur | Description |
|:---|:---|:---|:---|:---|:---|:---|
| `iron_talisman` | Talisman de Fer | Common | startOfTurn | gain_armor | 2 | Gagne 2 points d'Armure au début de chaque tour. |
| `whetstone` | Pierre à aiguiser | Common | startOfRun | gain_strength | 1 | +1 Force de manière permanente pour toute la run. |
| `leather_boots` | Bottes en cuir | Common | startOfCombat | gain_armor | 3 | Gagne 3 points d'Armure au début du combat. |
| `lucky_coin` | Pièce de chance | Common | startOfRun | gain_crit | 5 | +5 de chance de coup critique de manière permanente pour toute la run. |
| `bandage` | Bandage de voyage | Common | endOfTurn | heal | 1 | Restaure 1 PV à la fin de chaque tour. |
| `ancestral_shield` | Bouclier Ancestral | Uncommon | startOfCombat | gain_armor | 5 | Gagne 5 points d'Armure au début du combat. |
| `protection_rune` | Rune de Protection | Uncommon | endOfTurn | gain_armor | 3 | Gagne 3 points d'Armure à la fin de chaque tour. |
| `cursed_blade` | Lame Maudite | Uncommon | startOfRun | gain_strength | 2 | +2 Force de manière permanente pour toute la run. |
| `vampiric_fang` | Croc Vampirique | Uncommon | onEnemyKilled | heal | 8 | Restaure 8 PV chaque fois qu'un ennemi meurt. |
| `lucky_charm` | Porte-bonheur | Uncommon | startOfRun | gain_crit | 10 | +10% de chance de critique de manière permanente pour toute la run. |
| `pen_nib` | Plume de scribe | Uncommon | onCardPlayed | charge_strength_turn | 3 | Toutes les 5 cartes jouées, gagne 3 Force pour le tour en cours. |
| `mage_amulet` | Amulette du Mage | Rare | onCardPlayed | gain_armor | 1 | Gagne 1 point d'Armure chaque fois que vous jouez une carte. |
| `mana_crystal` | Cristal de Mana | Rare | startOfCombat | gain_mana | 1 | Gagne 1 Mana au début du combat (tour 1 uniquement). |
| `spirit_essence` | Essence Spirituelle | Rare | onEnemyKilled | gain_mana | 1 | Gagne 1 Mana chaque fois qu'un ennemi meurt. |
| `regen_ring` | Anneau Régenérant | Rare | endOfTurn | heal | 2 | Restaure 2 PV à la fin de chaque tour. |
| `critical_lens` | Lentille de Focalisation | Rare | startOfRun | gain_crit | 15 | +15% de chance de critique de manière permanente pour toute la run. |
| `kunai` | Croc Kunaï | Rare | onAttackPlayed | charge_armor_mastery_combat | 1 | Toutes les 3 attaques jouées dans un tour, gagne 1 Maîtrise d'Armure pour le combat. |
| `shuriken` | Shuriken | Rare | onAttackPlayed | charge_strength_combat | 1 | Toutes les 3 attaques jouées dans un tour, gagne 1 Force pour le combat. |
| `incense_burner` | Encensoir | Rare | startOfTurn | charge_armor_turn | 8 | Tous les 4 tours, gagne 8 points d'Armure. |
| `lucky_clover` | Trèfle Chanceux | Epic | startOfRun | gain_luck | 1 | +1 Chance de manière permanente pour toute la run. |
| `energy_stone` | Pierre d'Énergie | Epic | startOfTurn | gain_mana | 1 | Gagne 1 Mana au début de chaque tour. |
| `phoenix_feather` | Plume de Phénix | Epic | startOfCombat | gain_mana | 2 | Gagne 2 Mana au début du combat. |
| `fortune_dice` | Dés de Fortune | Legendary | startOfRun | gain_luck | 2 | +2 Chance de manière permanente pour toute la run. |
| `crown_kings` | Couronne des Rois | Legendary | startOfRun | gain_mana | 1 | Gagne 1 Mana Max de manière permanente au début de la run. |

**Cycle de vie des triggers** :
- `startOfRun` : Appliqué immédiatement à l'ajout (`InventoryController.addRelic()`).
- `startOfCombat` : Via `RunController.startCombat()`.
- `startOfTurn` / `endOfTurn` : Via `RunController.startTurn()` / `TraitSystem.onTurnEnd()`.
- `onCardPlayed` : Via `CombatController.applyPlayerCardPlay()`.
- `onAttackPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.attack`.
- `onSkillPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.skill`.
- `onPowerPlayed` : Via `CombatController.applyPlayerCardPlay()` si le type de la carte jouée est `CardType.power`.
- `onEnemyKilled` : Via `CombatController._cleanDeadEnemies()` → `RunController.onEnemyKilled()`.

**Système de Charges (Reliques Actives)** :
Les reliques à charges accumulent des compteurs représentés par des effets de statut temporaires ou de combat sur le Héros. Une fois le seuil de charges atteint, le compteur est réinitialisé et l'effet bénéfique s'applique :
- **Kunaï** (`kunai`) : Génère `kunai_charge` (durée 1, donc réinitialisé à chaque tour). À 3 charges, reset et ajoute +1 Maîtrise d'Armure pour le combat via le statut temporaire `'armor_mastery'` (durée 99).
- **Shuriken** (`shuriken`) : Génère `shuriken_charge` (durée 1). À 3 charges, reset et ajoute +1 Force permanente pour le combat (`strength` de 99 tours).
- **Plume de Scribe** (`pen_nib`) : Génère `pen_nib_charge` (durée 99). À 5 charges, reset et ajoute +3 Force temporaire pour le tour en cours (`strength` de 1 tour).
- **Encensoir** (`incense_burner`) : Génère `incense_charge` (durée 99). À 4 charges, reset et octroie +8 points d'Armure.

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

### 3.10. 🔨 Système de Forge Découplé (Forge v2)

La forge permet d'ajouter des améliorations permanentes (upgrades) aux cartes du Master Deck en échange d'or. Elle intègre un ensemble de règles de protection et de confort utilisateur révisées en version v0.2.00 :
- **Limite de Capacité & Fentes de Runes (Rune Sockets)** : Une carte peut accueillir au maximum $baseMaxForgeUpgrades + rarityIndex$ améliorations (la capacité augmente avec la rareté de la carte). Les cartes uniques de classe ont une limite fixe de 5 améliorations. Les améliorations de forge sont représentées par des fentes de runes circulaires disposées sur plusieurs rangées (maximum 5 fentes par ligne, avec retour à la ligne automatique géré par `Wrap` en Flutter et par division/coordonnées Canvas en Flame).
- **Génération Probabiliste de Slots de Base** : À chaque session d'ouverture pour une carte donnée, le système génère de 1 à 5 slots d'options d'upgrades indépendants (tirages de Bernoulli successifs) selon les chances suivantes :
  - Slot 1 : 100% (Garanti)
  - Slot 2 : 50%
  - Slot 3 : 25%
  - Slot 4 : 10%
  - Slot 5 : 2%
- **Anti-Exploit de Reroll Sauvage (Session Persistence)** : Afin d'éviter que le joueur ne contourne le coût des relances ou ne force de meilleures options en fermant et rouvrant simplement la forge, la session de forge active est persistée dans `RunState` (`forgeSlots` contenant les options tirées formatées `id:tier`, et `forgeTargetCardId` contenant l'identifiant unique de la carte ciblée).
  - Si le joueur ouvre la forge sur une carte et que `runState.forgeTargetCardId == card.uniqueId`, le dialogue charge immédiatement les fentes préalablement générées et sauvegardées.
  - Si la carte est différente ou s'il n'y a pas de session active, un nouveau tirage est effectué et immédiatement sauvegardé via `RunNotifier.setForgeSession()`.
  - La session n'est effacée (via `clearForgeSession()`) qu'après validation d'une amélioration ou lors du départ définitif du camp de repos (`RestScreen`).
- **Filtrage Intelligent par Type de Carte** : Les améliorations proposées sont filtrées en amont selon le type de carte pour éviter les tirages aberrants ou inutiles :
  - *skill* (Compétence) : Exclut toutes les options offensives de dégâts physiques (`sharp`) ou élémentaires (`burning`, `freezing`, `shocking`).
  - *power* (Pouvoir) : Autorise uniquement les améliorations utilitaires (`eco` pour la réduction de coût mana, `quick` pour piocher une carte, et `enduring` pour retirer l'effet d'épuisement).
  - *attack* (Attaque) : Conserve l'accès au pool complet de toutes les améliorations (stats physiques, élémentaires, pioche, réduction de coût, enduring).
- **Pools d'Améliorations Clamps par Rareté** : Les améliorations proposées sont tirées depuis des pools liés à la rareté de la carte :
  - *Common* : Améliorations de stats (`sharp`, `hardened`) et statuts élémentaires (`burning`, `freezing`, `shocking` - réservés aux attaques).
  - *Uncommon* : Pioche de cartes supplémentaires (`quick`).
  - *Rare* : Gains de mana (`eco`) et retrait d'épuisement (`enduring` persistant), réservé aux cartes non-pouvoir exhaustibles.
- **Pondération des Tiers** : Le tirage des pools est pondéré par l'index de rareté de la carte. Les Tiers des upgrades suivent la distribution : Tier I (80%), Tier II (15%), Tier III (5%).
- **Relance Individuelle (Reroll)** : Le joueur peut relancer le tirage d'un slot spécifique. Le coût en or augmente exponentiellement par slot :
  $$\text{Coût} = \text{round}(20 \times 1.25^n)$$
  où $n$ est le nombre de relances déjà appliquées à ce slot. Consomme l'or de l'inventaire via `inventoryProvider`.
- **Achat de Fentes Progressives (Buy Slots)** : Le joueur peut étendre sa grille d'options en achetant des fentes bonus additionnelles (champ `bonusForgeSlots` de `RunState`).
  - Capacité maximale : Capée à 4 fentes bonus achetées (soit un maximum de 5 slots affichés au total).
  - Tarification progressive en or : $50 \rightarrow 80 \rightarrow 120 \rightarrow 175$ Or.
  - Le bouton d'achat en bas de la liste est désactivé si l'or disponible est insuffisant ou si la capacité maximale de 5 slots est atteinte.
- **Rendu Plein Écran & UI Responsive** : Le dialogue de forge (`ForgeUpgradeDialog`) a été converti en interface plein écran réactive (`Dialog.fullscreen`) :
  - Desktop : Disposition en colonnes jumelles (`Row`), affichant le visuel de la carte sélectionnée avec ses étoiles à gauche, et le panneau de défilement scrollable (`ListView`) contenant les slots d'amélioration et le bouton d'achat à droite.
  - Mobile : Empilement vertical fluide (`Column`) assurant un scroll confortable et empêchant tout débordement (RenderFlex overflow).

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

Le système de draft (que ce soit pour le draft de récompense de combat dans `DraftScreen`, le draft de montée de niveau sur la carte du monde, ou le module d'apprentissage du tutoriel `TutorialDraftWidget`) intègre un feedback visuel et tactile premium pour guider les sélections du joueur :
- **Survol (Hover)** : Le passage du curseur sur une carte déclenche un gonflement d'échelle fluide à `1.05x` (`AnimatedScale` combiné à un `MouseRegion`) pour indiquer sa mise au point.
- **Sélection (Selection)** : Cliquer/taper sur une carte de récompense la sélectionne activement, ce qui la fait grossir à `1.12x` et projette un halo lumineux doré tout autour de la carte (`BoxShadow` couleur ambre `Colors.amber` avec un rayon de flou de 16px et une extension de 3px).
- **Consistance** : Ces animations de scale et de lueur partagent la même identité visuelle pour assurer la cohérence entre la phase d'apprentissage guidée et les combats réels du jeu.
- **Draft de Level Up Différé** : En cas de montée de niveau en combat, l'ouverture du draft est différée. Elle est matérialisée par un overlay d'animation plein écran « LEVEL UP ! » sur la carte du monde (`MapScreen`). Cet overlay bloque toute interaction avec les nœuds de la carte et, lors d'un clic, redirige le joueur vers le `DraftScreen` via une route de navigation classique.
- **Protection Anti-Spoil de la Roulette de Reliques** : Pendant la rotation du carrousel de récompense (`RelicRewardCarouselOverlay`), les cartes de reliques sont présentées sous un aspect gris neutre et anonyme. Les badges de rareté et de déclencheurs affichent « ??? ». Une fois le carrousel arrêté sur la relique cible, l'état bascule (`isWon = true`), révélant les vraies couleurs et badges, colorant le nom de la relique selon sa rareté et affichant le titre de rareté dans l'en-tête supérieur avec un effet de lueur.

### 3.11. 🎯 Système de Coup Critique (Critical Hit System)

Le coup critique introduit un élément probabiliste d'amplification des effets offensifs et curatifs du joueur et des ennemis :
- **Attributs Fondamentaux** (`EntityStats`) :
  - `critChance` : Le taux de base (en %) pour déclencher un coup critique (défaut: `0`).
  - `critMultiplier` : Le coefficient de multiplication des dégâts ou des soins (défaut: `1.5`).
- **Calcul en Combat & État Déterministe (v0.1.7)** :
  - La chance critique effective est calculée dynamiquement par le getter `effectiveCritChance` qui combine `critChance` permanente et les éventuels bonus temporaires issus du statut `crit_chance`.
  - **Suivi d'État Précis** : Au lieu de se baser sur des seuils de dégâts arbitraires lors de l'affichage, l'état de coup critique est formellement propagé et suivi au niveau du modèle d'état (`EntityStats.lastActionWasCrit`). Ce flag booléen est calculé lors des jets de dés en phase métier (`EffectResolver` et `CombatController`) et stocké temporairement dans les statistiques de l'entité, permettant à la couche de rendu Flame d'obtenir une source de vérité absolue pour déclencher les effets esthétiques associés.
- **Mécanismes d'Impact** :
  - **Dégâts des Cartes** (`EffectResolver._calculateDamage`) : Les attaques physiques ou magiques du joueur ont une probabilité égale à `effectiveCritChance` de voir leurs dégâts totaux multipliés par `critMultiplier` (arrondi).
  - **Soins des Cartes** (`EffectResolver.resolveCard` case 'heal') : Les soins appliqués au héros ont une chance de coup critique qui multiplie le soin par `critMultiplier`.
  - **Dégâts des Ennemis** (`CombatController.resolveEnemyIntent` case 'attack') : Les attaques d'intentions des ennemis effectuent également un jet de critique basé sur leur propre `effectiveCritChance`, multipliant les dégâts infligés au héros par leur `critMultiplier`.
  - **Compétences Héroïques (Skills)** (`HerosDraftGame.executeSkill`) : Les compétences actives du héros (de zone, ciblées, ou perçantes) effectuent également un jet critique pour multiplier leurs dégâts.
- **Récompenses de Draft de Niveau (Level Up)** :
  - **Précision** : Augmente de façon permanente `critChance` (de +1% à +5% selon la rareté de la récompense).
  - **Férocité** : Augmente de façon permanente `critMultiplier` (en ajoutant de +0.10 à +0.50 au multiplicateur via l'accumulateur `critDamageAcc`).
- **Éléments de Données & Reliques** :
  - Les ennemis dans `enemies.json` possèdent des chances de critiques de base distinctes (slime: 5%, gobelin: 10%, squelette: 10%, orc furieux: 15%).
  - Deux nouvelles reliques spécifiques aux critiques ont été intégrées dans `relics.json` via l'effet `gain_crit` :
    - *Focus Lens* (`critical_lens`, Rare, trigger: `startOfCombat`) : confère un buff temporaire de $+15\%$ de critique en combat.
    - *Lucky Charm* (`lucky_charm`, Uncommon, trigger: `startOfRun`) : confère un bonus permanent de $+10\%$ de critique pour toute la run.


### 3.12. 🎨 Optimisations Visuelles, Fluidité & Animations de Combat

Le moteur graphique Flame intègre des optimisations avancées pour stabiliser le framerate à 60 FPS et maximiser la sensation tactile du jeu :
- **Optimisation GPU (Dessin Direct)** : Les textes de combat (`FloatingText`) et icônes d'effets (`EffectIcon`) sont dessinés sans aucun appel coûteux à `canvas.saveLayer()`, évitant les surcoûts d'allocation GPU off-screen.
- **Optimisation CPU (Cache de Disposition)** : Les composants textuels (`TextPainter`) de `CardComponent` sont mis en cache et ne subissent pas de re-layout pendant les animations. L'opacité est appliquée via `saveLayer` uniquement et conditionnellement lorsque `opacity < 1.0`.
- **Physique de la Pioche** : Les cartes tirées apparaissent à l'emplacement de la pioche `Vector2(40, size.y - 40)` et effectuent des transitions physiques fluides (glissement, mise à l'échelle, rotation) vers la main.
- **Synchronisation Synchrone d'Impact** : Pour un game feel immersif, l'ennemi ciblé ne subit ses effets visuels d'impact (flash de douleur, secousse, FloatingText, émission de particules) qu'au moment précis de la collision de la carte de combat. Les réactions redondantes ont été épurées de `CardAnimator` pour éliminer tout double-déclenchement.
- **Blocage Tactile de Pioche (v0.1.00)** : Durant la distribution des cartes, le drapeau `isEnteringHand = true` bloque tous les callbacks d'interaction (`onTapDown`, `onDragStart`, `onHoverEnter`, `onHoverExit`, `onDragUpdate`) et la durée de transition est portée à `0.7s`. Le drapeau est réinitialisé à `false` via un callback `onComplete`.
- **Tooltips sur Focus Uniquement (v0.1.00)** : Les infobulles de cartes ne s'affichent que lors d'une sélection active (focus). `_buildDetailedDescription()` est enrichie pour lister les améliorations de forge appliquées. L'auto-masquage survient au jeu, à la défocalisation ou au changement de phase.
- **Refonte Visuelle des Cartes (v0.1.5)** :
  - **Style Glassmorphic** : Arrière-plan semi-transparent avec dégradés verticaux subtils (opacité `0.6` à `0.2`) et bordures fines (`1.5` ou `2.5` si sélectionné, opacité `0.5` de typeColor) s'appuyant sur un flou d'arrière-plan de 10px (`BackdropFilter`).
  - **Médaillon de Coût** : Standardisation du coût en mana en haut à gauche sous la forme d'un médaillon circulaire flottant sombre (`Color(0xFF0D1B2A)`) de rayon 12px avec liseré cyan et halo de lueur (shadow), unifiant le design Flame et Flutter.
  - **Fentes de Runes (Rune Sockets) avec Retour à la Ligne** : Remplacement des anciennes étoiles d'upgrades par des réceptacles circulaires représentant la capacité de forge (`baseMaxForgeUpgrades + rarityIndex`), disposés sur plusieurs rangées de 5 slots maximum. Les fentes vides sont des cercles blancs translucides (`0.05` d'opacité) et les améliorations appliquées affichent leur rune spécifique (⚔️, 🛡️, 🪶, 💎, 🔥, ❄️, ⚡, ⏳). Le retour à la ligne automatique est géré via un widget `Wrap` contraint dans une `SizedBox` de largeur `45.0` pixels pour les widgets Flutter (`UiCard`), et calculé mathématiquement sur le Canvas pour le moteur Flame (`CardTextRenderer`) en limitant à 5 slots par rangée, recentrant chaque rangée et décalant verticalement de 16 pixels.
  - **Réduction de 25% & Suppression du Filigrane** : Sizing des cartes réduit à `140 × 196` (aspect ratio `70/110`) et suppression des filigranes décoratifs d'arrière-plan pour optimiser l'espace et clarifier les textes.
  - **Simplification du Ciblage & Icônes Doublées (Raffiné)** : Suppression des badges textuels de ciblage (Cible unique, Tous, Soi) pour libérer de l'espace. Le ciblage multicible (`allEnemies`) est signifié de manière graphique en doublant les icônes d'effets offensifs ou destinés aux ennemis (ex: ⚔️⚔️ pour les dégâts AoE, ou double icône de débuff). Les effets bénéfiques pour le joueur (gain d'armure, soin, mana, pioche, ou buffs de force/régénération) sur ces mêmes cartes ne sont jamais doublés et conservent une icône simple.
  - **Suppression du label de rareté & Identification par la Couleur/Halo** : Retrait des labels textuels de rareté de la face avant de la carte. La couleur canonique de la rareté de la carte (`card.rarity.color`) est appliquée dynamiquement sur le contour de la carte (`rarityColor.withValues(alpha: 0.5)`), sous forme de halo radial de surbrillance (`rarityColor.withValues(alpha: 0.4)` de rayon de flou 15px et de diffusion 4px) à l'arrière-plan lorsque la carte est sélectionnée, et sur le contour de son infobulle (`Border.all(color: rarityColor, width: 1.5)`), garantissant une identification immédiate de sa rareté sans surcharge textuelle.
- **Textes Flottants Premium & Néon (v0.1.7)** : Les nombres flottants de dégâts et d'effets (`FloatingText`) disposent d'ombres néon colorées thématiques (orange/rouge pour les critiques, vert clair pour le poison, cyan/bleu pour le bouclier) dessinées directement sur le Canvas. À l'apparition, ils effectuent une légère rotation aléatoire (entre -0.15 et +0.15 radians) pour un effet dynamique. Les coups critiques affichent le préfixe `"💥 CRIT "` avec un corps de texte agrandi à 36 (au lieu de 26) et suivent un effet d'échelle séquentiel élastique (pop initial à 1.5x via `Curves.elasticOut`, réduction à 1.15x via `Curves.easeOut`, puis pulsation infinie alternée entre 1.15x et 1.3x).
- **Double Jauge de Vie Animée et Décélération (v0.1.7)** : `PlayerHealthBar` utilise un `TweenAnimationBuilder` et un `AnimatedBuilder` pour animer les jauges d'avant-plan (jauge verte de PV instantanés) et d'arrière-plan (jauge rouge/orange de catch-up).
  - *Dégâts* : La jauge verte chute instantanément, tandis que la jauge rouge de catch-up descend avec une animation de décélération progressive ralentie à **1200ms** utilisant la courbe `Curves.easeOut`, permettant de mieux apprécier et ressentir la violence des coups subis.
  - *Soin* : La jauge rouge de catch-up s'aligne instantanément sur le nouveau niveau de PV, tandis que la jauge verte d'avant-plan augmente de façon animée en **500ms** pour donner un sentiment de régénération progressive et fluide.

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
| `freeze` | Debuff | Oui | Réduit les dégâts de la prochaine attaque de l'ennemi de **50%** (calculé dans l'intention affichée). Ne se dissipe plus en début de tour mais après la résolution de son action d'attaque. | Durée décrémentée après l'action d'attaque |
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

`GameDataService.loadAll()` charge les 8 fichiers JSON via `Future.wait()` (chargement parallèle).

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

---

## 9. Sprint de Consolidation Architecturale & Qualité Visuelle (v0.0.97 → v0.0.99)

Ce sprint tri-phase constitue un investissement majeur dans la **qualité technique** et la **maintenabilité à long terme** du projet, sans ajout de features gameplay. Chaque phase a été validée avec 104/104 tests au vert et 0 erreur `dart analyze`.

### 9.1. Option A — Modernisation Architecturale (v0.0.97)

**Impact produit** : Réduction de la dette technique critique. Les contrôleurs métier (8+) migrent de `StateNotifier` vers `Notifier`, ce qui supprime les constructeurs à injection massive et les risques de cycles de dépendances. `CardInstance` devient strictement immuable.

**Portée technique** :
- `RunController`, `CombatController`, `DeckNotifier`, `InventoryController`, `SkillController`, `EventController`, `ShopController`, `RewardController` → héritage de `Notifier<T>`.
- `CardInstance.forgeUpgrades` → `List<String>.unmodifiable` avec pattern `copyWith`.
- Logique `executeSkill` extraite de `HerosDraftGame` vers `CombatController`.

### 9.2. Option B — Performance & Animations (v0.0.98)

**Impact produit** : Fluidité et "game feel" améliorés, notamment sur mobile. Les animations de combat sont synchronisées à la frame d'impact réelle, et la pioche devient physiquement satisfaisante.

**Portée technique** :
- `FloatingText` & `EffectIcon` : suppression des `saveLayer` → peindre direct.
- `CardComponent` : caching `TextPainter`, `saveLayer` conditionnel (`opacity < 1.0`).
- `EnemyCard` : buffer `_pendingVisualInstance`, déclenchement sur `resolvePendingVisualStats()`.
- `CardAnimator` : suppression des branches de double-déclenchement.
- Spawn pioche à `Vector2(40, size.y - 40)` + Flame Effects chaînés.

### 9.3. Option C — Système de Design & Uniformisation UI (v0.0.99)

**Impact produit** : Cohérence visuelle garantie à l'échelle de toute l'application. Les couleurs de rareté, les espacements et la typographie sont maintenant gérés depuis une source de vérité unique. Un bug de layout `GameButton` est résolu.

**Portée technique** :
- Module `lib/ui/theme/` : `AppColors`, `AppSpacing`, `AppTheme`.
- Extensions `CardRarityColor` et `RelicRarityColor` sur les enums de rareté.
- Correction `GameButton` : `Flexible` + omission `Text` si null.
- `RelicsDialog` : `switch` de 19 lignes → `.color`.

### 9.4. Invariants de Qualité Post-Sprint

| Invariant | Valeur |
|:---|:---|
| Tests automatisés | 104/104 ✅ |
| Erreurs `dart analyze` | 0 ✅ |
| Pattern Riverpod | `Notifier<T>` (v2.x) pour tous les contrôleurs |
| Source de vérité couleurs | `AppColors` (aucune magic constant dans les widgets) |
| Immuabilité des modèles | `CardInstance` : tous attributs `final` + `List.unmodifiable` |

---

## 10. Sprint d'Amélioration de l'Interface & Cartes (UX Combat) (v0.1.00)

Ce sprint cible l'optimisation visuelle et tactile du combat pour élever le niveau d'immersion et de satisfaction sensorielle.

### 10.1. Impact Produit

- **Fluidité de Pioche** : Protection contre les clics ou glissements prématurés durant la pioche, garantissant un comportement sans à-coups ni instabilités physiques.
- **Transparence Tactique** : Présentation directe et contextualisée des améliorations (upgrades de forge) appliquées aux cartes en combat, permettant des choix informés.
- **Clarté Visuelle Rénovée** : Élimination du bruit visuel causé par les icônes de fond translucides et les tailles de police trop imposantes sur les cartes Flame et Flutter. Indication élégante du niveau d'upgrade de la carte via des badges d'étoiles.
- **Game Feel Premium (HUD)** : Transformation de la simple barre de vie statique du héros en une jauge double-niveau interactive et dynamique, améliorant le feedback émotionnel lors des dégâts reçus ou des soins appliqués.

### 10.2. Portée Technique

- **Verrouillage Tactile de Pioche** : Introduction d'un drapeau `isEnteringHand` dans `CardComponent` qui filtre les callbacks de survol, glissement et clic. La durée de distribution est portée à `0.7s` dans `_layoutHand` avant d'être réalignée à `0.35s` après complétion.
- **Exhibition Sélective des Tooltips** : Raccordement du cycle de vie des infobulles aux seuls événements de focus sur la carte en combat. Enrichissement de la description textuelle par une liste mise en forme des upgrades de forge actifs.
- **Rénovation Esthétique des Cartes** :
  - **Flame** : Retrait du dessin de fond dans `card_text_renderer.dart`, diminution des polices et dessin vectoriel d'étoiles dorées proportionnelles à `card.forgeUpgrades.length`.
  - **Flutter** : Retrait de l'icône centrale translucide et réduction des polices dans `ui_card.dart`. Rendu d'une rangée d'étoiles dorées sous le label de rareté avec ajustement des offsets.
- **Double Jauge de Vie Animée (HP Dual-Bar)** : Conversion de `PlayerHealthBar` en `StatefulWidget`. Câblage d'un `TweenAnimationBuilder` (500ms, `Curves.easeOutCubic`) animant la différence de ratio entre les PV actuels et les PV précédents sous forme d'une jauge secondaire rouge/orange qui glisse lentement en arrière-plan sous les dégâts. En cas de soin, la jauge verte augmente de suite de manière fluide et la barre rouge s'y aligne instantanément.
