# Rapport d'Analyse et d'Évolution - Hero's Draft

## 1. Analyse du Projet Actuel
Le projet est un **Roguelike Card Game** solide combinant la puissance de **Flutter** pour l'UI et de **Flame** pour le rendu de jeu. L'architecture est saine, utilisant **Riverpod** pour une gestion d'état réactive et découplée. Le système est déjà **Data-Driven**, ce qui facilite l'extension du contenu via JSON.

### Points Forts :
*   **Système d'Auto-Merge** : Mécanique originale de montée en niveau des cartes (3 identiques = 1 supérieure).
*   **Architecture Hybride** : Utilisation judicieuse de Flame pour les animations de combat et Flutter pour les menus/HUD.
*   **Extensibilité** : La séparation claire entre modèles de données (JSON) et logique de jeu permet d'ajouter facilement des héros, ennemis et cartes.
*   **Feedbacks de Combat** : Intentions ennemies (telegraphing), textes flottants et animations de dash/buff déjà présents.

---

## 2. Axes d'Amélioration et Évolutions Possibles

### Axe A : Profondeur du Gameplay & Mécaniques de Combat
Pour sortir de la boucle "Dégâts / Armure", le jeu doit s'enrichir de variables stratégiques.
1.  **Système d'Altérations d'État (Buffs/Debuffs)** : 
    *   *Positif* : Régénération (soin par tour), Épine (renvoie des dégâts), Puissance (multiplicateur de dégâts).
    *   *Négatif* : Poison (dégâts sur la durée), Faiblesse (réduit les dégâts infligés), Vulnérabilité (augmente les dégâts subis).
2.  **Types de Cartes Spéciaux** : 
    *   *Cartes Pouvoir* : Effets permanents pour le reste du combat (ex: "Chaque fois que vous piochez, gagnez 1 Armure").
    *   *Cartes Malédiction* : Ajoutées au deck par certains ennemis pour polluer la main du joueur.
3.  **Reliques et Objets Passifs** : 
    *   Ajouter un système de "Reliques" obtenues sur les boss qui modifient les règles du jeu (ex: "Commencez chaque combat avec 2 points de mana supplémentaires").

### Axe B : Progression et Structure de Run
Actuellement, la progression semble être une suite de combats linéaires.
1.  **Carte de Navigation (World Map)** : 
    *   Inspirée de *Slay the Spire*, permettre au joueur de choisir son chemin entre des combats normaux, des élites, des événements aléatoires, des marchands et des feux de camp (repos).
2.  **Événements Aléatoires (Narratifs)** : 
    *   Rencontres textuelles offrant des choix cornéliens (ex: "Perdre 20 PV pour gagner une carte rare").
3.  **Système de Boutique** : 
    *   Introduire une monnaie (Or) pour acheter des cartes, supprimer des cartes inutiles du deck ou acheter des reliques.

### Axe C : Expérience Audio-Visuelle (Juice & Polish)
Le "Game Feel" est crucial pour l'immersion.
1.  **Identité Sonore** : 
    *   Musiques d'ambiance dynamiques (Calme en menu, Épique en combat, Sombre pour les Boss).
    *   Bruitages (SFX) : Impacts de coups, son de pioche de carte, validation de fin de tour.
2.  **Effets Visuels (VFX) Avancés** : 
    *   Particules Flame lors des attaques (étincelles, sang, magie).
    *   *Screen Shake* (secousse d'écran) subtil lors de gros impacts.
    *   Animations de transition entre les écrans plus fluides.
3.  **Amélioration de l'UI** : 
    *   **Combat Log** : Un petit historique textuel des actions effectuées.
    *   **Glossaire** : Pouvoir cliquer sur un mot-clé (ex: "Poison") dans un tooltip pour voir sa définition.

### Axe D : Méta-progression (Longévité)
Donner une raison au joueur de recommencer une partie après une victoire ou une défaite.
1.  **Déblocages Progressifs** : 
    *   Gagner de l'expérience par classe pour débloquer de nouvelles cartes spécifiques à cette classe lors des runs futures.
2.  **Encyclopédie / Collection** : 
    *   Un menu pour visualiser toutes les cartes et ennemis rencontrés.
3.  **Défis et Succès** : 
    *   Objectifs secondaires (ex: "Gagner un combat sans utiliser d'Armure").

### Axe E : Solidification Technique
Pour un projet qui grandit, la robustesse est clé.
1.  **Tests Automatisés** : 
    *   Implémenter des **Unit Tests** pour le `EffectResolver` et la logique de fusion des cartes.
    *   **Widget Tests** pour les écrans de sélection.
2.  **Optimisation des Assets** : 
    *   Passer par des *Sprite Sheets* (Atlas) pour réduire les appels de rendu (Draw Calls) dans Flame.
3.  **Internationalisation (i18n)** : 
    *   Préparer le support multi-langues, le système JSON actuel s'y prêtant très bien.

---

## 3. Recommandation de Priorités (Feuille de Route)

| Priorité | Tâche | Impact |
| :--- | :--- | :--- |
| **P0 (Urgent)** | **Audio & SFX** | Améliore instantanément la perception de qualité du jeu. |
| **P1 (Core)** | **Buffs/Debuffs** | Indispensable pour la profondeur tactique. |
| **P1 (Progression)** | **Boutique & Or** | Donne une utilité aux récompenses de combat. |
| **P2 (Design)** | **World Map** | Casse la linéarité et donne du contrôle au joueur. |
| **P3 (Meta)** | **Déblocages** | Fidélise le joueur sur le long terme. |
