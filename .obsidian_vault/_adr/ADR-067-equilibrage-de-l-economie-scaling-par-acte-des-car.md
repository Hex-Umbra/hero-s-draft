## 🛒 ADR-067 : Équilibrage de l'Économie, Scaling par Acte des Cartes en Boutique et Réinitialisation du Miroir Magique (v0.2.9)

### Statut
✅ Accepté & Implémenté (v0.2.9)

### Contexte
Avant cette version, les cartes proposées à la vente dans la boutique étaient stockées sous forme de données statiques `CardData`. Leurs raretés et leurs améliorations de forge étaient fixes, et leur tarification était peu dynamique et décorrélée de l'avancement du joueur dans les Actes. Le Magic Mirror (Service de clonage) était également exploitable car son prix de 150 Or demeurait constant, permettant de cloner ses meilleures cartes à l'infini tant que l'or le permettait. L'affichage des cartes en vente n'indiquait pas leurs runes ni leur rareté visuelle car il utilisait le factory `UiCard.fromData` au lieu de l'instance dynamique.

### Décision
1. **Instances Réelles de Cartes (`CardInstance`)** : Migrer la liste `cardsForSale` de `List<CardData>` à `List<CardInstance>` dans `ShopState`. Remplacer le rendu par `UiCard.fromInstance` dans `ShopScreen` pour afficher visuellement les fentes de runes et la rareté dynamique de la carte.
2. **Tarification Organique Dynamique** : Instaurer une formule dynamique calculée par le contrôleur de boutique `ShopController.getCardPrice(CardInstance)` :
   - Prix de base basé sur la rareté finale : Commun (25 Or), Peu Commun (50 Or), Rare (100 Or), Épique (150 Or), Légendaire (200 Or).
   - Surcoût de forge : +20 Or par rune d'amélioration présente sur la carte.
3. **Scaling Temporel par Acte** :
   - Tirage de rareté dynamique basé sur l'Acte courant : chances de cartes de rareté élevée (Rare, Épique, Légendaire) accrues dans les Actes supérieurs.
   - Génération d'upgrades aléatoires pré-forge à partir de l'Acte 2 : les cartes ont des chances croissantes de comporter des améliorations tirées au sort de façon compatible avec leur type (Attaque, Compétence, Pouvoir).
4. **Nerf du Miroir Magique** : Pour limiter le clonage abusif, doubler le prix du Miroir Magique à chaque achat effectué lors de la même session boutique : $150 \rightarrow 300 \rightarrow 600 \rightarrow 1200 \dots$ Or.
5. **Réinitialisation en Sortie de Session** : Remettre le prix du Miroir à sa base de 150 Or et le compteur d'achats `clonePurchasedCount` à 0 dès que le joueur quitte la boutique (via l'action de fermeture ou de réinitialisation de boutique `clearCloneOptions`).

### Preuves dans le code
- [shop_state.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/models/shop_state.dart) : stockage de `cardsForSale` en `List<CardInstance>`, ajout de `clonePurchasedCount` et getter `clonePrice`.
- [shop_controller.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/game/controllers/shop_controller.dart) : calcul dynamique des prix dans `getCardPrice`, génération procédurale des cartes avec raretés/upgrades selon l'Acte dans `_generateShopCardInstance` et `_rollRandomUpgrade`, mise à jour de `buyCard`, `cloneCard` (incrément du compteur) et `clearCloneOptions` (reset du compteur).
- [shop_screen.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/screens/shop_screen.dart) : modification de `_buyCard` pour recevoir `CardInstance`, utilisation de `UiCard.fromInstance` pour l'affichage visuel, retrait du prix codé en dur au profit de `clonePrice` réactif du state.

### Conséquences
- ✅ **Économie plus organique et équilibrée** : La boutique scale naturellement avec le niveau de la run et propose des opportunités stratégiques fortes (cartes déjà améliorées ou rares à prix élevé).
- ✅ **Éradication des exploits de clonage** : Le doublement géométrique du prix du miroir limite le clonage infini.
- ✅ **Cooptation visuelle** : Les cartes affichent fièrement leurs sockets de runes et contours foil dynamiques directement dans la grille de vente, en cohérence avec le reste du jeu.
- ✅ **Validation et Zéro Régression** : Code vierge d'erreurs sous `dart analyze` et suite de tests validée avec 100% de réussite.
