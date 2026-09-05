# S2 — Identité de classe — Conception

Date : 2026-08-07
Statut : **Design validé, non implémenté**
Chantier ROADMAP : **P-41**, Tier B (`docs/ROADMAP.md` §4) — lot S2 du programme **P-40 → P-44**
Sources amont :
- `docs/analysis_reports/05082026_etat_des_lieux_heros_et_cartes_Opus5.md` (diagnostic du 05/08)
- `docs/analysis_reports/05082026_brainstorm_heros_et_cartes_Opus5.md` (brainstorm du 05/08)
- `docs/Idées améliorations classe et cartes.md` (idées du propriétaire du projet)

> **Ce document couvre un lot sur cinq.** Le périmètre des trois sources amont vaut l'équivalent de
> cinq specs, qu'une seule ne pourrait ni faire relire ni faire exécuter. Le découpage est porté par
> [`docs/ROADMAP.md` §4](../../ROADMAP.md) sous les identifiants **P-40 → P-44** ; S2 y est **P-41**.
>
> **S2 en est le lot racine**, au sens technique et non par ordre de préférence : ses décisions
> déterminent la composition des pools de S3. Une seule ligne de `statRules` suffit à le montrer.
> Si le Berserker **convertit** l'armure en Force, `iron_wall` et `defend_basic` restent dans son
> pool — elles y lisent simplement autrement. S'il la **bloque**, ces deux cartes doivent en être
> retirées, sous peine qu'il drafte des cartes qui ne font littéralement rien. On ne peut donc pas
> écrire les pools de S3 avant d'avoir tranché ici. La réciproque ne tient pas : les neuf passifs
> se conçoivent sans connaître la liste des cartes.
>
> **Et S2 se teste seul.** La règle R4 (§5) interdit à un passif de dépendre du pool : les neuf sont
> jouables avec le catalogue actuel de 23 cartes, sans que S3 existe. C'est ce qui rend ce découpage
> réel plutôt que théorique — sinon il ne ferait que déplacer le problème d'un lot à l'autre.

---

## 1. Vérification préalable

Tous les constats ci-dessous ont été re-vérifiés contre le code le 2026-08-07, ligne par ligne.
Trois d'entre eux **corrigent ou complètent les documents amont** et sont marqués ⚠️.

| Constat | Vérification |
|:---|:---|
| `TraitSystem` est une chaîne `if/else` sur 3 chaînes de caractères | `lib/game/systems/trait_system.dart:15-66` |
| `PassiveData` ne porte qu'un seul `value`, sans durée ni seuil | `lib/models/data/passive_data.dart:13` |
| `PassiveData.fallback()` duplique les 3 passifs en Dart, en plus du JSON | `lib/models/data/passive_data.dart:67-120` |
| `RelicTrigger` compte 9 valeurs | `lib/models/data/relic_data.dart:5-13` |
| `onAttackPlayed` / `onSkillPlayed` / `onPowerPlayed` sont dispatchés | `lib/game/controllers/combat_controller.dart:302-306` |
| Sur les 25 reliques, **`onSkillPlayed` et `onPowerPlayed` n'ont aucun consommateur** ; `onAttackPlayed` en a **deux** (`kunai`, `shuriken`) | `assets/data/relics/`, re-mesuré le 2026-08-11 |
| `effectiveAttaque` n'a que 2 sites de résolution vivants | `lib/game/services/effects/strategies.dart:30` et `:42` |
| …plus 1 site d'affichage | `lib/game/components/card_component.dart:343` |
| …plus 1 getter de passe-plat et le système de compétences mort | `run_controller.dart:43` · `combat_controller.dart:212-244` |
| Les 12 effets `damage` du catalogue sont **tous** portés par des cartes de type `attack` | Tableaux §II.3 et §II.4 du diagnostic |
| `EntityStats` porte `critChance` ; `HeroData` ne l'expose pas | `lib/models/entity_stats.dart:17` · tableau §I.1 du diagnostic |
| `SaveService` sérialise un unique blob versionné, sans store méta | `CLAUDE.md` §Architecture · diagnostic §I.6 |
| `addCardToHand` n'existe pas | `deck_controller.dart:261` et `:375` existent ; la main n'est alimentée que par `:193` |

### ⚠️ 1.1. L'armure est remise à zéro à chaque début de tour

`startTurn()` exécute `armure: 0` **avant tout le reste** (`lib/game/controllers/run_controller.dart:412`).
L'armure est donc une ressource **strictement éphémère**, valable un tour.

C'est le constat le plus structurant de cette vérification : il invalide toute conversion de
l'armure vers une stat permanente (§3.3) et il fixe le point d'ancrage du passif *Bénédiction* (§6).

### ⚠️ 1.2. `lifesteal` est un quatrième statut orphelin, et le plus profondément mort

Le diagnostic du 05/08 recense trois statuts orphelins (`vulnerable`, `weakness`, `strength_regen`)
et qualifie les neuf statuts de « pleinement implémentés ». C'est inexact pour un quatrième.

| Élément | État |
|:---|:---|
| Création du statut | ✅ `player_stats_manager.dart:472` |
| Icône | ✅ `status_indicator.dart:155` |
| Panneau HUD | ✅ `status_effects_panel.dart:100` |
| Localisation bilingue | ✅ `app_fr.arb:211` · `app_en.arb:513` |
| **Consommation dans le calcul de dégâts** | ⛔ **aucune occurrence dans `damage_pipeline.dart`** |

Les trois statuts du diagnostic ont une mécanique qui fonctionne et aucune source. `lifesteal` a
l'inverse : une source (elle-même morte, appelée seulement par le système de compétences) et
**aucune mécanique**. Il s'affiche et ne fait rien.

Conséquence de périmètre : `applyLifestealBuff()` vit dans `RunController`, **pas** dans le système
de compétences. La suppression de `skills.json` (lot S1) ne doit pas l'emporter.

### ⚠️ 1.3. `armorMastery` ne s'applique qu'aux passifs

`entity_stats.dart:11` documente le champ comme « Bonus permanent ajouté à **chaque** gain d'armure ».
Le code ne le fait qu'aux quatre sites de `TraitSystem` :

| Source de gain d'armure | Site | `armorMastery` appliqué ? |
|:---|:---|:---:|
| Passifs | `trait_system.dart:23, 28, 44, 61` | ✅ |
| Cartes | `strategies.dart:90` | ❌ |
| Rune `hardened` | `effect_resolver.dart:241` | ❌ |
| Reliques | `player_stats_manager.dart:381` | ❌ |

Soit le commentaire ment, soit trois sources sur quatre ont un défaut. L'entonnoir de §3.1 tranche
la question par construction : le bonus est appliqué une fois, au seul point de passage.

---

## 2. Ce que le chantier livre

1. **Un mécanisme de règles de stat par classe**, piloté en JSON, réutilisable pour toute classe et
   toute stat future (§3).
2. **La scission de `attaque` en trois puissances** — `attackPower`, `skillPower`, `alterationPower` —
   à comportement identique au jeu actuel (§4).
3. **Neuf passifs sélectionnables**, trois par classe, sur un `TraitSystem` refondu en Strategy (§5, §6).
4. **Des stats de départ réellement différenciées**, et un écran de sélection qui cesse de mentir (§7).
5. **Une table de récompenses conditionnée par la classe et par le passif actif** (§8).

Et, en conséquence directe :

- Le trigger orphelin `onSkillPlayed` trouve son premier consommateur (M1). **Le point A3 du
  diagnostic se referme à moitié** — `onPowerPlayed` reste sans consommateur, et le refermer relève
  des reliques, pas des passifs. `onAttackPlayed`, lui, n'a jamais été orphelin : `kunai` et
  `shuriken` l'utilisent déjà, ce qui **prouve le chemin de dispatch** dont B2 et M2 dépendent.
- Le statut `vulnerable` trouve sa première source (§6, passif M2) — un tiers de l'axe B du brainstorm.
- `lifesteal` cesse d'être décoratif (§6, passif B2).
- La divergence `armorMastery` de §1.3 est résolue par construction.

---

## 3. Le mécanisme `statRules`

### 3.1. Prérequis : un entonnoir de gains

`setHeroStats()` est un **setter de valeur absolue** — son propre commentaire le dit
(`run_controller.dart:344` : « Modifie la valeur exacte d'un champ »). Les dix sites appelants
calculent eux-mêmes le total (`stats.armure + X`) avant d'appeler. La méthode ne voit donc jamais
un gain, seulement un résultat : **rien ne peut y être intercepté.**

| Ressource | Sites de gain | Détail |
|:---|:---:|:---|
| Armure | **8** | `strategies.dart:90` · `effect_resolver.dart:241` · `trait_system.dart:22, 27, 43, 60` · `player_stats_manager.dart:381` · `combat_controller.dart:267, 272` |
| Mana | **2** | `strategies.dart:106` · `effect_resolver.dart:170` |

*(Les deux sites de `combat_controller.dart` disparaissent avec S1.)*

**Livrable** : des méthodes de delta — `grantArmor(int)`, `grantMana(int)`, `grantPower(PowerStat, int)` —
qui portent la table de règles et le bonus de maîtrise, et la conversion des dix sites appelants.
`setHeroStats()` est conservé pour ce qu'il fait bien : les remises à zéro et les restaurations.

C'est la fondation. Aucun autre élément de S2 ne fonctionne sans elle.

### 3.2. La forme de la donnée

Une table de redirection dans `heroes.json`, pas une liste de booléens. Le blocage dur et la
conversion deviennent alors **deux valeurs de la même donnée**, décidées classe par classe :

```jsonc
// Berserker
"statRules": {
  "armure":     { "mode": "convert", "to": "status:strength", "duration": 1 },
  "skillPower": { "mode": "block" }
}

// Mage
"statRules": {
  "attackPower": { "mode": "convert", "to": "alterationPower", "ratio": 1.0 }
}

// Paladin — aucune règle
```

Modes retenus : `block` (le gain est annulé) et `convert` (le gain est redirigé). Le modèle est
extensible — `cap`, `decay` — sans changement de forme.

### 3.3. R5 — la règle qui protège l'économie

> **Une conversion ne peut jamais transformer une ressource éphémère en ressource permanente.**

L'armure est remise à zéro chaque tour (§1.1) ; `attackPower` est une stat de run permanente,
ajoutée à chaque effet `damage`. Convertir l'armure en `attackPower` ferait gagner au Berserker
**+5 de puissance définitive à chaque `iron_wall` jouée** (10 armure, 2 mana). Le jeu serait cassé
au troisième combat.

La conversion vise donc le **statut** `strength`, qui porte une durée et se décrémente : l'armure
d'un tour devient de la Force d'un tour. La symétrie est exacte.

La même règle borne *Ferveur* (§6, passif P2), dont le gain de Force est à durée courte et non
permanent.

---

## 4. La scission des stats de puissance

### 4.1. Pourquoi maintenant, et seulement maintenant

Les 12 effets `damage` du catalogue sont **tous** portés par des cartes de type `attack` (§1).
Aucune carte `skill` n'inflige de dégâts. Scinder `attaque` ne change donc **rien au comportement
du jeu actuel** : c'est un refactor à iso-résultat, sur 2 sites de résolution et 1 site d'affichage.

Le split ne devient un levier qu'au moment où S3 écrira les premières cartes `skill` offensives.
Fait après S3, il obligerait à ré-équilibrer une trentaine de cartes. **C'est la fenêtre.**

⚠️ **Deux constructeurs, pas un.** `EntityStats` est construit avec `attaque: 0` à **deux
endroits** de `RunController` : `build()` (`:224`, l'état initial) et `startNewRun()` (`:258`, le
démarrage réel). Le split doit traiter les deux, sous peine qu'une partie neuve et une partie
rechargée n'aient pas la même forme de statistiques. Le troisième chemin, `hydrate()` (`:237`),
relève de la migration de sauvegarde (§9).

### 4.2. Les trois stats et leur règle d'attribution

| Stat | S'applique à |
|:---|:---|
| `attackPower` | Effet `damage` porté par une carte de type `attack` |
| `skillPower` | Effet `damage` porté par une carte de type `skill` |
| `alterationPower` | Effet `apply_status` **ciblant un ennemi** |

Une seule lecture de `card.data.type`, champ qui existe déjà et est déjà affiché au joueur.

**Garde-fou sur `alterationPower`.** Sans la restriction « ciblant un ennemi », `demon_form`
(Force 2, ciblé soi) scalerait avec `alterationPower`, la Force nourrirait les dégâts, et
l'altération se bouclerait sur elle-même. La ligne de partage tombe exactement sur le catalogue
existant : `poison` / `burn` / `freeze` / `shock` sur l'ennemi d'un côté, `strength` / `armor_regen`
sur soi de l'autre.

**`strength` alimente `attackPower`.** Conséquence utile : un Mage qui convertit `attackPower` ne
tire plus rien de `demon_form`, qui devient naturellement une carte Berserker/Paladin. Le split
effectue donc une partie du tri des pools de S3 tout seul.

### 4.3. Le trou que ça comble

La valeur d'un statut ne croît aujourd'hui **que** par le multiplicateur de rareté
(`effect_resolver.dart:217`, `(baseValue * card.rarityMultiplier).round()`). Aucune relique, aucune récompense de level-up, aucune rune ne fait
monter un poison ou une brûlure. Le seul archétype du jeu sans courbe de progression est
précisément celui de la classe annoncée « Orientée Altération ». `alterationPower` la lui donne.

---

## 5. Le cadre des passifs

Cinq règles, pour que les neuf passifs ne soient pas neuf cas particuliers.

| | Règle |
|:---|:---|
| **R1** | Un passif = un trigger + **un axe de croissance nommé**. La récompense associée n'est pas inventée, elle est déduite de cet axe. |
| **R2** | Les trois passifs d'une classe pointent vers **trois façons de jouer**, pas vers trois puissances. Sinon le joueur ne choisit pas, il prend le meilleur. |
| **R3** | Aucun passif ne produit une ressource que `statRules` interdit à sa classe. |
| **R4** | Aucun passif ne se déclenche sur **moins de 40 % du pool jouable**. |
| **R5** | Une conversion ne transforme jamais une ressource éphémère en ressource permanente (§3.3). |

**R4 formalise un défaut existant.** `spellArmor` est conditionné aux cartes `skill`, soit 6 sur 17.
Un passif Paladin adossé aux soins serait pire : le jeu ne compte que **2 cartes de soin**
(`heal_potion`, `holy_shield`). D'où le principe corollaire :

> **Un passif ne doit pas amplifier le pool. Il doit produire lui-même son déclencheur.**

C'est ce qui sauve *Bénédiction* (§6) : au lieu d'« amplifier les soins », il convertit l'armure
survivante en PV. Zéro carte de soin requise.

### 5.1. Refonte de `TraitSystem`

`TraitSystem` est une chaîne `if/else` sur trois `effectType` (§1). Neuf passifs y ajouteraient
neuf branches, plus les nouveaux triggers. C'est exactement la forme que l'**ADR-061** a résolue
pour les effets de carte : une stratégie par `effectType`, enregistrée dans un registre.

`PassiveData` s'élargit en conséquence — durée, seuil, ratio, stat cible — et
`PassiveData.fallback()` disparaît : la duplication Dart/JSON de §1 n'a plus de raison d'être une
fois le registre en place.

### 5.2. Triggers

| Trigger | État | Consommé par |
|:---|:---|:---|
| `startOfTurn` | ✅ vivant | P3, B1 |
| `endOfTurn` | ✅ vivant | P1, M3 |
| `onAttackPlayed` | ✅ vivant — `kunai`, `shuriken` | B2, M2 |
| `onSkillPlayed` | ✅ **dispatché, orphelin** | M1 |
| `onEnemyKilled` | ✅ vivant | B3 |
| `onDamageTaken` | ❌ **à créer** | P2 |
| Facilité de comptage — par tour et par combat | ❌ **à créer** | M1 (« 3 compétences »), M2 (« 1ʳᵉ attaque du tour ») |

**Deux ajouts moteur seulement** : le trigger `onDamageTaken`, et une facilité de comptage commune
à M1 et M2 — un compteur remis à zéro en début de tour ou de combat selon la clé. Tout le reste
réutilise de l'existant, dont un trigger jusqu'ici inerte.

Note : `onCardPlayed` perd son seul consommateur côté passif avec la disparition de `spellArmor`
(§6) — deux reliques l'utilisent encore. `onPowerPlayed` reste le seul trigger sans aucun
consommateur : aucun des neuf passifs ne s'y adosse.

### 5.3. Nombre de passifs actifs

**Un seul par run**, choisi à la sélection de classe.

Le modèle porte cependant `activePassives: List<String>` et un `passiveSlots: int` lu depuis un
point unique — un provider renvoyant `1` en dur. Quand la méta-progression (**P-13**) arrivera,
elle écrira cet entier et rien d'autre ne bougera.

**S2 ne dépend donc pas de P-13.** `SaveService` n'ayant aucun store méta (§1), P-13 devra en créer
un ; ce provider est le seul point de contact.

---

## 6. Les neuf passifs

Aucune valeur chiffrée : elles relèvent de l'équilibrage, pas de la conception.

### Paladin — aucune règle de stat · `armorMastery` de départ > 0

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| P1 | **Régénération d'Armure** *(existant)* | `endOfTurn` | Gain d'armure | `armorMastery` |
| P2 | **Ferveur** | `onDamageTaken` | L'armure qui absorbe des dégâts octroie de la Force, à durée courte | `attackPower` |
| P3 | **Bénédiction** | `startOfTurn`, **avant le reset de §1.1** | L'armure survivante devient des PV | `armorMastery` |

Seule classe à conserver l'accès aux trois puissances : c'est son identité de généraliste, et le
repère du joueur qui découvre.

*Ferveur* referme une boucle propre : chez le Paladin, **encaisser devient une ressource offensive**.
Il tape parce qu'il tient, là où le Berserker tape parce qu'il meurt — les deux classes lisent le
même verbe à l'envers l'une de l'autre.

*Bénédiction* s'insère impérativement **avant** `armure: 0` dans `startTurn()`, sinon il n'a rien à
convertir. C'est le seul passif du jeu dont l'ordre d'exécution est contraignant ; il doit être
couvert par un test dédié.

### Berserker — `armure → strength(1)` · `skillPower: block` · `critChance` de départ > 0

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| B1 | **Rage** | `startOfTurn` | Force proportionnelle aux PV manquants | `attackPower` |
| B2 | **Soif de Sang** | `onAttackPlayed` | Vol de vie, croissant à mesure que les PV baissent | `critChance` |
| B3 | **Frénésie** | `onEnemyKilled` | Force et pioche à chaque ennemi abattu | `attackPower` |

*Rage* est la formule de `berserkerArmor` redirigée vers la Force. Elle corrige au passage le défaut
relevé au diagnostic (§I.3.2) : le passif ne sera plus muet à pleine vie, un plancher étant possible.

*Soif de Sang* exige le hook manquant de §1.2 : après résolution des dégâts, si le héros porte
`lifesteal`, il se soigne. `DamageEffectStrategy` dispose déjà des stats du héros.

**Le blocage de `skillPower` se paie en axes de croissance.** Le Berserker n'a que `attackPower` et
`critChance` ; ses trois passifs se distinguent par le *pattern* — attrition, soutien, boule de
neige — et non par la stat. Conforme à R2, mais c'est le coût réel du blocage, nommé ici plutôt que
découvert au playtest.

Le blocage est **souple** : les cartes `skill` restent jouables et leurs effets non offensifs
(pioche, mana, armure convertie) fonctionnent normalement. Seul leur scaling de dégâts est nul.

### Mage — `attackPower → alterationPower`

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| M1 | **Flux de Mana** | `onSkillPlayed`, compteur | Mana supplémentaire pour le tour | `skillPower` |
| M2 | **Marque du Mage** | 1ʳᵉ attaque du tour | La cible devient `vulnerable` | `alterationPower` |
| M3 | **Canalisation** | `endOfTurn` | Le mana non dépensé devient de l'armure | `armorMastery` |

**M1 et M3 sont activement opposés** : l'un récompense de vider sa main, l'autre de garder du mana.
Le même deck ne peut pas viser les deux. C'est ce qui fait du choix de passif une vraie décision.

**M2 est celui qui compte.** Seul passif qui rende la promesse « Orienté Altération » de
`heroes.json`, il donne à `vulnerable` sa première source, et il ne dépend d'aucune carte —
R4 est satisfait dès aujourd'hui, avant S3.

Le passif `spellArmor` actuel disparaît. Sa fonction — survivre à 60 PV — est reprise par M3, mais
en la faisant **payer** : le Mage ne se protège que s'il accepte de jouer moins.

---

## 7. Stats de départ et écran de sélection

### 7.1. Ce qui est différencié

| Classe | Levier | Justification |
|:---|:---|:---|
| Paladin | `armorMastery` > 0 | Amplifie son propre passif à chaque fin de tour |
| Berserker | `critChance` > 0 | Colle à « Orienté Dégâts » sans toucher aux puissances |
| Mage | *(aucune stat)* | Son identité passe par `statRules` et ses trois passifs |

**`maxMana` reste à 3 pour les trois classes.** Les cartes coûtent 0 à 2 : un point de mana
supplémentaire représente environ **+33 % d'actions par tour**, de loin le levier le plus explosif
du jeu — et c'est précisément le sujet de **P-16**. Différencier le mana avant l'assainissement de
son économie coulerait le défaut dans le béton des classes.

`luck` reste à 0 partout. Le champ attend un porteur — une classe orientée hasard — pas un
rééquilibrage.

**`critChance` est à ajouter à `HeroData`** ; `EntityStats` le porte déjà (`entity_stats.dart:17`).

### 7.2. L'écran de sélection

`class_selection_screen.dart:342` affiche `playerClass.baseDamage` — 5 / 15 / 10 — alors que la run
démarre à 0 pour tous (`run_controller.dart:258`, `attaque: 0 // Force de base à 0`).
**L'écran ment au joueur au moment le plus structurant de la run.**

`baseDamage` est retiré de `heroes.json` et de `HeroData` : le champ n'a aucun consommateur réel
côté héros, et le rétablir est explicitement écarté (§10).

L'écran affiche à la place ce qui diffère réellement : PV max, stats de départ non nulles, règles
de `statRules` en clair (« ne peut pas se blinder », « ne renforce pas ses compétences »), et le
**choix du passif parmi les trois de la classe**.

---

## 8. Les récompenses

### 8.1. Conditionnement par la classe — automatique

*Affûtage* se scinde en trois récompenses (`attackPower`, `skillPower`, `alterationPower`). Le
filtre n'est pas une table à écrire : **c'est `statRules` lui-même**. Un Berserker ne voit jamais
`skillPower` parce que sa classe le bloque ; un Mage ne voit jamais `attackPower` parce que sa
classe le convertit.

`LevelUpRewardType` passe de 8 à 10 types de stat, dont chaque classe n'en voit qu'environ 8.

### 8.2. Conditionnement par le passif — neuf récompenses dédiées

Une récompense dédiée par passif, améliorant ses chiffres propres — seuil de *Flux de Mana*, ratio
de *Rage*, durée de *Marque du Mage*.

**Ces neuf récompenses ne se concurrencent jamais.** Une seule est éligible dans une run donnée,
celle du passif actif ; les huit autres n'existent pas dans ce tirage. La table de tirage effective
compte donc **11 types**, non 19. Quand `passiveSlots` passera à N, N deviennent éligibles — le
mécanisme suit sans modification.

Coût : 9 entrées × 2 langues, et 9 effets à câbler. C'est du contenu, pas de l'architecture.

### 8.3. Hors périmètre

Le rééquilibrage des valeurs et des paliers de rareté des récompenses existantes — *Sagesse* en
tête — **reste à P-16**, qui exige une re-mesure que ce chantier ne fait pas.

S2 doit seulement **ne pas aggraver** : les trois récompenses de puissance héritent des paliers de
l'ancienne *Affûtage*, sans en inventer.

---

## 9. Migration de sauvegarde

`SaveService` sérialise un blob unique versionné. Le split de §4 impose un incrément de version et
une règle de reprise :

| Champ ancien | Champ nouveau | Règle |
|:---|:---|:---|
| `attaque` | `attackPower` | Report à l'identique |
| — | `skillPower`, `alterationPower` | 0 |
| `passiveTrait` | `activePassives` | Liste à un élément |

Les runs en cours restent chargeables ; le héros conserve exactement sa puissance offensive.

---

## 10. Alternatives écartées

| Idée | Motif |
|:---|:---|
| **Rendre `baseDamage` réel** | `effectiveAttaque` est ajouté **par cible** sur les AoE (`strategies.dart:42`). Un Berserker démarrant à 15 ferait de `sweep` (1 mana) une carte à 18 dégâts par ennemi. C'est très probablement la raison de la neutralisation d'origine. |
| **Différencier `maxMana`** | §7.1 — levier le plus explosif du jeu, et sujet de P-16. |
| **Convertir l'armure en `attackPower`** | §3.3 — viole R5, casse le jeu au troisième combat. |
| **Deux stats de puissance au lieu de trois** | Le Mage n'aurait plus qu'un axe de build, et `alterationPower` est précisément la stat qui manque au seul archétype sans courbe (§4.3). |
| **Quatre stats (`healPower`)** | Deux cartes de soin dans tout le jeu : stat sans substrat. |
| **Un passif Paladin adossé aux soins** | R4 — se déclencherait sur 2 cartes sur 23. Remplacé par *Bénédiction*. |
| **Passif Berserker générant une carte en main** | `addCardToHand` n'existe pas (§1). Le précédent — provenance, épuisement, comptage dans la taille du deck — appartient à S5. Remplacé par *Frénésie*. |
| **Plusieurs passifs actifs d'emblée** | Chaque paire devient une interaction à équilibrer, et le choix perd son coût. §5.3 en garde la forme sans la livrer. |
| **Faire dépendre S2 de P-13** | §5.3 — le seam `passiveSlots` évite la dépendance. |

---

## 11. Périmètre et suite

### Dans S2

L'entonnoir de gains, `statRules`, le split des trois puissances, la refonte de `TraitSystem` en
Strategy, les deux nouveaux triggers, les neuf passifs, les stats de départ, l'écran de sélection,
les récompenses conditionnées, la migration de sauvegarde, le hook `lifesteal`.

### Hors S2

Les quatre autres lots — **P-40** (nettoyage), **P-42** (pools de cartes), **P-43** (économie de
deck), **P-44** (profondeur de cartes) — sont décrits, chiffrés et ordonnés dans
[`docs/ROADMAP.md` §4](../../ROADMAP.md), section « Programme *Identité de classe & catalogue* ».
**Ce document ne les redécrit pas** : la ROADMAP est la source unique du reste à faire, et deux
formulations du même périmètre sont deux occasions de diverger.

Un seul point les concernant relève de la conception et vit donc ici : **P-40 est indépendant de
S2 et peut être livré avant, pendant ou après** — à la seule condition de ne pas emporter
`applyLifestealBuff()` avec la chaîne `skills.json` (§1.2).

### La tension à garder en tête pour S3 (P-42) et S4 (P-43)

Les documents amont portent deux objectifs opposés sans les nommer : « le joueur n'obtient pas
assez de copies des mêmes cartes » (concentrer le pool) et « comment élargir le pool ? » (diversifier).

Les pools par classe les réconcilient : le catalogue global grossit tandis que le pool **effectif
d'une run** rétrécit. C'est le mécanisme central de S3, et il conditionne la forme de la récompense
de carte de S4 — qui devra être **biaisée vers les doublons**, faute de quoi elle aggravera le
problème qu'elle est censée résoudre.

---

*Conception. Aucune valeur d'équilibrage chiffrée : elles relèvent du plan d'implémentation et du
playtest. Les chantiers `P-xx` cités renvoient à `docs/ROADMAP.md`, source unique du reste à faire.*
