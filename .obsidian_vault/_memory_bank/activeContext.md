<!-- last-sync: 2026-10-04 | commit: b6abcb5 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La vague 3 du programme P-43 → P-42 → P-44 lot 1 est livrée sur sa branche,
`feat/v0.5.5-p43-e3-trouvaille`, et attend le propriétaire** : son test manuel, la PR, la fusion
dans `main`, puis le tag. Elle porte le quatrième des cinq lots de P-43 « Économie unifiée », **E3 —
« trouvaille et progression »** ([ADR-107](../_adr/ADR-107-trouvaille-et-progression.md)) : une
carte après chaque combat, la main maximale en stat de run, le prix d'un niveau par acte en donnée,
la difficulté adaptative sur la somme des rangs de fusion, l'affûtage hors du feu — **les fusions
cessent d'être rares**. **Rien n'en est fusionné ni publié** : `main` reste à `bca35c5`, et tout ce
que le vault dit d'E3 n'y deviendra vrai qu'à la fusion. Le
[compte rendu de la vague](../../docs/superpowers/reports/2026-10-04-economie-et-catalogue-vague-3-compte-rendu.md)
porte la table des arbitrages, que le propriétaire lit au moment de son test (§2) ; le cahier de
test manuel et les statistiques de la session s'y ajoutent à la fin de la vague (orchestration
§3.8). **Un arbitrage qu'il renverse se corrige sur la branche avant la fusion**, et ses documents
— note de version, ADR — se rouvrent en place tant que la vague n'est pas taguée (orchestration
§3.10).

**La vague 2 est close** : fusionnée dans `main` le 2026-10-03 par la PR #48 (commit de fusion
`bca35c5`), taguée sur ce commit, CI/CD verte — `release.yml` run `37078474537` vert, release
publiée en pré-release le même jour —, constatée par la porte d'entrée de la vague 3 (`9282513`)
et re-vérifiée par `gh` à cette synchronisation. ADR-106 est désormais vrai sur `main`.

**La méthode est celle d'[ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
amendée par [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md)** :
une vague par version du jeu, une session par vague, un orchestrateur qui délègue et arbitre ; le
propriétaire teste, fusionne, puis tague ; la simulation se compare à sa sortie de référence ;
chaque vague laisse un compte rendu et une section non technique dans
`docs/suivi_vagues_chantier/`. **Deux documents font foi, et ne se recopient pas** : le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
pour le *déroulé* — vagues, versions, journal d'avancement — et le
[brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md)
pour les *décisions de conception*. `docs/ROADMAP.md` garde une ligne par chantier et ne bouge
qu'à la clôture d'une ligne — P-43 se clôt en vague 4.

Réserves à ne pas perdre de vue :

- **Ce que la vague 3 laisse ouvert**, consigné dans ADR-107 et au compte rendu §5 : le boss « XP »
  ne monte rien en début de run, faute de rune affûtable — les textes le disent d'avance ; l'or
  dort toujours (6 023 en médiane à l'acte 15 dans la simulation), constat de P-16 ; le bonus de
  plafond est optionnel à défaut neutre sur les fonctions pures, l'analyseur ne désigne donc pas
  l'écrivain de niveau neuf qui l'oublierait — les tests le gardent ; **à la file** : l'écart de la
  section « Butin de Reliques » de la fiche des probabilités (antérieur), `DebugActions.gainLevel`
  qui peut donner deux niveaux, une garde de `sharpen_rune` sans cible (inatteignable), un
  placeholder `{floor}` — *Flux de Mana* écrit « jamais sous 2 » en dur.
- **Ce que la vague 2 laisse ouvert**, consigné dans ADR-106 : *Précis* au niveau 10 ajoute 50
  points de critique ; *Spectral* sur une carte qui s'épuise déjà, et la paire *Spectral* /
  *Persistant*, attendent les cartes de lot de la vague 5 ; le rendu Flame recalcule le coût
  courant à chaque image ; le libellé anglais « SHARPEN » du feu côtoie la récompense de niveau
  « Sharpening ». Sa réserve « les fusions restent rares jusqu'à la vague 3 » est levée par E3.
- **Ce que la vague 1 laisse ouvert**, consigné dans ADR-104 et ADR-105 : les icônes de statut
  des ennemis supposent une entrée par `id` ; l'éligibilité des runes élémentaires ne lit pas la
  cible de la carte ; *Talisman de fer* et *Encensoir* ne donnent aucune Puissance au Berserker
  (défaut antérieur, à ouvrir en ticket).
- **Un test peut-être instable** : `test/widget/content_editor_screen_test.dart`, groupe des
  imports, a échoué une fois dans une suite complète pendant la vague 1 ; vert dans la suite
  complète de cette synchronisation. À surveiller.
- **⚠️ Les lots 1-2 de P-48 cassent toujours les sauvegardes antérieures à leurs ids de passifs en
  `snake_case`** (commit `7da5db2`). P-41 lot A a posé une chaîne de migration (`SaveMigrator`) et
  changé de clé de stockage (`run_save`, repli sur `run_save_v1`), mais sa seule étape migre
  `attaque` → `attackPower` : l'id de passif n'y est pas touché, et une partie d'avant `7da5db2` perd
  toujours son passif de classe au chargement, signalé par un `MissingSaveItem`. La note de version
  reste le seul canal qui prévienne *avant*.
- **La version se lit dans `pubspec.yaml` et la 1ʳᵉ entrée de
  `assets/data/patch_notes.json`, jamais ici.** Sur la branche de la vague 3, les trois porteurs de
  version portent déjà la sienne (`b6abcb5`), **ni taguée ni publiée** ; sur `main`, celle de la
  vague 2, publiée. Les versions que visent les vagues font foi dans le fichier d'orchestration, §1.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Le
  2026-10-01, `gh` a échoué une fois à joindre l'API GitHub depuis la session, puis a répondu.
  Si cela se reproduit à une porte d'entrée, c'est le propriétaire qui confirme, et le journal
  le note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Vague 3 — P-43 lot E3 : une carte après chaque combat, la main en stat de run, l'XP par acte,
   la difficulté sur les rangs, l'affûtage hors du feu** (2026-10-03 → 2026-10-04, branche
   `feat/v0.5.5-p43-e3-trouvaille`, 34 commits `9282513` → `b6abcb5` sur `main` à `bca35c5` —
   **livrée sur la branche, vague 3 du fichier d'orchestration, en attente du test, de la PR, de la
   fusion et du tag du propriétaire**) — **chaque combat rapporte une carte, et les fusions cessent
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
2. **Vague 2 — P-43 lot E2 : la fusion donne la rune, le feu affûte, le Puits échange, la boutique
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
3. **Vague 1 — P-43 lots E0 et E1 : la Puissance par source, le `ratio`, et le moteur de runes en
   donnée** (2026-10-01 → 2026-10-02, branche `feat/v0.5.3-p43-e0-e1`, 22 commits `0f56cd4` →
   `52cba87` sur `main` à `0ccacce` — **fusionnée dans `main` le 2026-10-02 par la PR #47, merge
   `559df08`, taguée, CI/CD verte, release publiée**) — **la Puissance garde la
   durée de ce qui la donne, et une rune devient un fichier.** *E0* : un statut retient sa source,
   et `addStatus` ne fusionne plus que même statut **et** même source — seule la Puissance en
   reçoit une ; *Forme Démoniaque* puis *Mur de Fer* donnent 7 ce tour-ci puis 2, au lieu de 12
   pendant quatre tours. La règle de classe gagne un `ratio` borné à ]0, 1] : le Berserker convertit
   la moitié de son Armure, arrondie au-dessus, et sa règle le dit en clair. *E1* : une rune
   déclare son effet en **deltas typés** (`percentBonus`, `addEffect`, `removeExhaust`), qu'un
   **applicateur unique**, `EffectiveCard`, calcule pour le moteur, les rendus de carte et le tutoriel ;
   son éligibilité par **un prédicat** lu dans la donnée, exclusions symétriques comprises ; son
   plafond par **`maxLevel`**, borné aux quatre endroits qui écrivent un niveau. *Tranchant* et
   *Endurci* passent à +15 % de la base, au moins +1 ; G1 fait gagner au moins 1 par fusion à tout
   chiffre que la rareté multiplie, G2 gèle la pioche et le mana ; les statuts des runes
   élémentaires fusionnent avec ceux de la cible ; le feu refuse une carte qui ne peut plus
   recevoir de rune. **La revue d'ensemble a trouvé un trou** — la fusion de cartes réunissait
   *Persistant* et *Économe*, que le prédicat interdit ensemble : corrigé avant la note (`ee814e9`).
   La simulation, relancée en un seul temps, rend sa référence à l'identique (compte rendu §4) :
   E0 et E1 n'y changent rien qu'elle lise. Note de version écrite (`52cba87`). **1375 tests** (+188
   sur la base de **1187**, re-mesurée sur `main` à `0ccacce`), `dart analyze` propre (**vérifié le
   2026-10-02**) — [ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md),
   [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md), qui amende ADR-094.
> [!NOTE]
> **Rotations.** Sortie le 2026-10-04, dans `../_archive/` : `2026-10-04-activeContext-livraisons.md`
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

**D'abord le propriétaire, sur la vague 3** : il joue le cahier de test du
[compte rendu](../../docs/superpowers/reports/2026-10-04-economie-et-catalogue-vague-3-compte-rendu.md),
une fois la fin de vague écrite (orchestration §3.8), lit la table des arbitrages (§2), ouvre la PR
de `feat/v0.5.5-p43-e3-trouvaille`, la fusionne dans `main`, puis pose le tag sur le commit de
fusion (ADR-103 D1). Une correction demandée se fait sur la branche, avant la fusion.

**Puis la vague 4 du fichier d'orchestration** : le lot E4 de P-43, le dernier — **les signatures
quittent le deck pour devenir des compétences de classe**, toujours disponibles, avec un temps de
recharge (D49, D41, D53). Elle se lance dans une session neuve, par le prompt unique du §0 de
l'orchestration, et **sa porte d'entrée attend le tag de la vague 3** : tag ancêtre de `main`,
CI/CD verte, constatée par `gh` — et c'est elle qui notera la vague 3 close. Elle hérite
d'ADR-107 : les signatures sont encore des cartes, exclues de la trouvaille par `unique`, sans rune
— le boss « XP » n'en trouve aucune à monter —, au rang 0 pour la difficulté adaptative ;
`signature_cards_transition_test.dart` le garde, et E4 les sort du deck sans que la trouvaille ni
la difficulté n'en voient la différence. Côté simulation, le script se compare à la référence
recommitée par la vague 3 (`11410f3`) ; son premier temps réaligne `classes/<id>/cards` →
`skills`. **P-43 se clôt dans `docs/ROADMAP.md` à cette vague.**

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**, laissée hors du lot D partie 2 de P-41 alors qu'elle pilote tout P-49.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
