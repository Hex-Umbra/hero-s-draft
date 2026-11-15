# Produire un fond en pixel art

**État au 10/11/2026.** La méthode est encore en itération. Les commandes exactes et les prérequis sont dans le [README des outils](../tools/README.md), avec les règles communes à toutes les images. Des cas complets sont racontés dans [les exemples](exemples/).

Il existe deux sortes de fonds, et elles ne se font pas de la même façon.

| | Fond d'écran | Fond de fenêtre |
|:---|:---|:---|
| **Où on le voit** | Derrière tout un écran : combat, aire de repos… | Dans la fenêtre du cadre d'un ennemi, derrière la créature |
| **Taille** | 320 × 180 | 128 × 192 |
| **Combien** | Un par écran, ou par biome de combat | Trois variations par biome |
| **Méthode** | La structure d'abord, par le code ; ComfyUI ajoute le détail | ComfyUI compose librement ; on choisit |
| **Calques** | Un calque par objet | Un seul : c'est une surface |
| **Rangement** | `backgrounds/<thème>/` | `backgrounds/windows/<biome>/` |

---

## 1. Fond d'écran (320 × 180)

L'écran a des zones réservées à l'interface : l'emplacement des ennemis et du héros, la main du joueur, un menu. La composition ne se laisse donc pas au hasard : on la construit d'abord.

### Les étapes

1. **Écrire le script de la scène**, `bg_<nom>.py`, en copiant un script de scène existant. Tous sont construits sur `scene.py`.
   - Une vraie perspective, calculée pixel par pixel.
   - Un calque complet par objet, posé à sa profondeur, avec sa lumière cuite dedans.
   - La palette Apollo dès cette étape.
   - Le script écrit le `.aseprite` de base, l'image guide et les deux cartes de guidage (profondeur et contours).
2. **Vérifier la composition sur le vrai écran.** Les zones de l'interface doivent rester calmes : rien d'important sous les éléments du jeu qui s'affichent par-dessus.
3. **Faire peindre le détail par ComfyUI**, en mode guidé, avec trois graines par tour. Les réglages par défaut de `comfy_gen.py` (1360 × 768, denoise 0.7, profondeur 0.7, contours 0.45, LoRA 0.9) sont un bon point de départ.
4. **Ramener sur la grille et découper** avec `bg_import.py`. Chaque pixel généré va au calque de l'objet visible à cet endroit, et les autres calques gardent le rendu de l'étape 1.
5. **Retoucher dans Aseprite.**

### Les pièges

- **Une carte des contours trop chargée** (chaque pavé, chaque brique) fige le générateur. On simplifie les formes avant de tracer les contours.
- **Les éléments fins se perdent.** Il faut les dessiner assez gros dans la géométrie.
- **Une forme ambiguë est réinterprétée** par le générateur, à sa façon. Chaque forme claire du guide doit être sans ambiguïté.
- **La lumière se cuit dans chaque objet**, jamais dans un calque de lumière posé par-dessus. Sinon, masquer un objet laisse sa lueur flotter.
- **Problème ouvert :** à 1360 de large, le LoRA peint une grille de 170 de large, deux fois plus grossière que celle de 320, ce qui donne des blocs de 2 × 2.

---

## 2. Fond de fenêtre (128 × 192)

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
