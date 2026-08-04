## 🛠️ ADR-074 : Introduction de la Forge de Fusion Procédurale et Forge Pilotée par les Données (v3.1.0)

> [!NOTE]
> Renumeroté de `ADR-068` en `ADR-074` le 2026-08-03 : le numero `ADR-068` etait porte par deux decisions distinctes. Voir `docs/superpowers/specs/2026-08-03-documentation-overhaul-design.md` §2.1.

### Statut
✅ Accepté & Implémenté (v3.1.0)

### Contexte
Auparavant, le système de la Forge limitait le choix des améliorations (runes) applicables à une carte en excluant les runes déjà possédées (filtre `alreadyHas`). De plus, les descriptions et effets de runes étaient en partie codés en dur dans divers composants graphiques et textuels. Pour offrir plus de profondeur stratégique, permettre la spécialisation tactique des decks et centraliser la logique de configuration, le jeu nécessitait une architecture pilotée par les données (data-driven), le cumul libre des runes identiques, et l'introduction d'un mécanisme de fusion pour combiner les runes de même type de niveau inférieur vers un niveau supérieur.

### Décision
1. **Forge Pilotée par les Données (Data-Driven)** :
   - Externaliser toutes les améliorations de la Forge dans le fichier déclaratif `assets/data/forge_upgrades.json`.
   - Créer le modèle `ForgeUpgradeData` (`lib/models/data/forge_upgrade_data.dart`) qui parse ces données et fournit un registre statique d'accès direct `getById(id)`.
   - Charger ces données asynchrones via `GameDataService` et les stocker dans `GameDataRegistry`.

2. **Cumul des Runes et Non-Épuisement** :
   - Supprimer le filtre `alreadyHas` dans `ForgeUpgradeDialog` et `ShopController` pour autoriser le cumul de plusieurs améliorations du même type sur une même carte.
   - Adapter le pipeline de combat (`EffectResolver` et `CardTextRenderer`) pour additionner dynamiquement les cumuls de runes identiques en combat.
   - Mettre en œuvre le tirage pondéré dans la Forge classique basé sur les poids spécifiés dans le JSON.

3. **Atelier et Nœud de Forge de Fusion** :
   - Ajouter un nouveau type de nœud de carte stratégique `MapNodeType.forgeFusion` (emoji ⚙️/Layers).
   - Configurer le placement procédural du nœud de fusion dans `MapContentPlacer` avec une **probabilité de 25% par carte/map**, choisi aléatoirement sur un étage intermédiaire entre les **étages 3 et 7** (pour ne pas interférer avec le début, la pause obligatoire d'avant-boss ou les boss).
   - Afficher le nœud dans le panneau de légende de la carte (`MapLegend`) pour assurer l'information du joueur.
   - Créer l'écran `ForgeFusionScreen` permettant au joueur de fusionner ses runes identiques d'une carte (ex: `sharp:1` et `sharp:2` fusionnent en un unique `sharp:3` cumulé).
   - Facturer la fusion à un coût financier strict de :
     $$\text{Coût} = 80 \times (N - 1) \text{ Or}$$
     où $N$ est le nombre de runes fusionnées (ex: 80 Or pour fusionner 2 runes, 160 Or pour 3 runes).
   - Débiter l'or via `inventoryProvider` et mettre à jour le deck via `deckProvider.notifier.setForgeUpgrades(uniqueId, upgrades)`.

4. **Correction de la Navigation au Repos** :
   - Lors de l'annulation de la forge au feu de camp (fermeture de `ForgeUpgradeDialog` sans sélection), le joueur est reconduit à l'écran de sélection de cartes de repos au lieu d'être renvoyé directement au menu principal du feu de camp, fluidifiant l'expérience de navigation.

### Preuves dans le code
- `lib/models/data/forge_upgrade_data.dart` (structure de données).
- `lib/ui/screens/forge_fusion_screen.dart` (écran de fusion et calcul du coût en Or).
- `lib/ui/widgets/map/map_legend.dart` (affichage dans la légende de la carte).
- `lib/services/map/map_content_placer.dart` (placement du nœud à 25% sur étages 3-7).
- `lib/game/controllers/deck_controller.dart` (`setForgeUpgrades` pour la mise à jour immuable des runes).
- `test/unit/decoupled_forge_test.dart` (tests unitaires de fusion, cumul et probabilités).

### Conséquences
- ✅ **Game Design et Rejouabilité** : Possibilité de concevoir des cartes hautement personnalisées et spécialisées (ex: cartes d'armure pure ou cartes de gros dégâts cumulés), augmentant l'engagement tactique.
- ✅ **Maintenabilité accrue** : L'ajout, la modification ou le rééquilibrage de runes (poids, coûts, effets) se fait directement dans le JSON sans compilation.
- ✅ **Validation automatique** : Suite de tests de forge découplée étendue à 112 tests automatisés 100% au vert.
- ⚠️ **Équilibrage à surveiller** : La création potentielle de cartes "brisées" (overpowered) est contrebalancée par la rareté du nœud de Fusion (25% par map) et par le coût important en Or (80 Or par fusion).
