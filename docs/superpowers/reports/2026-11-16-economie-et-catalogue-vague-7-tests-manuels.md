# Vague 7 — `0.5.9` — tests manuels

**Branche** : `feat/v0.5.9-p53-charges-elementaires` · **Compte rendu** : [2026-11-16-economie-et-catalogue-vague-7-compte-rendu.md](2026-11-16-economie-et-catalogue-vague-7-compte-rendu.md)
**Testé le** : 18/11/2026, par le propriétaire, au cours d'une run ; les tests ont été joués un par un, leurs résultats reportés ici sur sa déclaration
**Résultat** : 27 ✅ · 0 ❌ · 0 non testé (T27 ajouté le 17/11 pour le défaut D1)

**Repères communs.** Les tests sont numérotés T1 à T26 **dans l'ordre du risque**. Les seize points de la spec (§9.1, M1 à M16) y sont tous, sous un T, et chaque titre rappelle son M : M6 → T1, M5 → T2, M1 → T4, M2 → T5, M8 → T6, M9 → T9, M10 → T10 et T11, M7 → T13, M3 → T15, M4 → T16, M12 → T17, M15 → T20, M11 → T21, M13 → T23, M14 → T24. **M16, les animations, est détaillé par le plan de la partie 2 (Task 5, Step 4) en onze points, tous repris** : M16-F1 → T1, M16-F2 → T2 et T3, M16-G1 → T4, M16-G2 → T5, M16-L1 → T6, M16-L5 → T7, M16-L2 → T8, M16-G3 → T9, M16-L3 → T10, M16-F3 → T11, M16-L4 → T12. Les autres tests sont neufs : demandés par l'orchestrateur, ou renvoyés au test par le compte rendu (S10, S16, §4).

**Deux sortes de run.** « JOUER » lance une run normale, sauvegardée. « RUN DEBUG » (colonne DEBUG de l'accueil, build debug seulement) passe par la même sélection de classe et le même draft, mais **ne sauvegarde jamais rien**. Seule la run debug a le tiroir violet « DEBUG » au bord gauche. **Le menu de debug ne change pas** : mêmes onglets, mêmes champs, plus une section.
- **En combat, un seul onglet, « Combat »** : « PV », « Mana », « Armure », « Soin complet », « Mana plein », une ligne par ennemi (« 1. <nom> (PV/max) », champ chiffré, et « 0 PV »), « Tous les ennemis a 0 PV », « Gagner le combat », « Perdre le combat », « Sauter la phase ennemie ». **Tout en bas (faire défiler), la section « Charges »**, depuis la partie 1 : une ligne « Heros : » et une ligne « 1. <nom> : » par ennemi, chacune avec trois boutons « +1 Gel », « +1 Feu », « +1 Foudre », puis « Retirer les charges ». Un bouton pose **un point par la vraie règle** (plafond du Gel, refus sur un porteur gelé, rupture au seuil), **sans bonus de Puissance**.
- **Hors combat (carte du monde)** : « Heros » (« PV max », « Puissance », « Chance de critique (%) »…), « Run » (« Acte suivant (regenere la carte) »), « Deck » (« Ajouter une carte », et la liste « Deck maitre » pour retirer), « Reliques ». Un champ chiffré se valide en tapant la valeur puis Entrée. Le champ PV d'un ennemi **ne borne pas aux PV max** : on peut le monter à 100.
- **Passer d'acte** : onglet « Run », « Acte suivant (regenere la carte) », deux fois depuis l'acte 1, pour l'**acte 3**. Un combat normal compte **jusqu'à trois ennemis** (un à l'acte 1, davantage ensuite) : trois n'est qu'un plafond, le nombre réel est tiré. S'il y en a moins que demandé, jouer un autre combat ou passer encore d'acte. Le Feu n'a de voisins qu'à partir de deux ennemis.
- **Classes** : sauf mention, **Paladin sous *Régénération d'Armure*** (ni Puissance ni critique au départ ; le Berserker porte 10 % de critique, *Ferveur* donnerait de la Puissance), sans relique, **Puissance 0**. La Puissance « altération » ajoute des points de charge à chaque carte : tous les chiffres ci-dessous sont **sans Puissance**. Pour que la main d'ouverture contienne les cartes voulues : **avant le combat, sur la carte**, onglet « Deck », ajouter les cartes et retirer les autres de « Deck maitre ». « Mana » à 9 au besoin.

**Ce que la vague change, en bref.** Gel, Feu et Foudre ne sont plus des statuts à durée mais des **charges** : des points qui s'accumulent jusqu'à un seuil, où elles **rompent**. La Brûlure devient le **Feu**, l'Électrocution la **Foudre** (anglais : Freeze, Burn, Shock ; états rompus **Gelé** / Frozen et **Chargé** / Charged).
- **Gel** : seuil 3 (6 pour un boss, 5 pour le héros), +1 à chaque gel ; rien de plus sur un porteur gelé ; −1 point au tour du porteur s'il n'a pas gelé. **Ennemi gelé : il perd toute son action** (statuts quand même résolus). **Héros gelé : il joue, mais ses cartes et signatures infligent 50 % de dégâts en moins pendant son prochain tour.**
- **Feu** : s'accumule sans limite ; **au tour du porteur**, chaque tranche de 3 points inflige 12 au porteur et **explose** (12 dégâts et 1 Feu à chaque voisin) ; le reste inflige 2 par point, sans explosion. **La chaîne se joue vague par vague**, chaque vague simultanée, 800 ms par vague. Contre le Feu, **l'Armure absorbe** ; ni Vulnérable, ni critique, ni Faiblesse. Le héros porteur n'a pas de voisin.
- **Foudre** : chaque coup reçu fait **+1 par point** sous le seuil, **+2 par point** une fois **Chargé** (seuil 3, atteint dès la pose), jusqu'à la fin du tour en cours ; perd 1 point au tour du porteur sous le seuil. **Q-P2 (c), choix du propriétaire : chaque coup affiche son bonus « +N » en jaune `#FFEA00`, sous le seuil comme chargé ; le halo jaune dit qui est chargé.**
- **Animations (P-c)** : Gel = la **gangue** (voile bleu `#81D4FA` à 45 %, liseré blanc, qui monte en 0,4 s ; à l'action perdue, la carte tremble trois fois, la gangue éclate en six à huit éclats, « Gelé » flotte) ; Feu = l'**onde** (éclair radial orange `#FF6D00`, boules de feu vers les voisins, « +N 🔥 ») ; Foudre = le **halo** jaune qui pulse, sans éclair.

**Lire les charges.** Sur l'ennemi : « ❄ 2/3 », « ⚡ 2/3 » (points sur seuil courant), « 🔥 5 » (points seuls), « ⚡ 4 » **Chargé** en jaune vif, « ❄ » **Gelé**. Aucune durée sous une charge. Sur le héros, le panneau « Effets du Joueur » : « Gel : 2/5 », « Feu : 5 », « Foudre : 2/3 » ; gelé en attente « Gelé : −50 % de dégâts au prochain tour », actif « … ce tour » ; chargé « Chargé : +8 par coup ». **La langue suit celle de Windows** : pour l'anglais, passer la langue d'affichage en anglais et relancer ; sinon, noter « anglais non testé ».

**Valeurs relues (P-b), à vérifier aux textes** : *Embrasement* 3 Feu (4 en `0.5.8`), *Congelant* 1 Gel par niveau (2 en `0.5.8`) ; *Boule de Feu* 6 dégâts + 2 Feu, *Trait de Glace* 4 dégâts + 2 Gel, *Coup de Tonnerre* 4 dégâts **puis** 1 Foudre, *Nova de givre* 2 Gel à tous, *Rafale d'étincelles* 1 Foudre **puis** 3 × 3, *Brûlant* +1 Feu par niveau, *Surchargé* +1 Foudre par niveau, *Braise* +1 Feu par niveau : inchangés.

## À tester d'abord
<!-- du plus risqué au moins risqué -->
1. **T1** — La chaîne du Feu à trois ennemis : trois vagues, 48 / 64 / 48 de PV perdus, lus sur les cartes (M6, M16-F1).
2. **T2** — *Embrasement* : une tranche, deux vagues, l'Armure d'un voisin qui absorbe (M5, M16-F2).
3. **T3** — Feu et Poison sur la même carte : le Feu en rouge, le Poison en vert (S10, M16-F2).
4. **T4** — Le second *Trait de Glace* : la gangue monte, la carte se resserre (M1, M16-G1, S16).
5. **T5** — L'ennemi gelé à son action : il ne fait rien, la gangue éclate, le seuil monte (M2, M16-G2).
6. **T6** — La Foudre chargée par la *Rafale* : halo, trois « +6 », 27 dégâts (M8, M16-L1).
7. **T7** — *Rafale d'étincelles* sur un ennemi neuf : trois « +1 » jaunes, 12 dégâts, aucun halo (M16-L5, Q-P2 c).
8. **T8** — Une signature sur un ennemi chargé : « +6 » jaune, chemin direct (M16-L2).
9. **T9** — Le héros gelé : −50 % de dégâts, gangue pâle, givre aux coins (M9, M16-G3).
10. **T10** — Le héros porteur de Foudre, tiroir ouvert pendant la phase ennemie (M16-L3).
11. **T11** — Le héros porteur de Feu : éclair seul, rougeoiement (M10, M16-F3).
12. **T12** — Les halos s'éteignent à la fermeture de la phase (M16-L4).
13. **T13** — La mort d'un porteur de Feu : tué avant son tour, il n'explose pas ; tué par son Feu, il explose (M7).
14. **T14** — *Nova de givre* : deux Gel à tous, chacun sa piste.
15. **T15** — Le déclin : Gel et Foudre perdent 1 point au tour du porteur (M3).
16. **T16** — Le boss : « ❄ 2/6 » (M4).
17. **T17** — Le panneau du héros : lignes, libellé replié, liste qui défile (M12).
18. **T18** — Le panneau des intentions : l'ennemi gelé, l'intention entière sinon.
19. **T19** — Les charges ne survivent pas au combat ; la run normale se sauvegarde et reprend.
20. **T20** — La section « Charges » du menu de debug (M15).
21. **T21** — Les infobulles des cartes, en français et en anglais (M11).
22. **T22** — Les runes de forge et les cartes relues : *Brûlant*, *Congelant*, *Surchargé*, *Embrasement*.
23. **T23** — La signature *Braise* : « Applique 1 Feu » (M13).
24. **T24** — Le tutoriel : prose, galerie animée, panneau, étape des intentions (M14).
25. **T25** — L'éditeur de contenu à 600 px de haut, avec ses onze onglets (S10).
26. **T26** — La note de version `0.5.9`.
27. **T27** — La Puissance de statut affichée sur la carte (défaut D1, ajouté le 17/11).

## T1 — La chaîne du Feu : trois ennemis, trois vagues (M6, M16-F1)
*La chaîne se joue vague par vague ; la vague 2 touche B deux fois, la vague 3 le résout seul. Le défaut visé : une carte qui garde ses PV d'avant une vague, faute de boule de feu arrivée (revue de plan, point 4).*
- **Atteindre la situation** : « RUN DEBUG », Paladin, onglet « Run », « Acte suivant » deux fois (acte 3). Entrer dans un combat à **exactement trois ennemis** (sur quatre, la chaîne change ; s'il y en a moins, ou quatre, jouer un autre combat). Appelons-les A, B (celui du milieu), C. Onglet Combat : **les PV de A, B et C à 100** (au-dessus de 64, sinon les bords meurent dès la première vague). Aucune Armure sur eux : sinon l'Armure absorbe une part des dégâts et les chiffres changent (lire l'intention affichée ; en jouer un autre si l'un défend).
- **Faire** : en bas de l'onglet Combat, section « Charges », ligne de B : **« +1 Feu » neuf fois**. Vérifier « 🔥 9 » sur B ; fermer le tiroir ; toucher « Fin de Tour » ; regarder les trois vagues, puis lire les PV de chaque carte.
- **Attendu** : trois vagues, l'une après l'autre, 800 ms chacune. **Vague 1** : un éclair radial orange sur B et « −36 » ; puis une boule de feu vers A et une vers C, qui s'embrasent et montrent « −36 » et « +3 🔥 » **à l'arrivée de leur boule**. **Vague 2** : A et C se résolvent ensemble, un éclair sur chacun et « −12 » ; deux boules vers B, qui s'embrase et montre « −24 » et « +2 🔥 » (un seul « +2 🔥 », deux boules). **Vague 3** : B, à 2 points sous le seuil, **rougeoie seul**, sans éclair ni boule, « −4 ». Fin : **A a perdu 48 PV, B 64, C 48**, lus sur les cartes ; les trois icônes de Feu ont disparu ; aucune carte n'a gardé ses PV d'avant une vague. Pause visible de 0,2 s entre deux vagues.
- **Ne doit pas changer** : l'ordre de la phase ennemie (le Feu d'abord, puis les actions des ennemis) ; les actions de A, B et C après la chaîne ; la rangée qui ne bouge pas pendant la chaîne.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T2 — *Embrasement* : une tranche, deux vagues, l'Armure qui absorbe (M5, M16-F2)
*Les chiffres sont ceux de P-b : 3 Feu, une tranche exacte (à 4 points, le quatrième ne ferait que 2).*
- **Atteindre la situation** : « RUN DEBUG », Paladin, acte 3 ; sur la carte, onglet « Deck », ajouter *Embrasement* (et *Défense* si utile) ; combat à trois ennemis (A, B milieu, C). PV des trois à 100.
- **Faire** : jouer *Embrasement* sur B (1 Mana) ; lire « 🔥 3 » ; « Fin de Tour ». Regarder la phase ennemie. Si un voisin affiche une **intention de Défense**, noter si son Armure est déjà posée au début de la phase ennemie ; sinon, rejouer un autre combat jusqu'à en voir un.
- **Attendu** : au début de la phase ennemie. **Vague 1** : une tranche ; un éclair sur B et « −12 », puis deux boules, chaque voisin s'embrase avec « −12 » et « +1 🔥 ». **Vague 2** : les deux voisins, à 1 point, **rougeoient seuls**, « −2 » chacun, sans éclair. B ne reçoit rien en vague 2 (ses voisins n'ont aucune tranche). Total : B −12, chaque voisin −14. Un voisin porteur d'Armure la voit absorber : **un « −N » bleu**, N étant ce que l'Armure a pris, puis le reste en dégâts (P-d : l'Armure absorbe le Feu). Un bout de rangée n'a qu'un voisin, un ennemi seul aucun.
- **Ne doit pas changer** : l'Armure qui absorbe les dégâts normaux ; Vulnérable, critique et Faiblesse qui **n'amplifient pas** le Feu (le Paladin n'a pas de critique).
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T3 — Feu et Poison ensemble : rouge et vert (S10, M16-F2)
*Neuf : le Feu s'affichait en vert Poison sur un ennemi empoisonné (compte rendu, S10) ; corrigé par la partie 2.*
- **Atteindre la situation** : « RUN DEBUG », Paladin, acte 3 ; sur la carte, onglet « Deck », ajouter *Embrasement* et *Coup Empoisonné* (3 dégâts, 1 Poison). Combat à trois ennemis, PV à 100. (a) *Coup Empoisonné* sur A (un voisin), puis *Embrasement* sur B. (b) À un autre tour ou un autre combat : *Coup Empoisonné* **et** *Embrasement* sur B, le porteur.
- **Faire** : « Fin de Tour » ; regarder la couleur de chaque chiffre pendant la chaîne puis après elle.
- **Attendu** : (a) A, voisin empoisonné, reçoit le Feu de B : « −12 » **en rouge** (vague 1), puis « −2 » en rouge (vague 2) ; **après la chaîne**, au tour de statuts, son Poison : « −1 » **en vert**. (b) B perd 12 **en rouge** (le Feu), puis 1 **en vert** (le Poison), dans cet ordre. Jamais de Feu en vert, jamais de Poison en rouge. Le Feu passe avant le Poison.
- **Ne doit pas changer** : le Poison inflige sa valeur et vieillit au tic ; sa couleur verte seul.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T4 — Le second *Trait de Glace* : la gangue, le serrement (M1, M16-G1, S16)
*S16 : le serrement de la gangue (échelle 1 → 0,97 → 1, 3 %) pourrait ne pas se voir sous le sursaut du coup de *Trait de Glace* (22 %), deux `ScaleEffect` imbriqués s'additionnant. Le propriétaire tranche.*
- **Atteindre la situation** : « RUN DEBUG », Paladin ; sur la carte, onglet « Deck », *Trait de Glace* trois fois. Combat contre un ennemi non boss ; Mana à 9 au besoin.
- **Faire** : jouer *Trait de Glace* sur lui ; regarder l'icône et le panneau des intentions. Jouer un second *Trait de Glace* ; regarder l'ennemi **pendant la pose**, sans cligner : la montée de la gangue, la carte après le coup. Rester sur le tour du joueur ; essayer d'en poser un troisième.
- **Attendu** : après le premier : 4 dégâts, « ❄ 2/3 », pas de gangue. Après le second (un seul point posé, 2 → 3, le reste est plafonné) : « ❄ **Gelé** » ; **la gangue bleue monte du bas vers le haut en 0,4 s**, voile bleu glacier bordé d'un liseré blanc ; la carte se resserre à peine ; **après le second coup, la carte retrouve sa taille normale** (S16). Le panneau des intentions dit « Gelé : ne fait rien ce tour », l'intention barrée en gris. La gangue **reste tout le tour du joueur**. Un troisième Gel ne pose rien (« Rien de plus sur un porteur gelé »). **À noter pour le propriétaire** : le serrement de 3 % se voit-il sous le sursaut du coup ? Si non, il faudra le jouer après le sursaut.
- **Ne doit pas changer** : les 4 dégâts de chaque *Trait de Glace* ; leur coût de 1 Mana ; l'intention de l'ennemi, entière jusqu'à son action.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T5 — L'ennemi gelé à son action : il ne fait rien (M2, M16-G2)
- **Atteindre la situation** : comme T4, ennemi gelé (deux *Trait de Glace*) ; de plus, **un Poison sur lui** : *Coup Empoisonné* au deck, joué sur lui avant le gel. Combat à un ou deux ennemis.
- **Faire** : « Fin de Tour » ; regarder l'ennemi gelé à sa place dans la phase ennemie (pendant que les autres agissent) ; lire son intention au tour suivant ; poser *Trait de Glace* sur lui (le seuil monté).
- **Attendu** : au début de la phase ennemie, **son Poison le blesse** (« −1 » vert) : ses statuts se résolvent quand même. À son tour d'action : **il ne fonce pas** ; sa carte **tremble trois fois** (0,3 s), la gangue **se brise en six à huit éclats** blancs et bleu clair projetés autour de la carte, « **Gelé** » flotte au-dessus ; le héros ne perd ni PV ni Armure. **Au tour suivant : aucune gangue**, l'icône « ❄ » disparue (0 point), et il montre **l'intention d'après dans son cycle** (celle perdue est consommée). Un nouveau *Trait de Glace* dit « ❄ **1/4** » (le seuil monte de 1 à chaque gel : 3 → 4) ; un second le gèle de nouveau à 4.
- **Ne doit pas changer** : son Poison (valeur et tic) ; la mort de l'ennemi ; les actions des autres ennemis ; la phase ennemie des ennemis non gelés (bond de 200 ms).
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T6 — La Foudre chargée par la *Rafale* : halo et « +6 » (M8, M16-L1)
*Les 27 dégâts de D86 : 3 × (3 + 6).*
- **Atteindre la situation** : « RUN DEBUG », Paladin, sans relique, Puissance 0 ; **sur la carte**, onglet « Deck » : ajouter *Coup de Tonnerre* et *Rafale d'étincelles*, **retirer toutes les autres cartes** de la liste « Deck maitre » (pour que la main d'ouverture les contienne). Combat ; **onglet Combat, les PV de l'ennemi visé à 100** (au-dessus de 40, pour que les 27 se lisent en entier). Mana 3.
- **Faire** : dans le même tour : (a) jouer *Coup de Tonnerre* sur lui (1 Mana). (b) Section « Charges », ligne de l'ennemi : « +1 Foudre ». (c) Jouer *Rafale d'étincelles* (2 Mana). (d) « Fin de Tour ».
- **Attendu** : (a) 4 dégâts **puis** 1 Foudre : « ⚡ 1/3 » (le coup frappe avant de poser : il prépare). (b) « ⚡ 2/3 ». (c) la *Rafale* pose 1 Foudre : **3/3, chargé aussitôt** ; **le halo jaune naît** autour de la carte (0,2 s) et **pulse** toutes les 0,6 s ; l'icône « ⚡ 3 **Chargé** » en jaune vif ; **trois « +6 » en jaune, décalés d'environ 100 ms, avec « −27 »** (3 × (3 + 6)). (d) au début de la phase ennemie, la Foudre a disparu, le halo aussi.
- **Ne doit pas changer** : les dégâts de base (4, puis 3 × 3) ; le coût des cartes ; l'ordre « pose puis coups » de la *Rafale*.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T7 — *Rafale d'étincelles* sur un ennemi neuf : trois « +1 » jaunes (M16-L5, Q-P2 c)
*Q-P2 (c), choix du propriétaire le 17/11 : chaque coup affiche son bonus, sous le seuil comme chargé, dans le même jaune `#FFEA00`.*
- **Atteindre la situation** : comme T6, à un autre combat (ou le même, ennemi neuf). L'ennemi **sans Foudre**.
- **Faire** : jouer *Rafale d'étincelles* en premier sur lui (2 Mana) ; regarder les chiffres, leur couleur, l'ennemi ; lire l'icône.
- **Attendu** : la *Rafale* pose 1 Foudre puis frappe 3 × (3 + 1) = **12** ; **trois « +1 », décalés, dans le même jaune** que les « +6 » de T6 (à comparer côte à côte si possible), avec « −12 » ; **aucun halo** (sous le seuil) ; l'icône « ⚡ 1/3 ». Même jaune, mêmes tailles de police : seul le nombre change.
- **Ne doit pas changer** : les 3 dégâts de base par coup ; la durée du coup (le total « −12 » reste réglé sur le son de l'impact).
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T8 — Une signature sur un ennemi chargé : « +6 » (M16-L2)
*Le chemin direct, par opposition au chemin différé de la *Rafale* (T6).*
- **Atteindre la situation** : « RUN DEBUG », **Mage** (n'importe quel passif), Puissance 0 ; combat. Onglet Combat, section « Charges », ligne de l'ennemi : **« +1 Foudre » trois fois** (chargé : « ⚡ 3 Chargé », halo).
- **Faire** : jouer *Projectile Magique* (la signature de dégâts du Mage) sur lui ; regarder les chiffres.
- **Attendu** : **un « +6 » en jaune** (`#FFEA00`), et le total « −(dégâts de la signature + 6) » ; le halo jaune est toujours là. Pas de décalage entre les chiffres.
- **Ne doit pas changer** : les dégâts de base de *Projectile Magique* ; son coût ; son animation.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T9 — Le héros gelé : −50 % de dégâts, sans perdre son tour (M9, M16-G3)
- **Atteindre la situation** : « RUN DEBUG », Paladin ; sur la carte, onglet « Deck », *Frappe* en nombre ; combat contre un ennemi dont les PV sont à 100. Mana 3.
- **Faire** : (a) section « Charges », ligne « Heros : » : **« +1 Gel » cinq fois** ; regarder l'écran à chaque clic, puis la ligne du panneau « Effets du Joueur ». (b) Un sixième « +1 Gel ». (c) « Fin de Tour ». (d) Au tour suivant : jouer une *Frappe*, une signature ; regarder le héros et les coins de l'écran. (e) Au tour d'après. (f) Refaire (a) à (c) ; pendant le tour gelé, onglet Combat, « Retirer les charges ».
- **Attendu** : (a) « Gel : 1/5 », puis 2/5 … ; **à 5, aucune animation neuve** pendant l'attente ; la ligne dit « **Gelé : −50 % de dégâts au prochain tour** » (repliée sur deux lignes, pas de colonne de durée). (b) rien posé (« un porteur gelé n'en reçoit plus »). (c) le tour passe normalement. (d) la ligne dit « … **ce tour** » ; **il pioche, joue cartes et signatures** (il ne perd pas son tour) ; **une *Frappe* de 6 en fait 3** ; chaque coup d'un multi-coups est réduit de moitié ; **gangue pâle (25 %) sur la carte du héros et givre bleu aux quatre coins de l'écran**, ce givre **sous les cartes de la main** (il ne les cache pas). (e) **ni gangue ni givre**, plus de ligne. (f) « Retirer les charges » les retire aussi, gangue et givre compris, aussitôt.
- **Ne doit pas changer** : les dégâts des statuts du héros ne sont pas réduits ; la pioche, le Mana, l'Armure du tour ; le seuil du Gel du héros (5) distinct de celui des ennemis (3).
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T10 — Le héros porteur de Foudre : chargé pendant son tour, puis pendant la phase ennemie (M16-L3, M10)
*La Foudre du héros n'est posable que par l'entrée de debug. Pendant la phase ennemie, le tiroir de debug **doit rester ouvert** : on ne peut pas poser autrement.*
- **Atteindre la situation** : « RUN DEBUG », Paladin ; combat contre **un ou deux ennemis dont l'intention est une attaque** (lire le panneau des intentions).
- **Faire** : (a) pendant son tour, **« +1 Foudre » trois fois** sur « Heros : » ; regarder la carte du héros ; « Fin de Tour ». (b) Au tour suivant : **deux « +1 Foudre » sur le héros**, tiroir **laissé ouvert**, « Fin de Tour » ; regarder la première attaque ennemie. (c) **Avant** l'attaque suivante, pendant la phase ennemie, tiroir ouvert : une **troisième « +1 Foudre »** ; regarder la carte du héros et les attaques qui suivent. (d) À la fin de la phase ennemie.
- **Attendu** : (a) **le halo jaune naît aussitôt sur la carte du héros** (0,2 s), pulse ; il **s'éteint au début de la phase ennemie** (A9 : fermeture du tour du joueur) ; le héros prend les coups ennemis sans bonus. (b) la **première attaque ennemie affiche « +2 » en jaune** (2 points sous le seuil : +1 par point) ; panneau « Foudre : 2/3 ». (c) à 3 points, **le halo naît sur sa carte** ; **chaque attaque qui suit affiche « +6 » dans le même jaune** (3 points chargés : 2 × 3) ; les dégâts reçus sont ceux de l'attaque + 6. (d) **le halo s'éteint à la fin de la phase ennemie**, la Foudre retombe à 0.
- **Ne doit pas changer** : les attaques ennemies à 0 point de Foudre ; la Foudre qui ne s'applique pas aux dégâts de statuts.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T11 — Le héros porteur de Feu : l'éclair seul, le rougeoiement (M10, M16-F3)
- **Atteindre la situation** : « RUN DEBUG », Paladin ; combat ; **sans Armure** au début du tour (l'Armure est remise à 0 à chaque tour).
- **Faire** : (a) sur « Heros : » : **« +1 Feu » cinq fois**, puis « +1 Foudre » deux fois ; « Fin de Tour » ; lire les PV au début du tour suivant. (b) Un autre combat ou tour : **deux « +1 Feu »**, « Fin de Tour ».
- **Attendu** : (a) la Foudre : **chaque attaque ennemie fait +2** (T10). Au début de son tour, **le héros prend 16** (3 × 4 + 2 × 2, une tranche **et** 2 points de reste), **un éclair radial orange seul, sans boule de feu** ni voisin, et « −16 » ; la Foudre n'y change rien ; sa ligne passe à « **Foudre : 1/3** » après son déclin ; il n'y a **pas d'explosion** (le héros n'a pas de voisin). (b) à 2 Feu, sous le seuil : **un simple rougeoiement** et « −4 » (2 × 4 × 50 %). Le Feu retombe à 0 après chaque résolution.
- **Ne doit pas changer** : la phase ennemie, la pioche et le Mana du tour ; l'Armure qui absorberait le Feu si elle était posée.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T12 — Les halos s'éteignent à la fermeture de la phase (M16-L4)
- **Atteindre la situation** : « RUN DEBUG », Paladin ; combat contre deux ennemis. Un ennemi chargé (trois « +1 Foudre » sur sa ligne) ; le héros chargé **pendant son tour** (trois « +1 Foudre » sur « Heros : »).
- **Faire** : regarder les deux halos ; « Fin de Tour » ; regarder l'instant où la bannière « TOUR ENNEMI » s'affiche. Puis, **pendant la phase ennemie**, tiroir ouvert, trois « +1 Foudre » sur le héros ; attendre la fin de la phase.
- **Attendu** : **le halo de l'ennemi chargé, et celui du héros chargé pendant son tour, s'éteignent au début de la phase ennemie**, avant la première action ennemie ; le halo du héros chargé **pendant la phase ennemie s'éteint à sa fin**, pas plus tard (pas de halo qui survit jusqu'au tour suivant). Aucun halo ne naît deux fois sur la même carte.
- **Ne doit pas changer** : « Retirer les charges » du debug, qui éteint aussi tout halo.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T13 — La mort d'un porteur de Feu (M7)
- **Atteindre la situation** : « RUN DEBUG », Paladin, acte 3 ; trois ennemis. (a) *Coup Empoisonné*, ou onglet Combat, « 0 PV » : un porteur de Feu **tué par une carte** avant son tour. (b) À un autre combat, un porteur dont les PV sont **plus bas que son Feu** : B à 10 PV, 6 « +1 Feu » (2 tranches : 24 > 10), A et C à 100.
- **Faire** : (a) poser du Feu sur B, le tuer d'une carte (ou d'un « 0 PV »), « Fin de Tour ». (b) « Fin de Tour ».
- **Attendu** : (a) **B n'explose pas** (il perd son Feu avec lui) ; A et C intacts. (b) B, tué par sa propre résolution, **explose quand même** : ses voisins A et C sont touchés (« −24 » et « +2 🔥 » chacun), **B reste affiché jusqu'à la fin de la chaîne**, ne reçoit ni dégâts ni Feu des vagues suivantes ; **puis il disparaît et la rangée se resserre** (A et C se rapprochent) après les statuts. La suite de la phase ennemie ne le compte plus.
- **Ne doit pas changer** : la mort d'un ennemi sans Feu ; l'XP et les récompenses quand le dernier ennemi meurt.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T14 — *Nova de givre* : deux Gel à tous, chacun sa piste
- **Atteindre la situation** : « RUN DEBUG », **Mage** sous *Flux de Mana* (déplier « Passifs » à la sélection ; *Nova de givre* est une carte de ce lot), Puissance 0 ; sur la carte, onglet « Deck », ajouter *Nova de givre* trois fois. Combat contre deux ou trois ennemis (dont un boss si possible).
- **Faire** : jouer *Nova de givre* (2 Mana) ; lire chaque ennemi ; la rejouer.
- **Attendu** : au premier jeu, **« ❄ 2/3 »** sur chaque non-boss (**« ❄ 2/6 »** sur un boss) ; au second, **chaque non-boss est gelé** (gangue sur chacun, « ❄ Gelé »), le boss à « 2/6 » → 4/6 (non gelé) ; **chaque porteur a sa propre piste** : le seuil de chacun passe à 4 après son gel, indépendamment des autres. Pas de bonus de Puissance sans Puissance.
- **Ne doit pas changer** : les autres cartes du lot ; le Mana de la carte.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T15 — Le déclin : Gel et Foudre perdent 1 point au tour du porteur (M3)
- **Atteindre la situation** : « RUN DEBUG », Paladin ; combat contre un ennemi non boss ; son PV à 100.
- **Faire** : poser **2 Gel** (« +1 Gel » deux fois, ou un *Trait de Glace*) et **2 Foudre** (deux « +1 Foudre ») sur lui ; « Fin de Tour » ; regarder son icône après la phase ennemie.
- **Attendu** : après la phase ennemie, **« ❄ 1/3 » et « ⚡ 1/3 »** : chaque charge perd 1 point à son déclin (au tour du porteur, s'il n'est pas rompu). Un porteur **rompu** ne décline pas : le Gel d'un ennemi gelé reste à 0 point, le seuil monté ne se lit qu'à la pose suivante. Le Feu ne décline jamais (sa charge se résout à chaque tour).
- **Ne doit pas changer** : le Poison ; les statuts à durée (Éveil de Puissance, Métallisation) qui déclinent au tic.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T16 — Le boss : « ❄ 2/6 » (M4)
- **Atteindre la situation** : « RUN DEBUG », Paladin ; atteindre un combat de boss (par la carte : nœud de boss ; ou passer d'actes et avancer). Tous les ennemis d'un combat de boss portent le statut de boss (un seul jusqu'à l'acte 5).
- **Faire** : poser du Gel : un *Trait de Glace*, ou deux « +1 Gel » sur sa ligne ; puis jusqu'à 6.
- **Attendu** : « ❄ **2/6** » après 2 points ; il gèle à **6**, pas à 3 ; le seuil passe à 7 après son premier gel. Chez un ennemi normal : 3 (4 après un gel, 5 après deux).
- **Ne doit pas changer** : les PV et l'échelle du boss ; ses intentions.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T17 — Le panneau du héros : lignes, libellé replié, défilement (M12)
*Q1 du compte rendu : la ligne « Gelé : −50 % de dégâts au prochain tour » débordait du panneau (248 px pour 189) ; elle est repliée sur deux lignes, sans colonne de durée, et au-delà de 120 px de réserve la liste défile, barre visible.*
- **Atteindre la situation** : « RUN DEBUG », Paladin ; combat ; sur « Heros : » : « +1 Gel » deux fois, « +1 Feu » cinq fois, « +1 Foudre » deux fois. Puis, pour la liste longue : ajouter *Barrière* et *Méditation* (Deck, avant le combat) et les jouer, pour poser aussi *Métallisation* et *Source de Mana*. Fenêtre large, puis < 600 px.
- **Faire** : lire le panneau « Effets du Joueur » (à gauche, au-dessus du bas) ; poser un cinquième Gel pour la ligne de gel en attente ; faire défiler la liste si elle dépasse.
- **Attendu** : « **Gel : 2/5** », « **Feu : 5** », « **Foudre : 2/3** », chacune avec son icône et sa couleur (celles d'`effect_icons.json`), **aucune icône en point d'interrogation** ; gelé : « Gelé : −50 % de dégâts au prochain tour » **replié sur deux lignes**, non tronqué par une ellipse. Au-delà de 120 px de réserve, **la liste défile, avec sa barre visible** ; la ligne repliée ne déborde pas du panneau (anglais : « Frozen: −50% damage next turn »). Chargé : « Chargé : +8 par coup » à 4 points (2 × 4).
- **Ne doit pas changer** : les autres statuts du panneau (*Éveil de Puissance*, *Métallisation*, *Source de Mana*), leurs icônes et leur ordre ; le panneau vide sans statut.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T18 — Le panneau des intentions : l'ennemi gelé, l'intention entière sinon
- **Atteindre la situation** : « RUN DEBUG », Paladin ; combat ; un ennemi avec une intention d'attaque lisible.
- **Faire** : lire le panneau des intentions ; poser **1 Gel**, puis 2, sur cet ennemi (« +1 Gel ») ; le geler ; lire de nouveau.
- **Attendu** : sous le seuil, **l'intention est entière** (plus de baisse de 25 % par point de Gel, comme en `0.5.8`) ; gelé, l'intention est **barrée, en gris**, et la ligne « **Gelé : ne fait rien ce tour** » (anglais : « Frozen: does nothing this turn »).
- **Ne doit pas changer** : l'affichage de l'intention d'un ennemi non gelé ; les couleurs du panneau.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T19 — Les charges ne survivent pas au combat ; la run se sauvegarde
- **Atteindre la situation** : (a) « RUN DEBUG », Paladin ; combat ; poser du Gel (jusqu'à geler un ennemi : le seuil passe à 4), du Feu, de la Foudre sur le héros ; onglet Combat, « Gagner le combat ». (b) « JOUER », Paladin : une run normale ; gagner un combat avec un ennemi gelé (seuil à 4), revenir à la carte, fermer la fenêtre, relancer, « Continuer ».
- **Faire** : (a) à la carte puis au combat suivant, lire le panneau du héros et l'icône du premier ennemi après un seul *Trait de Glace*. (b) entrer dans le combat suivant.
- **Attendu** : (a) **plus aucune charge** sur le héros ni sur les nouveaux ennemis ; un seul *Trait de Glace* dit « ❄ **2/3** » (le seuil de départ, **pas** le seuil monté du combat précédent). (b) la run reprend : or, PV, deck, reliques, signatures, position ; même résultat au combat suivant ; **aucune sauvegarde en combat**.
- **Ne doit pas changer** : la sauvegarde hors combat ; la run debug ne sauve rien.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T20 — La section « Charges » du menu de debug (M15)
- **Atteindre la situation** : « RUN DEBUG », Paladin ; un combat ; tiroir ouvert, onglet « Combat », **tout en bas**.
- **Faire** : lire la section ; sur « Heros : » et sur chaque ennemi, poser « +1 Gel » jusqu'au seuil, puis encore un ; « +1 Feu » ; « +1 Foudre » ; « Retirer les charges ». Hors d'une run debug (« JOUER »), vérifier que le tiroir n'existe pas.
- **Attendu** : un titre « Charges », **une ligne par porteur**, le héros puis chaque ennemi (« 1. <nom> : »), chacune avec les trois boutons « +1 Gel », « +1 Feu », « +1 Foudre » ; **la pose suit la règle du jeu** : le Gel se plafonne au seuil et **rompt** (gangue, « Gelé »), rien de plus sur un porteur gelé ; le Feu n'a pas de limite ; la Foudre rompt à 3 (halo). « **Retirer les charges** » vide **tous** les porteurs d'un coup, gangues, givre et halos compris. Aucune Puissance dans la pose.
- **Ne doit pas changer** : les autres champs et boutons de l'onglet Combat ; les onglets hors combat (« Heros », « Run », « Deck », « Reliques »).
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T21 — Les infobulles des cartes, en français et en anglais (M11)
- **Atteindre la situation** : accueil « DICTIONNAIRE », onglet « Cartes » ; puis en combat (face Flame), les cartes en main. *Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, *Embrasement*, *Rafale d'étincelles*, *Nova de givre*. En français puis en anglais.
- **Faire** : ouvrir l'infobulle de chaque carte (survol ou appui long), au dictionnaire puis en combat.
- **Attendu** : « **Applique 2 Feu.** » (anglais « Applies 2 Burn. ») **sans durée**, puis, **en parenthèse, la règle de la charge**, chiffres remplis (seuil, dégâts par point, explosion, voisins ; la Foudre : « +1 par point », « À 3, le porteur est chargé … » ; le Gel : « jusqu'à 3 (6 pour un boss) … ») ; **aucun « pendant N tours »**, **aucun pourcentage de Gel**. *Embrasement* : « Applique 3 Feu. » / « Apply 3 Burn. » ; *Coup de Tonnerre* : « Inflige 4 dégâts. Applique 1 Foudre. » ; *Rafale d'étincelles* : « Applique 1 Foudre, puis inflige 3 dégâts 3 fois. ». Aucune accolade `{…}`, aucune ligne vide, aucune icône en point d'interrogation. Le nom d'une charge dans une infobulle est celui de la langue active : « Gel », « Feu », « Foudre » ; « Freeze », « Burn », « Shock ».
- **Ne doit pas changer** : les faces et infobulles des autres cartes ; le dictionnaire, ses onglets et son tri.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T22 — Les runes de forge et les cartes relues
- **Atteindre la situation** : « RUN DEBUG », Paladin ; onglet « Deck », *Boule de Feu* et *Trait de Glace* ; la forge (« MON DECK ») : une rune *Brûlant*, une *Congelant*, une *Surchargé* à poser ; ou lire leur description dans la forge.
- **Faire** : lire les trois descriptions de rune ; poser *Congelant* niveau 1 sur *Trait de Glace* ; jouer la carte ; poser *Brûlant* 1 sur *Boule de Feu* et la jouer.
- **Attendu** : *Brûlant* « Applique {n} **Feu** » (jamais « Brûlure »), *Surchargé* « Applique {n} **Foudre** » (jamais « Électrocution »), *Congelant* « Applique **1 Gel** » par niveau (et non 2). *Trait de Glace* + *Congelant* 1 : **3 Gel** (2 + 1), donc **gelé aussitôt** ; *Boule de Feu* + *Brûlant* 1 : **3 Feu** (2 + 1), une tranche exacte, qui explose à la phase ennemie. Les noms des runes ne changent pas.
- **Ne doit pas changer** : les autres runes et leurs textes ; les niveaux et les coûts de la forge.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T23 — La signature *Braise* : « Applique 1 Feu » (M13)
- **Atteindre la situation** : « RUN DEBUG », **Mage** ; carte du monde, hors combat ; menu de debug, onglet « Heros », section « Évolutions de signature » : sous *Projectile Magique*, le bouton *Braise* (une mineure, proposée tant que le prochain palier est mineur).
- **Faire** : en combat, rester appuyé sur la tuile de *Projectile Magique* ; lire la liste de ses effets ; l'utiliser sur un ennemi.
- **Attendu** : « **Applique 1 Feu** », sans durée (jamais « Brûlure », jamais « pendant 2 tours »). Utilisée, la signature pose 1 point de Feu : « 🔥 1 » sur l'ennemi.
- **Ne doit pas changer** : les autres évolutions de la signature ; sa barre en combat ; son Niv. et ses puces.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T24 — Le tutoriel : les charges (M14)
- **Atteindre la situation** : accueil « TUTORIEL » ; en français puis en anglais ; aller aux étapes « Les Effets Élémentaires » puis « Les Intentions Ennemies ».
- **Faire** : lire la prose ; regarder la galerie (Gel, Feu, Foudre) pendant son cycle de deux secondes ; lire le panneau de démonstration ; passer à l'étape des intentions ; aller jusqu'au bout du tutoriel.
- **Attendu** : la prose dit que Gel, Feu et Foudre sont des **charges** qui s'accumulent jusqu'à un seuil, avec leurs états Gelé / Chargé (« Aucun chiffre dans la prose ») ; **la galerie montre la règle**, chiffres lus sur la donnée : Gel « ❄ 1/3 » → « ❄ 2/3 » → « ❄ Gelé » ; Feu « 🔥 1 » → « 🔥 2 » → « 🔥 3 » → « 💥 12 » ; Foudre « ⚡ 1/3 : +1 » → « ⚡ 2/3 : +2 » → « ⚡ Chargé : +6 ». **Le « 10 -> 5 » du Gel et la Brûlure qui perd 1 ont disparu.** Panneau de démonstration : **Poison 3** et « **Feu : 2** ». L'étape des intentions dit **qu'un ennemi Gelé ne fait rien à son tour** (plus « baisse tant qu'il est Gelé »). Rien ne casse jusqu'à la fin ; le tutoriel pose toujours du Feu avec *Boule de Feu*.
- **Ne doit pas changer** : les étapes et leur ordre ; le message « Mana restant » du tutoriel, le Paladin et le Berserker du tutoriel.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T25 — L'éditeur de contenu : onze onglets à 600 px de haut (S10)
*Neuf : le compte rendu (S10) renvoie ici la question « l'éditeur déborde-t-il à 600 px de haut avec onze onglets ? ».*
- **Atteindre la situation** : accueil, « EDITEUR DE CONTENU » ; une fenêtre d'environ **600 px de haut** (≈ 360 × 640 ou 1024 × 600).
- **Faire** : regarder la barre d'onglets (onze catégories, dont **« Charge élémentaire »** en dernier) ; ouvrir « Charge élémentaire » : lire ses entrées (Gel, Feu, Foudre) et un champ de rupture (`breaksOn`, `rupture.kind`, `heroRupture.kind` en listes) ; en essayer une modification invalide (un seuil de Feu à 2).
- **Attendu** : **la barre ne déborde pas** de l'écran à 600 px de haut (ou défile sans casser la mise en page) ; la catégorie « Charge élémentaire » liste les trois charges livrées ; une valeur invalide est refusée avec le **nom de la règle** (« un seuil de Feu inférieur à 3 est refusé »). *Noter précisément* : l'onglet coupé, le bouton hors champ, la hauteur à laquelle le débordement apparaît.
- **Ne doit pas changer** : les dix autres catégories, leurs champs et leur enregistrement.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T26 — La note de version `0.5.9`
- **Atteindre la situation** : accueil, « PATCH NOTES ».
- **Faire** : lire la première entrée.
- **Attendu** : en tête, `0.5.9`, du 17/11/2026, « **Les Charges Élémentaires** » : six lignes de « Nouvelles Fonctionnalités » (les trois charges, le Gel à 3 (6 pour un boss), le Feu qui explose et se propage, la Foudre et son halo jaune, l'affichage « ❄ 2/3 », « 🔥 5 » et « ⚡ 2/3 », le tutoriel), trois d'« Améliorations » (la Brûlure devient le Feu et l'Électrocution la Foudre ; l'intention d'un ennemi n'est plus réduite par le Gel ; les infobulles et la galerie), trois d'« Équilibrage » (*Embrasement* 3 Feu, *Congelant* 1 Gel par niveau, trois passifs masqués jusqu'à `0.6.0`). **Chaque phrase dit vrai** sur ce que les tests précédents ont montré. Si l'accueil affiche la version, il dit `0.5.9`.
- **Ne doit pas changer** : l'entrée `0.5.8` et les précédentes.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## T27 — La Puissance de statut affichée sur la carte (défaut D1)
- **Atteindre la situation** : un Paladin (ou un Mage) avec au moins 1 de Puissance — la relique *Pierre à aiguiser*, ou le menu de debug ; en combat, *Trait de Glace*, *Coup de Tonnerre* et *Coup Empoisonné* en main.
- **Faire** : lire le badge et l'infobulle de chaque carte, puis la jouer sur un ennemi et lire sa piste.
- **Attendu** : avec 1 de Puissance, *Trait de Glace* affiche 5 dégâts et **3 Gel**, et le boss passe à « ❄ 3/6 » ; *Coup de Tonnerre* affiche **2 Foudre** ; *Coup Empoisonné* affiche **2 Poison**. Le chiffre de la carte et celui posé sont **toujours égaux**. Avec un Berserker, orienté vers les seules Attaques, le statut garde son chiffre de base.
- **Ne doit pas changer** : les dégâts affichés (Puissance comprise, comme avant) ; un buff posé sur soi (*Puissance* temporaire) ne reçoit rien ; une carte qui pose deux statuts n'en renforce qu'un, le premier.
- **Résultat** : ✅ — validé par le propriétaire le 18/11, au cours d'une run

## Ce qui doit rester inchangé
- **Vulnérable** (barème de P-1 ; Vulnérable amplifie toujours les coups, bonus de Foudre compris, mais jamais le Feu), **Faiblesse** (−25 % par point, avant le gel du héros, sans s'y additionner) et **Poison** (inflige sa valeur, vieillit au tic, seul dégât sur la durée) : mêmes chiffres, mêmes couleurs (Poison vert), mêmes icônes, même moment.
- Les trois passifs encore masqués : *Bénédiction*, *Frénésie* et *Marque du Mage* absents de la sélection de classe, du tutoriel et du draft.
- Les deux passifs de chaque classe et leurs lots (`0.5.8`) : *Régénération d'Armure*, *Ferveur*, *Rage*, *Soif de Sang*, *Canalisation*, *Flux de Mana* ; la réserve de Mana, ses flèches et sa légende sous *Canalisation*.
- La sauvegarde : « Continuer » rend or, PV, deck, reliques, signatures, évolutions et position ; **aucune charge ni piste sauvegardée** ; aucune sauvegarde en combat ; une run debug ne sauve rien.
- Aucun ennemi ne pose de charge en `0.5.9` : leurs actions, intentions et statuts (hors Poison, Éveil de Puissance, Métallisation) sont ceux de `0.5.8`.
- Les cartes qui ne posent pas de charge, la forge, la fusion, les signatures et leurs évolutions, « MON DECK », les reliques, le draft de niveau.
- La phase ennemie hors Feu : les actions dans l'ordre de la rangée, le bond de 200 ms, la pioche, le Mana, l'Armure remise à 0.
- Le menu de debug : mêmes onglets, mêmes champs ; seule la section « Charges » de l'onglet Combat est neuve (partie 1).
- Les animations d'avant la vague : réactions aux coups, flottants de dégâts, particules.

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
| D1 | T4 (boss) | Paladin à 1 de Puissance : *Trait de Glace*, *Coup de Tonnerre* et *Coup Empoisonné* posent un point de plus que le chiffre affiché. La règle Q11/A15 (la Puissance renforce le premier statut posé sur un ennemi) est juste ; la carte n'affichait pas ce bonus. Antérieur à la vague. | Moyenne : le joueur est trompé sur ce qu'il pose | `ab1e0e32` ; retesté par T27 ✅ |
