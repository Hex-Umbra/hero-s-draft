<!-- last-sync: 2026-11-19 | commit: ee60f62f -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**La vague 8 du programme P-43 → P-42 → P-44 lot 1 est livrée sur sa branche,
`feat/v0.6.0-p42-tranche-3`, et attend le propriétaire** : son test manuel, la PR, la fusion dans
`main`, puis le tag. Elle porte **la tranche 3 de P-42, la dernière** : les lots Sanctifié
(*Bénédiction*), Carnage (*Frénésie*) et Marque (*Marque du Mage*) arrivent et **les neuf passifs sont
jouables** ; *Marque du Mage* se déclenche sur la première carte de dégâts du tour, Attaque ou
Compétence, à cible unique et vivante (D34, A3 (c), A4 (ii)) ; *Prière* pose un statut neuf, la
*Source de Vie* (D55) — [ADR-118](../_adr/ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md).
**Rien n'en est fusionné ni publié** : `main` reste à `5d894785`, et ce que le vault dit de la vague 8
n'y deviendra vrai qu'à la fusion. La [spec](../../docs/superpowers/specs/2026-11-18-p42-tranche-3-design.md)
et le [plan](../../docs/superpowers/plans/2026-11-18-p42-tranche-3.md) font foi ; le
[compte rendu de la vague](../../docs/superpowers/reports/2026-11-18-economie-et-catalogue-vague-8-compte-rendu.md)
porte les chiffres (§1), les arbitrages et les décisions de SDD S0 à S5 (§2) ; sa fin — §0, §3 à §6
et le fichier de tests manuels, dont la spec §9.1 prépare les points M1 à M16 — s'écrit à la fin de
la vague (orchestration §3.8). **P-42 est clos dans `docs/ROADMAP.md`** ; **le chantier, lui, ne
l'est pas** : c'est la session de clôture qui le fera, après le tag (orchestration §8.9). **Un
arbitrage que le propriétaire renverse se corrige sur la branche avant la fusion.** Le 2026-11-19,
**six corrections de fin de vague** y sont faites, options choisies sur maquettes, un commit chacune
(`70fce82b` → `ee60f62f`) — [ADR-119](../_adr/ADR-119-les-corrections-de-fin-de-vague-8.md), tests manuels C1 à C6.

**La vague 7 est close** : fusionnée dans `main` le 2026-11-18 par la PR #55 (commit de fusion
`5d894785`), taguée `v0.5.9` sur ce commit, CI de tête `44271012349` et `release.yml` run
`44271100229` verts, release publiée — constatée par la porte d'entrée de la vague 8 (`eb7945fb`) et
re-vérifiée par `gh` à cette synchronisation. ADR-117 est désormais vrai sur `main`.

**La méthode est celle d'[ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
amendée par [ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md),
[ADR-108](../_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md),
[ADR-110](../_adr/ADR-110-une-vague-de-plus-pour-les-charges-elementaires.md) — clos par la vague 7 — et
[ADR-113](../_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md).** **Deux documents font
foi, et ne se recopient pas** : le
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
pour le *déroulé* et le
[brainstorm v3](../../docs/possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md)
pour les *décisions de conception*.

Réserves à ne pas perdre de vue :

- **Ce que la vague 8 laisse ouvert**, consigné à la spec §2 et dans ADR-118 : **une Faiblesse de N
  tours réduit N − 1 attaques ennemies** — le porteur décompte avant d'agir ; moteur gardé (A19), les
  durées des cartes de Sanctifié allongées d'un tour, le décalage antérieur (*Sentence*) à la file ;
  l'ennemi affiche Vulnérable et Faiblesse au-delà du plafond du barème (Vulnérable 8 sous quatre
  marques, que lit *Exploitation*) ; la face en main d'une carte à source de cible montre sa base ;
  l'accord des noms anglais de `statusName` n'a pas de test (S4) ; **aucune relique n'écoute
  `onDamagingCardPlayed`**. **Aux tests manuels** : *Exécution* face aux boss (M10) et le Vulnérable
  qui s'accumule (M7), à juger — la calibration est P-16 ; **Carnage à l'acte 1**, où chaque combat
  n'a qu'un ennemi (M9). **Dues à P-44, hors du programme** : les épines de Rempart, la carte
  `retain` de Voile, *Forge de guerre* de Carnage — la session de clôture les porte en ROADMAP.
- **Ce que la vague 7 laisse ouvert**, consigné au compte rendu §4 et dans ADR-117 : **la phase
  ennemie se joue jusqu'au bout après une victoire constatée par les statuts** (`_enemyRipostePhase`
  ne regarde jamais `isCombatEnded`) — un soin de trop de *Bénédiction*, et depuis la vague 8 de la
  *Source de Vie* de *Prière* —, **bloquant pour le premier contenu qui posera du Feu ou du Poison
  sur le héros** (S9) — non bloquant pour la vague 8, dont aucune carte n'en pose sur le héros ; un harnais de test
  commun qui surcharge le chargement du registre (S11) ; `FrostVignette` recrée ses dégradés à
  chaque frame, `ChargeHalo` et `FireBurst` leur `Paint`, la règle « 1,5 largeur de carte » est
  écrite deux fois ; `shippedCard(id)` ne lit pas les cartes de lot. **Aux tests manuels** : le
  serrement de la gangue (3 %) se perd sous le sursaut du coup de *Trait de Glace* (S16) ; l'éditeur
  de contenu déborde à 600 px de haut avec onze onglets (S10). **Le cadre est symétrique mais aucun
  ennemi ne pose de charge** : ce qui touche le héros porteur ne se vérifie que par l'entrée de debug.
  **L'affichage et les animations ne sont gardés par aucun test** (D77) : seuls leurs calculs le
  sont — `ChargeRules.linesFor`, le compte rendu de vague, `chargeHits`.
- **Ce que la vague 6 laisse ouvert**, consigné au compte rendu §4 et dans ADR-116 :
  `effect_line_texts.dart` n'a pas de phrase pour `mana_regen` (à écrire quand une signature
  posera le statut) ; `'status:${statusId}'` s'écrit dans `forge_rune_rules.dart`,
  `passive_feeds.dart` et `EffectKind.of`, à factoriser à la quatrième lectrice ; au tutoriel, sans
  couple attaque + Armure qui tienne dans le mana, la main d'avant est gardée ; la garde
  `if (preview == null) return;` de `ManaReservePassive` est inatteignable ; seize cristaux ou plus
  feraient déborder le HUD sous *Canalisation*.
- **Ce que la vague 5 laisse ouvert**, consigné au compte rendu §4 et dans ses ADR : un `flatBonus`
  qui vise un effet absent de sa signature est accepté en silence ; `DraftScreen` se quitte par le
  retour système sans choisir ; l'éditeur accepte une carte à `costs.armor` sous un passif sans classe unique ;
  `ProportionalStatus`, sous `lib/game/`, est importé par `enemy_instance.dart` ; `takeDamage` n'a
  pas de test direct ; `asCard` est recalculé à chaque lecture, `effectLines` couplé par l'ordre sans
  `assert`. **Les faces des cartes, les émojis des statuts ennemis et l'icône de *Précis*** ne
  lisent pas encore `effect_icons.json`, et **les infobulles des cartes** attendent leur reprise
  (PN12) — lignes de `docs/ROADMAP.md`. À 360 px de large, le compteur d'or de la barre de la carte
  chevauche « RELIQUES » et « CHANCES » dans le rendu de test — à confirmer sur un vrai téléphone
  (ADR-115). La croissance `targetStatus` nommée en français dans la version anglaise est réglée
  par la vague 8 (clé `statusName`, ADR-118).
- **Ce que la vague 4 laisse ouvert**, consigné dans ADR-109 : `playSignature` ne vérifie pas que
  l'ennemi visé est présent (S4) ; l'ennemi visé par la dernière carte garde sa bordure ambre
  pendant qu'une signature est armée (S12) ; la glue Flame du ciblage n'a pas de banc de test.
  Avant la `1.0.0`, rien ne garantit qu'une sauvegarde survive à une version.
- **Deux tests peut-être instables** : `test/widget/content_editor_screen_test.dart`, groupe des
  imports, a échoué une fois dans une suite complète pendant la vague 1 ;
  `test/unit/content_editor/entity_writer_test.dart` (« une sauvegarde ratée ne laisse aucune copie
  partielle ») une fois pendant la partie 1 de la vague 7. Tous deux verts dans la suite complète
  de cette synchronisation (2026-11-18). À surveiller.
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
  `assets/data/patch_notes.json`, jamais ici.** Sur la branche de la vague 8, les trois porteurs de
  version portent déjà la sienne (`147f564c`), **ni taguée ni publiée** ; sur `main`, celle de la
  vague 7, publiée. Les versions que visent les vagues font foi dans le fichier d'orchestration, §1.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Si `gh`
  ne joint pas l'API à une porte d'entrée, c'est le propriétaire qui confirme, et le journal le
  note — la porte ne suppose jamais.
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Vague 8 — P-42 tranche 3 : Sanctifié, Carnage, Marque, les neuf passifs jouables**
   (2026-11-18, branche `feat/v0.6.0-p42-tranche-3`, 13 commits `eb7945fb` → `147f564c` sur `main`
   à `5d894785` — **livrée sur la branche, vague 8 du fichier d'orchestration, en attente du test,
   de la PR, de la fusion et du tag du propriétaire**) — **chaque passif a son lot.** **Le
   déclencheur de D34** : `onDamagingCardPlayed`, que la suite commune envoie après l'événement du
   type si la carte porte un effet `damage` — un seul prédicat, `EffectiveCard.dealsDamage`, effets
   ajoutés compris, sans lire la cible ni les dégâts ; aucune relique ne l'écoute. ***Marque du
   Mage*** l'écoute : la première carte de dégâts du tour, Attaque ou Compétence, signature
   comprise, **qui vise un seul ennemi sans le tuer**, lui pose 2 Vulnérable — une carte de groupe
   ne marque ni ne consomme (A3 (c)), une carte qui tue sa cible non plus (A4 (ii)) ; *Projectile
   Magique* marque de nouveau, hors *Nova*. **La *Source de Vie*** (`hp_regen`, D55) : posée par
   *Prière*, elle rend ses PV après le tic, bornée aux PV max, jamais à un porteur mort, symétrique
   héros / ennemis ; le cœur rose du soin, dix-huitième sorte d'icône. **Le nom du statut** de la
   croissance `targetStatus` se lit dans la langue du joueur (clé `statusName`). **Trois lots** :
   Sanctifié (la Faiblesse, *Métallisation*, *Prière*), Carnage (quatre Attaques de groupe,
   *Exécution* sur `targetMissingHp`), Marque (les quatre élémentaires, *Exploitation* sur
   `targetStatus`, *Salve* 2 × 3) — dix fichiers neufs, six `git mv` ; neuf neutres restent ; les
   trois derniers passifs se démasquent par la donnée. **Deux réponses P au lancement** (Q12 oui,
   D43 non), **un arrêt** sur A3 et A4, levé par le propriétaire le 18/11 ; spec convergée au
   premier tour, plan prêt au deuxième ; SDD en sept tâches, revue d'ensemble « prête avec
   corrections » et sa passe (`a65bf4c7`). Note de version écrite (`147f564c`). **1826 tests**
   (+50 sur la base de **1776**, celle de `main`), `dart analyze` propre (**vérifié le
   2026-11-18**) — [ADR-118](../_adr/ADR-118-la-tranche-3-carte-de-degats-marque-et-source-de-vie.md),
   qui complète ADR-112, ADR-111 et ADR-116. **Clôt P-42.** **Puis six corrections de fin de vague**
   (2026-11-19, `70fce82b` → `ee60f62f`) : la mort efface la sauvegarde, l'affûtage ne liste que l'affûtable,
   les intentions en lignes compactes à infobulles, un arbitre du survol de la main, la
   Puissance sur les tuiles de signature, « -12 PV Max » — **1859 tests** (vérifié le 2026-11-19), ADR-119.
2. **Vague 7 — P-53 : les charges élémentaires, le Gel, le Feu et la Foudre** (2026-11-15 →
   2026-11-17, branche `feat/v0.5.9-p53-charges-elementaires`, 30 commits `b50eca31` → `d15bcd04`
   sur `main` à `535f9ded` — **fusionnée dans `main` le 2026-11-18 par la PR #55, merge
   `5d894785`, taguée `v0.5.9`, CI/CD verte**) — **les éléments rompent.** **Le
   cadre en donnée** : un fichier par charge sous `charges/` — la onzième source et la onzième
   catégorie de l'éditeur —, qui déclare seuils, montée, surcharge, déclin, moment et sorte de
   rupture, validé au chargement (un seuil de Feu sous 3 est refusé) ; quatre sortes de rupture
   seules en Dart, une piste par porteur hors sauvegarde, `ChargeRules` seule écriture des règles.
   **Le Gel** (seuils 3, 6 en boss, 5 pour le héros, +1 à chaque gel) ôte toute son action à
   l'ennemi ; le héros gelé frappe moitié moins à son tour suivant, sans le perdre. **Le Feu**
   s'accumule sans limite et, au tour du porteur, chaque tranche de 3 explose sur ses voisins — 12
   et 1 Feu chacun —, **une chaîne vague par vague** que le contrôleur joue et que Flame anime.
   **La Foudre** ajoute +1 par point à chaque coup, +2 une fois chargée, jusqu'à la fin de la phase.
   Le Gel **quitte le barème proportionnel** ; le pipeline reçoit le catalogue ; l'intention d'un
   ennemi n'est plus réduite. **Les dix contenus relus** : *Embrasement* 3 Feu, *Congelant* 1 Gel
   par niveau, les autres inchangés ; la Brûlure devient le Feu, l'Électrocution la Foudre. **À
   l'écran** : « ❄ 2/3 », « 🔥 5 », « ⚡ Chargé », l'intention barrée d'un ennemi gelé, le panneau du
   héros, le tutoriel, une section « Charges » au debug ; en partie 2, **la gangue, l'onde et le
   halo**, et le bonus « +N » de chaque coup de Foudre. **Trois arrêts sur des questions P**, chacun
   levé par le propriétaire sur maquettes : P-a à P-e (15/11), Q-P1 (16/11), Q-P2 (17/11) ; spec
   prête au quatrième tour. Note de version écrite (`d15bcd04`). **1772 tests** (+90 sur la base de
   **1682**, celle de la porte d'entrée), `dart analyze` propre (**vérifié le 2026-11-17**) —
   [ADR-117](../_adr/ADR-117-les-charges-elementaires.md), qui amende ADR-023 et ADR-111 et clôt
   ADR-110.
3. **Vague 6 — P-42 tranche 2 : Croisé, Vampire, Voile, et la banque de mana de *Canalisation***
   (2026-11-15, branche `feat/v0.5.8-p42-tranche-2`, 12 commits `b8e0641b` → `074d53ac` sur `main`
   à `df1b671d` — **fusionnée dans `main` le 2026-11-15 par la PR #54, merge `56fae9df`, taguée,
   CI/CD verte**) — **six passifs sur neuf se jouent.**
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
> [!NOTE]
> **Rotations.** Sortie le 2026-11-18, dans `../_archive/` : `2026-11-18-activeContext-livraisons.md`
> (la vague 5, P-42 tranche 1 et P-44 lot 1). Sortie le 2026-11-17 : `2026-11-17-activeContext-livraisons.md`
> (la vague 4, P-43 lot E4). Sortie le 2026-11-15 : `2026-11-15-activeContext-livraisons.md`
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

**D'abord le propriétaire, sur la vague 8** : la fin de vague écrite (orchestration §3.8), il
joue le fichier de tests manuels — les points M1 à M16 de la
[spec](../../docs/superpowers/specs/2026-11-18-p42-tranche-3-design.md) §9.1, validés, et C1 à C6 —, lit la
table des arbitrages du
[compte rendu](../../docs/superpowers/reports/2026-11-18-economie-et-catalogue-vague-8-compte-rendu.md)
(§2), ouvre la PR de `feat/v0.6.0-p42-tranche-3`, la fusionne dans `main`, puis pose le tag de la
version sur le commit de fusion (ADR-103 D1). Une correction demandée se fait sur la branche, avant la
fusion ; une valeur de carte que le test corrige se change dans son fichier, sans code.

**Puis la session de clôture du programme** (orchestration §8.9), dans une session neuve, une fois la
version de la vague 8 taguée : elle constate la vague 8 close et dit le chantier clos ; elle porte
en `docs/ROADMAP.md` les trois cartes dues à P-44 — les épines de Rempart, la carte `retain` de
Voile, *Forge de guerre* de Carnage. **Le défaut S9** (la phase ennemie après une victoire) reste
bloquant pour le premier contenu qui posera du Feu ou du Poison sur le héros. **P-16** calibrera
ensuite sur les neuf lots.

Une question reste tenue dans `docs/ROADMAP.md` §4, hors programme : la **Maîtrise dans l'onglet
Héros du menu de debug**.

Le Jalon 2 « Feel & contenu » (`docs/ROADMAP.md` §9) reste ouvert : P-06, P-07, le prototype de
P-08, P-05 — dont dépendent les lots 2 à 4 de P-44, après le programme. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
