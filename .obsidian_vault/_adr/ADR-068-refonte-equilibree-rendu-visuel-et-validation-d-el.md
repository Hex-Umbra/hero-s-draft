## 🎪 ADR-068 : Refonte Équilibrée, Rendu Visuel et Validation d'Éligibilité du Système d'Événements (v0.3.0)

### Statut
✅ Accepté & Implémenté (v0.3.0)

### Contexte
Avant cette refonte, le système d'événements ne comprenait que 2 rencontres narratives très basiques dans `events.json`. Plus grave encore, le jeu n'effectuait aucune vérification de sécurité sur les choix proposés. Un joueur pouvait sélectionner un choix infligeant des dégâts supérieurs à ses points de vie actuels (ex: sacrifier 15 PV alors qu'il n'en possédait que 10), provoquant une défaite subite ou un début de combat suivant dans un état mortel sans avertissement ni blocage. De même, les choix nécessitant de l'or pouvaient être cliqués sans fonds suffisants, et l'impact de chaque décision n'était indiqué que par de longs textes, nuisant à la lisibilité et à l'ergonomie globale.

### Décision
1. **Élargissement Narratif Bilingue** : Implémenter 5 rencontres narratives équilibrées dans `events.json` avec des titres, descriptions, choix et textes de résultats entièrement traduits en français et anglais :
   - `mysterious_altar` (L'Autel Mystérieux)
   - `goblin_merchant` (Le Marchand Fugitif)
   - `blessed_fountain` (La Fontaine Bénie)
   - `forgotten_tomb` (Le Tombeau Oublié)
   - `abandoned_camp` (Le Feu de Camp Abandonné)
2. **Safety Gate de Validation Métier (`isSelectable`)** : Déplacer la logique de validation des choix directement dans le modèle de données en ajoutant la méthode `isSelectable(currentHp, currentGold, currentMaxHp)` sur la classe `EventChoice` (`lib/models/data/event_data.dart`). Un choix est marqué comme non-sélectionnable si :
   - Les dégâts de l'action tueraient le héros (`currentHp <= damage`).
   - Le coût en or requis dépasse le solde du joueur (`currentGold < cost`).
   - La perte permanente de PV max réduit sa vitalité maximale à 0 ou moins (`currentMaxHp <= -val`).
3. **Désactivation Réactive de l'UI** : Dans `EventScreen`, évaluer dynamiquement l'éligibilité pour chaque option. Si `isSelectable` est faux, passer `onPressed: null` au bouton d'option pour bloquer les gestes tactiles/souris sous Flutter. Adapter le style graphique de l'option désactivée (opacité générale réduite à `0.55`, fond noir translucide, textes et badges compacts grisés).
4. **Signaux Visuels (Badges d'Actions)** :
   - Intégrer des badges d'actions compacts (`_buildCompactActionBadge`) directement dans les boutons de choix (ex: icône cœur rouge pour les PV, pièce d'or pour l'or) pour identifier les coûts/gains en un instant.
   - Présenter un volet récapitulatif animé via un `TweenAnimationBuilder` d'échelle élastique (500ms) affichant de grands badges d'effets après la résolution.
   - Intégrer une barre de statistiques (PV & Or) dynamique en haut de l'écran pour faciliter les comparaisons.

### Preuves dans le code
- [event_data.dart](../../lib/models/data/event_data.dart) :
  - Ajout de la méthode `isSelectable` sur `EventChoice` avec typage dynamique de `action.value` pour supporter les validations financières, de santé et de vitalité maximale.
- [event_screen.dart](../../lib/ui/screens/event_screen.dart) :
  - Câblage de `isSelectable` dans l'arbre de widgets.
  - Implémentation du style de désactivation réactif dans le widget privé `_EventOptionButton`.
  - Conception de `_buildCompactActionBadge` et `_buildActionBadge` pour le rendu visuel thématique et réactif.
  - Ajout des badges en direct pour les PV et l'or en haut de l'écran.
- [events.json](../../assets/data/events.json) :
  - Définition complète des 5 rencontres bilingues structurées et de leurs actions.

### Conséquences
- ✅ **Éradication des morts frustrantes** : Les choix infligeant des dégâts mortels sont physiquement bloqués, protégeant le joueur d'une fin de partie accidentelle hors combat.
- ✅ **Expérience utilisateur premium** : L'intégration de badges d'actions standardisés accélère la compréhension tactique sans alourdir la lecture.
- ✅ **Harmonisation visuelle et locale** : Les badges réutilisent le code de localisation du jeu, garantissant une traduction fluide (PV/HP, Or/Gold) tout en offrant des animations réactives qui renforcent l'aspect poli du titre.
- ✅ **Stabilité statique** : 0 erreur détectée sous `dart analyze` et passage complet de la suite de 108 tests unitaires.
