# Rotation de `activeContext.md` — 2026-11-04

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-11-04**,
poussée par l'entrée de la **vague 5 du programme P-43 → P-42 → P-44 lot 1** — la tranche 1 de
P-42 et le lot 1 de P-44, livrés sur la branche `feat/v0.5.7-p42-tranche-1-p44-lot-1`.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

## La livraison sortie

3. **Vague 2 — P-43 lot E2 : la fusion donne la rune, le feu affûte, le Puits échange, la boutique
   copie** (2026-10-02, branche `feat/v0.5.4-p43-e2-fusion-forge`, 27 commits `a9e2db6` → `82f902f`
   sur `main` à `559df08` — **fusionnée dans `main` le 2026-10-03 par la PR #48, merge `bca35c5`,
   taguée, CI/CD verte, release publiée**) — **la rune ne s'obtient plus au
   feu : elle naît de la fusion.** Chaque fusion 3 → 1 garde toutes les runes de ses trois
   exemplaires et en **offre une parmi trois**, au niveau 1, tirées au rang que la carte atteint ;
   une seule rune de chaque type par carte, *Véloce* et *Économe* à partir de la deuxième fusion
   (`minFusionRank`). Le feu de camp **affûte** : une rune gagne un niveau pour 50 or × son niveau.
   Le **Puits d'échange**, tous les trois actes, remplace la Forge de Fusion : une rune contre toute
   autre permise, aux deux tiers de son niveau, pour 50 or × le niveau donné. La boutique vend **la
   copie d'une carte du deck** et **retient son étal à son nœud** — la décision du propriétaire, à
   la levée de l'arrêt de la spec. Trois runes neuves, *Allégé*, *Précis*, *Spectral*, et trois
   sortes de delta. **Disparaissent** : la forge du feu — fentes, relances, fentes achetées, sa
   session dans `RunState` —, la capacité de runes, `pools`, `stackable`. Deux défauts antérieurs
   se ferment au passage : le second repos par le retour système, le retirage gratuit de l'étal.
   `ShopController` devient le premier Notifier du dossier des contrôleurs à écouter un autre
   provider (`ref.listen`, pas `ref.watch`). **La spec ne converge qu'au quatrième tour** : la
   troisième vérification a rendu deux constats moyens, la vague s'est arrêtée, le propriétaire a
   levé l'arrêt. La simulation, relancée en deux temps : le réalignement rend sa référence à
   l'identique, le *Spectral* du script aligné sur le jeu change 477 lignes sur 798, écart
   expliqué, référence recommitée. Note de version écrite (`4e4fa5c`). **1480 tests** (+105 sur la
   base de **1375**, celle de la porte d'entrée), `dart analyze` propre (**vérifié le
   2026-10-02**) — [ADR-106](../_adr/ADR-106-fusion-egale-forge.md), qui amende ADR-074, ADR-094,
   ADR-105 et ADR-067, et rend caducs ce qui restait d'ADR-025, ADR-039 D1 et D3, ADR-024 point 4.
