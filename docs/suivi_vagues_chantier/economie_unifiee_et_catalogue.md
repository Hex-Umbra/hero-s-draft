# Suivi des vagues — Économie unifiée et catalogue

**Chantier** : refaire la manière dont un deck se construit, puis donner à chaque classe ses compétences et ses cartes — P-43, P-42 et P-44 lot 1 de `docs/ROADMAP.md`
**Versions** : de `0.5.2` à `0.6.0`
**Ouvert le** : 01/10/2026
**Avancement** : 2 vagues livrées sur 8 — dernière : vague 1, le 02/10/2026
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
