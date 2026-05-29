## Phase 106 - Rénovation de la Localisation (i18n Absolue) — 2026-05-29

- refactor: Internationalisation absolue de la couche UI Flutter et découplage complet de la localisation des statuts de combat
    - **Centralisation des Ressources Multilingues (ARB)** :
        - Enrichissement de `lib/l10n/app_en.arb` et `lib/l10n/app_fr.arb` avec l'intégration systématique de clés pour le dictionnaire de cartes, les statuts, et les indicateurs d'effets d'événements.
        - Ajout des clés clés globales `"cardDictionary"` (Card Dictionary / Dictionnaire des Cartes) et `"statusCurses"` (STATUS / CURSES / STATUTS / MALÉDICTIONS).
        - Intégration de clés dynamiques de gains et pertes asynchrones d'événements avec placeholders numériques : `eventGainGold`, `eventSpendGold`, `eventLoseHp`, `eventGainHp`, `eventGainMaxHp`, `eventGainAttack`, et `eventGainRelic`.
        - Lancement et compilation robuste des ressources via `flutter gen-l10n`.
    - **Remplacement Nominal de `isFr` par `AppLocalizations` dans la couche UI** :
        - **`rest_screen.dart`** : Retrait du flag `isFr` local, remplacement de toutes les chaînes de feu de camp (Forge, Repos, Oubli) par des clés `AppLocalizations` fortement typées.
        - **`starter_deck_draft_screen.dart`** : Localisation bilingue complète de la constitution de deck, du compteur réactif de sélection de cartes et des dialogues d'avertissement.
        - **`card_dictionary_screen.dart`** : Remplacement nominal des en-têtes de catégorie, des types et cibles de cartes (`_getTargetLabel` et `_getTypeLabel`) par les délégués `AppLocalizations` correspondants.
        - **`class_selection_screen.dart`** : Remplacement des tooltips codés en dur par `l10n.cardDictionary`.
        - **`deck_screen.dart`** : Rénovation des dialogues de fusion de cartes et labels de rareté.
        - **`draft_screen.dart`** : Traduction dynamique bilingue des choix permanents d'augmentation de statistiques (Vitalité, Aiguisage, Sagesse, Forge d'Acier, Trèfle à 4 feuilles, Miroir) et du dialogue de clonage.
        - **`event_screen.dart`** : Restructuration complète de la méthode `_buildActionBadge` pour accepter un `BuildContext` et mapper dynamiquement chaque type d'effet de l'événement vers les traducteurs fortement typés d'AppLocalizations, éliminant définitivement toute chaîne brute.
    - **Découplage Logic-Rendu pour les Statuts de Combat** :
        - **`status_effects_panel.dart`** : Rénovation complète pour extraire et traduire les buffs et debuffs (Poison, Force, Faiblesse, Vulnérabilité, Métallisation/Régénération d'Armure, Éveil d'Attaque, Vol de vie) à la volée sur l'UI via `status.id` et `AppLocalizations` au lieu de coder les noms en dur dans le moteur ou les services métiers.
        - Nettoyage du fichier et suppression des variables inutilisées.
    - **Uniformisation et Résolution des Tests de Widgets** :
        - Migration de la configuration de locale dans `test/widget/starter_deck_draft_screen_test.dart` en lui injectant explicitement `locale: const Locale('fr', '')` pour garantir la validation parfaite des assertions textuelles réactives.
    - **Robustesse Statologique** :
        - Validation de la propreté statique totale du projet via `flutter analyze` : **0 avertissement, 0 erreur**.
        - Exécution de l'intégralité de la suite de tests automatisés via `flutter test` : **100% de réussite (58 tests passés avec succès !)**.

## Phase 107 - Optimisation du Démarrage & Navigation Robuste — 2026-05-29

- refactor: Parallélisation des I/O au chargement et unification de la navigation des nœuds en plein écran avec PopScope réactifs
    - **Optimisation des performances d'I/O au démarrage (Cold Start)** :
        - **`game_data_service.dart`** : Refactoring complet de `gameDataLoaderProvider`. Remplacement des 7 appels asynchrones séquentiels `await rootBundle.loadString(...)` par un unique appel de groupe parallélisé `Future.wait(...)`, éliminant tout blocage du fil d'exécution principal et améliorant le temps de Cold Start de façon significative.
    - **Unification de la Navigation des Nœuds** :
        - **`map_screen.dart`** : Suppression définitive de la méthode d'overlay dialog `_showNodeOverlay` et de son gestionnaire de fenêtres modales `showGeneralDialog`. Nettoyage des imports de widgets inutilisés (`blur_wrapper.dart`).
        - Refactoring de `_onNodeTap` pour rediriger uniformément et en plein écran toutes les destinations de la carte (`GameScreen`, `ShopScreen`, `RestScreen`, `EventScreen`) à l'aide de routes standard `MaterialPageRoute`.
    - **Sécurisation réactive de flux via PopScope** :
        - **`rest_screen.dart`** : Enveloppement du Scaffold par un `PopScope(canPop: _actionTaken)`. Empêche le joueur de quitter la zone de repos par un balayage arrière (swipe back) ou via le bouton physique sans avoir choisi une option de camp (soigner, forger, oublier) ou cliqué sur "CONTINUER LA ROUTE".
        - **`event_screen.dart`** : Enveloppement du Scaffold par un `PopScope(canPop: eventState.isResolved)`. Verrouille la navigation arrière tant que le choix d'événement n'est pas complètement validé.
        - **`shop_screen.dart`** : Enveloppement par un `PopScope(canPop: true)` assurant un comportement fiable et robuste du bouton physique de retour matériel vers la carte.
    - **Fiabilité et Assurance Qualité** :
        - Exécution et passage au vert de la suite de tests (`flutter test`) : **100% de réussite (58/58 tests validés)**.
        - Validation de la conformité statique du projet (`flutter analyze`) : **0 avertissement, 0 erreur**.
