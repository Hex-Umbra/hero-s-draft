# Rotation de `activeContext.md` — 2026-11-17

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-11-17**,
poussée par l'entrée de la **vague 7 du programme P-43 → P-42 → P-44 lot 1** — P-53, les charges
élémentaires, livrées sur la branche `feat/v0.5.9-p53-charges-elementaires`.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

## La livraison sortie

3. **Vague 4 — P-43 lot E4 : les signatures en compétences de classe** (2026-10-15 → 2026-10-16,
   branche `feat/v0.5.6-p43-e4-signatures`, 25 commits `d0ac431` → `f42a25a` sur `main` à
   `848645b`, puis six retouches de la barre demandées par le propriétaire — **fusionnée dans
   `main` le 2026-10-24 par la PR #50, merge `d99cd815`, taguée `v0.5.6`, CI/CD verte, pré-release
   publiée**) — **les signatures ne sont plus des cartes.** Deux par classe, rangées sous
   `classes/<id>/skills/` et chargées comme `SignatureData` dans `registry.signatures`, hors de
   tout pool par construction : jamais piochées, défaussées, épuisées, offertes, copiées,
   fusionnées ni runées. **Jouables dès le premier tour de chaque combat**, depuis une barre à
   gauche du HUD — cinq états, une signature à cible unique s'arme puis se joue sur l'ennemi
   touché —, **pour leur coût d'avant et une recharge de 2 tours pour les six**, dérivée du
   compteur de tours (`CombatState.signaturesReadyOn`), jamais sauvegardée ; **l'épuisement
   disparaît**. **Jouées comme une carte de leur type** par une vue de carte et la suite commune
   extraite du jeu d'une carte : passifs et reliques les voient ; *Projectile Magique* devient
   Compétence (D28) et ne déclenche plus *Marque du Mage*. Le deck de départ est **les 5 cartes
   choisies**. **Disparaissent** : la rareté `unique`, `isAcquirable`, `CardCategory`,
   `CardData.heroClass`, la réparation B5, le test de transition E3 → E4 ; le prédicat d'offre
   devient `CardData.isOfferable`, que **le draft de départ adopte**. **La spec est prête au
   quatrième tour** ; la vague s'arrête deux fois sur une question P, chaque arrêt levé par le
   propriétaire. **1694 tests** à la fin de vague (+69 sur **1625**), **1701** à la fusion,
   `dart analyze` propre (**vérifié le 2026-10-16**) —
   [ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md), qui amende ADR-094, ADR-101 et ADR-084.
