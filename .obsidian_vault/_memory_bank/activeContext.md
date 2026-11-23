<!-- last-sync: 2026-11-22 | commit: 477e9b12 -->

# 🧠 Contexte Actuel

> [!IMPORTANT]
> **Plafond : 240 lignes.** Focus courant, **3 dernières livraisons au maximum**, prochaine étape. Une 4ᵉ livraison pousse la plus ancienne vers `../_archive/`. Ce fichier ne contient jamais de backlog — voir `docs/ROADMAP.md`.

## Focus courant

**Le chantier du bestiaire (P-05) est ouvert.** Ses décisions sont au
[cadrage](../../docs/possible_upgrades/21-11-2026_cadrage_bestiaire_P05_Fable5.md) (§1) ; son
déroulé — les vagues, leurs versions, le journal, les fiches, le catalogue des mécanismes et celui
des ennemis — dans [`docs/chantier_bestiaire/`](../../docs/chantier_bestiaire/README.md). **La
vague 1, l'interface des ennemis, est fusionnée dans `main` (PR #57) et taguée depuis le
2026-11-22**, avec la correction S9. **Le programme a été révisé le 2026-11-23, après un audit** :
le visuel et une couture de lieu, puis le langage des intentions seul, puis les tiers 1 à 3, un par
vague, puis une refonte de la difficulté, les tiers 4 et 5 et les boss ; les lieux viennent après.
**Aucune vague n'est ouverte** : la vague 2 attend ses prérequis, et ce programme n'est encore que
sur sa branche de documentation.
Suivi en clair : [`docs/suivi_vagues_chantier/bestiaire.md`](../../docs/suivi_vagues_chantier/bestiaire.md).

**La méthode** est celle du chantier précédent — [ADR-102](../_adr/ADR-102-chantier-par-vagues-une-version-par-vague.md),
[ADR-103](../_adr/ADR-103-vagues-fusion-puis-tag-reference-de-simulation-suivi.md),
[ADR-108](../_adr/ADR-108-methode-par-vagues-calibree-plans-de-decisions-sans-simulation.md),
[ADR-113](../_adr/ADR-113-les-tests-gardent-les-calculs-et-les-donnees.md) et les cinq amendements
d'[ADR-120](../_adr/ADR-120-ce-que-le-chantier-economie-et-catalogue-legue-a-la-methode.md) D1 —,
avec le cycle et les gabarits du
[fichier d'orchestration](../../docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
§3 à §6, figé ; ni D3, ni D4, ni R31 ; autonomie `strict`. **Trois écarts du propriétaire pour la
vague 1** (cadrage §4) : la session de cadrage l'orchestre, la branche part de la correction S9, la
porte d'entrée ne contrôle ni fusion ni CI d'une vague précédente.

**Le chantier « Économie unifiée et catalogue » est clos depuis le 2026-11-19** — P-43, P-42, P-44
lot 1 et P-53, en neuf vagues ; sa clôture est fusionnée dans `main` (`f1ecddce`).

Réserves à ne pas perdre de vue :

- **Ce que la vague 1 du bestiaire laisse ouvert**, consigné dans
  [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md) et au compte rendu de la vague
  (§0, §4) : **le voile d'armure d'un ennemi est dormant** — aucun ennemi n'en gagne, le menu de
  debug n'en pose pas sur un ennemi : B12, B15, B16 ne se testent pas en jeu (T20) ; le cadre de la
  fiche sans hauteur maximale ; une languette intérieure plus large que sa carte recouvre l'autre ;
  `onGameResize`, rappelé à chaque reconstruction de l'écran, coupe encore les secousses et la mort
  d'un ennemi ; Puissance et Foudre partagent ⚡ ; les seuils 6, 12, 20 des paliers d'attaque écrits
  trois fois (à réunir avec B1) ; `lib/game/components/entities/health_bar.dart` sans lecteur. **Un
  changement visible non tranché** (V1) : les ennemis non sélectionnés gardent une bordure cyan sous
  une carte focalisée. **Aux tests manuels, joués le 22/11** : 25 ✅, T20 non testé (le voile), une
  correction C1 (`1876a07b`) ; V1 et les points vus laissés tels quels par le propriétaire.

- **Ce que la vague 8 laisse ouvert**, consigné à la spec §2 et dans ADR-118 : **une Faiblesse de N
  tours réduit N − 1 attaques ennemies** — le porteur décompte avant d'agir ; moteur gardé (A19), les
  durées des cartes de Sanctifié allongées d'un tour, le décalage antérieur (*Sentence*) à la file ;
  l'ennemi affiche Vulnérable et Faiblesse au-delà du plafond du barème (Vulnérable 8 sous quatre
  marques, que lit *Exploitation*) ; la face en main d'une carte à source de cible montre sa base ;
  l'accord des noms anglais de `statusName` n'a pas de test (S4) ; **aucune relique n'écoute
  `onDamagingCardPlayed`**. **Aux tests manuels** : *Exécution* face aux boss (M10) et le Vulnérable
  qui s'accumule (M7), à juger — la calibration est P-16 ; **Carnage à l'acte 1**, où chaque combat
  n'a qu'un ennemi (M9). **Dues à P-44, hors du programme** : les épines de Rempart, la carte
  `retain` de Voile, *Forge de guerre* de Carnage — portées sur la ligne de P-44 de `docs/ROADMAP.md`.
- **Ce que la vague 7 laisse ouvert**, consigné au compte rendu §4 et dans ADR-117 : **la phase
  ennemie se joue jusqu'au bout après une victoire constatée par les statuts** (`_enemyRipostePhase`
  ne regarde jamais `isCombatEnded`) — un soin de trop de *Bénédiction*, et depuis la vague 8 de la
  *Source de Vie* de *Prière* — (S9) : **corrigé par la vague 1 du bestiaire, fusionnée dans `main`**
  ([ADR-122](../_adr/ADR-122-un-combat-fini-ne-rouvre-aucun-tour.md)) ; un harnais de test
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
  de cette synchronisation (2026-11-22). À surveiller.
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
  `assets/data/patch_notes.json`, jamais ici.** Sur `main`, les trois porteurs de version portent
  celle de la vague 1 du bestiaire. Les versions des vagues font foi au fichier d'orchestration,
  §1, pour le chantier clos, et au README du chantier du bestiaire, §1, pour le bestiaire.
- **Une vague vérifie par `gh` que la précédente est taguée et que sa CI/CD est verte.** Si `gh`
  ne joint pas l'API à une porte d'entrée, c'est le propriétaire qui confirme, et le journal le
  note — la porte ne suppose jamais. La vague 1 du bestiaire en est dispensée (cadrage §4,
  troisième écart).
- **Les tiers A, B, C et E de `docs/ROADMAP.md` n'ont toujours pas été re-vérifiés contre le
  code** — seuls S et D l'ont été (2026-08-04).
- **Bouton de téléchargement mort** si le build Windows échoue quand le web réussit — correctif
  identifié, non fait, voir [ADR-080](../_adr/ADR-080-site-vitrine-pilote-par-la-donnee-et-jointure-decl.md).

## 3 dernières livraisons

1. **Bestiaire, vague 1 — l'interface des ennemis en combat** (2026-11-20 → 2026-11-22, branche
   `feat/v0.6.1-interface-des-ennemis`, partie de la correction S9 `8d544a3d` ; cadrage `c2e2dacb`,
   spec et plan `0eec1467` → `86a0f9db`, code `a356cabc` → `23c9823a`, note de version `5ea848fb` —
   **vague 1 du bestiaire, test du propriétaire passé le 2026-11-22, fusionnée dans `main` par la
   PR #57 et taguée le même jour**) — **l'ennemi se lit.** **Le panneau des intentions** en trois
   colonnes — « Niv. N », le nom, seul tronqué, les pastilles —, sans PV, une infobulle par rangée
   (B9, B10 ; la Puissance garde sa flèche violette, B31). **La barre de PV** à la largeur de la
   carte, l'armure en cyan à côté, un voile qui est la jauge de l'armure seule, plein au plus haut
   montant (B12, B15, B16 — dormant) ; la Puissance quitte le dessus de la carte (B11). **Les
   languettes**, sur les ennemis et le héros : bonus à gauche, altérations et charges à droite,
   déroulées au survol de la souris, vers l'intérieur au bord de l'écran (B14, B32, B33, B39, B41).
   **La fiche** : toucher un ennemi sans carte ni signature en attente agrandit sa carte, estompe le
   plateau et ouvre à côté un cadre Flutter ; tout autre appui la ferme (B13, B35, B36, B40). Les
   règles en fonctions pures, la fiche état d'affichage de `HerosDraftGame` reflété en différé, une
   zone par carte de combat, la fermeture par le pointeur retenu, des écarts relatifs d'échelle et
   de place ; `StatBadge`, `StatusIndicator`, `CircleProgressComponent` supprimés. Le tutoriel suit
   (B37). **S9** : un combat fini pendant la phase ennemie ne rouvre aucun tour. Deux arrêts à la
   spec, levés par les réponses B31 à B41 ; plan prêt au troisième tour ; sept tâches, une passe de
   corrections. **Testée par le propriétaire le 22/11** (25 ✅, T20 non atteignable) ; **une correction,
   C1** (`1876a07b`, note `477e9b12`) : la fiche écrit une ligne d'aide sous chaque entrée, la phrase
   courte d'une charge venant de son fichier (`summary_fr` / `summary_en`, obligatoire). **1939 tests**
   (+73 sur la base de **1866**), `dart analyze` propre (**vérifié le 2026-11-22**) — [ADR-121](../_adr/ADR-121-l-interface-des-ennemis-en-combat.md),
   [ADR-122](../_adr/ADR-122-un-combat-fini-ne-rouvre-aucun-tour.md).
2. **Clôture du chantier « Économie unifiée et catalogue »** (2026-11-19, branche
   `docs/cloture-chantier-economie-et-catalogue`, sur `main` à `84a1ee34` — **sans code, sans
   version, sans tag**, orchestration §8.9) — **le chantier est clos.** La porte d'entrée constate
   la vague 8 fusionnée, taguée, publiée, CI/CD verte ; le journal passe la vague 8 à « close » et
   la ligne « Clôture » à « faite » ; le suivi reçoit son bilan. **Les trois cartes dues à P-44** —
   une carte d'épines pour Rempart (lot 2), une carte `retain` pour Voile et *Forge de guerre* pour
   Carnage (lot 3) — sont portées sur la ligne de P-44 de `docs/ROADMAP.md` (brainstorm v3 §7.1 à
   §7.3 et §11, orchestration §7.2). **Un ADR de clôture**,
   [ADR-120](../_adr/ADR-120-ce-que-le-chantier-economie-et-catalogue-legue-a-la-methode.md).
   **1859 tests**, `dart analyze` propre (**vérifié le 2026-11-19**, `lib/`, `test/` et `assets/`
   identiques à `84a1ee34`).
3. **Vague 8 — P-42 tranche 3 : Sanctifié, Carnage, Marque, les neuf passifs jouables**
   (2026-11-18, branche `feat/v0.6.0-p42-tranche-3`, 13 commits `eb7945fb` → `147f564c` sur `main`
   à `5d894785` — **fusionnée dans `main` le 2026-11-19 par la PR #56, merge `84a1ee34`, taguée
   `v0.6.0`, CI/CD verte**) — **chaque passif a son lot.** **Le
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
> [!NOTE]
> **Rotations.** Sortie le 2026-11-22, dans `../_archive/` : `2026-11-22-activeContext-livraisons.md`
> (la vague 7, P-53). Sortie le 2026-11-19 : `2026-11-19-activeContext-livraisons.md`
> (la vague 6, P-42 tranche 2). Sortie le 2026-11-18 : `2026-11-18-activeContext-livraisons.md`
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

**D'abord le propriétaire** : fusionner dans `main` la branche de documentation du chantier — le
prompt de lancement d'une vague lit `docs/chantier_bestiaire/` depuis `main` —, lever les prérequis
de la vague 2 (sa fiche), et lancer la production des sprites du tier 1, dont l'état se tient au
catalogue des ennemis. Deux cadrages restent à tenir avant leurs vagues : la difficulté, après le
tier 3, et les boss.

**Puis la vague 2 du bestiaire, que le propriétaire ouvre** — ce fichier n'en ouvre aucune ; le
journal du chantier (README §4) en tient l'avancement, et sa porte d'entrée passe la vague 1 à
« close ». Le compte rendu de la vague 1 (§5) propose quatre amendements de méthode, laissés au
propriétaire. **P-07 doit lire
[ADR-083](../_adr/ADR-083-latence-et-synchronisation-du-chemin-de-lecture.md) D6 avant de toucher
aux animations.**
