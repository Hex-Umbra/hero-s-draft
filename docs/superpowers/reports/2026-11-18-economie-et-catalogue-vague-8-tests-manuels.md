# Vague 8 — `0.6.0` — tests manuels

**Branche** : `feat/v0.6.0-p42-tranche-3` · **Compte rendu** : [2026-11-18-economie-et-catalogue-vague-8-compte-rendu.md](2026-11-18-economie-et-catalogue-vague-8-compte-rendu.md)
**Testé le** : 19/11/2026, par le propriétaire ; les tests ont été joués un par un, leurs résultats reportés ici sur sa déclaration
**Résultat** : 20 ✅ · 0 ❌ · 0 non testé

**Repères communs.** Les tests sont numérotés T1 à T20 **dans l'ordre du risque**. Les seize points de la spec (§9.1, M1 à M16) y sont tous, sous un T, et chaque titre rappelle son M : M3 → T1, M4 → T2 et T13, M5 → T3, M11 → T5 et T8, M13 → T6, M9 → T7, M12 → T9, M10 → T10, M2 → T11, M1 → T12, M8 → T13, M6 → T16, M14 → T17, M15 → T18, M7 → T19, M16 → T20. Les autres tests sont neufs : la Nova (A3), les élémentaires qui changent de dossier (Q12), la rune *Résonant* sur *Prière* (D10).

**Deux sortes de run.** « JOUER » lance une run normale, sauvegardée. « RUN DEBUG » (colonne DEBUG de l'accueil, build debug seulement) passe par la même sélection de classe et le même draft, mais **ne sauvegarde jamais rien**. Seule la run debug a le tiroir violet « DEBUG » au bord gauche. **Le menu de debug ne change pas** : mêmes onglets, mêmes champs.
- **En combat, un seul onglet, « Combat »** : « PV (max N) », « Mana (max N) », « Armure », « Soin complet », « Mana plein », une ligne par ennemi (« 1. <nom> », champ chiffré des PV, et « 0 PV »), « Tous les ennemis a 0 PV », « Gagner le combat », « Perdre le combat », « Sauter la phase ennemie », puis tout en bas la section « Charges ». Un champ chiffré se valide en tapant la valeur puis Entrée. Le champ PV d'un ennemi **ne borne pas aux PV max** : on peut le monter à 100 ; mais les PV manquants d'un ennemi se lisent contre son max, donc **ne jamais monter un ennemi au-dessus de son max** quand le test lit ses PV manquants (T10).
- **Hors combat (carte du monde)**, quatre onglets : « Heros » (« PV max », « Puissance », « Chance de critique (%) », la ligne « Passif actif : … » en lecture seule, et la section « Évolutions de signature » : un bouton par évolution que le prochain palier admet, et « Retirer les évolutions »), « Run » (« Cartes par tour », « Main max », « Acte suivant (regenere la carte) »), « Deck », « Reliques ».
- **L'onglet « Deck »** (carte du monde seulement, jamais en combat) : « Piocher 1 », « Defausser la main », la liste « Ajouter une carte » — **toutes les cartes du registre**, une ligne « <nom> (<coût>) », un appui = **une copie au deck maître**, jamais en main — puis la liste « Deck maitre (N) », où un appui **retire** la carte. Pour qu'une main d'ouverture contienne les cartes voulues : **avant le combat, sur la carte**, ajouter les cartes et **retirer les cinq cartes du draft** de « Deck maitre ». Une main compte 5 cartes (« Cartes par tour ») : un deck de cinq cartes ou moins s'ouvre en entier ; au-delà, la main est tirée au hasard, et il faut rejouer un combat si une carte voulue manque.
- **Passer d'acte** : onglet « Run », « Acte suivant (regenere la carte) », deux fois depuis l'acte 1, pour l'**acte 3**. **À l'acte 1, un combat ne compte qu'un ennemi** ; ensuite, jusqu'à trois : trois n'est qu'un plafond, le nombre réel est tiré. S'il y en a moins que demandé, jouer un autre combat ou passer encore d'acte.
- **Mana et PV** : « Mana » à 9 (Combat) au besoin ; les PV du héros se règlent dans le même onglet. Le Paladin a 100 PV max, et 1 de Maîtrise.
- **Le choix du passif** : à la sélection de classe, déplier la liste « Passifs » (le premier est préselectionné) et toucher le passif voulu avant de valider. Les tests disent « sous *Marque du Mage* », « sous *Bénédiction* », « sous *Frénésie* » : le passif choisi à la sélection, puis le draft de départ habituel.
- **Classes** : sauf mention, **Puissance 0** et **sans relique**. Le Berserker porte 10 % de critique : **le mettre à 0** (onglet « Heros », « Chance de critique (%) ») pour tout test de dégâts qui le joue. Le Mage et le Paladin n'en ont pas. Tous les chiffres ci-dessous sont **sans Puissance ni critique**.
- **Langue** : elle suit celle de Windows ; pour l'anglais, passer la langue d'affichage en anglais et relancer ; sinon, noter « anglais non testé ».

**Ce que la vague change, en bref.** Les neuf passifs sont jouables, trois par classe : *Bénédiction*, *Frénésie* et *Marque du Mage* ont leur lot (5, 5 et 6 cartes). *Marque du Mage* se déclenche sur la **première carte de dégâts à cible unique** du tour, Attaque ou Compétence — *Projectile Magique* de nouveau —, qui **ne tue pas** sa cible, et pose 2 Vulnérable pendant 2 tours. *Prière* pose un statut neuf, la **Source de Vie** (+2 PV au début des trois tours suivants). Six cartes changent de lot sans changer d'id : *Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, *Coup Empoisonné* (Marque), *Métallisation* (Sanctifié), *Cri de Guerre* (Carnage) ; **le noyau neutre passe de 15 à 9 cartes**.
- **Une Faiblesse de N tours réduit N − 1 attaques** : un ennemi vieillit ses statuts au début de sa phase, avant d'agir. *Sommation* (3 tours) réduit donc deux attaques, *Édit*, *Réprimande* et *Sentence* (2 tours) une seule.
- **Vulnérable** : +25 % de dégâts encaissés par point, jusqu'à 4 points (+100 %) ; l'ennemi affiche la somme brute de ses points, même au-delà de 4.

**Les cartes (§3.2 de la spec).**

| Lot | Carte | Coût | Effet |
|:---|:---|:---:|:---|
| Sanctifié | *Sommation* | 1 | Compétence : 1 Faiblesse, 3 tours, un ennemi |
| | *Édit* | 2 | Compétence : 2 Faiblesse, 2 tours, tous les ennemis |
| | *Réprimande* | 1 | Compétence, un ennemi : 4 Armure, puis 1 Faiblesse, 2 tours |
| | *Prière* | 2 | Pouvoir : Source de Vie 2, 3 tours |
| Carnage | *Moulinet* | 2 | Attaque : 7 à tous |
| | *Tourbillon* | 1 | Attaque : 2 à tous, pioche 1 |
| | *Coup de grâce* | 3 | Attaque : 10 à tous |
| | *Exécution* | 1 | Attaque, un ennemi : 4, +1 par tranche de 5 PV manquants de la cible |
| Marque | *Exploitation* | 2 | Compétence, un ennemi : 4, +1 par point de Vulnérable de la cible |
| | *Salve* | 1 | Compétence, un ennemi : 2 dégâts 3 fois |

## À tester d'abord
<!-- du plus risqué au moins risqué -->
1. **T1** — *Marque du Mage* : *Projectile Magique* marque ; *Exploitation* frappe 9 ; la seconde carte ne remarque pas ; au tour 2, 4 points (M3).
2. **T2** — La carte sans dégâts et la carte de groupe ne marquent ni ne consomment ; *Salve* marque ensuite (M4).
3. **T3** — La carte qui tue sa cible ne consomme pas : la suivante marque (M5, A4).
4. **T4** — *Projectile Magique* évolué en *Nova* ne marque personne (A3).
5. **T5** — *Sommation* réduit deux attaques et pas la troisième (M11, A19).
6. **T6** — *Prière* : « Source de Vie : +2 », cœur rose, +2 PV trois tours, jamais au-delà du max (M13).
7. **T7** — Carnage sous *Frénésie* : *Moulinet* tue deux ennemis, +4 Puissance, deux pioches (M9).
8. **T8** — *Réprimande* et *Bénédiction* : l'Armure qui survit devient des PV (M11).
9. **T9** — *Édit* devant trois ennemis (M12).
10. **T10** — *Exécution* : 4 + 1 par tranche de 5 PV manquants ; le seuil de mort ; le boss (M10).
11. **T11** — Le draft de départ des trois lots : 2 + 3, un groupe neutre de 9 (M2).
12. **T12** — La sélection de classe : neuf passifs, trois par classe, FR et EN (M1).
13. **T13** — *Salve* et la Foudre : chaque coup reçoit le bonus (M8).
14. **T14** — Les quatre élémentaires dans leur lot : encore des Attaques, qui marquent (Q12).
15. **T15** — *Prière* reçoit la rune *Résonant* à la forge ; *Tourbillon* non (D10).
16. **T16** — Les textes des faces, FR et EN (M6).
17. **T17** — Le tutoriel : *Boule de Feu* à l'étape des cartes, trois passifs au Mage (M14).
18. **T18** — Les autres passifs n'offrent plus les cartes déplacées (M15).
19. **T19** — Vulnérable qui s'accumule : le plafond du barème (M7).
20. **T20** — *Sentence* : le nombre d'attaques réduites (M16).

## T1 — *Marque du Mage* : *Projectile Magique*, *Exploitation*, le tour suivant (M3)
*Le déclencheur est la carte de dégâts : la signature, Compétence depuis `0.5.6`, marque de nouveau. La marque est posée après la résolution de la carte qui la déclenche : cette carte-là ne profite pas de son propre Vulnérable.*
- **Atteindre la situation** : « RUN DEBUG », **Mage**, passif *Marque du Mage*, draft habituel. Sur la carte, onglet « Deck » : ajouter *Exploitation* une fois et *Salve* deux fois, **retirer les cinq cartes du draft** de « Deck maitre ». Combat contre un ennemi (acte 1 suffit) ; onglet Combat, **ses PV à 100** (s'il a moins de 100 PV max, lire plutôt ses PV max et suivre les différences) ; « Mana » à 9.
- **Faire** : (a) jouer *Projectile Magique* sur lui ; lire son icône. (b) Jouer *Exploitation* sur lui. (c) Jouer *Salve*. (d) « Fin de Tour » ; au tour suivant, jouer *Salve* d'abord, lire l'icône, puis *Exploitation*.
- **Attendu** : (a) 5 dégâts (100 → 95) et **« Vulnérable 2 »** sur l'ennemi, 2 tours ; l'ennemi n'a pas subi son propre Vulnérable. (b) 4 + 2 = 6, ×1,5 : **9 dégâts** (95 → 86). (c) 3 coups de 2 ×1,5 : **9 dégâts** (86 → 77), et **l'icône reste à « Vulnérable 2 »** : une seconde carte de dégâts ne remarque pas. (d) au tour 2, il reste 1 tour de la première marque ; *Salve* frappe 9 (77 → 68), puis **l'icône passe à « Vulnérable 4 »** (2 de plus : la marque revient) ; *Exploitation* compte alors 4 points : (4 + 4) × 2 = **16 dégâts** (68 → 52).
- **Ne doit pas changer** : le coût de *Projectile Magique* (1) et sa pioche ; sa recharge ; les dégâts de base des cartes.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T2 — La carte sans dégâts et la carte de groupe ne marquent ni ne consomment (M4)
*Une carte de groupe n'a pas d'ennemi visé : elle ne marque personne et ne consomme pas la marque du tour (A3, choix du propriétaire).*
- **Atteindre la situation** : « RUN DEBUG », **Mage** sous *Marque du Mage* ; onglet « Deck » : ajouter *Concentration*, *Balayage*, *Salve* ; retirer les cinq cartes du draft. Acte 3 ; un combat à **au moins deux ennemis**. Ennemis à pleine vie, « Mana » à 9.
- **Faire** : (a) jouer *Concentration* (coût 0). (b) Jouer *Balayage*. (c) Jouer *Salve* sur le premier ennemi. Lire les icônes de chaque ennemi après chaque carte.
- **Attendu** : (a) **aucune** icône de Vulnérable : *Concentration* pioche, sans dégâts. (b) *Balayage* inflige 3 à **tous** les ennemis ; **aucune** icône de Vulnérable, nulle part. (c) *Salve* frappe 3 × 2 = 6 sur sa cible (non vulnérable au moment des coups), **puis** « Vulnérable 2 » **sur cette cible seulement** : les autres n'ont rien. La marque du tour n'a donc été consommée ni par *Concentration* ni par *Balayage*.
- **Ne doit pas changer** : les 3 dégâts de *Balayage* à chaque ennemi ; la pioche de *Concentration*.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T3 — La carte qui tue sa cible ne consomme pas la marque (M5, A4)
*L'ennemi tué est encore à 0 PV quand le passif se résout : il doit être tenu pour absent, et la carte de dégâts suivante marque.*
- **Atteindre la situation** : « RUN DEBUG », **Mage** sous *Marque du Mage* ; deck : *Salve* ajoutée, cinq cartes du draft retirées. Acte 3, **au moins deux ennemis** ; onglet Combat, **PV du premier ennemi à 3**, les autres à pleine vie. « Mana » à 9.
- **Faire** : (a) jouer *Projectile Magique* sur le premier ennemi (5 dégâts : il meurt). Lire l'icône des autres. (b) Jouer *Salve* sur le deuxième ennemi.
- **Attendu** : (a) le premier ennemi meurt, la rangée se resserre ; **aucun** Vulnérable posé, nulle part (la signature n'a pas marqué un mort). (b) *Salve* frappe 6, **puis** « Vulnérable 2 » sur le deuxième ennemi : **la marque du tour n'avait pas été consommée** par la carte qui a tué.
- **Ne doit pas changer** : la mort d'un ennemi (XP, récompenses), la pioche de *Projectile Magique*.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T4 — *Projectile Magique* évolué en *Nova* ne marque personne (A3)
- **Atteindre la situation** : « RUN DEBUG », **Mage** sous *Marque du Mage* ; sur la carte, onglet « Heros », section « Évolutions de signature » : prendre *Acuité* (+2 dégâts par niveau) autant de fois que le menu le propose, jusqu'à ce que **le bouton *Nova* apparaisse** (une majeure, proposée quand le prochain palier est majeur) ; la prendre. Noter le nombre d'*Acuité* prises, n. Deck : *Salve* ajoutée, cinq cartes du draft retirées. Acte 3, **au moins deux ennemis**, pleine vie. « Mana » à 9.
- **Faire** : (a) jouer *Projectile Magique*, qui touche désormais tous les ennemis. (b) Jouer *Salve* sur un ennemi.
- **Attendu** : (a) chaque ennemi reçoit **5 + 2n** dégâts ; **aucune** icône de Vulnérable. (b) *Salve* frappe 6 ; « Vulnérable 2 » sur sa cible seule : *Nova* n'avait pas consommé la marque.
- **Ne doit pas changer** : la tuile de la signature, sa recharge, son coût.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T5 — *Sommation* : la Faiblesse réduit deux attaques, pas la troisième (M11, A19)
*Le décompte n'a pas changé : un ennemi vieillit ses statuts avant d'agir. Une Faiblesse de 3 tours, posée pendant le tour du joueur, est à 2 tours pendant la première attaque, à 1 pendant la deuxième, et **a expiré** avant la troisième.*
- **Atteindre la situation** : « RUN DEBUG », **Paladin** sous *Bénédiction* ; deck : *Sommation* ajoutée, cinq cartes du draft retirées. Acte 1 suffit, **un ennemi dont l'intention est une attaque** (lire le panneau des intentions ; en jouer un autre sinon). PV du héros à 100. **Ne jouer aucune carte d'Armure** : l'Armure fausserait les PV perdus. « Mana » à 3.
- **Faire** : noter l'intention affichée A (les dégâts), puis jouer *Sommation* sur l'ennemi. Lire son icône. « Fin de Tour » ; noter les PV perdus (a). Au tour 2, noter l'intention B, **ne rien jouer**, « Fin de Tour » ; noter les PV perdus (b). Au tour 3 : intention C, « Fin de Tour », PV perdus (c). Lire l'icône de l'ennemi après chaque phase.
- **Attendu** : « Faiblesse 1 » sur l'ennemi, avec ses tours (3). Phase 1 : **a ≈ 75 % de A** (arrondi), l'icône passe à 2 tours. Phase 2 : **b ≈ 75 % de B**, l'icône passe à 1 tour. Phase 3 : **c = C entière**, la Faiblesse a disparu avant l'attaque. Si une intention n'est pas une attaque, le noter : le test ne vaut que pour les phases où l'ennemi frappe.
- **Ne doit pas changer** : le barème de la Faiblesse (−25 % par point, 2 points au plus) ; l'ordre de la phase ennemie ; les dégâts des statuts.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T6 — *Prière* : la Source de Vie (M13)
*Un statut neuf, `hp_regen`, « Source de Vie » / « Life Spring » : il rend sa valeur au début des trois tours suivants, borné aux PV max. On règle l'Armure à 99 chaque tour pour que la phase ennemie ne touche pas aux PV.*
- **Atteindre la situation** : « RUN DEBUG », **Paladin** sous *Bénédiction* ; deck : *Prière* ajoutée, cinq cartes du draft retirées. Combat contre un ennemi. Onglet Combat : **PV du héros à 50**, « Mana » 3. *Prière* est un Pouvoir de coût 2.
- **Faire** : (a) jouer *Prière* ; lire le panneau « Effets du Joueur » et la carte. (b) **Armure à 99**, « Fin de Tour » ; lire les PV au début du tour 2. (c) Tour 2 : Armure à 99, **PV à 99**, « Fin de Tour » ; lire les PV au tour 3. (d) Tour 3 : Armure à 99, **PV à 60**, « Fin de Tour » ; PV au tour 4. (e) Tour 4 : Armure à 99, « Fin de Tour » ; PV au tour 5. Refaire (a) en anglais si la langue le permet.
- **Attendu** : (a) la ligne **« Source de Vie : +2 »** (anglais **« Life Spring: +2 »**) avec un **cœur rose**, 3 tours ; *Prière* quitte la main et **ne revient pas** (un Pouvoir s'épuise). Le statut de Vol de vie, s'il existe, garde son cœur rouge. (b) PV : **52**. (c) PV : **100**, jamais 101 (le soin est borné au max). (d) PV : **62**. (e) PV : **62**, la Source de Vie a disparu après sa troisième tic : **rien au quatrième tour**. La ligne disparaît du panneau.
- **Ne doit pas changer** : la *Potion de Soin* (3 PV d'un coup, inchangée) ; le panneau pour les autres statuts ; les PV de l'ennemi.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T7 — Carnage sous *Frénésie* : *Moulinet*, +4 Puissance, deux pioches (M9)
*Chaque mort donne 2 Puissance pour le tour et une pioche ; la Puissance du Berserker va aux Attaques et s'ajoute à chaque ennemi touché. Carnage est un lot des actes suivants : à l'acte 1, un seul ennemi par combat.*
- **Atteindre la situation** : « RUN DEBUG », **Berserker** sous *Frénésie* ; **« Chance de critique (%) » à 0** (onglet « Heros »). Deck : *Moulinet*, *Tourbillon*, *Coup de grâce* et trois *Frappe*, cinq cartes du draft retirées (six cartes : une seule est absente de la main, rejouer le combat si c'est l'une des trois du test). Acte 3, **au moins trois ennemis** ; onglet Combat : **PV des ennemis 1 et 2 à 7**, celui des autres à pleine vie. « Mana » à 9. Noter le nombre de cartes en main, N.
- **Faire** : (a) jouer *Moulinet* (7 à tous). (b) Jouer *Tourbillon*. (c) Jouer *Coup de grâce*. Lire la Puissance du héros et les PV du dernier ennemi après chaque carte.
- **Attendu** : (a) les ennemis 1 et 2 meurent (7 ≥ 7), le troisième perd 7 ; la Puissance monte à **4** (2 par mort), et la main gagne **deux cartes** (N − 1 + 2). (b) le survivant perd **2 + 4 = 6** ; *Tourbillon* pioche 1. (c) le survivant perd **10 + 4 = 14**. Ordre : à pleine vie 100, le survivant passe à 93, puis 87, puis 73. (d) Au tour suivant, la Puissance du tour est retombée à 0.
- **Ne doit pas changer** : les dégâts de *Moulinet* à chaque ennemi vivant, sans bonus avant la première mort ; la pioche de *Tourbillon*. **À juger, à l'acte 1** (un seul ennemi) : *Moulinet* y frappe une seule cible, et la mort de l'ennemi finit le combat — noter si le lot Carnage y paraît creux.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T8 — *Réprimande* et *Bénédiction* : l'Armure qui survit devient des PV (M11)
*Le Paladin a 1 de Maîtrise : chaque tranche de 5 points d'Armure survivante rend 2 PV. La Faiblesse de* Réprimande *fait survivre l'Armure.*
- **Atteindre la situation** : « RUN DEBUG », **Paladin** sous *Bénédiction* ; deck : *Réprimande* et *Défense* ×2 (les cinq cartes du draft retirées). Un ennemi dont l'intention est une attaque, de valeur A (la lire). **PV du héros à 50.** « Mana » 3.
- **Faire** : jouer *Réprimande* sur l'ennemi puis *Défense* deux fois ; lire l'Armure du héros ; « Fin de Tour » ; lire les PV au début du tour suivant.
- **Attendu** : *Réprimande* donne **4 Armure** (puis « Faiblesse 1 », 2 tours, sur l'ennemi), l'Armure monte à **14**. L'attaque, réduite de 25 %, vaut environ 0,75 × A ; l'Armure restante S = 14 − 0,75 × A. Au début du tour suivant, PV = **50 + 2 par tranche de 5 de S** : par exemple A = 8 → S = 8 → **+2 PV (52)** ; A = 4 → S = 11 → +4 (54). Si l'intention n'est pas une attaque : S = 14 → +4. L'Armure est ensuite remise à 0.
- **Ne doit pas changer** : l'Armure qui absorbe les dégâts normaux ; la règle de *Bénédiction* (le texte « chaque tranche de 5 points d'Armure survivante devient 1 PV », la Maîtrise s'ajoute).
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T9 — *Édit* devant trois ennemis (M12)
- **Atteindre la situation** : « RUN DEBUG », **Paladin** sous *Bénédiction* ; deck : *Édit* ajoutée, cinq cartes du draft retirées. Acte 3, **trois ennemis** (rejouer sinon). PV du héros à 100, aucune Armure jouée. « Mana » 3 (*Édit* coûte 2).
- **Faire** : noter les intentions de chaque ennemi attaquant ; jouer *Édit* ; lire les trois icônes ; « Fin de Tour » ; noter les PV perdus à chaque attaque ; au tour suivant, « Fin de Tour » de nouveau et noter les PV perdus.
- **Attendu** : **« Faiblesse 2 »** sur chaque ennemi, 2 tours. Phase 1 : chaque attaque est **réduite de moitié** (−25 % par point). Phase 2 : la Faiblesse a expiré, **attaques entières**. Un ennemi qui n'attaque pas ne montre rien.
- **Ne doit pas changer** : les dégâts du héros ; la rangée des ennemis ; la durée affichée (2).
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T10 — *Exécution* : 4, +1 par tranche de 5 PV manquants (M10)
*Pas de multiplicateur : la croissance est la source livrée en vague 5, `targetMissingHp`, à 0,2 par PV manquant. Les chiffres ci-dessous prennent des PV manquants multiples de 5.*
- **Atteindre la situation** : « RUN DEBUG », **Berserker**, passif de votre choix, **« Chance de critique (%) » à 0**. Deck : *Exécution* ×3, cinq cartes du draft retirées. Acte 2 ou plus, un ennemi dont le **max de PV dépasse 40** (lire « (max N) » dans le champ de sa ligne). « Mana » à 9.
- **Faire** : (a) *Exécution* sur l'ennemi à pleine vie. (b) Onglet Combat : PV de l'ennemi à **max − 20**, puis *Exécution*. (c) PV à **8**, puis *Exécution*. (d) Plus tard, devant un **boss** (par la carte du monde) : le mettre à la moitié de ses PV max, jouer *Exécution*, noter les dégâts.
- **Attendu** : (a) **4 dégâts**. (b) **4 + 4 = 8 dégâts** (max − 20 → max − 28). (c) l'ennemi **meurt** : 4 + (max − 8) / 5 ≥ 8 dès que le max est de 28 ou plus. (d) **à juger** : pour un boss de 100 PV à mi-vie, 4 + 10 = 14 dégâts, soit 28 % de sa vie restante ; noter si le terme grandit assez ou trop vite face aux boss (A8).
- **Ne doit pas changer** : le coût de la carte (1) ; les autres Attaques à cible unique.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T11 — Le draft de départ des trois lots : 2 + 3, un groupe neutre de 9 (M2)
- **Atteindre la situation** : « RUN DEBUG » (ou « JOUER »), puis la sélection de classe : **Paladin** sous *Bénédiction*, puis **Berserker** sous *Frénésie*, puis **Mage** sous *Marque du Mage* et sous *Flux de Mana*. Arriver au draft de départ.
- **Faire** : lire les deux groupes ; compter ; choisir 2 cartes du lot et 3 neutres ; essayer d'en prendre une troisième du lot, une quatrième neutre ; valider.
- **Attendu** : le **groupe du lot** montre **5 cartes** sous *Bénédiction* (*Sommation*, *Édit*, *Réprimande*, *Prière*, *Métallisation*), **5** sous *Frénésie* (*Moulinet*, *Tourbillon*, *Coup de grâce*, *Exécution*, *Cri de Guerre*), **6** sous *Marque du Mage* (*Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, *Coup Empoisonné*, *Exploitation*, *Salve*). Le **groupe neutre** montre **9 cartes**, les mêmes pour les trois : *Frappe*, *Défense*, *Attaque Rapide*, *Frappe Lourde*, *Balayage*, *Mur de Fer*, *Éveil*, *Concentration*, *Potion de Soin*. Quotas : **2 du lot, 3 neutres** ; une troisième du lot ou une quatrième neutre est refusée ; la validation n'est possible qu'à 2 + 3. **Sous *Flux de Mana*** : aucun élémentaire, ni *Métallisation*, ni *Cri de Guerre*, dans aucun groupe.
- **Ne doit pas changer** : le deck de départ de cinq cartes ; le reste de l'écran.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T12 — La sélection de classe : neuf passifs, trois par classe (M1)
- **Atteindre la situation** : accueil, « JOUER » ou « RUN DEBUG », sélection de classe. En français, puis la langue de Windows en anglais pour la seconde passe.
- **Faire** : pour chacune des trois classes, déplier la liste « Passifs », lire les trois passifs et la description du deuxième du Mage ; changer de passif et revenir.
- **Attendu** : **trois passifs par classe**, **le premier préselectionné** comme avant. Paladin : *Régénération d'Armure*, *Ferveur*, *Bénédiction* (anglais : Armor Regeneration, Fervor, Blessing). Berserker : *Rage*, *Soif de Sang*, *Frénésie* (Rage, Bloodthirst, Frenzy). Mage : *Canalisation*, *Marque du Mage*, *Flux de Mana* (Channeling, Mage's Mark, Mana Flux). *Marque du Mage* dit : « À chaque tour, la première carte de dégâts, Attaque ou Compétence, qui vise un seul ennemi sans le tuer lui applique 2 Vulnérable pendant 2 tours. » / « Each turn, the first damage card, Attack or Skill, that hits a single enemy without killing it applies 2 Vulnerable to it for 2 turns. » Aucun passif n'est absent ni grisé.
- **Ne doit pas changer** : les descriptions des six autres passifs ; la fiche du héros ; le passif préselectionné par défaut.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T13 — *Salve* et la Foudre : chaque coup reçoit le bonus (M8)
- **Atteindre la situation** : « RUN DEBUG », **Paladin**, passif au choix, Puissance 0 ; deck : *Coup de Tonnerre* et *Salve* ajoutées, cinq cartes du draft retirées. Un ennemi à 100 PV. « Mana » 3.
- **Faire** : jouer *Coup de Tonnerre* sur lui, puis *Salve* ; lire les chiffres jaunes et l'icône.
- **Attendu** : *Coup de Tonnerre* inflige 4 **puis** pose 1 Foudre : « ⚡ 1/3 » ; *Salve* frappe trois fois, chaque coup à **2 + 1 = 3**, avec **trois « +1 » jaunes** et **9 dégâts** en tout (100 → 87). Aucun halo (sous le seuil).
- **Ne doit pas changer** : l'ordre « les coups d'abord » du *Coup de Tonnerre* ; le coût des cartes.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T14 — Les quatre élémentaires dans leur lot : encore des Attaques (Q12)
*Elles changent de dossier, pas de type ; sous* Marque du Mage, *une Attaque de dégâts marque aussi.*
- **Atteindre la situation** : « RUN DEBUG », **Mage** sous *Marque du Mage* ; deck : *Boule de Feu* et *Trait de Glace*, cinq cartes du draft retirées ; un ennemi à 100 PV. « Mana » 3.
- **Faire** : jouer *Boule de Feu* sur l'ennemi ; lire son icône ; jouer *Trait de Glace* ; « Fin de Tour ».
- **Attendu** : *Boule de Feu* : 6 dégâts (100 → 94), **« Feu 2 »** (sans durée) et **« Vulnérable 2 »** (la première carte de dégâts du tour marque). *Trait de Glace* : 4 × 1,5 = **6 dégâts** (94 → 88), « Gel 2/3 » ; pas de nouvelle marque. Au début de la phase ennemie, le Feu inflige **2 × 2 = 4, en rouge, sans être amplifié par Vulnérable** (88 → 84). Les deux cartes sont **des Attaques** (leur bandeau, leur couleur).
- **Ne doit pas changer** : les valeurs de la vague 7 (6 + 2 Feu, 4 + 2 Gel) ; les règles des charges.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T15 — *Prière* reçoit la rune *Résonant* à la forge ; *Tourbillon* non (D10)
*Les règles de la forge ne changent pas : Résonant n'est refusée qu'aux cartes qui rendent du mana ou piochent. Prière ne fait ni l'un ni l'autre. Persistant ne s'offre à aucun Pouvoir.*
- **Atteindre la situation** : « RUN DEBUG », n'importe quelle classe ; sur la carte, onglet « Deck » : ajouter *Prière* **trois fois**, puis *Tourbillon* **trois fois**. Ouvrir « MON DECK ».
- **Faire** : sur *Prière* (3 exemplaires), choisir « Fusionner » et confirmer ; à l'écran « FUSION — CHOISISSEZ UNE RUNE », lire les runes offertes ; choisir *Résonant*. Refaire avec *Tourbillon*.
- **Attendu** : pour *Prière*, **deux runes** : *Allégé* et **Résonant** (« 15 % de chances de se rejouer » au niveau 1) ; jamais *Persistant*. Une *Prière* qui résonne pose deux Sources de Vie, soit +4 PV par tour (15 % de chances par jeu : le noter si on le voit, ne pas le chercher). Pour *Tourbillon* : *Résonant* **absent** (la carte pioche), les autres runes d'Attaque offertes.
- **Ne doit pas changer** : les runes des autres cartes ; le coût de la fusion ; les niveaux.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T16 — Les textes des faces, en français et en anglais (M6)
- **Atteindre la situation** : accueil « DICTIONNAIRE », onglet « Cartes » ; puis en combat (face Flame, infobulle d'appui long) les cartes en main : *Exécution*, *Exploitation*, *Salve*, *Prière*, *Sommation*, *Édit*, *Réprimande*, *Moulinet*, *Tourbillon*, *Coup de grâce*. En français puis en anglais.
- **Faire** : ouvrir chaque face et chaque infobulle ; en combat, regarder la face avant puis après avoir visé un ennemi.
- **Attendu** : *Exécution* : « Inflige 4 dégâts, +1 par tranche de 5 PV manquants de la cible. » / « Deal 4 damage, +1 per 5 missing HP on the target. » *Exploitation* : « Inflige 4 dégâts, +1 par point de Vulnérable de la cible. » / « Deal 4 damage, +1 per point of Vulnerable on the target. » — **en anglais, « Vulnerable », jamais « Vulnérable »**. *Salve* : « Inflige 2 dégâts 3 fois. » / « Deal 2 damage 3 times. » (noter si le badge dit « 2×3 »). *Prière* : en combat, « Pendant 3 tours, récupère 2 PV au début du tour. » / « For 3 turns, heals 2 HP at turn start. » ; au dictionnaire, la description du fichier : « For 3 turns, heal 2 HP at the start of your turn. » *Sommation* : « Applique 1 Faiblesse pendant 3 tours. » ; *Édit* : « Applique 2 Faiblesse à tous les ennemis pendant 2 tours. » ; *Réprimande* : « Gagne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. » ; *Moulinet*, *Coup de grâce* : « Inflige 7 / 10 dégâts à tous les ennemis. » ; *Tourbillon* : « … 2 dégâts à tous les ennemis et pioche 1 carte. » Les icônes de *Prière* (cœur rose) et de la Faiblesse sont celles du panneau ; **aucune icône en point d'interrogation**, aucune accolade `{…}`. **En main, la face d'une carte à cible affiche la base (4) tant qu'aucune cible n'est visée : à juger** (noter si le terme de croissance manque ou trompe).
- **Ne doit pas changer** : les faces des autres cartes ; le dictionnaire, ses onglets et son tri (toutes les cartes du registre, **58**, y figurent, dont les seize des trois lots).
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T17 — Le tutoriel : *Boule de Feu* à l'étape des cartes, trois passifs au Mage (M14)
- **Atteindre la situation** : accueil « TUTORIEL » ; en français, puis en anglais si possible. Faire le tutoriel avec le Paladin, puis avec le Mage.
- **Faire** : à l'étape des cartes, lire les cartes montrées ; à l'étape de la classe, lire les passifs du Mage ; aller jusqu'au bout.
- **Attendu** : l'étape des cartes montre **toujours *Boule de Feu*** (6 dégâts, 2 Feu) à toute classe, même au Paladin : c'est une démonstration, pas une offre. Le Mage voit **trois passifs**, le premier préselectionné ; la description de *Marque du Mage* est la nouvelle. Le tutoriel ne simule aucun passif : *Marque du Mage* n'y fait rien. **Rien ne casse** jusqu'au bout.
- **Ne doit pas changer** : les étapes et leur ordre ; la galerie des statuts ; le Paladin et le Berserker du tutoriel.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T18 — Les autres passifs n'offrent plus les cartes déplacées (M15)
*Sous les six autres passifs, la boutique, la trouvaille et le draft de départ n'offrent plus les quatre élémentaires, la* Métallisation *ni le* Cri de Guerre. *Un test d'absence ne prouve rien seul : le groupe neutre du draft de départ (T11) en est la preuve ; celui-ci n'est qu'un contrôle.*
- **Atteindre la situation** : « JOUER », **Berserker** sous *Rage*, puis **Mage** sous *Canalisation*.
- **Faire** : jouer trois combats ; à chaque boutique et à chaque offre de carte (trouvaille), lire toutes les cartes proposées.
- **Attendu** : **aucune** *Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, *Coup Empoisonné*, *Métallisation* ou *Cri de Guerre*, dans la boutique ni dans la trouvaille ; seules les neuf neutres et le lot du passif choisi.
- **Ne doit pas changer** : les prix, les tirages de relique, le draft de niveau.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T19 — Vulnérable qui s'accumule : le plafond du barème (M7, A9)
*Sous* Marque du Mage, *les points s'additionnent d'un tour à l'autre sur la même cible ; le barème plafonne à 4 points (+100 %), mais l'ennemi affiche la somme brute et* Exploitation *la compte.*
- **Atteindre la situation** : « RUN DEBUG », **Mage** sous *Marque du Mage* ; deck : *Salve* et *Exploitation*, cinq cartes du draft retirées. Un ennemi qui encaisse quatre tours : **PV à pleine vie**, « PV du héros » à 100. « Mana » à 9.
- **Faire** : quatre tours de suite, jouer *Salve* sur lui (elle marque) et fin de tour ; au quatrième tour, jouer *Salve*, puis *Exploitation* ; lire l'icône et les dégâts à chaque tour.
- **Attendu** : l'icône monte de 2 à chaque tour : **2, 4, 6, 8** points. Au quatrième tour, après *Salve* : « Vulnérable 8 » ; *Exploitation* compte **8** (4 + 8 = 12) et le pipeline plafonne à +100 % : **24 dégâts**. **À juger** : noter la valeur réellement affichée (la durée peut limiter l'accumulation) et si le terme qui grandit au fil d'un long combat est trop fort.
- **Ne doit pas changer** : le barème de Vulnérable ; les dégâts des autres cartes.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## T20 — *Sentence* : le nombre d'attaques réduites (M16)
*Le décalage « une Faiblesse de N tours réduit N − 1 attaques » est antérieur à la vague (`0.5.7`) ; il est porté à la file. Ce test n'en fait que le point d'observation.*
- **Atteindre la situation** : « RUN DEBUG », **Paladin** ; sur la carte, onglet « Heros », section « Évolutions de signature » : prendre *Sentence* sous *Châtiment* (une majeure, proposée quand le prochain palier est majeur). Un ennemi dont l'intention est une attaque, PV du héros à 100, aucune Armure.
- **Faire** : jouer *Châtiment* sur l'ennemi (il applique 1 Faiblesse pendant 2 tours) ; « Fin de Tour » ; noter les PV perdus ; refaire sur un second tour.
- **Attendu** : la première attaque est **réduite de 25 %**, la seconde est **entière** (la Faiblesse de 2 tours a vieilli à 1, puis expiré avant l'attaque). Une seule attaque réduite : c'est ce que la tranche 3 ne change pas.
- **Ne doit pas changer** : les dégâts et l'Armure de *Châtiment* ; sa recharge.
- **Résultat** : ✅ — validé par le propriétaire le 19/11

## Ce qui doit rester inchangé
- **La Faiblesse** (−25 % par point, 2 points au plus, avant le gel du héros, même tic de début de tour) et **Vulnérable** (barème de P-1, plafonné à 4 points) : mêmes chiffres, mêmes couleurs, mêmes icônes. Aucun fichier de `proportional_status.dart` ni de `damage_pipeline.dart` n'a bougé.
- **Les charges élémentaires** : Gel, Feu et Foudre se posent, rompent et déclinent comme en `0.5.9` ; le Feu n'est amplifié ni par Vulnérable ni par la critique.
- **Les neuf neutres qui restent** (*Frappe*, *Défense*, *Attaque Rapide*, *Frappe Lourde*, *Balayage*, *Mur de Fer*, *Éveil*, *Concentration*, *Potion de Soin*) : mêmes valeurs, mêmes coûts, mêmes faces.
- **Les six cartes déplacées** (*Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, *Coup Empoisonné*, *Métallisation*, *Cri de Guerre*) : mêmes valeurs, mêmes ids.
- **Les six autres passifs et leurs lots** : *Régénération d'Armure*, *Ferveur*, *Rage*, *Soif de Sang*, *Canalisation*, *Flux de Mana* ; le passif préselectionné par défaut, le premier de chaque classe.
- **Le Vol de vie** garde son cœur rouge ; *Bénédiction* garde sa description et sa Maîtrise ; *Frénésie* garde la sienne.
- **La sauvegarde** : « Continuer » rend or, PV, deck, reliques, signatures et position ; rien de neuf n'y est écrit ; aucune sauvegarde en combat ; la run debug ne sauve rien.
- **La phase ennemie** : les actions dans l'ordre de la rangée, le bond de 200 ms, la pioche, le Mana, l'Armure remise à 0. Aucun ennemi ne pose la Source de Vie ni la Faiblesse.
- **Le menu de debug** : mêmes onglets, mêmes champs.
- **Les reliques** : aucune n'écoute le nouveau déclencheur ; leurs libellés d'effet sont ceux d'avant.

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
