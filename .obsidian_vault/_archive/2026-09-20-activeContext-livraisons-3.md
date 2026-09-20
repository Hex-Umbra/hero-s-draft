# Rotation de `activeContext.md` — 2026-09-20 (3ᵉ du jour)

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-09-20**,
poussée par l'entrée de **P-41 lot D partie 2** (la console, PR #45). FIFO strict à 3 :
la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations intouchés,
seuls les chemins relatifs ont été rebasés d'un niveau pour rester résolvables depuis ce répertoire.

## La livraison sortie

**P-41 lot C, partie 1 — les récompenses de niveau deviennent de la donnée** (2026-09-18,
**fusionné dans `main` par la PR #42**, merge `152fbcc`, 11 commits, `face77b` → `9a2f375`) —
**le jeu ne change pas** : seule la provenance des valeurs change. Les huit récompenses — six
tirables, deux mythiques, séparées par un champ `pool` — vivent sous
`assets/data/level_up_rewards/`, neuvième source d'entités. `LevelUpRewardType`, son
`rng.nextInt(6)` **indexé sur l'ordre de l'énumération** et 17 clés ARB disparaissent ; les deux
régimes de valeur concurrents (multiplicateur générique **et** cascade de `if`) cèdent à une table
`values` explicite, celle-là même dont l'absence avait laissé un légendaire retomber sur la valeur
d'un commun. Les descriptions deviennent des **gabarits à trous** (`{amount}`, `{passive}`,
`{effect}`) : composer l'*Affinité* avec le passif actif est une règle unique, non une branche par
récompense. L'application du gain quitte l'écran de draft pour `PlayerStatsManager`, `switch`
exhaustif sur `RewardStat` ; la prose du tutoriel lit le registre par une fonction pure, ADR-081
intact. **Un seul texte joueur bouge** : la liste des mythiques du tutoriel perd ses articles.
**1065 tests** (+44), `dart analyze` propre —
[ADR-098](../_adr/ADR-098-recompenses-de-niveau-en-donnee-et-gabarits-a-tr.md).
