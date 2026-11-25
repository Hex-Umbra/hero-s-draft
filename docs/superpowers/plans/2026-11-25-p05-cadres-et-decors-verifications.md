# P-05 vague 2 — les cadres de tier et les décors — vérifications du plan

Fichier voisin du [plan](2026-11-25-p05-cadres-et-decors.md), tenu par l'orchestrateur (ADR-108 D4) : les écarts que le plan prend avec la [spec](../specs/2026-11-25-p05-cadres-et-decors-design.md), puis le journal des tours de vérification.

## 1. Les écarts déclarés par le rédacteur

| # | Écart | Classe | Raison |
|:---|:---|:---:|:---|
| D1 | Le rejeu de la tâche à risque sur cartes montées est un test jetable, joué puis supprimé, ses chiffres dans le message de commit | T | Monter un `HerosDraftGame` sans widget demande `load()` et `mount()`, `@internal` dans Flame 1.38.2 : `dart analyze` le refuserait |
| D2 | `boardScaleFor` reçoit un cinquième paramètre facultatif, `referenceRowWidth` (911) | T | Sans lui, le verrou de la marge de la 4K ne peut rien faire grandir |
| D3 | L'arrondi de `placeRow` : `max(round(pas), ceil(minimum))` | T | Caler au pixel sans passer sous la distance minimale ; retrouve le tableau de la spec §5.6 à un pixel près (quatre places : 1270 au lieu de 1271, la valeur non arrondie) |
| D5 | `currentLocationProvider` naît à la tâche 3, non à la tâche 1 | T | Ses deux lecteurs naissent à la tâche 3 : pas de code sans lecteur |
| D6 | Les constructeurs `HerosDraftGame(...)` des tests ne changent pas | T | La table et le lieu passent autrement |
| D7 | L'outil d'export lit la taille dans l'en-tête PNG et les calques par `--list-layers` / `--all-layers --list-layers` ; il se lance par `python export_jeu.py` depuis `art_src/tools/`, comme la spec §10.1 | T | Arbitré au tour 1 : l'option `-I` du premier jet venait du brief de l'orchestrateur, à tort ; `aseprite_io.py`, qui importe Pillow, n'est pas modifié |
| D8 | `LocationCatalog` porte un champ `faults` | T | La spec ne disait pas par où sortent les refus de `fromAssetKeys` |
| — | Les constantes de fenêtre et de gabarit entrent dans `GameConstants` dès la tâche 1 | T | `tierFrameFaults` les lit déjà |

## 2. Le journal des tours

| Tour | Mode | Bloquants | Moyens | Mineurs | Rédaction | Suite |
|:---:|:---|:---:|:---:|:---:|:---:|:---|
| 1 | complet | 0 | 3 (T) | 4 (T) | 4 | **À corriger.** La tâche 6 rejouée dans un clone sur un minimum des tâches 1, 2, 4 et 5 : elle compile telle qu'écrite, et toutes ses mesures montées tombent sur la spec — barre de 176 × 26 au gabarit, zone coins compris sur les cinq tiers, contour cyan et ambre sans liseré blanc, fiche à ×4 et descente de 154 en 1080p, décalage de −97 à six cartes, filtrage qui bascule entre 1080p et 1280 × 720 ; suite complète à 1955 sur ce minimum. Les trois moyens sont des tests rouges tels qu'écrits : deux tolérances trop fines pour le Float32 de `Vector2`, et une largeur de 1271 au lieu de 1270 sous l'arrondi de D3 (arbitré : 1270, l'écart d'un pixel avec la spec déclaré). Mineurs : `isBoss` sans lecteur, un grep qui ne contrôlait rien, la configuration 1, 1, 2, 3, 3 du rejeu, trois écarts non déclarés. **D7 arbitré** : l'option `-I` venait du brief de l'orchestrateur, à tort ; retour à la commande de la spec, `aseprite_io.py` n'est plus touché. D1, D2, D5, D6, D8 confirmés fondés |
| 2 | différentiel | 0 | 0 | 0 | 2 | **Prêt.** Les sept corrections faites et justes. Rejoué dans un clone : les tests de la tâche 6 et le « quatre places » à `+59`, le test jetable du Step 8 à `+9` avec ses huit lignes attendues (palier ×2 net, pas de 306, bord droit de la carte ouverte à 1864 en 1080p ; 1,3181, décalage nul, bord vers 1228 en 1264 × 681) ; l'outil d'export écrit en 21 lignes rend les neuf PNG aux tailles de la spec et refuse une taille fausse. Les deux rédactions (la source du Float32, ce tableau) corrigées par l'orchestrateur |
