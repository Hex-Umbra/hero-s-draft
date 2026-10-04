# Rotation de `activeContext.md` — 2026-10-04

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-10-04**,
poussée par l'entrée de la **vague 3 du programme P-43 → P-42 → P-44 lot 1** — lot E3 de P-43,
« trouvaille et progression », livré sur la branche `feat/v0.5.5-p43-e3-trouvaille`. FIFO strict à
3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations intouchés.

## La livraison sortie

**Le dossier du programme — brainstorm v3, revue, simulation, méthode par vagues**
   (2026-09-22 → 2026-10-01, directement sur `main`, depuis `3cd743f` — les deux dernières passes
   de revue entrent par le commit qui suit `25c36ba` —, **documentation et outillage seulement**)
   — **le programme a désormais une conception entière et un déroulé.** Le
   brainstorm v3 remplace celui du 05/08 : ses décisions acquises, D1 à D75, refondent l'économie
   de deck — la fusion devient le moteur de progression et donne la rune, le feu de camp affûte, une
   carte se trouve après chaque combat, les signatures quittent le deck pour devenir des
   compétences de classe, chaque passif reçoit son lot de cartes. Sa
   [revue](../../docs/possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md)
   l'a vérifié contre le code puis relu quatre fois après chaque vague de décisions ; la quatrième
   passe n'a trouvé aucune contradiction, et ses deux constats de fond sont venus de la lecture des
   chemins de code, pas du document. **Un outil entre dans le dépôt** :
   `tool/simulations/d26_economy_sim.dart`, qui a mesuré les valeurs d'économie retenues et
   contredit six prémisses du brainstorm — dont celle d'un deck qui gonfle : la fusion en est le
   puits ([rapport](../../docs/possible_upgrades/30-09-2026_simulation_D26_economie_Fable5.md),
   [`_patterns/20-00`](../_patterns/20-00-simulation-de-l-economie-de-deck.md)). **La ROADMAP est
   redécoupée** : P-43 « Économie unifiée » passe premier, P-42 devient le catalogue par lots de
   passif, P-44 compte quatre lots dont le premier se livre avec P-42 ; P-18 perd ses deux derniers
   points, P-16 hérite de cinq constats de la simulation. **Trois fiches de règles rattrapent le
   code** au passage — `might` au lieu de `strength`, `eco` qui rend du mana à la pose, une boucle
   qui ne promet plus de carte après un combat normal. **Aucun effet joueur, aucune note de
   version.** **Une cinquième passe, le même jour, a relu le fichier d'orchestration lui-même**
   avant de lancer la première vague : le fond tenait, le mode d'emploi a été corrigé. **Une
   sixième a rejoué le fichier corrigé** — la porte d'entrée de la vague 1 passe, la simulation
   relancée rend sa référence à l'identique — et trouvé une prémisse que le code dément : le
   plafond de niveau d'une rune ne tient pas par la seule fusion de cartes, il se pose aux quatre
   endroits qui écrivent un niveau.
   **1187 tests**, inchangés, `dart analyze` propre (**vérifié le 2026-10-01**) —
   [ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
   [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md).
