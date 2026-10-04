### 2.4. `EventController` (`eventProvider`)

**Provider** : `NotifierProvider<EventController, EventState>`

**Responsabilités** : `initializeEvent(events)` (pick aléatoire) et `setEvent(event)`, qui tirent aussi la relique visée ; `selectChoice(choice, allRelics, {mockRoll, mockRelicIndex, sharpenTarget})` — résout les actions séquentiellement : `gain_gold`, `spend_gold`, `take_damage`, `heal`, `gain_max_hp`, `gain_might`, `gain_relic`, et, sur la branche de la vague 3 ([ADR-107](../_adr/ADR-107-trouvaille-et-progression.md), A19 à A22), `trade_relic`, `heal_percent`, `lose_hp_percent` et `sharpen_rune` ([`_rules/03-6`](../_rules/03-6-systeme-d-evenements.md)). `gain_strength`, que cette fiche nommait, est `gain_might` depuis ADR-097 — corrigé le 2026-10-04.

**Ce qu'E3 ajoute au contrôleur** (branche de la vague 3) :
- **`EventState.tradedRelic`** (`RelicData?`) — tirée une fois, à l'ouverture, par `_drawTradedRelic` : si l'événement porte un `trade_relic` et que l'inventaire n'est pas vide, une relique de plus petite `RelicRarity.index`, au hasard parmi les ex æquo ; `trade_relic` la cède par `RunController.loseRelic`, contre `EventAction.tradeGoldFor(rareté)` or.
- **`isChoiceSelectable(choice, runeCatalog)`** — **le seul calcul** de la condition d'un choix : les PV et l'or lus sur `runProvider` et `inventoryProvider`, `hasTradedRelic` sur la relique visée, `hasSharpenableRune` par `hasSharpenableRune(runeCatalog)` — une carte du master deck dont `ForgeRuneRules.hasSharpenableRune` est vrai sous `RunState.runeCapBonus`. L'écran l'appelle pour chaque bouton, avec le catalogue des runes du registre, et `hasSharpenableRune` pour nommer l'inactivité du *Rémouleur*.
- **`sharpenTarget`** — la paire (carte, rune) que le joueur a choisie dans la sélection sans or, avant l'appel ; `sharpen_rune` la monte par `DeckNotifier.raiseRuneLevel(…, levels: value, capBonus:)`.
- **`EventAction.fromJson` borne les valeurs des quatre types neufs** au chargement (`trade_relic` ≥ 0, les deux pourcentages de 1 à 100, `sharpen_rune` à 1) ; `EventChoice.fromJson` lit `requiresHpBelowPercent`, absent ou de 1 à 100.

**Roll de rareté de relique** (influencé par luck) : Legendary $1\% + \text{luck} \times 0.5\%$, Epic $5\% + \text{luck} \times 1\%$, Rare $14\% + \text{luck} \times 2\%$, Uncommon $20\% + \text{luck} \times 3\%$, Common = reste. Fallback vers common si aucune relique de la rareté tirée.

#### 🛠️ Architecture Technique et Validation d'Éligibilité
La refonte du système d'événements repose sur un découplage strict entre la structure de données declarative, la logique métier de validation, et le rendu d'interface réactif :

1. **Structure de Données Déclarative et Bilingue (`EventData` / `EventChoice` / `EventAction`)** :
   - Les événements sont sérialisés sous `assets/data/events/`, un fichier par événement, avec des clés bilingues strictes (`title_en`/`title_fr`, `description_en`/`description_fr`, `text_en`/`text_fr`, `result_text_en`/`result_text_fr`).
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
   - **Sur la branche de la vague 3, la signature devient** `isSelectable(currentHp, currentGold, currentMaxHp, {required bool hasTradedRelic, required bool hasSharpenableRune})` : la méthode lit aussi `requiresHpBelowPercent` (`PV × 100 < PV max × p`), `trade_relic`, `lose_hp_percent` (la règle de `take_damage`, sur le montant en pourcentage) et `sharpen_rune`. **Les deux faits neufs arrivent calculés** — `lib/models/` n'importe rien de `lib/game/`, et `ForgeRuneRules` y vit — ; requis, pour que l'analyseur désigne l'appelant oublié. L'extrait ci-dessus est la forme d'avant E3.

3. **Verrouillage UI Réactif dans l'Écran (`EventScreen`)** :
   - Dans `EventScreen`, la construction des boutons de choix évalue dynamiquement cette éligibilité à chaque rendu, en observant l'état du héros (`runProvider`) et de l'inventaire (`inventoryProvider`) :
     ```dart
     final isSelectable = choice.isSelectable(currentPv, gold, maxPv);
     ```
     Sur la branche de la vague 3, l'écran appelle `ref.read(eventProvider.notifier).isChoiceSelectable(choice, forgeUpgrades)` à la place, et regarde aussi le deck, pour que le bouton suive chacune des entrées.
   - **Le choix qui affûte** (`sharpen_rune`, branche de la vague 3) pousse d'abord `RestCardSelectionScreen(isSharpen: true, isFree: true)` ; la paire rendue va à `selectChoice` en `sharpenTarget`, `null` — annuler — ne résout rien.
   - **Le retour système** (branche de la vague 3, A22) : `canPop: false` et un `onPopInvokedWithResult` qui, le choix fait, appelle `_leave` — il résout le nœud, le mécanisme du feu et du Puits ; avant tout choix, rien.
   - Les boutons d'option (`_EventOptionButton`) adaptent leur comportement et leur style visuel en conséquence :
     - Si `isSelectable` est faux, `onPressed` reçoit `null`, ce qui désactive nativement le bouton Flutter (ignorant les interactions tactiles/souris).
     - L'opacité globale du bouton est réduite à `0.55`, son arrière-plan devient translucide (`Colors.black.withValues(alpha: 0.2)`), sa bordure s'estompe, et les badges d'actions compacts qu'il contient héritent d'une opacité réduite, signalant clairement le verrouillage à l'utilisateur.

4. **Rendu Visuel des Badges d'Actions (Composants Réutilisables)** :
   - **Badges Compacts (`_buildCompactActionBadge`)** : Utilisés directement dans les boutons de choix pour lister succinctement les effets (ex: `-15 PV`, `+50 Or`). Ils ont des dimensions réduites (hauteur 14, taille police 12) pour éviter tout débordement (RenderFlex overflow) dans les boutons multi-lignes.
   - **Badges de Résolution (`_buildActionBadge`)** : Grands badges détaillés affichés après la validation du choix dans un volet récapitulatif avec un effet d'échelle élastique via un `TweenAnimationBuilder` (500ms). Ils affichent des libellés localisés via `AppLocalizations` (ex: `eventLoseHp`, `eventGainGold`).
   - **Les badges d'E3** (branche de la vague 3) : `trade_relic` nomme la relique visée et l'or (`eventTradeRelic`, `eventGiveRelic`) ou dit « Aucune relique à céder » (`eventNoRelicToGive`) ; les deux pourcentages disent le montant calculé sur les PV max (`eventGainHp`, `eventLoseHp`) ; `sharpen_rune` dit « +1 niveau de rune » (`eventSharpenRune`), ou « Aucune rune à affûter » (`eventNoRuneToSharpen`) quand aucune rune ne peut monter. Les `case` vivent dans les deux variantes, compacte et de résolution.
