# Exemple — les fonds de fenêtre du biome forêt

Le parcours des trois premiers fonds de fenêtre, produits par [le workflow des fonds](../workflow_fond.md) § 2, le 10/11/2026 : les tours, les prompts exacts, les graines et ce que chaque ajout a corrigé. Les fichiers sont dans `art_src/backgrounds/windows/forest/`.

Toutes les générations sont libres, en 1024 × 1536, avec le LoRA à 0.8.

## Les tours

| Tour | Ce qui change | Ce qui en sort |
|:---|:---|:---|
| 1 | Le prompt de forêt, avec « a small open clearing in the center » ; exclus : figures, brume | Trois forêts très détaillées, mais **un arbre géant au centre** sur chacune, et une rouille trop présente. Graine 121064 : un sentier rouille entre de grands pins. |
| 2 | + « a clear path in the foreground » | **Sur la graine 121064, le grand arbre disparaît** : une trouée au centre, un sentier qui serpente, des troncs qui cadrent. Graine 358320 : de nouveau un arbre géant, avec un motif carré bizarre. **Graine 832745 : un sentier entre de hauts pins, retenue.** |
| 3 | Exclus en plus : giant central tree, autumn | Graines 11058, 1942 et 293903 : trois forêts conformes, des sentiers rouille ou clairs, des sous-bois plus ou moins denses. |

## Le prompt final

> dark fantasy pixel art illustration of a dense dark forest, empty scene, a clear path in the foreground, highly detailed background with gnarled tree bark, mossy rocks, roots and a rust-colored forest floor, a small open clearing in the center, moody lighting, muted cold palette of deep navy blue, slate blue and teal greys, with sparse warm accents of rust, ember orange and old ivory, 16-bit, crisp pixels, highly detailed

**Exclusions :**

> halloween, cartoon, cute, plain background, fog, mist, haze, people, person, character, creature, skeleton, animal, giant central tree, autumn

**Commande :** `python comfy_gen.py foret "<prompt>" --libre --exclure "<exclusions>" --size 1024x1536 --seed N --lora 0.8`, puis `python window_import.py <image> forest_window_<n>.aseprite --source forest_window_<n>_comfy_source.png`.

## Les trois variations retenues

Le choix a été fait en greffant la même créature sur cinq candidats.

| Fichier | Graine | Ce qui le distingue |
|:---|:---|:---|
| `forest_window_1` | 832745 (tour 2) | Une lumière franche au fond, entre les pins : c'est là que la créature se détache le mieux |
| `forest_window_2` | 121064 (tour 2) | Un sentier rouille qui serpente, des racines au premier plan, une lumière claire au loin |
| `forest_window_3` | 293903 (tour 3) | Un sous-bois plus dense et plus sombre, avec un sentier clair |

## Ce qu'on en a appris

- **Le grand arbre central revient tant qu'on ne le chasse pas.** C'est « a clear path in the foreground » qui l'a chassé, plus que l'exclusion de « giant central tree ».
- **Retirer la brume est ce qui a le plus amélioré le détail.**
- **Les fonds clairs au loin servent mieux une créature sombre.** Sur le troisième fond, plus sombre, la robe de la Faucheuse se perd dans les troncs : voir [l'exemple de la Faucheuse](creature_faucheuse.md), « Ce qui reste ouvert ».
