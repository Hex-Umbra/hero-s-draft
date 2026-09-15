# Archive — livraisons sorties de `activeContext.md` le 2026-09-15

Rotation FIFO. Deux livraisons — le **formulaire inféré et les ressources liées** (2026-09-14) et
l'**habillage « éditeur »** (2026-09-15) de l'éditeur de contenu — entrent dans `activeContext.md` ;
les deux ci-dessous en sortent, conservées **verbatim**, numérotation comprise.

> [!WARNING]
> Lecture seule. Ces textes décrivent l'état du projet à la date où ils ont été écrits.

---

2. **Éditeur de contenu — lot 2 et création guidée** (2026-09-06 → 2026-09-09, 51 commits) —
   créer ou modifier une entité des 7 catégories, une classe entière et ses cartes en un geste.
   `dart:io` isolé derrière un seam (le jeu a un build web), racine déduite de l'exécutable,
   **9 contrôles avant toute écriture**, écriture transactionnelle avec rollback et
   `sync_assets` en fin de geste. Le risque — un fichier invalide casse **toute** sa catégorie —
   est tenu par la règle « Valider juge ce qu'Écrire écrira »
   ([ADR-089](../_adr/ADR-089-editeur-de-contenu-seam-disque-et-validation-totale.md)). Au
   passage, `iconPath` devient `classCard` et la classe gagne `themeColor`.
   ⚠️ Le rollback ne défait ni dossiers ni images placeholder.
3. **Menu de debug — lot 1, manipulateur de run** (2026-09-05 → 2026-09-06) — un tiroir ancré au
   bord gauche de la carte et du combat, jamais un dialogue. La première conception ne gardait que
   l'écriture : **tester une mort effaçait la vraie sauvegarde**. Le mode est désormais déclaré au
   lancement et le verrou vit dans `SaveService`
   ([ADR-087](../_adr/ADR-087-run-debug-declaree-au-lancement-et-verrou-de-persis.md)). Bug
   antérieur au menu corrigé en route : le combat sortait par le sommet de pile et laissait le
   joueur coincé sur un nœud résolu
   ([ADR-088](../_adr/ADR-088-tiroir-de-debug-ancre-et-sortie-de-combat-par-sa-pr.md)) — sans
   test automatisé, `GameScreen` exigeant Flame.
