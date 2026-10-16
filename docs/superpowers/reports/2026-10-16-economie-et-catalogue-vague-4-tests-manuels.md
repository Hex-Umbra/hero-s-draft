# Vague 4 — `0.5.6` — tests manuels

**Branche** : `feat/v0.5.6-p43-e4-signatures` · **Compte rendu** : [2026-10-16-economie-et-catalogue-vague-4-compte-rendu.md](2026-10-16-economie-et-catalogue-vague-4-compte-rendu.md)
**Testé le** : <JJ/MM/AAAA>, sur `<sha>`, sur <plateforme>
**Résultat** : <K> ✅ · <L> ❌ · <M> non testés

**Repères communs.** Les trois classes ont 3 Mana max. Les signatures, d'après `assets/data/classes/*/skills/*.json` (recharge 2 tours pour toutes) :

| Classe | Signature | Coût | Type | Cible | Effet |
|:---|:---|---:|:---|:---|:---|
| Paladin | Bouclier Sacré | 1 | Compétence | soi | +8 Armure, soigne 2 PV |
| Paladin | Châtiment | 1 | Attaque | un ennemi | 6 dégâts, +4 Armure |
| Berserker | Frappe Téméraire | 2 | Attaque | un ennemi | 15 dégâts |
| Berserker | Posture de Rage | 1 | Compétence | soi | +2 Puissance ce tour-ci, pioche 1 |
| Mage | Projectile Magique | 1 | Compétence | un ennemi | 5 dégâts, pioche 1 |
| Mage | Surtension de Mana | 0 | Compétence | soi | +1 Mana, pioche 1 |

Le menu de debug (tiroir au bord gauche, build debug seulement, run lancée par le menu de debug de l'accueil) a deux jeux d'onglets. **En combat : un seul onglet, « Combat »** (PV, Mana, Armure, « Soin complet », « Mana plein », PV de chaque ennemi / « 0 PV », « Tous les ennemis a 0 PV », « Gagner le combat », « Perdre le combat », « Sauter la phase ennemie »). **Hors combat (carte du monde) : « Heros », « Run », « Deck », « Reliques »** : « Deck » > « Ajouter une carte » ajoute une carte au deck ; « Reliques » > « Ajouter une relique » ajoute une relique ; « Heros » > « Mana max », « PV max », « Puissance » ; « Run » > « Or ». Pour atteindre un combat avec une relique ou des cartes précises, les ajouter sur la carte du monde, puis entrer dans un combat. Les valeurs de Puissance changent les dégâts : pour comparer des chiffres, partir de Puissance 0, sauf mention.

## À tester d'abord
<!-- du plus risqué au moins risqué -->
1. **T1** — Châtiment : toucher la tuile, puis un ennemi précis ; les dégâts vont à cet ennemi, pas à la sélection d'une carte précédente.
2. **T2** — Le héros meurt pendant que la souris est sur une tuile : rien ne reste affiché, les boutons de l'écran de mort restent cliquables.
3. **T3** — Chaque geste qui désarme une signature armée, et la priorité d'une carte focalisée.
4. **T4** — Une signature jouée compte comme une carte de son type pour les passifs (Flux de Mana, Soif de Sang) et **Marque du Mage ne se déclenche plus sur Projectile Magique**.
5. **T5** — Les quatre reliques (Amulette du Mage, Plume de scribe, Shuriken, Croc Kunaï) voient une signature jouée.
6. **T6** — La barre : place, au-dessus du panneau des statuts, tuile qui ne saute pas quand on arme.
7. **T7** — Le compte de recharge « 2 tours » puis « 1 tour », sous la description, sans rien recouvrir.
8. **T8** — Reprendre une run en cours garde les signatures.
9. **T9** — Les cinq états de la tuile.
10. **T10** — Aucune signature dans le deck, la pioche, la défausse, la fusion, la boutique, les récompenses ; Bouclier Sacré et Surtension de Mana ne s'épuisent pas.
11. **T11** — Bouclier Sacré (sans cible) : armure, soin, mana −1, animation, son.
12. **T12** — Mana insuffisant : secousse et son.
13. **T13** — Les deux autres classes : Berserker et Mage, leurs quatre signatures.
14. **T14** — Le survol : une tuile qui répond grossit et s'illumine ; aucune infobulle.
15. **T15** — Recharge remise à zéro au combat suivant.
16. **T16** — Boutons de 170 px de large sous 600 px de large.
17. **T17** — Le draft de départ : 5 cartes du pool commun, sans signature.
18. **T18** — Le tutoriel : prose, bandeau du draft, Fusion.
19. **T19** — La carte de classe à la sélection.
20. **T20** — L'onglet « Signatures » du dictionnaire.
21. **T21** — L'éditeur de contenu : la catégorie « signature ».

## T1 — Châtiment sur un ennemi précis (cible unique)
- **Atteindre la situation** : run Paladin ; entrer dans un combat à au moins 2 ennemis (sinon en choisir un contenant plusieurs ennemis sur la carte). Premier tour, Mana 3 (au besoin « Mana plein » de l'onglet Combat).
- **Faire** : (1) toucher une carte à cible unique de la main pour en sélectionner un ennemi A, sans la jouer, ou jouer une première carte sur A ; (2) toucher la tuile Châtiment ; (3) toucher l'ennemi B, différent de A.
- **Attendu** : à l'étape 2 la tuile est armée (bordure épaisse de 3 px qui pulse vers le blanc) et « Choisissez une cible » apparaît sous la colonne. Les ennemis s'illuminent (bordure ambre) au survol de la souris. À l'étape 3 : 6 dégâts à **B** (et rien à A), +4 Armure, Mana −1, animation de corps à corps, la tuile passe en recharge « 2 tours ». L'invite disparaît.
- **Ne doit pas changer** : l'ennemi A (déjà ciblé par une carte) garde sa bordure ambre mais ne subit rien ; la main n'est pas modifiée ; aucune carte n'est défaussée. Sur écran tactile, la bordure ambre de A ne signifie pas que la signature le frappera (décision S12, à la file).
- **Résultat** : ✅ · ❌ · non testé —

## T2 — Mort du héros, souris sur une tuile
- **Atteindre la situation** : combat Paladin, tiroir de debug fermé.
- **Faire** : placer la souris sur une tuile, sans la bouger ; ouvrir le tiroir de debug (sans passer sur la barre), onglet « Combat », « Perdre le combat » (ou laisser un ennemi tuer le héros, PV à 1 par l'onglet Combat, puis « Sauter la phase ennemie » ou fin de tour) ; essayer ensuite les boutons de l'écran de mort.
- **Attendu** : à la mort, la barre disparaît et rien ne reste affiché à sa place ; les boutons de l'écran de mort sont cliquables (rien ne les recouvre). Répéter avec un appui long maintenu au doigt/souris sur une tuile si le matériel le permet.
- **Ne doit pas changer** : l'écran de mort et son flux habituel (retour à l'accueil, etc.).
- **Résultat** : ✅ · ❌ · non testé —

## T3 — Les gestes qui désarment, et la priorité d'une carte focalisée
- **Atteindre la situation** : combat Paladin, 2 ennemis, Mana 3. Armer Châtiment (toucher sa tuile : bordure pulsante, invite visible).
- **Faire** : essayer chacun de ces gestes, en réarmant Châtiment avant chacun : (a) toucher à nouveau la tuile Châtiment ; (b) toucher le décor (fond du champ de bataille, hors ennemi, hors main) ; (c) toucher ou faire glisser une carte de la main (focalisation) ; (d) toucher la tuile Bouclier Sacré ; (e) toucher un ennemi mort ou mourant, s'il y en a un (sinon sauter) ; (f) terminer le tour. Puis : focaliser d'abord une carte à cible unique (carte levée), toucher ensuite Châtiment, puis un ennemi.
- **Attendu** : (a) désarme, invite disparue, rien n'est joué ; (b) désarme, rien n'est joué ; (c) désarme, la carte est focalisée ; (d) désarme Châtiment **et joue** Bouclier Sacré (+8 Armure, +2 PV, Mana −1) — un seul geste à la fois ; (e) rien ne se joue, la signature reste armée ; (f) plus d'armement après le changement de phase, tuiles inactives pendant la phase ennemie. Pour la carte focalisée : toucher Châtiment repose la carte dans la main (elle n'est plus levée) et arme la signature ; l'ennemi touché ensuite reçoit Châtiment, la carte reste en main, rien n'est joué en double. À l'inverse, Châtiment armé puis une carte focalisée : l'armement s'annule (c), et toucher un ennemi joue la carte, jamais la signature.
- **Ne doit pas changer** : le glisser-déposer d'une carte vers un ennemi, son ciblage et ses dégâts.
- **Résultat** : ✅ · ❌ · non testé —

## T4 — Passifs : une signature compte comme une carte de son type
- **Atteindre la situation** : trois runs courtes, passif de classe choisi au départ. Pour chacune, entrer dans un combat avec Mana plein (3).
  - Mage avec **Flux de Mana** (toutes les 3 Compétences : +1 Mana pour le tour) : jouer, dans un même combat, **Projectile Magique** (devenu Compétence), puis **Surtension de Mana**, puis une troisième Compétence (carte de la main, ou « Deck » > « Ajouter une carte » avant le combat).
  - Berserker avec **Soif de Sang** : jouer **Frappe Téméraire** (signature Attaque).
  - Mage avec **Marque du Mage** : jouer **Projectile Magique** sur un ennemi ; puis, séparément, une vraie carte Attaque sur un ennemi.
- **Faire** : jouer les signatures indiquées.
- **Attendu** : (Flux de Mana) la troisième Compétence jouée, signatures comprises, rend 1 Mana pour le tour en cours (Surtension, déjà +1 Mana, ne perturbe pas le décompte : 3 Compétences au total comptées). (Soif de Sang) jouer Frappe Téméraire arme le Vol de Vie 2 tours : les cartes de dégâts suivantes soignent (1 PV par carte de dégâts, plus 1 par quart de PV manquants). (Marque du Mage) **Projectile Magique ne rend pas la cible Vulnérable** ; la première vraie Attaque du tour, elle, la rend Vulnérable 2 tours.
- **Ne doit pas changer** : Rage, Régénération d'armure, Bénédiction, Canalisation, Ferveur et Frénésie se comportent comme avant ; le décompte des Compétences de Flux de Mana repart à zéro à chaque combat.
- **Résultat** : ✅ · ❌ · non testé —

## T5 — Reliques : une signature jouée compte
- **Atteindre la situation** : sur la carte du monde, onglet « Reliques » du debug, ajouter l'une des quatre reliques ; entrer en combat, Mana plein. Une relique à la fois, sur la classe voulue.
  - **Amulette du Mage** (+1 Armure par carte jouée) : jouer n'importe quelle signature.
  - **Plume de scribe** (toutes les 5 cartes jouées : +3 Puissance ce tour) : jouer 5 cartes ou signatures en un tour ; compter les signatures dans les 5 (ex. 2 signatures + 3 cartes).
  - **Shuriken** (toutes les 3 Attaques jouées dans un tour : +1 Puissance pour le combat) : Paladin, Châtiment (Attaque) comme une des trois.
  - **Croc Kunaï** (toutes les 3 Attaques jouées dans un tour : +1 Maîtrise pour le combat) : idem.
- **Faire** : jouer les signatures de type Attaque / n'importe quelle signature, selon la relique, et compléter avec des cartes de la main.
- **Attendu** : Amulette : +1 Armure en plus des effets de la signature. Plume : le compte monte avec les signatures, +3 Puissance au cinquième. Shuriken / Kunaï : Châtiment compte comme une Attaque ; la troisième Attaque du tour donne +1 Puissance / +1 Maîtrise (la Compétence Bouclier Sacré n'y compte pas).
- **Ne doit pas changer** : les autres reliques ; le compte des reliques « par tour » repart à zéro à chaque tour.
- **Résultat** : ✅ · ❌ · non testé —

## T6 — La barre : emplacement et stabilité
- **Atteindre la situation** : combat Paladin, fenêtre large (au moins 600 px).
- **Faire** : observer la barre ; armer puis désarmer Châtiment plusieurs fois ; ouvrir le panneau des statuts s'il y en a (appliquer un statut au héros par un combat ou une carte).
- **Attendu** : la barre est à **gauche**, à **mi-hauteur** de l'écran, deux **boutons larges** de **220 px** l'un sous l'autre (médaillon de coût, nom entier, type à sa couleur, description de l'effet), **au-dessus du panneau des statuts** (le panneau ne capte pas les touchers de la tuile du bas) ; elle fait miroir du bouton de fin de tour. En armant, **aucune tuile ne bouge** : l'invite « Choisissez une cible » pend sous la colonne, sans la déplacer. Une classe n'a pas de barre si le héros est mort.
- **Ne doit pas changer** : le bouton de fin de tour, le panneau des statuts, la main, l'indicateur de mana ; l'infobulle de carte passe toujours au-dessus de la barre.
- **Résultat** : ✅ · ❌ · non testé —

## T7 — Le compte de recharge
- **Atteindre la situation** : combat de n'importe quelle classe, Mana 3 ; jouer une signature.
- **Faire** : observer la tuile jouée tout de suite, puis après avoir fini le tour (phase ennemie comprise), puis au tour suivant. Répéter en français puis en anglais si la langue se change ; essayer Frappe Téméraire ou Projectile Magique (noms longs).
- **Attendu** : sous la description, la tuile jouée affiche un sablier et **« 2 tours »** sur une ligne, puis, au tour suivant, **« 1 tour »** (singulier), puis la ligne disparaît et la tuile redevient disponible au tour d'après. Le nom reste entier ; rien ne se chevauche, rien ne déborde. En recharge : fond gris, bordure grise, nom, type et description grisés.
- **Ne doit pas changer** : le médaillon de coût en haut à gauche ; pas de liseré de couleur à gauche.
- **Résultat** : ✅ · ❌ · non testé —

## T8 — Reprise de run : les signatures sont gardées
- **Atteindre la situation** : run Paladin, après au moins un combat, sur la carte du monde.
- **Faire** : quitter l'application ou revenir à l'accueil, puis « Continuer » ; entrer dans un combat. Répéter avec un Berserker et un Mage.
- **Attendu** : la barre montre les signatures de la classe (Bouclier Sacré, Châtiment pour le Paladin), toutes disponibles, avec leurs coûts d'origine ; le deck sauvegardé n'en contient aucune (voir le deck depuis la carte du monde).
- **Ne doit pas changer** : or, PV, reliques, deck, position sur la carte après reprise.
- **Résultat** : ✅ · ❌ · non testé —

## T9 — Les cinq états de la tuile
- **Atteindre la situation** : combat Paladin ; pour le mana, onglet Combat > « Mana ».
- **Faire** : observer une tuile dans chaque état. Disponible : Mana suffisant (tuile avec lueur de la couleur de classe). En recharge : après avoir joué Bouclier Sacré. Mana insuffisant : Mana 0 (onglet Combat), tuile disponible. Armée : toucher Châtiment avec Mana suffisant. Inactive : pendant la phase ennemie ; après la victoire (« Gagner le combat ») sans quitter l'écran. Vérifier aussi la priorité : une signature en recharge **et** sans mana se montre en recharge ; armée puis mana tombé à 0 se montre « mana insuffisant ».
- **Attendu** : hors recharge et hors mana insuffisant, toutes les tuiles ont le même fond neutre, quel que soit le type, sans liseré à gauche ; disponible = lueur de classe ; en recharge = fond gris sombre, bordure grise, compte ; mana insuffisant = tuile grisée comme en recharge (fond et bordure gris, textes pâles), médaillon de coût rouge, sans compte ; armée = bordure de 3 px pulsante vers le blanc ; inactive = opacité réduite (≈ 45 %), sans réaction au toucher.
- **Ne doit pas changer** : toucher une tuile en recharge ou inactive ne joue rien, ne secoue rien, ne fait aucun son.
- **Résultat** : ✅ · ❌ · non testé —

## T10 — Aucune signature dans les piles, la fusion, la boutique, les récompenses ; ne s'épuisent pas
- **Atteindre la situation** : run Paladin (puis Mage pour Surtension de Mana) sur quelques combats ; la carte du monde propose repos, boutique, fusion (écran du deck).
- **Faire** : (1) consulter le deck complet hors combat ; (2) en combat, regarder les piles de pioche et de défausse (compteurs, listes si affichées) après avoir joué des signatures ; (3) jouer Bouclier Sacré (Paladin) et Surtension de Mana (Mage), puis regarder la pile d'exil ; (4) ouvrir une boutique ; (5) gagner un combat et regarder les cartes proposées en récompense et dans le draft de niveau ; (6) ouvrir l'écran de fusion.
- **Attendu** : aucune signature n'apparaît nulle part (ni deck, ni pioche, ni défausse, ni exil, ni boutique, ni récompenses, ni fusion) ; une signature jouée ne rejoint aucune pile ; **Bouclier Sacré et Surtension de Mana ne s'épuisent plus** : elles reviennent disponibles après leur recharge, le combat suivant comme au tour suivant ; les compteurs de pioche/défausse ne bougent pas à cause d'elles (hors la carte piochée par Surtension, Posture de Rage, Projectile Magique).
- **Ne doit pas changer** : la taille du deck, le prix des cartes, les récompenses d'or et de reliques.
- **Résultat** : ✅ · ❌ · non testé —

## T11 — Bouclier Sacré (sans cible)
- **Atteindre la situation** : combat Paladin, PV inférieurs au max (onglet Combat > PV), Mana 3, Armure 0, Puissance 0.
- **Faire** : toucher la tuile Bouclier Sacré.
- **Attendu** : il se joue **immédiatement**, sans armement : Armure +8, PV +2 (jusqu'au maximum), Mana 3 → 2, animation de type buff (aura), son de carte joué, la tuile passe en « 2 tours ». Aucun ennemi n'est requis ni ciblé.
- **Ne doit pas changer** : la main (même nombre de cartes), le nombre de cartes jouées du tour pour la fin de tour.
- **Résultat** : ✅ · ❌ · non testé —

## T12 — Mana insuffisant : secousse et son
- **Atteindre la situation** : combat Berserker, onglet Combat > Mana à 1 (Frappe Téméraire coûte 2).
- **Faire** : toucher la tuile Frappe Téméraire.
- **Attendu** : avant le toucher, la tuile est **grisée** (fond et bordure gris, textes pâles), son médaillon de coût est rouge, et le survol ne la fait ni grossir ni s'illuminer (curseur flèche). Au toucher, la tuile **secoue** (≈ 250 ms, quatre allers-retours de 5 px) et le son « mana insuffisant » est joué, comme pour une carte inabordable ; la tuile n'arme pas ; le mana n'est pas dépensé ; l'avertissement de mana (indicateur) réagit comme avec une carte. Avec Mana 0, la tuile à coût 0 (Surtension de Mana, Mage) reste jouable.
- **Ne doit pas changer** : la recharge n'est pas posée ; aucune invite « Choisissez une cible ».
- **Résultat** : ✅ · ❌ · non testé —

## T13 — Berserker et Mage : leurs signatures
- **Atteindre la situation** : une run Berserker, puis une run Mage ; combat, Mana plein, Puissance 0, un ennemi au moins.
- **Faire** : Berserker : Frappe Téméraire (arme, toucher l'ennemi), puis Posture de Rage au tour suivant ou avec le mana restant. Mage : Projectile Magique (arme, toucher l'ennemi), Surtension de Mana.
- **Attendu** : Frappe Téméraire : coût 2, 15 dégâts à l'ennemi touché, animation de corps à corps. Posture de Rage : coût 1, +2 Puissance ce tour-ci, 1 carte piochée ; une Attaque jouée ensuite fait 2 de plus. Projectile Magique : coût 1, 5 dégâts, 1 carte piochée, animation magique ; il compte comme **Compétence** (la Puissance du Mage s'applique à lui). Surtension de Mana : coût 0, +1 Mana et 1 carte piochée. Chaque signature passe en « 2 tours » après son jeu.
- **Ne doit pas changer** : les cartes de la main et leurs effets ; le passif de la classe.
- **Résultat** : ✅ · ❌ · non testé —

## T14 — Le survol d'une signature, sans infobulle
- **Atteindre la situation** : combat Paladin (souris), puis, si possible, un écran tactile pour l'appui long.
- **Faire** : survoler une tuile puis la quitter ; maintenir un appui long sur une tuile puis relâcher ; survoler une tuile pendant qu'une autre est armée.
- **Attendu** : au survol, une tuile disponible ou armée grossit légèrement (ancrée à gauche, en un dixième de seconde), sa lueur de classe s'intensifie et le curseur devient une main ; elle revient à sa taille en sortant, ou dès que le tour ennemi commence ; une tuile en recharge, sans le mana ou inactive ne réagit pas (curseur flèche) ; l'autre tuile ne bouge pas. Aucune infobulle ne s'ouvre, dans aucun état de la tuile ; un appui long, une fois relâché, agit comme un toucher (il joue ou arme une tuile disponible) ; les informations se lisent sur la tuile elle-même (nom, type, description, recharge).
- **Ne doit pas changer** : l'infobulle d'une carte de la main (titre, description, couleur) ; sa disparition au retrait de la souris.
- **Résultat** : ✅ · ❌ · non testé —

## T15 — La recharge repart à zéro au combat suivant
- **Atteindre la situation** : combat Paladin ; jouer Bouclier Sacré et Châtiment (recharge en cours), puis « Gagner le combat » (onglet Combat) et passer au combat suivant.
- **Faire** : entrer dans le combat suivant ; aussi : fuir ou perdre ne doit pas être testé ici.
- **Attendu** : toutes les tuiles sont **disponibles** dès le premier tour, sans compte ; aucun reste de la recharge du combat précédent.
- **Ne doit pas changer** : le mana, l'armure et les statuts repartent comme avant (mana plein, armure 0).
- **Résultat** : ✅ · ❌ · non testé —

## T16 — Boutons de 170 px sous 600 px
- **Atteindre la situation** : combat dans une fenêtre redimensionnée à moins de 600 px de large (ou un émulateur étroit).
- **Faire** : observer la barre ; jouer une signature, observer le compte ; armer Châtiment ; passer de la largeur étroite à la largeur large pendant le combat.
- **Attendu** : boutons de **170 px** de large sous 600 px, **220 px** au-delà ; nom, type, description (deux lignes au plus) et compte « 2 tours » lisibles, sans chevauchement ni débordement ; l'invite ne fait pas sauter les tuiles.
- **Ne doit pas changer** : le reste du HUD reste utilisable, sans chevauchement avec la barre.
- **Résultat** : ✅ · ❌ · non testé —

## T17 — Le draft de départ
- **Atteindre la situation** : nouvelle partie, choisir une classe, arriver au draft du deck de départ.
- **Faire** : parcourir le pool, sélectionner 5 cartes, valider (« ENTRER DANS L'UMBRA »).
- **Attendu** : le pool est le pool commun offrable ; **aucune signature ni aucune carte spécifique de classe** ; il faut sélectionner exactement 5 cartes (compteur « Cartes sélectionnées : n / 5 », message à la 6e) ; le deck de départ compte 5 cartes ; en combat la barre montre les signatures de la classe, en plus. Le sous-titre du draft n'a pas changé (il parle toujours de « cartes globales », volontairement).
- **Ne doit pas changer** : le tri et l'affichage des cartes, la transition vers la carte du monde.
- **Résultat** : ✅ · ❌ · non testé —

## T18 — Le tutoriel
- **Atteindre la situation** : lancer le tutoriel depuis l'accueil.
- **Faire** : lire l'étape « Votre deck de départ », le bandeau du draft du tutoriel, puis, plus loin, l'étape « La Fusion de Cartes » ; essayer en français et en anglais.
- **Attendu** : l'étape « Votre deck de départ » explique les 5 cartes du pool commun puis les deux **signatures** (« qui ne sont pas des cartes : jamais piochées, elles ne fusionnent pas… barre à gauche de l'écran, dès le premier tour… se recharge quelques tours »). Le bandeau du draft du tutoriel affiche « Vos signatures, toujours disponibles en combat : Bouclier Sacré, Châtiment » (noms de la classe choisie ; « Your signatures, always available in combat: … » en anglais). **La phrase sur les cartes de classe uniques a disparu de l'étape de la Fusion** (plus de « cartes de classe sont uniques » ni « Ajoutées automatiquement »).
- **Ne doit pas changer** : le déroulé du tutoriel (étapes, ordre, combats guidés), la fusion elle-même.
- **Résultat** : ✅ · ❌ · non testé —

## T19 — La carte de classe à la sélection
- **Atteindre la situation** : nouvelle partie, écran de sélection de classe.
- **Faire** : parcourir chaque classe.
- **Attendu** : sur chaque carte, un bloc « **Signatures** » entre la Puissance et la description de la classe, avec pour chacune des deux signatures nom, coût, recharge, description (ex. Paladin : Bouclier Sacré 1 Mana · Recharge 2 tours — « Donne 8 d'Armure et soigne 2 PV. » ; Châtiment — « Inflige 6 dégâts et donne 4 d'Armure. »). Les deux tuiles occupent toute la largeur de la carte, avec le même fond neutre, ni rouge ni bleu, sans liseré à gauche, bordées de la couleur de la classe.
- **Ne doit pas changer** : le bloc de la Puissance, le passif, la description, le choix de la classe.
- **Résultat** : ✅ · ❌ · non testé —

## T20 — L'onglet « Signatures » du dictionnaire
- **Atteindre la situation** : accueil, « Dictionnaire des Cartes ».
- **Faire** : parcourir les trois onglets, puis les classes de l'onglet Signatures.
- **Attendu** : l'onglet « Signatures » est le **troisième**, après « Cartes » et « Reliques » ; il est groupé **par classe** ; chaque tuile montre nom, coût, recharge, description **et le type** (Attaque / Compétence : Châtiment et Frappe Téméraire = Attaque ; les quatre autres = Compétence). Les onglets Cartes et Reliques ne contiennent aucune signature.
- **Ne doit pas changer** : l'ordre et le contenu des onglets Cartes et Reliques.
- **Résultat** : ✅ · ❌ · non testé —

## T21 — L'éditeur de contenu (debug)
- **Atteindre la situation** : build debug, menu de debug de l'accueil, éditeur de contenu.
- **Faire** : choisir la catégorie « Signature » ; lister ses entrées, ouvrir « Châtiment », créer une signature sur la classe Paladin (id en snake_case, noms FR/EN) puis l'abandonner sans enregistrer, ou la supprimer ensuite à la main ; essayer la création d'une classe (nombre de signatures).
- **Attendu** : « Signature » figure parmi les catégories (à côté de Carte, Relique, Passif…) ; les entrées existantes (six) sont listées et se chargent ; le propriétaire (la classe) est un champ du formulaire ; une signature sans nom ou en doublon est refusée avec un message ; une carte neutre portant un `heroClass` est refusée ; la création d'une classe peut entraîner ses signatures en un geste. Toute écriture se fait sous `assets/data/classes/<classe>/skills/`.
- **Ne doit pas changer** : les autres catégories de l'éditeur ; les fichiers existants si rien n'est enregistré.
- **Résultat** : ✅ · ❌ · non testé —

## Ce qui doit rester inchangé
- Le jeu d'une carte de la main : coût, cible, dégâts, animation, son, mise en défausse ou en exil.
- Le glisser-déposer d'une carte vers un ennemi, et la sélection d'un ennemi par une carte.
- Le bouton de fin de tour, la phase ennemie, la pioche de début de tour et le mana de début de tour.
- Les cartes, passifs, reliques et événements existants (hors les trois changements de type : Projectile Magique devenu Compétence, Bouclier Sacré et Surtension de Mana non épuisantes).
- Le menu de debug : mêmes onglets, même contenu (en combat : « Combat » seul ; hors combat : « Heros », « Run », « Deck », « Reliques »).
- La boutique, les récompenses, le repos, les événements, la forge et la fusion (hors la disparition des cartes de classe).
- L'écran de mort, le menu de pause, la reprise de run (hors les signatures, qui reviennent par la classe).
- Les textes de l'écran de draft de départ (sous-titre et boutons).

## Défauts trouvés
| # | Test | Ce qui a été vu | Gravité ressentie | Corrigé par |
|:---:|:---|:---|:---|:---|
