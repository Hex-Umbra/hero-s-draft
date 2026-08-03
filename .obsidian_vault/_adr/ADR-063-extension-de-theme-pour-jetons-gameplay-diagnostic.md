## 🎨 ADR-063 : Extension de Thème pour Jetons Gameplay & Diagnostic de Diagnostic Data (v0.2.3)

### Statut
✅ Accepté & Implémenté (v0.2.3)

### Contexte
1. Bien que le design system `AppColors` de la version v0.0.99 ait centralisé les couleurs, il manquait d'intégration avec le pipeline standard de thèmes Flutter, obligeant à importer `AppColors` directement plutôt que d'utiliser `Theme.of(context)`.
2. Le service de chargement de données `GameDataService` lisait les JSONs bruts sans try/catch verbeux en cas d'erreur de formatage, provoquant des crashs silencieux de l'application difficiles à déboguer lors des modifications de data par le game design.

### Décision
- **Extension de Thème `GameThemeExtension`** : Créer `GameThemeExtension` héritant de `ThemeExtension` contenant les couleurs de raretés de cartes, de statistiques de combat et de néons. L'enregistrer dans `AppTheme` pour les modes clair/sombre.
- **Diagnostics I/O robustes** : Ajouter des blocs try/catch verbeux dans `GameDataService` lors du parsing de chaque fichier JSON, produisant un log explicite identifiant le fichier exact en cas d'échec de parsing.

### Preuves dans le code
- [game_theme_extension.dart](file:///c:/Users/Gpdac/OneDrive/Documents/GameDev%20and%20Godot/Roguelike%20Card%20Game/roguelike_card_game/lib/ui/theme/game_theme_extension.dart).
- Intégration dans `lib/ui/theme/app_theme.dart`.
- Blocs try/catch explicites dans `lib/services/game_data_service.dart`.

### Conséquences
- ✅ **Intégration Standard Flutter** : L'accès aux couleurs du gameplay se fait de manière idiomatique via `Theme.of(context)`.
- ✅ **Débogage Instantané** : En cas d'erreur de formatage dans les JSONs de cartes ou de reliques, le développeur ou game designer identifie immédiatement la source dans la console de diagnostic.
