# P-53 — Les charges élémentaires : le Gel, le Feu et la Foudre — Conception

Date : 2026-11-15
Statut : **Conception** — vague 7 (`0.5.9`), branche `feat/v0.5.9-p53-charges-elementaires`

Chantier ROADMAP : **P-53** « Charges élémentaires » — une vague à lui (D76). Le déroulé fait foi dans le
[fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md),
§8.7 ; les décisions, dans le [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md),
§1 (D76, D83 à D86) ; les réponses du propriétaire qui les fondent et l'exemple chiffré de la réaction en chaîne,
dans l'[étude](../../possible_upgrades/03-11-2026_charges_elementaires_Opus5.md), §11 et §12.

> **Ce que le lot livre, en une phrase.** Le Gel, le Feu et la Foudre cessent d'être des statuts à durée et
> deviennent des **charges** : des points qui s'accumulent sur leur porteur, héros ou ennemi, jusqu'à un seuil où
> ils **rompent** — l'ennemi gelé perd toute son action et le héros gelé frappe moitié moins, le Feu explose sur
> les voisins du porteur et peut se propager de l'un à l'autre, la Foudre ajoute à chaque coup reçu, deux fois
> plus une fois chargée ; un cadre commun en donnée, un fichier par élément, porte leurs paramètres, et seules
> les quatre sortes de rupture sont écrites en Dart.

Toute référence `fichier:ligne` de ce document a été lue le 2026-11-15 sur la branche à `b50eca31`, dont le code
(`lib/`, `assets/`, `test/`, `tool/`, `pubspec.yaml`) est celui de `main` à `7aadf8a5` — les trois commits qui
suivent sont de la documentation. **Les valeurs — seuils, dégâts par point, bonus par coup — sont des ordres de
grandeur** (D83) : la spec écrit celles des décisions, le test du propriétaire les corrige. Les valeurs des cartes
et des runes relues (P-b) et les textes (P-a) sont les réponses du propriétaire, tranchées le 15/11 (§1.2).

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce que le lot en livre | Où |
|:---|:---|:---|
| **D76** | Le périmètre : le Gel, le Feu et la Foudre en charges, dans un cadre commun en donnée, symétrique héros / ennemis ; une vague à elles, `0.5.9`, avant la tranche 3 ; les trois derniers passifs restent masqués | §2 |
| **D83** | Le cadre commun : seuil de départ, montée, plafond de pose, déclin, moment et sorte de rupture déclarés en donnée ; la rupture seule en Dart, réutilisable ; une rupture propre au héros possible ; la somme des entrées de même id ; la Puissance « altération » une fois par carte ; la moitié sous le seuil ; Vulnérable, Faiblesse et Poison inchangés | §3, §4.1 à §4.4, §4.9, §4.12 |
| **D84** | Le Gel : seuils 3, 6 (boss), 5 (héros), +1 à chaque gel ; rupture à l'atteinte du seuil ; pas de surcharge, rien sur un porteur gelé ; déclin −1 ; l'ennemi gelé ne fait rien, son intention est consommée, ses statuts se résolvent ; le héros gelé inflige 50 % de dégâts en moins pendant son prochain tour, après la Faiblesse sans s'y additionner | §4.5, §4.6, §4.9 |
| **D85** | Le Feu : surcharge libre, seuil 3 fixe ; au tour du porteur, tranches à 100 % qui explosent (12 et 1 Feu à chaque voisin), reste à 50 % ; la chaîne par vagues, sans bonus de Puissance ; le refus d'un seuil inférieur à 3 ; la mort pendant et avant la chaîne ; le héros sans voisin | §3.2, §4.7 |
| **D86** | La Foudre : seuil 3 fixe ; +1 par point sous le seuil, +2 par point une fois chargé, dès l'atteinte du seuil ; jusqu'à la fin du tour en cours ; surcharge libre ; déclin −1 sous le seuil ; après le critique, avant Vulnérable | §4.8, §4.9 |

Elles croisent, **sans les amender** :

- **D33** — `burning`, `shocking`, `freezing` « restent en piles » : la charge compte en points, chaque rune en pose
  par niveau (§3.4) ;
- **D12** — « statuts proportionnels » couvre une charge à seuil ; Vulnérable et Faiblesse gardent le barème de
  P-1 ;
- **Q11** (vague 5, spec §1.2 ; ADR-111 D5) — un seul bonus de Puissance « altération » par résolution : il ajoute
  des points de charge, une fois ; une explosion n'est pas une carte et n'en reçoit pas (§4.2, §4.7) ;
- **§9.2 n° 2** du brainstorm — `shock` par coup sur les multi-coups : chaque coup passe le pipeline et lit la
  Foudre de sa cible (§4.8) ;
- **D77** — plus aucun test d'écran : §9 ne prescrit que des tests de calcul, de donnée, de contrôleur et de
  sauvegarde ; l'écran passe aux tests manuels (§9.1).

**D84 remplace pour le Gel le barème proportionnel de P-1** (spec de la vague 5, §1.2 et §4.4 ;
`proportional_status.dart:22-23`) : `ProportionalStatus` ne garde que Vulnérable et Faiblesse (§3.5).

### 1.2. Les réponses du propriétaire, reprises telles quelles

Toutes les règles du lot sont des réponses du propriétaire (étude, §11 : C1 à C7, C10 à C17 ; §12 : C8.1 à C8.6),
écrites en D83 à D86 le 15/11. La spec les applique ; aucune n'est une question. Les points de lecture qu'elles
laissaient à la spec sont tranchés en §1.3 (classe T) ou étaient ouverts en §1.4 (classe P) : ces cinq questions P
sont tranchées ci-dessous.

Les cinq réponses de classe P, **tranchées par le propriétaire le 15/11 sur les
[maquettes](../../presentations/2026-11-15_charges_elementaires_maquettes.pptx)** :

- **P-a (c) — les noms affichés** : Gel, Feu, Foudre en français ; Freeze, Burn, Shock en anglais ; les états
  rompus Gelé / Frozen et Chargé / Charged ; les noms des runes — *Brûlant*, *Congelant*, *Surchargé* — ne changent
  pas. Raison : « Brûlure » dit un dégât sur la durée et « Électrocution » un choc, deux sens que D85 et D86
  retirent, quand « Feu » et « Foudre » nomment l'élément et sont les mots des décisions ; en anglais, *Burn* et
  *Shock* sont déjà les noms courants de charges qui s'accumulent dans le genre.
- **P-b (a) — les valeurs relues** : *Embrasement* passe de 4 à 3 Feu, *Congelant* de 2 à 1 Gel par niveau ; les
  huit autres contenus, *Braise* comprise, ne changent pas (la table avant → après est en §3.4). Raison : à 3,
  *Embrasement* est une tranche exacte, dont la première explosion se voit au premier jet, et à 1 *Congelant* pose
  « +1 pile par niveau » comme ses deux sœurs (D33), là où 2 gèlerait d'un coup sous le seuil.
- **P-c — les animations de rupture** : **G-a, la gangue**, pour le Gel et **F-a, l'onde**, pour le Feu ; pour la
  Foudre, **L-b, le halo** — le choix du propriétaire, contre la recommandation L-a (l'arc) : le halo jaune seul,
  sans éclair, tant que le porteur est chargé, et le bonus en jaune à chaque coup. Les trois sont décrites en §5.2.
  Raison (celle de G-a et F-a) : chaque rupture se reconnaît sans lire, et l'onde montre d'où part le Feu et où il
  va, ce qui rend la chaîne lisible vague par vague (fiche 8.7).
- **P-d (a) — ce qui protège des dégâts du Feu** : l'Armure absorbe ; ni Vulnérable, ni critique, ni Faiblesse,
  comme la Brûlure et le Poison aujourd'hui (§4.7). Raison : c'est le canal du tic que D85 remplace, Vulnérable
  n'amplifie aujourd'hui que les coups et D83 veut qu'il ne change pas, et une intention de Défense qui protège de
  l'explosion se lit — l'étude, §4, qui faisait passer le Feu par le pipeline, ne faisait qu'une remarque de
  faisabilité.
- **P-e (a) — l'entrée de debug** : une section « Charges » dans l'onglet Combat du menu de debug, qui pose un point
  par la vraie règle, sur le héros ou sur un ennemi, et un bouton « Retirer les charges » (§7.2). Raison : aucun
  ennemi ne pose de charge dans cette vague, et sans elle rien de ce qui touche le héros porteur ne se vérifie à la
  main, ni l'exemple de l'étude (9 Feu sur un seul ennemi) — le précédent de P-7 (vague 5).

### 1.3. Les arbitrages

**A1 — Un fichier par élément, `assets/data/charges/<id>.json`, l'id étant celui du statut** *(T, filtre 5)*.
Trois fichiers : `charges/freeze.json`, `charges/burn.json`, `charges/shock.json`. Un catalogue plat, comme
`relics/` ou `forge_upgrades/` : une charge n'appartient à aucune classe, le répertoire n'injecte que l'`id`.
L'id d'une charge **est** l'id du statut que posent les cartes (`statusId`) : `burn`, `freeze` et `shock` restent
les ids techniques (P-a ne porte que sur les noms affichés), et aucune carte, rune ni évolution ne change de
`statusId`. Un fichier par entité, parce que `CLAUDE.md` réserve les documents plats aux configurations, pas aux
catalogues, et que D83 veut qu'un élément futur soit « un fichier ».

**A2 — Le modèle `ChargeData`, le registre et un provider qui retombe sur un catalogue vide** *(T, filtre 5)*.
`lib/models/data/charge_data.dart` porte `ChargeData` et sa rupture (`ChargeRupture` : une sorte et ses
paramètres) ; `GameDataRegistry` gagne `charges`, **vide par défaut** — comme `levelUpRewards` et `effectIcons`
(`game_data_registry.dart:27`, `:43`, `:61`), pour ne pas casser les dizaines de registres construits par les
tests ; `loadGameDataRegistry` (`game_data_service.dart:91-190`) gagne la source
`EntitySource('assets/data/charges/*.json', ChargeData.fromJson, inject: (c) => {'id': c[0]})`. Les règles lisent
le catalogue par un provider, `chargeCatalogProvider`, à côté de `xpCurveProvider` (`game_data_service.dart:207`),
qu'un test surcharge (`overrideWithValue`) ; **sans registre chargé, il rend le catalogue vide** — les tests de
combat d'aujourd'hui ne chargent pas de registre (`combat_controller_test.dart` ne surcharge aucun provider) — et
un statut absent du catalogue n'est pas une charge. **Un test qui joue un contenu posant une charge, ou qui pose
une charge à la main, surcharge donc `chargeCatalogProvider` avec le catalogue livré** (les trois fichiers lus par
le chargeur) : sans quoi le statut n'est pas posé (A4) et le pipeline ne lit aucune Foudre (A14) ; la liste des
tests concernés est en §9. Jamais `GameDataRegistry.instance` dans les règles : un état global de plus, que la
règle des couches refuse. **Le catalogue atteint l'affichage** par les chemins qu'empruntent déjà les données de
combat, sans qu'aucun composant ne lise le registre : `game_screen.dart` le lit sur `chargeCatalogProvider` et le
passe au constructeur de `HerosDraftGame`, comme `imagesToPreload` (`game_screen.dart:307-310`) — `EnemyCard`, ses
`StatusIndicator` et `CardComponent` le lisent sur `game` ; `StatusEffectsPanel` et `EnemyIntentsPanel` le
reçoivent en paramètre, comme `effectIcons` (`status_effects_panel.dart:12-17`, `combat_side_panels.dart:23-31`,
`:84-86`) — le panneau du héros reçoit en plus ses lignes d'affichage, que `game_screen.dart` calcule de ses
`EntityStats` (§5.1) ; `buildDetailedDescription` (`ui_card_helpers.dart:251-261`), appelé par un `StatelessWidget`
(`ui_card.dart:13`, `:159`), le lit par le conteneur Riverpod de son `BuildContext`
(`ProviderScope.containerOf`) ; le tutoriel, sur `widget.engine.data.charges`.

**A3 — La validation au chargement** *(T, filtre 1 — D84, D85)*. `ChargeData.fromJson` refuse, avec le nom de la
faute : une clé inconnue ; un nom ou une description sans sa paire `_fr` / `_en` ; un seuil inférieur à 1 ; une
montée ou un déclin négatifs ; une sorte de rupture inconnue, ou un paramètre qui n'est pas celui de sa sorte ;
`belowThresholdPercent` hors de [0, 100] ; une sorte et un moment qui ne vont pas ensemble (§3.1) ; **une
rupture `explode` dont un seuil — ennemi, boss ou héros — ne dépasse pas `2 × chargePerNeighbour`** : à 1 Feu par
voisin, un seuil inférieur à 3, la règle même de D85 — chaque explosion consomme une tranche et pose au plus deux
fois `chargePerNeighbour`, la chaîne ne s'arrête qu'à ce prix (§4.7) ; **une charge dont la rupture qui vaut pour
le héros est `skipAction`** — D84 écarte la perte du tour pour le héros, la donnée ne peut pas la rétablir ; un
jeton `{…}` d'un texte qui ne nomme pas un champ de la charge (§6.1). L'éditeur de contenu passe par le même
`fromJson` (§7).

**A4 — Les points restent des statuts ; une seule pose, `ChargeRules.pose`** *(T, filtre 5)*. Les points d'une
charge sont des entrées `StatusEffect` de son id, lues en somme (D83, ADR-104) ; comme elles sont posées sans
source (`effect_resolver.dart:24-115` ne retient la source que pour `might`), il n'y en a qu'une par id. Toute
pose d'une charge passe par une fonction pure, `ChargeRules.pose`, dans `lib/game/systems/charge_rules.dart`
(le voisinage de `cost_rules.dart` et `power_rules.dart`) : plafond, refus sur un porteur rompu, seuil, rupture
immédiate (§4.2). Ses appelants : `ApplyStatusEffectStrategy` (`strategies.dart:221-267`) pour ses trois cibles
— un `statusId` du catalogue va à `ChargeRules.pose`, tout autre à `createStatus` puis `addStatus` comme
aujourd'hui —, l'explosion du Feu (§4.7) et l'entrée de debug (§7.2). **`createStatus` perd ses trois cas `burn`,
`freeze`, `shock`** (`effect_resolver.dart:88-111`) : le statut d'une charge naît de son fichier, nom compris — un
fait à un seul endroit. **Sa forme est fixe** : type `debuff` — l'indicateur de l'ennemi le range avec les
altérations (`enemy_card.dart:139-150`) —, **durée 1**, jamais décomptée (A6 : le tic laisse l'entrée intacte,
filtre `duration > 0` compris, `entity_stats.dart:158`), quelle que soit la durée que déclare l'effet (A7) ; une
entrée dont les points tombent à 0 — rupture du Gel, résolution du Feu, déclin, fin de la Foudre chargée — est
**retirée**. L'état rompu ne se lit jamais sur l'entrée, toujours sur la piste (A5). Le nom d'une charge que lit
`CardRuleTexts._statusName` (`card_rule_texts.dart:65-69`, aujourd'hui par `createStatus(id, 0, 0)?.name`) vient
désormais du catalogue, dans la langue active : `CardRuleTexts.scale` reçoit le catalogue de ses deux appelants
(`card_component.dart:459`, `ui_card_helpers.dart:432`), et un `scaleWith: targetStatus` sur une charge — celui
d'*Exploitation*, en vague 8 — dit « Gel », jamais l'id.

**A5 — La piste d'une charge vit sur `EntityStats`, hors sauvegarde** *(T, filtre 5)*. Par porteur et par
élément, une **piste** (`ChargeTrack`) garde ce que les points ne disent pas : le seuil courant, le nombre de
ruptures du combat, l'état de rupture (§4.1), et **la rupture en vigueur pour ce porteur** — sa sorte et ses
paramètres, `heroRupture` pour le héros s'il y en a une, `rupture` sinon —, copiée du catalogue à la première pose
avec le seuil de départ (A8). Elle vit sur `EntityStats`, que partagent le héros et les
ennemis (`entity_stats.dart:7-41`) — la charge vit sur le porteur, quel qu'il soit (D83) —, dans un champ
`charges` que ni `toJson` ni `fromJson` n'écrivent (§8). Une seule méthode vide ensemble les statuts et les
pistes, et remplace les deux remises à zéro d'aujourd'hui : `run_controller.dart:569` (début de combat) et
`map_progression_manager.dart:37` (nœud résolu). La piste n'est pas une entrée de statut : elle n'entre ni dans la
liste que réconcilie l'indicateur par id (`status_indicator.dart:43-62`) ni dans celle du panneau du héros ; ce
qu'ils en montrent leur arrive par des **lignes d'affichage**, calculées des statuts et des pistes par une fonction
pure (§5.1). Sur `EntityStats`, elle suit le héros, que `CombatState` ne porte pas. L'accesseur de l'ennemi gelé
(A13) lit la sorte de la rupture en vigueur sur la piste, sans catalogue.

**A6 — Le tic ne touche pas les charges ; il reçoit leurs ids** *(T, filtre 4)*. `tickStatuses`
(`entity_stats.dart:144-162`) écrit aujourd'hui deux exceptions en dur, `freeze` (:147) et `burn` (:150, :158).
Il reçoit désormais l'ensemble des ids du catalogue, paramètre obligatoire, et laisse ces entrées intactes :
leurs points suivent les règles de la charge, jamais une durée. `CombatController.tickEnemyStatuses`
(`combat_controller.dart:352-360`), qui n'a aucun appelant dans `lib/`, disparaît plutôt que d'apprendre le
paramètre.

**A7 — La durée d'un effet qui pose une charge n'est ni lue ni affichée** *(T, filtres 7 puis 8)*. Les cartes
déclarent `duration` (facultatif, `card_data.dart:152`) et le modèle des deltas exige `durationPerLevel` pour tout
`addEffect` `apply_status` (`card_delta.dart:136-154`) — les trois runes et *Braise* en portent un. Relâcher cette
règle demanderait au modèle des deltas de connaître le catalogue des charges, un lien entre deux modèles que le
chargeur évite (chaque `fromJson` se suffit) ; les fichiers gardent donc leurs durées, la pose les ignore et aucun
texte de charge ne dit « pendant N tours » (§6). Le jour où une charge voudrait une durée, elle la déclarera dans
son fichier.

**A8 — Le seuil se calcule par porteur et se garde sur la piste** *(T, filtre 1 — D84)*. Seuil de départ : celui
du héros pour le héros, celui du boss pour un ennemi `isBoss` (`enemy_instance.dart:15`), celui de l'ennemi sinon
— élites comprises (D84) ; plus `thresholdGrowth` × ruptures du combat. Il est écrit sur la piste à la première
pose et à chaque rupture, si bien que les chiffres de l'affichage (§5.1) — points, seuil, pourcentage et bonus de
la rupture en vigueur — se lisent sur l'état ; seuls les noms viennent du catalogue (A2, A16). Le porteur est nommé
par l'appelant (héros, ennemi, boss) : `EntityStats` ne sait pas qui il est.

**A9 — Ce que dure une rupture, et les deux fermetures de phase** *(T, filtre 1 — D84, D86)*. La durée est une
propriété de la sorte, écrite une fois avec elle : `skipAction` dure jusqu'à la prochaine action du porteur, qu'il
perd ; `weakenDealt`, pendant le prochain tour entier du porteur ; `amplifyHits`, jusqu'à la fin de la phase en
cours ; `explode` ne dure pas. Deux **fermetures de phase** portent les fins : la fin du tour du joueur (au début de
`startEnemyTurn`, avant toute chose) et la fin de la phase ennemie (dans `endEnemyTurn`, avant les intentions,
`turn_phase_manager.dart:80-92`). À chacune, chez **tous** les porteurs, héros et ennemis : une Foudre chargée
retombe à 0 (D86, « jusqu'à la fin du tour en cours ») ; à la fin du tour du joueur seulement, un gel du héros
**actif** prend fin (D84, « pendant son prochain tour »). Les états intermédiaires sont en §4.1.

**A10 — Au tour d'un porteur, le Feu se résout d'abord** *(T, filtre 1 — D85)*. Au début de la phase ennemie,
l'ordre devient : la fermeture du tour du joueur (A9) ; **la chaîne du Feu**, vague après vague (§4.7) ; puis les
autres statuts de chaque ennemi — Poison, Éveil de Puissance, Métallisation, le tic, les déclins —
(`status_effect_processor.dart:83-134`, sans le Feu) ; puis `cleanDeadEnemies` (`combat_controller.dart:373-418`),
une seule fois, après tout. Au début du tour du héros, de même : son Feu d'abord, puis le reste de
`processPlayerStatuses` (`status_effect_processor.dart:12-79`). D85 dit que toute la charge se résout au tour du
porteur et que seul un porteur tué **avant** son tour perd son Feu : un ennemi que son Poison achève au début de
son tour est mort pendant son tour, son Feu doit se résoudre ; le résoudre d'abord le garantit sans règle de
plus. Le Feu reste aussi devant la Métallisation, à la place qu'occupait la Brûlure (`status_effect_processor.dart:102-131`).

**A11 — Une vague de la chaîne est simultanée** *(T, filtre 1 — D85)*. Chaque vague se calcule sur l'état de la
rangée **au début de la vague** : tous ses porteurs vivants se résolvent ensemble, puis leurs dégâts s'appliquent,
puis le Feu des explosions se pose — sur les vivants seulement — et forme la vague suivante. Un porteur vivant au
début de la vague se résout même si la vague le tue : sa rupture et ses explosions sont calculées avant
(« un porteur que sa rupture tue explose quand même »). Un ennemi mort pendant la chaîne garde sa place jusqu'à la
fin, ne reçoit plus ni dégâts ni Feu et ne rapproche pas ses voisins ; la rangée se resserre au
`cleanDeadEnemies` qui suit (D85). C'est la lecture que fait l'exemple de l'étude (§4.7).

**A12 — Le contrôleur joue la chaîne vague par vague ; Flame l'appelle et la montre** *(T, filtres 5 puis 6)*.
La règle des couches veut que le contrôleur décide et que Flame lise ; « lisibles » (fiche 8.7) veut qu'on voie
chaque vague. `startEnemyTurn` ferme le tour du joueur et joue la **première** vague ; une méthode neuve,
`resolveNextFireWave`, joue la suivante et rend `false` quand il n'y en a plus ; une autre,
`resolveEnemyStatuses`, joue le reste des statuts et `cleanDeadEnemies`. Chaque vague laisse dans `CombatState` un
**compte rendu** — pour chaque porteur résolu : ses tranches, ses dégâts, et pour chaque voisin les dégâts et le
Feu reçus —, que Flame lit pour animer la vague, et qui retombe à `null` après la dernière ; il n'est pas
sauvegardé. `HerosDraftGame._enemyRipostePhase` (`heros_draft_game.dart:369-401`) appelle ces étapes l'une après
l'autre, avec un délai entre deux vagues ; `game_screen.dart:366-379` câble les deux rappels neufs. Le contrat de `startEnemyTurn` change donc : les tests qui l'appelaient pour tout le début de phase passent par un helper (§9). Ainsi l'état
ne montre jamais les PV d'une vague avant qu'elle soit animée, et Flame ne calcule aucune règle.

**A13 — L'ennemi gelé se lit sur l'état avant que Flame ne l'anime** *(T, filtre 5)*. `EnemyInstance` gagne un
accesseur, vrai quand l'une de ses pistes de sorte `skipAction` est rompue, que lisent `EnemyCard` (comme
`effectiveIntent`, `enemy_card.dart:36`), le panneau des intentions (`enemy_intents_panel.dart:66`) et
`resolveEnemyIntent`. Flame le lit **avant** de lancer l'animation de l'action (`heros_draft_game.dart:381-393`) :
un ennemi gelé ne fonce pas, il joue l'animation du gel perdu (P-c, §5.2) ; Flame appelle ensuite
`onResolveEnemyIntent` comme pour tout ennemi — **qu'il ait une intention ou non**, le test `intent == null`
venant après —, et le contrôleur, qui lit le même accesseur, **consomme le gel sans rien résoudre**. L'intention
perdue est consommée sans code neuf : `endEnemyTurn` tire l'intention suivante du cycle pour tous les ennemis
(`turn_phase_manager.dart:80-83`, `combat_controller.dart:430-457`).

**A14 — Le pipeline reçoit le catalogue ; une étape neuve après la Faiblesse, une étape remplacée**
*(T, filtres 1 puis 5)*. `DamagePipeline.calculate` (`damage_pipeline.dart:10-66`) reçoit le catalogue en
paramètre obligatoire — ses trois appelants le lui passent : `turn_phase_manager.dart:108`, `strategies.dart:98`,
`tutorial_engine.dart:410` (`data.charges`). Après la Faiblesse (:19-24), une étape neuve applique la rupture
`weakenDealt` **active** de l'attaquant : −50 % du résultat de la Faiblesse, arrondi comme elle — deux
réductions l'une après l'autre (D84 : 25 % puis 50 % laissent 37,5 % du coup). L'étape de l'Électrocution
(:37-50) devient celle des charges `amplifyHits` du défenseur, à la même place, après le critique et avant
Vulnérable (D86). Le Gel quitte `EnemyInstance.effectiveIntent` (`enemy_instance.dart:29-32`) : l'intention
affichée n'est plus réduite, et `enemy_instance.dart` cesse d'importer un service (`:3`), ce qu'ADR-111 laissait
à la file.

**A15 — Une part sous le seuil s'arrondit à la demie supérieure** *(T, filtre 8)*. Points × valeur par point ×
`belowThresholdPercent` / 100, en arithmétique entière, la demie vers le haut — la forme d'ADR-105 D6. Aux valeurs
des décisions (4 par point pour le Feu, 2 pour la Foudre, à 50 %), aucun arrondi n'a lieu ; la règle ne sert qu'aux valeurs que
le propriétaire choisira.

**A16 — Les textes d'une charge viennent de son fichier** *(T, filtre 5)*. Nom, nom de l'état rompu et
description vivent dans le fichier de la charge, en `_fr` et `_en` ; la description porte des jetons que remplit
la donnée de la même charge (§6.1) — le précédent des runes (ADR-105 D4). Les ARB ne gardent que des phrases à
trous (« Applique {amount} {name}. ») ; les six clés `cardDescStatus{Burn,Freeze,Shock}[Duration]`
(`app_fr.arb:155-160`), `effectLineBurn` (`:301`) et `statusFreezeHint` (`:333`), avec leurs sœurs anglaises
(`app_en.arb:406-443`, `:905`, `:1078`), disparaissent, comme les phrases écrites en dur en français et en anglais
dans les parenthèses des infobulles (`ui_card_helpers.dart:408-427`, `card_component.dart:432-452`), le panneau
des statuts du héros (`status_effects_panel.dart:131-151`) et le tutoriel (§6.3).

**A17 — L'éditeur de contenu gagne une onzième catégorie** *(T, filtre 5)*. Toute source du chargeur a son
descripteur, et un test le compte (`entity_descriptor_test.dart:20`, `:39`) : `EntityCategory.charge`, chemin
`charges/<id>.json` (§7.1).

**A18 — L'exemple de l'étude se teste à ses valeurs, la donnée livrée à part** *(T, filtre 8)*. Le test de la
chaîne construit ses charges aux valeurs de l'exemple (4, 12, 3, 1) et attend 48, 64, 48 ; un test de donnée, à
part, vérifie que les trois fichiers livrés portent les valeurs de D84 à D86. Quand le propriétaire corrigera une
valeur (C10), seul le second changera, et le premier gardera la règle.

**A19 — Deux parties, l'animation en dernier** *(T, filtres 7 puis 8)*. §10.

### 1.4. Les questions ouvertes

Aucune question ouverte : les cinq questions P posées à l'arrêt du 15/11 sont tranchées en §1.2, leurs options
écartées sont au fichier de vérifications, et aucune question de classe D ne se pose — rien n'exige d'amender
une décision acquise, et la prémisse relevée en §2.1 (tous les ennemis d'un combat de boss portent `isBoss`)
n'en appelle pas.

---

## 2. Périmètre

**Dans le lot** : le cadre des charges en donnée — trois fichiers, leur modèle, leur source, leur validation, leur
catégorie d'éditeur — ; le moteur — la piste, la pose, le seuil, le déclin, les quatre sortes de rupture, la
chaîne du Feu, l'ordre du tour, le pipeline — ; les dix contenus relus (P-b) ; l'affichage des charges, de
l'ennemi gelé et du héros gelé, les infobulles et les textes ; le tutoriel ; les trois animations de rupture
(P-c) ; l'entrée de debug (P-e) ; le retrait du Gel du barème de P-1.

| Hors du lot | Où |
|:---|:---|
| La tranche 3 et ses cartes — les quatre élémentaires du lot *Marque*, le déclencheur de D34, *Sanctifié* et sa Faiblesse | Vague 8 |
| L'étourdissement, les épines | P-44 lot 2 |
| La calibration (P-16) | Après `0.6.0` |
| **L'explosion du Feu à la mort** d'un porteur | Écartée pour l'instant (D85) |
| Un ennemi élémentaire : le cadre est symétrique, mais aucun ennemi ne pose de charge — `IntentType` ne connaît que `attack`, `defend`, `buff` (`enemy_intent.dart:1`) | Plus tard |
| Tout changement de Vulnérable, de Faiblesse, du Poison | — |
| Tout rééquilibrage hors des dix contenus qui posent une charge | — |
| Les émojis des statuts ennemis (`status_indicator.dart:141-166`) et les icônes des faces des cartes passés sur `effect_icons.json` | Plus tard, déjà à la ROADMAP (spec de la vague 5, §2, P-6) |
| `tool/simulations/` : gelé depuis ADR-108 | — |

### 2.1. Les transitions

| Frontière | État | Réglé par |
|:---|:---|:---|
| `0.5.8` → `0.5.9` | En `0.5.7` et `0.5.8`, le Gel suit le barème de P-1 (`proportional_status.dart:22-23`) ; la Brûlure et l'Électrocution gardent leur règle d'avant — un tic qui perd 1 (`entity_stats.dart:150-155`), sa valeur ajoutée à chaque coup (`damage_pipeline.dart:37-50`) ; en `0.5.9`, ils deviennent des charges, et les dix contenus qui les posent sont relus | Ce lot ; Vulnérable, Faiblesse et Poison ne changent pas |
| `0.5.9` → `0.6.0` | Les quatre élémentaires du lot *Marque* et les cartes de *Sanctifié* qui posent de la Faiblesse s'écriront sur les règles livrées ici. Elles n'exigent aucun moteur neuf : une carte qui pose une charge pose un `statusId` du catalogue ; `scaleWith: targetStatus` (*Exploitation*) lit la somme des entrées de même id, ce que sont les points d'une charge ; la Faiblesse garde son barème | Fiche 8.8 |
| Les combats de l'acte 1 | Un combat normal ne compte qu'un ennemi à l'acte 1, un de plus par acte (`encounter_system.dart:66-71`) : le Feu n'a de voisins qu'à partir de l'acte 2, et la chaîne de l'exemple demande trois ennemis, l'acte 3. Le test manuel passe d'acte par le menu de debug (§9.1) | — |
| Les combats de boss | **Tous les ennemis d'un combat de boss portent `isBoss`** (`combat_controller.dart:67`, `:161`), un seul jusqu'à l'acte 5, deux à partir de l'acte 6 (`encounter_system.dart:62`, `:78-79`) — tous ont l'échelle et les PV d'un boss (`enemy_card.dart:52`). Le seuil de 6 vaut donc pour chacun d'eux : D84 nomme `isBoss` | — |
| Sauvegardes de `0.5.8` | Elles ne portent ni charge ni piste : les statuts sont vides entre deux combats (§8) | Avant la `1.0.0`, rien |

---

## 3. Données

### 3.1. Le fichier d'une charge

| Clé | Type | Sens |
|:---|:---|:---|
| `id` | chaîne | Injecté par le nom du fichier ; l'id du statut que posent les cartes |
| `name_fr`, `name_en` | chaîne | Le nom affiché (P-a) |
| `brokenName_fr`, `brokenName_en` | chaîne | Le nom de l'état rompu — exigé pour une rupture qui dure (`skipAction`, `weakenDealt`, `amplifyHits`), refusé pour `explode` |
| `description_fr`, `description_en` | chaîne à jetons | La règle, pour un ennemi porteur (§6.1) |
| `heroDescription_fr`, `heroDescription_en` | chaîne à jetons | La règle sur le héros, exigée si et seulement si `heroRupture` est présent |
| `threshold` | entier ≥ 1 | Le seuil de départ d'un ennemi, élites comprises |
| `bossThreshold`, `heroThreshold` | entier ≥ 1, facultatif | Le seuil de départ d'un boss, du héros ; absent : `threshold` |
| `thresholdGrowth` | entier ≥ 0 | La montée du seuil à chaque rupture, pour le reste du combat |
| `overcharge` | booléen | `false` : la pose est plafonnée au restant, et un porteur rompu ne reçoit rien ; `true` : libre |
| `decay` | entier ≥ 0 | Les points perdus au tour du porteur, s'il n'est pas rompu |
| `breaksOn` | `threshold` · `bearerTurn` | La rupture à l'atteinte du seuil, ou au tour du porteur |
| `belowThresholdPercent` | entier de 0 à 100 | La part de l'effet par point sous le seuil (D83, « la moitié ») ; exigé pour `explode` et `amplifyHits`, refusé pour les autres |
| `rupture` | objet | `kind` et ses paramètres, ci-dessous |
| `heroRupture` | objet, facultatif | La rupture quand le porteur est le héros ; absent : `rupture` |

| `kind` | Paramètres | Moment exigé | Effet |
|:---|:---|:---|:---|
| `skipAction` | — | `threshold` | Le porteur perd toute sa prochaine action (§4.5). Refusé comme rupture du héros (A3) |
| `weakenDealt` | `percent` (1 à 100) | `threshold` | Pendant le prochain tour du porteur, ses cartes et ses signatures infligent `percent` % de dégâts en moins (§4.6) |
| `explode` | `damagePerPoint` ≥ 0, `explosionDamage` ≥ 0, `chargePerNeighbour` ≥ 0 | `bearerTurn` | Toute la charge se résout et explose sur les voisins (§4.7) |
| `amplifyHits` | `bonusPerPoint` ≥ 1 | `threshold` | Chaque coup reçu fait plus, davantage une fois rompue (§4.8) |

Les trois fichiers, aux valeurs de D84 à D86 et aux noms de P-a, réponse du propriétaire (§1.2) — les descriptions en §6.1 :

```json
{ "id": "freeze", "name_fr": "Gel", "name_en": "Freeze",
  "brokenName_fr": "Gelé", "brokenName_en": "Frozen",
  "threshold": 3, "bossThreshold": 6, "heroThreshold": 5, "thresholdGrowth": 1,
  "overcharge": false, "decay": 1, "breaksOn": "threshold",
  "rupture": { "kind": "skipAction" },
  "heroRupture": { "kind": "weakenDealt", "percent": 50 } }
```

```json
{ "id": "burn", "name_fr": "Feu", "name_en": "Burn",
  "threshold": 3, "thresholdGrowth": 0,
  "overcharge": true, "decay": 0, "breaksOn": "bearerTurn", "belowThresholdPercent": 50,
  "rupture": { "kind": "explode", "damagePerPoint": 4, "explosionDamage": 12, "chargePerNeighbour": 1 } }
```

```json
{ "id": "shock", "name_fr": "Foudre", "name_en": "Shock",
  "brokenName_fr": "Chargé", "brokenName_en": "Charged",
  "threshold": 3, "thresholdGrowth": 0,
  "overcharge": true, "decay": 1, "breaksOn": "threshold", "belowThresholdPercent": 50,
  "rupture": { "kind": "amplifyHits", "bonusPerPoint": 2 } }
```

Ce que D83 demande de déclarer s'y lit : le seuil de départ (`threshold` et ses deux variantes), sa montée
(`thresholdGrowth`), le plafond de pose (`overcharge`), le déclin (`decay`), le moment et la sorte de la rupture
(`breaksOn`, `rupture.kind`) ; une rupture propre au héros (`heroRupture`). Une charge future — l'Ombre, l'Acide —
est un fichier, et au besoin une sorte de rupture de plus.

### 3.2. La validation

A3. Les refus portent le nom de la clé et la règle ; le chargeur les accumule avec ceux des autres catégories
(`throwIfFailed`, `game_data_service.dart:170`). La règle du Feu se lit : **un seuil de Feu inférieur à 3 est
refusé**, parce que `chargePerNeighbour` vaut 1 (D85).

### 3.3. Le modèle, la source et les comptes

| Élément | Changement |
|:---|:---|
| `lib/models/data/charge_data.dart` *(nouveau)* | `ChargeData`, `ChargeRupture` (la sorte et ses paramètres), `fromJson` qui valide (A3), `toJson` pour l'éditeur, l'accès au seuil de départ par porteur (A8) et le remplissage des jetons (§6.1) |
| `game_data_registry.dart` | `charges`, vide par défaut (A2) |
| `game_data_service.dart` | La onzième `EntitySource` ; `chargeCatalogProvider` (A2) |
| `pubspec.yaml` | `dart run tool/sync_assets.dart` ajoute `- assets/data/charges/` ; `--check` passe |
| `CLAUDE.md:43` | `charge_data.dart` rejoint la liste des modèles |
| `CLAUDE.md:78-79`, `:85` ; `README.md:69-71` | L'arbre gagne `charges/<id>.json` parmi les catalogues plats ; la liste « To add or modify » gagne la charge |

**Les comptes** : `entity_id_convention_test.dart:72-78`, 130 → **133** fichiers d'entité ;
`real_bundle_load_test.dart`, `registry.charges` a 3 entrées, les autres comptes inchangés
(`registry.forgeUpgrades` reste à 16, `:102`) ; `entity_descriptor_test.dart:20` et `:39`, 10 → **11**.

### 3.4. Les contenus relus

Dix fichiers posent une charge : les neuf de la fiche et *Braise* (`ember`), une mineure de *Projectile Magique*
(`classes/mage/skills/magic_missile.json:56-74`), que la fiche ne nommait pas. **Aucun ne change de `statusId`**
(A1). Valeurs : celles de P-b (a), la réponse du propriétaire (§1.2) — *Embrasement* `value` 4 → 3
(`kindle.json:16`), *Congelant* `valuePerLevel` 2 → 1 (`freezing.json:18`) ; les huit autres ne changent pas. Les
`duration` et `durationPerLevel` restent (A7). Textes : §6.1. Aucun ennemi, aucune
relique, aucun passif, aucun événement ni aucune récompense de niveau ne pose `burn`, `freeze` ou `shock`
(re-mesuré : `git grep -n -w -e freeze -e burn -e shock -- assets` ne rend que ces dix fichiers et
`effect_icons.json:14-16`, qui garde ses trois entrées).

Les dix contenus, relus par le rôle `game_designer`, avant → après :

| Contenu | `0.5.8` | `0.5.9` | Raison |
|:---|:---|:---|:---|
| *Boule de Feu* (`cards/fireball.json`) | 2 mana, 6 dégâts, 2 Brûlure | 6 dégâts, **2 Feu** — inchangé | Seule, 6 + 4 au tour de l'ennemi, contre 6 + 2 + 1 aujourd'hui ; deux, ou une avec *Brûlant*, passent le seuil |
| *Trait de Glace* (`cards/ice_bolt.json`) | 1 mana, 4 dégâts, 2 Gel | 4 dégâts, **2 Gel** — inchangé | Seul il prépare (2/3) ; un second Gel gèle. À 3, un mana ôterait le tour d'un ennemi à chaque premier jet |
| *Coup de Tonnerre* (`cards/thunder_clap.json`) | 1 mana, 4 dégâts puis 1 Électrocution | 4 dégâts puis **1 Foudre** — inchangé | Frappe avant de poser : il prépare (D86, étude §12) |
| *Nova de givre* (`cards/mana_flux/frost_nova.json`) | 2 mana, 2 Gel à tous | **2 Gel** à tous — inchangé | Le cœur du lot Arcaniste ; avec 1 Puissance « altération », elle gèle la salle une fois, puis le seuil monte à 4 : le risque que l'étude signale (§3), laissé au test du propriétaire |
| *Embrasement* (`cards/mana_flux/kindle.json`) | 1 mana, 4 Brûlure | **3 Feu** (4 → 3) | Une tranche exacte : la première explosion se voit au premier jet (12, puis 12 et 1 Feu à chaque voisin). À 4, le quatrième point ne ferait que 2, et la Puissance du Mage le porterait à deux tranches (24, puis 24 et 2 Feu à chaque voisin) pour un mana |
| *Rafale d'étincelles* (`cards/mana_flux/spark_barrage.json`) | 2 mana, 1 Électrocution puis 3 × 3 | **1 Foudre** puis 3 × 3 — inchangé | D86 en donne les chiffres : 12 sur un ennemi neuf, 27 sur un ennemi à 2 points |
| *Brûlant* (`forge_upgrades/burning.json`) | +1 Brûlure par niveau | **+1 Feu** par niveau — inchangé | D33 |
| *Congelant* (`forge_upgrades/freezing.json`) | **+2 Gel** par niveau (barème de P-1) | **+1 Gel** par niveau (2 → 1) | D33 : les runes élémentaires « restent en piles » ; le brainstorm, §8 (tableau des runes, ligne `burning`, `freezing`, `shocking`), leur donne « +1 pile par niveau », comme à ses deux sœurs. Le 2 de la vague 5 gardait −50 % au premier usage ; sous le seuil, *Congelant* 2 poserait 4 points et gèlerait d'un coup, deux fois de suite (3 puis 4) |
| *Surchargé* (`forge_upgrades/shocking.json`) | +1 Électrocution par niveau | **+1 Foudre** par niveau — inchangé | D33 |
| *Braise* (`classes/mage/skills/magic_missile.json`, `ember`) | +1 Brûlure par niveau | **+1 Feu** par niveau — inchangé | Une mineure ; avec la Puissance du Mage et *Nova*, elle charge toute la rangée |

### 3.5. Ce qui disparaît

- `ProportionalStatus.freeze` (`proportional_status.dart:22-23`) et ses lecteurs : `enemy_instance.dart:29-32`,
  `card_component.dart:439-445`, `ui_card_helpers.dart:415-420`, `tutorial_elements_widget.dart:59-66` ;
  `ProportionalStatus` garde Vulnérable et Faiblesse, inchangés ;
- les trois cas de `createStatus` (A4) ;
- les deux exceptions en dur de `tickStatuses` (A6) et `tickEnemyStatuses` ;
- le Gel lu à l'attaque (`turn_phase_manager.dart:106`, `:116-128`), le tic de Brûlure
  (`status_effect_processor.dart:87`, `:96-98`, `:105-107`), l'Électrocution lue par `firstWhere`
  (`damage_pipeline.dart:37-50`) ;
- les clés ARB et les phrases en dur d'A16.

---

## 4. Le moteur

### 4.1. Les points, la piste et l'état de rupture

**Les points** d'une charge sur un porteur : la somme des valeurs de ses entrées de statut de même id (D83,
ADR-104) ; l'entrée elle-même a une forme fixe (A4). **La piste** (A5), par porteur et par élément, porte : le
**seuil courant** (A8), le **nombre de ruptures** du combat, la **rupture en vigueur** pour ce porteur — sa sorte
et ses paramètres, `heroRupture` pour le héros s'il y en a une, `rupture` sinon —, et l'**état** :

| État | Sens | Sortes |
|:---|:---|:---|
| aucun | Pas de rupture en cours | toutes |
| **rompu, en attente** | La rupture a eu lieu ; son effet attend la prochaine action ou le prochain tour du porteur | `skipAction` (jusqu'à l'action perdue), `weakenDealt` (jusqu'au début du prochain tour du héros) |
| **rompu, actif** | L'effet joue | `weakenDealt` (pendant ce tour du héros), `amplifyHits` (jusqu'à la fermeture de la phase, A9) |

Une piste naît à la première pose sur le porteur, et meurt avec ses statuts (A5) : au début de chaque combat et à
la résolution d'un nœud pour le héros ; un ennemi naît sans piste.

### 4.2. La pose

`ChargeRules.pose(porteur, charge, points)`, dans cet ordre :

1. **Rompu et sans surcharge** (`overcharge: false`, état autre qu'« aucun ») : rien n'est posé — « un porteur gelé
   n'en reçoit plus » (D84).
2. **Plafond** : sans surcharge, les points posés sont bornés au restant, `seuil − points` (D84) ; avec, tous.
3. **Rupture au seuil** (`breaksOn: threshold`, état « aucun ») : si les points atteignent le seuil, la charge
   rompt **aussitôt** (D84, D86) — ruptures + 1, seuil + `thresholdGrowth`, état selon la sorte (§4.5, §4.6,
   §4.8).
4. `breaksOn: bearerTurn` : la pose s'arrête au point 2 ; la rupture attend le tour du porteur (§4.7).

**Les points posés** sont la valeur de l'effet, bonus de Puissance compris : la Puissance « altération » ne vise
qu'un statut posé sur un ennemi (`power_rules.dart:27-32`) et le seul premier `apply_status` de la résolution
(Q11, ADR-111 D5) ; elle s'ajoute **avant** le plafond. Une rune élémentaire pose par `ApplyStatusEffectStrategy`,
avant les effets de la carte (ADR-105 D1, D2) : *Surchargé* sur *Coup de Tonnerre* pose donc sa Foudre avant le
coup de la carte. Une carte à cible `allEnemies` pose sur chacun, chaque porteur avec sa propre piste.

### 4.3. Le seuil

A8. Le seuil d'un porteur sans piste est le seuil de départ de son genre ; une rupture l'élève de
`thresholdGrowth`, pour le reste du combat. Aux valeurs de D84 : le Gel d'un ennemi passe de 3 à 4 puis 5, d'un
boss de 6 à 7, du héros de 5 à 6 ; le Feu et la Foudre restent à 3 pour tous.

### 4.4. Le déclin

Au tour du porteur, une charge dont l'état est « aucun » perd `decay` points, sans descendre sous 0 : le Gel
« s'il n'a pas gelé » (D84), la Foudre « sous le seuil » (D86) ; le Feu a `decay: 0`, sa charge se résout à
chaque tour (§4.7). Le tour d'un ennemi est le début de la phase ennemie (A10) ; celui du héros, le début de son
tour (`run_controller.dart:581-621`). *Nova de givre* laisse un ennemi à « ❄ 2/3 » ; après son tour, il est à
« ❄ 1/3 » (étude §3).

### 4.5. Le Gel d'un ennemi : `skipAction`

À la rupture, le Gel retombe à 0 et la piste passe « rompu, en attente » (D84). À son tour d'action, l'ennemi gelé
**ne fait rien** — attaque, défense ou renforcement : `resolveEnemyIntent` consomme le gel (état « aucun ») sans
résoudre l'intention (A13). L'intention perdue est consommée : la suivante de son cycle s'affiche au tour d'après
(A13). **Ses statuts se résolvent quand même** (D84) : son Poison et son Feu au début de la phase ennemie, avant
son action. Un ennemi gelé pendant la phase ennemie, avant son action, la perd ; après, il perdra la suivante —
cas sans contenu aujourd'hui, réglé par la même règle.

### 4.6. Le Gel du héros : `weakenDealt`

À la rupture (seuil 5, D84), le Gel retombe à 0 et la piste passe « rompu, en attente ». **Le héros ne perd pas son
tour** : au début de son prochain tour, l'état passe « actif » ; pendant ce tour, chaque coup de ses cartes et de
ses signatures — chaque coup d'un multi-coups, la part d'éclaboussure de *Ricochant* comprise, puisqu'elle passe
le pipeline avec le héros pour attaquant (`strategies.dart:60-80`) — est réduit de 50 % (A14). Les dégâts de ses
statuts ne le sont pas : ils se résolvent au tour de leur porteur, hors du pipeline. À la fin de son tour (A9),
l'état revient à « aucun ». Seuil, montée, déclin et plafond sont ceux du Gel. Exemple : 8 dégâts, 1 Faiblesse
(−25 %) et gelé : 8 → 6 → 3, 37,5 % du coup (D84).

### 4.7. Le Feu : `explode` et la chaîne

**La résolution d'un porteur** de `p` points, seuil `T` : `n = p ÷ T` tranches complètes, `r = p − n × T` points de
reste. Le porteur prend `n × T × damagePerPoint` plus la part de reste (A15 : `r × damagePerPoint × 50 %`) ; chaque
tranche **explose** : chacun de ses voisins prend `explosionDamage` et reçoit `chargePerNeighbour` point de Feu,
soit `n × 12` dégâts et `n` Feu ; le reste n'explose pas. Puis le Feu du porteur retombe à 0 (D85). 5 points :
3 × 4 + 2 × 2 = **16** au porteur, **12 et 1 Feu** à chaque voisin. **Contre les dégâts du Feu, l'Armure de la
cible absorbe ; ni Vulnérable, ni critique, ni Faiblesse** — comme la Brûlure et le Poison aujourd'hui
(`EntityStats.takeDamage`, `status_effect_processor.dart:102-107`) : P-d (a), la réponse du propriétaire (§1.2).

**Les voisins** : l'ennemi à gauche et l'ennemi à droite du porteur dans `CombatState.enemies`, l'ordre même de la
rangée Flame (`layout_system.dart:119-121`, `state_sync_system.dart:127-142` : les cartes existantes gardent leur
rang, les neuves s'ajoutent au bout). Un bout de rangée n'a qu'un voisin, un ennemi seul aucun. **Le héros
porteur n'a pas de voisin** : il ne prend que sa part (D85). Un voisin mort (PV ≤ 0) pendant la chaîne compte
dans la rangée mais ne reçoit rien (A11).

**La chaîne** (D85, A11, A12), au début de la phase ennemie :

1. **Vague 1** : tous les ennemis vivants qui portent du Feu se résolvent ensemble.
2. Le Feu posé par les explosions de la vague forme la **vague suivante** : ses porteurs, et eux seuls, se
   résolvent ensemble, de la même façon — y compris un porteur de la vague précédente qui en reçoit de nouveau.
3. La chaîne s'arrête quand une vague ne pose plus de Feu. Ce Feu-là ne reçoit **aucun bonus de Puissance** : une
   explosion n'est pas une carte (Q11).

**L'exemple de l'étude, §11**, aux valeurs de D85, est un test (§9) — A, B, C ; B porte 9 Feu, A et C aucun :

| Vague | Ce qui se résout | A | B | C |
|:---:|:---|:---:|:---:|:---:|
| 1 | B : 3 tranches → 36 à B ; 3 explosions → 36 et 3 Feu à A et à C | 36 | 36 | 36 |
| 2 | A et C : 1 tranche chacun → 12 à chacun ; une explosion chacun → 12 + 12 et 2 Feu à B | 12 | 24 | 12 |
| 3 | B : 2 points, sous le seuil → 4 à B, pas d'explosion ; fin | — | 4 | — |
| | **Total** | **48** | **64** | **48** |

**La chaîne s'arrête toujours.** Une explosion consomme une tranche de `T` points et en pose au plus
`2 × chargePerNeighbour` ; tant que `T > 2 × chargePerNeighbour` — ce que la validation impose (A3) —, le Feu en jeu
baisse strictement à chaque vague où une explosion a lieu, et une vague sans explosion ne pose rien. Aucune borne
de boucle de plus.

**La mort** (D85) : un porteur que sa rupture tue explose quand même (A11) ; un ennemi mort pendant la chaîne garde
sa place jusqu'à la fin ; la rangée se resserre au `cleanDeadEnemies` qui suit les statuts (A10) ; **un porteur
tué avant son tour perd son Feu sans exploser** — tué par une carte, il quitte l'état par le `cleanDeadEnemies` qui
suit chaque carte jouée (`combat_controller.dart:324`), son Feu avec lui. L'explosion à la mort n'est pas de ce
lot.

**Le compte rendu de vague** (A12) : à la fin de chaque vague, `CombatState` porte, pour chaque porteur résolu, ses
tranches et ses dégâts, et pour chaque voisin touché ses dégâts et son Feu reçu ; Flame le lit pour animer la
vague (P-c, §5.2), puis appelle la suivante.

### 4.8. La Foudre : `amplifyHits`

**Sous le seuil**, chaque coup reçu fait `points × bonusPerPoint × 50 %` de plus — **+1 par point** (D86). **À
l'atteinte du seuil**, le porteur est **chargé** aussitôt (§4.2, point 3 ; état « rompu, actif ») : chaque coup
reçu fait **+2 par point**, les coups suivants de la même carte compris. **Surcharge libre** : un point posé sur un
porteur chargé ajoute +2 à chacun des coups suivants. À la fermeture de la phase en cours (A9), la Foudre d'un
porteur chargé retombe à 0 et l'état à « aucun » ; un héros chargé pendant la phase ennemie l'est contre tous les
coups de cette phase (D86). Le déclin : §4.4.

Le bonus se lit **à chaque coup**, sur les points du moment (§9.2 n° 2) : *Rafale d'étincelles* sur un ennemi neuf
pose 1 point puis frappe 3 × (3 + 1) = **12** ; sur un ennemi qui en porte 2, elle l'amène à 3, il est chargé, et
elle frappe 3 × (3 + 6) = **27** (D86). *Coup de Tonnerre* frappe avant de poser : il prépare.

### 4.9. Le pipeline

`DamagePipeline.calculate`, dans l'ordre (A14) :

| # | Étape | Changement |
|:---:|:---|:---|
| 1 | Faiblesse de l'attaquant, barème de P-1 (`damage_pipeline.dart:19-24`) | Aucun |
| 1 bis | **Rupture `weakenDealt` active de l'attaquant** : −`percent` % du résultat de l'étape 1, arrondi comme elle | **Neuve** — le héros gelé |
| 2 | Critique de l'attaquant (`:26-35`) | Aucun |
| 3 | **Charges `amplifyHits` du défenseur** : leur bonus, sous le seuil ou chargé | Remplace l'Électrocution (`:37-50`) |
| 4 | Vulnérable du défenseur, barème de P-1 (`:52-58`), qui amplifie aussi l'étape 3 | Aucun |

L'étape 1 bis ne vise que l'attaquant porteur d'une rupture active, donc, aujourd'hui, le seul héros gelé : un
ennemi gelé n'attaque pas.

### 4.10. L'ordre du tour

| Moment | Ce qui se passe | Où |
|:---|:---|:---|
| **Début du tour du héros** | Mana, Armure à 0, reliques `startOfTurn`, puis les statuts du héros : **son Feu d'abord** (sa part seule), puis Poison, Éveil, le tic (charges exemptes, A6), Métallisation, Source de Mana, puis les **déclins** ; un gel du héros « en attente » passe « actif » ; puis les passifs | `run_controller.dart:581-621` ; `status_effect_processor.dart:12-79` |
| Tour du héros | Les cartes et signatures posent des charges (§4.2) ; le Gel et la Foudre peuvent rompre aussitôt ; les morts sortent après chaque carte | `combat_controller.dart:296-325` |
| **Fin du tour du héros** | `RunController.endTurn` (passif, reliques), puis Flame lance la phase ennemie | `game_screen.dart:629-631` |
| **Début de la phase ennemie** | (1) **fermeture du tour du joueur** : toute Foudre chargée retombe à 0, chez tous les porteurs ; le gel actif du héros prend fin (A9) ; (2) **la chaîne du Feu**, vague 1 puis les suivantes, une à une, que Flame anime (A12) ; (3) les autres statuts de chaque ennemi, puis les **déclins** ; (4) `cleanDeadEnemies` | `turn_phase_manager.dart:60-77` ; `heros_draft_game.dart:369-375` |
| Actions des ennemis | Pour chacun, dans l'ordre de la rangée : **gelé** → l'animation du gel perdu, puis le gel consommé, rien de résolu ; sinon l'animation de l'intention, puis sa résolution | `heros_draft_game.dart:377-396` ; `turn_phase_manager.dart:95-158` |
| **Fin de la phase ennemie** | **Fermeture de la phase ennemie** : toute Foudre chargée retombe à 0, chez tous les porteurs — un gel du héros « en attente » reste ; puis les intentions suivantes (l'intention perdue d'un ennemi gelé est ainsi consommée), le tour suivant | `turn_phase_manager.dart:80-92` |

Le déroulé de Flame devient : `onStartEnemyTurn` ; animation de la vague 1 s'il y en a une ; tant que
`onResolveFireWave` rend vrai, animation de la vague et délai ; `onResolveEnemyStatuses` ; délai
(`combatDelayAfterTicksMs`) ; les actions des ennemis — la liste copiée après ce délai, comme aujourd'hui
(`heros_draft_game.dart:377`), qui n'a plus les morts de la chaîne ; `onEndEnemyTurn`. Un délai neuf,
`combatDelayFireWaveMs`, rejoint `game_constants.dart:62-74` (environ 600 ms, P-c).

### 4.11. Ce que Flame lit, et quand

Les trois couches restent séparées : le contrôleur décide, Flame lit l'état et joue l'animation qui lui
correspond. Flame lit : l'accesseur de l'ennemi gelé (A13), **avant** de lancer l'animation de son action ; le
compte rendu de vague (A12) ; la transition d'état d'une piste, comme `EnemyCard.updateStats` compare déjà
l'ancien et le nouvel état pour ses réactions aux coups (`enemy_card.dart:217-231`) — « aucun » → « rompu » est le
moment des animations de rupture du Gel et de la Foudre (P-c, §5.2). Aucune règle ne se calcule dans Flame.

### 4.12. Ce qui ne change pas

**Vulnérable, Faiblesse et Poison** : même barème (`proportional_status.dart:16-20`), mêmes étapes du pipeline,
même tic. Le Poison reste le seul dégât sur la durée (D83). Les tests qui les gardent (§9) ne changent pas.

---

## 5. Les écrans

### 5.1. L'affichage d'une charge — partie 1

| Où | Forme |
|:---|:---|
| **L'ennemi** — les icônes de statut (`status_indicator.dart`, posées par `enemy_card.dart:139-150`) | Une icône par charge portée, son émoji d'aujourd'hui (`:157-162`). **Gel et Foudre sous le seuil : « ❄ 2/3 », « ⚡ 2/3 »** — points sur seuil courant ; **Feu : « 🔥 5 »** — les points seuls, la surcharge étant libre ; **Foudre chargée** : « ⚡ 4 » en jaune vif, sous-titré du nom de l'état (« Chargé ») ; **ennemi gelé** : « ❄ » sous-titré « Gelé ». Aucune durée sous une charge (`:116-132` ne s'écrit pas pour elle). Une charge à 0 point et non rompue ne s'affiche pas : après un gel consommé, le seuil monté se lit à la pose suivante (« ❄ 1/4 » pour un point posé, étude §3) |
| **Le panneau des intentions** (`enemy_intents_panel.dart:66`) | L'ennemi gelé : son intention barrée, en gris, et la ligne « Gelé : ne fait rien ce tour » ; l'intention n'est plus réduite par le Gel (A14) |
| **Le héros** — le panneau des effets (`status_effects_panel.dart`, posé par `combat_side_panels.dart:84`) | « Gel : 2/5 », « Feu : 5 », « Foudre : 2/3 » ; gelé en attente : « Gelé : −50 % de dégâts au prochain tour » ; gelé actif : « Gelé : −50 % de dégâts ce tour » ; chargé : « Chargé : +8 par coup » (2 × 4 points). L'icône et la couleur, celles d'`effect_icons.json:14-16` (P-6 de la vague 5, `:153-160`). **Une question laissée au plan, de classe T : la largeur de la ligne du gel en attente.** « Gelé : −50 % de dégâts au prochain tour » mesure 248 px pour 189 de large dans le panneau (Segoe UI gras 13 ; le panneau, large de 250, `status_effects_panel.dart:25`, la coupe d'une ellipse, `overflow: TextOverflow.ellipsis`, `:185`) ; l'anglais « Frozen: −50% damage next turn » aussi (197 px) — maquettes, p. 2. La manière se règle au plan, en classe T ; si la solution change ce que le joueur lit (le texte de la ligne), c'est une question P, que le plan pose avec des maquettes |
| **Les infobulles des cartes**, Flutter (`ui_card_helpers.dart:408-427`) et Flame (`card_component.dart:432-452`) | « Applique 2 Gel. » sans durée, puis en parenthèse la description de la charge, remplie (§6.1) |
| **La liste d'une signature** (appui long, `effect_line_texts.dart:26`) | *Braise* : « Applique 1 Feu », sans durée |

**Les lignes d'affichage.** Une fonction pure, à côté des règles (`ChargeRules`), rend pour un porteur une ligne
par charge à montrer — son id, ses points, son seuil courant, son état et la valeur de la rupture en vigueur
(pourcentage, bonus par coup) —, lue sur ses statuts et ses pistes (A5, A8) ; une charge à 0 point et non rompue
n'en a pas. L'indicateur de l'ennemi et le panneau du héros les lisent. Le panneau du héros
ne reçoit aujourd'hui que la liste de ses statuts (`game_screen.dart:640-646`, `heroStatuses:
runState.heroStats.statuses` ; `combat_side_panels.dart:21`, `:29`) : `game_screen.dart` passe désormais à
`CombatSidePanels` les lignes du héros, calculées de ses `EntityStats`, et le catalogue, que `CombatSidePanels`
transmet aux deux panneaux ; les lignes, au seul `StatusEffectsPanel` (`combat_side_panels.dart:84`). Le panneau
des intentions (`:95`) lit l'accesseur d'A13 et le nom de l'état dans le catalogue. Les noms viennent du
catalogue, qui leur arrive par les chemins d'A2, dans la langue active — Flame comme pour les textes de cartes qu'il
écrit déjà (`card_component.dart:432-452`). **L'indicateur se rafraîchit sur ces lignes** : il ne compare
aujourd'hui que les statuts (`status_indicator.dart:15-36`), si bien qu'un gel consommé, qui ne change que la piste,
ne le redessinerait pas ; sa comparaison porte désormais aussi sur les lignes des charges, qui deviennent un
**paramètre obligatoire** de `StatusIndicator.updateStatuses`. `EnemyCard` met à jour ses indicateurs par **deux
chemins** (`enemy_card.dart:217-246`) : `updateStats`, directement, ou, pendant l'animation d'une carte, en différant
l'état (`_pendingVisualInstance`, `:217-219`), que `resolvePendingVisualStats` (`:233-246`) applique après
l'animation (`heros_draft_game.dart:258-263`). Une charge posée par une carte passe par le second — « ❄ Gelé » après
le second *Trait de Glace* de M1 ; le paramètre obligatoire fait que le compilateur exige les lignes aux deux
endroits. Les libellés sont ceux de P-a, la réponse du propriétaire (§1.2).

### 5.2. Les animations — partie 2

Les trois animations de rupture de P-c, celles que le propriétaire a retenues (§1.2) — G-a pour le Gel, F-a pour
le Feu, L-b pour la Foudre —, la gangue de l'ennemi gelé et celle du héros gelé, le halo de la Foudre chargée. Elles
se jouent dans Flame et ne lisent que l'état (A12, A13). Les durées s'entendent à l'échelle des délais de combat
d'aujourd'hui (`game_constants.dart:62-74` : 200 ms le bond d'un ennemi, 400 ms après une intention).

| Rupture | Ce qu'on voit |
|:---|:---|
| **Le Gel — G-a, la gangue** | À la rupture (pendant le tour du joueur, quand la carte pose le dernier point) : une gangue de glace couvre la carte de l'ennemi — un voile bleu glacier (`#81D4FA`, 45 % d'opacité) bordé d'un liseré blanc, qui monte du bas vers le haut en 0,4 s, avec un léger serrement (échelle 1 → 0,97 → 1). Elle reste tant qu'il est gelé. À son tour d'action, à la place du bond : la carte tremble trois fois (0,3 s), la gangue se brise en six à huit éclats blancs et bleu clair projetés autour de la carte (0,4 s), et « Gelé » flotte au-dessus. Chez le héros gelé : la même gangue, plus pâle (25 %), sur la carte du héros pendant tout son tour gelé, et un givre bleu aux quatre coins de l'écran |
| **Le Feu — F-a, l'onde** | Une vague de la chaîne à la fois. Sur chaque porteur qui explose : un éclair radial orange (cœur `#FF6D00`, bord `#FFAB40`), d'un rayon d'environ une largeur et demie de carte, en 0,35 s, et ses dégâts en chiffre ; puis une boule de feu part vers chaque voisin touché (0,25 s), qui s'embrase brièvement, affiche ses dégâts et « +1 🔥 ». Un porteur qui ne passe pas le seuil ne fait qu'un rougeoiement de sa carte (0,2 s). Environ 0,6 s par vague, puis une pause de 0,2 s avant la suivante. Chez le héros : l'éclair seul, sans boule de feu |
| **La Foudre — L-b, le halo** | À l'atteinte du seuil, un halo jaune (`#FFEA00`) naît autour de la carte en 0,2 s, puis pulse toutes les 0,6 s tant qu'elle est chargée. Le bonus en jaune à chaque coup (« +6 » sur la cible chargée de la maquette). Chez le héros chargé : le même halo sur sa carte. Pas d'éclair depuis le haut de l'écran, pas de bordure qui crépite, pas d'étincelles (maquettes, diapositive 12) |

**Une question laissée au plan, de classe T : le bonus de la Foudre à chaque coup.** L'afficher en jaune à chaque
coup demande que Flame connaisse les coups d'une carte un à un ; aujourd'hui une carte à trois coups ne montre
qu'un « −27 », Flame comparant deux états (`triggerHitReactions`, `combat_entity.dart:176`) — maquettes, p. 11. La
maquette de L-b (p. 12) ne montre que la cible chargée ; sous le seuil, D86 donne aussi un bonus (+1 par point),
que la maquette ne dessine pas. La manière se règle au plan, en classe T ; si la solution change ce que le joueur
lit (ce qui s'affiche à chaque coup, chargé ou sous le seuil), c'est une question P, que le plan pose avec des
maquettes.

En partie 1, sans animation neuve : un ennemi gelé ne fonce pas à son tour
d'action ; chaque vague de la chaîne montre ses dégâts par les réactions aux coups d'aujourd'hui
(`enemy_card.dart:217-231`) et la flamme existante (`effect_icon.dart:126`) au-dessus de chaque porteur résolu, avec
le délai entre deux vagues.

---

## 6. Textes joueur

### 6.1. La donnée

**Les jetons d'une description** : `{name}`, `{threshold}`, `{bossThreshold}`, `{heroThreshold}`, `{growth}`,
`{decay}`, et ceux de la rupture — `{percent}`, `{damagePerPoint}`, `{explosionDamage}`,
`{chargePerNeighbour}`, `{bonusPerPoint}` — ; un jeton dérivé, `{belowValue}`, la valeur par point sous le seuil
(`damagePerPoint` ou `bonusPerPoint` × `belowThresholdPercent`, A15). Un jeton inconnu est refusé (A3). Les textes,
aux noms de P-a, la réponse du propriétaire (§1.2) :

| Fichier | Clé | Français | Anglais |
|:---|:---|:---|:---|
| `charges/freeze.json` | `description` | « S'accumule jusqu'à {threshold} ({bossThreshold} pour un boss), sans jamais le dépasser : le porteur gèle et perd toute sa prochaine action. Le seuil monte de {growth} à chaque gel. Perd {decay} point à son tour s'il n'a pas gelé. » | « Builds up to {threshold} ({bossThreshold} for a boss), never beyond: the bearer freezes and loses its whole next action. The threshold rises by {growth} with each freeze. Loses {decay} point on its turn if it did not freeze. » |
| | `heroDescription` | « Sur vous : à {heroThreshold}, vos cartes et signatures infligent {percent} % de dégâts en moins pendant votre prochain tour. » | « On you: at {heroThreshold}, your cards and signatures deal {percent}% less damage during your next turn. » |
| `charges/burn.json` | `description` | « S'accumule sans limite. Au tour du porteur, tout se résout : chaque tranche de {threshold} inflige {damagePerPoint} par point au porteur et explose — {explosionDamage} dégâts et {chargePerNeighbour} {name} à chacun de ses voisins ; le reste inflige {belowValue} par point. » | « Builds up without limit. On the bearer's turn, it all resolves: each set of {threshold} deals {damagePerPoint} per point to the bearer and explodes — {explosionDamage} damage and {chargePerNeighbour} {name} to each neighbour; the rest deals {belowValue} per point. » |
| `charges/shock.json` | `description` | « Chaque coup reçu inflige +{belowValue} par point. À {threshold}, le porteur est chargé jusqu'à la fin du tour : +{bonusPerPoint} par point à chaque coup. Perd {decay} point à son tour sous le seuil. » | « Each hit taken deals +{belowValue} per point. At {threshold}, the bearer is charged until the end of the turn: +{bonusPerPoint} per point on every hit. Loses {decay} point on its turn below the threshold. » |

**Les contenus relus**, aux réponses de P-a et de P-b (§1.2) — seuls changent les textes qui nomment la Brûlure ou
l'Électrocution, et celui d'*Embrasement* :

| Fichier | `description_fr` | `description_en` |
|:---|:---|:---|
| `cards/fireball.json` | « Inflige 6 dégâts. Applique 2 Feu. » | inchangé |
| `cards/thunder_clap.json` | « Inflige 4 dégâts. Applique 1 Foudre. » | inchangé |
| `cards/mana_flux/kindle.json` | « Applique 3 Feu. » | « Apply 3 Burn. » |
| `cards/mana_flux/spark_barrage.json` | « Applique 1 Foudre, puis inflige 3 dégâts 3 fois. » | inchangé |
| `forge_upgrades/burning.json` | « Applique {val} Feu » | inchangé |
| `forge_upgrades/shocking.json` | « Applique {val} Foudre » | inchangé |
| `classes/mage/skills/magic_missile.json`, `ember` | « Applique {val} Feu » | inchangé |

*Trait de Glace*, *Nova de givre* et *Congelant* gardent leurs textes : « Gel » ne change pas de nom, et le
`{val}` de *Congelant* suit sa valeur par niveau.

### 6.2. Clés ARB (`app_fr.arb`, `app_en.arb`)

| Clé | Français | Anglais |
|:---|:---|:---|
| `cardDescStatusCharge(amount, name)` | « Applique {amount} {name}. » | « Applies {amount} {name}. » |
| `effectLineCharge(amount, name)` | « Applique {amount} {name} » | « Apply {amount} {name} » |
| `statusChargePoints(name, points, threshold)` | « {name} : {points}/{threshold} » | « {name}: {points}/{threshold} » |
| `statusChargeOpen(name, points)` | « {name} : {points} » | « {name}: {points} » |
| `statusChargeWeakenNext(state, percent)` | « {state} : −{percent} % de dégâts au prochain tour » | « {state}: −{percent}% damage next turn » |
| `statusChargeWeakenNow(state, percent)` | « {state} : −{percent} % de dégâts ce tour » | « {state}: −{percent}% damage this turn » |
| `statusChargeCharged(state, bonus)` | « {state} : +{bonus} par coup » | « {state}: +{bonus} per hit » |
| `intentSkipped(state)` | « {state} : ne fait rien ce tour » | « {state}: does nothing this turn » |

`{name}` et `{state}` viennent du fichier de la charge, dans la langue active. Retirées : les clés d'A16.
`EffectLineTexts.phrase` (`effect_line_texts.dart:11-31`) rend la phrase d'une charge pour toute sorte
`status:<id>` du catalogue — `status:freeze` et `status:shock`, sans phrase aujourd'hui, en reçoivent une.

### 6.3. Le tutoriel

| Où | Changement |
|:---|:---|
| Étape « Les Effets Élémentaires » (`tutorial_data.dart:220-243`) | FR : « Certaines cartes appliquent des altérations aux ennemis :\n• 🧪 Poison : inflige sa valeur en dégâts au début de leur tour. La valeur ne baisse jamais — seule la durée décrémente.\n• ❄️ Gel, 🔥 Feu et ⚡ Foudre sont des **charges** : leurs points s'accumulent jusqu'à un seuil, où elles rompent.\n• ❄️ Gel : au seuil, l'ennemi gèle et **ne fait rien** à son prochain tour.\n• 🔥 Feu : à son tour, chaque tranche complète le blesse et **explose** sur ses voisins, qui prennent feu à leur tour.\n• ⚡ Foudre : chaque coup qu'il reçoit fait plus ; au seuil, il est **chargé** et le bonus par point double, jusqu'à la fin du tour. » — EN : « Some cards apply status effects to enemies:\n• 🧪 Poison: damage equal to its value at the start of their turn. The value never drops — only the duration ticks down.\n• ❄️ Freeze, 🔥 Burn and ⚡ Shock are **charges**: their points build up to a threshold, where they break.\n• ❄️ Freeze: at the threshold, the enemy freezes and **does nothing** on its next turn.\n• 🔥 Burn: on its turn, each full set hurts it and **explodes** onto its neighbours, who catch fire in turn.\n• ⚡ Shock: every hit it takes deals more; at the threshold, it is **charged** and the bonus per point doubles, until the end of the turn. » Aucun chiffre dans la prose : la galerie et les infobulles les donnent. Les noms Feu et Foudre, Burn et Shock, et les états Gelé et Chargé, sont ceux de P-a, la réponse du propriétaire (§1.2) |
| Étape « Les Intentions Ennemies » (`tutorial_data.dart:258`, `:270`) | EN « …and drops while they are Frozen. » → « …; a Frozen enemy does nothing on its turn. » — FR « …et baisse tant qu'il est Gelé. » → « … ; un ennemi Gelé ne fait rien à son tour. » |
| La galerie (`tutorial_elements_widget.dart:41-76`) | Les entrées Feu, Gel et Foudre lisent leur nom et leur description dans le catalogue (`widget.engine.data.charges`), au lieu des noms et des phrases en dur (`:54`, `:59-66`, `:71`) |
| Ses simulations (`tutorial_elements_widget.dart:130-149`, `:188-258`) | Le cycle de deux secondes montre la règle, chiffres lus sur la donnée : Gel « ❄ 1/3 » → « ❄ 2/3 » → « ❄ Gelé » ; Feu « 🔥 1 » → « 🔥 2 » → « 🔥 3 » → « 💥 12 » ; Foudre « ⚡ 1/3 : +1 » → « ⚡ 2/3 : +2 » → « ⚡ Chargé : +6 ». Le « 10 -> 5 » du Gel (`:227`) et la Brûlure qui perd 1 (`:140`) disparaissent |
| Le panneau de démonstration (`tutorial_elements_widget.dart:486-505`) | Poison 3 et Feu 2, la seconde entrée posée comme une charge, son libellé « Feu : 2 » |
| `tutorial_engine.dart:410` | Le pipeline reçoit `data.charges` (A14) ; la leçon de jeu ne pose pas de statut, rien d'autre ne change |

---

## 7. L'éditeur de contenu et le menu de debug

### 7.1. L'éditeur

| Élément | Changement |
|:---|:---|
| `EntityCategory.charge`, « Charge élémentaire » (`entity_descriptor.dart:26`, `:262`) | Chemin `charges/<id>.json`, id injecté ; ses clés, celles de §3.1 ; `breaksOn`, `rupture.kind` et `heroRupture.kind` en énumérations lues sur le modèle ; `construct` = `ChargeData.fromJson`, qui valide (A3) |
| Descripteurs de carte, de carte de lot, de signature, de rune | Inchangés : `effects[].statusId` et `deltas[].statusId` gardent leur vocabulaire lu sur les fichiers (`known_values.dart:97-107`) |
| `entity_descriptor_test.dart:20`, `:39` | Onze catégories, onze sources |

### 7.2. Le menu de debug

Il ne lit ni ne pose aucun de ces statuts aujourd'hui (`debug_combat_tab.dart`, `debug_actions.dart`). Sous P-e (a),
la réponse du propriétaire (§1.2) : une section « Charges » dans l'onglet Combat — pour le héros et pour chaque
ennemi, un bouton par charge du catalogue (« +1 Gel », « +1 Feu », « +1 Foudre »), et « Retirer les charges » —,
et deux actions, `DebugActions.poseCharge` — un point, par la règle du jeu, `ChargeRules.pose` (plafond, refus sur
un porteur rompu, rupture), sur le héros ou sur un ennemi — et `DebugActions.clearCharges`, gardées comme les autres
par la run debug (`_allowed`) : le menu n'existe que dans une run lancée par « Run Debug ». La pose de debug ne
reçoit pas de bonus de Puissance.

---

## 8. La sauvegarde

**Rien de neuf n'est sauvegardé ; aucun `schemaVersion` ne change.** La sauvegarde n'est jamais écrite en combat
(`CLAUDE.md`, `SaveService`) : `CombatState`, ses ennemis et le compte rendu de vague n'y entrent pas ; les
statuts du héros sont vides entre deux combats (`map_progression_manager.dart:37`) ; la piste n'est écrite ni par
`EntityStats.toJson` ni lue par `fromJson` (A5). Avant la `1.0.0`, les sauvegardes ne se transfèrent pas d'une
version à l'autre : rien d'autre à prévoir.

---

## 9. Tests

**Sous D77** (brainstorm v3, §1) : les tests automatiques gardent les calculs, les données, les contrôleurs et la
sauvegarde ; aucune ligne ne prescrit de test d'écran. L'affichage, les animations et les textes à l'écran sont
les tests manuels de §9.1.

| Sujet | Fichier | Ce qu'il verrouille | Partie |
|:---|:---|:---|:---:|
| **La donnée d'une charge** | `test/unit/charge_data_test.dart` *(nouveau)* | Chaque refus d'A3, nommé : clé inconnue, paire bilingue manquante, seuil < 1, montée ou déclin négatifs, sorte inconnue, paramètre d'une autre sorte, `belowThresholdPercent` hors bornes, sorte et moment incompatibles, `brokenName` absent pour une rupture qui dure, `heroDescription` sans `heroRupture` ; **un seuil de Feu de 2 refusé, de 3 accepté**, et le seuil du boss et du héros soumis à la même règle ; `skipAction` refusé comme rupture du héros ; un jeton inconnu refusé ; le seuil de départ par porteur ; les jetons remplis, `{belowValue}` compris ; aller-retour `toJson` / `fromJson` | 1 |
| La donnée livrée | `test/unit/real_bundle_load_test.dart` | `registry.charges` : trois, `freeze`, `burn`, `shock`, aux valeurs de D84 à D86 (A18) | 1 |
| **La pose, le seuil, le déclin** | `test/unit/charge_rules_test.dart` *(nouveau)* | Gel : plafond au restant ; rupture à 3, Gel à 0, seuil à 4 puis 5 ; rien sur un porteur gelé ; boss 6 ; héros 5 ; déclin −1 sans rupture, jamais sous 0, aucun sur un porteur rompu. Foudre : +1 par point sous le seuil, chargée à 3, +2 par point, surcharge libre, retombe à 0 à la fermeture de phase, déclin sous le seuil seulement. Feu : surcharge libre, aucune rupture à la pose. La somme des entrées de même id ; la forme de l'entrée (`debuff`, durée 1, jamais décomptée, retirée à 0, A4) ; la rupture en vigueur copiée sur la piste — `weakenDealt` pour le héros, `skipAction` pour un ennemi. Les lignes d'affichage (§5.1) : points, seuil, état et valeur de la rupture, sans texte ; une ligne pour un ennemi gelé à 0 point, aucune pour une charge à 0 non rompue | 1 |
| **Le Feu et sa chaîne** | `test/unit/charge_rules_test.dart` | 5 points : 16 au porteur, 12 et 1 Feu à chaque voisin ; 2 points : 4, sans explosion ; un bout de rangée, un ennemi seul, le héros sans voisin ; **l'exemple de l'étude §11, aux valeurs 4, 12, 3, 1 : A 48, B 64, C 48, en trois vagues** (A18) ; une vague simultanée (A11) ; un porteur que la vague tue explose ; un mort pendant la chaîne garde sa place et ne reçoit plus rien ; le Feu d'une explosion sans bonus de Puissance ; **la chaîne s'arrête** : une rangée de cinq ennemis à 9 Feu chacun se résout en un nombre fini de vagues, le Feu en jeu décroissant à chaque vague qui explose | 1 |
| **La symétrie** | `test/unit/charge_symmetry_test.dart` *(nouveau)* | Chaque charge posée sur le héros et sur un ennemi, par le contrôleur : le Gel de l'ennemi lui ôte son action ; **le Gel du héros réduit ses dégâts de 50 % pendant son prochain tour, chaque coup d'un multi-coups compris, et ne lui ôte pas son tour** — il joue cartes et signatures ; ses statuts ne sont pas réduits ; le Feu du héros : sa part au début de son tour, sans explosion ; la Foudre du héros : les coups ennemis lui font +1 par point | 1 |
| **Le pipeline** | `test/unit/damage_pipeline_test.dart` | Le barème de P-1 ne compte plus que Vulnérable et Faiblesse (`:59-69`) ; **Vulnérable et Faiblesse donnent les mêmes résultats qu'en `0.5.8`** (les tests de leurs plafonds ne changent pas) ; Foudre après le critique et avant Vulnérable, qui l'amplifie ; gelé et Faiblesse : 8 → 6 → 3 (37,5 %) ; une rupture « en attente » ne réduit rien | 1 |
| **Le tour, au contrôleur** | `test/unit/combat_controller_test.dart` — le test « Burn, Freeze, and Shock » (`:553-750`) réécrit | L'ennemi gelé : `resolveEnemyIntent` ne résout rien et consomme le gel ; son intention suivante du cycle après `endEnemyTurn` ; son Poison et son Feu résolus quand même. Le Feu avant le Poison (A10) ; les vagues une à une par `resolveNextFireWave`, le compte rendu de chaque vague, `false` à la fin ; `cleanDeadEnemies` après les statuts, la rangée resserrée ; un ennemi tué par une carte perd son Feu. Les deux fermetures de phase (A9) | 1 |
| **Le Poison** | `stat_gains_characterization_test.dart`, `mana_regen_test.dart`, `stat_rule_conversion_test.dart` | Inchangés : le Poison inflige sa valeur et vieillit au tic. Leurs appels à `processPlayerStatuses` / `processEnemyStatuses` (`stat_gains_characterization_test.dart:146`, `:161`, `:288`, `:328` ; `mana_regen_test.dart:38`, `:51` ; `stat_rule_conversion_test.dart:143`) reçoivent le catalogue | 1 |
| **Le début de phase ennemie, ancien contrat** | `combat_controller_test.dart:223-308` (« startEnemyTurn ticks statuses (Poison)… », appel `:289` : « goblin should take 3 poison damage »), `:546`, `encounter_system_test.dart:372`, `:401`, `:415`, `xp_scaling_test.dart:231` | Ces six appels attendent de `startEnemyTurn` le Poison et `cleanDeadEnemies`, que A12 déplace dans `resolveEnemyStatuses`. Ils passent par un helper de test, « début de phase ennemie complet » : `startEnemyTurn`, puis `resolveNextFireWave` jusqu'à `false`, puis `resolveEnemyStatuses` ; leurs valeurs attendues ne changent pas. `combat_signature_test.dart:93` (`nextTurn`) et `:202` n'attendent que la phase ennemie : inchangés | 1 |
| **Le catalogue surchargé** (A2) — valeurs inchangées | `multi_hit_test.dart:266` (2 Foudre posées à la main), `:308-345` (la *Rafale* livrée : 88, 97, 97 et 93) ; `rune_resolution_test.dart:366-390` (l'éclaboussure et la Foudre de sa cible) ; `might_orientation_test.dart:240-250` (*Brûlant* et la Puissance : 1 + 3) | Chacun surcharge `chargeCatalogProvider` avec le catalogue livré ; sous le seuil, la Foudre fait +1 par point, comme l'Électrocution : les valeurs restent justes. La durée d'une entrée de charge vaut 1 (A4) : `might_orientation_test.dart:250` l'attend déjà | 1 |
| **Le catalogue surchargé** (A2) — valeurs qui changent | `effect_resolver_test.dart:389-422` ; `rune_resolution_test.dart:165-212` | Avec le catalogue livré. *Boule de Feu* + *Brûlant*, *Coup de Tonnerre* + *Brûlant*, *Braise* : mêmes points (5 ; 3 et 1 ; 1 + 2), la durée de l'entrée à 1 (`effect_resolver_test.dart:393`). *Coup de Tonnerre* + *Surchargé*, trois fois dans le tour : 5, **10** puis **14** dégâts au lieu de 5, 7 et 9 — la deuxième pose de la rune amène la Foudre à 3, la cible est chargée (D86) —, et 6 points ; *Brûlant* 2 deux fois : (4, durée 1) ; *Trait de Glace* : 2 Gel, « 2/3 », non gelé, au lieu de −50 % ; *Congelant* 1 : **1** Gel ; *Boule de Feu* + *Brûlant* 1 : (3, durée 1) | 1 |
| La Puissance et les runes | `effect_resolver_test.dart`, `forge_upgrades_catalog_test.dart:112-124` | Q11 : un bonus, une fois, ajouté avant le plafond du Gel ; *Congelant* 1 point par niveau dans la matrice des runes | 1 |
| Les textes des runes | `forge_upgrade_data_test.dart:634-636` | « Applique 3 Feu », « Applique 1 Gel », « Applique 2 Foudre » au lieu de « 3 Brûlure », « 2 Gel », « 2 Électrocution » — les réponses de P-a et de P-b (§1.2) | 1 |
| L'intention et le Gel | `effect_resolver_test.dart:254-283` | Le test « le Gel reduit l intention de 25 % par point » disparaît avec la règle (A14) ; à sa place, un ennemi qui porte du Gel sous le seuil montre son intention entière | 1 |
| Les cartes de lot | `card_catalog_test.dart:84-97` | *Embrasement* à 3 Feu | 1 |
| Intégrité | `referential_integrity_test.dart` | Le test des sortes du document (`:199-216`, assertion `:211-213`), qui exige aujourd'hui que chaque `status:<id>` d'`effect_icons.json` soit créé par `createStatus`, devient « créé par `createStatus` ou charge du catalogue » : `status:burn`, `status:freeze`, `status:shock` (`effect_icons.json:14-16`) ne sont plus créés par la fabrique (A4). Deux autres tests du même fichier, pour la même raison, suivent la même règle, « créé par `createStatus` ou charge du catalogue » : celui des évolutions (`:265-294`, assertion `:285-288`), que *Braise* rougirait — elle pose `burn` (`magic_missile.json:68`) —, et celui des runes (`:346-361`, assertion `:356`), que les trois runes élémentaires rougiraient. Chaque `statusId` posé par une carte, une rune, une signature ou une évolution livrée est soit créé par `createStatus`, soit une charge du catalogue ; chaque charge a son entrée `status:<id>` dans `effect_icons.json` ; la liste des statuts des faces (`:303-314`) garde `burn`, `freeze`, `shock` | 1 |
| Comptes et chargeur | `entity_id_convention_test.dart:72-78`, `game_data_loader_injection_test.dart` | 133 fichiers ; `charges/*.json` injecte l'id | 1 |
| Éditeur | `entity_descriptor_test.dart`, `shipped_entities_round_trip_test.dart` | Onze catégories, onze sources ; les trois charges livrées repassent la validation et se réécrivent à l'identique | 1 |
| **Signatures qui changent** | `tickStatuses` (ids des charges, A6) : `effect_resolver_test.dart:83`, `:86`, `status_source_test.dart:118`, `:160`, `:196` ; `DamagePipeline.calculate` (catalogue, A14) : `damage_pipeline_test.dart:17`, `:30`, `:52` ; `CardRuleTexts.scale` (catalogue, A4) : `card_rule_texts_test.dart:45`, `:46`, `:49`, `:51`, `:93` ; `EffectLineTexts.phrase` (catalogue, §6.2) : `effect_line_texts_test.dart:69`, `:70`, `:76-82`, `:89`, `:98`, `referential_integrity_test.dart:233` ; le constructeur de `HerosDraftGame` (catalogue et deux rappels, A2, A12) : `flame_image_prefix_test.dart:12-30`, `heros_draft_game_targeting_test.dart:59-81` | Ces appels reçoivent le catalogue (ou les ids, ou les rappels) ; leurs valeurs attendues ne changent pas — `card_rule_texts_test.dart:90-94` nomme Vulnérable, qui n'est pas une charge. Les valeurs d'`effect_line_texts_test.dart` qui changent sont à la ligne suivante | 1 |
| Phrases | `test/unit/effect_line_texts_test.dart:28`, `:59`, `:82`, `:97` | `status:burn` sans durée ; `status:freeze` et `status:shock` ont désormais une phrase | 1 |
| Debug *(P-e (a))* | `test/unit/debug_actions_test.dart` | `poseCharge` suit `ChargeRules.pose` (plafond, rupture) ; hors d'une run debug, rien n'est écrit ; `clearCharges` | 1 |
| Tutoriel | `tutorial_fixtures_test.dart:106` | *Boule de Feu* pose toujours `burn` ; le tutoriel tourne avec elle | 1 |

### 9.1. Les tests manuels

Le fichier de tests manuels de la vague les reprend. Plusieurs ennemis demandent un acte avancé : l'onglet Run du
menu de debug passe d'acte (« Acte suivant (regenere la carte) », `debug_run_tab.dart:67-75`), deux fois de l'acte 1
pour un combat normal de **jusqu'à trois ennemis** : trois n'est qu'un plafond, le nombre réel est tiré sous le
budget du combat (`encounter_system.dart:66-71`, `:275-289`) — s'il y en a moins, passer encore d'acte ou jouer un
autre combat (M5) ; **M6 veut exactement trois ennemis** : s'il y en a moins, ou quatre après un acte de plus,
jouer un autre combat ; les charges se posent par les cartes ou par l'entrée de debug de §7.2
(P-e (a)). Les chiffres sont ceux des décisions et de P-b, la réponse du propriétaire (§1.2), **sans Puissance** : un héros qui en porte,
et le Mage surtout (Puissance « altération »), pose davantage de points.

| # | Écran | Ce que fait le propriétaire | Ce qu'il doit voir | Partie |
|:---:|:---|:---|:---|:---:|
| M1 | Combat : l'ennemi | Joue *Trait de Glace* sur un ennemi, puis un second | « ❄ 2/3 » ; au second, « ❄ Gelé » — un seul point posé ; le panneau des intentions dit « Gelé : ne fait rien ce tour », l'intention barrée | 1 |
| M2 | Combat : la phase ennemie | Finit le tour avec l'ennemi gelé, qui porte aussi du Poison | Il ne fonce pas et ne fait rien ; son Poison le blesse ; au tour suivant, il montre l'intention d'après dans son cycle ; un nouveau *Trait de Glace* (2 Gel, `ice_bolt.json:20`) dit « ❄ 2/4 » | 1 |
| M3 | Combat : le déclin | Pose 2 Gel, finit le tour | Après la phase ennemie : « ❄ 1/3 » | 1 |
| M4 | Combat : le boss | Pose du Gel sur un boss | « ❄ 2/6 » | 1 |
| M5 | Combat : le Feu | À l'acte 3, joue *Embrasement* sur l'ennemi du milieu, finit le tour | « 🔥 3 » ; au début de la phase ennemie : 12 au porteur, puis 12 à chaque voisin, « 🔥 1 » sur eux ; vague suivante : 2 à chaque voisin ; les vagues l'une après l'autre ; l'intention de défense d'un ennemi protège de l'explosion par son Armure (P-d) | 1 · 2 |
| M6 | Combat : la chaîne | À l'acte 3, devant **exactement trois ennemis** — sur quatre, la chaîne change ; s'il y en a moins (ou quatre, si l'on a passé un acte de plus), jouer un autre combat —, porte d'abord les PV des trois ennemis au-dessus de 64 par le champ PV de chaque ennemi de l'onglet Combat (`DebugActions.setEnemyHp`, `debug_actions.dart:169-182`, qui ne borne pas aux PV max) — sans quoi les bords meurent dès la première vague et la chaîne change ; puis, par l'entrée de debug, pose 9 Feu sur l'ennemi du milieu, sans Armure, et finit le tour | Trois vagues ; à la fin : 48, 64, 48 de PV perdus | 1 · 2 |
| M7 | Combat : la mort | Tue un porteur de Feu par une carte ; puis, à un autre combat, laisse un porteur mourir de son propre Feu | Le premier n'explose pas ; le second explose, ses voisins sont touchés, puis il disparaît et la rangée se resserre | 1 |
| M8 | Combat : la Foudre | Avec le **Paladin** sous *Régénération d'Armure* — ni Puissance ni critique au départ (`classes/paladin/class.json` ne déclare pas `critChance`), sans relique ; *Ferveur* donnerait de la Puissance dès que l'Armure encaisse, et le Berserker porte 10 % de critique (`classes/berserker/class.json:12`) —, **avant le combat, sur la carte** : par l'onglet Deck du menu de debug — il n'existe que hors combat ; en combat, l'onglet Combat reste seul (`debug_drawer.dart:45-52`) —, ajoute *Coup de Tonnerre* et *Rafale d'étincelles* au deck maître (`DebugActions.addCard`, `debug_actions.dart:127-130`), que le début du combat mélange en pioche avant de tirer la main d'ouverture (`deck_controller.dart:159-176`), et retire toutes les autres cartes de la liste « Deck maitre » du même onglet (`DebugActions.removeCard`, `debug_actions.dart:132-135`), pour que la main d'ouverture les contienne. Au premier tour du combat, porte d'abord les PV de l'ennemi visé au-dessus de 40 par son champ PV de l'onglet Combat (`DebugActions.setEnemyHp`, `debug_actions.dart:169-182`), pour que les 27 de la Rafale se lisent en entier. Dans ce même tour : joue *Coup de Tonnerre* sur un ennemi (1 mana), pose par l'entrée de debug 1 Foudre de plus sur lui, puis joue *Rafale d'étincelles* (2 mana) — tous les héros ont 3 mana (`classes/*/class.json:10`), et d'un tour à l'autre la Foudre décline | « ⚡ 1/3 » ; après le debug, « ⚡ 2/3 » ; la Rafale le charge : « ⚡ 3 Chargé », 27 dégâts ; au début de la phase ennemie, la Foudre a disparu | 1 |
| M9 | Combat : le héros gelé | Par l'entrée de debug, pose 5 Gel sur le héros, finit le tour | « Gelé : −50 % de dégâts au prochain tour » ; au tour suivant, « … ce tour » : il pioche, joue cartes et signatures ; une *Frappe* de 6 en fait 3 ; au tour d'après, plus rien | 1 |
| M10 | Combat : le héros porteur | Par l'entrée de debug, pose 5 Feu puis 2 Foudre sur le héros, finit le tour | La Foudre : chaque attaque ennemie fait +2 ; au début de son tour, le héros prend 16, sans explosion ; « Foudre : 1/3 » après son déclin | 1 |
| M11 | Les cartes | Ouvre l'infobulle de *Boule de Feu*, *Trait de Glace*, *Coup de Tonnerre*, au dictionnaire puis en combat (face Flame), en français puis en anglais | « Applique 2 Feu. », puis la règle de la charge, chiffres remplis ; aucun « pendant N tours » ; aucun pourcentage de Gel | 1 |
| M12 | Le panneau du héros | Porte Gel, Feu et Foudre (entrée de debug) | « Gel : 2/5 », « Feu : 5 », « Foudre : 2/3 », chacune son icône ; rien en point d'interrogation | 1 |
| M13 | La signature | Dans une run debug du Mage, pose *Braise* sur *Projectile Magique* (entrée de debug des évolutions), reste appuyé sur la tuile | « Applique 1 Feu », sans durée | 1 |
| M14 | Le tutoriel | Arrive à l'étape « Les Effets Élémentaires », puis « Les Intentions Ennemies », en français puis en anglais | La prose des charges ; la galerie et ses cycles (Gel, Feu, Foudre), sans « 10 -> 5 » ; le panneau « Feu : 2 » ; l'étape des intentions dit qu'un ennemi Gelé ne fait rien | 1 |
| M15 | Le menu de debug | Ouvre la section « Charges » de l'onglet Combat, pose et retire | Un bouton par charge et par porteur ; la pose suit la règle (le Gel plafonné, la rupture) ; « Retirer les charges » vide | 1 |
| M16 | Combat : les animations | Rejoue M1, M2, M5, M8, M9 | Les animations de P-c : la gangue et ses éclats, l'onde et ses boules de feu vague par vague, le halo jaune de la Foudre chargée, qui pulse, et son bonus en jaune à chaque coup ; la gangue pâle du héros gelé | 2 |

---

## 10. Le découpage

**Partie 1 — le cadre, le moteur, les contenus et tout ce que le joueur lit.** Les trois fichiers, `ChargeData`,
la source, la validation, le registre, le provider, `sync_assets`, la catégorie de l'éditeur ; la piste, la pose,
le seuil, le déclin, les quatre sortes de rupture, la chaîne et son compte rendu, l'ordre du tour, le pipeline,
l'ennemi gelé lu par Flame avant son action ; les dix contenus relus (P-b) ; les textes — fichiers, ARB, infobulles,
panneaux, intentions, icônes des ennemis — et le tutoriel, prose et galerie ; l'entrée de debug (P-e) ;
`CLAUDE.md` et `README.md` ; les tests de §9 et les tests manuels marqués 1. Flame n'y gagne aucune animation : il
appelle les vagues une à une et ne fait plus foncer un ennemi gelé (§5.2).

**Partie 2 — les animations.** Les trois animations de rupture de P-c (§5.2), la gangue de l'ennemi gelé et celle
du héros gelé, le halo de la Foudre chargée et son bonus à chaque coup, et le délai de vague ajusté ; les tests manuels marqués 2. Aucune
règle, aucune donnée, aucun test automatique : Flame lit des états que la partie 1 livre — sauf le moyen de
transmettre les coups un à un (§5.2) : s'il passe par l'état, il rejoint la partie 1 avec son test.

**L'invariant** : à la fin de chaque partie, `flutter test` est vert et `dart analyze` propre, et **la règle que le
moteur joue est celle que le joueur lit** — chiffres, textes, infobulles, tutoriel. C'est pourquoi les textes et le
tutoriel vont avec le moteur, et non avec l'affichage comme le proposait la fiche : après la partie 1, une
infobulle de Brûlure qui dirait « puis la valeur diminue de 1 » serait fausse (le précédent de la vague 5, dont la
partie 1 portait déjà les textes du barème). L'ordre suit les dépendances : les animations lisent la piste, son
état de rupture et le compte rendu de vague, que la partie 1 crée. La partie 2 porte les formes de P-c, tranchées
en §1.2 : si le propriétaire, à son test, en retient d'autres, seule elle change.

---

## 11. Documentation et livraison

| Quoi | Où, par qui |
|:---|:---|
| ADR « charges élémentaires » — **amende ADR-023** D1 (Brûlure), D2 (Gel) et D3 (Électrocution), D4 (Vulnérable) inchangée ; **amende ADR-111** D4 (le Gel quitte le barème, `ProportionalStatus` n'en garde que deux ; *Congelant* à 1 point par niveau) ; **complète ADR-104** D4 (les charges restent sans source, leurs points en somme par id, leur piste hors sauvegarde), **ADR-105** D2 (les statuts des runes élémentaires passent par la pose de la charge), **ADR-061** (`ApplyStatusEffectStrategy` aiguille les charges), **ADR-086** (la onzième source, `charges/*.json`) et **ADR-100** (la onzième catégorie de l'éditeur) ; **clôt ADR-110** | `memory-bank-sync` |
| Fiches `_rules/04-00` (statuts : §4.1, la note de §4.3, §4.4), `03-3` (pipeline : la Foudre, le héros gelé), `03-8` (les runes élémentaires), `03-14` (la Foudre par coup), `02-3` (catalogue : les cartes relues), `02-8` (*Braise*), `08-00` (la galerie du tutoriel), `07-00` (le dossier `charges/`) ; `_patterns/07-00` (le flux du tour : la chaîne, l'ennemi gelé), `02-2`, `03-4`, `05-2`, `05-8` — un minimum, que le diff complétera | `memory-bank-sync` |
| **P-53 se clôt** dans `docs/ROADMAP.md` | `memory-bank-sync`, à la fin de la vague |
| `CLAUDE.md:43`, `:78-79`, `:85` ; `README.md:69-71` | Partie 1 (§3.3) |
| Note de version `0.5.9` | `patch-notes-writer`, à la fin de la vague |

**Ce que le joueur voit en `0.5.9`** : le Gel, le Feu et la Foudre s'accumulent sur l'ennemi jusqu'à rompre — le
Gel lui fait perdre toute son action, le Feu explose sur ses voisins et peut se propager de l'un à l'autre, la
Foudre fait plus mal à chaque coup, davantage une fois chargée ; trois passifs restent masqués jusqu'à `0.6.0`.
**À dire dans la note**, sous les réponses de P-a et P-b : la Brûlure devient le Feu et l'Électrocution la Foudre ;
*Embrasement* pose 3 Feu ; *Congelant* pose 1 Gel par niveau ; l'intention d'un ennemi n'est plus réduite par le
Gel.

**Ce que le vérificateur contrôle** :

- la symétrie : `charge_symmetry_test.dart` pose chaque charge sur le héros et sur un ennemi, et le Gel du héros y
  réduit ses dégâts sans lui ôter son tour (D84) ;
- l'exemple de l'étude, §11 : `charge_rules_test.dart` attend 48, 64, 48 ; et la chaîne s'arrête (même fichier,
  la rangée de cinq à 9 Feu) ;
- Vulnérable, Faiblesse et Poison n'ont pas changé : `git diff main -- lib/game/services/proportional_status.dart`
  ne touche que le Gel ; les tests de leurs plafonds (`damage_pipeline_test.dart`) et du Poison passent sans que
  leurs valeurs attendues changent — « Poison inchangé » s'entend de sa valeur et de son tic : ses appels de test
  s'adaptent au nouveau contrat de la phase ennemie (le helper de §9) et au catalogue passé au processeur ;
- plus aucune règle ne lit un élément par son id en dur : `git grep -n -E "(s|status)\.id [!=]= '(burn|freeze|shock)'" -- lib`
  ne rend rien (re-mesuré avant le lot : `entity_stats.dart:147`, `:150`, `:158`,
  `status_effect_processor.dart:96`, `turn_phase_manager.dart:106`, `:118`, `damage_pipeline.dart:39`) ;
- `git grep -n "ProportionalStatus.freeze" -- lib test` ne rend rien ;
- aucun test d'écran neuf (D77) : `git diff main -- test | grep -c '^+.*testWidgets('` rend `0` ;
- `dart run tool/sync_assets.dart --check` passe.
