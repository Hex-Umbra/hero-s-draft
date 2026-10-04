## 8. Système de Tutoriel Autonome (Tutorial System)

Pour accompagner les nouveaux joueurs sans alourdir ni risquer la run de production, le
tutoriel est un module entièrement autonome sous `lib/tutorial/`. Il ne fabrique **aucune**
donnée qu'il pourrait lire dans le jeu réel : les valeurs de héros, de cartes, d'ennemis et de
reliques viennent du même `GameDataRegistry` que la partie normale. Seuls les textes
pédagogiques et les annotations visuelles sont écrits en dur. Décision et rationale complets :
[ADR-081](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md), qui amende
[ADR-019](../_adr/ADR-019-systeme-de-tutoriel-autonome-isolant-la-boucle-pri.md).

### 8.1. Architecture — zéro provider d'*état*

> [!IMPORTANT]
> La règle n'est plus « zéro Riverpod » mais **« zéro provider d'état »**. Les huit providers
> de run (`runProvider`, `deckProvider`, `combatProvider`, `inventoryProvider`,
> `rewardProvider`, `shopProvider`, `eventProvider`, `checkpointProvider`)
> restent interdits dans `lib/tutorial/` — eux seuls portent un risque d'effet de bord sur la
> run. `gameDataLoaderProvider`, qui ne lit que de la donnée immuable, est autorisé **en un
> point unique** : `lib/tutorial/tutorial_loader.dart` (`ConsumerWidget`). Il résout le
> `FutureProvider`, gère `loading`/`error`, puis passe le `GameDataRegistry` par constructeur
> à `TutorialScreen` → `TutorialEngine`. Le critère est vérifié par un test, pas seulement
> documenté : `test/tutorial/tutorial_isolation_test.dart` échoue si un autre fichier du
> dossier importe `flutter_riverpod` ou nomme un des huit providers, ou `GameDataRegistry.instance`.

Le moteur (`TutorialEngine`) reste un `ChangeNotifier` Dart simple : il ne gagne aucun
provider, il possède et mute lui-même les instances qu'il reçoit.

### 8.2. Contrat de données

`lib/tutorial/tutorial_fixtures.dart` est le **seul** endroit du dossier qui nomme un id de
donnée (`TutorialFixtureIds` : `strike_basic`, `defend_basic`, `fireball`, `slime`, `gobelin`,
`iron_talisman`, `paladin`/`berserker`/`mage`). `TutorialFixtures` les résout contre le
registre par `firstWhere` **sans `orElse`** — une donnée manquante fait échouer le test de
fidélité (`test/tutorial/tutorial_fixtures_test.dart`) plutôt que de dériver silencieusement
en production. Les modèles portés sont ceux du jeu, pas des POJOs : `CardInstance`,
`EnemyInstance`, `EntityStats`, et `DamagePipeline.calculate()` pour les dégâts (déterministe
à `critChance: 0`).

### 8.3. Parcours à état : tranche persistante et verrou

`TutorialMockState` se scinde en deux tranches. La **persistante** — `chosenHero`,
`activePassive`, `masterDeck` — n'est écrite que par les étapes 02 et 03 et survit à tout le
reste du parcours. `chooseHero` pose le premier passif de la classe comme défaut, `choosePassive`
le remplace ; seul un **changement** de classe repose le défaut, un retap sur la classe déjà
choisie ne le fait plus. La **scratch** — main, ennemi, armure et mana du tour, XP de démonstration,
drapeaux d'interaction — est réinitialisée par `prepareStep(index)` à chaque changement
d'étape.

Une fois l'étape 03 franchie, `prevStep()` ne redescend plus sous l'étape 04 : revenir
invaliderait la classe et le deck dont dépendent les étapes suivantes (Armure démontre *le*
passif choisi, Jouer pioche dans *ce* deck, Fusion y prend trois exemplaires d'une carte
réellement draftée). Le bouton « Précédent » est masqué sur l'étape 04, comme il l'était déjà
sur l'étape 01.

### 8.4. Déroulement en 15 Étapes Progressives

`PageView` non-swipeable ; chaque étape interactive bloque l'avancement jusqu'à son critère
(entre parenthèses) :

1. **Accueil** : logo animé, résumé du jeu.
2. **Choix de classe, et de son passif** *(une classe choisie)* : les 3 héros avec leurs vraies
   valeurs (Paladin 100 PV, Berserker 80, Mage 60, tous à 3 mana) et **tous** les passifs que
   `availablePassivesFor` ouvre à la classe, sous `assets/data/passives/`. Le bloc dépliant est
   le `ClassPassiveList` de `ClassSelectionScreen` — le widget de production, pas une seconde
   implémentation : c'est le remède que demande le §1.4 de la spec de P-41. Repliée, chaque carte
   montre le passif avec lequel la run partirait ; la carte choisie est dépliée et ses tuiles
   sont cliquables, une seule à la fois. Trois cartes simples, pas le carrousel. Écrit la tranche
   persistante.
3. **Draft du deck de départ** *(5 cartes choisies)* : les 17 cartes globales de
   `registry.cards` (mêmes critères que `StarterDeckDraftScreen`) ; les cartes de la classe
   choisie s'ajoutent automatiquement. Écrit `masterDeck`.
4. **Carte du Monde** : mini-carte annotée, dix planchers, goulot Élite au 6, Repos garanti au
   9, 3 Boss au sommet. Rappelle qu'un nœud touché engage immédiatement, sans confirmation.
5. **Types de Rencontres** : les 8 nœuds (Combat, Élite, Boutique, Repos, Événement, Autel des
   Reliques, Puits d'échange, Boss). Depuis le lot E2 de P-43, la Boutique dit la copie d'une carte
   du deck, le Repos l'affûtage d'une rune, et le Puits l'échange d'une rune contre de l'or, tous les
   trois actes ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md)). Depuis le lot E3 (branche de la
   vague 3, en attente du propriétaire — [ADR-107](../_adr/ADR-107-trouvaille-et-progression.md)),
   le Combat rapporte « l'or, l'XP et une carte », l'Élite « une Relique et une carte — parfois
   deux », et le Boss d'XP « le triple d'XP et d'or, et monte une rune si l'une peut encore
   monter » — dans la tuile comme dans la prose de l'étape des nœuds, qui le répète.
6. **Combat — Vue d'ensemble** : maquette annotée de la disposition de l'écran (Héros/Ennemi
   au centre, main/mana/PV en bas, effets joueur + pioche à gauche, Fin de Tour/intentions/
   défausse à droite, boutons Deck/Pause en haut à droite). **Ne montre pas de
   « Compétences »** — le widget réel n'en affiche pas.
7. **Cartes & Mana** : médaillon de coût, appui pour la description complète, 3 types
   (Attaque/Compétence/Pouvoir), cartes rendues par `UiCard.fromInstance`.
8. **Jouer des cartes & finir le tour** *(dégât porté et armure gagnée)* : glisser-déposer sur
   la cible, cycle de tour complet (pioche, défausse, double confirmation si mana restant,
   armure remise à 0). Le texte flottant d'une Compétence **mesure le gain réel** de part et
   d'autre de `playCard` (`armure` et `effectiveMight` avant/après) au lieu de lire la valeur
   imprimée sur la carte : une classe qui convertit son Armure y lit sa Puissance. Le `else if`
   y est délibéré — sans branche qui matche, l'étape ne dit rien plutôt que d'annoncer zéro. Le
   bandeau « Main max : » lit `GameConstants.startingMaxHandSize`, la main de départ d'une run, et
   non plus un `10` littéral.
9. **Armure & Dégâts** : l'armure retombe toujours à 0 en début de tour, quelle que soit la
   classe ; le passif choisi à l'étape 02 et la Maîtrise sont montrés avec leurs vraies valeurs.
   La démo comparative se joue **en deux temps** — le gain de 4 Armure, puis le coup de 10 —
   parce que c'est le gain que la classe modifie. Il passe par `TutorialEngine.gainArmorForDemo`,
   donc par `StatGains.apply` et les `statRules` de la classe, jamais par une écriture directe :
   le panneau droit part de **0 Armure** comme le gauche, et ce qu'il affiche après le gain est
   ce que la classe en a fait. Le titre du panneau est **généré** depuis la règle qui vise
   l'Armure (`StatRule.shortTitle` → « ARMURE → PUISSANCE »), jamais écrit classe par classe
   (ADR-090), et la règle elle-même est écrite en clair sous les deux panneaux par
   `StatRuleLabel.describe` — les mêmes phrases qu'à l'écran de sélection : **deux** quand la règle
   déclare un `ratio` autre que 1, la seconde disant le taux et son exemple (« Taux : 50%, arrondi à
   l'entier supérieur — 6 Armure → 3 Puissance. »). Le Berserker y voit +2 Puissance pour les 4
   Armure de la démonstration, et *Défense* lui en donne 3 à l'étape des cartes —
   [ADR-104](../_adr/ADR-104-un-statut-par-source-et-ratio-de-conversion.md).
10. **Effets Élémentaires** : galerie animée Poison, Brûlure, Gel, Électrocution, avec leurs
    règles exactes (valeur de Poison qui ne baisse jamais, Brûlure en début de tour, etc.).
11. **Intentions Ennemies** : lues dans le panneau `EnemyIntentsPanel` réel, en bas à droite —
    pas au-dessus de l'ennemi — avec ses 4 paliers d'attaque.
12. **Fusion de Cartes** *(fusion effectuée)* : manuelle, hors combat, 3 exemplaires de même
    rareté ; la rareté **augmente** les valeurs sans jamais changer le coût — ×1,2 à ×2,0, et
    toujours d'au moins 1 par fusion —, mais ni la pioche ni le Mana qu'une carte rend (G1, G2,
    [`_rules/02-4`](02-4-progression-de-rarete-dynamique-et-fusion-int.md)). **La fusion offre
    ensuite une rune parmi trois**, tirée par la fonction du jeu (`ForgeRuneRules.drawRunes`) sur le
    registre du tutoriel ; le joueur en touche une, la carte la porte, et **SUIVANT attend ce
    choix**. La main semée prend la première carte du deck dont la fusion offre au moins une rune —
    à défaut la première qui fusionne, puis les fixtures ; sans offre, l'étape le dit. L'encart
    « Même coût, rareté supérieure. » ne s'affiche que tant qu'aucune rune n'est choisie : *Allégé*
    le rendrait faux. La prose dit que la fusion garde toutes les runes et que le Puits d'échange
    est un système distinct et payant ([ADR-106](../_adr/ADR-106-fusion-egale-forge.md)). Le jeu d'une carte
    et la valeur affichée passent par l'applicateur du jeu, `EffectiveCard` — aucune recopie
    ([ADR-081](../_adr/ADR-081-amendement-autonomie-tutoriel-zero-provider-etat.md),
    [ADR-105](../_adr/ADR-105-moteur-de-runes-data-driven.md)).
13. **Expérience & Level Up** *(niveau gagné)* : le palier est celui de l'acte 1 sur la courbe
    du jeu — `TutorialEngine.xpThreshold`, `data.xpCurve!.thresholdFor(1)`, sur le registre du
    tutoriel, qui porte toujours la courbe (branche de la vague 3 ; la formule
    `100 × 1,5^(niveau-1)` et le champ `mockState.xpToNextLevel` ont disparu). La prose dit le prix
    des actes 1 et 2 par deux placeholders, `{xpAct1}` et `{xpAct2}`, que remplit la fonction pure
    `fillXpPlaceholders` de `tutorial_prose.dart`, et « de quoi gagner deux niveaux par acte » ;
    les drafts s'empilent si plusieurs niveaux tombent d'un coup.
14. **Draft de Récompenses** *(récompense choisie)* : `DraftChoiceCard` et
    `LevelUpRewardService.generateChoices()` réels — les 5 types plus les Mythiques (6 types sur
    `main`). La prose se réécrit d'elle-même par ses placeholders : « cinq types — Vitalité,
    Aiguisage, Affinité, Précision, Férocité — et jusqu'à quatre options Mythiques : Sagesse,
    Trèfle à 4 feuilles, Miroir et Transcendance ». Le tutoriel ne passe jamais `hasRaisableRune` :
    *Transcendance* n'y est jamais tirée. La carte d'*Affinité* lit la Maîtrise effective de la
    tranche persistante (`currentMastery`).
15. **Reliques** : **carte statique** présentant une relique d'exemple (`iron_talisman`) et la
    légende des raretés — ce n'est pas un carrousel. Sources réelles (Élite, Boss à relique
    améliorée, Autel des Reliques) et les 7 déclencheurs effectivement utilisés par le
    registre.

### 8.5. Internationalisation et Persistance

- **i18n intégrée** : chaque `TutorialStep` porte ses champs bilingues
  (`titleFr`/`titleEn`, `bodyFr`/`bodyEn`), résolus via
  `Localizations.localeOf(context).languageCode`.
- **Aucune persistance** depuis le 2026-09-14 : la complétion n'est plus enregistrée, et le
  bouton "TUTORIEL" de l'accueil ne porte plus de badge "NEW". Le badge était le seul lecteur du
  drapeau `tutorial_completed` ; le service qui l'écrivait est supprimé —
  [ADR-091](../_adr/ADR-091-menu-d-accueil-quitter-par-plateforme-et-retrait-du.md). Le tutoriel
  reste rejouable à volonté, et sa fin ramène à l'accueil.
