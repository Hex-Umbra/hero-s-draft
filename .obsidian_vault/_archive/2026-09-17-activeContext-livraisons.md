# Archive — livraison sortie de `activeContext.md` le 2026-09-17

Rotation FIFO. La livraison **P-49 — passifs partagés, éligibilité déclarée par le passif et
Maîtrise hybride** (2026-09-17, branche `feat/p49-passifs-partages`) entre dans `activeContext.md` ;
celle ci-dessous en sort, conservée **verbatim**, numérotation comprise.

> [!WARNING]
> Lecture seule. Ces textes décrivent l'état du projet à la date où ils ont été écrits.

---

3. **Éditeur de contenu — habillage « éditeur »** (2026-09-15, 14 commits, `78f342c` → `2c9ba6d`) —
   présentation seule, `lib/services/` intact. Onglets de type et segmenté Créer / Modifier
   remplacent les niveaux de l'arbre ; un explorateur groupe les entités par propriétaire en mode
   Modifier ; le formulaire devient en-tête de fichier et sections, la mécanique un inspecteur
   (grille de nombres, sous-panneaux numérotés) ; une barre d'actions fixe porte le bandeau d'issue,
   dont une faute ramène à son champ. **Toute couleur est un jeton nommé**, et **tout
   sélectionnable suit un contrat de choix** — fond opaque, 4,5:1, `selected`, indice hors couleur —
   porté par `ChoiceSurface` ([ADR-093](../_adr/ADR-093-habillage-editeur-jetons-nommes-et-contrat-de-choix.md)).
