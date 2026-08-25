# Audit Responsive — Jouabilité sur Téléphone et Tablette

> **Date :** 05/08/2026 · **Périmètre :** `lib/` (169 fichiers, 36 343 lignes) · **Méthode :** analyse statique + calcul de géométrie de mise en page par appareil.
> **Question posée :** le jeu, pensé mobile puis dérivé vers le desktop, est-il encore jouable sur un écran de téléphone ou de tablette ?

---

## 1. Verdict

| Plateforme | État | Résumé |
|:---|:---|:---|
| **Desktop / Web bureau** | ✅ Jouable | Cible de fait du développement. |
| **Tablette (paysage)** | ✅ Jouable | ≥ 1000 px de large : aucun débordement calculé. |
| **Tablette (portrait)** | 🟠 Dégradé | 820 px : le combat tient, la boutique tient, mais les panneaux latéraux HUD occupent 62 % de la largeur. |
| **Téléphone (paysage)** | 🔴 Cassé | Hauteur ~390 px : débordements verticaux non défilables (accueil, événement, carrousel de relique). |
| **Téléphone (portrait)** | 🔴 Injouable | **2 cartes sur 5 hors écran en combat**, deux panneaux HUD superposés sur 147 px, débordement dur dans la boutique et l'AppBar de la carte. |

**Le portrait téléphone — l'orientation naturelle du support et celle qu'aucune configuration ne bloque — est le cas le plus dégradé du jeu.** Ce n'est pas une question de finition : la main du joueur est partiellement invisible et deux panneaux d'information se recouvrent l'un l'autre.

Nuance importante : le projet n'est pas dépourvu de code responsive. Il en contient, mais **concentré dans les zones les plus récentes** (tutoriel, barre de vie, grilles de cartes) et **absent des zones les plus anciennes et les plus critiques** (arène de combat Flame, boutique, carte du monde). Le responsive n'a pas été « perdu » uniformément : il a été appliqué à ce qui a été retouché après coup, et jamais rétro-appliqué au cœur.

---

## 2. La cause racine : un facteur d'échelle aveugle à la largeur

Toute l'arène de combat Flame dérive d'une seule ligne — `lib/game/heros_draft_game.dart:46` :

```dart
double get scaleFactor => (size.y / 800).clamp(0.85, 2.5);
```

**L'échelle du jeu dépend de la hauteur seule.** Or en portrait, la hauteur est la *grande* dimension. Un iPhone 15 (393 × 852) obtient donc `scaleFactor = 1.07` — c'est-à-dire *plus grand* qu'un iPad en paysage (1180 × 820 → 1.02) — alors qu'il a trois fois moins de largeur disponible.

Ce facteur pilote **17 sites d'appel** : taille des cartes, des ennemis, du héros, espacement, animations. Le rayon de l'éventail de la main est lui aussi proportionnel à la hauteur (`layout_system.dart:13`, `radius = game.size.y * 1.5`). Résultat : plus l'écran est haut et étroit, plus la main s'étale horizontalement.

### 2.1 Débordement calculé de la main (5 cartes)

Géométrie exacte reproduite depuis `LayoutSystem.layoutHand()` :

| Appareil | Échelle | Taille carte | Éventail (gauche…droite) | Écran | **Hors écran** |
|:---|---:|---:|---:|---:|---:|
| iPhone SE 3 portrait | 0.85 | 105 × 147 | −24 … 399 | 375 | **49 px** |
| Galaxy S8 portrait | 0.93 | 114 × 160 | −54 … 414 | 360 | **108 px** |
| iPhone 14/15 portrait | 1.06 | 131 × 184 | −73 … 466 | 393 | **145 px** |
| Pixel 7 portrait | 1.14 | 141 × 197 | −83 … 495 | 412 | **166 px** |
| iPhone 14 paysage | 0.85 | 105 × 147 | 280 … 572 | 852 | 0 |
| iPad 10.9 portrait | 1.48 | 182 × 254 | 37 … 783 | 820 | 0 |
| Desktop 1080p | 1.35 | 166 × 233 | 619 … 1301 | 1920 | 0 |

Sur un Pixel 7, la carte de gauche déborde de 83 px et celle de droite de 83 px : **les deux cartes d'extrémité sont coupées à plus de moitié**. Elles restent techniquement jouables (le glisser-déposer fonctionne depuis la partie visible), mais leur coût en mana, leur nom et leur illustration sont illisibles.

Le calcul est stable : au-delà de 4 cartes, l'angle total est ramené à ~0,4 rad quel que soit le nombre de cartes, donc l'étalement horizontal reste constant à `±0,2 × hauteur`. **Le problème ne s'atténue pas avec plus de cartes, il est structurel.**

### 2.2 Écrasement des ennemis

`repositionEnemies()` compense en écrasant les sprites :

| Appareil | Échelle appliquée aux ennemis | Largeur sprite rendue |
|:---|---:|---:|
| Galaxy S8 portrait | **50 %** | 67 px |
| iPhone 14/15 portrait | **47 %** | 73 px |
| Pixel 7 portrait | **46 %** | 77 px |
| iPad portrait | 71 % | 153 px |
| Desktop 1080p | 100 % | 196 px |

Le mécanisme de secours fonctionne (rien ne déborde), mais à 46 % un ennemi mesure 77 px de large. Ses badges de statistiques (`badgeHpSize = 130 × 16`, `badgeStandardSize = 48 × 22` dans `game_constants.dart`) sont réduits d'autant : la barre de PV fait 60 px de long et 7 px de haut. **Les intentions et les PV ennemis deviennent illisibles sur téléphone**, ce qui casse la lecture tactique — le cœur d'un deckbuilder au tour par tour.

### 2.3 Texte des cartes

`card_text_renderer.dart` utilise des tailles de police de 7 à 8 pt pour les descriptions, multipliées par `scaleFactor × 0.88`. Sur téléphone (0,75 effectif) une description rend à **~6 px logiques** ; sur desktop (1,19) à ~9,5 px. Le texte des cartes est donc ~37 % plus petit sur l'appareil où l'écran est le plus proche des yeux mais le plus petit.

---

## 3. Le HUD de combat : collisions d'ancrages absolus

Le HUD Flutter superposé au jeu Flame est positionné en pixels absolus depuis les bords, sans aucune connaissance de la largeur disponible.

### 3.1 Superposition des deux panneaux d'information

`combat_side_panels.dart` place :
- `StatusEffectsPanel` (**largeur fixe 250**, `status_effects_panel.dart:15`) à `bottom: 80, left: 20`
- `EnemyIntentsPanel` (**largeur fixe 250**, `enemy_intents_panel.dart:17`) à `bottom: 80, right: 20`

Il faut donc **540 px de large minimum** pour qu'ils ne se touchent pas.

| Appareil | Statuts occupe | Intentions occupe | **Chevauchement** |
|:---|---:|---:|---:|
| Galaxy S8 portrait (360) | 20…270 | 90…340 | **180 px** |
| iPhone SE 3 portrait (375) | 20…270 | 105…355 | **165 px** |
| iPhone 14/15 portrait (393) | 20…270 | 123…373 | **147 px** |
| Pixel 7 portrait (412) | 20…270 | 142…392 | **128 px** |
| iPad portrait (820) | 20…270 | 550…800 | 0 |

Sur tout téléphone en portrait, **le panneau des intentions ennemies est dessiné par-dessus le panneau des buffs du joueur**, avec des fonds opaques (`withAlpha(240)`). L'un des deux est purement et simplement masqué. Ces deux panneaux sont les seules sources d'information sur ce que l'ennemi s'apprête à faire et sur les effets actifs — sans eux, le combat se joue à l'aveugle.

De plus, à `bottom: 80` ils remontent jusqu'à ~200 px du bas selon leur contenu, c'est-à-dire **par-dessus l'éventail de cartes** (centré à 77 % de la hauteur).

### 3.2 Le bouton « Fin de tour » au milieu du plateau

`turn_control_panel.dart` : quatre éléments de **largeur fixe 170**, ancrés `right: 20`, verticalement centrés.

| Appareil | Part de la largeur d'écran occupée |
|:---|---:|
| Galaxy S8 (360) | **47 %** |
| iPhone 14/15 (393) | **43 %** |
| Pixel 7 (412) | **41 %** |
| Desktop 1080p | 9 % |

Le héros est dessiné au centre à 51 % de la hauteur (`heros_draft_game.dart:181`), avec une largeur rendue de ~166 px sur iPhone 15 — il occupe donc x ∈ [113, 280]. Le bouton occupe x ∈ [203, 373] à la même hauteur : **le bouton « Fin de tour » recouvre le flanc droit du héros**, ainsi que l'avertissement de mana et le compteur de tour empilés au même endroit.

**Bug secondaire :** ce panneau calcule sa position verticale avec `MediaQuery.of(context).size.height / 2` alors qu'il est enfant d'une `SafeArea` (`game_screen.dart:456`). Sur un téléphone à encoche, le centre réel de la zone sûre est ~40 px plus haut que `screenHeight / 2` : le bouton est systématiquement décalé vers le bas. Même défaut de raisonnement dans `CombatTooltipOverlay` (`bottom: 270` en dur) : en paysage téléphone (hauteur utile ~340 px), l'infobulle se retrouve à 70 px du haut, **par-dessus les ennemis** placés à 21 % de la hauteur.

### 3.3 Ce qui fonctionne dans le HUD

`game_screen.dart:440-445` contient la seule adaptation explicite du combat :

```dart
final bool isMobile = screenWidth < 600;
final double hudHeight = (baseHudHeight * textScaleFactor).clamp(88.0, 140.0);
final double hudWidth  = isMobile ? screenWidth * 0.90 : screenWidth * 0.52;
```

Et `player_health_bar.dart` est le meilleur widget du projet sur ce plan : `textScalerOf`, largeur proportionnelle bornée (`(screenWidth * 0.26).clamp(120, 300)`), `Wrap` pour les statistiques, `FractionallySizedBox` pour les remplissages, `Expanded` symétriques pour le centrage. `ManaIndicator` réduit la taille des cristaux au-delà de 5 (`(24 * 5 / total).clamp(12, 24)`) et utilise un `Wrap`. **C'est le patron à généraliser** — il existe déjà, il n'a simplement jamais été étendu au reste du HUD.

---

## 4. Écran par écran

Relevé mécanique : présence d'une détection de taille (`MediaQuery.size` / `LayoutBuilder`), de conteneurs défilables, et nombre de dimensions codées en dur.

| Écran | Détection taille | Défilables | Dimensions figées | Verdict téléphone |
|:---|:---:|:---:|:---:|:---|
| `shop_screen` | **0** | 6 | **21** | 🔴 Débordement dur |
| `map_screen` | 1 | 0 | 2 | 🔴 Débordement dur (AppBar) |
| `game_screen` + HUD | 1 | 0 | ~10 | 🔴 Collisions |
| `event_screen` | **0** | 3 | **20** | 🟠 Déborde en paysage |
| `relic_exchange_screen` | **0** | 3 | 16 | 🟠 |
| `home_screen` | **0** | **0** | 9 | 🟠 Déborde en paysage |
| `relic_carousel_screen` | **0** | **0** | 4 | 🟠 Déborde en paysage |
| `patch_notes_screen` | **0** | 1 | 10 | 🟠 |
| `rest_screen` | **0** | **0** | 4 | 🟠 (option large de 320) |
| `card_dictionary_screen` | **0** | 5 | 7 | 🟢 (grilles adaptatives) |
| `deck_screen` | **0** | 3 | 8 | 🟢 (grilles adaptatives) |
| `boss_card_draft_screen` | **0** | 1 | 1 | 🟢 |
| `class_selection_screen` | 2 | 2 | 6 | ✅ Adapté |
| `draft_screen` | 2 | 2 | 1 | ✅ Adapté |
| `forge_fusion_screen` | 1 | 2 | 17 | ✅ Adapté (bascule 760 px) |
| `starter_deck_draft_screen` | 1 | 1 | 1 | ✅ Adapté |
| `rest_card_selection_screen` | 1 | 1 | 1 | ✅ Adapté |
| `tutorial/` (14 fichiers) | 12 | oui | — | ✅ Le mieux adapté du projet |

### 4.1 Boutique — débordement arithmétique certain

`shop_screen.dart:316` impose une **colonne double desktop sans repli** :

```
Padding(20) → Row[ Expanded(flex: 3), VerticalDivider(width: 40), Expanded(flex: 1) ]
```

Largeur de la barre latérale = `(largeur_écran − 40 − 40) / 4`. Elle contient des `_ShopServiceWidget` de **largeur fixe 130** (`shop_screen.dart:525`) :

| Écran | Barre latérale disponible | Enfant | **Débordement** |
|:---|---:|---:|---:|
| 360 px | 70 px | 130 px | **60 px** |
| 393 px | 78 px | 130 px | **52 px** |
| 412 px | 83 px | 130 px | **47 px** |
| 820 px (iPad portrait) | 185 px | 130 px | ✅ |

C'est la bande jaune et noire « RenderFlex overflowed » garantie sur tout téléphone. Le titre « Services » à `fontSize: 24` dans 78 px est illisible par-dessus le marché, et les cartes en vente (`SizedBox(width: 150)`) tiennent tout juste dans les 235 px de la colonne principale, une par ligne.

### 4.2 Carte du monde — AppBar impossible et zoom désactivé

`map_screen.dart:182` : `leadingWidth: 430`.

**430 px de zone « leading » sur un écran de 360 à 412 px.** Le slot du widget de gauche est à lui seul plus large que l'écran entier, avant même le titre centré (« Carte du Monde - Acte N ») et les deux actions (or + pause). Débordement dur de la barre d'application dès l'ouverture de la carte.

Deuxième problème, plus grave pour le jeu : `map_screen.dart:218` désactive le zoom.

```dart
InteractiveViewer(
  boundaryMargin: const EdgeInsets.all(2000),
  minScale: 0.1,
  maxScale: 2.0,
  scaleEnabled: false,   // ← le pincer-pour-zoomer est coupé
  constrained: false,
  child: Container(width: 3000, height: 5000, ...)
```

La carte fait 3000 × 5000 px et est affichée à une échelle fixe de 0,8. `minScale`/`maxScale` sont inertes puisque `scaleEnabled` est `false`. Le seul autre moyen de navigation est un `Listener` sur `PointerScrollEvent` (`map_screen.dart:202`) — c'est-à-dire **la molette de souris**, sans équivalent tactile. Sur téléphone, le joueur ne peut donc que déplacer la carte au doigt, sans jamais pouvoir dézoomer pour voir la structure des embranchements — l'information la plus importante d'une carte de roguelike.

Enfin, la légende (`left: 20, bottom: 20`) et le panneau de statistiques (`width: 165`, `right: 20, bottom: 20`) se partagent le bas de l'écran, ce qui passe, mais recouvrent les nœuds de la carte sur un écran étroit.

### 4.3 Accueil, événement, carrousel de relique — débordements verticaux

Ces trois écrans construisent une `Column` non défilable dont la hauteur est fixée par le contenu :

- **`home_screen.dart:99`** : `Scaffold` → `Center` → `Column`, **sans `SafeArea` ni défilement**. Titre 48 pt + sous-titre + 60 d'espacement + deux boutons de ~70 px + bouton tutoriel + ligne de version ≈ **450 px de haut**. En paysage téléphone (hauteur utile ~340 px), débordement de ~110 px et aucun moyen de faire défiler pour atteindre le bouton « Jouer ».
- **`relic_carousel_screen.dart:227`** : `Column` centrée avec un carrousel de **hauteur fixe 350** encadré par deux espaceurs de 48 px, plus l'en-tête et le bouton ≈ **560 px**. Déborde en paysage téléphone, et l'écran s'ouvre en `showGeneralDialog` plein écran juste après une victoire — donc en plein flux de récompense.
- **`event_screen.dart:317`** : `Column` avec un `Expanded(SingleChildScrollView)` pour le texte, mais les boutons de choix, l'en-tête et un `SizedBox(height: 40)` sont hors zone défilable. L'`Expanded` se réduit à zéro puis le reste déborde.

### 4.4 Cibles tactiles trop petites

Plusieurs boutons descendent sous le minimum recommandé (44 pt iOS / 48 dp Android) :

- `GameButton(height: 32)` — boutons d'achat de la boutique (`shop_screen.dart:580, 648`)
- `GameButton(height: 38)` — actions des dialogues de fusion (`deck_screen.dart:333, 340, 407, 419`)
- `GameButton(height: 36)` — `forge_fusion_screen.dart:474`
- `MapToolbar` : `minimumSize: Size(50, 36)` avec `tapTargetSize: shrinkWrap` et des libellés à `fontSize: 10.5`

---

## 5. Modèle d'interaction : ce qui survit au tactile

Bonne nouvelle, l'essentiel a un équivalent tactile :

| Interaction | Souris | Tactile | État |
|:---|:---|:---|:---|
| Jouer une carte | glisser-déposer | glisser-déposer (`DragCallbacks`) | ✅ |
| Sélectionner une carte | survol | **tap** (`onTapDown` → `setFocusedCard`) | ✅ |
| Voir la description d'une carte | survol | **tap** (`card_animation_system.dart:100`) | ✅ |
| Infobulle de nœud de carte | survol | **appui long** (`map_node_widget.dart:146`) | ✅ |
| Infobulle de badge de stat | — | **appui long** (`stat_badge.dart:467`) | ✅ |
| Surbrillance du chemin sur la carte | survol uniquement | ❌ aucun | 🔴 |
| Défilement de la carte du monde | molette | glisser seulement, **pas de zoom** | 🔴 |
| Retours visuels de survol (15 `MouseRegion`) | agrandissement | ❌ aucun | 🟠 cosmétique |

Deux manques réels : la **surbrillance du chemin** (`_updateHighlight`, déclenchée par `onHoverEnter`/`onHoverExit` uniquement) est une aide à la planification inaccessible au doigt ; et le **zoom de la carte**, traité plus haut.

Détail d'ergonomie tactile : pendant le glisser, la carte suit le doigt de sorte que **le doigt masque la carte elle-même**, et le ciblage se fait sur le centre de la carte (`findHoveredEnemy(cardComponent.position)`) et non sur le point de contact. Sur téléphone, viser un ennemi de 73 px de large avec un repère invisible sous le doigt est un exercice de devinette.

---

## 6. Configuration plateforme

| Point | État | Conséquence |
|:---|:---|:---|
| `SystemChrome.setPreferredOrientations` | **absent** de tout `lib/` | Rien n'empêche le portrait ni le paysage |
| `ios/Runner/Info.plist` | portrait + 2 paysages autorisés | Le portrait iPhone — le cas cassé — est autorisé |
| `AndroidManifest.xml` | `configChanges` inclut `orientation` | Rotation libre, sans recréation d'activité |
| `web/index.html` | **pas de balise `<meta name="viewport">`** | Repose sur l'injection du moteur Flutter à l'exécution ; une balise explicite est plus sûre pour le web mobile |
| Fond `bg_dungeon.png` | 1024 × 1024, rendu en `size: size` | **Étiré**, jamais recadré : déformé à tous les ratios (×1,87 en 1080p) |

### 6.1 Empreinte mémoire des sprites — spécifique au mobile

`heros_draft_game.dart:168` précharge **tous** les sprites au démarrage via `images.loadAll`. Or :

```
enemy_*.png / hero_*.png : 1696 × 2528 RGBA  →  ~17,1 Mo décodés par image
7 sprites d'entités                          →  ~120 Mo de mémoire texture
```

Ces images sont rendues à 67–200 px de large, soit un facteur de sur-échantillonnage de **8 à 25×**. Sur desktop c'est du gaspillage ; sur un téléphone Android d'entrée de gamme (2–3 Go de RAM), 120 Mo de textures est une cause classique de saccades voire de `OutOfMemoryError`. C'est le seul point de cet audit qui touche la performance plutôt que la mise en page, mais c'est celui qui décide si le jeu **démarre** sur un appareil modeste.

---

## 7. Absence de filet de sécurité

Le projet compte 14 tests de widgets. **Tous s'exécutent à une taille de surface ≥ 1200 × 900** :

```
class_selection_screen_test.dart : Size(1600, 1200)
forge_fusion_screen_test.dart    : Size(1200,  900)
relic_exchange_screen_test.dart  : Size(1200, 1600)
rest_screen_test.dart            : Size(1200,  900)
shop_screen_test.dart            : Size(1200,  900)  ×2
starter_deck_draft_test.dart     : Size(1200,  900)
```

Les autres utilisent la surface par défaut de `flutter_test`, soit 800 × 600. **Aucun test n'a jamais rendu un écran à une largeur de téléphone.** Un débordement de 60 px dans la boutique ne peut donc pas faire échouer la CI : c'est ainsi qu'il est arrivé jusqu'ici.

### 7.1 Écart entre la documentation et le code

Deux ADR revendiquent la responsivité :

- **ADR-021** (tutoriel) — *exact*. Les 14 fichiers de `lib/tutorial/` utilisent bien `FittedBox`, `LayoutBuilder`, bascule portrait/paysage et conteneurs défilables. C'est la référence du projet.
- **ADR-030** (« Polissage de l'UI de Combat Responsive ») — **largement en avance sur le code**. Il conclut à une « lisibilité universelle » et une « absence de clipping sur l'ensemble de la gamme d'appareils testés ». En pratique, seuls `PlayerHealthBar`, `ManaIndicator` et le calcul de `hudWidth/hudHeight` ont été rendus adaptatifs ; `CombatSidePanels`, `TurnControlPanel`, `CombatTooltipOverlay` et toute la géométrie Flame sont restés en ancrages absolus. La « gamme d'appareils testés » ne comprenait vraisemblablement aucun téléphone en portrait.

De même, `_memory_bank/progress.md:144` liste la responsivité comme acquise pour « mobile, web, desktop ». Ces trois affirmations mériteraient d'être corrigées.

---

## 8. Plan de remédiation proposé

Ordonné par rapport impact/effort. Les trois premiers points suffisent à rendre le jeu jouable sur téléphone.

### P0 — Rendre le combat jouable en portrait

1. **Rendre `scaleFactor` sensible à la largeur.** Remplacer `size.y / 800` par une contrainte sur les deux axes, par exemple `min(size.x / 480, size.y / 800).clamp(0.6, 2.5)`, et découpler le rayon de l'éventail de la hauteur : le calculer depuis la largeur disponible pour que la main tienne toujours dans l'écran. Un unique changement dans `heros_draft_game.dart` + `layout_system.dart` supprime le débordement des 5 appareils du tableau §2.1.
2. **Repositionner les panneaux HUD sous 600 px.** `CombatSidePanels` : passer d'une largeur fixe 250 à `min(250, (largeur − 60) / 2)`, ou mieux — les empiler en un unique bandeau repliable en portrait. `TurnControlPanel` : ancrer le bouton en bas-centre plutôt qu'à mi-hauteur à droite, avec une largeur proportionnelle.
3. **Corriger les ancrages calculés hors `SafeArea`.** Remplacer `MediaQuery.size.height / 2` par un `LayoutBuilder`/`constraints.maxHeight` dans `TurnControlPanel`, et `bottom: 270` par une fraction de la hauteur disponible dans `CombatTooltipOverlay`.

### P0 — Corriger les deux débordements durs

4. **Boutique** : passer la `Row` flex 3/1 en `Column` sous 600 px (services en `Wrap` horizontal défilable au-dessus ou en dessous de la grille de cartes). Remplacer les `width: 130` par des contraintes minimales.
5. **AppBar de la carte** : rendre `leadingWidth` conditionnel (`isMobile ? 0 : 430`) et déplacer `MapToolbar` dans le corps ou dans un menu déroulant sur téléphone.

### P1 — Navigation et sécurité de mise en page

6. **Réactiver `scaleEnabled: true`** sur l'`InteractiveViewer` de la carte du monde, et remplacer le `Listener` molette par un comportement commun aux deux entrées.
7. **Envelopper de `SingleChildScrollView`** les `Column` non défilables : `home_screen`, `relic_carousel_screen`, la zone de choix de `event_screen`, `rest_screen`. Ajouter la `SafeArea` manquante à `home_screen`.
8. **Extraire un helper responsive partagé.** Le prédicat `MediaQuery.of(context).size.width < 600` est dupliqué à l'identique dans 5 fichiers, avec en plus deux seuils divergents (`760` dans `forge_fusion_screen`, `720` dans `forge_upgrade_dialog`). Un `lib/ui/theme/app_breakpoints.dart` (`compact` / `medium` / `expanded`) supprime la dérive et donne un point d'entrée unique.

### P1 — Interaction tactile

9. **Cibles tactiles** : porter les `GameButton` à `height >= 44` sous 600 px.
10. **Surbrillance du chemin** : la déclencher aussi sur `onTapDown`/appui long des nœuds de carte, pas seulement au survol.
11. **Décalage de la carte glissée** : décaler la carte au-dessus du point de contact et cibler l'ennemi depuis le point de contact plutôt que le centre de la carte.

### P2 — Performance et actifs

12. **Réduire les sprites** à ~512 × 768 (ou fournir des variantes par densité). Diviserait l'empreinte texture par ~10 et supprimerait le principal risque de démarrage sur Android d'entrée de gamme.
13. **Fond de combat** : recadrer (`BoxFit.cover`) au lieu d'étirer.
14. **`<meta name="viewport">`** explicite dans `web/index.html`.

### P2 — Ne pas régresser

15. **Tests de non-débordement multi-tailles.** Un helper de test qui rend chaque écran à `Size(360, 740)`, `Size(393, 852)`, `Size(852, 393)` et `Size(820, 1180)` en échouant sur toute exception de débordement. C'est le point qui garantit que le travail P0 tient dans le temps — sans lui, la même dérive recommencera.
16. **Corriger ADR-030 et `progress.md:144`** pour refléter l'état réel plutôt que l'intention.

---

## 9. Ce qui est déjà bon, et qu'il faut réutiliser

L'audit ne part pas de zéro. Sont déjà corrects et servent de modèles :

- **`lib/tutorial/`** — le patron complet : `FittedBox` sur canevas à coordonnées absolues, bascule `Row`/`Column` selon l'orientation, `Wrap` adaptatifs, conteneurs défilables. C'est exactement ce qu'il faut appliquer à l'arène de combat.
- **`PlayerHealthBar` / `ManaIndicator`** — bornage par `clamp`, proportions, `textScalerOf`, `Wrap`. Le modèle pour le reste du HUD.
- **Les grilles** — 9 écrans sur 10 utilisent `SliverGridDelegateWithMaxCrossAxisExtent`, qui s'adapte seul à la largeur. Aucune grille n'utilise un `crossAxisCount` fixe hors tutoriel. C'est la seule pratique responsive appliquée avec constance.
- **`GameDialog`** — `maxWidth` + marge + `SingleChildScrollView` : les dialogues sont structurellement sains, seuls certains contenus injectés (hauteur 500, largeur 130) posent problème.
- **`ScreenScaffold`** — applique `SafeArea` par défaut à 13 écrans sur 17.

---

## Annexe — Hors périmètre, relevé au passage

`deck_screen.dart` contient des chaînes françaises codées en dur hors du système de localisation (`'Sélectionnez exactement 3 cartes à fusionner…'` l.276, `'Continuer'` l.337, `'Capacité de Forge Dépassée'` l.349), de même que `forge_fusion_screen.dart` qui construit ses libellés via des ternaires `isFr ? … : …` plutôt que par `AppLocalizations`. Sans rapport avec le responsive, mais contraire à la règle bilingue du projet.