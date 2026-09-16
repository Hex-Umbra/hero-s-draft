# Archive — livraison sortie de `activeContext.md` le 2026-09-16

Rotation FIFO. La livraison **P-41 lot A — passage unique des gains, scission des puissances,
migration de sauvegarde** (2026-09-16) entre dans `activeContext.md` ; celle ci-dessous en sort,
conservée **verbatim**, numérotation comprise.

> [!WARNING]
> Lecture seule. Ces textes décrivent l'état du projet à la date où ils ont été écrits.

---

3. **Éditeur de contenu — formulaire inféré et ressources liées** (2026-09-14, 28 commits,
   `891351c` → `25b2945`) — l'état du formulaire devient un **document**, dont les champs sont
   inférés : plus de boîte JSON en modification, aucune clé du fichier perdue, et une saisie non
   convertible est une faute au lieu d'être remplacée en silence. Les gabarits n'écrivent plus de
   `sfx` vide, qui faisait rougir la suite à chaque création ; les types d'effet se valident contre
   l'usage du disque ; un son ou une image s'importe sous rollback, `audio.json` compris
   ([ADR-092](../_adr/ADR-092-formulaire-infere-du-document-et-ressources-liees.md), qui amende
   ADR-089). Au passage, Flame monte en 1.38.2 (`c155f50`).
