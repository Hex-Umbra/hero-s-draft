# Outils de la chaîne pixel art

Les scripts qui produisent les sources `.aseprite` du projet. Ils sont rangés hors de `assets/` et ne sont jamais livrés avec le jeu. Pourquoi cette méthode a été choisie : voir le document de direction artistique, [§15](../../docs/possible_upgrades/07-11-2026_direction_artistique_evolutive_cartes_Opus5.md).

## La méthode, en quatre étapes

1. **La structure, par le code.** La géométrie (pour les fonds, une vraie perspective calculée pixel par pixel), la palette [Apollo](https://lospec.com/palette-list/apollo) et des calques nommés.
2. **Le détail, par ComfyUI**, en local. L'image guide, la carte de profondeur et la carte des contours tiennent la composition (ControlNet).
3. **Le retour sur la grille.** L'image générée est alignée, ramenée sur la grille avec la couleur Apollo majoritaire de chaque bloc, puis découpée en calques selon la géométrie de l'étape 1.
4. **La retouche à la main**, dans Aseprite.

**Règle des calques :** un calque est un objet complet. Le masquer le fait disparaître en entier et laisse voir une surface complète dessous. Seules les surfaces (murs, sol, voûte, fond) n'ont rien derrière elles. `aseprite_io.check_independent` vérifie cette règle à chaque export, et `aseprite_io.build` vérifie que chaque `.aseprite`, rouvert dans Aseprite, redonne exactement son rendu.

## Prérequis

- **Python 3 et Pillow** (`pip install pillow`).
- **Aseprite 1.3 ou plus récent.** Il est trouvé tout seul dans l'installation Steam ou dans `Program Files`. Sinon, définir `ASEPRITE_PATH` vers `Aseprite.exe`.
- **Pour les aperçus sur la carte (`pilot_cards.py`) :** la police d'icônes Material du SDK Flutter, au chemin écrit en tête du script.

Les fichiers intermédiaires vont dans `.work/`, que git ignore. Pour les envoyer ailleurs, définir `ART_WORK`.

## Les commandes

Toutes se lancent depuis ce dossier.

| Commande | Ce qu'elle produit |
|:---|:---|
| `python bg_hall.py ../backgrounds/dungeon_hall.aseprite` | La salle de la herse, 320 × 180, 12 calques. À côté : `_guide_x4.png`, l'image guide pour le générateur ; `_depth.png` et `_edges.png`, les cartes de guidage pour ControlNet. |
| `python bg_import.py <image générée> ../backgrounds/dungeon_hall_detail.aseprite [<copie PNG de la source>]` | L'image générée, alignée, ramenée sur la grille Apollo et découpée en calques. Sous chaque objet, la surface est complétée par le rendu de `bg_hall.py`, donc ce dernier doit avoir tourné avant. |
| `python aseprite_layers.py ../../docs/presentations/2026-11-09_sources_aseprite_serie_pilote` | Les paliers pixel 16 et pixel 64 des sept cartes de la série pilote. |
| `python pilot_cards.py` | Une planche de contrôle des cartes de la série pilote aux cinq paliers, sur la vraie carte. |

## Les fichiers

| Fichier | Rôle |
|:---|:---|
| `motifs.py` | Les motifs des cartes : des formes nommées par rôle (clair, sombre, accent, effet…), un sprite pixel 16 posé à la main et sa palette. |
| `ladder.py` | Les cinq paliers de l'échelle A (griffonnage, pixel 16, pixel 64, dessin animé, peinture numérique), applicables à tout motif. |
| `styles.py` | Frappe aux cinq paliers, et les outils de dessin partagés (bruit, dilatation, trame de Bayer…). |
| `cards.py`, `pilot_cards.py` | Le cadre de la carte de combat, et la carte complète avec titre, coût et valeurs par palier. |
| `aseprite_layers.py` | Le découpage en calques des paliers pixel des cartes. |
| `bg_hall.py` | Le fond « salle de la herse » : géométrie, matériaux, lumières, calques et cartes de guidage. |
| `bg_import.py` | L'étape 3 pour ce fond : alignement, mise sur la grille, découpage. |
| `aseprite_io.py`, `aseprite_build.lua`, `aseprite_verify.lua` | Le pont vers Aseprite : assemblage en mode indexé, aller-retour vérifié, contrôle des calques. |

**À savoir :** `bg_import.py` découpe selon la géométrie de `bg_hall.py`. Un nouveau fond demande donc son propre script de géométrie, dont `bg_hall.py` est le modèle.
