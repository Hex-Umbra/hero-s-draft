# Vague 5 — `0.5.7` — tests manuels

**Branche** : `feat/v0.5.7-p42-tranche-1-p44-lot-1` · **Compte rendu** : [2026-11-03-economie-et-catalogue-vague-5-compte-rendu.md](2026-11-03-economie-et-catalogue-vague-5-compte-rendu.md)
**Testé le** : non rempli
**Résultat** : 0 ✅ · 0 ❌ · 38 non testés

**Repères communs.** M1 à M34 reprennent la table des tests manuels de la spec (§9.1), dans son ordre et sous ses numéros ; M35 à M38 sont neufs (le parcours de bout en bout, et des points renvoyés au test par les revues, §2 et §3 du compte rendu) ; M39 s'y ajoute le 06/11 (les signatures dans « Mon Deck », demandées par le propriétaire). Les points des revues qui recoupaient un M y ont été fondus (M1, M2, M4, M5, M16, M32).

**Deux sortes de run.** « JOUER » lance une run normale, sauvegardée. « RUN DEBUG » (colonne DEBUG de l'accueil, build debug seulement) lance une run de test **qui ne sauvegarde jamais rien** : une reprise ne se teste que dans une run normale. Seule la run debug a le tiroir violet « DEBUG » au bord gauche. **En combat, un seul onglet, « Combat »** (« PV », « Mana », « Armure », « Soin complet », « Mana plein », les PV de chaque ennemi / « 0 PV », « Tous les ennemis a 0 PV », « Gagner le combat », « Perdre le combat », « Sauter la phase ennemie »). **Hors combat (carte du monde) : « Heros », « Run », « Deck », « Reliques ».** Un champ chiffré se valide en tapant la valeur puis Entrée. « Heros » porte « Puissance », « Niveau (stat brute) », « Gagner un niveau (ouvre le draft) » et, tout en bas, la section **« Évolutions de signature »** : pour chaque signature, son nom, la liste de ce qui est pris (« aucune », ou les identifiants et niveaux, ex. « zeal:2, sentence:1 »), un bouton par évolution que le prochain palier admet, **au nom français** (« Zèle »…), puis « Retirer les évolutions ». « Run » porte « Drafts en attente » ; « Deck » > « Ajouter une carte ». Les évolutions ne se posent donc que sur la carte du monde : entre deux poses qu'un combat doit montrer, finir le combat par « Gagner le combat », passer les récompenses, revenir à la carte.

**Les paliers.** Les évolutions d'une signature alternent : la 1re est mineure, la 2e majeure, la 3e mineure, etc. (le compte est la somme des niveaux) ; une mineure reprise monte d'un niveau à sa place, une majeure ne se prend qu'une fois. Quand il reste moins de trois majeures éligibles, le palier majeur admet aussi les mineures. Le héros attend une évolution par signature à chaque tranche de 5 niveaux (5, 10, 15…). À égalité, l'ordre est celui de la fiche de la classe : **Paladin, Bouclier Sacré puis Châtiment** — c'est aussi l'ordre de la barre en combat, **Bouclier Sacré en haut, Châtiment en bas** (Mage : Projectile Magique puis Surtension de Mana ; Berserker : Frappe Téméraire puis Posture de Rage). Le héros commence au niveau 1 ; à l'acte 1, chaque niveau coûte 115 XP (panneau en bas à droite de la carte : « Niv. N », « XP: x/115 »).

**La langue suit celle de Windows** : le jeu n'a pas de réglage. Pour l'anglais, passer la langue d'affichage de Windows en anglais et relancer ; sinon, noter « anglais non testé » dans le résultat. **La largeur** : sous 600 px de large, les tuiles de signature sont étroites (170 px), au-delà larges (220 px). **Un seul passif est proposé par classe** en `0.5.7`, celui qui a un lot : Paladin *Régénération d'Armure*, Berserker *Rage*, Mage *Flux de Mana*. Partir de Puissance 0 pour comparer des chiffres.

Les cartes utiles, d'après les données livrées :

| Carte | Lot (classe) | Coût | Effet |
|:---|:---|:---|:---|
| Pacte de sang | Rage (Berserker) | 1 Mana + 3 PV | Pioche 2 cartes |
| Sang versé | Rage | 0 Mana + 4 PV | 8 dégâts |
| Fureur sanguine | Rage | 1 | 1 Puissance ce tour, +1 par tranche de 10 PV manquants |
| Dernier souffle | Rage | 2 | 4 dégâts, +1 par tranche de 5 PV manquants |
| Forme Démoniaque | Rage | 2 | 2 Puissance pendant 4 tours |
| Transe | Rage | 2 | Pendant 3 tours, 1 Puissance au début du tour |
| Percée | Régénération d'Armure (Paladin) | 0 Mana + 4 Armure | 10 dégâts |
| Éclat de bouclier | Régénération d'Armure | 1 Mana + 6 Armure | 8 dégâts à tous les ennemis |
| Fortification | Régénération d'Armure | 1 | 6 Armure, +1 par tranche de 5 d'Armure |
| Rempart brisé | Régénération d'Armure | 1 | 2 dégâts, +1 par point d'Armure |
| Rafale d'étincelles | Flux de Mana (Mage) | 2 | 1 Électrocution, puis 3 dégâts 3 fois |
| Décharge | Flux de Mana | 3 | 12 dégâts, 2 Vulnérable pendant 2 tours |
| Nova de givre | Flux de Mana | 2 | 2 Gel à tous les ennemis |
| Trait de Glace | neutre | 1 | 4 dégâts, 2 Gel |
| Coup de Tonnerre | neutre | 1 | 4 dégâts, 1 Électrocution |
| Métallisation | neutre | 1 | Pendant 2 tours, 2 Armure au début du tour |

Les évolutions des signatures testées. « Chiffrée » change un chiffre de la tuile ; « verbale » ajoute une icône à sa bande.

| Signature | Bouton | Dans la liste | Palier | Effet | Sorte | Icône |
|:---|:---|:---|:---|:---|:---|:---|
| Châtiment (6 dégâts, 4 Armure) | Zèle | zeal | mineure | +2 dégâts par niveau | chiffrée | marteau rouge |
| | Égide | aegis | mineure | +2 Armure par niveau | chiffrée | écu bleu |
| | Ardeur | ardor | mineure | +5 % de critique par niveau | verbale | éclat ambre |
| | Célérité | haste | majeure | recharge réduite d'un tour | chiffrée | avance rapide sarcelle |
| | Sentence | sentence | majeure | 1 Faiblesse pendant 2 tours | verbale | courbe descendante violette |
| | Rayonnement | radiance | majeure | touche tous les ennemis | verbale | rayons violet foncé |
| | Dévotion | devotion | majeure | coûte 1 Mana de moins | chiffrée | tirelire cyan |
| Bouclier Sacré (8 Armure, soigne 2) | Garde | ward | mineure | +2 Armure par niveau | chiffrée | écu bleu |
| | Miséricorde | mercy | mineure | +1 PV soigné par niveau | chiffrée | cœur rose |
| | Résolution | resolve | mineure | gagne 1 Puissance (ce tour-ci) | verbale | éclair orange |
| | Célérité | haste | majeure | recharge réduite d'un tour | chiffrée | avance rapide sarcelle |
| | Consécration | consecration | majeure | 2 Puissance pendant 2 tours | verbale | éclair orange |
| | Inspiration | inspiration | majeure | pioche 1 carte | verbale | cartes ambre |
| | Égide durable | lasting_aegis | majeure | pendant 2 tours, 3 Armure au début du tour | verbale | flèches en cercle bleues |
| Surtension de Mana (1 Mana, pioche 1) | Bouclier de mana | mana_shield | mineure | 2 Armure | verbale | écu bleu |
| | Harmonie | attunement | mineure | 1 Puissance | verbale | éclair orange |
| | Clarté | clarity | mineure | soigne 1 PV | verbale | cœur rose |
| | Prescience | foresight | majeure | pioche 1 carte de plus | chiffrée | cartes ambre |
| | Glyphe de garde | glyph | majeure | pendant 2 tours, 3 Armure au début du tour | verbale | flèches en cercle bleues |
| | Exaltation | empower | majeure | 2 Puissance pendant 2 tours | verbale | éclair orange |
| | Sérénité | serenity | majeure | soigne 4 PV | verbale | cœur rose |
| Frappe Téméraire (15 dégâts) | Brutalité | brutality | mineure | +3 dégâts par niveau | chiffrée | marteau rouge |
| | Instinct | instinct | mineure | +5 % de critique | verbale | éclat ambre |
| | Fracas | shatter | mineure | 1 Vulnérable | verbale | viseur orange foncé |
| | Célérité | haste | majeure | recharge réduite d'un tour ; exclut Dévastation | chiffrée | avance rapide sarcelle |
| | Dévastation | devastation | majeure | +10 dégâts, recharge allongée d'un tour ; exclut Célérité | chiffrée | fusée jaune |
| | Fauchage | cleave | majeure | touche tous les ennemis | verbale | rayons violet foncé |
| | Sang-froid | composure | majeure | coûte 1 Mana de moins | chiffrée | tirelire cyan |

## À tester d'abord
<!-- du plus risqué au moins risqué -->
1. **M35** — Le parcours de bout en bout : une run normale du Paladin jusqu'au niveau 5, le draft, les deux évolutions, la tuile évoluée, puis la reprise.
2. **M39** — Les signatures en tête de « Mon Deck » : fiche évoluée, prochaine évolution, défilement.
3. **M10** — Le rideau au niveau 5 : le draft d'abord, puis *Bouclier Sacré*, puis *Châtiment*, puis les nœuds s'ouvrent.
4. **M2** — Les médaillons de PV et d'Armure, et le rouge d'une ressource qui manque.
5. **M24** — *Dévotion* jouable à 0 Mana ; *Rayonnement* joue sans demander de cible.
6. **M29** — L'appui court joue, arme, désarme comme en `0.5.6` ; l'appui long ne fait rien de tout cela.
7. **M34** — L'entrée de debug des évolutions (les autres points s'en servent).
8. **M4** — Le draft de départ à deux quotas.
9. **M9** — Le rideau sans draft : les nœuds restent éteints, aucun voyage possible.
10. **M17** — L'évolution choisie se voit sur la tuile au combat suivant.
11. **M25** — La liste de l'appui long : son contenu, et la colonne qui ne bouge pas.
12. **M26** — Relâcher replie la liste, glisser ne la replie pas.
13. **M31** — La barre sur une fenêtre basse : réduite, et la tuile réduite s'arme.
14. **M27** — La liste qui s'ouvre vers le haut sur une fenêtre basse.
15. **M28** — La liste dans les quatre états.
16. **M12** — Les en-têtes de l'écran d'évolution.
17. **M13** — Trois mineures au premier choix.
18. **M14** — Trois majeures au deuxième.
19. **M15** — Une mineure reprise : « +4 dégâts » et « Niveau 1 → 2 ».
20. **M16** — L'icône du rouleau arrêté ; une majeure assez distincte d'une mineure.
21. **M3** — Multi-coups (« 3×3 ») et croissance.
22. **M1** — Les parenthèses des statuts proportionnels.
23. **M20** — La bande d'icônes à la place de la description.
24. **M19** — Les puces d'évolution.
25. **M18** — Le badge « Niv. ».
26. **M22** — Les évolutions chiffrées et la ligne qui se réduit d'un bloc.
27. **M21** — Huit icônes sur Surtension de Mana.
28. **M23** — Le gris des tuiles en recharge et sans le mana.
29. **M30** — La barre à mi-hauteur à 1280 × 800.
30. **M32** — Les icônes du panneau des statuts, le bleu de l'Armure en début de tour, les éclairs.
31. **M33** — Métallisation et Vol de vie (non atteignables en `0.5.7`).
32. **M5** — Le tutoriel, étape des éléments : le barème, et le texte du Gel sur petit écran.
33. **M6** — Le tutoriel : le Mage sur Flux de Mana, le draft à deux sections.
34. **M7** — Le tutoriel : Poison et Brûlure aux icônes des cartes.
35. **M38** — Les deux phrases réécrites du tutoriel.
36. **M8** — La tuile de signature hors combat : description remplie, sans badge.
37. **M11** — Les rouleaux du draft de niveau : rien ne change.
38. **M36** — Le chevron « Passifs » à un seul passif.
39. **M37** — La barre de l'éditeur de contenu sur deux lignes.

## M1 — Infobulles : le barème des statuts proportionnels
- **Atteindre la situation** : hors combat, accueil « DICTIONNAIRE », onglet « Cartes ». En combat : *Trait de Glace* en main (run Paladin ou debug, « Deck » > « Ajouter une carte » sur la carte du monde) ; *Décharge* et *Nova de givre* dans une run Mage (draft de départ ou « Ajouter une carte »).
- **Faire** : survoler (ou appui long) *Trait de Glace*, *Nova de givre* puis *Décharge* au dictionnaire ; puis survoler les mêmes cartes dans la main, en combat. En français puis en anglais.
- **Attendu** : sous la ligne du statut, une parenthèse qui dit le barème par point. Gel : « (−25 % à la prochaine attaque par point, jusqu'à −75 %) » ; Vulnérable : « (+25 % de dégâts subis par point, jusqu'à +100 %) ». En anglais : « −25% to the next attack per point, down to −75% », « +25% damage taken per point, up to +100% ». Plus aucun pourcentage fixe (« 50% », « 25% »). **En combat, la parenthèse est bien là** : ni ligne absente, ni ligne vide (point des revues : la ligne de l'infobulle de combat écrite sans texte). Aucune carte livrée ne pose Faiblesse (seule l'évolution *Sentence* le fait, et une tuile n'a pas d'infobulle) : sa parenthèse, « −25 % de dégâts infligés par point, jusqu'à −50 % », ne se lit qu'au tutoriel (M5).
- **Ne doit pas changer** : les parenthèses du Poison, de la Brûlure et de l'Électrocution ; le reste de l'infobulle (cible, rareté, type, coût).
- **Résultat** : ✅ · ❌ · non testé —

## M2 — Les médaillons de PV et d'Armure
- **Atteindre la situation** : dictionnaire, *Pacte de sang*, *Sang versé*, *Percée*, *Éclat de bouclier*. En combat : run Paladin avec *Percée* et *Éclat de bouclier* en main ; run Berserker avec *Pacte de sang* et *Sang versé* en main (draft de départ, ou « Ajouter une carte »).
- **Faire** : regarder les cartes au dictionnaire, puis dans la main en début de tour (Armure 0). Onglet Combat : « Armure » à 3, puis à 4 ; « PV » à 3, puis à 4 ; « Mana » à 0. Jouer *Percée* à 4 d'Armure. Pour le point des revues : si une carte qui porte des runes (posées à la forge) a aussi un coût en PV ou en Armure, la regarder en main.
- **Attendu** : sous le médaillon de mana (en haut à gauche), un médaillon de plus : une goutte rouge et son chiffre (PV), un écu gris-bleu et son chiffre (Armure). Au dictionnaire, jamais de rouge. En combat, le médaillon d'une ressource qui manque passe au rouge vif sur fond rouge sombre : *Percée* à 0-3 d'Armure, rouge ; à 4, normal (l'Armure égale au coût suffit) ; *Pacte de sang* à 3 PV, rouge (les PV égaux au coût ne suffisent pas) ; à 4 PV, normal ; le mana aussi, s'il manque. Une carte au médaillon rouge ne se joue pas (refus habituel). *Percée* jouée à 4 d'Armure : Armure 0, 10 dégâts, Mana inchangé. Le second médaillon ne chevauche ni le nom, ni les emplacements de runes. Le troisième médaillon, plus bas (une carte qui coûterait des PV **et** de l'Armure), n'est porté par aucune carte livrée : non testable tel quel.
- **Ne doit pas changer** : le médaillon de mana des cartes qui ne coûtent que du mana ; le mana débité au jeu.
- **Résultat** : ✅ · ❌ · non testé —

## M3 — Multi-coups et croissance
- **Atteindre la situation** : dictionnaire : *Rafale d'étincelles*, *Fortification*, *Rempart brisé*, *Dernier souffle*, *Fureur sanguine*, *Pacte de sang*. Puis en combat, Puissance 0 : Mage avec *Rafale d'étincelles* ; Paladin avec *Fortification* et *Rempart brisé* ; Berserker avec *Dernier souffle*.
- **Faire** : regarder le badge de chaque carte, ouvrir son infobulle au dictionnaire puis en main. En combat, onglet Combat : « Armure » à 10 (Paladin) ; « PV » à 50 PV de moins que le maximum (Berserker).
- **Attendu** : *Rafale d'étincelles* : badge « 3×3 », infobulle « Inflige 3 dégâts 3 fois. ». Les lignes de croissance, en parenthèse sous l'effet : *Fortification* « (+1 par tranche de 5 d'Armure) », *Rempart brisé* « (+1 par point d'Armure) », *Dernier souffle* « (+1 par tranche de 5 PV manquants) », *Fureur sanguine* « (+1 par tranche de 10 PV manquants) ». *Pacte de sang* : sous « Coût : 1 Mana », la ligne « Coûte 3 PV ». Hors combat, la valeur de base (2, 6, 4) ; en combat, la valeur suit le héros, badge et infobulle d'accord : à 10 d'Armure, *Rempart brisé* 12, *Fortification* 8 ; à 50 PV manquants, *Dernier souffle* 14. En combat, ces lignes sont toutes écrites (aucune vide).
- **Ne doit pas changer** : les cartes sans coups ni croissance ; le badge des autres cartes.
- **Résultat** : ✅ · ❌ · non testé —

## M4 — Le draft de départ à deux quotas
- **Atteindre la situation** : « JOUER » (ou « RUN DEBUG »), Paladin, passif *Régénération d'Armure*, jusqu'au draft du deck de départ. Puis une fenêtre de moins de 600 px de large (largeur de téléphone).
- **Faire** : prendre 2 cartes du lot, essayer une 3e ; prendre 3 neutres, essayer une 4e ; désélectionner une carte ; regarder le bouton à chaque étape. Recommencer avec le Berserker et le Mage pour les titres.
- **Attendu** : sous-titre « Choisissez 2 cartes de votre passif et 3 cartes neutres pour constituer votre deck de départ. » Deux sections : « Cartes de Régénération d'Armure » (les six cartes du lot) avec « 0/2 », puis « Cartes neutres » avec « 0/3 » ; un compteur plein passe au vert, et les cartes de son groupe se grisent. Une 3e carte du lot est refusée avec « Vous avez déjà choisi vos 2 cartes de passif. », une 4e neutre avec « Vous avez déjà choisi vos 3 cartes neutres. » ; « Cartes sélectionnées : n / 5 » suit le total. Le bouton « ENTRER DANS L'UMBRA » (la spec le nomme « Valider ») ne s'active qu'à 2 + 3. Berserker : « Cartes de Rage » ; Mage : « Cartes de Flux de Mana ». Sous 600 px : le titre long « Cartes de Régénération d'Armure » tient, centré, sans déborder ni couper son compteur ; la grille resserre ses cartes, sans chevauchement.
- **Ne doit pas changer** : désélectionner une carte rend sa place ; le retour arrière ; l'arrivée sur la carte du monde avec un deck de 5 cartes.
- **Résultat** : ✅ · ❌ · non testé —

## M5 — Le tutoriel, étape « Les Effets Élémentaires »
- **Atteindre la situation** : accueil « TUTORIEL », avancer jusqu'à « Les Effets Élémentaires ». En français puis en anglais ; puis une fenêtre étroite (moins de 600 px) et basse.
- **Faire** : lire le texte de l'étape, la galerie, puis le tableau « Cinq autres altérations circulent en combat : ».
- **Attendu** : le texte dit « ❄️ Gel : réduit leur prochaine attaque, d'autant plus qu'il compte de points, jusqu'à un plafond. » Dans la galerie, la carte du Gel : « −25 % à la prochaine attaque par point, jusqu'à −75 % ». Au tableau : Vulnérable « +25 % de dégâts subis par point, jusqu'à +100 % », Faiblesse « −25 % de dégâts infligés par point, jusqu'à −50 % » — les mêmes chiffres que les infobulles (M1). L'étape « Les Intentions Ennemies » dit que le chiffre « baisse tant qu'il est Gelé » (plus « se divise par deux »). Sur la fenêtre étroite, le texte du Gel tient dans sa carte de galerie, ni coupé ni en débordement (point des revues).
- **Ne doit pas changer** : le Poison, la Brûlure, l'Électrocution et l'animation de la galerie.
- **Résultat** : ✅ · ❌ · non testé —

## M6 — Le tutoriel : le Mage et le draft de départ
- **Atteindre la situation** : « TUTORIEL », étape « Choisissez votre classe ».
- **Faire** : choisir le Mage, continuer jusqu'à « Votre deck de départ », prendre des cartes, remplir un groupe.
- **Attendu** : la carte du Mage s'ouvre sur *Flux de Mana* (le seul passif proposé). L'étape du deck dit « Choisissez 2 cartes du lot de votre passif et 3 cartes neutres : … ». Deux sections, « Cartes de Flux de Mana » avec « 0/2 » et « Cartes neutres » avec « 0/3 », compteur vert quand il est plein ; les cartes d'un groupe plein se grisent, comme au jeu (M4). Le bandeau du bas : « Vos signatures, toujours disponibles en combat : Projectile Magique, Surtension de Mana ».
- **Ne doit pas changer** : la suite du tutoriel (étapes, ordre, combats guidés).
- **Résultat** : ✅ · ❌ · non testé —

## M7 — Le tutoriel : le panneau des statuts
- **Atteindre la situation** : « TUTORIEL », étape « Les Effets Élémentaires », bas de l'étape (« Voilà comment ils apparaissent en combat : »).
- **Faire** : regarder le panneau.
- **Attendu** : « Poison : 3 » avec la fiole verte, « Brûlure : 2 » avec la flamme orange — les icônes des faces de *Coup Empoisonné* et de *Boule de Feu* (avant : une tête malade, une flamme orange foncé).
- **Ne doit pas changer** : les libellés et les valeurs du panneau ; le tableau au-dessus.
- **Résultat** : ✅ · ❌ · non testé —

## M8 — La tuile de signature hors combat
- **Atteindre la situation** : nouvelle partie, écran de sélection de classe ; puis accueil « DICTIONNAIRE », onglet « Signatures ».
- **Faire** : déplier la carte du Paladin et lire ses deux signatures ; au dictionnaire, chercher *Châtiment*, puis les six signatures.
- **Attendu** : la description complète, chiffres remplis : *Châtiment* « Inflige 6 dégâts et donne 4 d'Armure. », *Bouclier Sacré* « Donne 8 d'Armure et soigne 2 PV. » ; jamais d'accolade `{…}`. Ni badge « Niv. », ni puce, ni bande d'icônes. Les trois signatures qui piochent disent « carte(s) » : *Projectile Magique* « Inflige 5 dégâts et pioche 1 carte(s). », *Surtension de Mana* « Gagne 1 Mana et pioche 1 carte(s). », *Posture de Rage* « Applique 2 Puissance ce tour-ci. Pioche 1 carte(s). ».
- **Ne doit pas changer** : le reste de la carte de classe (stats, passif, choix) ; les onglets « Cartes » et « Reliques ».
- **Résultat** : ✅ · ❌ · non testé —

## M9 — Le rideau, sans draft en attente
- **Atteindre la situation** : « RUN DEBUG », Paladin, carte du monde. Onglet « Run » : « Drafts en attente » à 0. Onglet « Heros » : « Niveau (stat brute) » à 5.
- **Faire** : fermer le tiroir ; regarder le rideau apparaître ; essayer de toucher un nœud à travers lui.
- **Attendu** : le rideau « 🎉 LEVEL UP ! 🎉 », « Votre héros a gagné en puissance ! », « TOUCHEZ POUR OBTENIR VOS RÉCOMPENSES » s'affiche ; pendant son fondu, les nœuds restent éteints derrière le voile, sans s'éclaircir. Toucher n'importe où, nœud compris, ouvre l'évolution de *Bouclier Sacré* ; aucun voyage ne part.
- **Ne doit pas changer** : le rideau d'un simple draft de niveau ; la carte une fois le choix fait.
- **Résultat** : ✅ · ❌ · non testé —

## M10 — Le rideau au niveau 5 : le draft, puis les deux évolutions
- **Atteindre la situation** : « RUN DEBUG », Paladin, carte du monde. Onglet « Heros » : « Niveau (stat brute) » à 4, puis « Gagner un niveau (ouvre le draft) » (notification « Niveau 5 — draft en attente sur la carte »).
- **Faire** : fermer le tiroir ; toucher le rideau, finir le draft ; toucher le rideau, choisir ; toucher le rideau, choisir.
- **Attendu** : d'abord le draft de niveau ; au retour, le rideau toujours là ouvre « Évolution de Bouclier Sacré » ; puis « Évolution de Châtiment » (l'ordre de la fiche du Paladin) ; après ce dernier choix, le rideau disparaît, les nœuds accessibles s'éclairent et se touchent.
- **Ne doit pas changer** : le draft de niveau lui-même ; la position sur la carte.
- **Résultat** : ✅ · ❌ · non testé —

## M11 — Les rouleaux du draft de niveau
- **Atteindre la situation** : un draft de niveau (« Gagner un niveau (ouvre le draft) », puis toucher le rideau) ; si une run atteint un boss, son draft de cartes.
- **Faire** : laisser les rouleaux tourner puis s'arrêter.
- **Attendu** : les rouleaux posés montrent l'emoji d'aujourd'hui : ✨ par défaut, ou l'emoji de leur titre (❤️ Vitalité, ⚔️ Aiguisage, 🔮 Sagesse…) ; aucune icône d'évolution. Le draft de boss (des cartes, sans rouleaux) n'a pas changé.
- **Ne doit pas changer** : le tirage, les sons, le choix.
- **Résultat** : ✅ · ❌ · non testé —

## M12 — L'écran d'évolution : les en-têtes
- **Atteindre la situation** : comme M10, au niveau 5 (sans draft en attente : « Drafts en attente » à 0).
- **Faire** : toucher le rideau, choisir l'évolution de *Bouclier Sacré*, rouvrir le rideau. En français puis en anglais.
- **Attendu** : au premier écran, l'en-tête « Évolution de Bouclier Sacré » ; au second, « Évolution de Châtiment », puis « Choisissez une évolution » en dessous. En anglais : « Holy Shield evolves », « Smite evolves », « Choose an evolution ». Le retour système (Échap, bouton retour) ne quitte pas l'écran sans choisir.
- **Ne doit pas changer** : la musique et le fond de la carte.
- **Résultat** : ✅ · ❌ · non testé —

## M13 — L'écran d'évolution : trois mineures
- **Atteindre la situation** : niveau 5, aucune évolution prise (« Retirer les évolutions » sur les deux signatures au besoin).
- **Faire** : ouvrir le premier écran (*Bouclier Sacré*), choisir, puis ouvrir le second (*Châtiment*).
- **Attendu** : au second écran, trois rouleaux, chacun son nom, sa description et « MINEURE » : *Zèle* « +2 dégâts », *Égide* « +2 Armure », *Ardeur* « +5 % de critique » (dans un ordre quelconque). Au premier : *Garde* « +2 Armure », *Miséricorde* « +1 PV soignés », *Résolution* « Gagne 1 Puissance ».
- **Ne doit pas changer** : —
- **Résultat** : ✅ · ❌ · non testé —

## M14 — L'écran d'évolution : trois majeures
- **Atteindre la situation** : run debug Paladin, carte du monde, onglet « Heros », section « Évolutions de signature » : sous *Châtiment*, « Zèle » ; sous *Bouclier Sacré*, une mineure (« Garde »). Puis « Niveau (stat brute) » à 10.
- **Faire** : au rideau, choisir l'évolution de *Bouclier Sacré* (déjà des majeures), puis ouvrir celle de *Châtiment*.
- **Attendu** : trois rouleaux « MAJEURE », chacun une majeure de *Châtiment*, parmi *Célérité* « Recharge réduite d'un tour », *Sentence* « Applique 1 Faiblesse pendant 2 tours », *Rayonnement* « Touche tous les ennemis », *Dévotion* « Coûte 1 Mana de moins ».
- **Ne doit pas changer** : —
- **Résultat** : ✅ · ❌ · non testé —

## M15 — L'écran d'évolution : une mineure reprise
- **Atteindre la situation** : run debug Paladin, « Évolutions de signature » : sous *Châtiment*, « Zèle » puis « Célérité » ; sous *Bouclier Sacré*, « Garde » puis « Célérité ». Puis « Niveau (stat brute) » à 15.
- **Faire** : au rideau, choisir l'évolution de *Bouclier Sacré*, puis ouvrir celle de *Châtiment*.
- **Attendu** : trois mineures ; le rouleau de *Zèle* dit « +4 dégâts » (sa description au prochain niveau) et, en dernière ligne, « Niveau 1 → 2 » ; *Égide* et *Ardeur* n'ont pas cette ligne.
- **Ne doit pas changer** : —
- **Résultat** : ✅ · ❌ · non testé —

## M16 — L'écran d'évolution : l'icône, et une majeure distincte d'une mineure
- **Atteindre la situation** : un écran de mineures (M13) et un écran de majeures (M14).
- **Faire** : regarder les rouleaux tourner, puis s'arrêter ; comparer une majeure et une mineure.
- **Attendu** : pendant la rotation, l'emoji ✨ du carrousel, sans icône d'évolution. Rouleau arrêté : au-dessus du nom, l'icône de l'évolution à sa couleur (*Zèle* : le marteau rouge ; *Égide* : l'écu bleu) ; une majeure a son icône dans un anneau de sa couleur, une mineure est nue. « MINEURE » et « MAJEURE » sont écrits au même gris : l'anneau et le mot sont les seules différences. **Juger** (point des revues) : une majeure se distingue-t-elle assez d'une mineure ?
- **Ne doit pas changer** : la rotation, les sons, le choix au toucher.
- **Résultat** : ✅ · ❌ · non testé —

## M17 — Le choix pris, puis le combat
- **Atteindre la situation** : un écran d'évolution ouvert, rouleaux arrêtés.
- **Faire** : toucher un rouleau ; entrer en combat.
- **Attendu** : le rouleau grossit, l'écran se ferme et la carte revient ; en combat, la tuile de la signature porte la puce de l'évolution choisie et « Niv. 1 ».
- **Ne doit pas changer** : l'autre signature, si elle n'a rien reçu.
- **Résultat** : ✅ · ❌ · non testé —

## M18 — La tuile : le badge de niveau
- **Atteindre la situation** : run debug Paladin. Combat sans évolution, puis, sur la carte, « Évolutions de signature » sous *Châtiment* : « Zèle », « Sentence », « Zèle » (la liste affiche « zeal:2, sentence:1 ») ; combat. Puis run debug du Mage : sous *Surtension de Mana*, « Bouclier de mana » ; combat sur une fenêtre étroite.
- **Faire** : regarder *Châtiment* dans les quatre états : disponible, armée (toucher la tuile), en recharge (la jouer), sans le mana (onglet Combat, « Mana » à 0). En français puis en anglais.
- **Attendu** : sans évolution, aucun « Niv. ». Avec, « Niv. 3 » (« Lvl. 3 » en anglais) au bout de la ligne du type, sur la même ligne ; ambre disponible et armée, gris pâle en recharge et sans le mana. Sur la tuile étroite, « Surtension de Mana » s'écrit en entier (le badge est sur la ligne du type, pas sur celle du nom), « Niv. 1 ».
- **Ne doit pas changer** : le nom, le type à sa couleur, le médaillon de coût.
- **Résultat** : ✅ · ❌ · non testé —

## M19 — La tuile : les puces d'évolution
- **Atteindre la situation** : run debug Paladin, « Évolutions de signature » sous *Châtiment* : « Zèle », « Sentence », « Zèle », « Célérité », « Égide » ; combat. Puis, sur la carte, « Retirer les évolutions », et les sept de *Châtiment* en alternant les paliers : « Zèle », « Célérité », « Égide », « Sentence », « Ardeur », « Rayonnement », « Zèle », « Dévotion » ; combat.
- **Faire** : regarder les puces sur une fenêtre étroite (≈ 400 px de large) puis large.
- **Attendu** : une puce par évolution distincte, dans l'ordre de première prise, sous la bande : *Zèle* (marteau rouge) nue, suivie de son niveau « 2 » écrit à sa droite, à la taille du badge ; *Sentence* et *Célérité* dans un anneau ; *Égide* sans chiffre. Les sept puces tiennent sur la tuile, étroite comme large, sans débordement (la rangée se réduit d'un bloc s'il le faut).
- **Ne doit pas changer** : la tuile de *Bouclier Sacré*.
- **Résultat** : ✅ · ❌ · non testé —

## M20 — La tuile : la bande d'icônes
- **Atteindre la situation** : run debug Paladin. Combat sans évolution ; puis « Zèle », « Sentence », « Zèle » sous *Châtiment* ; combat ; puis, de plus, « Rayonnement » et « Ardeur » ; combat.
- **Faire** : regarder *Châtiment* au repos.
- **Attendu** : plus aucun texte de description sur la tuile. Sans évolution, deux icônes : marteau rouge « 6 », écu bleu « 4 ». Avec les trois : « 10 », « 4 », et la courbe descendante violette « 1 », sur une ligne, sans durée (pas de « 2 tours »). Avec les cinq : trois icônes sur la première ligne (« 10 », « 4 », « 1 ») et deux sur la seconde : *Rayonnement* (rayons violet foncé) sans chiffre, puis l'éclat ambre « +5 % ».
- **Ne doit pas changer** : le compte de recharge (sablier, « 2 tours ») quand la tuile est jouée.
- **Résultat** : ✅ · ❌ · non testé —

## M21 — La tuile : huit icônes sur Surtension de Mana
- **Atteindre la situation** : run debug du Mage, « Évolutions de signature » sous *Surtension de Mana*, dans cet ordre : « Bouclier de mana », « Glyphe de garde », « Harmonie », « Exaltation », « Clarté », « Sérénité » (*Prescience*, la seule chiffrée, n'est pas prise) ; combat.
- **Faire** : regarder la tuile sur une fenêtre étroite, puis large.
- **Attendu** : huit icônes en trois lignes de 3, 3 et 2, chaque ligne centrée dans la tuile, celle de deux comprise : diamant cyan « 1 », cartes ambre « 1 », écu bleu « 2 » / flèches en cercle bleues « 3 », éclair orange « 1 », éclair orange « 2 » / cœur rose « 1 », cœur rose « 4 ». Les icônes de la bande sont plus grandes que les puces ; rien ne déborde.
- **Ne doit pas changer** : la tuile de *Projectile Magique*.
- **Résultat** : ✅ · ❌ · non testé —

## M22 — La tuile : les évolutions chiffrées, la ligne qui se réduit
- **Atteindre la situation** : run debug Paladin, fenêtre étroite. Sous *Châtiment* : « Zèle », « Célérité », « Ardeur » ; combat. Puis « Retirer les évolutions » et « Zèle », « Célérité », « Zèle », « Dévotion », « Égide », « Égide », « Égide », « Ardeur » (les deux majeures chiffrées prises, le palier majeur admet alors les mineures) ; combat.
- **Faire** : regarder la bande sur la fenêtre étroite, puis large.
- **Attendu** : d'abord « 8 », « 4 », « +5 % » (*Célérité* n'ajoute pas d'icône) ; puis « 10 », « 10 », « +5 % ». La ligne tient, ou se réduit d'un bloc : jamais coupée, jamais en débordement ; sur la large, elle tient sans réduction. Le médaillon dit 0 (*Dévotion*).
- **Ne doit pas changer** : —
- **Résultat** : ✅ · ❌ · non testé —

## M23 — La tuile : gris en recharge et sans le mana
- **Atteindre la situation** : run debug Paladin, « Zèle », « Sentence », « Zèle » sous *Châtiment* ; combat.
- **Faire** : regarder *Châtiment* disponible, armée ; onglet Combat, « Mana » à 0 ; « Mana plein », la jouer (recharge) ; « Fin de Tour » et la regarder pendant le tour ennemi.
- **Attendu** : disponible et armée, tout à ses couleurs (la puce de *Zèle* rouge, le badge ambre). En recharge et sans le mana : icônes et valeurs de la bande, puces, anneaux, chiffres et badge en gris pâle ; le médaillon de coût reste bleu en recharge, et passe au rouge sans le mana (comme en `0.5.6`). Inactive (tour ennemi) : toute la tuile à demi effacée.
- **Ne doit pas changer** : la bordure grise en recharge et sans le mana, la lueur de classe disponible.
- **Résultat** : ✅ · ❌ · non testé —

## M24 — Dévotion à 0 Mana ; Rayonnement sans cible
- **Atteindre la situation** : run debug Paladin, sous *Châtiment* « Zèle », « Dévotion » ; combat. Puis, sur la carte, « Retirer les évolutions », « Zèle », « Rayonnement » ; combat à au moins deux ennemis.
- **Faire** : avec *Dévotion*, onglet Combat « Mana » à 0, toucher *Châtiment* puis un ennemi. Avec *Rayonnement*, toucher *Châtiment*.
- **Attendu** : le médaillon dit 0 ; à 0 Mana la tuile reste disponible (lueur, pas de gris), s'arme et frappe (8 dégâts, 4 Armure). Avec *Rayonnement*, le toucher joue aussitôt sur tous les ennemis (8 dégâts chacun), sans armer, sans « Choisissez une cible ».
- **Ne doit pas changer** : *Bouclier Sacré* ; la recharge posée après le jeu.
- **Résultat** : ✅ · ❌ · non testé —

## M25 — La liste de l'appui long : contenu, et la colonne immobile
- **Atteindre la situation** : run debug Paladin, « Zèle », « Sentence », « Zèle » sous *Châtiment* (comme M18), « Garde » puis « Consécration » sous *Bouclier Sacré* ; combat.
- **Faire** : rester appuyé (bouton de la souris tenu) sur *Châtiment*, la tuile du bas ; relâcher ; puis rester appuyé sur *Bouclier Sacré*, la tuile du haut.
- **Attendu** : la liste s'ouvre vers le bas depuis le haut de la tuile : une ligne par icône de la bande, dans son ordre, l'icône puis sa phrase — *Châtiment* : « Inflige 10 dégâts », « Donne 4 d'Armure », « Applique 1 Faiblesse pendant 2 tours » ; *Bouclier Sacré* : « Donne 10 d'Armure », « Soigne 2 PV », « Gagne 2 Puissance pendant 2 tours », et sa liste passe par-dessus la tuile voisine, *Châtiment*. La colonne des tuiles ne bouge ni ne change de taille.
- **Ne doit pas changer** : rien n'est joué ni armé ; la main.
- **Résultat** : ✅ · ❌ · non testé —

## M26 — La liste : relâcher, glisser
- **Atteindre la situation** : comme M25.
- **Faire** : ouvrir la liste puis relâcher ; la rouvrir et glisser la souris hors de la tuile sans relâcher, puis relâcher. Android seulement : rouvrir et tirer le volet des notifications.
- **Attendu** : relâcher replie la liste ; le glissement ne la replie pas (elle se replie au relâcher) ; le geste du système la replie. Sous Windows, ce dernier cas ne se provoque pas : le noter non testé.
- **Ne doit pas changer** : un glissement ne joue ni n'arme la signature.
- **Résultat** : ✅ · ❌ · non testé —

## M27 — La liste sur une fenêtre basse
- **Atteindre la situation** : fenêtre basse (≈ 400 px de haut, celle de M31). Run debug Paladin : sous *Bouclier Sacré*, les sept en alternant les paliers, « Garde », « Célérité », « Miséricorde », « Consécration », « Résolution », « Inspiration », « Garde », « Égide durable » ; sous *Châtiment*, les sept de M19 ; combat.
- **Faire** : rester appuyé sur *Châtiment*, la tuile du bas ; puis sur *Bouclier Sacré*. Au besoin, baisser encore la fenêtre.
- **Attendu** : une liste qui tient sous le haut de sa tuile s'ouvre vers le bas ; sinon elle s'ouvre vers le haut, son bas au bas de la tuile. Jamais coupée par le bas de la fenêtre.
- **Ne doit pas changer** : la colonne, qui reste où M31 la pose.
- **Résultat** : ✅ · ❌ · non testé —

## M28 — La liste dans les quatre états
- **Atteindre la situation** : comme M25, fenêtre étroite puis large.
- **Faire** : ouvrir la liste de *Châtiment* disponible ; sans le mana (« Mana » à 0) ; en recharge (après l'avoir jouée) ; puis hors du tour du joueur : « Fin de Tour », et rester appuyé sur la tuile pendant « TOUR ENNEMI ».
- **Attendu** : elle s'ouvre dans les quatre états. En recharge et sans le mana : cadre et en-tête gris, phrases en gris pâle, icônes de la liste à leurs couleurs. Disponible : phrases en blanc atténué. Inactive : la liste à pleine opacité (la tuile, elle, à demi effacée). Les icônes de la liste sont petites, de la même taille sur les deux largeurs.
- **Ne doit pas changer** : le tour ennemi se déroule ; rien n'est joué.
- **Résultat** : ✅ · ❌ · non testé —

## M29 — Appui court et appui long
- **Atteindre la situation** : combat Paladin, Mana 3, au moins un ennemi.
- **Faire** : toucher brièvement *Bouclier Sacré* ; *Châtiment* ; *Châtiment* armée ; puis, « Mana » à 0, *Châtiment*. Recommencer chaque cas en restant appuyé, puis en relâchant.
- **Attendu** : l'appui court fait comme en `0.5.6` : *Bouclier Sacré* se joue (+8 Armure, +2 PV, Mana −1) ; *Châtiment* s'arme (« Choisissez une cible ») ; armée, il se désarme ; sans le mana, la tuile secoue et le son « mana insuffisant » sonne. L'appui long ouvre la liste et ne joue, n'arme ni ne désarme rien (une tuile armée reste armée).
- **Ne doit pas changer** : le jeu d'une carte de la main ; le glisser-déposer.
- **Résultat** : ✅ · ❌ · non testé —

## M30 — La barre à 1280 × 800
- **Atteindre la situation** : combat, aucune évolution, fenêtre de 1280 × 800.
- **Faire** : regarder la colonne.
- **Attendu** : les deux tuiles à mi-hauteur, comme en `0.5.6`, en face du bouton « Fin de Tour ».
- **Ne doit pas changer** : le panneau des statuts sous la colonne ; la main.
- **Résultat** : ✅ · ❌ · non testé —

## M31 — La barre sur une fenêtre basse
- **Atteindre la situation** : fenêtre basse (≈ 400 px de haut) ; beaucoup d'évolutions (les sept de chaque signature, comme M27) ; combat.
- **Faire** : regarder la colonne ; toucher *Châtiment* ; toucher un ennemi.
- **Attendu** : la colonne se réduit (aux trois quarts au plus), reste sous la barre du haut et peut sortir par le bas, peinte au-dessus du reste de l'interface ; la tuile réduite s'arme, et « Choisissez une cible » reste visible sous la colonne ; l'ennemi touché reçoit le coup.
- **Ne doit pas changer** : la tuile répond au toucher à sa place réduite (pas à côté).
- **Résultat** : ✅ · ❌ · non testé —

## M32 — Le panneau des statuts : les icônes des cartes
- **Atteindre la situation** : combats qui donnent au héros : Puissance (Berserker, *Posture de Rage* ou *Forme Démoniaque* ; Paladin avec *Résolution* ou *Consécration*) ; Éveil de Puissance (*Transe*, Berserker) ; Armure au début du tour (*Métallisation*, *Bastion*, ou *Égide durable*). Pour comparer les éclairs : *Coup de Tonnerre* ou *Rafale d'étincelles* en main avec *Forme Démoniaque* ou *Fureur sanguine*.
- **Faire** : jouer ces cartes et signatures, regarder le panneau des statuts du héros (en bas à gauche) et les faces des cartes.
- **Attendu** : chaque statut porte l'icône et la couleur des faces des cartes : l'éclair orange pour « Puissance : +2 » comme pour « Éveil de Puissance : +1 » ; les flèches en cercle bleues pour « Métallisation : +2 » (l'Armure au début du tour ; avant, l'écu cyan). Les libellés ne changent pas. **Juger** (point des revues) : le bleu de l'Armure au début du tour se lit-il à côté du bleu de l'Armure ? Puissance et Éveil, au même éclair, se distinguent-ils par leur libellé ? Sur les faces, l'éclair orange de la Puissance et l'éclair ambre de l'Électrocution se distinguent-ils ? Faiblesse, Brûlure et Poison ne se posent jamais sur le héros en `0.5.7` (aucun ennemi ne pose de statut, aucune carte ne les pose sur soi) : non atteignables ici, la Brûlure et le Poison se voient au tutoriel (M7).
- **Ne doit pas changer** : les valeurs, les durées, l'ordre des statuts.
- **Résultat** : ✅ · ❌ · non testé —

## M33 — Métallisation et Vol de vie
- **Atteindre la situation** : aucune relique livrée ne donne ces deux statuts. Le statut « Vol de Vie » ne vient que du passif *Soif de Sang*, masqué en `0.5.7` (pas de lot) ; le statut de relique « Métallisation » n'est posé par rien — le « Métallisation » que l'on voit au panneau est l'Armure au début du tour (M32).
- **Faire** : au fil des combats de cette campagne, regarder chaque statut du panneau.
- **Attendu** : aucun statut ne s'affiche en point d'interrogation. L'écu cyan et le cœur rouge d'aujourd'hui : non atteignables, à noter non testés.
- **Ne doit pas changer** : —
- **Résultat** : ✅ · ❌ · non testé —

## M34 — Le menu de debug : « Évolutions de signature »
- **Atteindre la situation** : « RUN DEBUG », Paladin, carte du monde, tiroir, onglet « Heros », section « Évolutions de signature » (tout en bas). Puis une run debug du Berserker.
- **Faire** : sous *Châtiment*, poser « Zèle », « Sentence », « Zèle », lire la liste et les boutons à chaque pas ; prendre une majeure, regarder si elle revient ; « Retirer les évolutions » ; entrer en combat. Berserker, sous *Frappe Téméraire* : « Brutalité », « Célérité », « Instinct », puis lire les boutons.
- **Attendu** : pour chaque signature, ce qui est pris dans l'ordre (« zeal:2, sentence:1 ») ou « aucune ». Un bouton par évolution que le prochain palier admet : sans évolution, les trois mineures seules (« Zèle », « Égide », « Ardeur ») ; après une mineure, les quatre majeures (« Célérité », « Sentence », « Rayonnement », « Dévotion ») ; une majeure prise n'est plus proposée. Sur *Frappe Téméraire*, après « Instinct », le palier majeur ne garde que « Fauchage » et « Sang-froid » — « Célérité » est prise, « Dévastation » exclue par elle —, et les trois mineures (« Brutalité », « Instinct », « Fracas ») s'ajoutent aux boutons. « Retirer les évolutions » remet « aucune ». Le niveau du héros ne bouge pas (« Niveau (stat brute) » inchangé), aucun rideau n'apparaît. En combat, la tuile porte ce qui est posé.
- **Ne doit pas changer** : les autres champs de l'onglet ; rien n'est sauvé (une run debug ne sauvegarde pas).
- **Résultat** : ✅ · ❌ · non testé —

## M35 — Le parcours de bout en bout (neuf)
*Neuf : demandé par l'orchestrateur de la vague. Run normale, sans debug : la reprise ne se teste pas en run debug, qui ne sauvegarde rien. Le niveau 5 est jouable : environ 460 XP à l'acte 1, quatre à six combats.*
- **Atteindre la situation** : accueil « JOUER », Paladin, passif *Régénération d'Armure*, draft 2 + 3, « ENTRER DANS L'UMBRA ».
- **Faire** : (1) gagner des combats ; à chaque niveau (2, 3, 4), toucher le rideau et faire le draft. (2) Au niveau 5 (panneau en bas à droite : « Niv. 5 ») : toucher le rideau, faire le draft ; toucher le rideau, choisir une évolution de *Bouclier Sacré*. (3) Le rideau revenu, **fermer la fenêtre du jeu**. (4) Relancer, « Continuer » ; toucher le rideau, choisir *Zèle* pour *Châtiment*. (5) Entrer en combat ; regarder les deux tuiles ; rester appuyé sur *Châtiment*. (6) Finir le combat, revenir à la carte, fermer le jeu, relancer, « Continuer », entrer en combat.
- **Attendu** : (2) le draft d'abord, puis « Évolution de Bouclier Sacré » (*Garde*, *Miséricorde*, *Résolution*, « MINEURE ») ; le rideau revient après le choix. (4) Après la reprise : le rideau est toujours là, l'évolution de *Bouclier Sacré* est gardée, et le rideau ouvre « Évolution de Châtiment » (*Zèle*, *Égide*, *Ardeur*) ; après le choix, il disparaît et les nœuds s'ouvrent. (5) Les deux tuiles portent « Niv. 1 » et leur puce ; *Châtiment* montre le marteau rouge « 8 » et l'écu bleu « 4 » ; la liste dit « Inflige 8 dégâts », « Donne 4 d'Armure ». (6) Après la seconde reprise : mêmes tuiles, même badge, mêmes puces ; aucun rideau.
- **Ne doit pas changer** : or, PV, reliques, deck, position sur la carte après chaque reprise ; le draft de niveau ne revient pas une seconde fois.
- **Résultat** : ✅ · ❌ · non testé —

## M36 — Un seul passif : ni badge, ni dépliage (neuf)
*Neuf : renvoyé au test par la revue de la partie 2 (compte rendu, S10). Le propriétaire a signalé le 04/11 que le dépliage ne montrait rien de plus ; corrigé le même jour, l'attendu ci-dessous est le nouveau.*
- **Atteindre la situation** : nouvelle partie, écran de sélection de classe.
- **Faire** : sur chaque classe, regarder le bas de la carte, puis toucher la carte et son passif. Sur une fenêtre large, puis sous 600 px.
- **Attendu** : chaque classe montre un seul passif, en entier (Paladin *Régénération d'Armure*, Berserker *Rage*, Mage *Flux de Mana*), juste sous le bouton « Sélectionner », **sans** l'étiquette « Passifs » ni son chevron, et sans espace vide en dessous. Toucher la carte ou le passif ne fait rien ; le survol garde le halo et l'inclinaison de la carte, mais le passif ne s'allume pas. Le badge et le dépliage reviennent d'eux-mêmes en `0.5.8`, quand chaque classe aura un deuxième passif.
- **Ne doit pas changer** : le choix de la classe et du passif ; le reste de la carte.
- **Résultat** : ✅ · ❌ · non testé —

## M37 — La barre de l'éditeur de contenu (neuf)
*Neuf : renvoyé au test par la revue de la partie 2 (compte rendu, S12).*
- **Atteindre la situation** : accueil, colonne DEBUG, « EDITEUR DE CONTENU ».
- **Faire** : regarder la barre des catégories sur une fenêtre large, puis rétrécir la fenêtre.
- **Attendu** : dix catégories (Carte, Carte de lot, Signature, Relique, Passif, Événement, Amélioration de forge, Récompense de niveau, Classe, Ennemi) ; sur une fenêtre étroite, elles passent sur deux lignes, sans débordement (pas de bandes jaunes et noires) ; chacune reste cliquable.
- **Ne doit pas changer** : le formulaire sous la barre ; les fichiers, si rien n'est enregistré.
- **Résultat** : ✅ · ❌ · non testé —

## M38 — Les deux phrases réécrites du tutoriel (neuf)
*Neuf : renvoyé au test par la revue d'ensemble de la partie 2 (compte rendu, S14) ; deux phrases rendues fausses par le masquage des passifs sans lot.*
- **Atteindre la situation** : « TUTORIEL » ; étapes « Choisissez votre classe » et « Armure & Dégâts ». En français puis en anglais.
- **Faire** : lire les deux passages.
- **Attendu** : « Choisissez votre classe » : « …et surtout par leur passif : c'est lui qui donne son style à la partie, et chaque passif a son propre lot de cartes. » (« …by their passive: it sets the style of your run, and each passive has its own set of cards. »). « Armure & Dégâts » : « La *façon d'en gagner* : vos cartes, et parfois votre passif — la Maîtrise, … » (« *How you earn it*: your cards, and sometimes your passive — Mastery, … »). Plus de « chaque classe en propose plusieurs », plus de « c'est votre passif ». **Juger** la formulation : elle se réécrit au besoin.
- **Ne doit pas changer** : le reste des deux étapes.
- **Résultat** : ✅ · ❌ · non testé —

## M39 — Les signatures en tête de « Mon Deck » (neuf)
*Neuf : demandé par le propriétaire le 06/11 ; [maquettes](../../presentations/2026-11-06_signatures_hors_combat_maquettes.pptx), options A et 2, sans chiffre d'XP.*
- **Atteindre la situation** : « RUN DEBUG », Paladin ; niveau du héros par l'onglet « Heros », évolutions par sa section « Évolutions de signature » (M34) ; puis « MON DECK » depuis la carte, et depuis la barre du haut en combat. Pour l'attente, le niveau 5 sans choisir (M10).
- **Faire** : ouvrir l'écran au niveau 3, sans évolution ; poser « Zèle », « Sentence », « Zèle » sur *Châtiment* au niveau 15 ; défiler ; recommencer sous 600 px de large, puis en anglais.
- **Attendu** : en haut, « SIGNATURES » et une fiche par signature (*Bouclier Sacré*, puis *Châtiment*) : nom, type, coût et recharge, description. Sans évolution : pas de badge ni de liste, et « Prochaine évolution mineure au niveau 5 ». Avec les trois évolutions : badge « Niv. 3 », « Inflige 10 dégâts et donne 4 d'Armure. Applique 1 Faiblesse pendant 2 tours. », les lignes « Zèle 2 +4 dégâts » et « Sentence… » avec leur icône, et « Prochaine évolution majeure au niveau 20 ». Quand un choix attend : « Évolution à choisir ». Côte à côte en large, empilées sous 600 px ; la bande défile avec les cartes. En anglais : « Next minor evolution at level 5 », « Next major evolution at level 20 », « Evolution to choose ». **Juger** : la bande prend-elle trop de place sur téléphone ?
- **Ne doit pas changer** : les cartes, leur compteur, la fusion depuis la carte et son absence depuis le combat ; la tuile de combat ; aucun chiffre d'XP sur la fiche.
- **Résultat** : ✅ · ❌ · non testé —

## Ce qui doit rester inchangé
- Le jeu d'une carte de la main : coût en mana, cible, dégâts, animation, son, mise en défausse ou en exil ; le glisser-déposer vers un ennemi.
- L'appui court sur une signature : jouer, armer, désarmer, refuser faute de mana, comme en `0.5.6` ; la recharge et son compte.
- Le bouton « Fin de Tour », la phase ennemie, la pioche et le mana de début de tour.
- Les reliques, les événements, la boutique, le repos, la forge et la fusion (hors les cartes offertes, filtrées par le passif).
- Le draft de niveau, le draft de boss, leurs rouleaux et leurs emojis.
- Le menu de debug : mêmes onglets (en combat : « Combat » seul ; hors combat : « Heros », « Run », « Deck », « Reliques ») ; seule la section « Évolutions de signature » s'ajoute à « Heros ».
- L'écran de mort, le menu de pause, la reprise d'une run.
- Le tutoriel : le déroulé, les étapes et leur ordre (hors les textes cités en M5, M6 et M38).

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
| 1 | M36 | Cliquer sur « Passifs » ne déplie rien : chaque classe n'a plus qu'un passif disponible (O5), déjà montré replié | Gênant | `fix(classes): sans deuxieme passif, ni badge ni depliage`, le 04/11 |
