### 2.4. Progression de Rareté Dynamique et Fusion Interactive

La progression des cartes s'effectue via des raretés dynamiques (`common` → `uncommon` → `rare` → `epic` → `legendary`), chacune appliquant un coefficient multiplicateur sur les statistiques de base de dégâts et d'armure de la carte.

La fusion de cartes 3-en-1 est gérée par `DeckNotifier.mergeCards(selectedIds, inheritedUpgrades)` :
1. Le joueur sélectionne 3 exemplaires d'une carte ayant la même rareté active.
2. Les 3 copies sont supprimées du `masterDeck`.
3. Une nouvelle copie de rareté directement supérieure est ajoutée au `masterDeck`.
4. **Héritage des Améliorations de Forge** : Les upgrades de même ID voient leurs Tiers additionnés (ex: deux upgrades `sharp:1` fusionnent en un unique `sharp:2`). Le nombre d'améliorations final est limité par la capacité maximale de la nouvelle rareté (`baseMaxForgeUpgrades + rarityIndex`). Le joueur choisit de manière interactive les upgrades qu'il souhaite hériter en cas de dépassement de la capacité.
5. **Restriction de la Rareté Unique** : Les cartes de rareté `unique` (de classe) ne peuvent pas être fusionnées. La logique de fusion est bloquée dans `deck_controller.dart` et l'interface utilisateur n'affiche pas l'option de fusion pour ces cartes.
