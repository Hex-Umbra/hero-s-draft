# État des Lieux — Roster de Héros & Catalogue de Cartes

**Date** : 05/08/2026
**Contexte** : suite du cycle de brainstorms consacré aux ennemis (27-28/07, quatre documents dans ce dossier). Le chantier bascule maintenant sur les deux autres piliers de contenu du jeu : **les héros** et **les cartes**.
**Périmètre** : `heroes.json`, `passives.json`, `skills.json`, `hero_cards.json`, `cards.json`, `forge_upgrades.json`, **et l'intégralité du code qui les consomme**.
**Statut** : ⚠️ **État des lieux descriptif et diagnostique uniquement.** Aucune proposition de contenu nouveau, aucun équilibrage suggéré, aucune idée de design. Le brainstorm fera l'objet d'un document séparé, sur instructions.

---

## Méthode

Chaque champ de chaque fichier d'assets a été tracé jusqu'à son **point de consommation réel** dans `lib/`. La question posée n'était pas « qu'est-ce qui est déclaré ? » mais « qu'est-ce qui **arrive effectivement au joueur** ? ». Les deux réponses divergent plus souvent qu'attendu — c'est le principal résultat de cette passe.

Chaque constat cite le `fichier:ligne` qui l'établit, de sorte que la prochaine lecture puisse le réfuter en une commande. Les chantiers déjà inscrits à `docs/ROADMAP.md` sont **cités, pas re-litigés** : ce document ne rouvre aucun débat déjà tranché.

---

# PARTIE I — LE ROSTER DE HÉROS

## 1. Ce qui est déclaré

`assets/data/heroes.json` — 3 entrées, 12 champs chacune.

| Champ | Paladin | Berserker | Mage |
|:---|:---|:---|:---|
| `id` | `paladin` | `berserker` | `mage` |
| `name_fr` | Le Paladin | Le Berserker | Le Mage |
| `description_fr` | Orienté Survie | Orienté Dégâts | Orienté Altération |
| `iconPath` | `hero_paladin.png` | `hero_berserker.png` | `hero_mage.png` |
| `maxHp` | **100** | **80** | **60** |
| `maxMana` | 3 | 3 | 3 |
| `baseDamage` | 5 | 15 | 10 |
| `luck` | 0 | 0 | 0 |
| `armorMastery` | *(absent)* | *(absent)* | *(absent)* |
| `passiveTrait` | `regenArmor` | `berserkerArmor` | `spellArmor` |
| `skills` | `holy_shield`, `smite` | `reckless_strike`, `rage_form` | `magic_missile`, `mana_surge` |

## 2. Ce qui est réellement utilisé

Traçage champ par champ jusqu'au point de consommation.

| Champ | Consommé où | Effet réel en jeu |
|:---|:---|:---|
| `id` | `run_controller.dart:239`, écrans | ✅ Identité de run, couleur de thème du draft |
| `name_*` / `description_*` | `ClassSelectionScreen` | ✅ Affichage seul |
| `iconPath` | `ClassSelectionScreen`, HUD | ✅ Rendu |
| `maxHp` | `run_controller.dart:243` | ✅ `EntityStats.maxPv` |
| `maxMana` | `run_controller.dart:244-245` | ✅ `EntityStats.maxMana` — **identique aux 3 classes** |
| `baseDamage` | `class_selection_screen.dart:342` | ⛔ **Affichage uniquement.** La run démarre à `attaque: 0` (`run_controller.dart:250`) |
| `luck` | `run_controller.dart:252` | ⚠️ Câblé, mais **vaut 0 pour les 3 classes** |
| `armorMastery` | `run_controller.dart:249` | ⚠️ Câblé, mais **absent du JSON → 0 pour les 3 classes** |
| `passiveTrait` | `TraitSystem` | ✅ Seul vrai différenciateur mécanique |
| `skills` | `HeroSkillsLink.getHeroCards()` | ✅ …mais **ne pointe pas vers `skills.json`** (§4) |

### 2.1. Le stat « Attaque » de l'écran de sélection est décoratif

`class_selection_screen.dart:342` affiche `playerClass.baseDamage` — soit 5 / 15 / 10. Mais `startNewRun()` construit les `EntityStats` avec `attaque: 0` et le commentaire explicite `// Force de base à 0` (`run_controller.dart:250`). Le seul autre point de lecture de `baseDamage` dans tout `lib/` concerne les **ennemis** (`EnemyData.baseDamage`), jamais le héros.

**Conséquence** : un joueur qui choisit le Berserker « parce qu'il tape à 15 » commence exactement au même niveau de dégâts que le Mage et le Paladin. Toute la puissance offensive vient des cartes ; `attaque` ne monte ensuite que via la récompense de level-up *Affûtage* et les reliques `gain_strength`.

C'est d'autant plus structurant que `effectiveAttaque` est **ajouté à chaque effet `damage`**, et **par cible** pour les cartes AoE (`strategies.dart:29` et `:42`). C'est donc un multiplicateur global du deck, pas une stat de classe.

### 2.2. Différenciation réelle entre les trois classes

Ne subsistent, une fois le traçage fait, que **trois** différences :

| Axe | Différencié ? |
|:---|:---|
| PV max | ✅ 100 / 80 / 60 |
| Passif | ✅ 3 passifs distincts |
| 2 cartes de classe | ✅ 2 cartes chacun |
| Mana max | ❌ 3 partout |
| Attaque de départ | ❌ 0 partout (affiché 5/15/10) |
| Luck | ❌ 0 partout |
| Maîtrise d'armure | ❌ 0 partout (champ absent) |
| Compétences héroïques | ❌ système inatteignable (§4) |
| Deck de départ | ❌ **5 cartes libres parmi les 17 mêmes cartes globales** |
| Récompenses de level-up | ❌ 8 types, aucun conditionné à la classe |
| Reliques | ❌ 24 reliques, aucune conditionnée à la classe |

Le deck de départ mérite d'être souligné : `StarterDeckDraftScreen` affiche **l'intégralité des cartes globales** sans aucun filtre de classe (`starter_deck_draft_screen.dart:51-55`), et le joueur en choisit 5 librement. Un Paladin et un Mage peuvent donc démarrer avec **exactement le même deck à 5 cartes sur 7**.

## 3. Les passifs

`assets/data/passives.json` — 3 entrées, résolues par `TraitSystem` (`lib/game/systems/trait_system.dart`).

| ID | Classe | Trigger | Mécanisme réel |
|:---|:---|:---|:---|
| `regenArmor` | Paladin | `endOfTurn` | `+2 + effectiveArmorMastery` armure à chaque fin de tour |
| `berserkerArmor` | Berserker | `startOfTurn` | `(PV manquants ÷ 10) × 1 + effectiveArmorMastery` armure, **si > 0** |
| `spellArmor` | Mage | `onCardPlayed` | `+1 + effectiveArmorMastery` armure, **uniquement si `card.type == skill`** |

Trois observations factuelles :

1. **Les trois passifs produisent de l'armure.** Aucun autre axe (dégâts, pioche, mana, statut, soin) n'est couvert. `PassiveData.effectType` n'accepte d'ailleurs que 4 valeurs, dont `'none'` en repli (`passive_data.dart:116`).
2. **`berserkerArmor` ne se déclenche pas à pleine vie** : `armorGain > 0` est requis (`trait_system.dart:23`). Le Berserker commence donc chaque combat sans son passif, et le récupère à mesure qu'il encaisse.
3. **`spellArmor` dépend du type de carte joué.** Or le catalogue global ne compte que **6 cartes de type `skill` sur 17**, et le Mage n'en a qu'une sur ses deux cartes de classe (`mana_surge`). Son passif est donc conditionné à une portion minoritaire du pool — et rien dans le draft de départ ne l'oriente vers elle.

`effectiveArmorMastery` amplifie les trois passifs, mais vaut 0 au départ pour tout le monde et ne monte que par la récompense de level-up *Forge d'Acier* et la relique `kunai`.

## 4. `skills.json` — un système entier inatteignable

C'est le constat le plus lourd de cette partie.

### 4.1. La chaîne est rompue

```
skills.json (6 entrées)
  └─> game_data_service.dart:82  →  GameDataRegistry.skills
        └─> ??? …aucun consommateur
```

`HerosDraftGame.executeSkill()` existe (`heros_draft_game.dart:319-361`), `CombatController.executeSkill()` existe (`combat_controller.dart:209-271`), `game_screen.dart:378` câble bien le callback `onExecuteSkill`. **Mais rien n'appelle jamais `_game.executeSkill(...)`.** Vérifié par recherche exhaustive : les paramètres obligatoires `onTriggerAttackBuff` et `onTriggerLifesteal` n'ont **aucun site d'appel** dans tout le dépôt, et `lib/ui/` ne contient **aucun bouton de compétence**.

`SkillController` est vivant mais ne fait qu'égrener des cooldowns que rien ne pose : `tickCooldowns()` (`run_controller.dart:410`), `resetCooldowns()` (`run_controller.dart:266`, `map_progression_manager.dart:71`), plus la sérialisation dans `SaveService`. `triggerSkill1()` / `triggerSkill2()` ne sont appelés que par leurs propres tests unitaires.

### 4.2. Même branché, le système ne fonctionnerait pas

`CombatController.executeSkill()` traite `effectValue` comme un **pourcentage de l'attaque du héros** :

```dart
initialDamage: (effectiveAttaque * (skill.effectValue / 100.0)).round()   // combat_controller.dart:217, 231
```

Or `effectiveAttaque` vaut **0** au démarrage d'une run (§2.1). `mage_nova` (20), `mage_strike` (150) et `berserker_pierce` infligeraient donc **0 dégât**. Seul `armor_buff` utilise la valeur brute (`combat_controller.dart:272`), et `attack_buff` / `lifesteal_buff` sont délégués à des callbacks qui n'existent pas.

### 4.3. Le modèle viole une règle explicite du projet

`SkillData` n'expose qu'un `final String name` monolingue français (`skill_data.dart:3`), alors que `CLAUDE.md` impose `_fr` / `_en` sur toute entrée à texte visible. Déjà inscrit à la roadmap — **P-26**, Tier D.

### 4.4. La fiche de règles décrit un système qui n'existe pas

`.obsidian_vault/_rules/05-00-competences-heroiques.md` documente des cooldowns, des durées (« buff force 15% maxPv, durée 2 », « lifesteal durée 3 ») et des sémantiques absentes du code lu. Cette fiche décrit un état antérieur du jeu.

### 4.5. Collision de nommage `skills`

Le champ `"skills"` de `heroes.json` contient `["holy_shield", "smite"]` — des **identifiants de cartes** de `hero_cards.json`, résolus par `HeroSkillsLink.getHeroCards()` (`hero_skills_link.dart:6-14`). Il n'a **aucun rapport** avec les identifiants de `skills.json` (`paladin_shield`, `paladin_rage`…).

Deux concepts distincts portent le même nom dans le même fichier. C'est ce qui explique que la fiche `_rules/02-2-systeme-de-heros.md` attribue au Paladin les compétences `paladin_shield` / `paladin_rage` — un croisement erroné des deux systèmes.

## 5. Progression du héros

| Élément | Valeur | Source |
|:---|:---|:---|
| Courbe d'XP | `100 × 1.5^(niveau-1)`, report de l'excédent | `player_stats_manager.dart:72` |
| Déclenchement | Gain de niveau → `pendingDrafts++`, overlay bloquant sur la carte | `player_stats_manager.dart:86` |
| Choix offerts | **3** tirages de rareté (+ jusqu'à **2** options mythiques) | `level_up_reward_service.dart:109-239` |
| Types de récompense | 8 (`LevelUpRewardType`) | `level_up_reward_service.dart:8-17` |

Les 8 récompenses : **Vitalité** (+PV max), **Affûtage** (+attaque), **Forge d'Acier** (+maîtrise d'armure), **Sagesse** (+mana max), **Précision** (+% crit), **Férocité** (+dégâts crit), **Trèfle Porte-Bonheur** (+luck, mythique), **Miroir** (clonage de carte, mythique).

**Aucune des 8 n'est conditionnée à la classe.** Un Mage à 60 PV et un Paladin à 100 PV se voient proposer la même table, aux mêmes probabilités.

Note : `rng.nextInt(6)` (`level_up_reward_service.dart:129`) ne tire que parmi les 6 récompenses standard ; les deux mythiques passent par un second jet indépendant. La montée de mana disponible jusqu'en légendaire est déjà signalée comme un problème d'équilibrage — **P-16**, Tier C.

## 6. Ce qui n'existe pas, côté héros

- Aucune **4ᵉ classe**, aucun système de déblocage, aucune méta-progression (**P-13**).
- Aucun **choix de passif** : `ClassSelectionScreen` transmet le passif imposé de la classe (`class_selection_screen.dart:150-152, 444`).
- Aucun **passif évolutif** en cours de run.
- Aucune **relique ni carte conditionnée à la classe** au-delà des 2 cartes de départ.
- Aucun **scaling de `mastery` par classe** (**P-20**).
- Aucun **skin** (**P-39**).
- Aucune **stat de classe différenciée** hors PV (cf. §2.2).

---

# PARTIE II — LE CATALOGUE DE CARTES

## 1. Volumétrie réelle

> **23 cartes** : **17 globales** (`cards.json`) + **6 de classe** (`hero_cards.json`).

Les deux fichiers sont concaténés au chargement (`game_data_service.dart:74-77`), si bien que `GameDataRegistry.cards` en contient 23 — c'est ce que le Dictionnaire affiche, cartes des 3 classes comprises.

⚠️ La fiche `_rules/02-3-catalogue-de-cartes.md` annonce **21 cartes dont 15 globales**. Ce chiffre est **périmé** ; `_memory_bank/progress.md:74` porte le bon (23 = 17 + 6). Voir le tableau de dérives en Partie III.

## 2. Schéma d'une carte (`CardData`)

| Champ | Type | Remarque |
|:---|:---|:---|
| `id`, `name_fr/en`, `description_fr/en` | `String` | Bilingue conforme sur les 23 |
| `cost` | `int` | **0 à 2 en pratique** — voir §5 |
| `type` | `attack` \| `skill` \| `power` \| `status` | `status` : **0 carte** |
| `category` | `global` \| `characterSpecific` | 17 / 6 |
| `heroClass` | `String?` | `null` sur les globales |
| `rarity` | `common`…`legendary` \| `unique` | **17 globales toutes `common`** |
| `target` | `singleEnemy` \| `allEnemies` \| `self` \| `none` | `none` : **0 carte** |
| `animation` | `String?` | 7 valeurs utilisées |
| `isExhaust` | `bool` | 4 cartes sur 23 |
| `effects` | `List<CardEffect>` | 1 ou 2 effets par carte, jamais plus |
| `baseMaxForgeUpgrades` | `int` (défaut **1**) | **Absent des 17 globales** → toutes à 1. Voir §7.3 |
| `spritePath` | `String?` | **Jamais renseigné** — rendu 100 % procédural |

## 3. Les 17 cartes globales

| ID | Nom FR | Coût | Type | Cible | Épuise | Effets |
|:---|:---|:---:|:---|:---|:---:|:---|
| `strike_basic` | Frappe | 1 | attack | 1 ennemi | — | 6 dégâts |
| `defend_basic` | Défense | 1 | skill | soi | — | 5 armure |
| `quick_attack` | Attaque Rapide | 1 | attack | 1 ennemi | — | 3 dégâts + 1 pioche |
| `sweep` | Balayage | 1 | attack | tous | — | 3 dégâts |
| `concentration` | Concentration | 0 | skill | soi | ✅ | 2 pioches |
| `heal_potion` | Potion de Soin | 1 | skill | soi | ✅ | 3 soins |
| `iron_wall` | Mur de Fer | 2 | skill | soi | — | 10 armure |
| `heavy_strike` | Frappe Lourde | 2 | attack | 1 ennemi | — | 12 dégâts |
| `awakening` | Éveil | 1 | skill | soi | — | 4 armure + 1 pioche |
| `warcry` | Cri de Guerre | 2 | attack | tous | — | 4 dégâts + 4 armure |
| `demon_form` | Forme Démoniaque | 2 | power | soi | *(auto)* | Force 2 / 4 tours |
| `metallicize` | Métallisation | 1 | power | soi | *(auto)* | Régén. armure 2 / 2 tours |
| `poison_stab` | Coup Empoisonné | 1 | attack | 1 ennemi | — | 3 dégâts + Poison 1 / 2t |
| `fireball` | Boule de Feu | 2 | attack | 1 ennemi | — | 6 dégâts + Brûlure 2 / 2t |
| `ice_bolt` | Trait de Glace | 1 | attack | 1 ennemi | — | 4 dégâts + Gel 1 / 1t |
| `thunder_clap` | Coup de Tonnerre | 1 | attack | 1 ennemi | — | 4 dégâts + Électro. 1 / 1t |
| `focus` | Focalisation | 0 | skill | soi | ✅ | +1 mana |

*Les cartes de type `power` partent systématiquement à l'épuisement, quel que soit `isExhaust` (`deck_controller.dart:190`).*

## 4. Les 6 cartes de classe

| ID | Nom FR | Classe | Coût | Type | Épuise | Effets |
|:---|:---|:---|:---:|:---|:---:|:---|
| `holy_shield` | Bouclier Sacré | Paladin | 1 | skill | ✅ | 8 armure + 2 soins |
| `smite` | Châtiment | Paladin | 1 | attack | — | 6 dégâts + 4 armure |
| `reckless_strike` | Frappe Téméraire | Berserker | 2 | attack | — | 15 dégâts |
| `rage_form` | Posture de Rage | Berserker | 1 | skill | — | Force 2 / **1 tour** + 1 pioche |
| `magic_missile` | Projectile Magique | Mage | 1 | attack | — | 5 dégâts + 1 pioche |
| `mana_surge` | Surtension de Mana | Mage | 0 | skill | ✅ | +1 mana + 1 pioche |

Toutes en rareté `unique` (multiplicateur **1,0**, donc **jamais scalées**), toutes à `baseMaxForgeUpgrades: 5`.

Deux observations :
- Le Paladin est le seul dont **la carte défensive de classe s'épuise** — `holy_shield` est un one-shot par combat, là où `smite` (armure + dégâts) est rejouable.
- `rage_form` applique Force pour **1 seul tour** contre 4 pour `demon_form` (carte globale, accessible à tous). La carte de classe du Berserker est donc mécaniquement inférieure à une commune sur son propre axe, compensée par la pioche et le coût moindre.

## 5. Distribution et couverture

| Axe | Répartition | Trou identifié |
|:---|:---|:---|
| **Type** (globales) | 9 attack · 6 skill · 2 power | `status` : **0 carte** |
| **Type** (classe) | 3 attack · 3 skill | `power` : **0 carte de classe** |
| **Coût** (globales) | 0×2 · 1×10 · 2×5 | **Aucune carte à 3 mana**, alors que la fiche de règles annonce « 0-3 » |
| **Cible** (globales) | 8 soi · 7 mono · **2 AoE** | `none` : **0 carte** |
| **Rareté** (globales) | 17 × `common` | Aucune carte n'existe nativement au-dessus de commune |
| **Nombre d'effets** | 1 ou 2 | **Aucune carte à 3 effets ou plus** |
| **Animations** | 8 buff · 3 melee · 2 magic · 1 poison/fire/ice/lightning | — |

### 5.1. Les types d'effet

Six types sont enregistrés dans `EffectRegistry` et **les six sont utilisés** :

| Type | Occurrences | Stratégie |
|:---|:---:|:---|
| `damage` | 12 | `DamageEffectStrategy` — ajoute `effectiveAttaque`, passe par `DamagePipeline` (crit) |
| `apply_status` | 7 | `ApplyStatusEffectStrategy` |
| `armor` | 6 | `ArmorEffectStrategy` |
| `draw` | 6 | `DrawEffectStrategy` |
| `heal` | 2 | `HealEffectStrategy` — **peut critiquer** (`strategies.dart:69`) |
| `gain_mana` | 2 | `GainManaEffectStrategy` |

### 5.2. Les statuts atteignables par une carte

Sur les **9 statuts pleinement implémentés** dans le moteur :

| Statut | Source existante |
|:---|:---|
| `poison` | ✅ `poison_stab` — **seule source du jeu**, aucune rune ne l'applique |
| `burn` | ✅ `fireball` + rune `burning` |
| `freeze` | ✅ `ice_bolt` + rune `freezing` |
| `shock` | ✅ `thunder_clap` + rune `shocking` |
| `strength` | ✅ `demon_form`, `rage_form` + intent ennemi `buff` |
| `armor_regen` | ✅ `metallicize` |
| **`vulnerable`** | ⛔ **aucune** |
| **`weakness`** | ⛔ **aucune** |
| **`strength_regen`** | ⛔ **aucune** |

`vulnerable` (+50 % de dégâts subis), `weakness` (−25 % de dégâts infligés) et `strength_regen` sont **entièrement implémentés** — calcul de dégâts, tick, icône, couleur, panneau de statuts, rendu Flame et Flutter — mais **rien dans le jeu ne les applique** : aucune carte, aucune rune, aucune relique (les 24 se limitent à `gain_armor`/`gain_mana`/`heal`/`gain_crit`/`gain_strength`/`gain_luck`/`charge_*`), aucun passif, et aucune intention ennemie (`IntentType` ne produit que dégâts, armure et `strength` — `turn_phase_manager.dart:62-112`).

C'est **un tiers du système de statuts qui est construit, testé, rendu… et inaccessible au joueur.**

## 6. Rareté et scaling

Les raretés s'obtiennent **en jeu**, pas en données : fusion 3→1, tirage en boutique, ou `upgradeCard()`.

| Rareté | Multiplicateur | Slots de forge (carte globale) |
|:---|:---:|:---:|
| `common` | 1,0 | 1 |
| `uncommon` | 1,2 | 2 |
| `rare` | 1,4 | 3 |
| `epic` | 1,6 | 4 |
| `legendary` | 2,0 | 5 |
| `unique` | **1,0** | **10** *(cf. §7.3)* |

Le multiplicateur s'applique à **tous** les effets, pas seulement dégâts et armure : `scaledValue = (baseValue × rarityMultiplier).round()` (`effect_resolver.dart:216`). Donc `draw`, `heal`, `gain_mana` et la **valeur** des statuts scalent aussi ; leur `duration`, non.

### 6.1. Collisions d'arrondi

`round()` sur de petites valeurs de base produit des paliers de rareté **strictement identiques** :

| Carte | Base | Commune | Peu Com. | Rare | Épique | Légendaire |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|
| `quick_attack` / `sweep` / `poison_stab` | 3 | 3 | **4** | **4** | 5 | 6 |
| `ice_bolt` / `thunder_clap` / `awakening` | 4 | 4 | 5 | **6** | **6** | 8 |
| `warcry` (dégâts et armure) | 4 | 4/4 | 5/5 | **6/6** | **6/6** | 8/8 |

Sur 7 des 12 cartes scalables, **une montée de rareté sur deux ne change rien** — alors qu'elle coûte 3 exemplaires de la carte, ou un achat en boutique plus cher.

Effet symétrique sur les effets non numériques : `draw 1` reste à 1 jusqu'en épique (`round(1,4) = 1`), et `focus` (+1 mana, coût 0, épuise) devient **+2 mana** dès l'épique — une carte qui rend deux fois son coût.

## 7. La forge (8 runes)

`assets/data/forge_upgrades.json` — 8 runes, pilotées par pools de rareté et par type de carte.

| Rune | Effet réel (`effect_resolver.dart:139-161`) | Pools | Types éligibles |
|:---|:---|:---|:---|
| `sharp` | +2 × tier dégâts | common, uncommon, rare | attack |
| `hardened` | +2 × tier armure | common, uncommon, rare | attack, skill |
| `burning` | Brûlure valeur=durée=tier | common, uncommon, rare | attack |
| `freezing` | Gel valeur=durée=tier | common, uncommon, rare | attack |
| `shocking` | Électrocution valeur=durée=tier | common, uncommon, rare | attack |
| `quick` | +tier pioches | uncommon, rare | attack, skill, power |
| `eco` | +tier mana | rare | attack, skill, power |
| `enduring` | Retire l'Épuisement | rare | attack, skill, power *(requiert `isExhaust`)* |

### 7.1. Les statuts élémentaires de rune ne s'appliquent qu'aux attaques

`effect_resolver.dart:173` conditionne l'application de `burning`/`freezing`/`shocking` à `card.data.type == CardType.attack`. Le filtrage par `eligibleCardTypes` le garantit déjà côté tirage : la double barrière est cohérente.

### 7.2. `hardened` sur une carte sans effet `armor`

`effect_resolver.dart:237-241` : si la carte n'a aucun effet `armor`, l'`extraArmor` est appliqué séparément en fin de résolution. Une `strike_basic` runée `hardened` gagne donc bien son armure. Comportement correct et non évident — documenté par ADR-047.

### 7.3. Asymétrie de capacité : 1 slot contre 10

La capacité vaut `baseMaxForgeUpgrades + rarity.index` — formule répétée en 6 points (`forge_upgrade_dialog.dart:52`, `rest_card_selection_screen.dart:30`, `deck_screen.dart:222`, `deck_controller.dart:250`, `shop_controller.dart:205`, `card_rune_sockets.dart:19`).

Or `CardRarity.unique` est **le dernier membre de l'enum**, donc `index = 5`. Les cartes de classe (`baseMaxForgeUpgrades: 5`) obtiennent :

```
5 + 5 = 10 emplacements de rune
```

contre **1** pour une carte globale commune, et **5** pour une légendaire. Une carte de classe peut donc porter **deux fois plus de runes que la meilleure carte globale possible** — tout en étant non-fusionnable et donc figée en rareté.

⚠️ La fiche `_rules/03-8-systeme-de-forge-forge-de-fusion.md:8` affirme : « Les cartes uniques de classe ont une limite fixe de **5** améliorations. » **Le code en donne 10.** Écart code/documentation à trancher : soit l'intention est 5 et c'est un bug, soit l'intention est 10 et la fiche est fausse.

## 8. Cycle de vie d'une carte

### 8.1. Entrées dans le Master Deck

| Voie | Volume | Détail |
|:---|:---|:---|
| Draft de départ | **7** | 5 globales libres parmi 17 + 2 de classe automatiques |
| Boutique — achat | 3 + bonus | Rareté et runes tirées **selon l'acte** (`shop_controller.dart:160-235`) |
| Boutique — Miroir Magique | 1 par achat | Clone d'une carte **du deck**, prix ×2 à chaque fois |
| Boss `BossRewardType.cards` | **2** | Choisies parmi **5 tirées du deck du joueur** |
| Boss `BossRewardType.doubleXp` | 1 | Carte aléatoire du catalogue, ajoutée d'office |
| Level-up « Miroir » (mythique) | 1 | Ouvre la modale de clonage |

**Il n'existe aucune récompense de carte après un combat normal.** `RewardController.handleVictory()` ne tire des cartes que sur un nœud boss (`reward_controller.dart:170-195`). Le `DraftScreen` post-victoire distribue des **stats**, pas des cartes.

### 8.2. Transformations

| Opération | Où | Règle |
|:---|:---|:---|
| Fusion 3→1 | `DeckNotifier.mergeCards()` | 3 copies même ID + même rareté → 1 rareté supérieure ; `unique` interdit |
| Rune de forge | Feu de camp / `ForgeUpgradeDialog` | 1-5 slots probabilistes, reroll à coût exponentiel |
| Fusion de runes | `ForgeFusionScreen` | Runes de même ID sur une carte → tiers additionnés, `80 × (N-1)` or |
| Montée de rareté directe | `DeckNotifier.upgradeCard()` | Existe, aucun appelant en jeu |

### 8.3. Sorties

| Voie | Où |
|:---|:---|
| Oubli au feu de camp | `RestScreen._removeCard()` |
| Purge en boutique | `ShopController.purgeCard()` |
| Consommée par une fusion 3→1 | `mergeCards()` |

**Aucune limite de taille de deck** n'est appliquée nulle part (chantier **P-18**, Tier C).

## 9. Ce qui n'existe pas, côté cartes

Trous de couverture constatés, sans jugement de valeur :

- **Aucune carte ne produit de carte** (ni génération, ni copie, ni transformation en main).
- **Aucune carte n'agit sur les piles** : ni défausse volontaire, ni récupération depuis la défausse, ni fouille de la pioche, ni épuisement ciblé.
- **Aucun effet conditionnel ou variable** : pas de coût X, pas de « si… alors », pas de scaling sur un état (PV manquants, cartes en main, statuts posés).
- **Aucune carte multi-coups** (le champ `value` est appliqué une fois par cible).
- **Aucun coût alternatif** : rien ne se paie en PV, en or ou en défausse.
- **Aucune carte n'applique `vulnerable`, `weakness` ou `strength_regen`** (§5.2).
- **Aucune carte de type `status`** — donc aucune malédiction, blessure ou carte parasite. `EffectResolver.canPlayCard()` bloque déjà leur jeu (`effect_resolver.dart:101`), et `DeckNotifier.addCardToDiscardPile()` existe pour les injecter : l'infrastructure est prête, le contenu absent.
- **Aucune carte à 3 mana**, aucune attaque à 0 mana, aucune carte à 3 effets.
- **Aucune carte de classe de type `power`.**
- **Aucune carte ne cible `none`.**

---

# PARTIE III — DIAGNOSTIC

## A. Contenu construit mais inatteignable

Classé par ampleur.

| # | Élément | Nature | Preuve |
|:---:|:---|:---|:---|
| 1 | **Système de compétences héroïques complet** (`skills.json`, `SkillController`, `executeSkill` ×2, `SkillState` persisté) | 6 contenus + ~150 lignes de logique, **zéro point d'entrée UI** | §I.4 |
| 2 | **Statuts `vulnerable`, `weakness`, `strength_regen`** | 3 statuts sur 9, implémentés et rendus, **sans aucune source** | §II.5.2 |
| 3 | `RelicTrigger.onSkillPlayed` / `onPowerPlayed` | Dispatchés (`combat_controller.dart:302-304`), **0 relique sur 24 ne les utilise** | `relics.json` |
| 4 | `CardType.status` | Enum + blocage de jeu + injection en défausse prêts, **0 carte** | §II.9 |
| 5 | `DeckNotifier.upgradeCard()` | Méthode publique **sans appelant** en jeu | `deck_controller.dart:276` |
| 6 | `CardInstance.temporaryCost` | Champ sérialisé, **jamais écrit** | Déjà cité par **P-02** |
| 7 | Deck de secours codé en dur | 5 cartes en dur dans `game_screen.dart:229-245` | Déjà cité par **P-02** |

## B. Défauts confirmés

### B1. La rune `enduring` se casse dès qu'elle atteint le tier 2

`deck_controller.dart:188` teste l'épuisement ainsi :

```dart
final isExhausted = cardToPlay.data.isExhaust && !cardToPlay.forgeUpgrades.contains('enduring:1');
```

La chaîne `'enduring:1'` est **codée en dur**. Or deux chemins produisent un tier supérieur :

1. **`ForgeFusionScreen`** ne filtre **pas** `enduring` : `_getFusionsForCard()` (`forge_fusion_screen.dart:40-65`) groupe toutes les runes par ID et additionne les tiers sans exception. Fusionner deux `enduring:1` donne `enduring:2`.
2. **`DeckNotifier.mergeCards()`** consolide de même (`deck_controller.dart:237-247`) : trois cartes portant chacune `enduring:1` produisent `enduring:3`.

Dans les deux cas, la carte **redevient silencieusement épuisable** alors que le joueur a payé pour l'inverse. Aucun message, aucun garde-fou.

⚠️ La fiche `_rules/03-8-…:43` affirme que « les runes de type `enduring` … sont exclues de la fusion ». **Cette exclusion n'existe pas dans le code lu.**

### B2. Les cartes de classe peuvent être dupliquées

`ADR-051` a exclu la rareté `unique` du draft post-boss, et le filtre existe toujours — mais **sur l'autre branche** : il ne s'applique qu'à la carte bonus de `BossRewardType.doubleXp` (`reward_controller.dart:190`).

La branche `BossRewardType.cards` tire aujourd'hui ses 5 candidates **depuis le deck du joueur** (`reward_controller.dart:171-184`), lequel contient toujours ses 2 cartes de classe `unique`. Le `ShopController` (Miroir Magique) et la récompense « Miroir » de level-up clonent également depuis le deck sans filtre.

L'ADR-051 est donc **partiellement invalidé par une évolution ultérieure**. Le point est déjà signalé comme bug dans `ROADMAP.md:255` ; ce document en identifie la **cause exacte** (changement de pool source, pas suppression du filtre) et les **deux voies supplémentaires** (Miroir de boutique, Miroir de level-up).

### B3. Un palier de rareté sur deux est nul sur 7 cartes

Cf. §II.6.1. Purement mécanique (arrondi), mais visible par le joueur : il paie une fusion et ne voit aucun changement de chiffre.

### B4. Écart de capacité de forge 1 ↔ 10

Cf. §II.7.3. Le code contredit la fiche de règles ; à trancher.

## C. Dérives documentaires

Constats faits en croisant les fiches du vault avec le code. **Ne pas se fier aux entrées de gauche avant correction.**

| # | Affirmation | Source | Réalité vérifiée |
|:---:|:---|:---|:---|
| 1 | « **21 cartes**, dont **15 globales** » | `_rules/02-3:3-4` | **23** dont **17** globales |
| 2 | « `heal_potion` : Coût 1, **Soin 4** » | `_rules/02-3:13` | Soin **3** (`cards.json`) |
| 3 | « Cartes uniques : limite fixe de **5** améliorations » | `_rules/03-8:8` | **10** (`5 + index(unique)=5`) |
| 4 | « Les runes `enduring` sont **exclues de la fusion** » | `_rules/03-8:43` | Aucune exclusion dans `forge_fusion_screen.dart` |
| 5 | Compétences du Paladin = `paladin_shield` / `paladin_rage` | `_rules/02-2:7` | Croisement erroné : `heroes.json.skills` pointe vers des **cartes** |
| 6 | Table des compétences (cooldowns, « 15 % maxPv », « durée 2/3 ») | `_rules/05-00` | Décrit un système antérieur ; le code actuel est de surcroît inatteignable |
| 7 | « Coût des cartes : **0 à 3** cristaux » | `_rules/03-1:6` | **0 à 2** en pratique — aucune carte à 3 |
| 8 | « `Attaque Rapide` gratuite (**0 mana**) » | `ROADMAP.md:183` (héritée de `6_analyse_game_balance.md`) | **Coût 1** dans `cards.json` |
| 9 | « Paladin quasi invulnérable (**20 armure de base**) » | `ROADMAP.md:183`, même héritage | Aucune armure de base dans `heroes.json` ; passif à +2/tour |
| 10 | « Le pool de drafts de boss reste sain, **15 cartes globales neutres uniquement** » | `ADR-051:24` | Le pool est désormais **le deck du joueur** (cf. B2) |

Les points 8 et 9 concernent des fiches d'équilibrage **héritées sans re-mesure** dans la roadmap — exactement le motif que `ROADMAP.md:319` documente pour le Tier D. Le Tier C n'a pas encore subi ce contrôle ; ces deux entrées le confirment.

## D. Tensions de design observées

Constats structurels, formulés sans proposition.

1. **Les trois classes convergent.** Hors PV max et passif, tout est commun : même mana, même attaque de départ (0), même luck, même maîtrise, mêmes récompenses de level-up, mêmes reliques, et **5 des 7 cartes de départ tirées du même pool de 17 communes**. La promesse « Survie / Dégâts / Altération » de `heroes.json` n'a pas de support mécanique — d'autant que la classe *Altération* ne dispose d'aucune carte de classe posant un statut.

2. **Le deck ne grossit presque pas.** Sans récompense de carte en combat normal, l'acquisition passe par la boutique, deux boss sur trois et deux miroirs. La progression de run est donc majoritairement une progression **de stats et de runes**, pas de deck — ce qui déplace le centre de gravité du deckbuilder vers l'ARPG.

3. **Le pool de 17 communes est le plafond de variété.** Toute rareté supérieure est une **version numériquement enflée d'une de ces 17 cartes**, jamais une carte différente. Fusionner, acheter et forger amplifient ; rien n'élargit.

4. **Le moteur d'effets est en avance sur le contenu.** 6 stratégies d'effet, 9 statuts, 8 runes, 4 types de carte, 4 cibles, 9 triggers de relique — et le contenu n'exploite ni `status`, ni la cible `none`, ni 3 statuts sur 9, ni 2 triggers sur 9, ni le coût 3. Le catalogue est le facteur limitant, pas l'architecture.

5. **Les deux systèmes « héroïques » sont désynchronisés.** `hero_cards.json` (vivant, 6 cartes, bilingue, forgeable) et `skills.json` (mort, 6 entrées, monolingue, inatteignable) décrivent tous deux « ce que la classe sait faire », sous deux modèles incompatibles et avec un champ homonyme (`skills`) qui pointe vers le premier.

---

# ANNEXE — Index des points de vérification

Pour re-mesurer chaque constat en une lecture.

| Sujet | Fichier:ligne |
|:---|:---|
| Attaque de départ à 0 | `lib/game/controllers/run_controller.dart:250` |
| `baseDamage` affiché seul | `lib/ui/screens/class_selection_screen.dart:342` |
| Passifs | `lib/game/systems/trait_system.dart:10-70` |
| `skills` → cartes (pas `skills.json`) | `lib/models/data/hero_skills_link.dart:6-14` |
| `executeSkill` sans appelant | `lib/game/heros_draft_game.dart:319` · `lib/ui/screens/game_screen.dart:378` |
| Compétences en % d'attaque | `lib/game/controllers/combat_controller.dart:217, 231` |
| `SkillData` monolingue | `lib/models/data/skill_data.dart:3` |
| Fusion des deux catalogues | `lib/services/game_data_service.dart:74-77` |
| Multiplicateurs de rareté | `lib/models/card_instance.dart:25-40` |
| Scaling appliqué à **tous** les effets | `lib/game/services/effect_resolver.dart:216` |
| Runes de forge → effets | `lib/game/services/effect_resolver.dart:139-161` |
| Statuts élémentaires réservés aux attaques | `lib/game/services/effect_resolver.dart:173` |
| Capacité de forge | `lib/ui/widgets/forge_upgrade_dialog.dart:52` (+5 autres sites) |
| `enduring:1` codé en dur | `lib/game/controllers/deck_controller.dart:188` |
| Fusion de runes sans exclusion | `lib/ui/screens/forge_fusion_screen.dart:40-65` |
| Consolidation des runes en fusion 3→1 | `lib/game/controllers/deck_controller.dart:237-247` |
| Draft post-boss tiré du deck | `lib/game/controllers/reward_controller.dart:171-184` |
| Filtre `unique` sur la seule carte bonus | `lib/game/controllers/reward_controller.dart:190` |
| Draft de départ sans filtre de classe | `lib/ui/screens/starter_deck_draft_screen.dart:51-55` |
| Récompenses de level-up | `lib/game/services/level_up_reward_service.dart:103-242` |
| Courbe d'XP | `lib/game/controllers/run/player_stats_manager.dart:72` |
| Statuts appliqués par les ennemis | `lib/game/controllers/combat/turn_phase_manager.dart:62-112` |
| Pioche : 5 cartes, remélange si `< 5` | `lib/ui/screens/game_screen.dart:214-217` |

---

*Document descriptif. Les chantiers `P-xx` cités renvoient à `docs/ROADMAP.md`, source unique du reste à faire. Le brainstorm sur l'évolution des deux rosters fera l'objet d'un document distinct.*
