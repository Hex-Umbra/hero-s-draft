# Hero's Draft - Rapport d'Analyse d'Équilibrage des Cartes

Ce document présente une analyse mathématique et fonctionnelle des **23 cartes** de *Hero's Draft*. L'objectif est d'identifier les anomalies de game design, les écarts de puissance par rapport au coût en mana, et de proposer des axes d'équilibrage concrets.

---

## 📊 1. Modélisation Mathématique de la Valeur des Cartes (VPM)

Pour comparer équitablement les cartes, nous établissons un barème de **Valeur Standardisée (VS)** basé sur les effets élémentaires fondamentaux pour 1 mana (valeur de base 1 mana = 5-6 points) :
* **1 Dégât (Cible unique)** = `1 point`
* **1 Dégât (Zone / AOE)** = `2 points` (équivalent à toucher 2 cibles en moyenne)
* **1 Armure** = `1 point`
* **1 Soin (HP)** = `2 points` (les points de vie sont permanents et donc plus précieux)
* **1 Carte piochée** = `2 points`
* **1 Mana gagné** = `3 points` (accélérateur de tempo)
* **1 Statut appliqué (Poison, Force)** = `1.5 point * valeur * durée` (dégâts/bonus différés)

Le ratio **VPM (Valeur par Mana)** mesure le rendement de la carte : $VPM = \frac{\text{Valeur Standardisée}}{\text{Coût en Mana}}$. Un VPM sain oscille entre **5.0 et 7.0**.
  
### A. Analyse des Cartes Globales (Accessibles à tous)

| Nom de la Carte | Type | Coût | Effets & Valeurs | Valeur Standardisée (VS) | VPM Ratio | Évaluation & Rareté |
| :--- | :---: | :---: | :--- | :---: | :---: | :--- |
| **Frappe (Strike)** | Attaque | 1 | 6 Dégâts | 6.0 | **6.0** | Équilibré (Common) |
| **Défense (Defend)** | Compétence | 1 | 5 Armure | 5.0 | **5.0** | Équilibré (Common) |
| **Concentration** | Compétence | 1 | Pioche 2 | 4.0 | **4.0** | Faible rendement, mais compense par le card advantage |
| **Balayage (Sweep)** | Attaque | 1 | 5 Dégâts (AOE) | 10.0 | **10.0** | Très fort si ≥ 2 ennemis (Common) |
| **Potion de Soin** | Compétence | 2 | Soigne 8 (Exhaust) | 16.0 | **8.0** | Fort mais limité par l'usage unique (Rare) |
| **Frappe Lourde** | Attaque | 2 | 14 Dégâts | 14.0 | **7.0** | Solide (Uncommon) |
| **Mur de Fer** | Compétence | 2 | 12 Armure | 12.0 | **6.0** | Solide (Uncommon) |
| **Éveil (Awakening)** | Compétence | 1 | 6 Armure + 1 Pioche | 8.0 | **8.0** | Très rentable (Rare) |
| **Focalisation (Focus)** | Compétence | 0 | +1 Mana (Exhaust) | 3.0 | **Infini** | Excellent générateur de tempo (Uncommon) |
| **Cri de Guerre** | Attaque | 1 | 4 Dégâts (AOE) + 4 Armure | 12.0 | **12.0** | **Surpuissant** (Epic). Rendement trop élevé pour 1 mana. |
| **Métallisation** | Pouvoir | 1 | +3 Armure/tour pendant 3 tours | 9.0 | **9.0** | Fort sur la durée (Uncommon) |
| **Forme Démoniaque** | Pouvoir | 3 | +4 Force pendant 3 tours | 18.0 | **6.0** | Lent à rentabiliser mais destructeur (Rare) |

### B. Analyse des Cartes Spécifiques de Classes

| Classe | Nom de la Carte | Rareté | Coût | Effets & Valeurs | VS | VPM Ratio | Évaluation vs. Globales |
| :--- | :--- | :---: | :---: | :--- | :---: | :---: | :--- |
| **Paladin** | **Smite** | Uncommon | 1 | 6 Dégâts + 4 Armure | 10.0 | **10.0** | Très fort. Rendement 2x supérieur à Frappe/Défense de base. |
| **Paladin** | **Holy Shield** | Rare | 1 | 8 Armure + 2 Soins | 12.0 | **12.0** | **Surpuissant**. Le soin répétable sans Exhaust détruit la tension des PV. |
| **Berserker** | **Frappe Téméraire** | Uncommon | 2 | 15 Dégâts | 15.0 | **7.5** | Excellent. Dépasse la Frappe Lourde globale. |
| **Berserker** | **Posture de Rage** | Common | 1 | +2 Force (1t) + 1 Pioche | 5.0 | **5.0** | Équilibré. Bon moteur de combo. |
| **Mage** | **Projectile Magique** | Common | 1 | 5 Dégâts + 1 Pioche | 7.0 | **7.0** | Très fort. Rendement supérieur à Quick Attack global. |
| **Mage** | **Surtension de Mana** | Uncommon | 0 | +2 Mana (Exhaust) | 6.0 | **Infini** | **Surpuissant**. Accélérateur de tempo extrême. |

---

## 🚨 2. Anomalies Critiques Identifiées (Codebase Audit)

En analysant le résolveur d'effets (`lib/game/services/effect_resolver.dart`), nous avons découvert une **anomalie de développement majeure** qui fausse complètement l'équilibrage actuel :

> [!WARNING]
> ### 🧪 Les Effets Élémentaires sont Inopérants !
> Les cartes **Boule de Feu (Fireball)**, **Trait de Glace (Ice Bolt)** et **Coup de Tonnerre (Thunderclap)** sont actuellement **extrêmement faibles** car leurs effets de statut ne sont **pas implémentés** dans le moteur de jeu :
> * `EffectIcon` et `EffectResolver._createStatus` renvoient `null` pour les statuts `burn`, `freeze` et `shock`.
> * La phase de combat (`CombatController.startEnemyTurn`) n'applique aucun calcul de dégâts ou de réduction d'action pour ces trois statuts élémentaires.
>
> **Conséquence** : Ces cartes payent un coût en mana élevé pour des dégâts bruts très faibles sans appliquer de contrepartie tactique.

---

## 🎯 3. Axes de Rééquilibrage & Concept Design

Voici nos recommandations concrètes pour équilibrer la base de données de cartes :

### Axe A : Activation et Design des Statuts Élémentaires 
Pour redonner de la valeur aux cartes élémentaires (Mage/Global), nous devons implémenter ces trois règles métier :
1. **Brûlure (`burn`)** : 
   * *Règle* : Inflige des dégâts de feu égaux à la valeur du statut au début du tour de l'ennemi. La valeur diminue de 1 après chaque tick.
   * *Impact* : Fireball infligera 8 dégâts + 2 au tour 1 + 1 au tour 2 (Total 11 dégâts pour 2 mana).
2. **Gel (`freeze`)** :
   * *Règle* : Réduit les dégâts de la prochaine attaque de l'ennemi de 50%. La durée diminue de 1 par tour.
   * *Impact* : Ice Bolt devient une excellente carte de contrôle défensive/offensive (6 dégâts + atténuation).
3. **Électrocution (`shock`)** :
   * *Règle* : Chaque fois que l'ennemi subit une attaque directe, il prend des dégâts supplémentaires égaux à la valeur de Électrocution. La durée diminue de 1 par tour.
   * *Impact* : Thunderclap crée une synergie surpuissante avec les cartes multi-coups ou les decks à forte pioche (ex: Berserker/Mage).

### Axe B : Ajustement des Cartes Surpuissantes (Nerfs)
* **Holy Shield (Paladin)** : 
  * *Option 1* : Ajouter `isExhaust: true` pour empêcher le joueur de se soigner indéfiniment à chaque cycle de deck.
  * *Option 2* : Réduire l'Armure à 5 et le Soin à 1 (VPM ramené à 7.0).
* **Cri de Guerre (Epic)** :
  * *Option* : Augmenter son coût en Mana à **2** (ramenant le VPM à un ratio sain de 6.0) ou réduire les dégâts en zone à 3 et l'Armure à 3.
* **Surtension de Mana (Mage)** :
  * *Option* : Réduire le gain de Mana à **1** (comme Focus) mais lui donner un effet de pioche de 1 carte pour préserver son identité de Mage.

### Axe C : Valorisation des Cartes Faibles (Buffs)
* **Coup Empoisonné (Poison Stab)** :
  * *Option* : Augmenter la valeur de Poison appliquée à **4** (durée 3) pour compenser la lenteur de la mécanique de poison par rapport aux dégâts bruts directs.
* **Concentration** :
  * *Option* : Réduire son coût en mana à **0** mais lui ajouter `isExhaust: true` pour en faire un excellent outil de cyclage de deck une fois par combat.
