# Vague 2 — `0.6.2` — tests manuels

**Branche** : `feat/v0.6.2-cadres-et-decors` · **Compte rendu** : [2026-11-25-bestiaire-vague-2-compte-rendu.md](2026-11-25-bestiaire-vague-2-compte-rendu.md)
**Testé le** : <JJ/MM/AAAA>, sur `<sha>`, sur <plateforme>
**Résultat** : <K> ✅ · <L> ❌ · <M> non testés

**Ce que la vague change, en bref.** Rien ne change à ce que les ennemis font ; change ce que le joueur voit du plateau. (1) Chaque ennemi est une carte **composée** : sa créature dans une fenêtre de 64 × 96 pixels de cadre, entourée d'un **cadre de tier** (cinq images, de 88 × 120 à 120 × 152 pixels de cadre ; seuls les tiers 1 à 3 s'atteignent en jeu). (2) Le plateau n'est plus à l'échelle continue : sa taille **suit celle du héros** (B90) : un **palier** en pixels entiers quand elle en est à 10 % près (×2 en 1080p, ×3 en 1440p, ×4 en 4K), lissée sinon (3,31 sur 2880 × 1800 à 200 % dans Chrome, réduite sous le 1080p), et **le boss n'est plus agrandi** : il porte le cadre de son tier à la taille des autres. (3) Le décor de combat est une **forêt neuve** de 640 × 360 pixels, à la place du donjon étiré. (4) Les quatre **anciens sprites** sont recadrés sur leur illustration et lissés. (5) La **rangée** des ennemis est calculée pour six places de 117, deux languettes voisines pouvant se superposer ; les **languettes** sont réduites d'un quart (B92). (6) La barre, les languettes, le contour de ciblage, la zone d'appui et la fiche de la vague 1 sont recalés sur la fenêtre ; la fiche passe au **double** de la carte (× 2 au lieu de × 1,25). (7) La fenêtre Windows s'ouvre **maximisée**. (8) Un fond de fenêtre (trois fonds de forêt) est tiré, mais caché par les illustrations d'aujourd'hui.

**Repères communs.**
- **Deux sortes de run.** « JOUER » lance une run normale, sauvegardée. « RUN DEBUG » (colonne DEBUG de l'accueil, build debug seulement) passe par la même sélection de classe et le même draft, mais ne sauvegarde jamais rien ; seule elle a le tiroir « DEBUG » au bord gauche. **Le menu de debug gagne, en combat, la section « Faire apparaitre »** : un bouton par ennemi du jeu (« + Gobelin (tier 1) »…), aux PV et à la Puissance d'un combat normal de l'acte courant, jusqu'à **six** sur le plateau — un combat n'en place jamais plus de cinq ; et la section **« Bonus (languette de gauche) »** : « Heros : » et « 1. <nom> : » par ennemi, avec « +1 Puissance », « +1 Éveil de Puissance », « +1 Métallisation », « +1 Source de Vie », « +1 Source de Mana » (valeur 1, trois tours), puis « Retirer les bonus ».
- **En combat, un seul onglet, « Combat »** : « PV (max N) », « Mana (max N) », « Armure » (ceux **du héros**), « Soin complet », « Mana plein » ; « Ennemis (N) », une ligne par ennemi (« 1. <nom> (PV/PV max) », champ chiffré, bouton « 0 PV ») ; « Tous les ennemis a 0 PV », « Gagner le combat », « Perdre le combat », « Sauter la phase ennemie » ; la section « Charges » : « Heros : » et « 1. <nom> : » par ennemi, avec **« +1 Gel »**, **« +1 Feu »**, **« +1 Foudre »**, et en bas « Retirer les charges ». Un champ chiffré se valide en tapant la valeur puis Entrée ; ne jamais monter les PV d'un ennemi au-dessus de son max.
- **Sur la carte du monde**, onglet « Run » : **« Acte suivant (regenere la carte) »** et le champ **« Acte (sans regenerer la carte) »**. Les ennemis par acte : **acte 1 à 5 : Slime, Gobelin (tier 1) ; acte 6 à 10 : Squelette (tier 2) ; acte 11 et plus : Orc Furieux (tier 3)**. Un combat normal compte **au plus un ennemi à l'acte 1, un de plus par acte, plafond de cinq** : c'est un plafond, rejouer un combat si le tirage en donne moins. Fixer l'acte à **5** donne jusqu'à cinq ennemis de tier 1 ; pour des **tiers mêlés** (T11), fixer l'acte à 6 ou 11 ; si le combat tiré n'est pas mêlé, en rejouer un. Le **boss** est sur le nœud boss de la carte du monde, à l'acte voulu.
- **Statuts utiles** : « +1 Gel » trois fois sur un ennemi le gèle (seuil 3, gangue de givre) ; « +1 Feu » ou « +1 Gel » donne une languette à droite ; tout bonus de la section « Bonus » du menu de debug donne une languette à gauche, comme la **Puissance** de l'Orc (intention « Buff Puissance »). « +1 Foudre » jusqu'au seuil charge le halo.
- **Carte focalisée / signature armée** : prendre une carte d'attaque en main (elle se lève et les ennemis prennent le contour cyan), ou armer une signature qui cible un ennemi (*Frappe Téméraire* du Berserker, *Châtiment* du Paladin). Aucune main n'est garantie : au besoin, ajouter l'attaque voulue au deck sur la carte du monde, onglet « Deck ».
- **Fenêtre et plateforme.** Les mesures sont celles de la **build Windows** ou du **build web**, à **1920 × 1080** (palier ×2 net : 1 pixel de cadre = 2 pixels d'écran, 1 pixel de créature = 1 pixel d'écran, 1 pixel de décor = 3 pixels d'écran) et à **1280 × 720** (palier ≈ 1,422, lissé, la rangée descendue sous la barre du haut, B93). **Avertissement** : Smart App Control a déjà bloqué sur ce poste l'exécutable Windows fraîchement construit ; si un test en dépend (T2, T21), vérifier d'abord qu'il se lance, sinon passer par le build web de debug et noter « Windows non testé ».
- **Mesures de référence, en pixels d'écran à 1920 × 1080, ×2** : une carte de tier 1 mesure 176 × 240 (cadre 88 × 120), de tier 2 192 × 256, de tier 3 208 × 272 ; la fenêtre de la créature fait toujours 128 × 192 ; la barre de PV 176 × 26, son haut à 154 pixels de cadre au-dessus du centre de la fenêtre (77 × 2) ; le centre des fenêtres à 0,21 de la hauteur (227 pixels) ; deux ennemis voisins ont leurs centres à 248 pixels (six ennemis), 272 (cinq), 326 (quatre), 478 (deux) ; une rangée de cinq mesure environ 1322 pixels. La fiche ouverte est la carte au **double** (tier 1 : 352 × 480 à ×2, soit × 4 le pixel de cadre).

## À tester d'abord
<!-- du plus risqué au moins risqué -->
**Ce qui peut casser le jeu ou son entrée**
1. **T17** — La rangée sous la barre du haut, en 1280 × 720 et dans la fenêtre restaurée (correction B93).
2. **T25** — Les languettes réduites d'un quart : cadre, émojis, textes (correction B92).
3. **T24** — Les ennemis encore un peu plus grands, et la carte dessinée par-dessus qui reçoit le pointeur (correction B91, M18, M23).
4. **T23** — Les ennemis à leur taille sur un écran haute définition : 2880 × 1800 à 200 % (correction B90, M18) ; validé sous B90, remplacé par T24.
5. **T1** — L'appui : épine du cadre, décor entre deux vrilles, haut de barre, languettes au repos et déroulées vers l'intérieur, ennemis **et** héros (M12).
6. **T2** — La fenêtre Windows ouverte maximisée, « Restaurer », relance, sans éclair (M22).
7. **T3** — Le plateau suit la fenêtre : restaurée, maximisée, plein écran, et un écran à 125 % (M16, M18).

**La fiche, qui double**
8. **T4** — La fiche doublée : barre à la hauteur des autres, bord de l'écran, tier 3, la carte sur le héros (M10).
9. **T5** — La fiche suit le redimensionnement (M17).

**Le plateau**
10. **T6** — Cinq ennemis tiennent dans l'écran, cadres sans chevauchement (M7).
11. **T7** — Un, deux, trois ennemis s'écartent comme avant (M8).
12. **T8** — Les tiers : cadres 1, 2, 3, plus grands, même fenêtre (M1, M2) ; tiers mêlés sur le même sol (M3).
13. **T9** — Le boss : le cadre de son tier, plus d'agrandissement (M15).

**Les gestes de ciblage**
14. **T10** — Glisser-déposer une carte sur le cadre d'un ennemi de tier 3 (M13).
15. **T11** — Le contour cyan, puis ambre ; plus de liseré blanc (M11) — et le recouvrement du trait sombre du cadre.
16. **T12** — Les languettes contre le gabarit, vers l'extérieur, vers l'intérieur au bord (M9).
17. **T13** — Coup, gel, Foudre : textes flottants, gangue, halo, teinte (M14) — et la gangue de gel.

**Ce que le joueur regarde**
18. **T14** — Les quatre anciens sprites : recadrés, lissés (M6).
19. **T15** — Le décor : la forêt neuve, nette (M4).
20. **T16** — Les grilles de pixels : cadre net, rien ne se brouille (M5).
21. **T18** — Un écran 1440p, 4K ou à 125 % (M18).

**Ce qui ne doit pas bouger, ou ne se voit pas**
22. **T19** — Le repos, la boutique, un événement, l'autel, la forge : leur fond d'aujourd'hui (M20).
23. **T20** — Le décor d'un autre écran : `rest.png` copié puis retiré (M19).
24. **T21** — Le fond de fenêtre, caché (dormant).
25. **T22** — Le premier affichage du héros.

## Points que le propriétaire est le premier à juger
*À regarder dans le jeu lancé (build web, 1920 × 1080 puis 1280 × 720) ; ce qui en est pensé va dans la table des défauts, ou nulle part. Chacun est repris dans le test indiqué.*
1. **Le contour de ciblage recouvre le trait sombre du cadre** (T11) : cyan plein, de 3 pixels de cadre dans le code (la revue le compte à environ 4 pixels d'écran à ×2 ; le code donne 6), il se pose à l'extérieur de la fenêtre et doit recouvrir le trait sombre intérieur du cadre, côté fenêtre. Ambre, sur la fiche ouverte, il fait environ 16 pixels d'écran (4 pixels de cadre × 4) et masque la bordure du cadre. À juger : est-ce voulu, lisible, ou trop épais ?
2. **La gangue de gel rappelle l'ancien liseré** (T13) : un ennemi gelé a une bordure blanche d'environ 8 pixels d'écran à l'intérieur du cadre, sur la fenêtre. Elle peut rappeler le liseré blanc d'avant, qui a disparu au repos.
3. **La carte ouverte d'un ennemi seul descend sur la carte du héros** (T4) : à un seul ennemi, la carte doublée recouvre la moitié haute de la carte du héros, estompée sous le voile. **La spec le veut** (B40) : la carte grandit vers le bas, sa barre garde la hauteur qu'elle avait. À juger : acceptable, ou gênant ?

## T1 — L'appui : ce qui touche l'ennemi, et ce qui ne le touche pas (M12)
*La zone d'un ennemi est désormais le rectangle du canevas du cadre, du haut de la barre au bas du cadre, coins de part et d'autre de la barre compris, plus ses languettes. Aucun test automatique ne vérifie ce geste à l'écran : la revue d'ensemble l'a demandé.*
- **Atteindre la situation** : « RUN DEBUG », combat à l'acte 5 (champ « Acte (sans regenerer la carte) » à 5, onglet « Run ») : au moins deux ennemis. Onglet « Combat », section « Charges » : « +1 Feu » sur un ennemi, et « +1 Feu » sur « Heros : » (une languette à droite pour chacun). Aucune fiche ouverte, aucune carte prise. Refaire à l'acte 11 pour un tier 3.
- **Faire** : (a) toucher une **épine** du cadre, dans la bordure, entre le coin et la fenêtre. (b) Toucher le **décor** vu entre deux vrilles du cadre. (c) Toucher le **haut de la barre de PV**, puis le **coin** du canevas à côté de la barre. (d) Fiche fermée, toucher la **languette au repos** de l'ennemi (celle qui porte le Feu). (e) Prendre une carte d'attaque (carte focalisée, contour cyan), refaire (a) à (d) sur un ennemi. (f) **Au bord de l'écran** : à cinq ennemis, survoler l'ennemi le plus à droite (sa languette extérieure se déroule vers l'intérieur, par-dessus sa carte), **souris immobile**, puis toucher l'endroit où la languette était **au repos**, puis la languette déroulée elle-même ; refaire sur l'ennemi le plus à gauche. (h) **Deux voisines portant chacune une languette du côté qui les sépare** : arriver à la souris de chaque côté, puis toucher la **zone commune** des deux languettes. (g) Refaire (d) et (f) **sur le héros** : sa languette au repos, puis sa languette déroulée vers l'intérieur au bord (le héros est au centre : au besoin, réduire la fenêtre ; sinon noter que la situation ne s'atteint pas), avec une carte qui cible soi prise en main pour (e).
- **Attendu** : (a) à (d) fiche fermée, chaque touche **ouvre la fiche** de cet ennemi, et elle reste ouverte ; carte prise (e), chaque touche **joue la carte sur cet ennemi**, sans fiche. (f) et (g) **l'appui vise la carte**, jamais le vide ni un voisin : toucher une languette au repos, ou déroulée vers l'intérieur, agit comme toucher sa carte (fiche ouverte sur cet ennemi ; ou carte jouée si elle est focalisée) ; aucune languette ne reste déroulée hors de l'écran. (h) la touche dans la zone commune agit sur la carte dont la languette se voit par-dessus. Le décor vu **à travers** les jours du cadre est, lui aussi, dans la zone : il ouvre la fiche ; au-delà du canevas, il la ferme (fiche ouverte) ou ne fait rien (fiche fermée).
- **Ne doit pas changer** : les PV ; aucune carte jouée par un appui sur le décor ; le HUD (Son, Deck) garde la priorité là où il recouvre une barre.
- **Résultat** :

## T2 — La fenêtre Windows ouverte maximisée (M22, B86)
*Une ligne du lanceur natif : `SW_SHOWMAXIMIZED` à la place de `SW_SHOWNORMAL`. Aucun test automatique, par ADR-113. **Smart App Control a déjà bloqué l'exécutable fraîchement construit sur ce poste** : vérifier d'abord que le jeu se lance ; sinon noter « non testé — Windows bloqué ».*
- **Atteindre la situation** : un build Windows (`flutter build windows` ou `flutter run -d windows`), sur un écran 1080p.
- **Faire** : (a) lancer le jeu ; regarder le **premier affichage**. (b) Cliquer « Restaurer » (le bouton à côté de Fermer). (c) Cliquer « Agrandir ». (d) Fermer le jeu et le relancer.
- **Attendu** : (a) la fenêtre s'ouvre **maximisée dès son premier affichage, sans éclair** de sa taille de création (1280 × 720, cadre compris) ; une zone de jeu d'environ **1920 × 1009** ; en combat, le plateau est net au **palier ×2**. (b) restaurée : fenêtre de **1280 × 720** (cadre compris), **zone de jeu d'environ 1264 × 681** à 100 % ; le plateau est **réduit et lissé** (palier ≈ 1,326) ; il ne déborde pas. (c) maximisée de nouveau : retour au palier ×2 net. (d) la relance s'ouvre de nouveau **maximisée** : rien ne garde la taille restaurée.
- **Ne doit pas changer** : le menu, la carte du monde et les autres écrans, qui suivent la taille ; aucune sauvegarde de la taille ; la plateforme web.
- **Résultat** :

## T3 — Le plateau suit la fenêtre : restaurée, maximisée, plein écran, 125 % (M16, M18)
- **Atteindre la situation** : « RUN DEBUG », combat à l'acte 5 (cinq ennemis ou moins), fiche fermée.
- **Faire** : (a) fenêtre maximisée. (b) La restaurer. (c) La remaximiser. (d) Plein écran (F11 ou le bouton du navigateur). (e) Redimensionner à la main entre deux. (f) **Si le propriétaire a un écran réglé à 125 %** (ou 150 %) : lancer le jeu dessus, regarder le plateau dès l'arrivée en combat.
- **Attendu** : (a), (c), (d) le plateau est **net**, au palier ×2 : cadres aux pixels carrés et égaux ; les cartes ne changent pas de taille d'un cran à l'autre au-delà du palier. (b) restauré, la mise en page du palier ×2 **réduite et lissée** (cartes environ 34 % plus petites : 1,326 au lieu de 2), toujours dans l'écran, cadres sans chevauchement. (e) le plateau suit sans saut ni carte laissée à son ancienne taille. (f) à 125 %, les cadres sont **aussi nets qu'à 100 %**. *La revue a noté* que le **tout premier palier** se calcule avec un rapport de pixels de 1 et se corrige à la reconstruction suivante : **regarder si le plateau est flou ou mal placé un instant à l'arrivée en combat, ou durablement** ; noter la durée.
- **Ne doit pas changer** : la carte du héros et la main, qui gardent leur échelle continue ; le HUD.
- **Résultat** :

## T4 — La fiche doublée : barre à la hauteur des autres, bord, tier 3, carte sur le héros (M10)
*La fiche est désormais le double de la carte (× 2 au lieu de × 1,25), barre et languettes comprises ; sa carte descend de 77 pixels de cadre × le palier, ce qui garde le haut de sa barre où il était (B40). Le panneau de la fiche (textes) garde sa taille.*
- **Atteindre la situation** : « RUN DEBUG », un combat à cinq ennemis (acte 5), puis un à l'acte 11 (Orc, tier 3). Un ennemi porteur d'une charge (« +1 Feu ») pour avoir une languette. Aucune carte prise, c'est le tour du joueur. Puis **un seul ennemi** (acte 1).
- **Faire** : (a) toucher un ennemi de tier 1. (b) Toucher un ennemi de tier 3. (c) Toucher l'ennemi le plus à droite, puis le plus à gauche. (d) À un seul ennemi (acte 1), toucher l'ennemi ; regarder le bas de sa carte.
- **Attendu** : (a) la carte **grandit au double** en 0,15 s, barre et languettes comprises ; **le haut de sa barre reste à la même hauteur que celle de ses voisines** ; le panneau de la fiche se pose à côté à sa taille (310 de large), sans couvrir la languette de ce côté. À ×2 en 1080p, la carte de tier 1 ouverte mesure environ 352 × 480 pixels d'écran. (b) la même chose, plus grande, la fenêtre toujours à la même place. (c) la carte du bord **reste entièrement dans l'écran** (en 1080p, à cinq cartes au plus, elle n'a pas besoin d'être décalée : le décalage de sécurité de B89 vaut 0, bord droit à 1796 sur 1920 ; en plein écran 2880 × 1800 à 200 %, elle se décale d'environ 3 pixels logiques). (d) *À juger, point 3* : la carte doublée d'un ennemi seul **descend sur la moitié haute de la carte du héros**, estompée sous le voile ; la spec le veut (la carte grandit vers le bas). Le dégât flottant d'un coup porté sur la carte ouverte s'affiche à l'ancre de la carte.
- **Ne doit pas changer** : l'agrandissement et le retour en 0,15 s ; la fermeture, le voile à 55 %, le fait que les boutons du HUD restent nets ; le panneau d'intentions.
- **Résultat** :

## T5 — La fiche suit le redimensionnement (M17)
- **Atteindre la situation** : un combat à au moins trois ennemis, la fiche ouverte sur l'un d'eux.
- **Faire** : redimensionner la fenêtre (plus grande, plus petite, puis maximiser et restaurer), fiche ouverte.
- **Attendu** : la carte ouverte et le panneau de la fiche **suivent** le nouvel emplacement, la carte au double de celle de repos (ni trop grande, ni trop petite), le panneau toujours dans l'écran ; aucune erreur dans la console du navigateur sur le web.
- **Ne doit pas changer** : le voile reste ; l'ouverture et la fermeture rapides, la souris immobile, ne laissent ni carte agrandie ni scène assombrie.
- **Résultat** :

## T6 — Cinq ennemis tiennent dans l'écran (M7)
- **Atteindre la situation** : « RUN DEBUG », onglet « Run » : champ « Acte (sans regenerer la carte) » à **5** ; combats jusqu'à en tirer cinq (c'est un plafond). Un porteur de charge sur chaque ennemi (« +1 Feu ») pour que chaque carte ait sa languette.
- **Faire** : regarder la rangée, plein écran 1080p, puis fenêtre à 1280 × 720.
- **Attendu** : la rangée est **centrée** et tient dans l'écran ; les **cadres ne se chevauchent pas**. Les **languettes au repos** de deux voisines ne se superposent plus à cinq (B92) ; à six, faits apparaître par le menu de debug, celles qui se font face se **superposent sur environ 14 pixels d'écran** : la carte du dessus reste visible. À 1080p, ×2 : deux voisins ont leurs centres à environ **272 pixels**, la rangée mesure environ **1322 pixels** ; la dernière carte reste loin du bord.
- **Ne doit pas changer** : le nombre d'ennemis (plafond de cinq) ; l'ordre de la phase ennemie.
- **Résultat** :

## T7 — Un, deux, trois ennemis s'écartent comme avant (M8)
- **Atteindre la situation** : des combats de l'acte 1 (un ennemi), de l'acte 2 (deux au plus), de l'acte 3 (trois au plus).
- **Faire** : regarder la rangée avec un, deux, trois ennemis (au besoin, « 0 PV » sur un ennemi pour en retirer un).
- **Attendu** : un seul ennemi **au centre** ; deux, trois ou quatre qui **s'écartent** davantage que cinq (à 1080p, ×2 : environ 478 pixels entre deux ennemis, 326 pour quatre), la rangée toujours centrée ; à la mort d'un ennemi, les cartes se replacent.
- **Ne doit pas changer** : l'effet de mort ; l'ordre de la phase ennemie.
- **Résultat** :

## T8 — Les cadres des tiers 1, 2, 3, et les tiers mêlés (M1, M2, M3)
- **Atteindre la situation** : « RUN DEBUG » : (a) un combat de l'acte 1 (Slime, Gobelin) ; (b) acte 6, un combat (Squelette) ; (c) acte 11, un combat (Orc) ; (d) un combat à plusieurs tiers mêlés : si un acte ne donne jamais deux tiers dans le même combat, noter « tiers mêlés non atteint ». Plein écran 1080p.
- **Faire** : regarder chaque ennemi et son cadre.
- **Attendu** : (a) **tier 1** : cadre de 88 × 120 pixels de cadre (176 × 240 à ×2), **ronce aux coins bas-gauche et haut-droit, une gemme verte**, le décor de forêt entre les vrilles. (b) **tier 2** : 96 × 128 (192 × 256), **deux gemmes violettes, des pousses**. (c) **tier 3** : 104 × 136 (208 × 272), **trois gemmes rouges, des baies**. **La fenêtre est toujours la même** : 128 × 192 pixels d'écran. (d) les créatures sont **sur le même sol** (les centres des fenêtres à la même hauteur), **les barres à la même hauteur quel que soit le cadre** (B77).
- **Ne doit pas changer** : les ennemis, leurs PV, leurs intentions. **Les tiers 4 et 5 ne s'atteignent pas en jeu** (`maxTierAuthored` = 3) : leurs cadres sont gardés par le test de la table, rien à voir ici.
- **Résultat** :

## T9 — Le boss : le cadre de son tier, plus d'agrandissement (M15)
- **Atteindre la situation** : le nœud boss de la carte du monde, à l'acte 1 ; puis, si possible, aux actes 6 et 11 (champ « Acte (sans regenerer la carte) »).
- **Faire** : regarder le boss à côté des ennemis normaux ; ouvrir sa fiche.
- **Attendu** : le boss porte **le cadre de son tier, à la taille des autres ennemis** : *plus d'agrandissement* (avant, × 1,25). Sa barre est à la hauteur de celle des autres ennemis. Sa fiche s'ouvre comme celle d'un autre, au double. Dans un combat de boss, tous les ennemis portent `isBoss` : tous sont à la même taille.
- **Ne doit pas changer** : les PV, les intentions et les dégâts du boss ; le nombre d'ennemis du combat de boss (un à l'acte 1, un de plus tous les cinq actes).
- **Résultat** :

## T10 — Glisser-déposer une carte sur le cadre d'un ennemi de tier 3 (M13)
- **Atteindre la situation** : acte 11, un combat à au moins deux ennemis, une carte d'attaque en main, du mana.
- **Faire** : saisir la carte et la lâcher (a) sur le **cadre** d'un ennemi de tier 3, dans sa bordure, et non sur la fenêtre ; (b) sur sa **barre** ; (c) sur sa **languette au repos** (porteur de charge) ; (d) entre deux ennemis ; (e) dans la zone d'annulation ; (f) dans la **zone commune** des languettes au repos de deux ennemis voisins.
- **Attendu** : (a) à (c) la carte se joue sur lui ; (d) et (e) elle retourne en main sans rien jouer ; (f) elle se joue sur la carte dont la languette se voit par-dessus. Aucune languette ne se déroule pendant qu'on glisse la carte à la souris ; aucune fiche ne s'ouvre.
- **Ne doit pas changer** : la zone d'annulation ; le coût de la carte.
- **Résultat** :

## T11 — Le contour cyan, puis ambre ; plus de liseré blanc (M11, point 1)
*Le contour est posé à l'extérieur de la fenêtre, sur le filet du cadre, de la même taille sur tous les tiers ; au repos, rien.*
- **Atteindre la situation** : un combat à au moins deux ennemis, une carte d'attaque en main ; une signature qui cible un ennemi.
- **Faire** : (a) regarder les ennemis **au repos**. (b) **Armer** une signature, puis, séparément, **prendre une carte focalisée** qui vise un ennemi : regarder chaque ennemi. (c) Jouer la carte sur un ennemi : regarder sa bordure. (d) Ouvrir sa fiche, regarder la bordure, fermer. (e) Refaire (b) sur un ennemi de tier 1, puis de tier 3.
- **Attendu** : (a) **plus de liseré blanc** : rien autour de la fenêtre ni du cadre. (b) un **contour cyan plein** autour de la **fenêtre** de chaque cible possible, avec la **lueur cyan pulsante** de la surbrillance ; **le même épaisseur sur tous les tiers**. (c) l'ennemi choisi/frappé en **ambre**. (d) la fiche ouverte a son ambre. (e) la taille du contour ne change pas d'un tier à l'autre. **Au coup d'œil (point 1)** : le contour cyan **recouvre le trait sombre intérieur du cadre**, côté fenêtre ; ambre, sur la fiche ouverte (environ 16 pixels d'écran), il **masque la bordure** du cadre. Noter si c'est lisible. Regarder à 1920 × 1080, puis à 1280 × 720.
- **Ne doit pas changer** : le liseré blanc du **héros**, qui reste ; le halo d'une charge ; la gangue de givre ; le flash cyan d'un coup sur l'armure, qui passe sur le contour.
- **Résultat** :

## T12 — Les languettes contre le gabarit (M9)
- **Atteindre la situation** : « RUN DEBUG », combat. Un ennemi qui porte une altération (« +1 Gel » deux fois, « +1 Feu » une fois) et, si possible, un bonus (Orc, acte 11). Cinq ennemis (acte 5) pour les bords.
- **Faire** : (a) lire les languettes au repos. (b) Survoler la carte de l'ennemi. (c) Survoler l'ennemi le plus à droite, puis le plus à gauche. (d) Survoler un ennemi de **tier 3** (acte 11) et regarder où se pose la languette déroulée. (e) Survoler le héros.
- **Attendu** : (a) les languettes au repos sont **collées aux côtés du gabarit** (le même rectangle autour de la fenêtre sur les cinq cadres), **1 pixel de cadre de recouvrement**, **leur haut à 11 pixels de cadre sous le haut du gabarit** ; bonus à gauche, altérations et charges à droite, une icône avec sa valeur. (b) elles se déroulent en 0,1 s **vers l'extérieur**, nom, valeur, durée, **par-dessus la carte voisine**. (c) aux bords de l'écran, la languette extérieure se déroule **vers l'intérieur** (B39), **par-dessus le gabarit**, sans sortir de l'écran. (d) sur un tier 3, elle **passe sur le bord du cadre**, dont la bordure est plus large. (e) le héros se comporte comme avant, au centre, sans se retourner.
- **Ne doit pas changer** : le sens et les couleurs (vert à gauche, rouge à droite) ; la zone d'appui d'une languette ; la carte du héros, qui garde sa propre ancre.
- **Résultat** :

## T13 — Coup, gel, Foudre : où se posent les effets (M14, point 2)
- **Atteindre la situation** : un combat, une attaque en main ; onglet Combat, section « Charges » : sur un ennemi, « +1 Gel » **trois fois** (gel) ; sur un autre, « +1 Foudre » jusqu'à ce que le halo apparaisse ; un troisième de tier 3 (acte 11) si possible.
- **Faire** : (a) jouer une attaque sur un ennemi non gelé : regarder le dégât flottant, l'entaille, l'icône d'effet. (b) Regarder l'ennemi gelé et celui chargé de Foudre. (c) Regarder la couleur du coup sur la créature. Refaire sur un tier 1 et un tier 3.
- **Attendu** : (a) les **textes flottants au-dessus de la barre, à la même place sur tous les tiers** ; l'entaille et la boule de feu un peu plus petites qu'avant (132 × 180 pixels logiques pour l'entaille, au lieu de 150 × 210). (b) la **gangue de gel et le halo se posent sur la fenêtre**, pas sur le cadre. **Au coup d'œil (point 2)** : la gangue d'un ennemi gelé est une **bordure blanche d'environ 8 pixels d'écran à l'intérieur du cadre**, qui peut rappeler l'ancien liseré ; noter si elle est lisible, ou gênante. (c) la **teinte du coup** joue sur la **créature**, pas sur le cadre.
- **Ne doit pas changer** : les dégâts ; la rupture du gel (éclats ou fonte) ; le halo de la Foudre ; les chiffres de la barre.
- **Résultat** :

## T14 — Les quatre anciens sprites : recadrés et lissés (M6)
*Le Slime, le Gobelin, le Squelette et l'Orc sont de grandes peintures (1696 × 2528, le Squelette 1694 × 2528) : chacune est recadrée sur son illustration (x 308 à 1388, y 329 à 1949) et réduite avec un filtrage lissé jusqu'à la fenêtre de 128 × 192 pixels. Le Slime et le Gobelin vivent jusqu'en `0.6.3`, le Squelette jusqu'en `0.6.4`, l'Orc jusqu'en `0.6.5`.*
- **Atteindre la situation** : un combat de l'acte 1 (Slime, Gobelin), de l'acte 6 (Squelette), de l'acte 11 (Orc).
- **Faire** : regarder chaque créature de près, plein écran 1080p, puis à 1280 × 720 ; jouer un ou deux tours (animation de coup).
- **Attendu** : chacun est **recadré sur son illustration, sans le cadre de parchemin peint** de l'ancien sprite, **lissé, sans scintillement** ni crénelage pendant l'animation. *Un trait fin de la bordure peinte peut encore se voir* sur le bord de la fenêtre (environ 3 pixels, §5.4) : le noter, il est connu. Sous le 1080p, la créature reste propre (filtrage lissé).
- **Ne doit pas changer** : les créatures elles-mêmes ; l'effet de mort ; la secousse d'un coup.
- **Résultat** :

## T15 — Le décor : la forêt neuve, nette (M4)
- **Atteindre la situation** : tout combat, plein écran 1080p ; puis maximisé 1920 × 1009 ; puis 1280 × 720 ; si possible un écran 16:10 (1280 × 800).
- **Faire** : regarder le fond derrière les cartes.
- **Attendu** : une **forêt neuve, nette**, sans flou ni étirement, **plus le donjon d'avant** ; à 1080p, chaque pixel du décor fait 3 pixels d'écran (3 pixels en carré, sans lissage) ; à 1920 × 1009 il est centré et rogné de 71 pixels (la moitié en haut, la moitié en bas) ; à 1280 × 800, il est rogné de 71 pixels de chaque côté. **Il ne se lisse jamais**, même à un facteur fractionnaire (1280 × 720 : facteur 2 ; zone restaurée 1264 × 681 : 1,975).
- **Ne doit pas changer** : le voile de la fiche passe toujours **au-dessus** du décor.
- **Résultat** :

## T16 — Les grilles de pixels : le cadre est net, rien ne se brouille (M5)
- **Atteindre la situation** : un combat plein écran 1080p ; zoom de l'œil ou capture agrandie.
- **Faire** : regarder de près un cadre et une barre.
- **Attendu** : **le cadre aux pixels carrés et égaux** (chaque pixel de cadre fait exactement 2 × 2 pixels d'écran) ; **trois grilles — le décor (3 pixels d'écran par pixel), le cadre (2) et la créature (1) — qui ne se brouillent pas** ; la barre de PV est nette (176 × 26 pixels d'écran).
- **Ne doit pas changer** : la carte du héros et la main (échelle continue, lissées comme avant).
- **Résultat** :

## T17 — La barre de l'ennemi le plus à droite, sous Son et Deck (M21, B93)
- **Atteindre la situation** : fenêtre **restaurée** (zone de jeu d'environ 1264 × 681), combat à cinq ennemis (acte 5).
- **Faire** : regarder la barre de PV de l'ennemi le plus à droite par rapport aux boutons Son et Deck.
- **Attendu** : **elle ne passe pas sous les boutons Son et Deck**, ni la barre de l'ennemi le plus à gauche sous « Acte - Niveau » : depuis B93, le haut des barres reste sous le bas visible des icônes (56 pixels logiques), la rangée descendue d'environ 14 pixels en 1280 × 720, à six ennemis compris. Toucher le bouton à cet endroit ferme la fiche et agit.
- **Ne doit pas changer** : la place des boutons du HUD.
- **Résultat** : ✅ — le 25/11, dans Chrome en 1280 × 720 (outils de développement), après B93 : « la rangée ne passe plus sous la barre »

## T18 — Un écran 1440p, 4K, ou un réglage à 125 % ou 150 % (M18)
*Si le propriétaire n'en a pas : noter « non testé ». L'écran de 2880 × 1800 à 200 % du propriétaire est testé à part, en T24 (T23 l'a été sous B90).*
- **Atteindre la situation** : le jeu en plein écran sur un écran 1440p, 4K, ou réglé à 125 % ou 150 % dans Windows.
- **Faire** : un combat à cinq ennemis ; regarder le plateau et ses cadres.
- **Attendu** : le palier de B91, qui suit la taille du héros : **×3 net en 1440p** (un tier 1 de 264 × 360 pixels physiques) ; **3,31, lissé, sur 2880 × 1800 à 200 % dans Chrome** (environ 291 × 397 pixels physiques), **3,667, lissé, en plein écran** ; **×4 net en 4K** (un tier 1 de 352 × 480, la rangée de six à 2948 sur 3648) ; à 125 % sur un 1080p, les cadres **aussi nets qu'à 100 %** (le palier ×2 physique vaut 1,6 pixel logique). Le décor est inchangé : facteur 4 en 1440p, 6 en 4K.
- **Ne doit pas changer** : l'échelle de la carte du héros et de la main ; le décor.
- **Résultat** :

## T19 — Les autres écrans gardent leur fond d'aujourd'hui (M20)
- **Atteindre la situation** : sur la carte du monde, ouvrir un repos, la boutique, un événement, l'autel d'échange de reliques, la forge de fusion ; le choix de carte du repos.
- **Faire** : regarder le fond de chaque écran.
- **Attendu** : **leur fond d'aujourd'hui, inchangé** (dégradé ou parchemin) ; **aucun décor de forêt**. Aucune erreur.
- **Ne doit pas changer** : leur contenu et leur mise en page.
- **Résultat** :

## T20 — Le décor d'un autre écran : `rest.png` copié, puis retiré (M19)
*Dormant : la couture existe, aucune image d'écran n'est livrée. Se vérifie sans rien commiter. **Ne pas commiter le fichier copié.***
- **Atteindre la situation** : copier `assets/data/locations/forest/combat.png` en `assets/data/locations/forest/rest.png` ; relancer le jeu complètement (un nouvel asset demande un rechargement). Ouvrir un repos.
- **Faire** : regarder le fond du repos ; **puis supprimer `rest.png`**, relancer, ouvrir un repos de nouveau.
- **Attendu** : avec le fichier, **le décor de forêt derrière le menu du repos**, au cadrage du décor, sans lissage ; sans le fichier, **le fond d'aujourd'hui**.
- **Ne doit pas changer** : les autres écrans (boutique, événement…), qui n'ont pas d'image ; le combat.
- **Résultat** :

## T21 — Ce qui ne se voit pas encore : le fond de fenêtre
*Chaque carte tire à sa naissance un fond de fenêtre parmi les trois fonds de forêt (`window_1.png`, `window_2.png`, `window_3.png`), tenu par la carte. Il est dessiné **derrière** la créature, et les illustrations d'aujourd'hui sont **opaques** : il est **dormant**, caché. Le premier sprite neuf, en vague 4, le montrera.*
- **Atteindre la situation** : tout combat.
- **Faire** : regarder la fenêtre de plusieurs ennemis, à plusieurs combats ; **chercher un ancien sprite qui serait transparent** par endroits.
- **Attendu** : **rien à voir** : les créatures couvrent leur fenêtre entièrement. **Sauf** si un ancien sprite était transparent par endroits : on verrait alors un fond de forêt dans le trou ; le noter, c'est un défaut à porter au compte rendu. Aucune erreur au chargement.
- **Ne doit pas changer** : l'aspect des créatures d'aujourd'hui ; la sauvegarde (le fond tiré n'est pas sauvegardé).
- **Résultat** :

## T22 — Le premier affichage du héros
*Le héros est posé un instant à 0,6 de la hauteur de l'écran avant de prendre sa place à 0,51 : un saut possible, antérieur à la vague, à noter s'il se voit.*
- **Atteindre la situation** : entrer dans un combat, depuis la carte du monde, plusieurs fois.
- **Faire** : regarder la carte du héros à l'instant où le combat s'ouvre.
- **Attendu** : la carte du héros est à sa place, à 0,51 de la hauteur. **Noter un saut** de la carte du héros (de plus bas vers sa place) pendant la première image ; s'il est vu, sa cause est antérieure à la vague.
- **Ne doit pas changer** : la position du héros, sa jauge et son panneau d'effets.
- **Résultat** :

## T23 — Les ennemis à leur taille sur un écran haute définition (correction B90)
*Né du premier test du propriétaire : sur 2880 × 1800 à 200 %, un ennemi de tier 1 faisait 0,57 fois la hauteur du héros, contre 0,85 en 1080p. La taille des ennemis suit désormais celle du héros, nette quand elle est presque entière (B90).*
- **Atteindre la situation** : « RUN DEBUG », un combat à l'acte 5, sur l'écran du propriétaire (2880 × 1800 à 200 %), dans Chrome ou en application Windows maximisée. Si possible, la même chose sur un écran 1440p.
- **Faire** : regarder les ennemis de tier 1 face à la carte du héros ; mesurer le cadre d'un ennemi de tier 1 (capture d'écran).
- **Attendu** : sur 2880 × 1800 à 200 %, le cadre d'un tier 1 mesure environ **264 × 360 pixels physiques** (88 × 120 pixels de cadre à ×3), **net** (pixels carrés et égaux), et l'ennemi fait environ **0,85 fois la hauteur du héros**, comme en 1080p (au lieu de 0,57). La rangée de cinq tient dans l'écran, sans chevauchement. En 1440p, si possible : environ **235 × 320 pixels physiques, lissé** (2,667).
- **Ne doit pas changer** : la carte du héros et la main ; le décor ; le 1080p, toujours ×2 net.
- **Résultat** : ✅ — le 25/11, sur 2880 × 1800 à 200 % dans Chrome, après la correction B90 : « les ennemis ont la bonne taille maintenant »
*Remplacé par B91, voir T24.*

## T24 — Les ennemis un peu plus grands, et la carte du dessus qui reçoit le pointeur (correction B91)
*Né du test de T23 : « les ennemis encore un peu petits, à agrandir légèrement ». La cible passe à 2,2 pixels d'écran par pixel de cadre pour 1080 px de haut ; la place d'une carte est le gabarit et une languette (117), si bien que deux languettes voisines peuvent se superposer ; dans le recouvrement, la carte dessinée par-dessus reçoit le survol, l'appui et le lâcher.*
- **Atteindre la situation** : (a) « RUN DEBUG », un combat à l'acte 5, sur l'écran du propriétaire (2880 × 1800 à 200 %, dans Chrome), puis en 1080p et, si possible, en 1440p. (b) En combat, « Faire apparaitre » jusqu'à **six** ennemis, : depuis B92, deux languettes ne se superposent qu'à six. Sur deux voisins, « +1 Feu » sur celui de gauche (languette à droite), « +1 Puissance » sur celui de droite (languette à gauche), section « Bonus ». Une carte d'attaque en main, une signature armée possible.
- **Faire** : (a) regarder les ennemis de tier 1 face au héros ; mesurer le cadre (capture d'écran). (b) Arriver à la souris de chaque côté, toucher la zone commune, y lâcher une carte d'attaque, y viser avec une signature armée.
- **Attendu** : (a) sur Chrome à 2880 × 1800 : tier 1 d'environ **291 × 397 pixels physiques, lissé**, environ **0,93 fois la hauteur du héros** ; en 1080p, inchangé (×2 net, 176 × 240, 0,85) ; en 1440p, ×3 net (environ 0,96). (b) chaque fois, la carte dont la languette se voit par-dessus ; à noter : la dernière carte quittée par la souris passe au-dessus de ses voisines.
- **Ne doit pas changer** : la carte du héros et la main ; le décor ; le 1080p, toujours ×2 net.
- **Résultat** : la taille ✅ — le 25/11, sur 2880 × 1800 à 200 % dans Chrome, après B91 : « les ennemis ont la bonne taille » ; le chevauchement des languettes : non testé

## T25 — Les languettes réduites d'un quart (correction B92)
*Demandé après T24 : « réduire de 25 % la taille des icônes et des informations affichées dans les languettes ». Toute la languette rétrécit, cadre, émojis et textes, au repos comme déroulée ; sa hauteur sur la carte et la place de chaque ennemi ne changent pas.*
- **Atteindre la situation** : « RUN DEBUG », un combat ; « +1 Feu » et « +1 Gel » sur un ennemi et sur le héros (onglet Combat) ; « +1 Puissance » et « +1 Métallisation » (section « Bonus ») pour la languette de gauche.
- **Faire** : regarder les languettes au repos ; survoler la carte pour les dérouler ; sur l'ennemi le plus à droite, la languette déroulée vers l'intérieur.
- **Attendu** : au repos, une entrée mesure **45 × 55,5 pixels d'écran en 1080p** (22,5 × 27,75 pixels de cadre, au lieu de 60 × 74) ; l'émoji et la valeur restent lisibles. Déroulée, le nom, la valeur et la durée restent lisibles, coupés par « … » au-delà de 90 pixels de cadre (au lieu de 120). Même réduction sur la carte du héros.
- **Ne doit pas changer** : la taille et la place des ennemis (T24) ; le haut des languettes, 11 pixels de cadre sous celui du gabarit ; ce qu'elles montrent ; le survol, l'appui et le lâcher sur elles.
- **Résultat** :

## Ce qui doit rester inchangé
- **Ce que font les ennemis** : mêmes intentions, mêmes valeurs, même ordre de la phase ennemie, mêmes dégâts, aucune règle de combat changée.
- **La carte du héros et la main** : leur échelle continue, leurs positions, leur survol ; le héros garde son liseré blanc.
- **Les écrans de repos, de boutique, d'événement, d'échange de reliques et de forge** : leur fond d'aujourd'hui, aucun décor de forêt.
- **Le tutoriel** : mêmes étapes, même ordre ; il n'a pas de combat réel, ni cadre de tier ni palier à démontrer.
- **Le jeu d'une carte** : le clic (carte, puis cible), le glisser-déposer, la zone d'annulation, la signature armée, leur son.
- **Le menu de debug** : mêmes onglets, mêmes champs, mêmes boutons, sauf les sections « Faire apparaitre » et « Bonus » de l'onglet Combat.
- **La fiche d'un ennemi** : son contenu, ses textes, la façon de l'ouvrir et de la fermer (l'agrandissement est le seul changement).
- **Le plafond du plateau** : cinq ennemis à l'écran, la réserve au-delà.
- **La victoire et la défaite** : les récompenses, l'XP, l'or, l'écran de mort.
- **La sauvegarde** : rien de neuf n'est écrit (ni palier, ni fond de fenêtre, ni taille de la fenêtre) ; aucune sauvegarde en combat ; la run debug ne sauve rien.
- **Le HUD** : la barre du haut (Son, Deck), « Fin de Tour », le compteur de tour, le panneau des intentions.
- **Avertissement — un fichier caché de Windows fait échouer le démarrage.** Un fichier **`Thumbs.db` ou `desktop.ini`** (ou tout fichier qui n'est pas un `.png`) dans `assets/data/locations/forest/` **fait échouer le chargement des données**, donc le démarrage : voulu par la spec (§4.2), qui refuse tout fichier non PNG d'un dossier de lieu. Si le jeu ne démarre plus après avoir ouvert ce dossier dans l'Explorateur, vérifier d'abord cela et le supprimer.

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
| 1 | T18, T23 | Sur un écran de 2880 × 1800 à 200 %, dans Chrome, les cartes ennemies sont trop petites face au héros (un ennemi de tier 1 à 0,57 fois sa hauteur) | — | B90, `30e09645` : la taille des ennemis suit celle du héros |
| 2 | T23, T24 | Les ennemis encore un peu petits, à agrandir légèrement | — | B91, `bcb2f51c` |
| 3 | T24 | Les icônes et les informations des languettes trop grandes, à réduire de 25 % | — | B92, `defac1cd` |
| 4 | T17, T25 | En 1280 × 720, la barre du haut chevauche les barres de PV des ennemis des deux bords (« Acte - Niveau », Son et Pause) | — | B93, `f699ce0a` |
