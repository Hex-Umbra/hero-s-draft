# Analyse des Améliorations : Système de World Map

**Date :** 15 Mai 2026
**Objectif :** Analyser les systèmes de navigation (World Map) des jeux roguelike majeurs (Slay the Spire, Monster Train, Rogue Lords, Inscryption) afin d'extraire des mécaniques et des concepts UI/UX pertinents pour améliorer la carte de "Hero's Draft".

---

## 1. Analyse des Références du Genre

### A. Slay the Spire (Le Standard)
*   **Structure :** Graphe Acyclique Dirigé (DAG) généré de bas en haut.
*   **Lisibilité :** La carte est entièrement visible dès le départ. Le joueur peut planifier sa route de l'étage 1 jusqu'au Boss.
*   **Mécaniques clés :**
    *   **Chokepoints (Étranglements) :** Des points de passage obligatoires forcent parfois le joueur à affronter un Élite ou à se reposer, ajoutant une pression stratégique.
    *   **Lisibilité des lignes :** Les chemins croisés sont évités au maximum pour ne pas rendre la carte brouillonne. Le tracé de la ligne active (chemin parcouru) est très clair.
    *   **Icônes distinctes :** Un code couleur et des formes très facilement identifiables.

### B. Monster Train (Le Choix Binaire Spécialisé)
*   **Structure :** Progression linéaire "Anneau par Anneau". À chaque étape, le joueur choisit entre deux voies ferrées (gauche ou droite).
*   **Lisibilité :** Prévisualisation des 2 anneaux suivants. On voit le boss final très tôt.
*   **Mécaniques clés :**
    *   **Choix synergique clair :** Un chemin propose "Amélioration Unité + Boutique", l'autre "Amélioration Sort + Événement". Le joueur choisit non pas un "chemin" complexe, mais une "opportunité" immédiate qui synergise avec son deck actuel.
    *   **Zéro hasard de navigation :** Pas de nœuds cachés, tout est question de trade-off (compromis).

### C. Rogue Lords / Inscryption (L'Interaction et le Mystère)
*   **Structure :** Chemins avec embranchements, parfois modifiables.
*   **Mécaniques clés :**
    *   **Rogue Lords (Pouvoirs du Diable) :** Le joueur incarne le Diable et peut dépenser une ressource (Essence spirituelle) pour *modifier* la carte, par exemple forcer l'apparition d'un repos au lieu d'un combat élite.
    *   **Inscryption (Carte en parchemin 3D) :** La carte est un objet physique (un parchemin déroulé sur une table). Le pion avance physiquement.
    *   **Événements contextuels sur la map :** Parfois, le pion s'arrête entre deux nœuds pour une embuscade ou un mini-événement textuel sans changer d'écran.

---

## 2. Pistes d'Amélioration pour "Hero's Draft" (Systèmes & Mécaniques)

Actuellement, notre génération est purement aléatoire étage par étage. Voici comment nous pouvons la rendre plus stratégique :

### A. Génération Dirigée (Smart Pathfinding)
*   **Chokepoints :** Générer intentionnellement des nœuds par lesquels *tous* les chemins doivent passer (ex: étage 5 ou 6). Cela force le joueur à se préparer pour un défi spécifique sans pouvoir l'esquiver.
*   **Règles de Spawn :**
    *   Interdire 3 nœuds Repos consécutifs.
    *   Garantir qu'il y a toujours un chemin "Sûr" (que des combats normaux) et un chemin "Risqué" (Élites + Boutiques).
    *   Forcer la présence d'un Repos juste avant le Boss.

### B. Fog of War (Brouillard de Guerre) vs Visibilité Totale
*   **Option 1 : Le Radar.** Seuls l'étage actuel et les 2 étages suivants sont visibles (les icônes sont affichées). Les étages au-delà montrent des nœuds "Inconnus" (point d'interrogation). Cela force l'adaptabilité.
*   **Option 2 : Information Payante.** Permettre au joueur de payer de l'or sur la MapScreen pour révéler le chemin d'un Boss ou d'un Élite.

### C. Interactions directes sur la carte (Map Actions)
*   **Consommables de Map :** Introduire des objets ou des reliques qui s'utilisent *sur la carte* (ex: "Clé de Donjon" pour ouvrir un chemin alternatif, "Longue-vue" pour scouter un chemin).
*   **Nœuds "Verrouillés" :** Certains chemins nécessitent de sacrifier des PV ou de l'or juste pour y entrer, mais mènent à un coffre garanti.

---

## 3. Pistes d'Amélioration (UI / Affichage / Overlay)

L'aspect visuel de la carte est crucial pour l'immersion. Notre `MapScreen` est fonctionnel mais manque de "Jus".

### A. Rendu Visuel et Esthétique
*   **Parallax & Fond dynamique :** Remplacer le fond uni (`Color(0xFF0D0D1A)`) par un fond en parchemin texturé ou une vue isométrique de dessus. Ajouter un léger mouvement de nuages ou de particules en arrière-plan.
*   **Lignes de connexion animées :** Remplacer les lignes pleines par des lignes en pointillés animées (qui défilent) indiquant la direction possible. Les chemins déjà parcourus pourraient devenir dorés ou brûlés.
*   **Pion du joueur :** Au lieu de simplement changer la couleur du nœud actuel, afficher un petit avatar ou un pion (ex: une tête de chevalier) qui se déplace physiquement (animation) d'un nœud à l'autre lors du clic.

### B. Interactions et Feedbacks
*   **Path Highlighting (Surbrillance de chemin) :** Au survol d'un nœud lointain (si atteignable), mettre en surbrillance tous les nœuds précédents nécessaires pour l'atteindre.
*   **Zoom fluide :** Activer le `scaleEnabled: true` sur le `InteractiveViewer`, mais avec des contraintes strictes (`minScale: 0.5`, `maxScale: 1.5`) pour permettre au joueur d'avoir une vue d'ensemble de l'acte complet.
*   **HUD de Map :** Afficher un tracker visuel en haut de l'écran (ex: "Étage 4 / 10") sous forme de barre de progression horizontale.

### C. Transitions et Menus (Overlays)
*   Les nœuds **Shop** et **Rest** sont souvent plus immersifs s'ils ne cassent pas le contexte. Au lieu de `Navigator.push` vers un nouvel écran opaque, ils pourraient apparaître sous forme de **Modal Bottom Sheet massive** ou de **Dialog stylisé** en surimpression de la carte (avec un effet de flou en arrière-plan), renforçant l'idée qu'on est juste en train de faire une pause sur le chemin.

---

## Conclusion et Proposition de Priorités

Pour "Hero's Draft", l'approche la plus impactante avec le meilleur ratio "Temps/Effet" serait de :

1.  **Priorité 1 (Juice & UI) :** Animer le déplacement d'un pion sur la carte, rendre les lignes de connexion dynamiques (pointillés qui défilent), et améliorer le fond (texture ou particules).
2.  **Priorité 2 (Génération) :** Implémenter des règles de génération (Chokepoints et Repos forcé avant le boss) pour donner une vraie courbe de tension à l'acte.
3.  **Priorité 3 (Immersion) :** Transformer le `ShopScreen` et le `RestScreen` en overlays (Dialogs géants ou BottomSheets) par-dessus la map plutôt que des écrans séparés.
