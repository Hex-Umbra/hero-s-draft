---
description: The enemy card composed in layers (P-05 bestiary, wave 2) — window background, creature, tier frame, targeting outline, then charge shell, halo, status tabs and health bar; the 64 x 96 window is invariant and the five frames (88 x 120 to 120 x 152) are PNG files under assets/data/frames/ declared by tier_frames.json, a tier without a frame refused at load; the board draws at the largest EVEN step, in physical pixels per frame pixel, that fits a reference row of six cards (x2 in 1080p and 1440p, x4 in 4K), the creature at half of it, and below x2 it shrinks and smooths; boardScaleFor, placeRow, creatureFitOf, decorFitFor, pickWindowBackground and inspectionShift are pure functions; the location seam is a directory assets/data/locations/<id>/ read from the manifest with no JSON, one location only, a combat decor of 640 x 360 per screen and three window backgrounds, one drawn per enemy at birth; one zone per card, the card's own hit test; the outline hugs the window; the sheet doubles the card and shifts inward at the edge; the Windows window opens maximized; enemies leave scaleFactor; amends ADR-121 and ADR-002; carries owner decisions B66 to B89 and sets aside the visual identity proposals for a const Dart table and assets/art/
---

# ADR-123 — Le Cadre de Tier et la Carte d'Ennemi Composée

### Statut

✅ Accepté — 2026-11-25 (P-05, le bestiaire ; décisions du propriétaire B66 à B82 au cadrage, B83 à B89
sur la spec, tranchées sur maquettes le 25/11). **Livré sur la branche `feat/v0.6.2-cadres-et-decors` —
vague 2 du [cadrage du bestiaire](../../docs/possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md),
en attente du test, de la PR, de la fusion et du tag du propriétaire.** Rien n'en est dans `main`.
[Spec](../../docs/superpowers/specs/2026-11-25-p05-cadres-et-decors-design.md) (deux tours),
[plan](../../docs/superpowers/plans/2026-11-25-p05-cadres-et-decors.md) (deux tours, décisions D1 à
D15), [compte rendu](../../docs/superpowers/reports/2026-11-25-bestiaire-vague-2-compte-rendu.md) ;
leurs motifs ne se recopient pas ici.

**Amende [ADR-121](ADR-121-l-interface-des-ennemis-en-combat.md)** : la barre de PV prend la largeur
du gabarit et non celle de la carte, les languettes se posent contre lui, la zone de la carte devient
le test d'appui de la carte entière, la barre et les languettes ne renvoient plus d'appui, la fiche
double la carte au lieu de la porter à ×1,25, le contour de ciblage entoure la fenêtre et le liseré
blanc du repos disparaît. **Amende [ADR-002](ADR-002-responsivite-dynamique-par-scalefactor.md)** : les
ennemis quittent `scaleFactor`, que gardent le héros et la main. Chacun de ces deux ADR ne change que
de Statut.

### Contexte

Une carte d'ennemi était une carte peinte entière, mise à l'échelle en continu par `scaleFactor`, au
fond d'une salle unique. La vague 1 y avait posé une interface. Il fallait un cadre qui dise le tier,
un fond de créature, un décor redessiné, et une échelle qui ne rende pas les pixels flous — sans
changer ce que font les ennemis : aucun fichier de `lib/game/controllers/`, `lib/game/services/` ni
de `lib/models/` hors `lib/models/data/` ne bouge.

### Décision

1. **La carte est composée en calques, une fenêtre invariante.** Dans l'ordre des priorités de ses
   enfants : le fond de la fenêtre (0), la créature (1), le cadre du tier (2), le contour de ciblage
   (3), puis la gangue (4), le halo (5), les languettes (6) et la barre de PV, au-dessus du cadre.
   **La fenêtre fait 64 × 96 pour tous les tiers** ; seul le canevas grandit de 4 pixels de bordure
   par tier (88 × 120, 96 × 128, 104 × 136, 112 × 144, 120 × 152 — B73). La gangue et le halo se
   posent sur la fenêtre (identité visuelle §4.2.3). La barre et les languettes s'ancrent à **un
   gabarit de 88 × 120**, centré sur la fenêtre, le même sur les cinq cadres (B77).

2. **La table des cadres est une donnée, et un tier sans cadre est refusé.** `assets/data/tier_frames.json`
   (cinq lignes : tier, taille, décalage de la fenêtre) et les images `assets/data/frames/tier_<n>.png`,
   lues par `TierFrame` (`lib/models/data/tier_frame_data.dart`) ; `tierFrameFaults` refuse au chargement
   une taille impaire, une fenêtre hors du canevas ou décentrée, une image absente, **et un tier
   d'ennemi livré qui n'a pas de cadre** — avec les autres fautes (A2, A7). Le document est chargé par
   `loadDocument`, obligatoire comme la courbe d'XP.

3. **L'échelle est un palier pair en pixels physiques.** `boardScaleFor` (`lib/game/systems/board_scale.dart`)
   rend le plus grand pas **pair**, en pixels physiques par pixel de cadre, qui laisse tenir une rangée de
   référence de six places, la barre au-dessus du centre de la rangée et le cadre du tier 5 au-dessus du
   héros : **×2 en 1080p et en 1440p, ×4 en 4K** (B83, qui amende les exemples de B72 — ×4 en 1440p, ×6 en
   4K — par sa règle). **La créature et son fond sont à la moitié** du pas, donc sur des pixels entiers.
   **Sous le plus petit écran qui tient ×2, le plateau garde la mise en page de ×2, réduit en continu et
   lissé** (`FilterQuality.medium`, `BoardScale.crisp` faux ; B85) ; sur un palier net, le cadre et le
   fond ne se lissent pas, la créature non plus sauf un ancien sprite. **Le plateau ne rétrécit plus en
   continu.** Le rapport de pixels se lit sur le contexte du jeu, repli 1 (`HerosDraftGame.devicePixelRatio`).

4. **La rangée est une fonction pure.** `placeRow` (`lib/game/systems/enemy_row.dart`) pose les centres
   des places — chacune la plus large de son cadre et du gabarit avec ses deux languettes au repos
   (146 pixels de cadre pour les plus étroites), écart minimal 7, maximal 122, largeur utile 0,95 —,
   chaque centre sur un pixel physique ; `LayoutSystem` n'est plus que son appelant et le seul écrivain
   de la position d'un ennemi. Le centre des fenêtres est à 0,21 de la hauteur. Un boss a la taille des
   autres ennemis.

5. **Un ancien sprite se recadre par la taille de son image.** `creatureFitOf`
   (`lib/game/systems/creature_fit.dart`) : une image de 128 × 192 se dessine entière et nette ; une
   ancienne peinture, qui contient le rectangle x 308–1388, y 329–1949, se recadre dessus et se lisse
   (B75) ; toute autre image se dessine entière. Le recadrage disparaît avec le dernier ancien sprite.

6. **La couture de lieu est un répertoire, et le lieu est unique.** `assets/data/locations/<id>/`, **sans
   JSON** : `LocationCatalog` (`lib/models/data/location_data.dart`) se lit dans le manifeste d'assets par
   `GameDataLoader.assetsMatching`, et ses fautes rejoignent les autres par `GameDataLoader.fault`, deux
   méthodes publiques neuves. Un lieu porte un décor par écran (`DecorScreen`) et trois fonds de fenêtre
   `window_1..3.png` ; **zéro lieu ou deux sont refusés au chargement** en nommant le dossier, `combat.png`
   est obligatoire (B66, B76, A3 à A6). `currentLocationProvider` désigne le seul lieu, la forêt. **Un
   décor d'écran se dessine en 640 × 360** (B74), en couleurs peintes (B80) : `decorFitFor`
   (`lib/game/systems/decor_fit.dart`) le fait couvrir l'écran au plus petit facteur qui le couvre, centré,
   rogné, jamais lissé (B88). Flame le pose (`HerosDraftGame`), les écrans Flutter par `LocationBackdrop`,
   que `ScreenScaffold` reçoit en paramètre `decor` ; **six écrans le déclarent, sans image de lieu, donc
   dormants**. `assets/images/bg_dungeon.png` est supprimé.

7. **Le fond de la fenêtre se tire à la naissance de la carte.** `pickWindowBackground` rend un indice
   parmi les trois du lieu ; la carte le tient, il n'est pas sauvegardé (B87). Il est **dormant derrière
   les anciennes peintures**, qui le recouvrent : il ne se voit qu'avec les sprites neufs (vague 4).

8. **Une seule zone par carte, le test d'appui de la carte.** `enemyZoneRect` (`lib/game/systems/entity_hover.dart`)
   couvre le canevas, la barre et les languettes au repos, coins compris ; c'est ce que lisent le survol,
   l'appui et le lâcher d'une carte. `enemyBodyRect` disparaît ; la barre et les languettes ne renvoient plus
   leur appui.

9. **Le contour entoure la fenêtre.** `TargetOutline` (`lib/game/components/entities/target_outline.dart`)
   pose son trait à l'extérieur de la fenêtre, avec la lueur cyan de la surbrillance, à la même taille sur
   les cinq cadres : cyan pour une cible possible, ambre pour une carte choisie ou dont la fiche est ouverte ;
   au repos, rien (B78). Le héros garde son rectangle.

10. **La fiche double tout, et se décale vers l'intérieur.** `GameConstants.inspectionScale` passe de 1,25 à
    2,0 **à tout palier** (B79, B84) : la carte, sa barre et ses languettes, non le panneau Flutter. La
    descente de la carte ouverte vaut 77 pixels de cadre × le palier. **Une carte ouverte qui sortirait de
    l'écran se décale** par `inspectionShift`, arrondi vers l'intérieur, sa barre gardant sa hauteur (B89).

11. **L'export et la fenêtre.** `art_src/tools/export_jeu.py` convertit les sources Aseprite par
    `aseprite --batch --save-as` vers `assets/data/` (A19). **La fenêtre Windows s'ouvre maximisée**
    (`SW_SHOWMAXIMIZED`, `windows/runner/win32_window.cpp` — B86), pour que l'écran 1080p voie le plateau à
    ×2, net, dès l'ouverture.

12. **Propositions de l'identité visuelle écartées**, motivées : la table des cadres en `const` Dart (§4.1),
    `assets/art/frames/` et `assets/art/backgrounds/` (§7.2), et la migration `assets/images/` →
    `assets/art/` (§9, point 3), devenue sans objet — la donnée vit sous `assets/data/`, que le chargeur
    et l'éditeur connaissent déjà (A2, A3, A5).

### Preuves dans le code

- Tests de calcul, sans écran (ADR-113) : `board_scale_test.dart`, `enemy_row_test.dart`,
  `creature_fit_test.dart`, `decor_fit_test.dart`, `window_background_test.dart`,
  `tier_frames_test.dart`, `location_catalog_test.dart`, `target_outline_test.dart`, et les tests de
  chargement (`game_data_loader_test.dart`, `real_bundle_load_test.dart`, `referential_integrity_test.dart`).
  **Aucun test d'écran neuf.**
- `git diff e2a96432 -- lib/game/controllers lib/game/services` ne rend rien ; sous `assets/data` ne
  changent que `tier_frames.json`, `frames/`, `locations/` et la note de version.
- Le rejeu sur composants montés (cinq ennemis de tiers 1, 1, 2, 3, 3 en 1920 × 1080, 1920 × 1009 et
  1280 × 720) est un test jetable du vérificateur, faute de pouvoir monter un jeu sans membres `@internal`
  de Flame (D1 du plan) : la pose du décor et la couture Flame n'ont donc aucun test permanent.
- `lib/game/components/entities/enemy_card.dart`, `enemy_health_bar.dart`, `status_tabs.dart`,
  `target_outline.dart`, `combat_entity.dart` ; `lib/game/systems/layout_system.dart`.

### Conséquences

- ✅ Un tier se lit au cadre ; le plateau est net à ×2 et à ×4, sur des pixels entiers ; un lieu futur
  (P-12) n'est qu'un dossier de plus, derrière une seule question — « quel lieu » — que la couture pose déjà.
- ✅ Les cadres, le décor et les fonds se retouchent à la main sous `art_src/`, sans toucher au code.
- ⚠️ **Dormant** : les fonds de fenêtre derrière les anciennes peintures, et le décor de tout écran autre
  que le combat. Ils ne se voient pas en jeu avant leurs sprites et leurs images.
- ⚠️ **Le palier ×2 laisse le héros et la main sur `scaleFactor`** : deux échelles cohabitent sur le plateau
  jusqu'à ce qu'une vague les réunisse.
- ⚠️ `CLAUDE.md` reste faux sur trois points — l'arbre de « Data-Driven Content Workflow » sans `frames/`,
  `tier_frames.json` et `locations/<id>/`, la couche de données sans `tier_frame_data.dart` et
  `location_data.dart`, `GameDataLoader` sans `assetsMatching` et `fault` — jusqu'à la retouche du
  propriétaire (S2 du compte rendu).
- ⚠️ `build/unit_test_assets` ne se purge jamais : `bg_dungeon.png` y reste, sans lecteur, jusqu'à ce que le
  dossier soit vidé.
