# Liste des Tâches - Améliorations de Forge & Fusion

- [x] Étape 1 : Création du fichier de données JSON `assets/data/forge_upgrades.json`
- [x] Étape 2 : Création du modèle `ForgeUpgradeData` dans `lib/models/data/forge_upgrade_data.dart`
- [x] Étape 3 : Chargement des données dans `GameDataService` et mise à jour de `GameDataRegistry`
- [x] Étape 4 : Modification de `ForgeUpgradeDialog` et `ShopController` pour enlever les exclusions d'épuisement et utiliser les probabilités du JSON (tirage pondéré)
- [x] Étape 5 : Mise à jour de l'affichage des améliorations dans `ForgeSlotRow`, `CardTextRenderer` et `DeckScreen` (localisé et data-driven)
- [x] Étape 6 : Ajout du nœud de Fusion (`MapNodeType.forgeFusion`) dans la génération de carte avec 25% de probabilité
- [x] Étape 7 : Ajout de la navigation et rendu graphique du nœud de Fusion sur la carte
- [x] Étape 8 : Création de la page `ForgeFusionScreen` avec le coût de 80 Or par fusion d'améliorations identiques
- [x] Étape 9 : Ajout de tests unitaires dans `test/unit/decoupled_forge_test.dart` et vérification globale
