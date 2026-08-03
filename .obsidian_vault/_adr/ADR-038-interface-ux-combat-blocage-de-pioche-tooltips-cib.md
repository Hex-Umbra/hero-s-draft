## 🃏 ADR-038 : Interface UX Combat — Blocage de Pioche, Tooltips Ciblés, Étoiles de Forge et Double Jauge HP (v0.1.00)

### Statut
✅ Accepté & Implémenté

### Contexte
Quatre problèmes d'expérience utilisateur distincts avaient été identifiés dans le combat de Hero's Draft lors de l'analyse UX Section 1 :

1. **Interactions prématurées lors de la pioche** : Les cartes distribuées depuis la pioche vers la main étaient immédiatement interactables dès leur instanciation, avant même de rejoindre leur emplacement final dans l'arc. Cela causait des sauts de position et des désalignements lors d'un survol ou d'un glissement prématuré.
2. **Tooltips intempestifs et peu informatifs** : Les infobulles de cartes s'affichaient au simple passage de la souris, encombrant l'écran pendant les phases de lecture ou de planification. De plus, leur contenu n'incluait pas les améliorations de forge appliquées, forçant le joueur à quitter l'arène pour consulter ses cartes.
3. **Surcharge visuelle et polices surdimensionnées** : Les icônes vectorielles translucides en arrière-plan des cartes (épées, boucliers) généraient un bruit visuel gênant. Les tailles de polices étaient jugées trop imposantes pour le ratio d'aspect de la carte, rendant les textes difficiles à lire sur mobile.
4. **Barre de vie statique peu expressives** : La `PlayerHealthBar` était un `StatelessWidget` avec une simple mise à jour de largeur, sans animation. Les dégâts et les soins n'avaient aucun effet cinétique distinct, nuisant au feedback sensoriel et à l'immersion du combat.

### Décision

#### 1. Verrouillage Tactile de Pioche (`isEnteringHand`)
- Ajouter un drapeau public `bool isEnteringHand = false` dans `CardComponent`.
- Tous les handlers d'entrée (`onTapDown`, `onDragStart`, `onHoverEnter`, `onHoverExit`, `onDragUpdate`) effectuent une garde `if (isEnteringHand) return;` immédiate.
- Dans `HerosDraftGame._applyDeckState()`, les nouvelles cartes sont instanciées avec `isEnteringHand = true`.
- Dans `_layoutHand()`, si `card.isEnteringHand`, la durée du `MoveEffect` est portée à `0.7s` (au lieu de `0.35s`). Un callback `onComplete` réinitialise le drapeau à `false`.

#### 2. Cycle de Vie des Tooltips de Combat (Focus-Only)
- Remplacer le déclenchement au survol par un déclenchement uniquement sur sélection active de la carte.
- Câbler `game.onShowTooltip()` dans `HerosDraftGame.setFocusedCard()` lorsqu'une carte est focalisée.
- Câbler `game.onHideTooltip()` lors de la défocalisation, du jeu d'une carte, ou du changement de phase de combat.
- Dans `card_component.dart`, enrichir `_buildDetailedDescription()` pour itérer sur `card.card.forgeUpgrades` et les concaténer sous forme de liste à puces formatée.

#### 3. Rénovation Esthétique des Cartes (Flame & Flutter)
- **Réduction du bruit de fond** : Supprimer l'instanciation et l'appel à `bgIconPainter` dans `card_text_renderer.dart` (Flame). Supprimer les icônes transparentes `Center` dans `ui_card.dart` (Flutter).
- **Diminution des polices** : Réduire toutes les tailles de polices de 10% à 20% de manière proportionnelle pour assurer la lisibilité sur petits écrans :
  - Flame : Titre `12→10.5`, Rareté `8→7.0`, Badges `8→7.0`, Description `9→8.0`, Valeurs `18→15.0`, Icônes `27→22.0`.
  - Flutter : Titre `12→10.5`, Rareté `9→8.0`, Badge `8→7.0`, Description `9→8.0`, Valeurs `18→15.0`, Icônes `25→20.0`.
- **Étoiles de forge** : Dessiner une rangée d'étoiles proportionnelles à la capacité maximale de forge de la carte sous le label de rareté. Les étoiles pleines dorées (`★`) représentent les upgrades actifs, les étoiles vides (`☆`) représentent les slots disponibles restants.

#### 4. Double Jauge de Vie Animée (`PlayerHealthBar` Dual-Bar)
- Convertir `PlayerHealthBar` de `StatelessWidget` en `StatefulWidget`.
- Maintenir localement `_targetRatio` (ratio courant) et `_oldRatio` (ratio précédent avant mise à jour).
- Lors de la réception d'un nouveau ratio :
  - Si le ratio **diminue** (dégâts) : la jauge verte d'avant-plan chute instantanément, la jauge rouge d'arrière-plan anime via `TweenAnimationBuilder` (500ms, `Curves.easeOutCubic`).
  - Si le ratio **augmente** (soin) : la jauge verte d'avant-plan anime fluide vers le haut, la jauge rouge s'aligne immédiatement pour éviter tout artefact de traînée inversée.

### Preuves dans le code
- `lib/game/components/card_component.dart` : Champ `isEnteringHand`, gardes d'input, appel `_buildDetailedDescription()` avec inject des forge upgrades.
- `lib/game/components/widgets/card_text_renderer.dart` : Suppression de `bgIconPainter`, réduction des tailles de police, boucle de dessin Canvas des étoiles.
- `lib/game/heros_draft_game.dart` : Set `isEnteringHand = true` dans `_applyDeckState`, durée `0.7s` dans `_layoutHand`, appel `onShowTooltip`/`onHideTooltip` dans `setFocusedCard`.
- `lib/ui/widgets/ui_card.dart` : Suppression des icônes de fond, réduction des polices, rangée d'icônes Flutter `Icons.star`/`Icons.star_border` sous le label de rareté.
- `lib/ui/widgets/hud/player_health_bar.dart` : Conversion `StatefulWidget`, champs `_targetRatio`/`_oldRatio`, `TweenAnimationBuilder` 500ms `Curves.easeOutCubic`, rendu dual-stack.
- **Vérification** : `dart analyze` 0 erreur. Suite complète de 104 tests — 100% au vert.

### Conséquences
- ✅ **Game Feel Immersif et Réactif** : Les cartes distribuées ne génèrent plus de sauts ni de désalignements. La double jauge donne une sensation d'impact physique convaincante aux dégâts reçus.
- ✅ **Lisibilité et Clarté Tactique** : Les tooltips apparaissent uniquement quand le joueur a une intention de lecture, et incluent désormais les upgrades de forge pour des décisions informées. Les polices réduites améliorent la densité d'information sans surcharge.
- ✅ **Transparence Systémique** : La jauge d'étoiles de forge matérialise visuellement le potentiel restant de chaque carte, guidant les stratégies de forge et de fusion sans quitter l'arène.
- ✅ **Architecture Préservée (ADR-001)** : Toute la logique de ratio HP reste dans les providers Riverpod (`runProvider`). `PlayerHealthBar` ne fait qu'observer et animer. `CardComponent` n'héberge aucune logique de calcul.
- ⚠️ **Cohérence Duale Flame/Flutter** : La réduction de polices et le rendu d'étoiles étant implémentés en parallèle dans `card_text_renderer.dart` (canvas Flame) et `ui_card.dart` (widgets Flutter), toute modification future des tailles ou du style des étoiles devra être propagée dans les deux systèmes de rendu simultanément.
