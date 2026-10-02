# Rotation de `activeContext.md` — 2026-10-02

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-10-02**,
poussée par l'entrée de la **vague 1 du programme P-43 → P-42 → P-44 lot 1** — lots E0 et E1 de
P-43, livrés sur la branche `feat/v0.5.3-p43-e0-e1`. FIFO strict à 3 : la 4ᵉ livraison sort.
Recopiée **telle quelle** — chiffres, dates et affirmations intouchés.

## La livraison sortie

**P-41 lot D, partie 2 — la console rattrape l'identité de classe** (2026-09-20, **fusionné
   dans `main` par la PR #45**, merge `d27edc9`, 5 commits, `70fea1d` → `6c1a8dd`, branche
   `feat/p41-lot-d-console`) — **l'outil qui écrit la donnée apprend enfin ce que trois lots y ont
   mis.** L'éditeur laissait passer `"mode": "convrt"` : les trois clés de `statRules` sont
   bornées, et leur vocabulaire est **lu sur `StatRule`** — `status:might` ne s'écrit pas
   `statusMight`, et seul le parseur connaît la correspondance. La création guidée d'une classe
   écrit un **passif de départ** dérivé de l'identifiant de la classe, avec `classes: [<id>]` : une
   classe créée n'avait jusque-là aucun passif disponible — choix vide à la sélection, et
   `referential_integrity_test` rouge *après* écriture des fichiers. Pour que ce passif ne soit pas
   refusé par une référence vers une classe que le registre ignore encore, `EntityValidator` gagne
   **`pendingIds`** — ce que la même transaction va écrire —, le trou décrit dans le code depuis
   P-30 enfin nommé ; l'unicité, elle, continue de lire le registre seul. Les récompenses de niveau
   deviennent la **8ᵉ catégorie éditable**, par une entrée de table. Le menu de debug règle les
   cibles de la Puissance (puces générées, la dernière non retirable : `HeroData` refuse une liste
   vide) et affiche classe, règles de stat et passif actif en lecture seule, **dans le vocabulaire
   du fichier**. **Aucun effet joueur.** **1179 tests** (+20), `dart analyze` propre —
   [ADR-100](../_adr/ADR-100-console-de-contenu-vocabulaire-du-moteur-et-ident.md).
