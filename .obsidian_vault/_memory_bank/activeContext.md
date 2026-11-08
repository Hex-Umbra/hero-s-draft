<!-- last-sync: 2026-11-09 | commit: 8a5d92b9 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La vague 5 du programme P-43 → P-42 → P-44 lot 1 est livrée sur sa branche,
`feat/v0.5.7-p42-tranche-1-p44-lot-1`, et attend le propriétaire** : son test manuel, la PR, la
fusion dans `main`, puis le tag. Elle porte **la tranche 1 de P-42** « Catalogue par lots de
passif » et **le lot 1 de P-44** « Profondeur », en trois parties : le moteur et les cinq runes
([ADR-111](../_adr/ADR-111-profondeur-lot-1-couts-croissance-multi-coups-statuts-proportionnels.md)) ;
la forme C, les trois lots, le masquage des passifs sans lot et le draft de départ à deux quotas
([ADR-112](../_adr/ADR-112-forme-c-un-lot-de-cartes-par-passif.md)) ; les évolutions de signature
([ADR-114](../_adr/ADR-114-les-evolutions-de-signature.md)). **Une série de corrections du
propriétaire l'a suivie sur la même branche** (2026-11-04 → 2026-11-07, D78 à D82, [ADR-115](../_adr/ADR-115-le-choix-libre-des-evolutions-et-les-rideaux-de-la-carte.md)) :
le choix libre des évolutions, les deux signatures sur un écran, trois rideaux sur la carte, les
signatures dans Mon Deck. **Rien n'en est fusionné ni publié** :
`main` reste à `d99cd815`, et ce que le vault dit de la vague 5 n'y deviendra vrai qu'à la fusion.
**P-44 lot 1 est clos dans `docs/ROADMAP.md`** ; P-42 reste ouvert, deux tranches à venir. Le
[compte rendu de la vague](../../docs/superpowers/reports/2026-11-03-economie-et-catalogue-vague-5-compte-rendu.md)
porte les chiffres (§1), les arbitrages et les décisions de SDD S1 à S23 (§2) et la file (§4) ;
sa fin — §0, §3, §6 et le fichier de tests manuels voisin — s'écrit à la fin de la vague
(orchestration §3.8), en parallèle de cette synchronisation. **Un arbitrage que le propriétaire renverse se corrige sur la branche avant
la fusion.**

**Deux décisions de méthode sont nées pendant la vague**, chacune d'un arrêt :

- **D76** (03/11, [ADR-110](../_adr/ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md),
  qui amende ADR-102) : **le chantier gagne une vague** — les charges élémentaires (P-53) en vague
  7, `0.5.9` ; la tranche 3 en vague 8, toujours `0.6.0`. Les règles des charges restent à décider
  avant la vague 7 (fiche 8.7 de l'orchestration).
- **D77** (04/11, [ADR-113](../_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md), qui
  amende ADR-108) : **les tests gardent les calculs, les données, les contrôleurs et la
  sauvegarde ; plus aucun test d'écran** — ce qu'il aurait vérifié devient un point du fichier de
  tests manuels. Les tests d'écran existants ont été triés et supprimés (1916 → 1524), six règles
  laissées sans garde par le premier passage ayant été re-gardées
  ([rapport du tri](../../docs/superpowers/reports/2026-11-04-vague-5-tri-des-tests-d-ecran.md)).

**La vague 4 est close** : fusionnée dans `main` le 2026-10-24 par la PR #50 (commit de fusion
`d99cd815`), taguée `v0.5.6` sur ce commit, `release.yml` run `40107686574` vert, pré-release
publiée le même jour — constatée par la porte d'entrée de la vague 5 (`da233ba6`) et re-vérifiée
par `gh` à cette synchronisation. ADR-109 est désormais vrai sur `main`.

**La méthode est celle d'[ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
amendée par [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md),
[ADR-108](../_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md),
ADR-110 et ADR-113.** **Deux documents font foi, et ne se recopient pas** : le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
pour le *déroulé* et le
[brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md)
pour les *décisions de conception*.

Réserves à ne pas perdre de vue :

- **Ce que la vague 5 laisse ouvert**, consigné au compte rendu §4 et dans ses ADR : un `flatBonus`
  qui vise un effet absent de sa signature est accepté en silence ; `DraftScreen` se quitte par le
  retour système sans choisir ; l'éditeur accepte une carte à `costs.armor` sous un passif sans classe unique ;
  `ProportionalStatus`, sous `lib/game/`, est importé par `enemy_instance.dart` ; `takeDamage` n'a
  pas de test direct ; la croissance `targetStatus` nomme le statut en français dans la version
  anglaise ; `asCard` est recalculé à chaque lecture, `effectLines` couplé par l'ordre sans
  `assert`. **Les faces des cartes, les émojis des statuts ennemis et l'icône de *Précis*** ne
  lisent pas encore `effect_icons.json`, et **les infobulles des cartes** attendent leur reprise
  (PN12) — lignes de `docs/ROADMAP.md`. À 360 px de large, le compteur d'or de la barre de la carte
  chevauche « RELIQUES » et « CHANCES » dans le rendu de test — à confirmer sur un vrai téléphone
  (ADR-115). *Marque du Mage* ne voit toujours pas *Projectile
  Magique* : D34 passe en **vague 8** depuis D76 ; le passif est masqué jusque-là.
- **Ce que la vague 4 laisse ouvert**, consigné dans ADR-109 : `playSignature` ne vérifie pas que
  l'ennemi visé est présent (S4) ; l'ennemi visé par la dernière carte garde sa bordure ambre
  pendant qu'une signature est armée (S12) ; la glue Flame du ciblage n'a pas de banc de test.
  **Une partie de la vague 4 reprend sous la vague 5**, sans évolution et, sous un passif masqué,
  avec ce passif et des neutres seulement ; avant la `1.0.0`, rien ne garantit qu'une sauvegarde
  survive à une version.
- **Un test peut-être instable** : `test/widget/content_editor_screen_test.dart`, groupe des
  imports, a échoué une fois dans une suite complète pendant la vague 1 ; gardé par le tri de D77,
  vert dans la suite complète de cette synchronisation. À surveiller.
- **Ce que la vague 3 laisse ouvert**, consigné dans ADR-107 : le boss « XP » ne monte rien en
  début de run ; l'or dort (constat de P-16) ; **à la file** : l'écart de « Butin de Reliques » de
  la fiche des probabilités, `DebugActions.gainLevel` qui peut donner deux niveaux, une garde de
  `sharpen_rune` sans cible, un placeholder `{floor}`.
- **Ce que les vagues 1 et 2 laissent ouvert**, consigné dans ADR-104 à ADR-106 : *Précis* au
  niveau 10 ajoute 50 points de critique ; *Spectral* sur une carte qui s'épuise déjà ; le rendu
  Flame recalcule le coût courant à chaque image ; les icônes de statut des ennemis supposent une
  entrée par `id` ; *Talisman de fer* et *Encensoir* ne donnent aucune Puissance au Berserker.
- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`) : la seule étape de `SaveMigrator` migre `attaque` →
  `attackPower`, pas l'id de passif.
- **La version se lit dans `pubspec.yaml` et la 1ʳᵉ entrée de
  `assets/data/patch_notes.json`, jamais ici.** Sur la branche de la vague 5, les trois porteurs de
  version portent déjà la sienne (`22da17b5`, note corrigée en `8a5d92b9`), **ni taguée ni publiée** ; sur `main`, celle de la
  vague 4, publiée. Les versions que visent les vagues font foi dans le fichier d'orchestration, §1.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Si `gh`
  ne joint pas l'API à une porte d'entrée, c'est le propriétaire qui confirme, et le journal le
  note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Vague 5 — P-42 tranche 1 et P-44 lot 1 : les lots de cartes par passif, la profondeur, les
   évolutions de signature** (2026-10-25 → 2026-11-04, branche
   `feat/v0.5.7-p42-tranche-1-p44-lot-1`, 81 commits `da233ba6` → `22da17b5` sur `main` à
   `d99cd815` — **livrée sur la branche, vague 5 du fichier d'orchestration, en attente du test,
   de la PR, de la fusion et du tag du propriétaire**) — **le deckbuilding existe.** **Partie 1,
   le moteur** : une carte peut coûter des PV ou de l'Armure, sous une seule règle — jamais
   mortelle — et un seul débit ; grandir avec une source (`scaleWith`, six sources, arrondi bas) ;
   frapper plusieurs fois, la Puissance par coup au `mightRatio` ; Vulnérable, Faiblesse et Gel
   comptent leurs points (25 % par point, plafonds 4, 2, 3 — réponse P-1) ; un seul bonus de
   statut par résolution ; cinq runes de mécanisme, *Perforant*, *Vampirique*, *Ricochant*,
   *Résonant* — dont l'écho ne déclenche aucun événement (P-3) — et *Transfusion*. **Partie 2, la
   forme C** : chaque passif a son dossier `cards/<passif>/`, qui injecte `CardData.passive` ;
   trois lots de six cartes, Rempart, Sang, Arcaniste ; **un passif sans lot quitte la
   sélection** — un par classe, le Mage sur *Flux de Mana* ; `isOfferable` lit le passif actif ;
   le draft de départ prend 2 cartes du lot et 3 neutres ; *Focalisation* supprimée. **Partie 3,
   les évolutions** : tous les 5 niveaux, chaque signature gagne une évolution choisie parmi trois
   de son pool (3 mineures, 4 majeures), sur un écran à trois rouleaux ouvert par le rideau de la
   carte ; la tuile de combat passe en icônes, avec un badge et des puces, et déroule sa liste à
   l'appui long dans un calque (PN12 (d), P-5) ; une table d'icônes d'effet unique,
   `effect_icons.json` (P-6) ; une entrée de debug (P-7) ; la sauvegarde sous
   `signatureEvolutions`. **Puis une série de corrections du propriétaire** (D78 à D82) : plus de
   tirage, tout ce que le palier admet se choisit ; les deux signatures sur un seul écran ; un rideau
   par ce qui attend — bandeau et flèches, bandeau, médaillon ; les signatures évoluées en tête de
   Mon Deck ; plus de badge « Passifs » sans deuxième passif. **Quatre arrêts**, chacun levé par le propriétaire : P-1 à P-3 (25/10),
   PN12 et PN13 (03/11), P-5 et P-6 (03/11), D77 (04/11). **Deux décisions de méthode** : D76,
   une vague de plus (ADR-110) ; D77, plus de tests d'écran (ADR-113). Simulation non relancée
   (ADR-108 D5). Note de version écrite (`22da17b5`), corrigée sur place (`8a5d92b9`). **1620 tests** (−81 sur la
   base de **1701**, celle de la porte d'entrée ; le tri de D77 en a retiré 392), `dart analyze`
   propre (**vérifié le 2026-11-09**) — [ADR-110](../_adr/ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md)
   à [ADR-115](../_adr/ADR-115-le-choix-libre-des-evolutions-et-les-rideaux-de-la-carte.md).
2. **Vague 4 — P-43 lot E4 : les signatures en compétences de classe** (2026-10-15 → 2026-10-16,
   branche `feat/v0.5.6-p43-e4-signatures`, 25 commits `d0ac431` → `f42a25a` sur `main` à
   `848645b`, puis six retouches de la barre demandées par le propriétaire — **fusionnée dans
   `main` le 2026-10-24 par la PR #50, merge `d99cd815`, taguée `v0.5.6`, CI/CD verte, pré-release
   publiée**) — **les signatures ne sont plus des cartes.** Deux par classe, rangées sous
   `classes/<id>/skills/` et chargées comme `SignatureData` dans `registry.signatures`, hors de
   tout pool par construction : jamais piochées, défaussées, épuisées, offertes, copiées,
   fusionnées ni runées. **Jouables dès le premier tour de chaque combat**, depuis une barre à
   gauche du HUD — cinq états, une signature à cible unique s'arme puis se joue sur l'ennemi
   touché —, **pour leur coût d'avant et une recharge de 2 tours pour les six**, dérivée du
   compteur de tours (`CombatState.signaturesReadyOn`), jamais sauvegardée ; **l'épuisement
   disparaît**. **Jouées comme une carte de leur type** par une vue de carte et la suite commune
   extraite du jeu d'une carte : passifs et reliques les voient ; *Projectile Magique* devient
   Compétence (D28) et ne déclenche plus *Marque du Mage*. Le deck de départ est **les 5 cartes
   choisies**. **Disparaissent** : la rareté `unique`, `isAcquirable`, `CardCategory`,
   `CardData.heroClass`, la réparation B5, le test de transition E3 → E4 ; le prédicat d'offre
   devient `CardData.isOfferable`, que **le draft de départ adopte**. **La spec est prête au
   quatrième tour** ; la vague s'arrête deux fois sur une question P, chaque arrêt levé par le
   propriétaire. **1694 tests** à la fin de vague (+69 sur **1625**), **1701** à la fusion,
   `dart analyze` propre (**vérifié le 2026-10-16**) —
   [ADR-109](../_adr/ADR-109-signatures-hors-du-deck.md), qui amende ADR-094, ADR-101 et ADR-084.
3. **Vague 3 — P-43 lot E3 : une carte après chaque combat, la main en stat de run, l'XP par acte,
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

> [!NOTE]
> **Rotations.** Sortie le 2026-11-04, dans `../_archive/` : `2026-11-04-activeContext-livraisons.md`
> (la vague 2, P-43 lot E2). Sortie le 2026-10-16 : `2026-10-16-activeContext-livraisons.md`
> (la vague 1, P-43 lots E0 et E1). Sortie le 2026-10-04 : `2026-10-04-activeContext-livraisons.md`
> (le dossier du programme — brainstorm v3, revue, simulation, méthode par vagues). Sorties le
> 2026-10-02 : `2026-10-02-activeContext-livraisons-2.md` (le filtre de classe sur les pools
> d'offre) et `2026-10-02-activeContext-livraisons.md` (P-41 lot D partie 2). Sortie le 2026-10-01 :
> `2026-10-01-activeContext-livraisons.md` (P-41 lot D partie 1). Sortie le 2026-09-21 :
> `2026-09-21-activeContext-livraisons.md` (P-41 lot C partie 2). Sorties le 2026-09-20 :
> `2026-09-20-activeContext-livraisons-3.md`, `-2.md` et `2026-09-20-activeContext-livraisons.md`
> (P-41 lots C partie 1 et B). Sorties le 2026-09-18 : `2026-09-18-activeContext-livraisons-2.md`
> (P-49) et `2026-09-18-activeContext-livraisons.md` (P-41 lot A). Les onze rotations précédentes
> portent le même nom, daté du 2026-09-17 au 2026-08-20.

## Prochaine étape

**D'abord le propriétaire, sur la vague 5** : une fois la fin de vague écrite (orchestration
§3.8), il joue **le [fichier de tests manuels](../../docs/superpowers/reports/2026-11-04-economie-et-catalogue-vague-5-tests-manuels.md)**
de la vague, voisin du
[compte rendu](../../docs/superpowers/reports/2026-11-03-economie-et-catalogue-vague-5-compte-rendu.md)
— 41 points : ceux que les revues renvoient au test, M7 à M34 de la spec, préparés par l'entrée
de debug des évolutions, et ceux de la série de corrections, jusqu'à M41 pour les rideaux —, lit la table des arbitrages (§2), ouvre la PR de
`feat/v0.5.7-p42-tranche-1-p44-lot-1`, la fusionne dans `main`, puis pose le tag de la version sur
le commit de fusion (ADR-103 D1). Une correction demandée se fait sur la branche, avant la fusion.

**Puis la vague 6 du fichier d'orchestration**, `0.5.8` : **la tranche 2 de P-42** — trois lots,
Croisé (Paladin, *Ferveur*), Vampire (Berserker, *Soif de Sang*), Voile (Mage, *Canalisation*),
qui rouvrent leurs passifs. Elle se lance dans une session neuve, **sous D77** — aucun test
d'écran —, et **sa porte d'entrée attend le tag de la vague 5** : tag ancêtre de `main`, CI/CD
verte, constatée par `gh` — c'est elle qui notera la vague 5 close. Elle hérite d'ADR-112 : le lot
d'une tranche ouvre son passif sans code, et les `feeds` des passifs sans lot sont des valeurs de
départ qu'elle ajuste. **La vague 7 ne s'ouvre pas** tant que les règles des charges élémentaires
ne sont pas devenues des décisions du brainstorm (D76, fiche 8.7).

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
