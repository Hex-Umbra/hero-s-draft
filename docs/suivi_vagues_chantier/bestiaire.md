# Suivi des vagues — Le bestiaire

**Chantier** : donner au jeu des ennemis qui se lisent mieux et qui se servent enfin de ses systèmes — P-05 dans `docs/ROADMAP.md`
**Versions** : de `0.6.1` à `0.7.0`
**Ouvert le** : 21/11/2026
**Avancement** : 2 vagues livrées sur 10 — dernière : vague 2, le 25/11/2026
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

---

## Vague 2 — version `0.6.2` — Les ennemis dans leur cadre

*Livrée le 25/11/2026.*

**Pourquoi cette vague.** Les ennemis s'affichaient comme de grandes cartes peintes, toutes de la même taille, et rien ne disait d'un coup d'œil lequel était le plus dangereux. Le combat se jouait devant une image de donjon étirée à la taille de l'écran, et le plateau rétrécissait peu à peu quand les ennemis devenaient nombreux, si bien que leurs dessins perdaient leur netteté. Les ennemis à venir sont dessinés en pixel art, à une taille précise : avant de les faire entrer, il fallait leur préparer le cadre, l'échelle et le décor sur lesquels ils seront jugés.

**Ce qu'elle apporte au jeu.** Chaque ennemi est désormais posé dans un cadre de ronce d'encre, ajouré, dont les gemmes disent le rang : un cadre plus grand et plus orné pour un ennemi plus redoutable, et le même pour un boss que pour un ennemi de son rang. L'illustration des quatre ennemis d'aujourd'hui est recadrée dans la fenêtre du cadre, en attendant leurs nouveaux dessins. Le combat se joue devant une forêt, et le plateau ne rétrécit plus : la taille des ennemis suit celle de l'écran, comme celle du héros, et reste nette dans la plupart des cas — après les premiers tests, où les ennemis paraissaient trop petits sur un grand écran haute définition. Pour qu'ils soient un peu plus grands et tiennent encore à six, leurs places se resserrent : les languettes de deux voisins peuvent se chevaucher, et c'est celle du dessus qui répond au pointeur. La barre de vie, les bonus et les altérations se rangent autour de l'illustration ; un contour cyan entoure les ennemis qu'on peut viser, un contour ambre celui qu'on a choisi, et le liseré blanc des ennemis au repos disparaît. La fiche d'un ennemi double sa carte, et se décale pour rester entière près du bord de l'écran. Sous Windows, le jeu s'ouvre en plein écran fenêtré. Une chose reste en attente : chaque ennemi reçoit aussi un fond de forêt derrière son illustration, mais les peintures d'aujourd'hui le couvrent entièrement ; il ne se verra qu'avec les ennemis redessinés. Les autres écrans, le repos, la boutique, les événements, gardent leur fond d'aujourd'hui. Rien ne change à ce que les ennemis font.
