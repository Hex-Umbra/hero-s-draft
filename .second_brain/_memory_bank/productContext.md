# 🎯 Contexte Produit & Règles Métier (Product Context)

Ce document synthétise la boucle de gameplay (Core Loop) de **Hero's Draft**, son économie, ses systèmes de progression procédurale et ses règles métier fondamentales.

---

## 1. Boucle de Gameplay Principale (Core Loop)

La progression dans **Hero's Draft** est structurée autour d'une boucle classique de roguelike deckbuilder enrichie d'une mécanique de draft tactique de héros et de cartes.

```
[Écran d'Accueil]
       │
       ▼
[Sélection de Classe] ── Paladin (regenArmor) / Berserker (berserkerArmor) / Mage (spellArmor)
       │
       ▼
[Starter Deck Draft] ── Constitution du deck initial (choix par paquets/draft de départ)
       │
       ▼
[Carte Stratégique] ◄─── Navigation sur le Graphe Acyclique Dirigé (10 étages générés procéduralement)
  (Combat / Élite / Boutique / Événement / Repos / Boss)
       │
       ├─────────────────────────┐
       ▼                         ▼
[Écran de Combat]        [Écrans Spécifiques] (Boutique, Feu de Camp, Événement)
 (Flame Canvas HUD)              │
       │                         │
       ▼                         │
[Draft de Récompense] ◄──────────┘ (Chance influe sur Rareté + tirage Légendaire bonus)
       │
       ▼
[Évaluation Auto-Merge] ── Fusion 3x cartes identiques → Carte Level + 1
       │
       ▼
[Passage à l'Étage Suivant] ── (Si Boss complété → Acte + 1)
```

### Systèmes de Progression et exploration
1. **Génération Procédurale de Carte (`MapGeneratorService`)** :
   - Chaque Acte est constitué de **10 étages** (`floors = 10`).
   - La largeur de chaque étage varie de **2 à 5 nœuds**, sauf le dernier étage ( Boss) qui se resserre sur un nœud unique.
   - Les connexions forment un **Graphe Acyclique Dirigé (DAG)** reliant l'étage $N$ aux nœuds adjacents (offset horizontal de -1, 0, ou 1) de l'étage $N+1$. Des passes de connexion corrigent tout nœud orphelin.
   - Distribution probabiliste des types de nœuds (hors étage 0 qui est 100% Combat et étage 9 qui est 100% Boss) :
     - **Combat standard** : 60%
     - **Événement narratif** : 15%
     - **Boutique (Shop)** : 10%
     - **Repos (Campfire)** : 10%
     - **Combat Élite** : 5%

2. **Système de Draft Post-Combat et Influence de la Chance (`luck`)** :
   - Chaque victoire offre un draft de 3 choix de récompenses de statistiques (Vitalité, Aiguisage, Forge, Sagesse).
   - Les bonus de statistiques de base (Rareté Commun) sont :
     - **Commun (x1.0)** : +5 PV Max, +2 Attaque (Force), +1 Maîtrise d'Armure, +1 Mana Max.
     - **Peu Commun (x1.5)** : +8 PV Max, +3 Attaque, +2 Maîtrise, +2 Mana Max.
     - **Rare (x2.0)** : +10 PV Max, +4 Dégâts, +3 Maîtrise, +2 Mana Max.
     - **Épique (x3.0)** : +15 PV Max, +6 Dégâts, +5 Maîtrise, +3 Mana Max.
   - **Algorithme de Rareté et Chance (Luck)** :
     - Probabilités de base (à 0 Luck) : Légendaire (1%), Épique (4%), Rare (15%), Peu Commun (30%), Commun (50%).
     - Chaque point de `luck` permanente du héros augmente la chance d'obtenir des raretés supérieures : **+0.5% Légendaire**, **+1.5% Épique**, **+3.0% Rare**, et **+4.0% Peu Commun** par point.
     - **Tirages Légendaires Bonus** : Les objets légendaires n'empiètent pas sur les 3 slots. Ils subissent un jet indépendant et s'y additionnent :
       - *Trèfle à 4 feuilles* : +1 Chance de façon permanente.
       - *Miroir Magique* : Clone une carte de son deck actuel parmi 3 proposées.

3. **Mécanique d'Auto-Merge (Fusion de Deck)** :
   - Gérée par `DeckNotifier.mergeCards()`. Dès que le master deck comporte **3 exemplaires identiques** d'une carte de même niveau (ex : 3x *Frappe* Niv. 1), elles fusionnent automatiquement en **1 exemplaire amélioré** de niveau supérieur (Niv. 2).
   - Les effets de la carte et ses coûts sont recalculés selon la formule d'échelonnement : `scaledValue = baseValue * (1 + (level - 1) * 0.5)`.

---

## 2. Règles Métier Majeures

Les règles métier de combat sont centralisées au sein d'une boucle logicielle hautement prévisible.

### 🔋 Gestion de la Ressource de Mana
- Au début de chaque tour de combat, le mana actuel est réinitialisé au mana maximum (`state.heroStats.maxMana`).
- Les gains de mana exceptionnels en cours de tour (via la relique `gain_mana` ou des cartes comme `Focalisation`) s'ajoutent directement et peuvent temporairement dépasser le cap maximum pour le tour en cours uniquement (effet transitoire).
- Chaque carte possède un coût (0 à 3 cristaux). Si le coût est supérieur au mana disponible, la carte est déclarée injouable.

### 🛡️ Gestion de l'Armure et Absorption
- L'armure absorbe la totalité des dégâts reçus en priorité.
- **Règles d'absorption (`EntityStats.takeDamage`)** :
  - Si dégâts > armure : le restant affecte directement les points de vie (`currentPv`), et l'armure est brisée (remise à 0).
  - Si armure $\ge$ dégâts : l'armure encaisse tout et est déduite du montant des dégâts.
- **Maîtrise d'Armure (`armorMastery`)** : Statistique cumulative et permanente augmentant tous les gains d'armure générés en cours de combat. Par exemple, avec 3 de Maîtrise, un gain d'armure passif ou de carte de value 5 génère réellement **8 d'Armure**.
- **Persistance** : L'armure accumulée est transitoire et est remise à 0 à la fin de chaque combat (`completeCurrentNode()`), tandis que la Maîtrise d'Armure reste permanente tout au long de la run.

### ⚔️ Résolution des Effets de Combat
- Les dégâts physiques infligés par le joueur sont résolus dans `EffectResolver._calculateDamage()` :
  $$\text{Dégâts Finaux} = (\text{Dégâts de base de la carte} + \text{Force effective}) \times \text{Modificateurs}$$
  - **Force effective** : Cumul de la statistique `attaque` permanente et des effets de statut `strength` actifs.
  - **Faiblesse (`weakness`)** : Si l'attaquant possède le statut faiblesse, ses dégâts physiques finaux sont réduits de **25%** (arrondi à l'entier).

---

## 3. Altérations d'État & Statuts (Status Effects)

Les combattants accumulent des altérations d'état temporaires ou permanentes dont le décompte (`tickStatuses()`) s'opère au début de leur tour respectif.

| Statut (ID technique) | Nature (Type) | Effet mécanique |
| :--- | :---: | :--- |
| **`poison`** | Debuff | Inflige des dégâts directs égaux à sa valeur au début du tour de l'entité affectée. La durée décrémente de 1 à chaque tour. |
| **`strength`** | Buff | Ajoute sa valeur brute aux dégâts physiques infligés (`effectiveAttaque`). |
| **`weakness`** | Debuff | Réduit les dégâts physiques infligés par l'entité de 25%. |
| **`strength_regen`** (Éveil) | Buff | Ajoute sa valeur au statut permanent `strength` au début de chaque tour, puis décrémente sa durée. |
| **`armor_regen`** (Métallisation)| Buff | Génère de l'armure brute égale à sa valeur au début du tour, puis décrémente sa durée. |
| **`vulnerable`** | Debuff | *Partiellement Implémenté* : Est déclaré dans `EffectResolver` et l'UI, mais absent des calculs physiques réels dans `EffectResolver._calculateDamage()`. |
| **`burn`, `freeze`, `shock`** | Placeholders | *Non Implémentés* : Présents uniquement comme gabarits d'affichage textuel dans `UiCard`, mais absents du moteur de jeu Flame et de la couche logique d'effet `EffectResolver`. |
