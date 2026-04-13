# Documentation des Classes : Hero's Draft

Ce document répertorie l'ensemble des classes jouables actuellement intégrées au jeu "Hero's Draft", leurs caractéristiques de départ, le fonctionnement de leurs mécaniques spéciales et leurs coûts (Mana ou PV), ainsi que la cartographie des fichiers du code source responsables de ces mécaniques.

---

## Nouvelle Mécanique : Le Mana
Chaque classe possède maintenant une jauge de **Mana** qui permet d'utiliser ses compétences spéciales.
- Le coup des compétences est individuel, tout comme leur temps de rechargement (Cooldown).
- A chaque niveau complété, le Héros régénère **50% de son Mana Maximum**.
- Entre chaque niveau, les joueurs peuvent choisir diverses améliorations en récompense, incluant **Sagesse (+5 Mana Max)**, avec des probabilités égales.

---

## 1. Le Paladin (Orienté Survie)
Le Paladin est la classe la plus endurante. Elle se base sur la gestion de l'armure et l'augmentation conditionnelle de sa faible force de frappe grâce à ses buffs.

### Statistiques de Base
- **PV (Points de Vie)** : `100`
- **Mana de départ** : `10`
- **Armure de départ** : `20`
- **Attaque** : `5`
- **Défense** : `0.1` (10% de réduction des dégâts)

### Compétences Spéciales
1. **Bouclier (+15 Armure)** : (Coût : 3 Mana, CD : 2 tours) Injecte instantanément de manière inconditionnelle 15 points d'armures supplémentaires aux statistiques du héros.
2. **Rage (+15% PV Max en Attaque)** : (Coût : 5 Mana, CD : 4 tours) Applique une altération temporelle au Héros. Son attaque totale sera augmentée d'un montant plat équivalent à `15%` de ses PV Max lors des 2 prochains tours.

---

## 2. Le Mage (Orienté Altération / Zone)
Le Mage possède de bonnes frappes moyennes, très peu de défense, mais est la seule classe capable de toucher plusieurs ennemis en un seul tour, ou d'abattre de puissants éclairs mortels.

### Statistiques de Base
- **PV (Points de Vie)** : `60`
- **Mana de départ** : `15`
- **Armure de départ** : `5`
- **Attaque** : `10`
- **Défense** : `0.05` (5% de réduction des dégâts)

### Compétences Spéciales
1. **Nova (AoE de 20%)** : (Coût : 4 Mana, CD : 2 tours) Inflige instantanément `20%` de l'Attaque totale du Mage à **tous** les adversaires présents sur le terrain sans distinction.
2. **Frappe de Foudre (150% Cible)** : (Coût : 8 Mana, CD : 3 tours) Foudroie un ennemi sélectionné, lui infligeant `150%` de la valeur de l'Attaque totale. Nécessite qu'un ennemi soit actuellement ciblé.

---

## 3. Le Berserker (Orienté Dégâts purs)
Le Berserker n'a aucune armure ni aucune stat de protection (Défense à 0). Il doit se reposer strictement sur l'agression, la mitigation de l'armure adverse, et la ponction de vie pour survivre.

### Statistiques de Base
- **PV (Points de Vie)** : `80`
- **Mana de départ** : `5`
- **Armure de départ** : `0`
- **Attaque** : `15`
- **Défense** : `0.0` (Aucune réduction des dégâts)

### Compétences Spéciales
1. **Vampirisme (3 Tours)** : (Coût : **10% des PV Actuels**, CD : 4 tours) Lance une charge de Lifesteal (`lifestealDuration = 3`) sur le héros sans utiliser de Mana. Pendant les 3 prochains tours, `25%` des dégâts occasionnés *via l'attaque de base sur les cibles* sont aspirés et soignent les Points de vie du Héros.
2. **Perce-Armure (Vol 15%)** : (Coût : 3 Mana, CD : 3 tours) Lance une frappe brutale de `100%` de l'Attaque (comme une attaque normale) mais ce coup n'affecte pas l'Armure adverse : le coup frappe directement **les PV adverses**. En parallèle de la frappe, `15%` de l'armure totale qu'avait ce monstre sont convertis en statistiques d'Armure.

---

## Tableau des Récompenses de Draft et d'Améliorations

À la fin de chaque niveau d'ennemis vaincus, une interface apparaît pour proposer *une* amélioration au joueur parmi une sélection de 3 cartes tirées aléatoirement (chances égales) parmi le tableau de récompenses suivant :

1. **Vitalité** : +15 PV Max
2. **Aiguisage** : +5 Attaque
3. **Plaque de Fer** : +10 Armure
4. **Sagesse** : +5 Mana Max

*Note : Lors du gain de mana max par "Sagesse", le héros gagne également cette même valeur en mana actuel.*
