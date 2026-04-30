## Phase 1 - Implémentation du système de données

- feat: implémentation Phase 1 
    - configuration des assets json et création des modèles de données (EnemyData, HeroData, SkillData)
        - J'ai terminé la Phase 1. Les fichiers JSON ont été créés, le pubspec.yaml a été mis à jour et les classes Dart (DTOs) ont été implémentées.
- feat: implémentation Phase 2 
    - création du service de chargement Riverpod (gameDataLoaderProvider) et synchronisation au démarrage via un SplashScreen
        - J'ai terminé la Phase 2. Le système de chargement via Riverpod est en place et attend que les fichiers JSON soient chargés avant d'afficher le menu principal.
- feat: implémentation Phase 3 
    - refactoring des ennemis pour utiliser EnemyData depuis le JSON
        - J'ai terminé la Phase 3. Les ennemis générés lors des combats utilisent maintenant strictement les données issues de enemies.json via le GameDataRegistry ! Le EncounterSystem et le EnemyCard ont été mis à jour en conséquence, et j'ai ajouté quelques ennemis d'exemple dans le JSON pour que ça fonctionne directement.
    

