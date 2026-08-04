### 2.4. `EventController` (`eventProvider`)

**Provider** : `NotifierProvider<EventController, EventState>`

**Responsabilités** : `initializeEvent(events)` (pick aléatoire), `selectChoice(choice, RunController, InventoryController, allRelics)` — résout les actions séquentiellement : `gain_gold`, `spend_gold`, `take_damage`, `heal`, `gain_max_hp`, `gain_strength`, `gain_relic`.

**Roll de rareté de relique** (influencé par luck) : Legendary $1\% + \text{luck} \times 0.5\%$, Epic $5\% + \text{luck} \times 1\%$, Rare $14\% + \text{luck} \times 2\%$, Uncommon $20\% + \text{luck} \times 3\%$, Common = reste. Fallback vers common si aucune relique de la rareté tirée.

#### 🛠️ Architecture Technique et Validation d'Éligibilité
La refonte du système d'événements repose sur un découplage strict entre la structure de données declarative, la logique métier de validation, et le rendu d'interface réactif :

1. **Structure de Données Déclarative et Bilingue (`EventData` / `EventChoice` / `EventAction`)** :
   - Les événements sont sérialisés dans `assets/data/events.json` avec des clés bilingues strictes (`title_en`/`title_fr`, `description_en`/`description_fr`, `text_en`/`text_fr`, `result_text_en`/`result_text_fr`).
   - Le modèle `EventData` résout les textes dynamiquement en fonction du code de langue actif (`locale`).
   - La classe `EventAction` encapsule de manière générique le type d'action et sa valeur numérique (`value` typé `dynamic` pour supporter à la fois des entiers de dégâts/or ou des identifiants/quantités de reliques).

2. **Validation Métier Encapsulée dans le Modèle (`isSelectable`)** :
   - Plutôt que d'éparpiller les conditions de validation dans l'UI ou les contrôleurs, la logique d'éligibilité d'un choix est centralisée dans la méthode `isSelectable(currentHp, currentGold, currentMaxHp)` de `EventChoice` :
     ```dart
     bool isSelectable(int currentHp, int currentGold, int currentMaxHp) {
       for (final action in actions) {
         if (action.type == 'take_damage') {
           final damage = action.value as int;
           if (currentHp <= damage) return false; // Protection anti-mort subite
         } else if (action.type == 'spend_gold') {
           final cost = action.value as int;
           if (currentGold < cost) return false; // Protection financière
         } else if (action.type == 'gain_max_hp') {
           final val = action.value as int;
           if (val < 0 && currentMaxHp <= -val) return false; // Protection de vitalité
         }
       }
       return true;
     }
     ```
   - Cette centralisation assure que la règle est facilement testable de manière unitaire et cohérente sur toutes les plateformes.

3. **Verrouillage UI Réactif dans l'Écran (`EventScreen`)** :
   - Dans `EventScreen`, la construction des boutons de choix évalue dynamiquement cette éligibilité à chaque rendu, en observant l'état du héros (`runProvider`) et de l'inventaire (`inventoryProvider`) :
     ```dart
     final isSelectable = choice.isSelectable(currentPv, gold, maxPv);
     ```
   - Les boutons d'option (`_EventOptionButton`) adaptent leur comportement et leur style visuel en conséquence :
     - Si `isSelectable` est faux, `onPressed` reçoit `null`, ce qui désactive nativement le bouton Flutter (ignorant les interactions tactiles/souris).
     - L'opacité globale du bouton est réduite à `0.55`, son arrière-plan devient translucide (`Colors.black.withValues(alpha: 0.2)`), sa bordure s'estompe, et les badges d'actions compacts qu'il contient héritent d'une opacité réduite, signalant clairement le verrouillage à l'utilisateur.

4. **Rendu Visuel des Badges d'Actions (Composants Réutilisables)** :
   - **Badges Compacts (`_buildCompactActionBadge`)** : Utilisés directement dans les boutons de choix pour lister succinctement les effets (ex: `-15 PV`, `+50 Or`). Ils ont des dimensions réduites (hauteur 14, taille police 12) pour éviter tout débordement (RenderFlex overflow) dans les boutons multi-lignes.
   - **Badges de Résolution (`_buildActionBadge`)** : Grands badges détaillés affichés après la validation du choix dans un volet récapitulatif avec un effet d'échelle élastique via un `TweenAnimationBuilder` (500ms). Ils affichent des libellés localisés via `AppLocalizations` (ex: `eventLoseHp`, `eventGainGold`).
