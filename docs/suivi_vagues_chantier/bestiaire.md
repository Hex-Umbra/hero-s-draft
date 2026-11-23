# Suivi des vagues — Le bestiaire

**Chantier** : donner au jeu des ennemis qui se lisent mieux et qui se servent enfin de ses systèmes — P-05 dans `docs/ROADMAP.md`
**Versions** : de `0.6.1` à `0.7.0`
**Ouvert le** : 21/11/2026
**Avancement** : 1 vague livrée sur 10 — dernière : vague 1, le 22/11/2026
**Ce qui fait foi techniquement** : le [chantier du bestiaire](../chantier_bestiaire/README.md) tient le journal de chaque vague ; les décisions de conception sont dans le [cadrage](../possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md), §1
**Modèle** : [`_modele_suivi.md`](_modele_suivi.md)

---

## Le chantier en quelques lignes

Pendant les cinq premiers actes, le joueur ne croise que deux ennemis, le Slime et le Gobelin, qui répètent la même attaque. Aucun ennemi ne pose de Gel, de Feu, de Foudre ni de Poison sur le héros, alors que le jeu sait le faire. Et ce qu'un ennemi s'apprête à faire, ce qu'il porte comme bonus ou comme altération, se lit mal à l'écran.

Le chantier commence par l'écran : une première vague refait ce que le joueur voit d'un ennemi en combat, sans rien changer à ce que les ennemis font. Les vagues suivantes, qui ne sont pas encore ouvertes, donneront d'abord aux ennemis un cadre qui dit leur rang, un fond et une salle de combat redessinée ; puis des ennemis qui frappent avec les mêmes effets que les cartes, des familles reconnaissables, et une meute de rats menée par un chef qui appelle les siens. Le programme a été revu le 23/11 : après les trois premiers rangs d'ennemis, une vague retravaillera la difficulté du jeu, sur ce que les nouveaux ennemis auront montré en partie ; viendront ensuite les ennemis les plus hauts, puis de vrais boss.

---

## Vague 1 — version `0.6.1` — Ce qu'on voit d'un ennemi

*Livrée le 22/11/2026.*

**Pourquoi cette vague.** Ce qu'un ennemi s'apprêtait à faire se lisait dans un panneau encombré de ses PV, que sa carte affichait déjà. Au-dessus de sa carte, un petit badge serrait trois chiffres — sa Puissance, son armure, ses PV — et sa barre de vie n'occupait qu'une moitié de la carte. Ses bonus et ses altérations tenaient en icônes sans nom : pour savoir ce qu'était l'une d'elles et combien de tours elle durait, il fallait le deviner. Avant d'ajouter des ennemis qui posent du Gel, du Feu ou du Poison, il fallait que l'écran sache les montrer.

**Ce qu'elle apporte au jeu.** Le panneau des intentions ennemies tient en trois colonnes : le niveau, écrit « Niv. 1 », le nom, puis une pastille qui dit ce que l'ennemi va faire ; passer la souris dessus le dit en une phrase. Au-dessus de chaque ennemi il ne reste qu'une barre de PV, à la largeur de sa carte. De part et d'autre des cartes, celles des ennemis comme celle du héros, deux languettes rangent les bonus à gauche et les altérations et les charges à droite ; à la souris, survoler la carte les déroule pour lire le nom, la valeur et la durée de chacune. Et toucher un ennemi quand aucune carte n'est sélectionnée ouvre sa fiche : sa carte s'agrandit, le reste du plateau s'estompe, et tout ce qu'on sait de lui s'écrit à côté — ses PV, son armure, sa Puissance, ce qu'il prépare, ses bonus, ses altérations. La Puissance d'un ennemi ne s'affiche plus au-dessus de sa carte : elle se lit dans sa fiche. Le tutoriel suit. Rien ne change à ce que les ennemis font. Une chose reste en attente : la barre sait montrer l'armure d'un ennemi, par un voile bleu qui recule à mesure qu'on l'entame, mais aucun ennemi du jeu ne gagne encore d'armure — ce voile ne se verra qu'avec les ennemis à venir. Après le test, une précision dans la fiche : sous chaque bonus, altération et charge, une phrase dit d'un coup d'œil ce qu'il fait — le Gel au seuil fait perdre son action suivante, le Feu explose sur les voisins. La vague emporte enfin une correction : un combat gagné pendant le tour des ennemis ne rouvre plus de tour.
