## 8. Système de Tutoriel Autonome (Tutorial System)

Pour accompagner les nouveaux joueurs sans alourdir ou impacter le moteur de combat principal et l'état Riverpod global du jeu, un système de tutoriel entièrement autonome et auto-suffisant a été implémenté.

### 8.1. Architecture découplée et autonome

- **Emplacement dédié** : Le dossier `lib/tutorial/` regroupe l'intégralité du code du tutoriel (moteur, données, écran d'accueil, et widgets d'étapes).
- **Zéro dépendance Riverpod** : Pour éliminer le risque d'effets de bord avec la run de production, le tutoriel n'utilise aucun provider Riverpod (pas de `runProvider`, `deckProvider` ou `combatProvider`).
- **Moteur local (`TutorialEngine`)** : Un simple `ChangeNotifier` Dart gère l'état courant et la transition pas-à-pas.
- **État simulé (`TutorialMockState`)** : L'état contient des POJOs simplifiés (`TutorialCard`, `TutorialEnemy`) simulant les PV du héros (80/80), son mana (3/3), son armure, sa main, son deck, et un ennemi factice avec ses intentions. L'état est réinitialisé et préparé différemment pour chaque étape spécifique du tutoriel.

### 8.2. Déroulement en 13 Étapes Progressives

Le tutoriel se présente sous la forme d'un `PageView` non-swipeable, où la progression est bloquée ou validée par des interactions spécifiques :
1. **Accueil (Welcome)** : Introduction avec logo animé et résumé du jeu.
2. **Carte (World Map)** : Présentation de la carte sous forme de mini-carte interactive avec des bulles d'aide explicatives.
3. **Nœuds (Node Types)** : Explication didactique des 6 types de salles (Combat, Élite, Boutique, Repos, Événement, Boss).
4. **Combat (Combat Overview)** : Visualisation statique annotée d'une zone de combat (Héros, Ennemis, Deck, Compétences).
5. **Mana & Cartes (Cards & Mana)** : Apprentissage des coûts en mana et des types de cartes. Le joueur doit toucher les cartes pour voir les modifications de focus.
6. **Jouer une Carte (Play Card)** : Première phase active. Le joueur doit jouer des cartes (Frappe Basique) pour entamer les points de vie d'un Slime d'entraînement, avec déclenchement de textes flottants de dégâts.
7. **Dégâts & Armure (Armor & Damage)** : Démo comparative. Le joueur subit des dégâts avec et sans armure pour voir l'impact visuel de l'absorption par l'armure.
8. **Statuts Élémentaires (Status Effects)** : Galerie interactive détaillant le Poison, la Brûlure, le Gel, et l'Électrocution.
9. **Intentions Ennemies (Enemy Intents)** : Décryptage des icônes d'intentions affichées au-dessus des ennemis (Attaque, Défense, Buff).
10. **Fusion de Cartes (Merge)** : Démo interactive de la fusion 3-en-1. Le joueur fusionne 3 cartes identiques pour obtenir une version de rareté supérieure avec transfert d'améliorations.
11. **XP & Niveaux (XP & Level Up)** : Accumulation d'expérience interactive jusqu'au passage de niveau du héros.
12. **Draft (Reward Draft)** : Simulation de draft de fin de combat avec effets de survol/sélection dorée et scale-up (identique au jeu de production).
13. **Reliques (Relics Carousel)** : Présentation des reliques passives de combat avec défilement de carrousel.

### 8.3. Internationalisation et Persistance

- **i18n Intégrée** : Pour respecter les règles de bilinguisme, le modèle `TutorialStepData` intègre ses propres champs doublés (`titleEn`/`titleFr`, `bodyEn`/`bodyFr`). La sélection de la langue est résolue dynamiquement à l'affichage via `Localizations.localeOf(context).languageCode`.
- **Persistance (`SharedPreferences`)** : L'état de complétion du tutoriel est stocké par le service `TutorialProgressService` sous la clé `tutorial_completed`.
- **Badge "NEW" sur l'Accueil** : L'écran d'accueil (`HomeScreen`) affiche un badge "NEW" rouge et brillant à côté du bouton "TUTORIEL" tant que le joueur ne l'a pas terminé. Une fois le tutoriel complété au moins une fois, le badge disparaît définitivement. Le tutoriel reste rejouable à l'infini pour réviser les bases.
