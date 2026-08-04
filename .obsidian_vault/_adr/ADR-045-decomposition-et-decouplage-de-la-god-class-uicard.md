## 🛠️ ADR-045 : Décomposition et Découplage de la God Class `UiCard` (UiCard Decomposition & Decoupling)

### Statut
✅ Accepté & Implémenté (v0.2.01)

### Contexte
Le widget `UiCard` (`lib/ui/widgets/ui_card.dart`) est central pour l'affichage de toutes les cartes à jouer dans l'interface Flutter (menus, boutique, draft, dictionnaire). En raison des refontes esthétiques successives (v0.1.5), ce widget a accumulé de nombreuses responsabilités :
1. Analyse et parsing de la cible de la carte (`_resolveTarget`).
2. Résolution dynamique du type d'élément et des dégâts (`_determineDamageType`).
3. Mappage des icônes et couleurs d'effets (`_getEffectVisuals`).
4. Formatage et mise en page complexe de la description abrégée sous forme de badges (`_buildCompactDescription`).
5. Construction verbeuse de la description textuelle multilingue pour les infobulles / tooltips (`_buildDetailedDescription`).
6. Rendu visuel direct des fentes de runes, du médaillon de mana, et du type de carte.
7. Rendu et gestion d'animation personnalisée de la bordure polychromatique brillante au survol (`PolychromaticBorder` et son painter).

Cette concentration de logique et d'affichage au sein d'un seul fichier de plus de 1130 lignes violait le principe de responsabilité unique (SRP), créait une forte dette technique ("god component"), et rendait le composant difficile à maintenir et à faire évoluer.

### Décision
Décomposer et découpler `UiCard` en extrayant ses sous-composants visuels et ses fonctions logiques pures dans un sous-dossier dédié `lib/ui/widgets/ui_card/` :
1. **Création de `ui_card_helpers.dart`** : Centralisation de l'ensemble des fonctions pures et des mappages de données (résolution de cible, détection d'élément, couleur des types, couleurs de rareté, emojis de runes, et construction du texte détaillé pour le tooltip) afin d'isoler la logique du cycle de vie des widgets.
2. **Création de `polychromatic_border.dart`** : Encapsulation de la bordure animée (`PolychromaticBorder` et `_PolychromaticBorderPainter`), retirant la gestion du ticker de la classe principale.
3. **Création de `card_mana_medallion.dart`** : Extraction de l'indicateur circulaire de coût sous forme de widget autonome layout-agnostique.
4. **Création de `card_rune_sockets.dart`** : Extraction du widget de gestion et d'agencement multi-lignes des emplacements d'upgrades.
5. **Création de `card_compact_description.dart`** : Extraction du layout d'affichage abrégé des effets et des modificateurs de forge sous forme de widget dédié.
6. **Simplification de `ui_card.dart`** : Le widget principal sert de couche d'assemblage et de composition ("facade") pour ces sous-widgets. Son code est réduit de plus de 80% (de 1136 à ~175 lignes).
7. **Préservation de l'Interface Publique** : Conservation de l'exactitude du constructeur de `UiCard` et de ses paramètres originaux pour éviter toute modification des fichiers externes (boutique, draft, dictionnaire) qui l'instancient.

### Preuves dans le code
- `lib/ui/widgets/ui_card.dart` : Importe et compose `PolychromaticBorder`, `CardManaMedallion`, `CardRuneSockets` et `CardCompactDescription`. Le fichier ne contient plus aucune méthode de rendu privée ni calcul d'icône.
- `lib/ui/widgets/ui_card/` : Dossier contenant les 5 nouveaux fichiers extraits et découplés de manière modulaire.
- `test/widget/hud_and_targeting_badge_test.dart` et `test/widget/shop_screen_test.dart` : Passent sans modification des tests unitaires ni des widgets, prouvant le respect total de l'interface d'instanciation de `UiCard`.

### Conséquences
- ✅ **Respect du Single Responsibility Principle (SRP)** : Chaque sous-composant gère sa propre structure et logique, réduisant la complexité cognitive.
- ✅ **Facilité de Maintenance** : Le code de `UiCard` est réduit à ~175 lignes claires et lisibles. Toute modification future de l'affichage du coût, des sockets ou de la description se fera dans un fichier dédié.
- ✅ **Testabilité Accrue** : Les fonctions d'aide de `ui_card_helpers.dart` sont pures et isolées, facilitant leur test unitaire direct.
- ✅ **Zéro Régression** : La compatibilité de la signature du constructeur a garanti une intégration sans impact sur les 107 tests existants de l'application.
