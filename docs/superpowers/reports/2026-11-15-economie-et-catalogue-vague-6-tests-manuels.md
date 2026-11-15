# Vague 6 — `0.5.8` — tests manuels

**Branche** : `feat/v0.5.8-p42-tranche-2` · **Compte rendu** : [2026-11-15-economie-et-catalogue-vague-6-compte-rendu.md](2026-11-15-economie-et-catalogue-vague-6-compte-rendu.md)
**Testé le** : non rempli
**Résultat** : 0 ✅ · 0 ❌ · 25 non testés

**Repères communs.** Les tests sont numérotés T1 à T25 **dans l'ordre du risque**. Les quatorze points du plan (§8, M1 à M14) y sont tous, sous un T, et chaque titre rappelle son M : M1 → T1, M14 → T2, M2 → T3, M13 → T4, M6 → T6, M3 → T7, M5 → T10, M7 → T12, M11 → T13, M4 → T17, M8 → T18, M9 → T19, M12 → T20, M10 → T23. Les autres sont neufs : demandés par l'orchestrateur, ou renvoyés au test par le compte rendu (S3, S6, §4).

**Deux sortes de run.** « JOUER » lance une run normale, sauvegardée. « RUN DEBUG » (colonne DEBUG de l'accueil, build debug seulement) passe par la même sélection de classe et le même draft, mais **ne sauvegarde jamais rien** : une reprise ne se teste qu'en run normale. Seule la run debug a le tiroir violet « DEBUG » au bord gauche. **En combat, un seul onglet, « Combat »** : « PV », « Mana », « Armure », « Soin complet », « Mana plein », une ligne par ennemi (ses PV, et « 0 PV »), « Tous les ennemis a 0 PV », « Gagner le combat », « Perdre le combat », « Sauter la phase ennemie ». **Hors combat (carte du monde) : « Heros »** (« PV max », « Mana max », « Puissance », « Chance », « Chance de critique (%) », « Passif actif : … » en lecture, « Niveau (stat brute) », « Gagner un niveau (ouvre le draft) »…), **« Run », « Deck »** (« Ajouter une carte »), **« Reliques »** (« Ajouter une relique »). Un champ chiffré se valide en tapant la valeur puis Entrée. **Aucun champ ne règle la Maîtrise** : elle vient d'*Affinité* au draft de niveau, ou de la relique *Croc Kunaï* (T10). **Ne pas utiliser « Sauter la phase ennemie » dans les tests de réserve** : il rend la main au joueur sans ouvrir de tour, donc sans lire la réserve.

**Les passifs en `0.5.8`.** Deux par classe, triés par rang : Paladin *Régénération d'Armure* (par défaut) puis *Ferveur* ; Berserker *Rage* (par défaut) puis *Soif de Sang* ; Mage **_Canalisation_ (par défaut)** puis *Flux de Mana*. *Bénédiction*, *Frénésie* et *Marque du Mage* restent masqués. Pour un Mage sous *Flux de Mana*, déplier « Passifs » à la sélection et le choisir. Le Berserker a 10 % de critique : pour comparer des chiffres, « Chance de critique (%) » à 0 dans l'onglet « Heros ». Partir de Puissance 0, sans relique, sauf mention.

**Lire les cristaux.** Sous la barre de vie du HUD du bas, un cristal par point de Mana : **plein** (cyan, lumineux) jusqu'au Mana max, **gris** une fois dépensé, **cerclé** (contour cyan sur fond noir) pour le Mana au-delà du max. 24 px jusqu'à cinq cristaux, puis plus petits (6 : 20 px ; 8 : 15 px ; 10 et plus : 12 px). Sous *Canalisation* seulement : une **flèche** — une pastille sombre cerclée de cyan, flèche blanche, au coin bas droit du cristal, de près de la moitié de sa taille — marque chaque cristal qui passera en réserve, les premiers dans l'ordre d'affichage (les pleins, puis les cerclés) ; une **légende** cyan en gras, sur une ligne de 14 px entre les cristaux et la barre de vie, dit « +n au prochain tour », et « +n au prochain tour (plafond) » **seulement quand le plafond retient du Mana** (Mana restant **strictement** supérieur au plafond). Le plafond vaut le Mana max, plus 1 par point de Maîtrise. Le HUD fait 88 px de haut, 100 px sous 600 px de large, et grandit avec le facteur de texte jusqu'à 140 px. **Le message de fin de tour** s'ouvre au premier clic sur « Fin de Tour » s'il reste du Mana, au-dessus du bouton, dans un cadre de 170 px ; le second clic finit le tour.

**La langue suit celle de Windows** : pour l'anglais, passer la langue d'affichage de Windows en anglais et relancer ; sinon, noter « anglais non testé ».

Les quinze cartes neuves, d'après les données livrées (toutes communes). Le « Face » est le badge hors combat ; « deux marteaux » : l'icône de dégâts doublée des cartes qui touchent tous les ennemis.

| Carte (anglais) | Lot — passif, classe | Coût, type | Effet | Face |
|:---|:---|:---|:---|:---|
| *Riposte* (*Riposte*) | Croisé — *Ferveur*, Paladin | 1, Attaque | 3 dégâts ; 5 Armure | marteau rouge « 3 », écu bleu « 5 » |
| *Charge du croisé* (*Crusader's Charge*) | Croisé | 2, Attaque | 7 dégâts ; 7 Armure | « 7 », « 7 » |
| *Marteau sacré* (*Holy Hammer*) | Croisé | 2, Attaque | 3 dégâts 3 fois ; la Puissance compte aux 3/4 par coup, arrondi en dessous | « 3×3 » |
| *Fléau béni* (*Blessed Flail*) | Croisé | 1, Attaque | 3 dégâts 2 fois ; idem | « 3×2 » |
| *Jugement* (*Judgment*) | Croisé | 3, Attaque, tous | 5 dégâts à chaque ennemi ; 6 Armure, une fois | deux marteaux « 5 », un écu « 6 » |
| *Morsure* (*Bite*) | Vampire — *Soif de Sang*, Berserker | 1, Attaque | 4 dégâts ; pioche 1 | « 4 », cartes ambre « 1 » |
| *Traque* (*Stalk*) | Vampire | 1, Attaque | 2 dégâts ; pioche 2 | « 2 », « 2 » |
| *Curée* (*Feast*) | Vampire | 2, Attaque | 8 dégâts ; pioche 1 | « 8 », « 1 » |
| *Lacération* (*Laceration*) | Vampire | 0, Attaque, s'épuise | 4 dégâts | « 4 » |
| *Frénésie sanglante* (*Blood Frenzy*) | Vampire | 1, Attaque | 3 dégâts, +2 par carte jouée avant elle ce tour, signatures comprises | « 3 » |
| *Barrière* (*Barrier*) | Voile — *Canalisation*, Mage | 2, Pouvoir | pendant 3 tours, 3 Armure au début du tour | flèches en cercle bleues « 3 », minuteur « 3 » |
| *Méditation* (*Meditation*) | Voile | 1, Compétence, s'épuise | pendant 2 tours, 1 Mana au début du tour (Source de Mana) | diamant cyan « 1 », minuteur « 2 » |
| *Sceau* (*Seal*) | Voile | 3, Pouvoir | pendant 4 tours, 1 Puissance au début du tour | éclair orange « 1 », minuteur « 4 » |
| *Cataclysme* (*Cataclysm*) | Voile | 3, Compétence, tous | 8 dégâts à chaque ennemi ; la Puissance du Mage s'y ajoute | deux marteaux « 8 » |
| *Bouclier d'éther* (*Ether Shield*) | Voile | 3, Compétence | 18 Armure | écu « 18 » |

## À tester d'abord
<!-- du plus risqué au moins risqué -->
1. **T1** — La réserve au fil d'un tour : flèches, légende, message, second clic, tour ennemi, cristaux cerclés au tour suivant (M1).
2. **T2** — Au tour ennemi : la légende garde le n écrit malgré *Essence Spirituelle*, et « (plafond) » tombe avec la bannière (M14).
3. **T3** — Le plafond : « (plafond) » et « Réserve pleine » au-delà, rien à plafond exact (M2).
4. **T4** — Une réserve qui ne fuit pas : combat gagné pendant le tour ennemi, combat suivant à 3, reprise de la run (M13).
5. **T5** — La victoire efface la légende, sous la récompense.
6. **T6** — Les autres classes, et le Mage sous *Flux de Mana* : ni flèche, ni légende, message ambré « Mana restant » inchangé (M6).
7. **T7** — Téléphone et fenêtre étroite : la légende ne touche pas « Effets du Joueur », les cristaux ne bougent pas (M3).
8. **T8** — Grand facteur de texte : la légende et le message réduits d'un bloc, le bouton dégagé.
9. **T9** — Un Mana max plus haut : le plafond suit ; plus de cinq cristaux, les petites flèches ; un plafond à deux chiffres.
10. **T10** — La Maîtrise relève le plafond : *Affinité*, *Croc Kunaï* (M5).
11. **T11** — Les reliques de mana sous *Canalisation* : *Pierre d'Énergie*, *Cristal de Mana*, *Essence Spirituelle* pendant son tour.
12. **T12** — *Méditation* et la *Source de Mana* : face, infobulle, panneau, +1 deux tours (M7).
13. **T13** — La fusion : ni *Persistant* ni *Résonant* sur *Méditation*, *Persistant* possible sur *Lacération* (M11).
14. **T14** — Le lot Vampire joué : *Frénésie sanglante*, signatures comprises.
15. **T15** — Le lot Croisé joué : les deux multi-coups à Puissance, *Jugement* sur tous.
16. **T16** — Le lot Voile joué : deux Pouvoirs, deux Compétences à 3.
17. **T17** — Tout dépenser : flèches et légende disparaissent, la barre ne bouge pas (M4).
18. **T18** — La sélection de classe : deux passifs par classe, le Mage sur *Canalisation*, trois passifs absents (M8).
19. **T19** — Le draft de départ des trois passifs neufs : 2 du lot + 3 neutres (M9).
20. **T20** — Le tutoriel avec le Mage sous *Canalisation* : « Mana restant », aucune réserve (M12).
21. **T21** — Le tutoriel : l'étape « Jouer des cartes » tient en un tour avec *Bouclier d'éther* au deck.
22. **T22** — *Ferveur* et *Soif de Sang* en combat : la Puissance de l'Armure frappée, le Vol de Vie.
23. **T23** — Faces et infobulles des quinze cartes, en français et en anglais (M10).
24. **T24** — Les textes de *Canalisation* partout où ils s'affichent, en français et en anglais.
25. **T25** — La note de version `0.5.8`.

## T1 — La réserve au fil d'un tour : 2 Mana restants (M1)
- **Atteindre la situation** : « RUN DEBUG », Mage, passif *Canalisation* (préselectionné), un draft 2 + 3 quelconque, entrer dans un combat. Puissance 0, aucune relique.
- **Faire** : (a) au premier tour, avant de jouer, regarder les cristaux. (b) Jouer une carte qui coûte 1 Mana (ou onglet Combat, « Mana » à 2). (c) Toucher « Fin de Tour » une fois ; lire le message. (d) Jouer une carte à 1 ; toucher « Fin de Tour » de nouveau ; puis, le message ouvert, onglet Combat, « Mana » à 2. (e) Toucher « Fin de Tour » : c'est le second clic. (f) Regarder le HUD pendant tout le tour ennemi. (g) Au tour suivant, ne rien jouer ; puis « Fin de Tour » deux fois ; regarder le tour d'après.
- **Attendu** : (a) trois cristaux pleins, une flèche sur chacun ; sous eux, « +3 au prochain tour », sans « (plafond) » (3 Mana, plafond 3 : rien n'est retenu). (b) deux pleins puis un gris ; flèches sur les deux pleins seulement ; « +2 au prochain tour ». (c) au-dessus du bouton, un cadre **bordé de cyan** (plus d'ambre), sur deux lignes : « 2 Mana en réserve. » / « Terminer le tour ? » ; le tour ne finit pas. (d) jouer une carte ferme le message ; le clic suivant le rouvre avec le nouveau chiffre, « 1 Mana en réserve. » ; le Mana remis à 2, il suit : « 2 Mana en réserve. ». (e) le tour finit, bannière « TOUR ENNEMI ». (f) pendant tout le tour ennemi : deux cristaux pleins fléchés, « +2 au prochain tour », jamais « (plafond) ». (g) le tour suivant s'ouvre à **cinq cristaux : trois pleins puis deux cerclés** ; flèches sur les trois pleins seulement, les cerclés sans flèche ; « +3 au prochain tour (plafond) » (5 Mana, plafond 3). Le message dit « Réserve pleine : 3 Mana. » / « Terminer le tour ? ». Le tour d'après s'ouvre à six cristaux : trois pleins, trois cerclés.
- **Ne doit pas changer** : le second clic qui confirme ; la main défaussée, la pioche ; l'Armure remise à 0 au tour suivant ; le Mana débité au jeu d'une carte.
- **Résultat** : ✅ · ❌ · non testé —

## T2 — Au tour ennemi, la réserve écrite ; « (plafond) » tombe avec la bannière (M14)
*Le n affiché au tour ennemi est la réserve écrite à la fin du tour, pas le Mana courant (A14, T1.2 du compte rendu).*
- **Atteindre la situation** : « RUN DEBUG », Mage sous *Canalisation*. Sur la carte du monde : onglet « Reliques », « Essence Spirituelle » ; onglet « Deck », « Ajouter une carte », *Coup Empoisonné* trois fois. Entrer dans un combat **à deux ennemis au moins** (la mort du dernier ennemi finirait le combat) ; au besoin, en essayer un autre.
- **Faire** : (a) onglet Combat, PV du premier ennemi à 4 ; jouer *Coup Empoisonné* sur lui (3 dégâts, 1 Poison) : il reste à 1 PV (s'il porte de l'Armure, ajuster ses PV pour qu'il reste à 1), Mana 2. Toucher « Fin de Tour » deux fois, et regarder la légende quand le poison le tue, au début du tour ennemi. (b) Regarder le tour suivant. (c) À ce tour, onglet Combat, « Mana » à 4 ; « Fin de Tour » deux fois, les yeux sur la légende au moment où la bannière « TOUR ENNEMI » apparaît. (d) Regarder le tour suivant.
- **Attendu** : (a) avant la fin du tour, « +2 au prochain tour », deux flèches. L'ennemi meurt du poison : *Essence Spirituelle* donne 1 Mana, trois cristaux pleins, mais la légende **reste « +2 au prochain tour »** (pas « +3 ») et seules les deux premières flèches restent. (b) le tour s'ouvre à **cinq** cristaux (trois pleins, deux cerclés), pas six. (c) avant le second clic : quatre cristaux (trois pleins, un cerclé), trois flèches, « +3 au prochain tour (plafond) » et « Réserve pleine : 3 Mana. ». **Dès que la bannière s'affiche**, la légende passe à « +3 au prochain tour », sans « (plafond) », sans retard visible (pas une demi-seconde après) ; trois flèches, le quatrième cristal sans flèche. (d) six cristaux, trois pleins et trois cerclés.
- **Ne doit pas changer** : le tic du poison, la mort de l'ennemi, le Mana d'*Essence Spirituelle* (+1) ; le reste du tour ennemi.
- **Résultat** : ✅ · ❌ · non testé —

## T3 — Le plafond : retenu, puis exact (M2)
- **Atteindre la situation** : combat d'un Mage sous *Canalisation*, tour du joueur, Mana max 3, sans Maîtrise.
- **Faire** : (a) onglet Combat, « Mana » à 4, puis 5, puis 6 ; regarder chaque fois ; à 6, toucher « Fin de Tour » une fois. (b) Le message ouvert, « Mana » à 3. (c) « Mana » à 6, toucher « Fin de Tour » : le tour finit ; regarder le tour suivant. (d) Sans debug, au premier tour d'un autre combat, à 3 Mana : jouer *Surtension de Mana* (0 Mana, +1 Mana, pioche 1).
- **Attendu** : (a) à 4 : trois pleins, un cerclé ; flèches sur les trois pleins, pas sur le cerclé ; « +3 au prochain tour (plafond) ». À 5 et 6 : de même, deux puis trois cerclés sans flèche ; à six cristaux, tous rapetissent (20 px) et les flèches restent visibles. Le message : « Réserve pleine : 3 Mana. » / « Terminer le tour ? », bordé de cyan. (b) à 3 exactement : trois flèches, « +3 au prochain tour » **sans** « (plafond) » ; le message passe à « 3 Mana en réserve. » / « Terminer le tour ? ». (c) le tour suivant s'ouvre à six cristaux : 3 + 3, le surplus est perdu. (d) quatre cristaux, « +3 au prochain tour (plafond) ».
- **Ne doit pas changer** : le Mana au-delà du max affiché en cerclés, comme celui d'une relique ; la Surtension et sa recharge.
- **Résultat** : ✅ · ❌ · non testé —

## T4 — Une réserve qui ne fuit pas : combat suivant, reprise (M13)
- **Atteindre la situation** : (a) « RUN DEBUG », Mage sous *Canalisation*, *Coup Empoisonné* au deck (onglet « Deck »). (b) « JOUER », Mage sous *Canalisation* : une run normale.
- **Faire** : (a) dans un combat à **un seul** ennemi restant : onglet Combat, ses PV à 4 ; *Coup Empoisonné* sur lui ; finir le tour avec 2 Mana (« +2 au prochain tour »). Le poison le tue au début du tour ennemi : le combat est gagné **pendant le tour ennemi**, après une fin de tour qui a mis en réserve. Passer les récompenses, entrer dans le combat suivant. (b) Gagner un combat en ayant fini au moins un tour avec du Mana ; revenu sur la carte, fermer la fenêtre du jeu ; relancer, « Continuer » ; entrer dans le combat suivant.
- **Attendu** : (a) le combat suivant s'ouvre à **trois cristaux pleins**, aucun cerclé, « +3 au prochain tour ». (b) après la reprise, la run est là : or, PV, deck, reliques, signatures, position ; le combat suivant s'ouvre à trois cristaux pleins.
- **Ne doit pas changer** : la sauvegarde hors combat, et « Continuer » ; aucune sauvegarde en combat.
- **Résultat** : ✅ · ❌ · non testé —

## T5 — La victoire efface la légende
*Neuf : corrigé par la revue d'ensemble (compte rendu, S6).*
- **Atteindre la situation** : « RUN DEBUG », Mage sous *Canalisation*, en combat ; onglet Combat, les PV de chaque ennemi à 1.
- **Faire** : (a) avec 2 Mana restants, tuer le dernier ennemi d'une carte ; regarder le HUD pendant l'animation de victoire, puis sous l'écran de récompense. (b) Dans un autre combat, à 3 Mana, « Gagner le combat ».
- **Attendu** : dès le combat gagné, plus aucune flèche ni légende cyan, ni pendant la victoire ni sous la récompense, au cas où le HUD resterait visible. La ligne de 14 px disparaît avec elle : si le HUD se voit encore, la barre de vie remonte de 14 px, et c'est attendu.
- **Ne doit pas changer** : les récompenses, l'or, l'XP ; le combat suivant (T4).
- **Résultat** : ✅ · ❌ · non testé —

## T6 — Les autres classes, et le Mage sous *Flux de Mana* : rien ne change (M6)
*Le propriétaire veut le message « Mana restant » des autres classes exactement inchangé (compte rendu, S3).*
- **Atteindre la situation** : « RUN DEBUG » : Paladin sous *Régénération d'Armure* puis sous *Ferveur* ; Berserker sous *Rage* puis sous *Soif de Sang* ; Mage sous *Flux de Mana*. Si possible, une capture du même écran en `0.5.7` pour comparer.
- **Faire** : en combat, garder du Mana et toucher « Fin de Tour » une fois ; confirmer ; regarder le tour suivant. Pour le Mage, jouer trois Compétences dans le combat (*Projectile Magique* en est une).
- **Attendu** : ni flèche ni légende sous les cristaux ; les cristaux **et la barre de vie à leur place de `0.5.7`** (la barre ne descend pas de 14 px). Le message est celui d'avant : « Mana restant. » / « Terminer le tour ? », **bordé d'ambre**, même taille, même police, même retour à la ligne. Le tour suivant repart à trois cristaux pleins : le Mana restant est perdu. Sous *Flux de Mana*, la troisième Compétence donne 1 Mana pour le tour en cours (un cerclé), perdu à la fin du tour.
- **Ne doit pas changer** : « Plus de mana. » / « Terminer le tour ? », bordé de cyan, qui s'ouvre une demi-seconde après le dernier Mana dépensé ; finir un tour à 0 Mana sans confirmation.
- **Résultat** : ✅ · ❌ · non testé —

## T7 — Téléphone et fenêtre étroite (M3)
- **Atteindre la situation** : un téléphone Android en 360 × 640 si possible ; sinon une fenêtre Windows de moins de 600 px de large (≈ 360 × 640). « RUN DEBUG », Mage sous *Canalisation*, combat. Pour que le panneau « Effets du Joueur » s'affiche, poser un statut sur le héros : jouer *Méditation* ou *Barrière* (« Deck » > « Ajouter une carte »). Pour comparer, la même fenêtre avec un Mage sous *Flux de Mana*.
- **Faire** : regarder le HUD à 2 Mana, puis à 4 (onglet Combat) ; toucher « Fin de Tour » une fois à 4. Comparer la hauteur des cristaux et de la barre avec celles du Mage sous *Flux de Mana*.
- **Attendu** : la légende « +3 au prochain tour (plafond) » tient sur sa ligne, sous les cristaux, **sans toucher le panneau « Effets du Joueur »** (à gauche, posé à 80 px du bas) ni la pile de pioche. Les cristaux sont **à la même hauteur** que sous *Flux de Mana* ; seule la barre de vie est 14 px plus bas, et rien ne sort par le bas du HUD (environ 9 px de marge sous la barre sur téléphone, 3 px en large). Les flèches restent visibles sur les cristaux. Le message « Réserve pleine : 3 Mana. » / « Terminer le tour ? » tient sur deux lignes dans son cadre, sans mordre sur le bouton « Fin de Tour ».
- **Ne doit pas changer** : la main, la barre des signatures, la barre du haut, le panneau des intentions ennemies.
- **Résultat** : ✅ · ❌ · non testé —

## T8 — Grand facteur de texte
*Neuf : la marge sous le bouton à grand facteur de texte est renvoyée au test (compte rendu, S3).*
- **Atteindre la situation** : agrandir le texte du système, puis relancer le jeu — Windows : Paramètres > Accessibilité > Taille du texte, à 150 % puis au maximum ; Android : taille de police au maximum. S'il ne se règle pas, noter « non réglable » et laisser le test non testé. « RUN DEBUG », Mage sous *Canalisation*, combat.
- **Faire** : onglet Combat, « Mana » à 4 ; regarder la légende ; toucher « Fin de Tour » une fois ; regarder le message et le bouton. Puis, le message ouvert, « Mana » à 2.
- **Attendu** : le HUD grandit (jusqu'à 140 px). La légende reste dans sa ligne de 14 px, réduite d'un bloc plutôt que coupée ou débordante. Le message « Réserve pleine : 3 Mana. » / « Terminer le tour ? » garde deux lignes au plus — il se réduit d'un bloc au lieu d'en prendre une troisième — et ne recouvre pas le bouton « Fin de Tour », ni ne le touche. **Juger** : la légende réduite se lit-elle encore ?
- **Ne doit pas changer** : chez une autre classe, le message « Mana restant » au même facteur de texte se comporte comme en `0.5.7` (il n'est pas réduit d'un bloc : ce n'est pas un défaut de la vague).
- **Résultat** : ✅ · ❌ · non testé —

## T9 — Un Mana max plus haut ; plus de cinq cristaux ; un plafond à deux chiffres
*Neuf : la taille des flèches est renvoyée au test (compte rendu, S3).*
- **Atteindre la situation** : « RUN DEBUG », Mage sous *Canalisation*. Sur la carte, onglet « Heros », « Mana max » à 4 ; combat. Plus tard, hors combat, « Mana max » à 10.
- **Faire** : (a) Mana max 4 : regarder le premier tour ; onglet Combat, « Mana » à 6 ; « Fin de Tour » deux fois ; regarder le tour suivant, sur une fenêtre large puis étroite. (b) Mana max 10 : en combat, « Mana » à 12 ; « Fin de Tour » une fois.
- **Attendu** : (a) quatre cristaux pleins fléchés, « +4 au prochain tour », sans « (plafond) ». À 6 : quatre pleins, deux cerclés, flèches sur les quatre pleins, « +4 au prochain tour (plafond) » et « Réserve pleine : 4 Mana. ». Le tour suivant s'ouvre à **huit cristaux** (quatre pleins, quatre cerclés), d'environ 15 px, aux flèches d'environ 7 px. **Juger** : les flèches se lisent-elles à cette taille, sur la fenêtre étroite comme sur la large ? (b) douze cristaux de 12 px sur une seule rangée, flèches sur les dix premiers ; « +10 au prochain tour (plafond) » tient sur sa ligne ; le message « Réserve pleine : 10 Mana. » / « Terminer le tour ? » tient en deux lignes, réduit d'un bloc s'il le faut.
- **Ne doit pas changer** : le Mana max des autres classes, et le tour qui repart à ce max hors *Canalisation*.
- **Résultat** : ✅ · ❌ · non testé —

## T10 — La Maîtrise relève le plafond (M5)
*L'onglet « Heros » n'a pas de champ de Maîtrise : le plan disait « onglet Héros, ou Affinité », seule la seconde voie existe, et la relique *Croc Kunaï* en donne une autre, le temps d'un combat.*
- **Atteindre la situation** : (a) « RUN DEBUG », Mage sous *Canalisation*, carte du monde : onglet « Heros », « Gagner un niveau (ouvre le draft) », toucher le rideau ; répéter jusqu'à ce que le draft propose *Affinité*, et la prendre en commune (+1). (b) Une autre run debug du Mage : onglet « Reliques », « Croc Kunaï » ; onglet « Deck », *Frappe* trois fois (toute Attaque convient ; en combat, « Mana » à 9 au besoin).
- **Faire** : (a) lire la carte d'*Affinité* au draft ; ouvrir la fiche du héros (barre du haut de la carte, ou le panneau « Niv. » en bas à droite) ; en combat, onglet Combat, « Mana » à 4, puis à 5 ; toucher « Fin de Tour » une fois ; confirmer à 5 ; regarder le tour suivant. (b) En combat, jouer trois Attaques dans le même tour, puis « Mana » à 5 ; au combat suivant, « Mana » à 4.
- **Attendu** : (a) la carte du draft dit « Canalisation : +1 au plafond de la réserve de Mana » (« +2 » sur une *Affinité* peu commune), le rouleau « +1 Maîtrise ». La fiche dit, sous la description, « Maîtrise : +1 au plafond de la réserve de Mana » ; le panneau de la carte, « +1 Maîtrise ». En combat, à 4 : quatre flèches (trois pleins et le cerclé), « +4 au prochain tour », sans « (plafond) ». À 5 : quatre flèches, le cinquième cristal sans, « +4 au prochain tour (plafond) », « Réserve pleine : 4 Mana. ». Le tour suivant s'ouvre à sept cristaux (3 + 4). (b) après la troisième Attaque, le plafond passe à 4 dans le même tour : à 5 Mana, « +4 au prochain tour (plafond) ». Au combat suivant, le plafond est revenu à 3 : à 4 Mana, « +3 au prochain tour (plafond) ».
- **Ne doit pas changer** : *Affinité* sous un autre passif (« Flux de Mana : -1 Compétence à réunir »…) ; le draft de niveau et ses rouleaux.
- **Résultat** : ✅ · ❌ · non testé —

## T11 — Les reliques de mana sous *Canalisation*
*Neuf : tout Mana non dépensé passe en réserve, d'où qu'il vienne ; la réserve se pose avant les reliques de début de tour (A3).*
- **Atteindre la situation** : « RUN DEBUG », Mage sous *Canalisation*, onglet « Reliques », une relique à la fois : (a) « Pierre d'Énergie » ; (b) « Cristal de Mana » ; (c) « Essence Spirituelle », dans un combat à deux ennemis au moins.
- **Faire** : (a) finir un tour sans rien dépenser ; regarder le tour suivant. (b) Regarder le premier tour d'un combat ; finir ce tour sans rien dépenser ; regarder le tour suivant. (c) Pendant son tour, à 3 Mana, onglet Combat, « 0 PV » sur un ennemi.
- **Attendu** : (a) un tour qui s'ouvre sur une réserve de 3 compte 3 + 3 + 1 = **sept cristaux** (trois pleins, quatre cerclés) : la *Pierre* s'ajoute par-dessus la réserve. (b) le premier tour s'ouvre à quatre cristaux (trois pleins, un cerclé), « +3 au prochain tour (plafond) » ; le tour suivant, à six. (c) l'ennemi meurt, *Essence Spirituelle* donne 1 Mana **pendant le tour du joueur** : quatre cristaux, la légende passe aussitôt à « +3 au prochain tour (plafond) ».
- **Ne doit pas changer** : ces trois reliques chez les autres classes, et chez le Mage sous *Flux de Mana* : leur Mana est perdu à la fin du tour.
- **Résultat** : ✅ · ❌ · non testé —

## T12 — *Méditation* et la *Source de Mana* (M7)
- **Atteindre la situation** : accueil « DICTIONNAIRE », onglet « Cartes », *Méditation*. Puis (a) « RUN DEBUG », Mage sous *Flux de Mana* ; (b) Mage sous *Canalisation* ; chaque fois, onglet « Deck », *Méditation* deux fois ; combat.
- **Faire** : au dictionnaire, regarder la face, ouvrir l'infobulle ; en combat, la même chose en main. (a) À 3 Mana, jouer *Méditation*, puis finir les tours sans rien jouer d'autre ; regarder les trois tours suivants et le panneau « Effets du Joueur ». (b) À 3 Mana, jouer *Méditation* (reste 2) ; finir les tours sans rien jouer d'autre ; regarder les trois tours suivants.
- **Attendu** : face : le diamant cyan « 1 » et le minuteur « 2 », comme l'icône de *Surtension de Mana* ; le médaillon de coût « 1 ». Infobulle : « Pendant 2 tours, gagne 1 Mana au début du tour. », et la mention d'épuisement (en combat, « ⚠️ USAGE UNIQUE (Épuisement) »). Jouée, la carte part en exil ; le panneau montre « Source de Mana : +1 » avec un diamant cyan et « 2 trs », un compte qui baisse à chaque début de tour, et la ligne disparaît après le second gain. (a) sous *Flux de Mana* : 4 cristaux (trois pleins, un cerclé) au tour suivant, 4 au suivant, 3 au troisième. (b) sous *Canalisation* : 3 + 2 + 1 = 6 au tour suivant, puis 3 + 3 + 1 = 7, puis 3 + 3 = 6.
- **Ne doit pas changer** : le panneau des autres statuts (*Éveil de Puissance*, *Métallisation*), leurs icônes et leur ordre.
- **Résultat** : ✅ · ❌ · non testé —

## T13 — La fusion : *Méditation* et *Lacération* (M11)
*La fusion 3 → 1 tire jusqu'à trois runes parmi celles que la carte accepte, à son rang.*
- **Atteindre la situation** : « RUN DEBUG » (Mage, pour avoir *Canalisation*), carte du monde : onglet « Deck », « Ajouter une carte » : *Méditation* neuf fois, *Lacération* neuf fois, *Barrière* trois fois. Puis « MON DECK » depuis la carte.
- **Faire** : fusionner trois *Méditation* communes, trois fois (trois peu communes), puis les trois peu communes (une rare) ; lire chaque offre « FUSION — CHOISISSEZ UNE RUNE ». De même pour *Lacération* : quatre offres en tout. Fusionner les trois *Barrière*, pour comparer. Si *Persistant* sort sur *Lacération*, le prendre, et jouer la carte en combat.
- **Attendu** : *Méditation*, au rang peu commun : une seule ligne, *Allégé* (la seule rune qu'elle accepte à ce rang) ; au rang rare : parmi *Allégé*, *Véloce* et *Économe*. **Jamais *Persistant*, jamais *Résonant*.** *Lacération* : parmi les runes d'Attaque (*Tranchant*, *Brûlant*, *Congelant*, *Surchargé*, *Précis*, *Spectral*…), et *Persistant* peut sortir — il n'est pas garanti : quatre tirages de trois parmi une dizaine ; noter s'il est sorti. Avec *Persistant*, l'infobulle de *Lacération* perd la mention d'épuisement, et la carte jouée va à la défausse, plus à l'exil : 4 dégâts pour 0 Mana à chaque passage. *Barrière* peut recevoir *Résonant*.
- **Ne doit pas changer** : les offres des autres cartes ; *Persistant* et *Résonant* là où ils étaient offerts en `0.5.7`.
- **Résultat** : ✅ · ❌ · non testé —

## T14 — Le lot Vampire joué : *Frénésie sanglante*
- **Atteindre la situation** : « RUN DEBUG », Berserker, passif *Soif de Sang* (aucune Puissance de passif). Carte du monde : onglet « Heros », « Chance de critique (%) » à 0, « Puissance » à 0 ; onglet « Deck », les cinq cartes du lot deux fois chacune. Combat ; onglet Combat, « Mana » à 9 au besoin.
- **Faire** : (a) jouer *Frénésie sanglante* en premier ; puis *Lacération*, *Morsure*, *Traque*, en regardant le badge de la seconde *Frénésie sanglante* en main après chaque carte ; la jouer. (b) Jouer *Curée*. (c) Au tour suivant : jouer *Frappe Téméraire* (signature, 2 Mana), puis *Frénésie sanglante*. (d) Au tour d'après, regarder le badge avant de jouer.
- **Attendu** : (a) la première : 3 dégâts. Puis *Lacération* : 4 dégâts, 0 Mana, part en exil ; *Morsure* : 4 dégâts, une carte piochée ; *Traque* : 2 dégâts, deux cartes piochées. Le badge de la seconde *Frénésie* en main monte avec chaque carte jouée — 5 après la première *Frénésie*, puis 7, 9, 11 —, l'infobulle dit « Inflige 11 dégâts. » et « (+2 par carte jouée ce tour) » ; jouée, 11 dégâts : 3 + 2 × 4, les quatre cartes jouées avant elle, la première *Frénésie* comprise ; elle ne se compte pas elle-même. (b) *Curée* : 8 dégâts, une carte piochée, 2 Mana. (c) 15 dégâts de la signature, puis 5 de la *Frénésie* : la signature compte. (d) le badge est revenu à 3 : le tour d'avant ne compte pas.
- **Ne doit pas changer** : la ligne « Pioche 1 cartes. » des infobulles, celle d'*Attaque Rapide* depuis `0.5.7` ; les cartes de *Rage*.
- **Résultat** : ✅ · ❌ · non testé —

## T15 — Le lot Croisé joué : les multi-coups et *Jugement*
- **Atteindre la situation** : « RUN DEBUG », Paladin sous *Régénération d'Armure* (aucune Puissance de passif). Carte du monde : « Puissance » à 0 ; onglet « Deck », les cinq cartes du lot. Combat **à deux ennemis** au moins ; « Mana » à 9 au besoin. Puis, hors combat, « Puissance » à 2, puis à 4.
- **Faire** : jouer les cinq cartes à Puissance 0, en lisant le badge et la ligne de dégâts ; regarder l'Armure du héros et les PV des ennemis. Recommencer à Puissance 2, puis à 4.
- **Attendu** : à Puissance 0 : *Riposte* (1 Mana) : 3 dégâts, +5 Armure ; *Charge du croisé* (2) : 7, +7 ; *Marteau sacré* (2) : badge « 3×3 », trois coups de 3 (9) ; *Fléau béni* (1) : « 3×2 », deux coups de 3 (6) ; *Jugement* (3) : se joue sans demander de cible, 5 dégâts à **chaque** ennemi, **+6 Armure une seule fois** (pas 12). À Puissance 2 : *Riposte* 5, *Charge* 9, *Jugement* 7 à chacun, *Marteau sacré* « 4×3 » (12), *Fléau béni* « 4×2 » (8) ; l'Armure reste 5, 7 et 6. À Puissance 4 : *Marteau sacré* « 6×3 » (18), *Fléau béni* « 6×2 » (12) — les trois quarts de la Puissance par coup, arrondis en dessous ; badge et infobulle d'accord.
- **Ne doit pas changer** : la Puissance pleine sur les autres Attaques ; les cartes de *Régénération d'Armure*.
- **Résultat** : ✅ · ❌ · non testé —

## T16 — Le lot Voile joué
- **Atteindre la situation** : « RUN DEBUG », Mage sous *Canalisation*, « Puissance » à 0 ; onglet « Deck », *Barrière*, *Sceau*, *Cataclysme*, *Bouclier d'éther*. Combat à deux ennemis au moins ; « Mana » à 9 au besoin. Puis « Puissance » à 2.
- **Faire** : jouer chaque carte ; regarder le panneau « Effets du Joueur », l'Armure, la Puissance et les PV des ennemis sur les tours suivants. Puis, sans debug de Mana, finir un tour sans rien dépenser et, au tour à six cristaux, jouer *Cataclysme* et *Bouclier d'éther*.
- **Attendu** : *Barrière* (2) : « Métallisation : +3 », flèches en cercle bleues, 3 tours ; +3 Armure au début de chacun des tours suivants. *Sceau* (3) : « Éveil de Puissance : +1 », éclair orange, 4 tours ; la Puissance monte de 1 au début de chacun des tours suivants, comme sous *Transe*. *Cataclysme* (3) : sans cible, 8 dégâts à chaque ennemi ; à Puissance 2, 10. *Bouclier d'éther* (3) : +18 Armure, à Puissance 2 aussi. Au tour à six cristaux, les deux cartes à 3 se jouent dans le même tour.
- **Ne doit pas changer** : les cartes de *Flux de Mana* ; la Puissance du Mage sur les Compétences et les altérations seulement.
- **Résultat** : ✅ · ❌ · non testé —

## T17 — Tout dépenser (M4)
- **Atteindre la situation** : combat d'un Mage sous *Canalisation*, 3 Mana.
- **Faire** : jouer des cartes jusqu'à 0 Mana (ou onglet Combat, « Mana » à 0), en regardant la barre de vie ; toucher « Fin de Tour » ; regarder le tour ennemi et le tour suivant.
- **Attendu** : à 0, plus aucune flèche ni texte, mais la ligne reste : **la barre de vie ne bouge pas** quand le dernier cristal se dépense. « Plus de mana. » / « Terminer le tour ? » apparaît comme avant ; « Fin de Tour » finit le tour au premier clic. Au tour ennemi, la ligne reste vide. Le tour suivant s'ouvre à trois cristaux pleins.
- **Ne doit pas changer** : l'avertissement « Plus de mana », sa demi-seconde de délai, son cadre cyan.
- **Résultat** : ✅ · ❌ · non testé —

## T18 — La sélection de classe (M8)
- **Atteindre la situation** : « JOUER » ou « RUN DEBUG », écran de sélection de classe ; fenêtre large, puis de moins de 600 px.
- **Faire** : sur chaque classe, regarder le bas de la carte ; la déplier ; lire les passifs ; choisir le second, entrer dans la run ; vérifier l'onglet « Heros » (« Passif actif »).
- **Attendu** : l'étiquette « Passifs » et son chevron sont revenus (masqués en `0.5.7`, faute de second passif). Repliée, chaque carte montre son passif par défaut ; dépliée, deux passifs : Paladin *Régénération d'Armure* (coché) et *Ferveur* ; Berserker *Rage* (coché) et *Soif de Sang* ; Mage **_Canalisation_ (coché)** et *Flux de Mana*. **Aucune trace de *Bénédiction*, *Frénésie* ni *Marque du Mage*.** Descriptions : *Ferveur* « Quand votre Armure encaisse des dégâts, gagne 1 Puissance pendant 2 tours. », « Maîtrise 1 : +1 Puissance par absorption » ; *Soif de Sang* « Jouer une Attaque arme le Vol de Vie pendant 2 tours : 1 PV par carte de dégâts, plus 1 par quart de PV manquants. », « Maîtrise 0 au départ : +1 PV drainé » ; *Canalisation* « À la fin du tour, le Mana non dépensé est mis en réserve, jusqu'à votre Mana max : le tour suivant commence avec ce Mana en plus. Chaque point de Maîtrise relève ce plafond de 1. », « Maîtrise 0 au départ : +1 au plafond de la réserve de Mana ». Sous 600 px, tout tient, sans débordement. Le passif choisi est celui de la run (« Passif actif : fervor », « bloodthirst », « channeling »).
- **Ne doit pas changer** : les stats et signatures des classes ; le survol et l'inclinaison des cartes ; *Régénération d'Armure*, *Rage* et *Flux de Mana* et leurs textes.
- **Résultat** : ✅ · ❌ · non testé —

## T19 — Le draft de départ des trois passifs neufs (M9)
- **Atteindre la situation** : « RUN DEBUG », jusqu'au draft du deck de départ : Paladin sous *Ferveur*, Berserker sous *Soif de Sang*, Mage sous *Canalisation*. Puis une fenêtre de moins de 600 px.
- **Faire** : prendre 2 cartes du lot, essayer une 3e ; prendre 3 neutres ; regarder le bouton.
- **Attendu** : deux sections : « Cartes de Ferveur » (les cinq cartes Croisé), « Cartes de Soif de Sang » (les cinq Vampire), « Cartes de Canalisation » (les cinq Voile), chacune « 0/2 », puis « Cartes neutres » « 0/3 » (les quinze neutres). Une 3e carte du lot est refusée : « Vous avez déjà choisi vos 2 cartes de passif. » ; « ENTRER DANS L'UMBRA » ne s'active qu'à 2 + 3. Sous 600 px, « Cartes de Soif de Sang » tient, centré, compteur compris. En anglais : « Fervor cards », « Bloodthirst cards », « Channeling cards ».
- **Ne doit pas changer** : le draft sous *Régénération d'Armure*, *Rage* et *Flux de Mana* (six cartes de lot chacun) ; l'arrivée sur la carte avec un deck de 5 cartes.
- **Résultat** : ✅ · ❌ · non testé —

## T20 — Le tutoriel avec le Mage sous *Canalisation* (M12)
*Le tutoriel ne simule aucun passif (A12) : son message reste « Mana restant », même sous Canalisation.*
- **Atteindre la situation** : accueil « TUTORIEL », étape « Choisissez votre classe ».
- **Faire** : choisir le Mage ; continuer jusqu'à « Votre deck de départ », faire le draft ; à « Jouer des cartes & finir le tour », toucher « Fin de Tour » avec du Mana restant, puis confirmer ; aller jusqu'au bout du tutoriel.
- **Attendu** : la carte du Mage s'ouvre sur *Canalisation*, avec sa description neuve (celle de T18) et sa ligne de Maîtrise. Le draft : « Cartes de Canalisation » (les cinq Voile) « 0/2 » et « Cartes neutres » « 0/3 ». À la fin du tour : « Mana restant. Terminer le tour ? » **en orange**, sur une ligne — pas de cyan, pas de « en réserve » ; le second clic confirme ; le tour suivant repart au Mana maximum, sans cristal cerclé, sans flèche ni légende. Rien ne casse jusqu'à la fin.
- **Ne doit pas changer** : les étapes et leur ordre ; le Paladin et le Berserker du tutoriel.
- **Résultat** : ✅ · ❌ · non testé —

## T21 — Le tutoriel : « Jouer des cartes » en un tour avec *Bouclier d'éther*
*Neuf : corrigé par la revue d'ensemble (compte rendu, S6) ; la limite connue est au §4 du compte rendu.*
- **Atteindre la situation** : « TUTORIEL », Mage. Au draft : *Bouclier d'éther* et une autre carte Voile ; parmi les neutres, *Frappe*, *Défense* et une troisième qui ne donne pas d'Armure (pas *Éveil* ni *Mur de Fer*).
- **Faire** : à l'étape « Jouer des cartes & finir le tour », regarder la main ; jouer l'attaque sur l'ennemi, la carte d'Armure sur la carte Héros.
- **Attendu** : la main est *Frappe* + *Défense* (2 Mana pour 3), pas *Bouclier d'éther* ; les deux gestes se font dans le même tour, et l'étape se valide sans finir le tour. *Variante, la limite connue* : si le deck n'a que *Bouclier d'éther* comme carte d'Armure, la main garde *Frappe* + *Bouclier d'éther* (4 Mana pour 3) et l'étape demande deux tours ; noter ce qui est vu.
- **Ne doit pas changer** : l'étape avec le Paladin ou le Berserker ; le texte de l'étape.
- **Résultat** : ✅ · ❌ · non testé —

## T22 — *Ferveur* et *Soif de Sang* en combat
*Neuf : les deux passifs deviennent jouables ; leur moteur date de la vague 5.*
- **Atteindre la situation** : (a) « RUN DEBUG », Paladin sous *Ferveur*, *Riposte* au deck. (b) Berserker sous *Soif de Sang*, « Chance de critique (%) » à 0.
- **Faire** : (a) gagner de l'Armure (*Riposte*, *Bouclier Sacré*), finir le tour, laisser un ennemi frapper l'Armure ; au tour suivant, jouer une Attaque. Puis un tour à 0 Armure. (b) Jouer une Attaque à PV pleins, puis une seconde ; onglet Combat, « PV » à 40 (sur 80), jouer une Attaque.
- **Attendu** : (a) quand l'Armure encaisse, le panneau gagne « Puissance : +2 » (1, plus 1 par la Maîtrise de départ du Paladin), pour 2 tours ; au tour suivant, l'Attaque inflige 2 de plus (*Riposte* 5). Sans Armure frappée, rien. (b) la première Attaque pose « Vol de Vie : 1 », au cœur rouge — non atteignable en `0.5.7` ; les cartes de dégâts suivantes rendent 1 PV chacune quand il en manque. À 40 PV sur 80, « Vol de Vie : 3 ». Deux Attaques ne cumulent pas le statut : la plus forte valeur reste.
- **Ne doit pas changer** : *Régénération d'Armure* (+3 Armure en fin de tour pour le Paladin) et *Rage*.
- **Résultat** : ✅ · ❌ · non testé —

## T23 — Faces et infobulles des quinze cartes (M10)
- **Atteindre la situation** : accueil « DICTIONNAIRE », onglet « Cartes » ; puis en combat, Puissance 0, les cartes en main (onglet « Deck », « Ajouter une carte »). En français puis en anglais.
- **Faire** : regarder la face de chaque carte du tableau des repères ; ouvrir son infobulle (survol ou appui long), au dictionnaire puis en main.
- **Attendu** : coût, nom et face du tableau des repères ; le texte de la carte est celui de ses données (ex. *Frénésie sanglante* « Inflige 3 dégâts, +2 par carte jouée ce tour. », « Deal 3 damage, +2 per card played this turn. »). *Marteau sacré* « 3×3 », infobulle « Inflige 3 dégâts 3 fois. » (« Deal 3 damage 3 times. ») ; *Fléau béni* « 3×2 ». *Frénésie sanglante* : la ligne de croissance « (+2 par carte jouée ce tour) » (« +2 per card played this turn »). *Jugement* et *Cataclysme* : deux marteaux sur les dégâts ; l'écu de *Jugement* reste simple ; infobulle « Inflige 5 dégâts à tous les ennemis. » et « Donne 6 Armure. ». *Lacération* et *Méditation* : la mention d'épuisement (« ⚠️ USAGE UNIQUE (Épuisement) », « ⚠️ ONCE PLAYED (Exhaust) ») ; *Lacération* au médaillon « 0 ». *Barrière* : « Pendant 3 tours, gagne 3 Armure au début du tour. » ; *Sceau* : « Gagne 1 Éveil de Puissance pendant 4 tours. » ; *Méditation* : « Pendant 2 tours, gagne 1 Mana au début du tour. » (« For 2 turns, gains 1 Mana at turn start. »). Aucune accolade `{…}`, aucune ligne vide, aucune icône en point d'interrogation.
- **Ne doit pas changer** : les faces et infobulles des autres cartes ; le dictionnaire, ses onglets et son tri.
- **Résultat** : ✅ · ❌ · non testé —

## T24 — Les textes de *Canalisation* partout
- **Atteindre la situation** : la sélection de classe (T18) ; la carte de classe du tutoriel ; la fiche du héros d'une run Mage sous *Canalisation*, sans puis avec Maîtrise (T10) ; la carte d'*Affinité* au draft de niveau ; un combat. En français puis en anglais.
- **Faire** : lire chaque texte.
- **Attendu** : partout, la même description : « À la fin du tour, le Mana non dépensé est mis en réserve, jusqu'à votre Mana max : le tour suivant commence avec ce Mana en plus. Chaque point de Maîtrise relève ce plafond de 1. » — en anglais « At the end of your turn, unspent Mana goes into reserve, up to your max Mana: your next turn starts with that Mana on top. Each point of Mastery raises this cap by 1. ». Plus aucune mention d'Armure gagnée par le Mana restant. Maîtrise : « +1 au plafond de la réserve de Mana » (« +1 to the Mana reserve cap »), précédé de « Maîtrise 0 au départ : » à la sélection (« Mastery 0 at start: »), de « Maîtrise : » à la fiche (« Mastery: »), de « Canalisation : » à *Affinité* (« Channeling: »). En combat, en anglais : « +2 next turn », « +3 next turn (cap) », « 2 Mana in reserve. » / « End your turn? », « Reserve full: 3 Mana. » / « End your turn? », « Mana Spring: +1 ».
- **Ne doit pas changer** : les textes des autres passifs.
- **Résultat** : ✅ · ❌ · non testé —

## T25 — La note de version `0.5.8`
- **Atteindre la situation** : accueil, « PATCH NOTES ».
- **Faire** : lire la première entrée.
- **Attendu** : en tête, `0.5.8`, du 15/11/2026, « Trois Passifs Reviennent » : huit lignes de « Nouvelles Fonctionnalités » (les trois passifs et leurs lots, la réserve, les flèches et la légende, le message de fin de tour, *Méditation*) et trois d'« Équilibrage » (le Mage commence sur *Canalisation* ; les trois passifs encore masqués, `0.5.9` et `0.6.0` annoncées ; *Persistant* et *Résonant* refusés à *Méditation*). Chaque phrase dit vrai sur ce que les tests précédents ont montré. Si l'accueil affiche la version, il dit `0.5.8`.
- **Ne doit pas changer** : l'entrée `0.5.7` et les précédentes.
- **Résultat** : ✅ · ❌ · non testé —

## Ce qui doit rester inchangé
- Le Paladin, le Berserker et le Mage sous *Flux de Mana* : ni flèche ni légende, cristaux et barre de vie à leur place de `0.5.7`, le message ambré « Mana restant. Terminer le tour ? » tel quel, le tour qui repart au Mana max, le Mana non dépensé perdu.
- Les passifs de la vague 5 : *Régénération d'Armure* (+3 Armure en fin de tour pour le Paladin, Maîtrise 1 comprise), *Rage* (Puissance au début du tour), *Flux de Mana* (+1 Mana toutes les 3 Compétences du combat) ; leurs lots de six cartes, chiffres, faces et infobulles.
- *Bénédiction*, *Frénésie* et *Marque du Mage* : absents de la sélection de classe, du tutoriel et du draft.
- « Plus de mana. Terminer le tour ? », bordé de cyan, pour toutes les classes ; le bouton « Fin de Tour », la phase ennemie, la pioche.
- La sauvegarde hors combat : « Continuer » rend or, PV, deck, reliques, signatures, évolutions et position ; aucune sauvegarde en combat ; une run debug ne sauve rien.
- Les quinze cartes neutres, la forge, la fusion et les runes des autres cartes ; *Persistant* et *Résonant* là où ils étaient offerts.
- Les signatures, leurs évolutions, leur barre en combat, « MON DECK ».
- Les reliques, leur effet hors *Canalisation* ; le draft de niveau, *Affinité* sous les autres passifs.
- La carte ennemie : statuts, intentions.
- Le menu de debug : mêmes onglets, mêmes champs.
- Le tutoriel : son déroulé, ses étapes et leur ordre ; son message « Mana restant » pour toutes les classes.

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
