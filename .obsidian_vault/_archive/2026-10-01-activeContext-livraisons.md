# Rotation de `activeContext.md` — 2026-10-01

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-10-01**,
poussée par l'entrée du **dossier du programme** — brainstorm v3, revue, simulation, méthode par
vagues (`3cd743f` → `a850968`). FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** —
chiffres, dates et affirmations intouchés.

## La livraison sortie

**P-41 lot D, partie 1 — le tutoriel enseigne la classe qu'on a choisie**
(2026-09-20, **fusionné dans `main` par la PR #44**, merge `54c28dd`, 9 commits,
`30d48dc` → `639a222`, branche `feat/p41-lot-d-tutoriel`) — **le tutoriel cesse d'enseigner
une règle que la classe choisie ne suit pas.** Trois étapes arrêtaient chacune de court-circuiter
un point de passage qui existait déjà : l'étape 02 déplie les passifs que `availablePassivesFor`
ouvre à la classe — dans le **`ClassPassiveList` de l'écran de sélection**, le widget de
production et non une seconde implémentation (spec §1.4) — et retaper la classe déjà choisie
replie sa carte au lieu de reposer son passif. L'étape « Armure & Dégâts » fait passer son gain
de démonstration par `StatGains.apply` et les `statRules` de la classe au lieu d'écrire 4 Armure
en dur : elle se joue **en deux temps** (le gain, puis le coup), son panneau droit part de 0, son
titre est **généré** depuis la règle qui vise l'Armure (`shortTitle`, deux clés ARB neuves) et la
règle est écrite en clair sous les panneaux par `StatRuleLabel.describe`. L'étape « Jouer des
cartes » **mesure le gain réel** de part et d'autre de `playCard` au lieu de lire la valeur
imprimée sur la carte. Les deux acquis que le lot B avait livrés sans les verrouiller —
`critChance` forcé à 0, conversion d'armure appliquée par `playCard` — passent sous test.
**Aucun mécanisme nouveau, donc aucun ADR** : la livraison applique ADR-081, ADR-090 et
ADR-097. **1159 tests** (+24), `dart analyze` propre.
