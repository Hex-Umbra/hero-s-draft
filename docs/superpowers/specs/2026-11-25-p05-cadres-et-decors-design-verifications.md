# P-05 vague 2 — les cadres de tier et les décors — vérifications de la spec

Fichier voisin de [la spec](2026-11-25-p05-cadres-et-decors-design.md), tenu par l'orchestrateur (ADR-108 D4) : les options écartées de chaque arbitrage, les questions posées au propriétaire, puis le journal des tours de vérification. La spec ne garde que les choix.

## 1. Les options écartées

| # | Question | Classe | Options écartées | Filtre |
|:---|:---|:---:|:---|:---:|
| A1 | Les couches | T | Un état Riverpod pour le palier ou le lieu ; des composants Flame qui lisent les providers | 5 |
| A2 | La table des cadres | T | Une table `const` en Dart (identité visuelle §4.1) ; l'offset de fenêtre déduit de la taille du PNG ; le chemin de l'image écrit dans le JSON ; un dossier `assets/art/frames/` (identité visuelle §7.2) | 4, 5 |
| A3 | Le lieu | T | Un `location.json` qui liste ses fichiers ; une constante Dart ; un dossier `assets/art/` | 5, 7 |
| A4 | Le lieu courant | T | Une constante `'forest'` ; un `RunState.locationId` sauvegardé | 5, 8 |
| A5 | Le repli du décor de combat | T | Garder `bg_dungeon.png` comme repli ; la couleur de fond | 1, 8 |
| A6 | Les autres écrans | T | Ne câbler que le combat | 1 |
| A7 | Où vit le refus d'un tier sans cadre | T | Un test de données seul ; `EnemyData.fromJson` ; l'affichage | 5 |
| A8 | Le calcul du palier | T | En pixels logiques ; selon le nombre d'ennemis du combat ; `min(largeur / 1920, hauteur / 1080)`, qui ferait perdre ×2 à une fenêtre maximisée | 1 |
| A9 | La place d'une carte et les écarts | T | Le pas fixe de la maquette (310 px) ; une largeur utile égale à l'écran moins une marge | échelle existante |
| A10 | La hauteur des fenêtres | T | Une barre à marge fixe du haut ; une bande centrée | échelle existante |
| A11 | La taille de la carte | T | Une carte de la taille du gabarit, le cadre en débord | 5 |
| A12 | Reconnaître un ancien sprite | T | Un champ `legacySprite` ; une liste d'ids en Dart ; le rectangle intérieur au filet peint (330, 360, 1038 × 1557) | 5, 7 |
| A13 | Le fond de fenêtre | T | Le tenir dans `EnemyInstance` ou `CombatState` ; le retirer à chaque replacement | 5 |
| A14 | Le contour de ciblage | T | Un trait centré sur le bord, qui mordrait la créature ; la lueur laissée sous le cadre | 1 |
| A15 | La gangue et le halo | T | Le canevas ; le gabarit | 1, 6 |
| A16 | Les ancres (textes flottants, icône, entaille, boule de feu) | T | Le canevas ; garder 100 × 140 | 1 |
| A17 | La zone de toucher | T | Le gabarit seul ; une zone au pixel près (alpha) | 6 |
| A18 | La fiche | T | ×1,25 ; le palier pair suivant | B79, sous D2 |
| A19 | L'export | T | Recomposer depuis `aseprite_export.lua` ; un export à la main | 8 |
| A20 | L'éditeur | T | Proposer le tier comme liste des cadres | 7 |
| A21 | Le découpage | T | Deux plans | 7 |
| A17 (tour 1) | La zone d'appui, coins de la barre compris | T | Une zone propre à la barre, élargie aux coins ; garder les renvois d'appui de la barre et des languettes | 5 (une seule définition, ADR-121 point 3) |
| §4.1 (tour 1) | Une fenêtre décentrée dans son canevas | T | L'ancrer au centre de la fenêtre plutôt que du canevas | 8 (refuser au chargement se défait plus simplement, aucun cadre n'est décentré) |

## 2. Les questions du propriétaire

Nées en écrivant la spec puis en la vérifiant (§1.3) : trois de classe D — D1 (les exemples de B72 contre sa règle), D2 (« palier pair suivant » de B72 contre « double » de B79), D3 (le plateau sous le 1080p, où aucun palier pair ne tient : c'était P1, reclassé au tour 1) — et trois de classe P, P2 à P4. Posées le 25/11 sur maquettes à la taille réelle de l'écran : <https://claude.ai/artifact/5fcccZZGtE1xJVW9eLtAAq> (privé), une section par question.

## 3. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Suite |
|:---:|:---|:---:|:---:|:---:|:---:|:---|
| 1 | complet | 0 | 1 (T) | 10 (7 T, 2 D, 1 P) | 4 | **À corriger.** Les quelque 80 références et tous les calculs de §5.1, §5.6 et §5.9 sont confirmés. D1 et D2 confirmées D, recommandations tenues ; P1 reclassée D3 (toutes ses options dérogent à la lettre de B72), avec une option (e), la fenêtre maximisée au lancement ; A15 reste T, appuyé sur l'identité visuelle §4.2.3. Le constat moyen : aux tiers 2 à 5, un appui dans les coins au-dessus du canevas, de part et d'autre de la barre, tombait au décor et fermait la fiche ; la zone devient le test d'appui de la carte. Tout corrigé par le rédacteur repris, aucun constat contesté ; deux références fausses de la première version trouvées et corrigées au passage (`main.cpp:28`, `heros_draft_game_targeting_test.dart:68`). **Arrêt** sur les questions D (orchestration §6), avant le tour 2 |
