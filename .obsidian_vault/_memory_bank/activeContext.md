<!-- last-sync: 2026-11-15 | commit: 074d53ac -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La vague 6 du programme P-43 → P-42 → P-44 lot 1 est livrée sur sa branche,
`feat/v0.5.8-p42-tranche-2`, et attend le propriétaire** : son test manuel, la PR, la fusion dans
`main`, puis le tag. Elle porte **la tranche 2 de P-42** « Catalogue par lots de passif » : trois
lots de cinq cartes — Croisé, Vampire, Voile — qui rouvrent *Ferveur*, *Soif de Sang* et
*Canalisation*, et **la banque de mana de *Canalisation*** (D30,
[ADR-116](../_adr/ADR-116-canalisation-une-banque-de-mana.md), qui complète ADR-105). **Rien n'en est
fusionné ni publié** : `main` reste à `df1b671d`, et ce que le vault dit de la vague 6 n'y deviendra
vrai qu'à la fusion. **Premier lot « sans spec »** (R31, à l'essai) : les « Décisions de
conception » du [plan](../../docs/superpowers/plans/2026-11-15-p42-tranche-2.md) en tiennent lieu.
Le [compte rendu de la vague](../../docs/superpowers/reports/2026-11-15-economie-et-catalogue-vague-6-compte-rendu.md)
porte les chiffres (§1), les arbitrages A1 à A15 et les décisions de SDD S1 à S6 (§2) et la file
(§4) ; sa fin — §0, §3, §5, §6 et le fichier de tests manuels voisin, dont le plan §8 prépare les
points M1 à M14 — s'écrit à la fin de la vague (orchestration §3.8). **P-42 reste ouvert dans
`docs/ROADMAP.md`** : la tranche 3 vient en vague 8. **Un arbitrage que le propriétaire renverse se
corrige sur la branche avant la fusion.**

**La vague 5 est close** : fusionnée dans `main` le 2026-11-09 par la PR #51 (commit de fusion
`fbfa839a`), taguée `v0.5.7` sur ce commit, `release.yml` run `42538736623` vert — constatée par la
porte d'entrée de la vague 6 (`b8e0641b`) et re-vérifiée par `gh` à cette synchronisation.
ADR-110 à ADR-115 sont désormais vrais sur `main`. Entre la fusion et la vague 6, `main` a reçu,
hors programme, la chaîne pixel art des créatures et le skill `/workflow-creature` (PR #52), puis
la méthode R31 à l'essai et les maquettes de la réserve de mana (PR #53, `df1b671d`).

**La méthode est celle d'[ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
amendée par [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md),
[ADR-108](../_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md),
[ADR-110](../_adr/ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md) et
[ADR-113](../_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md).** **Deux documents font
foi, et ne se recopient pas** : le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
pour le *déroulé* et le
[brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md)
pour les *décisions de conception*.

Réserves à ne pas perdre de vue :

- **Ce que la vague 6 laisse ouvert**, consigné au compte rendu §4 et dans ADR-116 :
  `effect_line_texts.dart` n'a pas de phrase pour `mana_regen` (à écrire quand une signature
  posera le statut) ; `'status:${statusId}'` s'écrit dans `forge_rune_rules.dart`,
  `passive_feeds.dart` et `EffectKind.of`, à factoriser à la quatrième lectrice ; au tutoriel, sans
  couple attaque + Armure qui tienne dans le mana, la main d'avant est gardée ; la garde
  `if (preview == null) return;` de `ManaReservePassive` est inatteignable ; seize cristaux ou plus
  feraient déborder le HUD sous *Canalisation*. **Les flèches, la légende et le message de fin de
  tour ne sont gardés par aucun test** (D77) : seuls leurs calculs le sont, `preview` et `shown` ;
  l'écran va au test du propriétaire.
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
  Magique* : D34 passe en **vague 8** depuis D76 ; le passif reste masqué jusque-là, comme
  *Bénédiction* et *Frénésie*.
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
  `assets/data/patch_notes.json`, jamais ici.** Sur la branche de la vague 6, les trois porteurs de
  version portent déjà la sienne (`074d53ac`), **ni taguée ni publiée** ; sur `main`, celle de la
  vague 5, publiée. Les versions que visent les vagues font foi dans le fichier d'orchestration, §1.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Si `gh`
  ne joint pas l'API à une porte d'entrée, c'est le propriétaire qui confirme, et le journal le
  note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Vague 6 — P-42 tranche 2 : Croisé, Vampire, Voile, et la banque de mana de *Canalisation***
   (2026-11-15, branche `feat/v0.5.8-p42-tranche-2`, 12 commits `b8e0641b` → `074d53ac` sur `main`
   à `df1b671d` — **livrée sur la branche, vague 6 du fichier d'orchestration, en attente du test,
   de la PR, de la fusion et du tag du propriétaire**) — **six passifs sur neuf se jouent.**
   **Trois lots de cinq cartes**, toutes communes, rangés sous `cards/<passif>/` : **Croisé**
   (*Ferveur*, Paladin) — cinq Attaques, trois qui donnent de l'Armure, deux multi-coups à
   `mightRatio` 0,75 ; **Vampire** (*Soif de Sang*, Berserker) — cinq Attaques, trois qui piochent,
   *Lacération* à 0 qui s'épuise, *Frénésie sanglante* à 1 mana qui grandit avec les cartes jouées
   ce tour ; **Voile** (*Canalisation*, Mage) — Pouvoirs durables et Compétences à 3, courbe
   1-2-3-3-3. Leur arrivée **démasque leurs passifs par la donnée** (O5), sans code ; le Mage
   démarre de nouveau sur *Canalisation*. **La banque de mana** (D30) : à la fin du tour, le mana
   non dépensé passe en réserve, jusqu'au Mana max + Maîtrise, et le tour suivant commence avec
   — `RunState.manaReserve`, jamais sauvegardée ; un seul calcul, `ManaReserve.preview`, pour la
   stratégie et l'écran ; hors de `StatGains`. **À l'écran**, réponse C et D du propriétaire sur
   maquettes (15/11) : flèches sur les cristaux qui passeront en réserve, légende cyan « +n au
   prochain tour », message de fin de tour « n Mana en réserve », bordé de cyan ; Mage sous
   *Canalisation* seulement. **Un statut neuf**, `mana_regen` (*Source de Mana*), posé par
   *Méditation* ; *Persistant* et *Résonant* le refusent par `excludesEffects`, qui lit désormais
   `status:<id>` (D44). **Deux corrections de la revue d'ensemble** : la main de l'étape « Jouer des
   cartes » du tutoriel tient dans le Mana max ; la légende de la réserve quitte le combat fini.
   Une question P, A14 — l'affichage de la réserve —, tranchée par le propriétaire sur maquettes
   le 15/11 (`df1b671d`) ; T1.1, rendue P par le vérificateur, reclassée T. Note de version écrite (`074d53ac`). **1682 tests** (+62 sur la base de **1620**, celle
   de la porte d'entrée), `dart analyze` propre (**vérifié le 2026-11-15**) —
   [ADR-116](../_adr/ADR-116-canalisation-une-banque-de-mana.md).
2. **Vague 5 — P-42 tranche 1 et P-44 lot 1 : les lots de cartes par passif, la profondeur, les
   évolutions de signature** (2026-10-25 → 2026-11-04, branche
   `feat/v0.5.7-p42-tranche-1-p44-lot-1`, 81 commits `da233ba6` → `22da17b5` sur `main` à
   `d99cd815` — **fusionnée dans `main` le 2026-11-09 par la PR #51, merge `fbfa839a`, taguée
   `v0.5.7`, CI/CD verte**) — **le deckbuilding existe.** **Partie 1,
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
3. **Vague 4 — P-43 lot E4 : les signatures en compétences de classe** (2026-10-15 → 2026-10-16,
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

> [!NOTE]
> **Rotations.** Sortie le 2026-11-15, dans `../_archive/` : `2026-11-15-activeContext-livraisons.md`
> (la vague 3, P-43 lot E3). Sortie le 2026-11-04 : `2026-11-04-activeContext-livraisons.md`
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

**D'abord le propriétaire, sur la vague 6** : une fois la fin de vague écrite (orchestration
§3.8) — dont le fichier de tests manuels, qui reprend les points M1 à M14 du
[plan](../../docs/superpowers/plans/2026-11-15-p42-tranche-2.md) §8, du plus au moins risqué —, il
le joue, lit la table des arbitrages du
[compte rendu](../../docs/superpowers/reports/2026-11-15-economie-et-catalogue-vague-6-compte-rendu.md)
(§2), ouvre la PR de `feat/v0.5.8-p42-tranche-2`, la fusionne dans `main`, puis pose le tag de la
version sur le commit de fusion (ADR-103 D1). Une correction demandée se fait sur la branche, avant
la fusion.

**Puis la vague 7 du fichier d'orchestration** (sa version y est fixée, §1) : **les charges élémentaires** (P-53, D76,
[ADR-110](../_adr/ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md)) — le Gel, le Feu et la
Foudre qui s'accumulent jusqu'à un seuil qui les fait rompre. **Elle ne s'ouvre pas encore** : sa fiche, §8.7 de l'orchestration, est **à compléter
avant elle, dans une session de documentation**, pour que les règles des charges deviennent des
décisions du brainstorm. Elle se lancera ensuite dans une session neuve, **sous D77** — aucun test
d'écran —, et **sa porte d'entrée attendra le tag de la vague 6** : tag ancêtre de `main`, CI/CD
verte, constatée par `gh` — c'est elle qui notera la vague 6 close. La tranche 3 de P-42
(*Bénédiction*, *Frénésie*, *Marque du Mage*, D34) suit en vague 8.

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
