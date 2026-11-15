# Rotation de `activeContext.md` — 2026-11-15

Sortie du bloc « 3 dernières livraisons » de `../_memory_bank/activeContext.md` le **2026-11-15**,
poussée par l'entrée de la **vague 6 du programme P-43 → P-42 → P-44 lot 1** — la tranche 2 de
P-42, livrée sur la branche `feat/v0.5.8-p42-tranche-2`.
FIFO strict à 3 : la 4ᵉ livraison sort. Recopiée **telle quelle** — chiffres, dates et affirmations
intouchés ; ses liens `../_adr/` se résolvent depuis ce dossier comme depuis le sien.

## La livraison sortie

3. **Vague 3 — P-43 lot E3 : une carte après chaque combat, la main en stat de run, l'XP par acte,
   la difficulté sur les rangs, l'affûtage hors du feu** (2026-10-03 → 2026-10-04, branche
   `feat/v0.5.5-p43-e3-trouvaille`, 34 commits `9282513` → `b6abcb5` sur `main` à `bca35c5` —
   **fusionnée dans `main` le 2026-10-04 par la PR #49, merge `0ec09ab`, taguée, CI/CD verte,
   release publiée**) — **chaque combat rapporte une carte, et les fusions cessent
   d'être rares.** Après un combat normal, une carte commune tirée parmi celles que la classe peut
   recevoir entre au deck sans choix ; en élite, une seconde à 25 % ; deux reliques rares, le
   *Registre des primes* et la *Sacoche du glaneur*, le modulent. La carte bonus du boss « XP »
   disparaît : il **monte une rune** du deck d'un niveau, deux avec la *Meule*, relique légendaire ;
   le *Rémouleur*, un événement, en monte une contre 10 % des PV max ; une mythique,
   ***Transcendance***, relève de 1 le plafond d'un type de rune pour la run — *Économe 2* devient
   possible, et le nom dit le niveau. Le *Colporteur* échange la relique la plus faible contre de
   l'or, ou contre des soins sous la moitié des PV. **La main maximale devient une stat de run**,
   lue par les six chemins de pioche — la « pioche infinie » rapportée n'est pas reproduite après
   15 920 contrôles, ADR-078 D3 est amendé ; **le prix d'un niveau est une table par acte** dans
   `assets/data/xp_curve.json`, chargée par un `loadDocument` neuf, le palier dérivé de l'acte et
   jamais stocké ; **la difficulté adaptative lit 2 × Σ des rangs de fusion**, plus le nombre de
   cartes. *Sagesse* passe mythique ; *Bénédiction* et *Flux de Mana* lisent leurs seuils en
   donnée, et la Maîtrise affichée dit ce qu'elle change vraiment. **Trois corrections** :
   l'infobulle du boss d'XP disait « x2 » ; le retour système rejouait un événement dans le même
   nœud ; la fiche des probabilités affichait des chances qu'aucun tirage n'utilise. **La spec n'a
   convergé qu'au sixième tour** : trois arrêts de la vague, chacun levé par le propriétaire le
   2026-10-03 ; deux parties, la boucle puis les sources. La simulation, relancée en deux temps :
   réalignement à diff vide, puis la relique B, l'événement de D29 et la table d'XP du jeu relancés
   chacun à part, écarts expliqués, référence recommitée (`11410f3`). Note de version écrite
   (`b6abcb5`). **1625 tests** (+145 sur la base de **1480**, celle de la porte d'entrée), `dart
   analyze` propre (**vérifié le 2026-10-04**) — [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md),
   qui amende ADR-078 D3 et complète ADR-096, ADR-097 D3, ADR-098, ADR-099 D1, ADR-101, ADR-105 D7
   et ADR-106.
