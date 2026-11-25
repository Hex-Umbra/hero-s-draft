# Rotation de `activeContext.md` — 2026-11-25

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-11-25**,
poussée par l'entrée de la **vague 2 du bestiaire** (P-05, les cadres de tier et les décors), livrée sur la
branche `feat/v0.6.2-cadres-et-decors`.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

3. **Vague 8 — P-42 tranche 3 : Sanctifié, Carnage, Marque, les neuf passifs jouables**
   (2026-11-18, branche `feat/v0.6.0-p42-tranche-3`, 13 commits `eb7945fb` → `147f564c` sur `main`
   à `5d894785` — **fusionnée dans `main` le 2026-11-19 par la PR #56, merge `84a1ee34`, taguée
   `v0.6.0`, CI/CD verte**) — **chaque passif a son lot.** **Le
   déclencheur de D34** : `onDamagingCardPlayed`, que la suite commune envoie après l'événement du
   type si la carte porte un effet `damage` — un seul prédicat, `EffectiveCard.dealsDamage`, effets
   ajoutés compris, sans lire la cible ni les dégâts ; aucune relique ne l'écoute. ***Marque du
   Mage*** l'écoute : la première carte de dégâts du tour, Attaque ou Compétence, signature
   comprise, **qui vise un seul ennemi sans le tuer**, lui pose 2 Vulnérable — une carte de groupe
   ne marque ni ne consomme (A3 (c)), une carte qui tue sa cible non plus (A4 (ii)) ; *Projectile
   Magique* marque de nouveau, hors *Nova*. **La *Source de Vie*** (`hp_regen`, D55) : posée par
   *Prière*, elle rend ses PV après le tic, bornée aux PV max, jamais à un porteur mort, symétrique
   héros / ennemis ; le cœur rose du soin, dix-huitième sorte d'icône. **Le nom du statut** de la
   croissance `targetStatus` se lit dans la langue du joueur (clé `statusName`). **Trois lots** :
   Sanctifié (la Faiblesse, *Métallisation*, *Prière*), Carnage (quatre Attaques de groupe,
   *Exécution* sur `targetMissingHp`), Marque (les quatre élémentaires, *Exploitation* sur
   `targetStatus`, *Salve* 2 × 3) — dix fichiers neufs, six `git mv` ; neuf neutres restent ; les
   trois derniers passifs se démasquent par la donnée. **Deux réponses P au lancement** (Q12 oui,
   D43 non), **un arrêt** sur A3 et A4, levé par le propriétaire le 18/11 ; spec convergée au
   premier tour, plan prêt au deuxième ; SDD en sept tâches, revue d'ensemble « prête avec
   corrections » et sa passe (`a65bf4c7`). Note de version écrite (`147f564c`). **1826 tests**
   (+50 sur la base de **1776**, celle de `main`), `dart analyze` propre (**vérifié le
   2026-11-18**) — [ADR-118](../_adr/ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md),
   qui complète ADR-112, ADR-111 et ADR-116. **Clôt P-42.** **Puis six corrections de fin de vague**
   (2026-11-19, `70fce82b` → `ee60f62f`) : la mort efface la sauvegarde, l'affûtage ne liste que l'affûtable,
   les intentions en lignes compactes à infobulles, un arbitre du survol de la main, la
   Puissance sur les tuiles de signature, « -12 PV Max » — **1859 tests** (vérifié le 2026-11-19), ADR-119.
