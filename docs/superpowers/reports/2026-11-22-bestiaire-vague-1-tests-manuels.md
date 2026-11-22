# Vague 1 — `0.6.1` — tests manuels

**Branche** : `feat/v0.6.1-interface-des-ennemis` · **Compte rendu** : [2026-11-22-bestiaire-vague-1-compte-rendu.md](2026-11-22-bestiaire-vague-1-compte-rendu.md)
**Testé le** : 22/11/2026, par le propriétaire ; les résultats sont reportés ici sur sa déclaration
**Résultat** : 25 ✅ · 0 ❌ · 1 non testé, T20, non atteignable en jeu (T1 à T25, puis C1)

**Ce que la vague change, en bref.** Rien ne change à ce que les ennemis font ; seul change ce que le joueur voit d'eux. (1) Le panneau « INTENTIONS ENNEMIES » passe à trois colonnes (niveau, nom, pastille), sans les PV, avec une infobulle par ligne. (2) Au-dessus de chaque ennemi, une seule barre de PV, à la largeur de la carte, avec un voile d'armure bleu, à la place de l'ancien badge (Puissance, bouclier, petite barre). (3) Des languettes de part et d'autre des cartes, ennemis et héros : bonus à gauche (vert), altérations et charges à droite (rouge) ; au repos, l'icône et la valeur ; au survol de la carte, elles se déroulent. (4) Toucher un ennemi, sans carte ni signature en attente, ouvre sa fiche. (5) Le tutoriel suit. La vague emporte aussi le correctif S9 : un combat gagné ou perdu pendant la phase ennemie ne rouvre plus de tour.

**Repères communs.**
- **Deux sortes de run.** « JOUER » lance une run normale, sauvegardée. « RUN DEBUG » (colonne DEBUG de l'accueil, build debug seulement) passe par la même sélection de classe et le même draft, mais ne sauvegarde jamais rien. Seule la run debug a le tiroir « DEBUG » au bord gauche. **Le menu de debug ne change pas.**
- **En combat, un seul onglet, « Combat »**, de haut en bas : « PV (max N) », « Mana (max N) », « Armure » (ces trois champs sont ceux **du héros**), « Soin complet », « Mana plein » ; puis « Ennemis (N) », une ligne par ennemi (« 1. <nom> (PV/PV max) », champ chiffré, bouton « 0 PV ») ; « Tous les ennemis a 0 PV », « Gagner le combat », « Perdre le combat », « Sauter la phase ennemie » ; puis la section « Charges » : une ligne « Heros : » et une ligne par ennemi (« 1. <nom> : »), chacune avec les boutons **« +1 Gel »**, **« +1 Feu »**, **« +1 Foudre »**, et en bas « Retirer les charges ». Un champ chiffré se valide en tapant la valeur puis Entrée. Le champ PV d'un ennemi ne borne pas aux PV max : ne jamais le monter au-dessus.
- **Hors combat (carte du monde)**, cinq onglets : « Heros » (PV max, Mana max, Puissance, Chance de critique (%)…, les « Évolutions de signature »), « Run » (voir plus bas), « Deck », « Reliques ». **L'onglet « Deck »** : la liste « Ajouter une carte » (une ligne « <nom> (<coût>) », un appui = une copie au deck maître) et la liste « Deck maitre (N) » (un appui retire la carte). Pour qu'une carte voulue soit en main dès le premier tour : l'ajouter **sur la carte du monde, avant le combat**, et retirer les cinq cartes du draft de « Deck maitre » (une main compte 5 cartes : un deck de cinq cartes ou moins s'ouvre en entier).
- **Statuts et armure par le menu de debug : il n'y en a pas.** Le menu pose l'armure **du héros** seulement, et des charges (Gel, Feu, Foudre, « +1 » par appui) sur le héros comme sur chaque ennemi. **Il ne pose aucune armure sur un ennemi, ni aucun autre statut** (Puissance, Poison, Faiblesse, Vulnérable). Ces statuts d'ennemi s'obtiennent en jouant : *Sommation* (Faiblesse 1, 3 tours) et *Édit* (Faiblesse 2, 2 tours) sous le passif *Bénédiction* du Paladin ; *Coup Empoisonné* (Poison 1, 2 tours) et *Projectile Magique* sous *Marque du Mage* (Vulnérable 2, 2 tours) pour le Mage ; l'**Orc Furieux** pose sur lui-même sa Puissance (intention « Buff Puissance », 99 tours) quand il apparaît. Côté héros : *Méditation* (Mage, passif *Canalisation* : Régénération de mana 1, 2 tours), *Prière* (Paladin, passif *Bénédiction* : Source de Vie 2, 3 tours), *Fureur sanguine* (+1 Puissance, 1 tour) et *Forme Démoniaque* (+2 Puissance, 4 tours) pour le Berserker. Les noms de passif sont à choisir à la sélection de classe, en dépliant la liste « Passifs ».
- **Plusieurs ennemis.** Un combat normal compte **au plus un ennemi à l'acte 1, un de plus par acte** : jusqu'à 5 à l'acte 5. C'est un plafond, le nombre réel est tiré selon un budget : s'il y en a moins que demandé, jouer un autre combat. Le menu y saute : sur la carte du monde, onglet « Run », **« Acte suivant (regenere la carte) »** (une fois par acte, notification « Acte N — carte regeneree »), ou le champ **« Acte (sans regenerer la carte) »** pour fixer l'acte d'un coup (« 5 » pour jusqu'à cinq ennemis). Les ennemis du jeu : Slime, Gobelin (acte 1), Squelette (à partir de l'acte 6), **Orc Furieux (à partir de l'acte 11)**. Un boss se rencontre sur le nœud boss de la carte du monde (un seul ennemi à l'acte 1, un de plus tous les cinq actes).
- **Fenêtre et langue.** Les mesures de la vague sont prises à **1280 × 800**. Pour l'anglais, passer la langue d'affichage de Windows en anglais et relancer ; sinon, noter « anglais non testé ». Pour le tactile, un écran tactile ; sinon, noter « tactile non testé ».
- **Les situations que la vague ne permet pas d'atteindre en jeu** sont dites dans le test (voile d'armure, T20).
- **Mesures de référence** : la carte d'un ennemi mesure 100 × 140 unités ; à 1280 × 800 et cinq ennemis, une carte fait environ 143 px, 93 px séparent deux cartes, et une languette au repos mesure environ 43 px. La carte ouverte grandit de **× 1,25**, en **0,15 s**, et le voile d'estompage est un noir à **55 %**. Les languettes se déroulent en **0,1 s**.

## À tester d'abord
<!-- du plus risqué au moins risqué -->
**La fiche d'un ennemi (le geste le plus risqué de la vague)**
1. **T1** — Toucher un ennemi ouvre sa fiche : la carte agrandie, le plateau estompé, le cadre complet, FR et EN (M12).
2. **T2** — La barre, le haut de la carte et la languette au repos de l'ennemi ouvrent, ou gardent, sa fiche (T5-a).
3. **T3** — Tout ce qui ferme la fiche, et ce qui ne la ferme pas : le décor, la main, le HUD, le cadre, un autre ennemi, le clic droit (M13, T5-b, T5-c).
4. **T4** — La fiche pendant un coup : la carte se secoue et revient agrandie, ni trop grande ni trop petite (M17, T5-g, T5-h, C-a).
5. **T5** — La fiche quand le plateau bouge : redimensionnement, mort d'un ennemi, carte en vol, ouverture et fermeture rapides (T5-d, T5-f, C-b).
6. **T6** — La fiche suit le tour : « Fin de Tour » la ferme, la phase ennemie ne l'ouvre pas (M16).

**Le ciblage, qui ne doit pas avoir régressé**
7. **T7** — Carte focalisée : toucher la carte, la barre ou la languette d'un ennemi joue la carte, sans ouvrir de fiche (M14, T4-b, T4-c).
8. **T8** — Signature armée : toucher un ennemi la joue, sans fiche (M14).
9. **T9** — Glisser-déposer : lâcher une carte sur la carte, la barre ou la languette d'un ennemi la joue sur lui (A3, A9).
10. **T10** — Les bordures : l'ambre d'un ennemi frappé, le cyan des cibles possibles (T5-i).

**La fiche, suite**
11. **T11** — Le cadre se pose du bon côté, jamais hors de l'écran, sans couvrir la languette (M15, T5-e).
12. **T12** — La fiche d'un ennemi gelé, d'un boss, d'un ennemi à bonus et altération (T5-e).

**Les languettes et leur survol**
13. **T13** — Une carte survolée déroule ses deux languettes ; glisser sur la languette ouverte la garde ouverte (M8).
14. **T14** — Cinq ennemis à 1280 × 800 : les languettes au repos tiennent entre deux cartes (M9).
15. **T15** — Aux bords de l'écran, la languette se déroule vers l'intérieur (M20, T4-a, C-c).
16. **T16** — Un ennemi qui meurt sous la souris replie ses languettes (C-d).
17. **T17** — Les languettes du héros : 💎, 💖, deux Puissances, charges (M10).
18. **T18** — Au doigt, rien ne se déroule ; appui long sur une pastille (M11).

**La barre et le voile**
19. **T19** — La barre à la largeur de la carte, sans badge (M4).
20. **T20** — Le voile d'armure : plein, recule, se remplit, boss (M5, M6, M7) — situation non atteignable en jeu.

**Le panneau des intentions**
21. **T21** — Trois colonnes alignées, FR puis EN (M1).
22. **T22** — Une infobulle par ligne, la pastille survolée cerclée, les couleurs (M2).
23. **T23** — L'ennemi gelé : pastille grisée et barrée (M3).

**Le tutoriel**
24. **T24** — Les étapes « Vue d'ensemble » et « Intentions » du tutoriel (M18).

**Le correctif S9**
25. **T25** — Un combat gagné par le Feu ou le Poison pendant la phase ennemie ne rouvre aucun tour ; la mort du héros non plus (M19).

## Points que l'orchestrateur a vus et laisse à ton jugement
*Vus dans le jeu lancé (build web de debug, 1280 × 800, un seul ennemi), notés sans être jugés. À reprendre dans le test indiqué ; ce que tu en penses va dans la table des défauts, ou nulle part.*
1. **Le haut de la fiche et le bouton Son** (T11) : quand l'ennemi est au centre, le coin haut droit du cadre de la fiche passe de quelques pixels sous le bouton Son.
2. **La bordure ambre d'un ennemi frappé** (T10) : un ennemi qu'on vient de frapper garde une bordure ambre de 4, la même que celle d'une fiche ouverte. C'est le comportement d'avant la branche (la dernière cible jouée garde son ambre).
3. **Un seul ennemi, sa carte agrandie** (T1, T4) : à un seul ennemi, sa carte agrandie recouvre le haut de la carte du héros ; et le dégât flottant d'un coup porté sur la carte ouverte s'affiche sur le héros.
4. **Le chiffre d'armure sur la barre** (T20) : le chiffre d'armure cyan se lit mal sur le rouge de la barre quand le voile a reculé.
5. **Le même émoji pour deux statuts** (T13, T17) : la Puissance (à gauche, en vert) et la Foudre (à droite, en rouge) ont le même émoji ⚡.
6. **Une languette recouvre l'autre** (T15) : au bord de l'écran, une languette déroulée vers l'intérieur peut recouvrir l'autre languette de la même carte.
7. **Les ennemis non sélectionnés pendant une carte focalisée** (T10) : quand on prend une carte qui cible les ennemis, les ennemis non sélectionnés gardent une bordure cyan sous leur halo, au lieu de retomber au blanc.

*Ce qui n'a pas pu être vu et que le propriétaire est donc le premier à voir* : un combat à plusieurs ennemis (deux, puis cinq), l'anglais, le tactile et l'appui long, un ennemi gelé, un boss et son voile, les icônes 💎 et 💖 du héros, la version Windows elle-même.

## T1 — Toucher un ennemi ouvre sa fiche (M12)
*La fiche n'existait pas : toucher un ennemi sans carte ni signature en attente ne faisait rien.*
- **Atteindre la situation** : « RUN DEBUG », n'importe quelle classe, combat à l'acte 1 (un ennemi) ; puis la même chose à l'**acte 3** (« Acte (sans regenerer la carte) » à 3, onglet « Run », puis un combat) pour trois ennemis au plus. Aucune carte n'est prise en main, aucune signature n'est armée, c'est le tour du joueur.
- **Faire** : toucher (cliquer) la carte d'un ennemi. Lire le cadre à côté de la carte. Recommencer en anglais (langue de Windows).
- **Attendu** : en **0,15 s** la carte grandit (× 1,25) et descend, avec une **bordure ambre de 4** ; le reste du plateau (décor, héros, main, autres ennemis) passe sous un voile noir d'environ 55 % ; **les panneaux et les boutons du HUD restent nets**. À côté, un cadre de 310 de large, fond sombre, liseré ambre, de haut en bas : le **nom en capitales** (jaune) et « Niv. N » (gris) ; une ligne de chiffres « PV 9/14 » (blanc), le bouclier bleu et « Armure N » (cyan), « Puissance N » (rouge) — **« Armure 0 » et « Puissance 0 » s'affichent même à zéro** ; un trait ; « INTENTION » (gris) puis la pastille de l'intention, son nom (« Attaque Rapide », sans la valeur) et sa phrase (« Attaquera le héros pour 5 dégâts. ») ; « BONUS » (vert) et « ALTÉRATIONS » (rose-rouge) **seulement s'il y en a** : un ennemi sans statut n'a aucune de ces deux sections. En anglais : « HP », « Armor », « Might », « INTENT », « BUFFS », « DEBUFFS », « Lvl. N », « Will attack the hero for 5 damage. ».
- **Ne doit pas changer** : la main reste affichée sous le voile ; le panneau des intentions et la barre du haut restent nets ; les PV de l'ennemi ; aucun son de carte.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T2 — La barre, le haut de la carte et la languette au repos ouvrent aussi la fiche (T5-a)
*L'ennemi, c'est le rectangle qui va du haut de la barre au bas de la carte, plus ses languettes. La bande de 4 unités entre la barre et la carte n'est pas un trou.*
- **Atteindre la situation** : un combat à au moins deux ennemis (acte 3), un ennemi qui porte une charge pour avoir une languette (onglet Combat, section « Charges », « +1 Feu » sur « 1. <nom> »). Aucune fiche ouverte.
- **Faire** : (a) toucher la **barre de PV** d'un ennemi. Fermer (toucher le décor). (b) Toucher le **haut de sa carte**, juste sous la barre, dans la mince bande qui les sépare. Fermer. (c) Toucher sa **languette au repos** (celle qui porte le Feu). Fermer. (d) Fiche ouverte sur cet ennemi, toucher de nouveau sa barre, puis sa languette. (e) Fiche ouverte sur un autre ennemi, toucher la languette au repos du premier.
- **Attendu** : (a) à (c) la fiche de cet ennemi s'ouvre, et **reste ouverte** (elle ne s'ouvre pas puis se referme). (d) elle reste ouverte, sans clignoter. (e) la fiche du premier ennemi **remplace** celle de l'autre.
- **Ne doit pas changer** : les PV de l'ennemi ; aucune carte jouée.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T3 — Ce qui ferme la fiche, et ce qui ne la ferme pas (M13, T5-b, T5-c)
- **Atteindre la situation** : un combat à trois ennemis ou plus, une main en cours ; fiche ouverte sur un ennemi.
- **Faire** : fiche ouverte, essayer chacun de ces gestes, en rouvrant la fiche entre deux : (a) toucher le **décor** (le fond, entre les cartes). (b) Toucher une **carte de la main**. (c) Toucher un **bouton du HUD** (Deck, Son). (d) Toucher le **cadre de la fiche** lui-même. (e) Toucher la **carte ouverte**. (f) Toucher **un autre ennemi**. (g) **Clic droit** sur un autre ennemi. (h) Passer la souris sur la main, sans cliquer. (i) Souris immobile sur une carte de la main, cliquer. (j) À **cinq ennemis**, fiche ouverte sur l'ennemi de droite, toucher **Son**, puis **Deck**, à hauteur de sa barre.
- **Attendu** : (a) la fiche se ferme. (b) elle se ferme **et** la carte touchée se lève comme d'habitude. (c) elle se ferme, le bouton agit. (d) **elle ne se ferme pas**, et rien n'est touché dessous. (e) elle ne se ferme pas, rien ne se passe. (f) la fiche de l'autre ennemi **remplace** la première (le voile ne clignote pas). (g) rien ne change. (h) **aucune carte ne se lève au survol** : la main ne réagit pas tant que la fiche est ouverte. (i) la fiche se ferme, la carte se lève, **un seul son** joue, celui de la prise. (j) la fiche se ferme dans les deux cas : le bouton, peint au-dessus de la barre de l'ennemi, la ferme.
- **Ne doit pas changer** : le jeu au clic (carte, puis cible) ; les boutons du HUD gardent leur effet.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T4 — La fiche pendant un coup : la carte se secoue et revient agrandie (M17, T5-g, T5-h, C-a)
*La carte agrandie est à l'échelle × 1,25 ; la secousse d'un coup et les autres effets doivent la ramener à cette échelle, pas à celle d'avant.*
- **Atteindre la situation** : un combat, un ennemi à pleine vie, une carte d'attaque en main, du mana.
- **Faire** : (a) jouer l'attaque sur l'ennemi et, **avant l'impact**, toucher l'ennemi pour ouvrir sa fiche. (b) Attendre l'impact, fiche ouverte : lire le cadre. (c) Refaire (a), puis toucher le **décor** juste après l'impact, **pendant la secousse**. (d) Jouer une attaque sur l'ennemi, le toucher **juste après l'impact**, pendant sa secousse. (e) Ouvrir et fermer la fiche plusieurs fois, la souris immobile ; regarder la carte pendant la fermeture. (f) Toucher le décor, puis refaire la même chose en touchant un ennemi puis un autre.
- **Attendu** : (a) la fiche s'ouvre. (b) à l'impact, la carte agrandie **se secoue et revient agrandie** (× 1,25), pas à sa taille d'avant ; les PV du cadre changent avec le coup ; le dégât flottant se lit. (c) puis (d) la carte finit à **exactement** × 1,25 si la fiche est ouverte, **exactement** à sa taille au repos si elle est fermée. (e) elle grandit et descend en 0,15 s, sans à-coup, et revient de même ; fiche ouverte, **rien ne bouge ni ne clignote**. À la fermeture, la carte **reste claire du début à la fin** (jamais assombrie un instant) pendant que le reste de la scène s'éclaircit ; avec la souris dessus, elle déroule ses languettes dès la fermeture ; à la fin de son retour elles sont dans le bon sens — au bord de l'écran, une languette peut se retourner à ce moment-là. (f) d'un ennemi à l'autre, la carte quittée repasse sous le voile tout de suite.
- **Ne doit pas changer** : les dégâts réellement infligés ; la secousse et l'élan d'une carte qui frappe sans fiche ; l'effet de mort d'un ennemi.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T5 — La fiche quand le plateau bouge (T5-d, T5-f, C-b)
- **Atteindre la situation** : un combat à au moins trois ennemis (acte 3), une attaque qui tue un ennemi (mettre ses PV à 1 par le champ de sa ligne dans l'onglet Combat), une seconde attaque. Fenêtre redimensionnable.
- **Faire** : (a) fiche ouverte, **redimensionner la fenêtre** (plus grande, puis plus petite). (b) Jouer l'attaque mortelle sur l'ennemi à 1 PV et, **pendant son vol**, toucher **sa cible**. (c) Refaire, mais pendant le vol toucher **un autre ennemi**. (d) Toucher un ennemi puis le décor **le plus vite possible**, plusieurs fois de suite. (e) Au doigt, deux doigts presque ensemble : l'un sur un ennemi, l'autre sur le décor. (f) Sur le web, ouvrir la console du navigateur et regarder les erreurs.
- **Attendu** : (a) la carte ouverte et le cadre **suivent le nouvel emplacement**, la carte ni trop grande ni trop petite, le cadre toujours dans l'écran. (b) **aucune fiche ne s'ouvre** (la cible est mourante) ; elle meurt et disparaît. (c) la fiche de l'autre ennemi s'ouvre, les cartes se replacent à la mort de la première, la carte ouverte et le cadre suivent. (d) et (e) la scène n'est jamais laissée assombrie et aucune carte ne reste agrandie. (f) aucune erreur.
- **Ne doit pas changer** : l'effet de mort (la carte s'efface comme avant) ; l'XP et les récompenses.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T6 — La fiche suit le tour (M16)
- **Atteindre la situation** : un combat, fiche ouverte sur un ennemi, c'est le tour du joueur.
- **Faire** : (a) toucher « Fin de Tour ». (b) Pendant la phase ennemie, toucher un ennemi. (c) Au tour suivant, toucher un ennemi.
- **Attendu** : (a) la fiche se ferme dès la fin du tour, la carte retrouve sa taille. (b) **rien ne s'ouvre** pendant la phase ennemie. (c) la fiche s'ouvre de nouveau.
- **Ne doit pas changer** : l'ordre de la phase ennemie (actions dans l'ordre de la rangée, bond de 200 ms) ; la pioche ; le mana.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T7 — Carte focalisée : toucher un ennemi la joue, sans fiche (M14, T4-b, T4-c)
- **Atteindre la situation** : un combat à au moins deux ennemis, le héros porte au moins un statut (poser une charge : onglet Combat, section « Charges », ligne « Heros : », « +1 Gel »), une carte d'attaque et une carte de défense (qui cible soi) en main, assez de mana.
- **Faire** : (a) prendre la carte d'attaque (elle se lève, les ennemis prennent une bordure cyan). Toucher la **carte** d'un ennemi. (b) Reprendre une attaque, toucher la **barre de PV** d'un autre ennemi. (c) Reprendre une attaque, toucher la **languette au repos** d'un ennemi. (d) Prendre la carte de défense (cible soi), toucher la **languette au repos du héros**.
- **Attendu** : à chaque fois la carte **se joue sur la cible touchée**, et **aucune fiche ne s'ouvre**.
- **Ne doit pas changer** : le coût, les dégâts, la pioche ; l'élan de la carte vers sa cible.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T8 — Signature armée : toucher un ennemi la joue, sans fiche (M14)
- **Atteindre la situation** : un combat à au moins deux ennemis, une signature qui cible un ennemi (par exemple *Frappe Téméraire* du Berserker, ou *Châtiment* du Paladin), prête.
- **Faire** : armer la signature (toucher sa tuile) ; toucher la carte d'un ennemi. Armer de nouveau ; toucher la barre ; armer encore, toucher sa languette. Armer, puis passer la souris sur les ennemis. Fiche ouverte au préalable : armer la signature.
- **Attendu** : la signature se joue sur l'ennemi touché, **aucune fiche** ; le survol d'un ennemi pendant que la signature attend l'illumine comme avant ; armer une signature **ferme** une fiche ouverte.
- **Ne doit pas changer** : la recharge et les dégâts de la signature.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T9 — Glisser-déposer : lâcher une carte sur la carte, la barre ou la languette d'un ennemi (A3, A9)
*Le glisser cherche l'ennemi sous la carte lâchée ; la zone de l'ennemi comprend désormais sa barre et ses languettes.*
- **Atteindre la situation** : un combat à au moins deux ennemis, un porteur de charge (« +1 Feu » sur un ennemi), une carte d'attaque en main.
- **Faire** : saisir la carte et la lâcher (a) sur la **carte** d'un ennemi ; (b) sur sa **barre de PV** ; (c) sur sa **languette au repos** ; (d) entre deux ennemis ; (e) dans la zone d'annulation.
- **Attendu** : (a) à (c) la carte se joue sur cet ennemi ; (d) et (e) elle retourne en main sans rien jouer. **Aucune languette ne se déroule** pendant qu'on glisse une carte à la souris, et aucune fiche ne s'ouvre.
- **Ne doit pas changer** : la zone d'annulation ; le coût de la carte.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T10 — Les bordures : l'ambre d'un ennemi frappé, le cyan des cibles (T5-i, D14)
*La fiche ouverte a sa propre bordure ambre de 4, indépendante de la sélection.*
- **Atteindre la situation** : un combat à au moins deux ennemis, deux attaques en main.
- **Faire** : (a) jouer une attaque sur un ennemi ; regarder sa bordure. (b) Prendre la seconde attaque (carte focalisée) ; regarder la bordure de chaque ennemi. (c) La reposer. (d) Ouvrir la fiche d'un ennemi **qui n'est pas** celui frappé ; regarder les deux bordures ; fermer. (e) Ouvrir la fiche de l'ennemi frappé ; fermer.
- **Attendu** : (a) l'ennemi frappé garde une **bordure ambre de 4**. (b) l'ennemi frappé garde son ambre ; **les autres ennemis ont une bordure cyan de 3** sous leur halo, au lieu du blanc d'avant. (c) retour à l'état de (a). (d) la fiche a son ambre ; l'ennemi frappé garde le sien ; à la fermeture, **l'ambre de l'ennemi frappé reste**. (e) à la fermeture, il garde son ambre de dernière cible.
- **Ne doit pas changer** : le halo d'une charge (Gel, Feu, Foudre) ; la gangue de givre.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T11 — Le cadre se pose du bon côté, sans couvrir la languette (M15, T5-e)
- **Atteindre la situation** : cinq ennemis à 1280 × 800 (« Acte (sans regenerer la carte) » à 5 ; rejouer si moins de cinq), un porteur de charge à chaque extrémité pour qu'ils aient une languette.
- **Faire** : ouvrir la fiche de l'ennemi le plus à droite, puis le plus à gauche, puis celui du centre ; refaire avec un seul ennemi, et en rétrécissant la fenêtre.
- **Attendu** : le cadre se pose **à droite de la carte** s'il y tient, sinon à gauche, **sans jamais sortir de l'écran** ; à 24 de la languette au repos du côté où il se pose, **sans la recouvrir** (elle reste touchable) ; son haut à la hauteur du haut de la barre agrandie. La carte agrandie **garde sa barre à la même hauteur que celle de ses voisines** et grandit vers le bas. À cinq ennemis, la barre de l'ennemi de droite passe déjà sous les boutons Son et Deck, fiche ouverte ou non : la fiche ne la couvre pas davantage.
- **Ne doit pas changer** : la place des boutons du HUD ; l'alignement des cartes quand la fiche se ferme.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T12 — La fiche d'un ennemi gelé, d'un boss, d'un ennemi à bonus et altération (T5-e)
- **Atteindre la situation** : (a) onglet Combat, section « Charges », ligne de l'ennemi : **« +1 Gel » trois fois** (le seuil d'un ennemi qui n'est pas un boss est 3). (b) Un **boss** : le nœud boss de la carte du monde. (c) Un ennemi avec un bonus et une altération : l'**Orc Furieux** (acte 11 : fixer « Acte (sans regenerer la carte) » à 11 ; il pose sur lui sa Puissance quand il a l'intention « Buff Puissance ») avec une charge posée (« +1 Feu »), ou un ennemi qui a reçu *Sommation* (Faiblesse) et une charge.
- **Faire** : ouvrir la fiche de chacun.
- **Attendu** : (a) la section « INTENTION » dit **« Gelé : ne fait rien ce tour »** ; la pastille est grisée et barrée ; l'état « Gelé » se lit dans la section « ALTÉRATIONS ». (b) le boss, à × 1,25, grandit **vers le bas sans sortir de l'écran**, la barre à la même hauteur qu'au repos. (c) « BONUS » liste « ⚡ Puissance +2 » (sans durée : 99 tours n'affiche pas de durée), « ALTÉRATIONS » liste l'altération avec « · encore N tours » et, pour la Faiblesse, une ligne qui dit l'effet ; **le cadre ne couvre pas la languette** du côté où il se pose.
- **Ne doit pas changer** : l'intention de l'ennemi ; sa barre.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T13 — Une carte survolée déroule ses deux languettes (M8)
- **Atteindre la situation** : un combat, souris, un ennemi qui porte au moins une altération et si possible un bonus, dont une charge sous son seuil (onglet Combat : « +1 Gel » deux fois sur l'ennemi, « +1 Feu » une fois ; pour un bonus : l'Orc, acte 11). Aucune fiche.
- **Faire** : (a) lire les languettes au repos. (b) Survoler la carte de l'ennemi. (c) Faire glisser la souris de la carte sur la languette ouverte. (d) Sortir de la carte.
- **Attendu** : (a) à gauche les bonus, à droite les altérations et charges, **une icône (14) avec sa valeur dessous** : « 2/3 » pour le Gel, « 1 » pour le Feu ; une charge rompue sans chiffre montre le nom de son état (« Gelé ») ; une charge de Foudre chargée en jaune. (b) en **0,1 s** les deux languettes se déroulent ensemble, vers l'extérieur : l'icône, le **nom** et la valeur (« Puissance +2 », « Poison 2 », « Gel 2/3 »), la **durée** en jaune dessous quand il y en a une (« 3 tours »), pas de durée pour 99 tours ; **la languette déroulée passe par-dessus la carte voisine**. (c) elle **reste ouverte**. (d) elles se replient. En anglais : « Freeze 2/3 », « Frozen », « 3 turns ».
- **Ne doit pas changer** : le halo et la gangue ; les chiffres de la barre.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T14 — Cinq ennemis à 1280 × 800 : les languettes au repos tiennent entre deux cartes (M9)
- **Atteindre la situation** : cinq ennemis (acte 5) ; une charge posée sur chacun (« +1 Feu » sur chaque ligne) pour que chaque carte porte une languette de chaque côté (un « +1 Gel » donne une altération à droite ; pour avoir aussi un bonus à gauche, voir T13).
- **Faire** : regarder l'espace entre deux cartes voisines, au repos, sans rien survoler.
- **Attendu** : les deux languettes qui se font face (celle de droite de la carte de gauche, celle de gauche de la carte de droite) **tiennent entre les deux cartes sans se toucher** : environ 43 px chacune, 86 sur 93.
- **Ne doit pas changer** : l'alignement des cinq cartes et leur échelle (environ 98,7 %).
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T15 — Aux bords de l'écran, la languette se déroule vers l'intérieur (M20, T4-a, C-c)
- **Atteindre la situation** : cinq ennemis à 1280 × 800, l'ennemi le plus à droite et le plus à gauche portent chacun une altération et un bonus (T13).
- **Faire** : (a) survoler l'ennemi le plus à droite, puis le plus à gauche. (b) Survoler l'ennemi de droite, **souris immobile**, pendant qu'un voisin meurt (« 0 PV » sur sa ligne). (c) Souris immobile sur l'ennemi de droite, languette déroulée, pendant qu'un renfort entre ou que le plateau se décale. (d) Survoler le héros, au centre.
- **Attendu** : (a) leurs languettes **extérieures** se déroulent **vers l'intérieur, par-dessus leur propre carte**, sans sortir de l'écran ; les languettes intérieures se déroulent comme d'habitude. (b) le survol suit la carte replacée sans bouger la souris. (c) la languette se replace avec sa carte et, si elle sortait, se déroule vers l'intérieur ; **aucune languette ne reste déroulée hors de l'écran**. (d) le héros ne se retourne jamais.
- **Ne doit pas changer** : la zone d'appui de la languette (toucher là où elle était au repos agit encore sur sa carte). *À juger, point 6 ci-dessus* : une languette déroulée vers l'intérieur peut recouvrir l'autre languette de la même carte.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T16 — Un ennemi qui meurt sous la souris replie ses languettes (C-d)
- **Atteindre la situation** : deux ennemis au moins, souris immobile sur l'un d'eux, languettes déroulées ; puis le dernier ennemi du combat.
- **Faire** : tuer l'ennemi survolé (une carte jouée par glisser, ou en touchant l'ennemi avec une carte focalisée) ; refaire sur le dernier ennemi du combat.
- **Attendu** : ses languettes se replient **dès qu'il est mourant**, pendant qu'il s'efface, pour le dernier ennemi aussi ; aucune carte morte ne se déroule.
- **Ne doit pas changer** : l'effet de mort ; la victoire et les récompenses.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T17 — Les languettes du héros : 💎, 💖, deux Puissances, charges (M10)
*Le héros n'avait aucune languette. Son panneau des effets, lui, reste à côté d'elles, inchangé.*
- **Atteindre la situation** : une run debug, un combat. Pour 💎 : Mage sous *Canalisation*, *Méditation* ajoutée au deck (onglet Deck, sur la carte). Pour 💖 : Paladin sous *Bénédiction*, *Prière* ajoutée. Pour la Puissance : Berserker, *Fureur sanguine* et *Forme Démoniaque*. Pour les charges : onglet Combat, ligne « Heros : », « +1 Gel », « +1 Feu », « +1 Foudre ». Du mana.
- **Faire** : jouer la carte voulue ; survoler la carte du héros ; poser des charges sur lui ; le geler (**« +1 Gel » cinq fois**, le seuil du héros est 5).
- **Attendu** : à gauche les bonus : **💎** pour la régénération de mana, **💖** pour celle des PV, ⚡ pour la Puissance ; deux Puissances de sources différentes font deux entrées (recette non vérifiée : noter si on les voit) ; à droite les charges, le héros gelé montre « Gelé », avec sa phrase au déroulé (« −N % de dégâts au prochain tour »). Les compteurs de reliques et le compteur du passif portent leurs noms (« Compteur » / « Counter »). Les règles de déroulé sont celles de T13. **Le panneau des effets du héros est inchangé**, à côté. *À juger, point 5 ci-dessus* : la Puissance (vert, gauche) et la Foudre (rouge, droite) ont le même émoji.
- **Ne doit pas changer** : la jauge de PV du héros, son armure, son panneau des effets ; la Potion de Soin.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T18 — Au doigt : rien ne se déroule, et l'appui long (M11)
*Sans tactile, noter « non testé ».*
- **Atteindre la situation** : un écran tactile, un combat à plusieurs ennemis portant des statuts.
- **Faire** : (a) saisir une carte et la faire glisser au-dessus des ennemis. (b) Toucher un ennemi (sa fiche s'ouvre), toucher le décor. (c) Appui long sur une pastille du panneau des intentions. (d) Appui court sur une languette au repos.
- **Attendu** : (a) **aucune languette ne se déroule**, aucune carte n'est survolée. (b) la fiche s'ouvre, puis se ferme : au doigt, c'est le seul détail d'un ennemi. (c) l'infobulle de l'intention s'ouvre. (d) comme T2 : ouvre la fiche de la carte.
- **Ne doit pas changer** : le glisser-déposer d'une carte ; aucun survol au tactile.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T19 — La barre de PV à la largeur de la carte, sans badge (M4)
- **Atteindre la situation** : un combat, un ennemi à pleine vie, puis blessé (onglet Combat, champ PV de l'ennemi à un peu moins que son max, ou une attaque jouée) ; puis un boss.
- **Faire** : regarder le dessus de la carte, avant puis après avoir blessé l'ennemi.
- **Attendu** : **une seule barre, à la largeur de la carte**, rouge, avec les PV en **blanc** au centre : « 28/28 » puis « 23/28 » ; **plus aucun ⚡ ni 🛡** au-dessus de la carte, plus de petite barre de 66 ; sans armure, le seul « PV/PV max ». La barre du boss est la même, à l'échelle de sa carte. **Plus d'appui long** sur la barre : rien ne s'ouvre ; un appui court ouvre la fiche.
- **Ne doit pas changer** : la couleur et le dégradé des PV ; la barre du haut de l'écran ; la jauge du héros.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T20 — Le voile d'armure : plein, recule, se remplit, boss (M5, M6, M7)
*Le voile est la jauge de l'armure seule : plein au plus haut montant d'armure, il recule à chaque coup, disparaît à zéro ; de l'armure regagnée le remplit de nouveau. 6 couvrent la barre d'un petit ennemi comme 40 celle d'un boss.*
- **Atteindre la situation** : **non atteignable en jeu**. Aucun ennemi n'a aujourd'hui d'intention de Défense (Slime, Gobelin, Squelette : attaques seules ; Orc : attaques et Buff Puissance), et le menu de debug ne donne d'armure qu'au héros. Rien à jouer ici. À noter « non testé », ou à reprendre quand un ennemi de Défense existera.
- **Faire** : (si la situation existe) regarder la barre d'un ennemi qui vient de gagner 6 d'armure ; le frapper deux fois ; l'amener à 0 ; lui faire regagner de l'armure ; un boss qui gagne 40.
- **Attendu** : voile bleu plein sur **toute la largeur de la barre**, le bouclier bleu et « 6 » en cyan à côté des PV ; il recule à chaque coup (un ennemi à 2 sur 6 : un tiers) ; il disparaît à 0 ; l'armure regagnée le remplit de nouveau, le nouveau montant pour plein ; un boss à 40 : barre couverte, comme 6 sur un petit ennemi. *À juger, point 4 ci-dessus* : le chiffre d'armure cyan se lit mal sur le rouge de la barre quand le voile a reculé.
- **Ne doit pas changer** : l'armure du héros et sa jauge.
- **Résultat** : non testé — non atteignable en jeu (aucun ennemi ne gagne d'armure en `0.6.1`, le menu de debug n'en donne qu'au héros) ; à reprendre à la vague qui donnera de l'armure à un ennemi

## T21 — Le panneau des intentions en trois colonnes (M1)
- **Atteindre la situation** : un combat à trois ennemis ou plus (acte 3), dont un nom long si possible (« Orc Furieux », acte 11, ou « Squelette »). En français, puis en anglais.
- **Faire** : lire le panneau « 👁 INTENTIONS ENNEMIES », en bas à droite ; refaire avec cinq ennemis (le panneau défile).
- **Attendu** : une ligne par ennemi, **trois colonnes alignées** : « **Niv. N** » (gris, jamais tronqué) / « **Lvl. N** », le **nom** (blanc gras ; ambre pour un boss ; **seul à se tronquer**, par des points de suspension), la **pastille** de l'intention (icône et valeur). **Plus aucun PV dans le panneau.** Un ennemi sans intention connue : un sablier et « En attente... » en italique (« Waiting... »), réduit s'il est large, jamais tronqué.
- **Ne doit pas changer** : la largeur du panneau, son cadre, son titre ; le bouton « Fin de Tour » reste entièrement visible et cliquable ; le panneau des effets du héros.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T22 — Une infobulle par ligne, les couleurs des pastilles (M2)
- **Atteindre la situation** : un combat à plusieurs ennemis : des attaques (Slime, Gobelin, Squelette), et si possible un Buff (Orc, acte 11).
- **Faire** : survoler la pastille d'une attaque, puis celle d'une Défense si on en trouve une (T20 : il n'y en a pas), puis celle d'un Buff ; survoler le nom d'un ennemi ; refaire en anglais.
- **Attendu** : **une seule infobulle par ligne**, quelle que soit la partie survolée de la rangée de pastilles. Titre : le libellé de l'intention avec sa valeur (« Attaque Rapide : 5 ») ; dessous, sa phrase (« À son tour, … attaquera le héros pour 5 dégâts. »). **La pastille survolée est cerclée** de la couleur de l'infobulle. Couleurs des attaques : éclair ambre pour une petite attaque (valeur sous 6) puis des paliers à 6, 12 et 20 ; Buff : **flèche montante violette** (et non un éclair orange, pour ne pas confondre avec une petite attaque) ; Défense : bouclier bleu. En anglais, le libellé et la phrase passent en anglais (« Quick Attack: 5 »).
- **Ne doit pas changer** : le texte des phrases des intentions ; l'infobulle apparaît aussi à l'appui long au doigt.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T23 — L'ennemi gelé dans le panneau (M3)
- **Atteindre la situation** : un ennemi qui n'est pas un boss et qui n'a encore jamais été gelé : onglet Combat, section « Charges », sa ligne, **« +1 Gel » trois fois**.
- **Faire** : lire sa ligne dans le panneau ; survoler sa pastille.
- **Attendu** : sa pastille est **grisée et barrée**, sa valeur barrée ; **plus de ligne « Gelé : ne fait rien ce tour »** sous elle ; l'infobulle a une **bordure bleu clair**, un titre barré, et sa phrase « Gelé : ne fait rien ce tour » en **bleu clair gras**. Sa carte porte la gangue de givre, et sa fiche (T12) le dit.
- **Ne doit pas changer** : à la fin du tour, l'ennemi gelé ne fait rien, comme avant la branche.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T24 — Le tutoriel : les étapes « Vue d'ensemble » et « Intentions » (M18)
- **Atteindre la situation** : accueil « TUTORIEL » ; en français, puis en anglais.
- **Faire** : aller jusqu'à l'étape « Vue d'ensemble » (maquette du combat), puis à l'étape « Les Intentions Ennemies » ; aller jusqu'au bout.
- **Attendu** : à la « Vue d'ensemble », **la maquette de l'ennemi n'a plus de rangée Puissance/armure** : une barre à la largeur de la carte, « 28/28 » dedans ; **la maquette du panneau** est une ligne « Niv. 1 · Gobelin · [⚡ 5] » (plus de « Gobelin (Niv. 1) » ni d'« Attaque Rapide : 5 »). À l'étape des intentions, **le vrai panneau en trois colonnes** : ses quatre ennemis d'entraînement y lisent « Niv. 1 » et leur pastille ; la légende des paliers reste ; **la phrase neuve** : « **Touchez un ennemi** pour ouvrir sa fiche : ses PV, son Armure, sa Puissance, son intention, ses bonus et ses altérations. À la souris, survoler sa carte déroule ses deux languettes. » (anglais : « **Tap an enemy** to open its sheet… »). Rien ne casse jusqu'au bout.
- **Ne doit pas changer** : les étapes et leur ordre ; l'étape « Armure & Dégâts » (jauge du héros) ; l'étape « Effets Élémentaires ». Le tutoriel n'a pas de combat réel : ni languette, ni fiche à démontrer.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## T25 — Un combat fini à la phase ennemie ne rouvre aucun tour (M19, S9)
*Avant la correction, un tour joueur complet s'ouvrait sur un combat fini : après une victoire, le héros subissait ses statuts (un soin de trop, un Poison qui pouvait le tuer) ; après sa mort, un soin de début de tour pouvait le ranimer.*
- **Atteindre la situation** : (a) « RUN DEBUG », un combat à **un ennemi** ; onglet Combat : **PV de l'ennemi à 1**, « +1 Feu » sur sa ligne (le Feu inflige ses dégâts au début de la phase de son porteur) ; avec le Mage, *Coup Empoisonné* en main fait l'équivalent par le Poison. (b) Paladin sous *Bénédiction*, *Prière* jouée (Source de Vie), **PV du héros à 1**, aucune Armure ; un ennemi dont l'intention est une attaque.
- **Faire** : (a) « Fin de Tour » ; regarder ce qui suit. (b) « Fin de Tour » ; regarder ce qui suit.
- **Attendu** : (a) l'ennemi meurt de son Feu pendant la phase ennemie ; **la victoire s'affiche** (récompenses) ; **aucun tour joueur ne se rouvre** (pas de nouvelle main, pas de mana rendu, pas de soin de statut en trop pour le héros). (b) le héros meurt de l'attaque : l'écran de mort s'affiche, **les PV ne remontent pas** (la Source de Vie ne le ranime pas), aucun tour ne se rouvre.
- **Ne doit pas changer** : l'XP, l'or et les récompenses d'une victoire ; l'écran de mort et ses boutons.
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## Ce qui doit rester inchangé
- **Ce que font les ennemis** : mêmes intentions, mêmes valeurs, même ordre de la phase ennemie (actions dans l'ordre de la rangée, bond de 200 ms), mêmes dégâts, aucune règle de combat changée.
- **La jauge du héros et son panneau des effets** : leur forme, leurs couleurs, leurs valeurs ; le panneau reste à côté des languettes du héros.
- **Le jeu d'une carte** : le clic (carte, puis cible), le glisser-déposer, la zone d'annulation, la prise d'une carte focalisée, la signature armée, leur son.
- **Les charges élémentaires** : Gel, Feu et Foudre se posent, rompent et déclinent comme avant ; le halo, la gangue de givre, les dégâts jaunes du Feu et de la Foudre.
- **Le menu de debug** : mêmes onglets, mêmes champs, mêmes boutons.
- **Les mesures** : une carte d'ennemi de 100 × 140 unités, l'échelle d'un boss (× 1,25), l'alignement des ennemis (98,7 % à cinq).
- **La victoire et la défaite** : les récompenses, l'XP, l'or, l'écran de mort.
- **La sauvegarde** : rien de neuf n'est écrit ; aucune sauvegarde en combat ; la run debug ne sauve rien.
- **Le reste du HUD** : la barre du haut (Son, Deck), « Fin de Tour », le compteur de tour, le panneau des intentions (sa largeur, son titre, son défilement).
- **Les autres écrans** : carte du monde, boutique, événements, dictionnaire, forge.

## C1 — Chaque entrée de la fiche dit ce qu'elle fait (défaut 1)
*Correction de fin de vague : seules la Faiblesse et le Vulnérable avaient une ligne d'aide ; « Gel 2/3 » ne disait pas ce qui arrive au seuil.*
- **Atteindre la situation** : « RUN DEBUG », un combat ; onglet Combat, section « Charges », sur la ligne de l'ennemi : « +1 Gel » deux fois, « +1 Feu », « +1 Foudre ». Pour une altération : *Coup Empoisonné* (Mage) ou *Sommation* (Paladin). Pour un bonus : l'Orc Furieux (acte 11).
- **Faire** : ouvrir la fiche de l'ennemi ; lire la ligne grise sous chaque entrée. Geler l'ennemi (« +1 Gel » une fois de plus) et relire. Refaire en anglais.
- **Attendu** : **chaque entrée a sa ligne grise, d'une phrase courte.** Gel : « Au seuil, gèle : perd sa prochaine action. » — la même sous « Gelé ». Feu : « Brûle à son tour ; chaque tranche de 3 explose sur ses voisins. » Foudre : « Les coups reçus font +1 par point, +2 au seuil. » Poison N : « Subit N dégâts au début de son tour ». Puissance +N (bonus) : « +N aux dégâts de ses attaques ». Faiblesse et Vulnérable : inchangés. La règle complète des charges reste aux infobulles des cartes. En anglais : « At the threshold, freezes: loses its next action. », « Takes N damage at the start of its turn », « +N damage on its attacks ».
- **Ne doit pas changer** : les titres des entrées, leurs couleurs, les tours restants ; les languettes (elles n'écrivent pas cette ligne).
- **Résultat** : ✅ validé par le propriétaire le 22/11/2026

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
| 1 | T12 | Dans la fiche, le Gel (« Gel 2/3 ») ne dit pas ce qui arrive au seuil ; seules la Faiblesse et le Vulnérable avaient une ligne d'aide | À corriger | C1 — chaque statut a sa phrase, chaque charge une phrase courte (`summary_fr` / `summary_en` de son fichier) |
