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
