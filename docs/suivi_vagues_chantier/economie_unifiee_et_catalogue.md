# Suivi des vagues — Économie unifiée et catalogue

**Chantier** : refaire la manière dont un deck se construit, puis donner à chaque classe ses compétences et ses cartes — P-43, P-42 et P-44 lot 1 de `docs/ROADMAP.md`
**Versions** : de `0.5.2` à `0.6.0`
**Ouvert le** : 01/10/2026
**Avancement** : 4 vagues livrées sur 8 — dernière : vague 3, le 04/10/2026
**Ce qui fait foi techniquement** : le [fichier d'orchestration](../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md) — son journal (§2) donne l'état de chaque vague ; ses décisions de conception sont dans le [brainstorm v3](../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1
**Modèle** : [`_modele_suivi.md`](_modele_suivi.md)

---

## Le chantier en quelques lignes

Aujourd'hui, le deck ne grandit presque pas pendant une partie, fusionner trois cartes rapporte moins que les améliorer une par une, et les trois classes piochent dans les mêmes cartes. Le chantier change ces trois choses, dans cet ordre : d'abord **la manière dont un deck se construit** — trouver des cartes, les fusionner, améliorer leurs runes —, puis **les compétences propres à chaque classe**, enfin **des cartes pensées pour chaque passif**. Une vague de préparation, puis sept vagues qui livrent chacune une version du jeu, jusqu'à la `0.6.0`.

---

## Vague 0 — sans version — la préparation

*Faite le 01/10/2026.*

**Pourquoi cette vague.** Le chantier touche à presque tout ce qui fait une partie : les cartes que l'on trouve, la fusion, les runes, le feu de camp, les compétences de classe, puis une cinquantaine de cartes neuves. Avant d'y toucher, il fallait décider dans quel ordre le faire pour que le jeu reste jouable à chaque étape, et vérifier, en simulant un grand nombre de parties, que les nouvelles règles tiennent ensemble sur quinze actes.

**Ce qu'elle apporte au jeu.** Rien de visible : aucune version ne sort, rien ne change dans une partie. Elle fixe le plan — sept vagues qui livrent chacune une version, des règles arrêtées et des valeurs mesurées plutôt que devinées. À partir de la vague suivante, chaque section de ce document décrit un changement que l'on peut jouer.

---

## Vague 1 — version `0.5.3` — une Puissance qui tient ses promesses, des runes qui disent ce qu'elles font

*Livrée le 02/10/2026.*

**Pourquoi cette vague.** Deux choses n'allaient pas. La Puissance d'abord : le Berserker changeait toute son Armure en Puissance, et deux bonus de Puissance de durées différentes se confondaient — *Forme Démoniaque* puis *Mur de Fer* donnaient 12 Puissance pendant quatre tours, bien plus que ce que promettait chacune des deux cartes. Les runes ensuite : la forge proposait des runes qui ne faisaient rien sur la carte choisie, comme *Endurci* sur une carte sans Armure ou *Économe* sur une carte gratuite, et *Économe* ou *Véloce* pouvaient monter de niveau et s'empiler jusqu'à rendre la pioche et le mana sans fin. Il fallait remettre de l'ordre maintenant : dès la version suivante, c'est la fusion qui donnera les runes, et elle a besoin de runes qui savent où elles peuvent aller et jusqu'où elles peuvent monter.

**Ce qu'elle apporte au jeu.** Le Berserker ne convertit plus que la moitié de son Armure, arrondie au-dessus, et sa carte de classe comme le tutoriel le disent ; deux bonus de Puissance venus de sources différentes restent séparés, chacun avec sa durée. *Tranchant* et *Endurci* donnent désormais 15 % de la valeur de la carte par niveau, au moins 1, au lieu de 2 : moins sur une petite carte, plus sur une grosse, et davantage à mesure que la carte monte en rareté. La forge ne propose plus une rune inutile ou dangereuse pour la carte ; *Économe*, *Véloce*, *Congelant* et *Persistant* restent au niveau 1 partout, une carte n'en porte plus deux, et une carte qui ne peut plus rien recevoir est refusée au feu de camp avec un message. Chaque fusion fait gagner au moins 1 à chaque chiffre de dégâts, d'Armure, de soin ou d'altération, mais la pioche et le mana rendu ne grandissent plus avec la rareté. Les runes de brûlure et de choc renforcent enfin ce que l'ennemi porte déjà. Le reste ne bouge pas : les écrans sont les mêmes, et les runes s'obtiennent encore au feu de camp — c'est la prochaine version qui les fera venir de la fusion.

---

## Vague 2 — version `0.5.4` — la fusion devient la forge

*Livrée le 02/10/2026.*

**Pourquoi cette vague.** Fusionner trois cartes rapportait trop peu : la carte montait d'une rareté, mais les runes venaient du feu de camp, que l'on visitait souvent, si bien que c'était la forge, et non la fusion, qui faisait progresser un deck — et une carte fusionnée perdait les runes en trop. La Forge de Fusion, elle, ne servait qu'à réunir des runes en double. Cette vague fait de la fusion le moteur du deck : la fusion donne les runes, le feu de camp les améliore, le Puits les échange, la boutique fournit des doublons. Elle vient maintenant parce que la vague précédente a appris aux runes où elles peuvent aller et jusqu'où elles montent, et avant la suivante, qui fera trouver une carte après chaque combat : ces cartes auront besoin de la fusion pour compter.

**Ce qu'elle apporte au jeu.** Chaque fusion de trois cartes offre une rune au choix parmi trois — moins quand moins conviennent à la carte —, et la carte garde toutes les runes de ses trois exemplaires, sans limite ; une carte ne porte qu'une rune de chaque sorte, et *Véloce* comme *Économe* n'arrivent qu'à partir d'une carte rare. Le feu de camp affûte : une rune gagne un niveau pour 50 or fois son niveau, à la place du repos ou de l'oubli ; la forge du feu disparaît, avec ses emplacements et ses relances. Le Puits d'échange remplace la Forge de Fusion : tous les trois actes, il change une rune d'une carte contre une autre, aux deux tiers de son niveau. La boutique vend la copie d'une carte du deck, sans ses runes, et garde son étal si l'on sort puis revient ; ses cartes runées n'ont plus de runes qu'une fusion n'aurait pu leur donner. Trois runes arrivent : *Allégé* (la carte coûte 1 Mana de moins), *Précis* (des coups critiques plus fréquents) et *Spectral* (plus de dégâts, mais la carte s'épuise). Les cartes de classe ne reçoivent plus de rune. Ce qui reste en attente : en `0.5.4`, les fusions restent rares, faute de doublons — la version suivante fera trouver une carte après chaque combat.

---

## Vague 3 — version `0.5.5` — une carte après chaque combat

*Livrée le 04/10/2026.*

**Pourquoi cette vague.** Depuis la version précédente, c'est la fusion qui donne les runes ; mais un deck ne réunissait presque jamais trois exemplaires d'une même carte, si bien que les fusions restaient rares et que ce nouveau moteur tournait à vide. La difficulté des combats grandissait avec le nombre de cartes du deck, ce qui punissait celui qui en ramassait ; le prix d'un niveau montait si vite que l'on cessait de progresser au milieu de la partie ; et seules les visites au feu de camp faisaient monter une rune. Cette vague nourrit la fusion en faisant trouver des cartes, et ouvre d'autres chemins pour améliorer les runes. Elle vient maintenant parce que la fusion sait désormais accueillir ces cartes, et avant la suivante, qui sortira du deck les cartes de classe pour en faire des compétences.

**Ce qu'elle apporte au jeu.** Chaque combat normal rapporte une carte commune, tirée parmi celles que la classe peut recevoir et annoncée à l'écran ; un combat d'élite en donne une, et une seconde une fois sur quatre : les doublons s'accumulent, et les fusions deviennent fréquentes. Deux reliques rares en ajoutent, le *Registre des primes* et la *Sacoche du glaneur*. La difficulté se règle désormais sur ce que les fusions ont fait du deck, et non plus sur sa taille. Un niveau coûte 115 XP à l'acte 1, 200 à l'acte 2, puis selon l'acte : on gagne environ deux niveaux par acte, jusqu'au bout de la partie. Le boss d'XP ne donne plus de carte : avec le triple d'XP et d'or, une rune du deck gagne un niveau — deux avec la *Meule*, une relique légendaire. Deux événements arrivent : le *Rémouleur*, qui fait monter une rune au choix contre 10 % des PV max, et le *Colporteur*, qui reprend la relique la plus faible contre de l'or, ou contre des soins sous la moitié des PV. *Transcendance*, une récompense mythique, relève d'un niveau le plafond d'une sorte de rune pour toute la partie : *Économe 2* ou *Véloce 2* deviennent possibles. En échange, *Sagesse* devient une récompense mythique qui ne donne plus qu'un point de Mana, et *Flux de Mana* ne descend plus sous deux Compétences. Ce qui reste en attente : les cartes de classe sont encore dans le deck, sans rune et jamais trouvées après un combat ; elles en sortiront à la version suivante.
