# Produire un fond de fenêtre en pixel art

**État au 23/11/2026.** La méthode est encore en itération. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images. Des cas complets sont racontés dans [les exemples](exemples/).

Il existe deux sortes de fonds, et elles ne se font pas de la même façon. **Depuis le 23/11/2026, le décor d'écran a son propre document** : [le workflow des décors](workflow_decor.md). Celui-ci ne décrit plus que le fond de fenêtre.

| | Décor d'écran | Fond de fenêtre |
|:---|:---|:---|
| **Où on le voit** | Derrière tout un écran : combat, aire de repos… | Dans la fenêtre du cadre d'un ennemi, derrière la créature |
| **Taille** | 640 × 360 | 128 × 192 |
| **Combien** | Un par lieu et par écran | Trois variations par lieu |
| **Méthode** | La structure par le code, puis deux passes de génération, dont une par tuiles | ComfyUI compose librement, en une génération ; on choisit |
| **Calques** | Un calque par objet | Un seul : c'est une surface |
| **Rangement** | `decors/<lieu>/<écran>/` | `fonds/<lieu>/` |
| **Document** | [Le workflow des décors](workflow_decor.md) | Celui-ci |

---

## Le fond de fenêtre (128 × 192)

Le fond de fenêtre est un asset à part. Le jeu y greffe la créature qui apparaît, selon le biome. Chaque biome en a **trois variations**, pour que le même ennemi ne se présente pas toujours dans le même décor.

### Le cahier des charges

Chaque fond doit laisser la place à n'importe quelle créature :
- **Un sol dégagé au premier plan**, où la créature pose les pieds. La ligne de sol commune des créatures est à y = 183 sur 192.
- **Rien de grand au centre,** là où se tient la créature.
- **Une zone claire au loin, au centre,** quand c'est possible. Les créatures sombres se détachent mieux sur ce contraste.
- **Pas de brume :** elle aplatit le fond et tue le détail.

### Les étapes

1. **Générer en mode libre**, à 1024 × 1536, avec un LoRA à 0.8 et trois graines au hasard par tour.
2. **Choisir, puis itérer** sur le prompt. Une image qu'on aime se relance avec sa graine : la composition reste souvent proche.
3. **Ramener sur la grille** avec `window_import.py`, en gardant la source.
4. **Vérifier en greffant une créature** dessus : la créature se lit-elle bien ? Ses pieds tombent-ils sur le sol ?
5. **Recommencer jusqu'à trois variations** qui se distinguent : lumière, sol, densité.
6. **Exporter vers le jeu**, depuis `art_src/tools/` : `python export_jeu.py ../fonds/<lieu>/<lieu>_window_<n>.aseprite ../../assets/data/locations/<lieu>/window_<n>.png --taille 128x192`. Le livrable est ce PNG de 128 × 192, `window_1.png` à `window_3.png` : trois par lieu, exactement (B67). Il garde les couleurs d'Apollo telles quelles.

### Le gabarit du prompt

> dark fantasy pixel art illustration of **[le lieu]**, empty scene, a clear path in the foreground, highly detailed background with **[les matières et les éléments du lieu]**, a small open clearing in the center, moody lighting, muted cold palette of deep navy blue, slate blue and teal greys, with sparse warm accents of rust, ember orange and old ivory, 16-bit, crisp pixels, highly detailed

**Les exclusions de base** (`--exclure`), à compléter selon le biome :

> halloween, cartoon, cute, plain background, fog, mist, haze, people, person, character, creature, animal

On ajoute aux exclusions ce que le générateur met au centre sans qu'on le veuille, par exemple un grand arbre en forêt ou une statue dans des ruines. On ajoute aussi les ambiances qui sortent de la palette froide, comme « autumn » en forêt.

**Ce que fait chaque partie :**
- **« a clear path in the foreground » et « a small open clearing in the center »** gardent la place de la créature.
- **Exclure la brume** garde le détail net.
- **Exclure les figures** garde le fond vide.
- **La phrase de palette** décrit Apollo en mots, car ComfyUI ne connaît pas la palette elle-même.

Il reste en moyenne une image sur trois à écarter : il faut toujours générer plusieurs graines.
