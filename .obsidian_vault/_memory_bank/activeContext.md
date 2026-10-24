<!-- last-sync: 2026-10-16 | commit: f42a25a -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La vague 4 du programme P-43 → P-42 → P-44 lot 1 est livrée sur sa branche,
`feat/v0.5.6-p43-e4-signatures`, et attend le propriétaire** : son test manuel, la PR, la fusion
dans `main`, puis le tag. Elle porte le dernier des cinq lots de P-43 « Économie unifiée », **E4 —
« les signatures en compétences de classe »** ([ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md)) :
les six signatures quittent les cartes pour `classes/<id>/skills/`, hors du deck, jouables dès le
premier tour de chaque combat depuis une barre à gauche du HUD, pour leur coût d'avant et une
recharge de deux tours ; la rareté `unique`, `isAcquirable`, `CardCategory` et `CardData.heroClass`
disparaissent avec elles. **Rien n'en est fusionné ni publié** : `main` reste à `848645b`, et tout
ce que le vault dit d'E4 n'y deviendra vrai qu'à la fusion. **P-43 est clos dans
`docs/ROADMAP.md`** avec ce lot. Le
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-16-economie-et-catalogue-vague-4-compte-rendu.md)
porte la table des arbitrages (§2) ; sa fin — §0, §1, §3 à §6, le cahier de test manuel en fichier
voisin et les statistiques de la session — s'écrit à la fin de la vague (orchestration §3.8). **Un
arbitrage que le propriétaire renverse se corrige sur la branche avant la fusion**, et ses
documents — note de version, ADR — se rouvrent en place tant que la vague n'est pas taguée.

**La vague 3 est close** : fusionnée dans `main` le 2026-10-04 par la PR #49 (commit de fusion
`0ec09ab`), taguée sur ce commit, CI/CD verte — `release.yml` run `37208776369` vert, release
publiée en pré-release le même jour —, constatée par la porte d'entrée de la vague 4 (`d0ac431`)
et re-vérifiée par `gh` à cette synchronisation. ADR-107 est désormais vrai sur `main`. Depuis,
`main` a reçu hors vague la méthode calibrée (ADR-108, merge `a296ef0`), deux classeurs de
référence et la note Superpowers 7.0.0 (`848645b`).

**La méthode est celle d'[ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
amendée par [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md)
et calibrée par [ADR-108](../_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md)** :
une vague par version, une session par vague ; les plans consignent des décisions, chaque question
a une classe T · P · D, **la simulation n'est plus relancée par une vague** — sur la branche de la
vague 4, elle ne tourne même plus : elle lit `classes/*/cards/`, renommé ; accepté, aucune ligne de
`tool/simulations/` n'a changé ([`_patterns/20-00`](../_patterns/20-00-simulation-de-l-economie-de-deck.md)).
**La vague 4 est l'essai mesuré** de cette méthode : la spec, puis le plan de la partie 2, ont
chacun arrêté la vague sur une question P (Q-P1 et Q-P2 le 15/10 ; P-2 le 16/10), chaque arrêt
levé par le propriétaire. **Deux documents font foi, et ne se recopient pas** : le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
pour le *déroulé* et le
[brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md)
pour les *décisions de conception*.

Réserves à ne pas perdre de vue :

- **Ce que la vague 4 laisse ouvert**, consigné dans ADR-109 et au compte rendu §2 : un deck de
  départ de 5 cartes pour 5 piochées par tour met tout le deck en main au premier combat ;
  `playSignature` ne vérifie pas que l'ennemi visé est présent, comme une carte (S4) ; l'ennemi
  visé par la dernière carte garde sa bordure ambre pendant qu'une signature est armée (S12) ; la
  glue Flame du ciblage n'a pas de banc de test ; *Marque du Mage* ne voit plus *Projectile
  Magique* jusqu'à D34 (vague 7). **Une partie en cours sous la version précédente ne reprend
  pas** : sa sauvegarde est effacée au chargement — la règle avant la `1.0.0`.
- **Ce que la vague 3 laisse ouvert**, consigné dans ADR-107 : le boss « XP » ne monte rien en
  début de run ; l'or dort (constat de P-16) ; le bonus de plafond est optionnel à défaut neutre
  sur les fonctions pures ; **à la file** : l'écart de « Butin de Reliques » de la fiche des
  probabilités, `DebugActions.gainLevel` qui peut donner deux niveaux, une garde de `sharpen_rune`
  sans cible, un placeholder `{floor}` — *Flux de Mana* écrit « jamais sous 2 » en dur.
- **Ce que la vague 2 laisse ouvert**, consigné dans ADR-106 : *Précis* au niveau 10 ajoute 50
  points de critique ; *Spectral* sur une carte qui s'épuise déjà, et la paire *Spectral* /
  *Persistant*, attendent les cartes de lot de la vague 5 ; le rendu Flame recalcule le coût
  courant à chaque image ; le libellé anglais « SHARPEN » du feu côtoie la récompense de niveau
  « Sharpening ».
- **Ce que la vague 1 laisse ouvert**, consigné dans ADR-104 et ADR-105 : les icônes de statut
  des ennemis supposent une entrée par `id` ; l'éligibilité des runes élémentaires ne lit pas la
  cible de la carte ; *Talisman de fer* et *Encensoir* ne donnent aucune Puissance au Berserker
  (défaut antérieur, à ouvrir en ticket).
- **Un test peut-être instable** : `test/widget/content_editor_screen_test.dart`, groupe des
  imports, a échoué une fois dans une suite complète pendant la vague 1 ; vert dans la suite
  complète de cette synchronisation. À surveiller.
- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`) : la seule étape de `SaveMigrator` migre `attaque` →
  `attackPower`, pas l'id de passif. La note de version reste le seul canal qui prévienne *avant*.
- **La version se lit dans `pubspec.yaml` et la 1ʳᵉ entrée de
  `assets/data/patch_notes.json`, jamais ici.** Sur la branche de la vague 4, les trois porteurs de
  version portent déjà la sienne (`f42a25a`), **ni taguée ni publiée** ; sur `main`, celle de la
  vague 3, publiée. Les versions que visent les vagues font foi dans le fichier d'orchestration, §1.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Si `gh`
  ne joint pas l'API à une porte d'entrée, c'est le propriétaire qui confirme, et le journal le
  note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Vague 4 — P-43 lot E4 : les signatures en compétences de classe** (2026-10-15 → 2026-10-16,
   branche `feat/v0.5.6-p43-e4-signatures`, 25 commits `d0ac431` → `f42a25a` sur `main` à
   `848645b` — **livrée sur la branche, vague 4 du fichier d'orchestration, en attente du test, de
   la PR, de la fusion et du tag du propriétaire**) — **les signatures ne sont plus des cartes.**
   Deux par classe, rangées sous `classes/<id>/skills/` et chargées comme `SignatureData` dans
   `registry.signatures`, hors de tout pool par construction : jamais piochées, défaussées,
   épuisées, offertes, copiées, fusionnées ni runées. **Jouables dès le premier tour de chaque
   combat**, depuis une barre à gauche du HUD — cinq états, une signature à cible unique s'arme
   puis se joue sur l'ennemi touché —, **pour leur coût d'avant et une recharge de 2 tours pour les
   six**, dérivée du compteur de tours (`CombatState.signaturesReadyOn`), jamais sauvegardée ;
   **l'épuisement disparaît**. **Jouées comme une carte de leur type** par une vue de carte et la
   suite commune extraite du jeu d'une carte : passifs et reliques les voient ; *Projectile
   Magique* devient Compétence (D28) et ne déclenche plus *Marque du Mage*. Le deck de départ est
   **les 5 cartes choisies**. **Disparaissent** : la rareté `unique`, `isAcquirable` —
   `copyableCards` est le deck entier —, `CardCategory`, `CardData.heroClass`, la réparation B5,
   le test de transition E3 → E4 ; le prédicat d'offre devient `CardData.isOfferable`, que **le
   draft de départ adopte**. L'éditeur de contenu gagne une neuvième catégorie ; la carte de classe
   un bloc « Signatures », le dictionnaire un onglet ; le tutoriel les enseigne par la prose seule.
   **La spec est prête au quatrième tour** ; la vague s'arrête deux fois sur une question P —
   Q-P1 et Q-P2 le 15/10, P-2 le 16/10 —, chaque arrêt levé par le propriétaire ; deux parties,
   chacune corrigée après sa revue d'ensemble (`a5a91ef`, `e434d0d`). Simulation non relancée
   (ADR-108 D5) ; elle ne tourne plus. Note de version écrite (`f42a25a`). **1694 tests** (+69 sur
   la base de **1625**, celle de la porte d'entrée), `dart analyze` propre (**vérifié le
   2026-10-16**) — [ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md), qui amende ADR-094 (D1,
   D2, D6), ADR-101 (D1, D3) et ADR-084 (D3, l'interdit de noms tient), et complète ADR-086 et
   ADR-100.
2. **Vague 3 — P-43 lot E3 : une carte après chaque combat, la main en stat de run, l'XP par acte,
   la difficulté sur les rangs, l'affûtage hors du feu** (2026-10-03 → 2026-10-04, branche
   `feat/v0.5.5-p43-e3-trouvaille`, 34 commits `9282513` → `b6abcb5` sur `main` à `bca35c5` —
   **fusionnée dans `main` le 2026-10-04 par la PR #49, merge `0ec09ab`, taguée, CI/CD verte,
   release publiée**) — **chaque combat rapporte une carte, et les fusions cessent
   d'être rares.** Après un combat normal, une carte commune tirée parmi celles que la classe peut
   recevoir entre au deck sans choix ; en élite, une seconde à 25 % ; deux reliques rares, le
   *Registre des primes* et la *Sacoche du glaneur*, le modulent. La carte bonus du boss « XP »
   disparaît : il **monte une rune** du deck d'un niveau, deux avec la *Meule*, relique légendaire ;
   le *Rémouleur*, un événement, en monte une contre 10 % des PV max ; une mythique,
   ***Transcendance***, relève de 1 le plafond d'un type de rune pour la run — *Économe 2* devient
   possible, et le nom dit le niveau. Le *Colporteur* échange la relique la plus faible contre de
   l'or, ou contre des soins sous la moitié des PV. **La main maximale devient une stat de run**,
   lue par les six chemins de pioche — la « pioche infinie » rapportée n'est pas reproduite après
   15 920 contrôles, ADR-078 D3 est amendé ; **le prix d'un niveau est une table par acte** dans
   `assets/data/xp_curve.json`, chargée par un `loadDocument` neuf, le palier dérivé de l'acte et
   jamais stocké ; **la difficulté adaptative lit 2 × Σ des rangs de fusion**, plus le nombre de
   cartes. *Sagesse* passe mythique ; *Bénédiction* et *Flux de Mana* lisent leurs seuils en
   donnée, et la Maîtrise affichée dit ce qu'elle change vraiment. **Trois corrections** :
   l'infobulle du boss d'XP disait « x2 » ; le retour système rejouait un événement dans le même
   nœud ; la fiche des probabilités affichait des chances qu'aucun tirage n'utilise. **La spec n'a
   convergé qu'au sixième tour** : trois arrêts de la vague, chacun levé par le propriétaire le
   2026-10-03 ; deux parties, la boucle puis les sources. La simulation, relancée en deux temps :
   réalignement à diff vide, puis la relique B, l'événement de D29 et la table d'XP du jeu relancés
   chacun à part, écarts expliqués, référence recommitée (`11410f3`). Note de version écrite
   (`b6abcb5`). **1625 tests** (+145 sur la base de **1480**, celle de la porte d'entrée), `dart
   analyze` propre (**vérifié le 2026-10-04**) — [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md),
   qui amende ADR-078 D3 et complète ADR-096, ADR-097 D3, ADR-098, ADR-099 D1, ADR-101, ADR-105 D7
   et ADR-106.
3. **Vague 2 — P-43 lot E2 : la fusion donne la rune, le feu affûte, le Puits échange, la boutique
   copie** (2026-10-02, branche `feat/v0.5.4-p43-e2-fusion-forge`, 27 commits `a9e2db6` → `82f902f`
   sur `main` à `559df08` — **fusionnée dans `main` le 2026-10-03 par la PR #48, merge `bca35c5`,
   taguée, CI/CD verte, release publiée**) — **la rune ne s'obtient plus au
   feu : elle naît de la fusion.** Chaque fusion 3 → 1 garde toutes les runes de ses trois
   exemplaires et en **offre une parmi trois**, au niveau 1, tirées au rang que la carte atteint ;
   une seule rune de chaque type par carte, *Véloce* et *Économe* à partir de la deuxième fusion
   (`minFusionRank`). Le feu de camp **affûte** : une rune gagne un niveau pour 50 or × son niveau.
   Le **Puits d'échange**, tous les trois actes, remplace la Forge de Fusion : une rune contre toute
   autre permise, aux deux tiers de son niveau, pour 50 or × le niveau donné. La boutique vend **la
   copie d'une carte du deck** et **retient son étal à son nœud** — la décision du propriétaire, à
   la levée de l'arrêt de la spec. Trois runes neuves, *Allégé*, *Précis*, *Spectral*, et trois
   sortes de delta. **Disparaissent** : la forge du feu — fentes, relances, fentes achetées, sa
   session dans `RunState` —, la capacité de runes, `pools`, `stackable`. Deux défauts antérieurs
   se ferment au passage : le second repos par le retour système, le retirage gratuit de l'étal.
   `ShopController` devient le premier Notifier du dossier des contrôleurs à écouter un autre
   provider (`ref.listen`, pas `ref.watch`). **La spec ne converge qu'au quatrième tour** : la
   troisième vérification a rendu deux constats moyens, la vague s'est arrêtée, le propriétaire a
   levé l'arrêt. La simulation, relancée en deux temps : le réalignement rend sa référence à
   l'identique, le *Spectral* du script aligné sur le jeu change 477 lignes sur 798, écart
   expliqué, référence recommitée. Note de version écrite (`4e4fa5c`). **1480 tests** (+105 sur la
   base de **1375**, celle de la porte d'entrée), `dart analyze` propre (**vérifié le
   2026-10-02**) — [ADR-106](../_adr/ADR-106-fusion-egale-forge.md), qui amende ADR-074, ADR-094,
   ADR-105 et ADR-067, et rend caducs ce qui restait d'ADR-025, ADR-039 D1 et D3, ADR-024 point 4.
> [!NOTE]
> **Rotations.** Sortie le 2026-10-16, dans `../_archive/` : `2026-10-16-activeContext-livraisons.md`
> (la vague 1, P-43 lots E0 et E1). Sortie le 2026-10-04, dans `../_archive/` : `2026-10-04-activeContext-livraisons.md`
> (le dossier du programme — brainstorm v3, revue, simulation, méthode par vagues). Sorties le
> 2026-10-02 : `2026-10-02-activeContext-livraisons-2.md` (le filtre de classe sur les pools
> d'offre) et `2026-10-02-activeContext-livraisons.md` (P-41 lot D partie 2). Sortie le 2026-10-01 :
> `2026-10-01-activeContext-livraisons.md` (P-41 lot D partie 1). Sortie le 2026-09-21 :
> `2026-09-21-activeContext-livraisons.md` (P-41 lot C partie 2). Sorties le 2026-09-20 :
> `2026-09-20-activeContext-livraisons-3.md` (P-41 lot C partie 1),
> `2026-09-20-activeContext-livraisons-2.md` (lot B partie 2) et
> `2026-09-20-activeContext-livraisons.md` (lot B partie 1, avec quatre réserves closes). Sorties
> le 2026-09-18 : `2026-09-18-activeContext-livraisons-2.md` (P-49) et
> `2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes portent le
> même nom, daté du 2026-09-17 au 2026-08-20.

## Prochaine étape

**D'abord le propriétaire, sur la vague 4** : une fois la fin de vague écrite (orchestration §3.8),
il joue le cahier de test du
[compte rendu](../../docs/superpowers/reports/2026-10-16-economie-et-catalogue-vague-4-compte-rendu.md),
lit la table des arbitrages (§2) — dont la forme de la barre, déléguée (A6, S7 à S12) —, ouvre la
PR de `feat/v0.5.6-p43-e4-signatures`, la fusionne dans `main`, puis pose le tag sur le commit de
fusion (ADR-103 D1). Une correction demandée se fait sur la branche, avant la fusion.

**Puis la vague 5 du fichier d'orchestration** : la tranche 1 de P-42 « Catalogue par lots de
passif » avec le lot 1 de P-44 — trois lots de cartes (Rempart, Sang, Arcaniste), les mécanismes
de profondeur, les évolutions de signature. Elle se lance dans une session neuve, et **sa porte
d'entrée attend le tag de la vague 4** : tag ancêtre de `main`, CI/CD verte, constatée par `gh` —
c'est elle qui notera la vague 4 close. Elle hérite d'ADR-109 : `SignatureInstance`, sur laquelle
elle écrira les évolutions (D19, D21, D54) ; `CardData.isOfferable` sans paramètre, à qui elle
donnera le passif actif ; l'appartenance d'une carte, à redonner par un champ injecté (Q10).

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**, laissée hors du lot D partie 2 de P-41 alors qu'elle pilote tout P-49.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
