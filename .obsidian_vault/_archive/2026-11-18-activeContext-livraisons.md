# Rotation de `activeContext.md` — 2026-11-18

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-11-18**,
poussée par l'entrée de la **vague 8 du programme P-43 → P-42 → P-44 lot 1** — P-42 tranche 3,
Sanctifié, Carnage, Marque, livrée sur la branche `feat/v0.6.0-p42-tranche-3`.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

## La livraison sortie

3. **Vague 5 — P-42 tranche 1 et P-44 lot 1 : les lots de cartes par passif, la profondeur, les
   évolutions de signature** (2026-10-25 → 2026-11-04, branche
   `feat/v0.5.7-p42-tranche-1-p44-lot-1`, 81 commits `da233ba6` → `22da17b5` sur `main` à
   `d99cd815` — **fusionnée dans `main` le 2026-11-09 par la PR #51, merge `fbfa839a`, taguée
   `v0.5.7`, CI/CD verte**) — **le deckbuilding existe.** **Partie 1,
   le moteur** : une carte peut coûter des PV ou de l'Armure, sous une seule règle — jamais
   mortelle — et un seul débit ; grandir avec une source (`scaleWith`, six sources, arrondi bas) ;
   frapper plusieurs fois, la Puissance par coup au `mightRatio` ; Vulnérable, Faiblesse et Gel
   comptent leurs points (25 % par point, plafonds 4, 2, 3 — réponse P-1) ; un seul bonus de
   statut par résolution ; cinq runes de mécanisme, *Perforant*, *Vampirique*, *Ricochant*,
   *Résonant* — dont l'écho ne déclenche aucun événement (P-3) — et *Transfusion*. **Partie 2, la
   forme C** : chaque passif a son dossier `cards/<passif>/`, qui injecte `CardData.passive` ;
   trois lots de six cartes, Rempart, Sang, Arcaniste ; **un passif sans lot quitte la
   sélection** — un par classe, le Mage sur *Flux de Mana* ; `isOfferable` lit le passif actif ;
   le draft de départ prend 2 cartes du lot et 3 neutres ; *Focalisation* supprimée. **Partie 3,
   les évolutions** : tous les 5 niveaux, chaque signature gagne une évolution choisie parmi trois
   de son pool (3 mineures, 4 majeures), sur un écran à trois rouleaux ouvert par le rideau de la
   carte ; la tuile de combat passe en icônes, avec un badge et des puces, et déroule sa liste à
   l'appui long dans un calque (PN12 (d), P-5) ; une table d'icônes d'effet unique,
   `effect_icons.json` (P-6) ; une entrée de debug (P-7) ; la sauvegarde sous
   `signatureEvolutions`. **Puis une série de corrections du propriétaire** (D78 à D82) : plus de
   tirage, tout ce que le palier admet se choisit ; les deux signatures sur un seul écran ; un rideau
   par ce qui attend — bandeau et flèches, bandeau, médaillon ; les signatures évoluées en tête de
   Mon Deck ; plus de badge « Passifs » sans deuxième passif. **Quatre arrêts**, chacun levé par le propriétaire : P-1 à P-3 (25/10),
   PN12 et PN13 (03/11), P-5 et P-6 (03/11), D77 (04/11). **Deux décisions de méthode** : D76,
   une vague de plus (ADR-110) ; D77, plus de tests d'écran (ADR-113). Simulation non relancée
   (ADR-108 D5). Note de version écrite (`22da17b5`), corrigée sur place (`8a5d92b9`). **1620 tests** (−81 sur la
   base de **1701**, celle de la porte d'entrée ; le tri de D77 en a retiré 392), `dart analyze`
   propre (**vérifié le 2026-11-09**) — [ADR-110](../_adr/ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md)
   à [ADR-115](../_adr/ADR-115-le-choix-libre-des-evolutions-et-les-rideaux-de-la-carte.md).
