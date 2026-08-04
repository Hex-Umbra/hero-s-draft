### 2.6. Équilibrage Hybride, Budget de Menace et Réserve de Vagues

Pour offrir un défi adapté aux choix stratégiques du joueur tout en évitant la trivialisation ou le blocage, le jeu utilise un système d'équilibrage hybride :

1. **Mécanique de Difficulté Dynamique (DDA Hybride)** :
   La difficulté ajuste la composition des combats selon un budget de menace calculé en comparant la puissance réelle du joueur avec celle théoriquement attendue :
   - **Puissance Réelle du Joueur (`PlayerPower`)** : Évaluée en agrégeant ses PV max, son attaque permanente, son mana maximum, son nombre de reliques, et le nombre de cartes dans son deck principal :
     $$\text{PlayerPower} = \text{maxHP} + (\text{attaque} \times 10) + (\text{maxMana} \times 15) + (\text{relicsCount} \times 5) + (\text{playerCardsCount} \times 2.0)$$
   - **Puissance Attendue (`ExpectedPower`)** : Modèle de progression théorique basé sur le niveau du joueur et l'acte en cours :
     $$\text{ExpectedPower} = 145 + [(\text{playerLevel} - 1) \times 15] + [(\text{act} - 1) \times 20]$$
   - **Ajustement Amorti (`PowerModifier`)** : Un ratio de puissance amorti à $0.5$ pour éviter les sauts brusques de difficulté :
     $$\text{PowerRatio} = \frac{\text{PlayerPower}}{\text{ExpectedPower}}$$
     $$\text{PowerModifier} = 1.0 + (\text{PowerRatio} - 1.0) \times 0.5$$

2. **Budget de Menace du Combat (`FinalBudget`)** :
   Le budget théorique de base (`BaseBudget`) augmente avec le niveau du joueur et l'acte :
   $$\text{BaseBudget} = 40 + [(\text{playerLevel} - 1) \times 10] + [(\text{act} - 1) \times 25]$$
   Le budget final alloué au combat combine le budget de base, le modificateur de puissance dynamique, le multiplicateur lié au type de nœud, et un bonus fixe de $+10.0$ par acte au-delà de l'acte 1 pour permettre la génération de groupes d'ennemis plus fournis :
   $$\text{FinalBudget} = (\text{BaseBudget} \times \text{PowerModifier} \times \text{NodeMultiplier}) + [(\text{act} - 1) \times 10.0]$$
   *(Avec `NodeMultiplier` = 1.0 pour un combat normal, 1.5 pour un combat élite, et 2.0 pour un boss)*

3. **Système de Score de Menace (`CombatRating`)** :
   Chaque ennemi est doté d'une valeur de menace dynamique reflétant sa puissance réelle après application des multiplicateurs de scaling (niveau, acte, modificateur de nœud). Pour favoriser le surnombre (plus d'ennemis simultanés) et éviter qu'un unique ennemi sac à PV ne consomme tout le budget, le poids des PV bruts a été divisé par 4 et celui des dégâts a été doublé :
   $$\text{CombatRating} = (\text{tier} \times 15.0) + \frac{\text{HP\_Scalé}}{4.0} + (\text{Dégâts\_Scalés} \times 2.0) \times \left(1.0 + \frac{\text{critChance}}{100.0}\right)$$
   Le générateur choisit des candidats aléatoires dont la `CombatRating` est inférieure ou égale au budget restant, et déduit cette note du budget jusqu'à ce que plus aucun ennemi disponible ne rentre dans l'enveloppe budgétaire. Un fallback garantit au moins un ennemi si le budget est trop faible.

4. **Système de Réserve de Vagues (`pendingEnemies`)** :
   Pour éviter de surcharger le board visuel de Flame et limiter les calculs de ciblage, le nombre d'ennemis actifs affichés simultanément est limité à **5 slots maximum**.
   - Si le budget de menace permet de générer plus de 5 ennemis, les 5 premiers sont instanciés en tant qu'ennemis actifs sur le board (`enemies`), tandis que le reste est placé dans une file d'attente de réserve (`pendingEnemies`).
   - Lorsqu'un ennemi actif meurt en combat, le système vérifie s'il y a des ennemis en réserve. Si c'est le cas et que le nombre d'ennemis actifs est inférieur à 5, le premier ennemi de la file de réserve est immédiatement extrait, transféré sur le board actif, et doté de sa première intention de combat.
   - Le combat ne se termine par une victoire que lorsque la liste des ennemis actifs **ET** la liste de réserve sont entièrement vides.
