# P-43 E0 — Puissance par source et `ratio` de conversion — Conception

Date : 2026-10-01
Statut : **Conception** — vague 1 (`0.5.3`), premier de ses deux lots, branche `feat/v0.5.3-p43-e0-e1`

Chantier ROADMAP : **P-43** « Économie unifiée », lot **E0**, le premier des cinq lots E0 à E4. Le déroulé
fait foi dans le [fichier d'orchestration](../../possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md)
(fiche §8.1, partie E0) ; **E1**, le moteur de runes, suit dans la même vague, sur le code qu'E0 aura laissé.
Sources amont :
- [brainstorm v3](../../possible_upgrades/22-09-2026_brainstorm_heros_et_cartes_v3_Fable5.md), §1 — **D36** et
  **D37**, réunies dans E0 par **D66** : source de vérité, ni rediscutées ni amendées ici ; §7.2 et §11, ligne E0 ;
- [revue du brainstorm](../../possible_upgrades/29-09-2026_revue_brainstorm_v3_heros_et_cartes_Fable5.md), §8.1 R3
  et §8.2 idées 2 et 3 — l'idée 2 pour son diagnostic seulement : elle fusionnait « à durée égale », le
  mécanisme retenu est celui de D36 ;
- [spec de P-41](2026-08-07-s2-identite-de-classe-design.md), §7 (la Puissance, `statRules`, la règle R5) et
  §9.1 (le tutoriel) ; ADR-095, ADR-097, ADR-099, ADR-100, ADR-081.

> **Ce que E0 livre, en une phrase.** Un statut retient l'identité de ce qui l'a posé et `addStatus` ne
> fusionne plus que même statut **et** même source — seule la Puissance reçoit une source, tout autre statut
> fusionne comme aujourd'hui —, et la règle de classe gagne un `ratio`, que le Berserker déclare à 0,5 arrondi
> à l'entier supérieur : *Forme Démoniaque* puis *Mur de Fer* ne donnent plus 12 Puissance pendant 4 tours,
> mais 7 ce tour-ci puis 2 pendant les trois suivants.

Toute référence `fichier:ligne` de ce document a été mesurée le 2026-10-01 sur `0f56cd4`.

---

## 1. Décisions

### 1.1. Les décisions acquises que le lot livre

| # | Ce qu'E0 en livre | Où |
|:---|:---|:---|
| **D36** | `StatusEffect` porte l'identité de ce qui l'a posé ; `addStatus` ne fusionne que même statut et même source ; la même source rejouée s'additionne comme aujourd'hui ; `effectiveMight` somme toutes les entrées, `tickStatuses` les vieillit séparément, la barre de vie affiche la somme | §4.1 à §4.4, §5.2 |
| **D37** | Un champ `ratio` (défaut 1) sur la règle de classe, appliqué par `StatGains._convert` ; 0,5 arrondi à l'entier supérieur dans `classes/berserker/class.json` — 6 → 3, 5 → 3, 1 → 1. Un garde-fou de classe : **aucune carte ne change** | §3, §4.5 |
| **D66** | Les deux dans un même lot | — |

### 1.2. Les arbitrages de la spec

Tranchés par l'arbre de décision du fichier d'orchestration (§5) : le premier filtre qui départage l'emporte.
La portée (A1) est tranchée avant l'identité (A2), qui en dépend. **Aucune question ne s'est révélée ne se
trancher qu'en amendant une décision acquise.**

#### A1 — La portée de la règle *(posée par la fiche)*

Le titre de D36 dit « Puissance par source » ; son texte, « `addStatus` ne fusionne que même statut et même
source ».

| Option | Ce qu'elle fait |
|:---|:---|
| **(a) `might` seul** | Le mécanisme est général — tout `StatusEffect` peut porter une source, `addStatus` compare l'identifiant **et** la source pour tous —, mais seuls les fabricants de Puissance en donnent une. Deux statuts posés sans source fusionnent entre eux : c'est exactement aujourd'hui pour tout statut autre que `might` |
| (b) Tout statut | Tout fabricant de statut donne une source |
| (c) Tout statut posé sur le héros | Les statuts du héros reçoivent une source, ceux des ennemis non |

1. *Décision acquise* — aucune n'est écartée : (a) satisfait le titre de D36 et la lettre de son texte (deux
   statuts sans source sont « même statut et même source »), (b) et (c) aussi.
2. *Valeur mesurée* — aucune n'en touche.
3. *Principes* — neutres.
4. *Mécanisme* — les trois options sont des valeurs d'un même mécanisme, la source sur `StatusEffect` et la
   règle d'`addStatus` : le mécanisme est livré sous sa forme générale — **`addStatus` ne teste jamais
   l'identifiant `might`** —, reste à en choisir la valeur.
5. *Architecture* — écarte (c) : la source est une propriété de ce qui pose, pas de ce qui reçoit ; sous (c),
   une même Puissance suivrait deux règles selon qu'elle tombe sur le héros ou sur un ennemi.
6. *Ce que le joueur lit* — ne départage pas (a) et (b), une fois leurs lecteurs à jour : chaque entrée
   s'affiche avec sa valeur et sa durée.
7. *Périmètre* — **retient (a)**. (b) ferait entrer dans le lot le lecteur de `shock`
   (`lib/game/services/damage_pipeline.dart:31-43`, un `firstWhere`, que P-44 lot 1 réécrit pour « `shock`
   par coup »), les icônes de statut des ennemis, indexées par identifiant
   (`lib/game/components/entities/status_indicator.dart:43-62`), et un changement de **la règle commune**
   elle-même : toute altération posée par une carte cesserait de fusionner avec celle d'une autre carte —
   un remaniement de toutes les altérations que la vague n'annonce pas et que D36, qui parle de la
   Puissance, ne demande pas. A4 n'y contredit pas : il ne change pas la règle commune, il y range les
   statuts des runes, qui y échappaient.

**Choix : (a).** Les trois lecteurs que nomme la fiche — `damage_pipeline.dart:31-43` (`shock`),
`lib/game/services/effects/strategies.dart:71-74` (`lifesteal`), les charges de relique
(`lib/game/controllers/run/player_stats_manager.dart:305-306`, `:339-340`, `:373-374`, `:407-408`) — et
`test/unit/effect_resolver_test.dart:44-63` restent **hors du lot, inchangés** : les statuts qu'ils lisent
sont posés sans source et fusionnent comme avant. Le test de fusion des deux `poison` devient la preuve que,
hors de la Puissance, rien ne bouge.

#### A2 — L'identité d'une source, pour ses six natures *(posée par la fiche)*

Une règle commune s'en dégage : **la source est l'identifiant du contenu qui pose, jamais celui d'un
exemplaire.**

| Nature | Options | Filtre qui tranche | Identité retenue |
|:---|:---|:---|:---|
| **Carte** | (a) `CardData.id` ; (b) `CardInstance.uniqueId`, l'exemplaire | **1** écarte (b). D36 dit « l'id de ce qui l'a posé » et garde « la même carte rejouée s'additionne comme aujourd'hui ». La carte qu'il cite, `demon_form`, est un Pouvoir (`assets/data/cards/demon_form.json`), épuisé une fois joué (`lib/models/card_instance.dart:30-33`) : cet exemplaire-là n'est jamais rejoué dans un combat, la clause ne vise donc pour elle qu'un **second exemplaire** — sous (b), elle n'aurait aucun cas sur la carte même qu'elle cite. L'autre carte qui pose une Puissance, `rage_form` (`assets/data/classes/berserker/cards/rage_form.json`), est une Compétence rejouable ; mais sa Puissance dure un tour, et un exemplaire rejoué dans le tour retrouve une entrée de même durée : sous (a) comme sous (b), le cas est sans effet | `card:<id de la carte>` — `card:demon_form` |
| **Règle de classe** | (a) la classe ; (b) la règle, désignée par la ressource qu'elle convertit ; (c) la source du gain converti (la carte, la relique…) | **1** écarte (c) : D36 compte la règle de classe parmi les poseurs — c'est elle qui pose la Puissance convertie —, et (c) réunirait sous une même source, sur une carte qui poserait une Puissance durable et de l'armure convertie, deux durées : le défaut même que D36 corrige. **1** écarte (a) : `RuleStat` admet `armor` et `mana`, chacune avec sa `duration` (`lib/models/data/stat_rule.dart:6`, `:34`) — deux règles d'une même classe mêleraient deux durées | `rule:<ressource>` — `rule:armor`. `_convert` applique la première règle qui vise une ressource (`lib/game/systems/stat_gains.dart:92-93`) : la ressource désigne la règle dans sa classe, et une run n'a qu'une classe. Toutes les conversions d'un tour fusionnent en une entrée — exact, elles ont toutes la durée de la règle. `StatGain` ne gagne aucun identifiant |
| **Passif** | l'id ; l'`effectType` ; une étiquette commune | **1** : « l'id de ce qui l'a posé » | `passive:<id du passif>` — `passive:rage` |
| **Relique** | l'id ; l'`effectType` ; une étiquette commune | **1** écarte l'étiquette commune : *Plume de scribe* (Puissance d'un tour, `player_stats_manager.dart:384-391`) et *Shuriken* (tout le combat, `:350-357`) réuniraient deux durées ; puis « l'id » de D36 | `relic:<id de la relique>` — `relic:pen_nib` |
| **Statut qui en pose un autre** (`might_regen`) | (a) le statut qui pose ; (b) la source héritée du statut poseur ; (c) une source neuve à chaque tic | **1** écarte (b) : sous A1, `might_regen` n'a pas de source à transmettre — et s'il en avait une, la Puissance d'un `might_regen` posé par une carte rejoindrait la Puissance directe de cette carte, deux durées sous une source. **1** écarte (c) : le poseur est le même statut à chaque tour, et « la même source rejouée s'additionne » ; (c) changerait de surcroît le rendement d'Éveil de Puissance — 1, 2, 2, 1 au lieu de 1, 2, 3, 3 pour 1 pendant 3 tours | `status:<id du statut qui pose>` — `status:might_regen`. Seule, la Puissance d'Éveil se comporte comme aujourd'hui |
| **Ennemi** | (a) `EnemyData.id` ; (b) `EnemyInstance.id`, un uuid ; (c) une étiquette commune | Aujourd'hui les trois se valent : la Puissance d'un ennemi ne vient que de sa propre intention Buff, toujours pour 99 tours (`lib/game/controllers/combat/turn_phase_manager.dart:141-154`). Filtres 1 à 3 neutres ; **4** retient (a) : la règle commune des six natures, celle que D36 impose pour la carte — (b) ferait de l'ennemi une exception | `enemy:<id de l'ennemi>` — `enemy:orc`, le seul ennemi livré à intention Buff (`assets/data/enemies/orc/enemy.json:18`) |

**Ce que « la même carte rejouée s'additionne » veut dire avec deux exemplaires** : deux *Forme Démoniaque*
jouées à deux tours d'écart fusionnent — 4 Puissance, durée la plus longue —, comme aujourd'hui ; deux
exemplaires de raretés différentes aussi, la rareté vivant sur l'exemplaire. C'est la conséquence voulue de
la clause, pas un reste du défaut : D36 ne sépare que des sources différentes.

#### A3 — La forme de l'identité *(apparue à la rédaction ; retenue par l'orchestrateur)*

- **(a) une chaîne `<nature>:<id>`, nullable**, fabriquée par un seul utilitaire ;
- (b) un type valeur — nature et id —, avec égalité et JSON ;
- (c) deux champs sur `StatusEffect`, une énumération de nature et un id.

Les filtres 1 à 7 ne départagent pas : les trois se déclarent en un seul endroit, se sérialisent, et le joueur
n'en voit aucune. **8** retient (a), la plus simple à défaire : un champ `String?`, aucun type neuf dans le
format de sauvegarde. Le préfixe de nature évite qu'une carte et un passif de même identifiant se confondent.

#### A4 — Le sort des statuts que posent les runes élémentaires *(posée par la fiche ; orchestration §7.2 : E0 tranche, E1 suit)*

Aujourd'hui, `lib/game/services/effect_resolver.dart:176-220` fabrique `burn`, `freeze` et `shock` par
`createStatus` (`:184`, `:188`, `:192`) et les **concatène** à la liste de l'ennemi (`:205`, `:214`) : deux
`shock` coexistent, `damage_pipeline` n'en lit qu'un, et l'icône de l'ennemi, indexée par identifiant
(`status_indicator.dart:43-62`), n'en rafraîchit qu'un.

- **(a)** hors de la règle (A1) : E0 ne touche pas le bloc ; **E1, qui le réécrit, pose ces statuts par
  `addStatus`, sans source** — ils fusionnent avec le statut de même identifiant, celui que la carte pose
  elle-même compris, comme tout statut hors Puissance ;
- (b) E1 garde la concaténation ;
- (c) les runes donnent une source à leurs statuts.

Les filtres 1 à 3 ne départagent pas. **4** et **5** retiennent (a) : **un seul chemin de pose pour tous les
statuts**, `addStatus` — celui que suivent déjà les statuts posés par les cartes (`strategies.dart:178`,
`:185`) —, au lieu d'un chemin d'exception pour les runes. (b) garde ce chemin d'exception, la concaténation,
que ne suit aucun autre statut ; (c) en ouvrirait un autre — les seuls statuts hors Puissance suivis par
source. Ce n'est pas le rééquilibrage de carte que le lot refuse : c'est l'alignement d'un effet de rune sur
la règle commune, et **c'est E1 qui le livre**. **Choix : (a)** *(maintenu par l'orchestrateur après
vérification, sur les filtres 4 et 5)*.

**Ce que (a) change au jeu, en E1** — seulement quand un statut de rune tombe sur une cible qui porte déjà ce
statut. Sur une cible qui ne le porte pas, rien ne change : la rune pose son statut avant que les effets de la
carte se résolvent (`effect_resolver.dart:176-220`, puis `:222-243`), et le statut que la carte pose ensuite
par `addStatus` rejoint déjà celui de la rune — *Boule de Feu* portant `burning:1` fait aujourd'hui une seule
brûlure, 3 pendant 2 tours. Exemples à bonus de Puissance nul (le Berserker) :

| Statut | Cas | Aujourd'hui | Après E1 |
|:---|:---|:---|:---|
| Brûlure | Une Attaque sans brûlure propre, portant `burning:2`, jouée deux fois sur la même cible dans le même tour | Deux entrées de 2 pour 2 tours : 4 dégâts, puis 2 — chaque entrée perd 1 par tour (`entity_stats.dart:154-162`) et les dégâts les somment (`status_effect_processor.dart:83-93`, tic final `:116`) | Une entrée de 4 pour 2 tours : 4, puis 3 |
| Choc | *Coup de Tonnerre* (choc 1, un tour) portant `shocking:1`, joué plusieurs fois dans le tour sur la même cible | Dès le second coup, le choc de la rune est une entrée de plus que `damage_pipeline` ne lit pas (`firstWhere`, `:31-43`) : le second coup reçoit +2, le troisième +3 | Chaque choc de rune rejoint le premier et compte : le second coup reçoit +3, le troisième +5 |
| Gel | Toute pose sur une cible déjà gelée | Sa valeur n'est jamais lue ; chaque entrée perd 1 après une attaque, l'ennemi reste gelé tant qu'il en reste une (`turn_phase_manager.dart:107`, `:117-123`) — soit la plus longue | Une entrée de durée la plus longue : **aucun effet de cumul**, rien ne change |

L'icône de l'ennemi, indexée par identifiant (`status_indicator.dart:43-62`), redevient juste : une seule
entrée par statut.

**La ligne joueur que la spec E1 reprend**, dans la part E1 de « Ce que le joueur voit » — transmise ici,
elle n'est pas dans la part E0 (§10) : *« Les runes de brûlure et de choc renforcent désormais la brûlure ou
le choc que la cible porte déjà : le choc d'une rune sur un ennemi déjà électrocuté compte enfin dans les
dégâts, et une brûlure de rune se fond dans la brûlure en cours, qui s'éteint au même rythme au lieu de deux
fois plus vite. »*

Pour E0 : la signature de `createStatus` gagne un paramètre nommé **facultatif** (§4.4) — les trois appels
du bloc ne changent pas, le bloc n'est pas touché.

#### A5 — La borne de `ratio`, et où elle vit *(posée par la fiche)*

**La valeur.** (a) ]0, 1] ; (b) ]0, +∞[ ; (c) [0, 1] ; (d) aucune borne.
**5** écarte (c) et (d) : un ratio nul ou négatif fabriquerait une Puissance nulle ou négative, ce que le
moteur refuse déjà de créer (`stat_gains.dart:75-76`, `:82` : « un statut de valeur négative n'a pas de
sens ») — le modèle refuse au chargement ce que le moteur refuse au gain. Les filtres 1 à 7 ne départagent pas
(a) et (b) : D37 fait du champ « un garde-fou », mais n'interdit pas un ratio supérieur à 1. **8** retient
(a) : élargir une borne plus tard ne casse aucun fichier, la resserrer le peut.

**L'endroit.** (i) dans `StatRule.fromJson`, que le chargeur et la famille 7 de l'éditeur traversent tous deux
(`lib/services/content_editor/entity_validator.dart:96`, `:542-552`) ; (ii) une famille de validation
numérique neuve dans l'éditeur, déclarée sur le descripteur. **5** retient (i) : le jeu doit de toute façon
refuser `"ratio": 2` au chargement, et une seconde copie dans le descripteur écrirait un fait à deux endroits
— la règle d'ADR-100 (D1) : le vocabulaire est lu sur le moteur, jamais recopié. Précédent :
`mastery.perPoint`, refusé à 0 par le modèle (`lib/models/data/passive_data.dart:50-53`).

**Choix : ratio dans ]0, 1], refusé par `StatRule.fromJson`.**

#### A6 — L'arrondi : par gain, à un seul endroit *(apparue à la rédaction ; retenue par l'orchestrateur)*

**Par gain ou par tour.** (a) Chaque gain est converti et arrondi seul ; (b) l'armure d'un tour est cumulée,
puis convertie. **1** retient (a) : D37 confie le ratio à `StatGains._convert`, qui ne voit qu'un gain à la
fois (`stat_gains.dart:77-110`), et donne ses exemples montant par montant. Deux *Défense* dans un tour
donnent 3 + 3 = 6, et non 5.

**Le calcul.** Un produit flottant peut dépasser un entier exact : `0.1 × 30` vaut `3.0000000000000004`, dont
l'arrondi supérieur est 4. (i) Arrondi supérieur du produit brut ; (ii) arrondi supérieur avec une tolérance
de 10⁻⁹, au moins 1 ; (iii) un ratio en fraction, deux entiers. **1** écarte (iii) : D37 nomme « le champ
`ratio` », un nombre (0,5). **6** écarte (i) : le texte annonce « arrondi à l'entier supérieur » (§5.1), et
30 → 4 à 10 % le contredirait. **Choix : (ii), dans une seule fonction de `StatRule`**, appelée par `_convert`
et par le texte de la règle : l'exemple que lit le joueur sort de l'arithmétique que le moteur applique.

#### A7 — Où le joueur lit le taux *(née de « La spec doit fixer » : « les textes générés qui doivent dire "6 armure → 3 Puissance" »)*

Le brainstorm, §7.2 (ligne *Rage*), en fait une proposition — pas une décision de son §1 : « chez lui
"6 armure" se lit "+3 Puissance ce tour" (D37), et la description doit le dire ». **« La description » est lue
ici comme la phrase de la règle de classe** ; la lecture « texte de la carte » est l'option (c) ci-dessous,
écartée et signalée pour la file.

- **(a)** la phrase de la règle — carte de classe, tutoriel — gagne, quand le ratio diffère de 1, une seconde
  phrase : le taux et l'exemple de D37, calculé par A6 ; le titre du panneau du tutoriel ne change pas ;
- (b) (a), et le titre « ARMURE → PUISSANCE » porte aussi le taux ;
- (c) (a), et chaque carte d'armure affiche, chez une classe qui convertit, sa valeur convertie
  (« +3 Puissance » au lieu de « 6 Armure »).

**6** — l'effet doit se lire sans règle cachée — est satisfait par les trois, et par (a) déjà : la règle est
écrite là où elle l'est aujourd'hui, et au moment du gain le joueur voit la Puissance réelle dans le panneau des
effets, et dans le tutoriel le gain mesuré (« +2 Puissance », `lib/tutorial/widgets/tutorial_armor_widget.dart:96-104`).
**7** écarte (c) : aucun rendu de carte ne lit les règles de classe aujourd'hui — ni `card_text_renderer.dart`,
ni `card_component.dart`, ni `ui_card/ui_card_helpers.dart`, ni `ui_card/card_compact_description.dart` —, et
sous la conversion 1:1 la carte disait déjà « Armure » ; apprendre la règle de la run à quatre rendus, Flame et
Flutter, est une fonctionnalité à part entière. **8** départage (a) et (b) : (b) n'ajoute rien que la phrase
placée juste dessous ne dise, et (a) laisse le titre tel quel — la plus simple à défaire. **Choix : (a).** La
carte qui lirait la règle est signalée pour la file (§2).

#### A8 — Le panneau des statuts quand deux Puissances coexistent *(née de « La spec doit fixer »)*

- **(a)** une ligne par entrée, tel qu'aujourd'hui (`lib/ui/widgets/hud/status_effects_panel.dart:74-84`, la
  durée à `:174`) ;
- (b) une ligne par identifiant, valeurs sommées ;
- (c) une ligne par entrée, suffixée du nom de sa source.

**6** écarte (b) : une seule durée ne peut pas dire deux vieillissements, précisément ce que D36 rend
visible. **7** retient (a) contre (c) : (c) demanderait au panneau, qui ne reçoit que des statuts, de
retrouver dans le registre le nom d'une carte, d'un passif ou d'une relique — ou de stocker un nom localisé
sur chaque statut —, sans que la règle en soit plus lisible. **Choix : (a)**, aucun code dans le panneau ;
la barre de vie garde la somme (`lib/ui/widgets/hud/player_health_bar.dart:134`).

#### Récapitulatif

| # | Question | Options | Filtre qui tranche | Choix |
|:---|:---|:---|:---|:---|
| A1 | Portée de la règle | `might` seul · tout statut · statuts du héros | 5 écarte « statuts du héros », 7 retient `might` seul | `might` seul, mécanisme général |
| A2 | Identité, six natures | instance ou contenu, étiquette ou id, héritée ou propre | 1 (carte, règle, passif, relique, statut), 4 (ennemi) | L'id du contenu qui pose ; `rule:<ressource>` pour la règle |
| A3 | Forme de l'identité | chaîne · type valeur · deux champs | 8 | Chaîne `<nature>:<id>`, nullable |
| A4 | Statuts des runes élémentaires | `addStatus` sans source · concaténation · source de rune | 4 et 5 (maintenu par l'orchestrateur) | Hors règle ; E1 les pose par `addStatus`, sans source — changement de jeu chiffré, livré et annoncé par E1 |
| A5 | Borne de `ratio` | ]0, 1] · ]0, +∞[ · [0, 1] · aucune ; modèle ou descripteur | 5 puis 8 ; 5 | ]0, 1], refusé par `StatRule.fromJson` |
| A6 | Arrondi | par gain · par tour ; brut · tolérance · fraction | 1 ; 1 puis 6 | Par gain, arrondi supérieur à 10⁻⁹ près, une fonction |
| A7 | Où se lit le taux | la phrase · + le titre · + les cartes | 7 écarte les cartes, 8 le titre | Une seconde phrase à la règle |
| A8 | Panneau à deux Puissances | une ligne par entrée · sommée · nommée | 6 puis 7 | Une ligne par entrée, tel quel |

---

## 2. Périmètre

**Dans E0**

- le champ `sourceId` de `StatusEffect`, la règle de fusion d'`addStatus` et de `combine`, l'utilitaire des
  identités ;
- les neuf sites qui fabriquent une Puissance, chacun avec sa source ; le paramètre facultatif de
  `createStatus` ;
- `StatRule.ratio`, sa borne, son arithmétique, sa lecture par `_convert`, et l'accesseur `statName` (§4.2) ; `"ratio": 0.5` dans
  `classes/berserker/class.json` ;
- la seconde phrase de la règle en clair, deux chaînes ARB par langue ;
- le `toString` de la règle, que lit le menu de debug ;
- les tests (§8).

**Hors d'E0**

| Sujet | Où |
|:---|:---|
| `forge_upgrade_data.dart`, le `switch` des runes (`effect_resolver.dart:142-164`), la logique du bloc élémentaire (`:176-220`) et sa pose par `addStatus` (A4) | E1, même vague |
| `mightRatio` par effet `damage`, le budget de Puissance (D38) | P-44 lot 1 (D66) |
| `shock` par coup ; `weakness`, `vulnerable`, `freeze` lus comme des booléens | P-44 lot 1 |
| Une source sur un statut autre que `might` | Écartée (A1) |
| Le texte d'une carte d'armure qui lirait la règle de la classe (A7) | Non planifié — signalé pour la file |
| La nature de source d'une signature devenue compétence de classe | E4 : elle ne sera plus une carte |
| Le défaut d'ordre de `processEnemyStatuses` (ADR-097, Conséquences) | Hors programme, inchangé |
| Tout rééquilibrage de carte | Aucun : D37 est un garde-fou de classe, pas un nerf de carte |
| `tool/simulations/d26_economy_sim.dart` | Non touché (§9) |

---

## 3. Données

### 3.1. La règle du Berserker

`assets/data/classes/berserker/class.json:14-16` — la seule donnée qui change :

```json
"statRules": [
  { "stat": "armor", "mode": "convert", "to": "status:might", "duration": 1, "ratio": 0.5 }
]
```

Le Paladin et le Mage ne déclarent aucune règle. Aucun dossier neuf : `tool/sync_assets.dart` n'est pas à
relancer.

### 3.2. `StatRule.ratio`

| Élément | Contrainte |
|:---|:---|
| Type | Un nombre JSON, entier ou décimal ; `StatRule.ratio` est un `double` |
| Absent | 1 — la conversion d'aujourd'hui, à l'identique |
| Bornes | **]0, 1]** (A5). Hors bornes, ou non numérique : `FormatException` levée par `StatRule.fromJson`, avec la valeur reçue — accumulée par `GameDataLoader.throwIfFailed`, montrée par la famille 7 de l'éditeur |
| Égalité | `==` et `hashCode` (`stat_rule.dart:94-104`) comptent le ratio : `RunState.fromJsonWithReport` reconstruit les règles depuis le registre, et une égalité qui l'ignorerait laisserait passer une reconstruction fausse |
| `toString` (`:112-114`) | Inchangé à 1 ; sinon suivi de `, ratio <valeur>` : `armor convert status:might, 1 tour(s), ratio 0.5` — le vocabulaire du fichier (§6.2) |

`HeroData.fromJson` ne change pas : il lit déjà `statRules` par `StatRule.parseAll`.

### 3.3. `StatusEffect.sourceId`

Une donnée d'exécution, pas d'asset : aucun fichier sous `assets/data/` ne pose de statut avec une source.

| Élément | Contrainte |
|:---|:---|
| Champ | `sourceId`, `String?`, facultatif et nommé dans le constructeur (`lib/models/status_effect.dart:11-18`), qui reste `const` ; repris par `copyWith` |
| `null` | « Sans source » : le cas de tout statut autre que `might` (A1) |
| JSON | Clé `sourceId`, **écrite seulement si elle n'est pas nulle** (`toJson`, `:52-59`) ; absente à la lecture, elle vaut `null` (`fromJson`, `:38-50`) |

---

## 4. Le moteur

### 4.1. La règle de fusion

| Où | Aujourd'hui | Avec E0 |
|:---|:---|:---|
| `EntityStats.addStatus` (`lib/models/entity_stats.dart:134-145`) | Cherche une entrée de même `id` (`:135`) | Cherche une entrée de même `id` **et** de même `sourceId` — `null` compris |
| `StatusEffect.combine` (`status_effect.dart:62-78`) | Rend l'effet tel quel si les `id` diffèrent (`:63`) | … si les `id` **ou** les `sourceId` diffèrent |

Au sein d'une même entrée, rien ne change : `isStackable` (`:17`) additionne les valeurs et garde la durée la
plus longue, ou garde le maximum des deux. `effectiveMight` (`entity_stats.dart:180-188`) somme déjà toutes les
entrées `might`, et `tickStatuses` (`:148-166`) les vieillit une à une : ni l'un ni l'autre ne change.

### 4.2. Les identités

Un utilitaire du modèle, `StatusSource`, dans `lib/models/status_effect.dart` à côté de `StatusEffect`,
fabrique les six formes — le seul endroit qui les écrive :

| Nature | Forme | Exemple |
|:---|:---|:---|
| Carte | `card:<id de la carte>` | `card:demon_form` |
| Règle de classe | `rule:<ressource, dans le vocabulaire du fichier>` | `rule:armor` |
| Passif | `passive:<id du passif>` | `passive:rage` |
| Relique | `relic:<id de la relique>` | `relic:shuriken` |
| Statut | `status:<id du statut qui pose>` | `status:might_regen` |
| Ennemi | `enemy:<id de l'ennemi>` | `enemy:orc` |

La ressource de la règle s'écrit dans le vocabulaire du fichier — la table `_stats` de `StatRule`
(`stat_rule.dart:43-46`) —, pas par un nom d'énumération Dart (`stat.name`) : la précaution qu'ADR-100 (D1)
prend pour `status:might`. `statNames` (`:64`) rend la liste de **tous** les noms, et le nom d'une règle donnée
ne passe aujourd'hui que par `_nameOf` (`:68-69`), privé, que lit `toString` (`:113-114`). E0 ajoute donc à
`StatRule` un accesseur public, **`String get statName`**, par `_nameOf(stat, _stats)` : c'est par lui seul que
`rule:<ressource>` lit la table.

### 4.3. Les neuf sites qui fabriquent une Puissance

| Site | Où | Avec E0 |
|:---|:---|:---|
| Carte (`apply_status` sur `might`) | `strategies.dart:164-169`, par `EffectResolver.createStatus` | Passe `card:<card.data.id>` à la fabrique (§4.4) |
| Conversion de classe | `stat_gains.dart:98-106` — l'entrée de *Mur de Fer* chez le Berserker naît là, d'un `GainSource.card` sans id | `rule:<ressource de la règle>` ; la valeur passe par le ratio (§4.5) |
| *Ferveur*, *Rage*, *Frénésie* | `lib/game/systems/passives/passive_strategies.dart:15-21`, appelé `:130`, `:174-176`, `:215` | La fabrique locale reçoit le passif et pose `passive:<passive.id>` |
| Relique `gain_might` hors début de run | `player_stats_manager.dart:255-263` | `relic:<relic.id>`. Aucune relique livrée n'y passe : `whetstone` et `cursed_blade` sont `startOfRun` |
| *Shuriken* (`charge_might_combat`) | `player_stats_manager.dart:350-357` | `relic:shuriken` |
| *Plume de scribe* (`charge_might_turn`) | `player_stats_manager.dart:384-391` | `relic:pen_nib` |
| Éveil de Puissance, héros | `lib/game/controllers/combat/status_effect_processor.dart:34-44` | `status:might_regen`. Aucune carte livrée ne pose `might_regen` (rien sous `assets/data/`) : la branche n'est pas atteinte aujourd'hui |
| Éveil de Puissance, ennemi | `status_effect_processor.dart:95-105` | `status:might_regen`. **E0 change cette branche** : aujourd'hui, sur un ennemi qui porte déjà la Puissance de son intention Buff (99 tours, `turn_phase_manager.dart:141-154`), le gain d'Éveil fusionne dans cette entrée (`entity_stats.dart:135`, `:139`) et survit au tic ; avec E0 il devient une entrée à part, d'un tour, que le tic final du même appel retire (`:116`). La branche reste morte : aucun `might_regen` sous `assets/data/`, et seul `orc` a une intention Buff (`assets/data/enemies/orc/enemy.json:18`) |
| Intention Buff d'un ennemi | `turn_phase_manager.dart:141-154` | `enemy:<enemy.data.id>` |

Ce sont les neuf constructions de `id: 'might'` de `lib/` : aucune autre n'existe.

### 4.4. La fabrique `createStatus`

`EffectResolver.createStatus` (`effect_resolver.dart:16-93`) gagne un paramètre **nommé et facultatif**,
`sourceId`. Sa table déclare déjà, statut par statut, le nom et le type de chaque statut posé par une carte ;
**seule la branche `might` (`:26-33`) retient la source**, les autres l'ignorent — c'est là que la portée
d'A1 s'écrit, une fois, pour le chemin des cartes. Ses appelants :

| Appelant | Avec E0 |
|:---|:---|
| `ApplyStatusEffectStrategy` (`strategies.dart:164-169`) | Passe toujours `card:<card.data.id>` |
| *Marque du Mage* (`passive_strategies.dart:84-88`, `vulnerable`) | Inchangé |
| Le bloc élémentaire (`effect_resolver.dart:184`, `:188`, `:192`) | **Inchangé** : le paramètre est facultatif (A4) |

### 4.5. Le `ratio` dans la conversion

`StatRule` porte l'arithmétique (A6) : le montant converti d'un gain strictement positif est son produit par le
ratio, **arrondi à l'entier supérieur avec une tolérance de 10⁻⁹, et jamais moins de 1**. `_convert`
(`stat_gains.dart:77-110`) l'appelle à la place de `gain.amount` ; le garde d'un gain nul ou négatif (`:82`)
reste devant. À ratio 1, le résultat est le montant lui-même.

| Ratio | 1 | 5 | 6 | 10 | 30 |
|:---|---:|---:|---:|---:|---:|
| 0,5 | 1 | 3 | 3 | 5 | 15 |
| 1 | 1 | 5 | 6 | 10 | 30 |
| 0,1 | 1 | 1 | 1 | 1 | **3**, et non 4 |

**Chaque gain est arrondi seul.** Une carte d'armure portant une rune `hardened` ne fait qu'un gain — la rune
s'ajoute à l'effet (`effect_resolver.dart:225-229`) — ; une carte sans armure portant la rune en fait un à
part (`:245-250`), arrondi pour lui-même. `armor_regen` somme ses entrées en un gain par tour
(`status_effect_processor.dart:20-28`, `:57-63`) : un seul arrondi.

Le passage unique d'ADR-095 tient : la conversion reste dans `StatGains.apply`, et
`test/unit/stat_gain_single_passage_test.dart` n'est pas touché.

### 4.6. Ce que cela fait au combat

**Le cas de D36** — le Berserker joue *Forme Démoniaque* (2 Puissance, 4 tours), puis *Mur de Fer*
(10 Armure) au même tour T :

| Tour | Aujourd'hui | Avec E0 |
|:---|:---|:---|
| T | 12 — une entrée de 12, 4 tours | **7** — `card:demon_form` 2 (4 tours) et `rule:armor` 5 (1 tour) |
| T+1 à T+3 | 12 | 2 |
| T+4 | 0 | 0 |

***Rage* ne s'accumule plus** (revue, R3 c). Aujourd'hui, la Puissance de *Rage*, posée chaque début de tour
après le tic (`lib/game/controllers/run_controller.dart:466-477`), rejoint l'entrée d'une *Forme Démoniaque* en
cours et y reste jusqu'à son terme : elle grossit de tour en tour. Avec E0, `passive:rage` a son entrée, qui
expire au tic suivant avant que la nouvelle ne se pose.

**Les mêmes sources s'additionnent comme aujourd'hui** : deux *Forme Démoniaque* ; les conversions d'un tour ;
les morts d'un tour sous *Frénésie* ; *Ferveur* d'un tour ennemi à l'autre (un +1 pour 2 tours, encore actif,
rejoint le suivant et prend sa durée) ; les charges de *Shuriken*. Une entrée de même source n'a jamais
qu'une durée.

**Les cartes d'armure, chez le Berserker** (rareté commune) :

| Carte | Armure | Puissance aujourd'hui | Avec E0 |
|:---|---:|---:|---:|
| *Mur de Fer* (`iron_wall`) | 10 | 10 | 5 |
| *Défense* (`defend_basic`) | 5 | 5 | 3 |
| *Éveil* (`awakening`) | 4 | 4 | 2 |
| *Cri de Guerre* (`warcry`) | 4 | 4 | 2 |

### 4.7. Ce qui ne change pas

- Les lecteurs qui supposent une entrée par identifiant — `shock` (`damage_pipeline.dart:31-43`),
  `lifesteal` (`strategies.dart:71-74`), les charges de relique, les icônes des ennemis
  (`status_indicator.dart:43-62`) — : ils ne lisent aucune Puissance de héros. L'icône des ennemis ne voit
  jamais deux `might` : la Puissance d'un ennemi n'a qu'une source, son intention, et celle d'Éveil meurt dans
  l'appel qui la crée (ADR-097).
- Les sommes de `StatusEffectProcessor` (`:20-28`, `:76-86`), `PassiveCounters.valueOf`, `effectiveMastery`,
  `effectiveCritChance`.
- L'ordre du début de tour (`run_controller.dart:443-477`) et le vieillissement délibéré d'Éveil, 3 → 2
  (`status_effect_processor.dart:45-55`).
- `StatGain` et `GainSource` ; `removeStatus(id)`, qui retire toutes les entrées d'un identifiant.

### 4.8. La frontière avec E1

| Fichier | E0 | E1 |
|:---|:---|:---|
| `effect_resolver.dart` | `createStatus` (`:16-93`) et son paramètre facultatif | Le `switch` (`:142-164`) et le bloc élémentaire (`:176-220`), réécrit selon A4 : par `addStatus`, sans source — le changement de jeu qu'A4 chiffre est livré et annoncé par E1 |
| `entity_descriptor.dart` | **Non touché** : `ratio` n'y entre pas (A5, §6.1) | Le descripteur de rune |

E1 trouve la fabrique de statuts avec sa signature finale ; elle n'a rien à lui demander de plus pour poser des
statuts sans source.

---

## 5. Textes joueur

### 5.1. La règle en clair

`StatRuleLabel.describe` (`lib/models/data/model_extensions.dart:154-166`) rend aujourd'hui une phrase par
triplet (ressource, mode, cible), paramétrée par la seule durée (`lib/l10n/app_fr.arb:108-109`,
`lib/l10n/app_en.arb:172-183`). **À ratio 1, elle ne change pas.** Sinon, une seconde phrase s'y ajoute, tirée
d'une clé par ressource, dans le même `switch` exhaustif :

| Clé | Français | English |
|:---|:---|:---|
| `statRuleRatioArmor` | `Taux : {percent}%, arrondi à l'entier supérieur — {amount} Armure → {converted} Puissance.` | `Rate: {percent}%, rounded up — {amount} Armor → {converted} Might.` |
| `statRuleRatioMana` | `Taux : {percent}%, arrondi à l'entier supérieur — {amount} Mana → {converted} Puissance.` | `Rate: {percent}%, rounded up — {amount} Mana → {converted} Might.` |

- `{percent}` : le ratio en pourcentage, arrondi à l'unité (50) — écrit `50%`, sans espace, comme les
  pourcentages du français existant (`app_fr.arb:64`, `:184`) ;
- `{amount}` : **6**, l'exemple de D37, une constante d'affichage de `StatRuleLabel` ;
- `{converted}` : la conversion de 6 par la fonction d'A6 — l'exemple ne peut pas mentir sur le moteur.

Trois placeholders entiers, déclarés dans `app_en.arb`, le gabarit (`l10n.yaml`) ; `flutter gen-l10n` régénère
les trois `app_localizations*.dart`.

**Le Berserker, à l'écran de sélection et au tutoriel** :

| | Texte |
|:---|:---|
| Français | Son Armure devient de la Puissance pour un tour. Taux : 50%, arrondi à l'entier supérieur — 6 Armure → 3 Puissance. |
| English | Their Armor becomes Might for one turn. Rate: 50%, rounded up — 6 Armor → 3 Might. |

Où elle s'affiche : la carte de classe (`lib/ui/screens/class_selection_screen.dart:646-649`) et l'encadré de
l'étape « Armure & Dégâts » (`tutorial_armor_widget.dart:464-466`). Aucun appelant ne change.

`StatRuleLabel.shortTitle` (`model_extensions.dart:181-186`) — « ARMURE → PUISSANCE » — **ne change pas**
(A7) ; le titre de l'étape, écrit en dur (`lib/tutorial/tutorial_data.dart:177-178`), non plus, ni le corps de
l'étape, qui dit seulement que certaines classes changent leur Armure « en autre chose ».

### 5.2. Le panneau des effets et la barre de vie

Rien ne change dans le code (A8). Le joueur qui a joué *Forme Démoniaque* puis *Mur de Fer* lit :

| Panneau des effets | |
|:---|:---|
| ⚡ `Puissance : +2` | `4 trs` |
| ⚡ `Puissance : +5` | `1 trs` |

et `7` à côté de l'éclair de sa barre de vie. Une ligne par source présente ; au plus une par source.

### 5.3. Le tutoriel

ADR-081 tient : `lib/tutorial/` ne gagne ni provider ni recopie. Le gain de démonstration passe par
`StatGains.apply` et les règles de la classe choisie (`lib/tutorial/tutorial_engine.dart:318-323`), le jeu de
cartes aussi (`:399-407`) : le ratio du `class.json` s'y applique de lui-même.

| Ce que voit le Berserker | Aujourd'hui | Avec E0 |
|:---|:---|:---|
| Démonstration, 4 Armure (`tutorial_armor_widget.dart:21`) | `+4 Puissance` | `+2 Puissance` |
| *Défense* jouée à l'étape des cartes | `+5 ⚡` | `+3 ⚡` |
| Encadré de la règle | Une phrase | Deux phrases (§5.1) |

L'encadré de l'étape a une hauteur fixe pour une classe à règle (`tutorial_armor_widget.dart:189`) : la seconde
phrase ne doit pas le faire déborder — les tests de l'étape échouent sur un débordement. Les commentaires qui
citent « +4 puis +8 Puissance » (`tutorial_engine.dart:359-362`) suivent les nouvelles valeurs.

### 5.4. Ce qui ne change pas

Le texte des cartes (A7) ; les noms des statuts créés en code (« Puissance », « Puissance (Relique) ») ;
`statusMight` et `statusTurns`.

---

## 6. L'éditeur de contenu et le menu de debug

### 6.1. L'éditeur

`ratio` n'a **pas d'entrée de descripteur** (A5) : `entity_descriptor.dart` n'est pas touché. L'éditeur
l'apprend par le modèle :

| Geste | Ce qui se passe |
|:---|:---|
| Le formulaire ouvre `classes/berserker/class.json` | `statRules[]` est une liste d'objets ; `ratio`, décimal, reçoit un champ décimal (`lib/services/content_editor/field_kind.dart:46`), à côté des trois listes fermées de `stat`, `mode` et `to` (`entity_descriptor.dart:426-430`) |
| L'auteur écrit `0`, `1.5` ou `"0.5"` | Refusé par la famille 7 (`entity_validator.dart:542-552`), avec le message de `StatRule.fromJson` |
| Une classe créée depuis la console | Son gabarit garde `"statRules": []` (`entity_descriptor.dart:451`, ADR-100 D2) : une règle s'y écrit en JSON brut, `ratio` facultatif |

### 6.2. Le menu de debug

L'onglet « Héros » affiche chaque règle de la run par `StatRule.toString()`, en lecture seule
(`lib/ui/widgets/debug/tabs/debug_hero_tab.dart:121-127` ; ADR-100 D6) : la ligne du Berserker devient
`armor convert status:might, 1 tour(s), ratio 0.5`. Aucun code de l'onglet ne change, et le ratio ne se règle
pas : la règle vient du `class.json`, et la run la relit de sa classe.

---

## 7. La sauvegarde

**Rien à migrer ; `SaveMigrator.currentVersion` ne bouge pas.**

| Élément | Pourquoi rien ne casse |
|:---|:---|
| Les statuts | Le format les porte (`entity_stats.dart:82-88`, `:129`), mais la liste est vide à toute écriture : vidée en fin de combat (`lib/game/controllers/run/map_progression_manager.dart:37`) et au début du suivant (`run_controller.dart:431-436`) ; la sauvegarde n'est jamais écrite en combat |
| `sourceId` | Absent à la lecture, il vaut `null` (§3.3) ; jamais écrit pour un statut sans source |
| `ratio` | `RunState.statRules` n'est pas sérialisé : il est relu du registre par la classe (`run_controller.dart:202-204`, ADR-097 D1). Une run du Berserker rechargée prend le ratio 0,5 d'elle-même |

---

## 8. Tests

| Sujet | Fichier | Ce qu'il verrouille |
|:---|:---|:---|
| Fusion par source | `test/unit/status_source_test.dart` *(nouveau)* | `addStatus` : même identifiant et même source → une entrée, valeurs additionnées, durée la plus longue ; sources différentes → deux entrées ; deux statuts sans source fusionnent comme avant ; `combine` rend l'effet inchangé si les sources diffèrent ; `effectiveMight` somme deux entrées, `tickStatuses` les vieillit séparément ; JSON : aller-retour avec `sourceId`, clé absente → `null`, aucune clé écrite sans source ; les six formes de §4.2 |
| Le cas de D36 | même fichier | *Forme Démoniaque* (`card:demon_form`, 2, 4 tours) puis 10 Armure sous une règle d'Armure à 0,5 : deux entrées, 2 (4 tours) et 5 (1 tour), `effectiveMight` 7 ; après un tic, 2 ; après quatre, 0. Deux *Forme Démoniaque* **à un tic d'écart** : une entrée de 4 — la source traverse le tic, que `tickStatuses` reconstruit par `copyWith` (`entity_stats.dart:155-160`, `status_effect.dart:20-36`) |
| La fabrique | `test/unit/effect_resolver_test.dart` | `createStatus('might', …, sourceId:)` garde la source ; `createStatus('poison', …, sourceId:)` ne la garde pas (A1). Le test des deux `poison` (`:44-63`) reste tel quel |
| La carte | `test/unit/might_orientation_test.dart:224-232` | La Puissance posée par une carte porte `card:<id de la carte>` |
| La règle et le ratio, au gain | `test/unit/stat_rule_conversion_test.dart` | La Puissance convertie porte `rule:armor` ; à 0,5, 6 Armure → 3 Puissance et aucune Armure ; deux gains de 5 → 6, arrondis un par un (A6). `:87-92` (deux gains → une entrée) reste vert : même source |
| Les passifs | `test/unit/passives_berserker_test.dart`, `test/unit/passives_paladin_test.dart` | *Rage*, *Frénésie*, *Ferveur* posent `passive:<id>` ; *Rage* en début de tour ne rejoint pas une *Forme Démoniaque* en cours, et son entrée expire au tic suivant (R3 c) |
| Les reliques, Éveil | `test/unit/stat_gains_characterization_test.dart` | *Plume de scribe* et *Shuriken* posent `relic:<id>`, durées 1 et 99 ; leurs charges restent une entrée chacune ; une relique de test `gain_might` hors `startOfRun` — l'aide `relic(...)` du fichier la déclare déjà en `startOfTurn` (`:89-91`) — pose `relic:<id>` (`player_stats_manager.dart:251-264`) ; Éveil de Puissance, côté héros, pose `status:might_regen` et, seul, s'accumule comme aujourd'hui — **1, 2, 3, 3 sur quatre débuts de tour**, ce qui fait traverser à la source quatre tics (`entity_stats.dart:148-166`). **La branche ennemie d'Éveil** (`status_effect_processor.dart:95-105`) : un ennemi portant un `might` `enemy:orc` de 2 pour 99 tours et un `might_regen` de 1 passe par `processEnemyStatuses` ; `effectiveMight` (Puissance permanente à 0) vaut **2, et non 3 comme aujourd'hui** — la Puissance d'Éveil, devenue une entrée à part, est retirée par le tic final du même appel (`:116`), quand aujourd'hui elle fusionne dans l'entrée de l'intention et survit |
| L'ennemi | `test/unit/combat_controller_test.dart` | L'intention Buff pose `enemy:<id de l'ennemi>` ; deux Buff → une entrée |
| `ratio` | `test/unit/stat_rule_test.dart` | Lu à 0,5 ; 1 en son absence ; un entier admis ; refusé à 0, négatif, au-delà de 1, non numérique ; compté par `==` et `hashCode`. L'arithmétique : à 0,5, 1 → 1, 5 → 3, 6 → 3 ; identité à 1 ; à 0,1, 30 → 3 |
| La donnée | `test/unit/class_identity_test.dart:49-55` | La règle du Berserker déclare un ratio de 0,5 |
| Le vocabulaire | `test/unit/stat_rule_vocabulary_test.dart:50-69` | `toString` inchangé à 1 ; `…, ratio 0.5` à 0,5 |
| Les textes | `test/unit/stat_rule_label_test.dart` | Ses trois tests, à ratio 1, restent tels quels ; à 0,5, les deux phrases exactes, en français et en anglais, pour l'Armure et pour le Mana |
| Le panneau | `test/widget/status_effects_panel_overflow_test.dart` | Deux `might` de sources différentes : deux lignes, chacune avec sa durée |
| L'éditeur | `test/unit/content_editor/entity_validator_test.dart` | Une classe à ratio 0, 1,5 ou `"0.5"` refusée par la famille 7 ; à 0,5, acceptée |
| Le debug | `test/widget/debug_drawer_test.dart:328-330` | Le héros de test déclare 0,5 : la ligne de sa règle porte `ratio 0.5` |
| Le tutoriel | `test/tutorial/tutorial_engine_test.dart:172-174`, `:276-280` ; `test/widget/tutorial_armor_step_test.dart:103`, `:138`, `:152-155`, `:170` ; `test/widget/tutorial_play_card_step_test.dart:123` | Ils vérifient la conversion 1:1 sur la vraie classe : réécrits sur la conversion réelle — 4 Armure → 2, *Défense* 5 → 3 —, la phrase de la règle en deux phrases ; « presser deux fois n'empile pas » à 2. L'étape s'affiche sans débordement. Les commentaires qui citent l'ancienne conversion suivent : `test/widget/tutorial_armor_step_test.dart:95-100` (le badge « 4 » de Puissance) et `:164-169` (« +4, jamais +8 »), `test/tutorial/tutorial_engine_test.dart:284-286` (« +4 puis +8 ») |

`test/widget/class_selection_screen_test.dart` : **`_berserkerReel`** (`:83-101`), la copie du vrai Berserker,
déclare `ratio: 0.5` comme `class.json` ; les groupes « sans débordement » qui l'emploient (`:866`, `:1004`),
sur mobile, sur bureau et sous `TextScaler.linear(1.3)` (`:950`, `:1073`), gardent alors la règle en deux
phrases sur la carte de classe (`class_selection_screen.dart:646-649`) sans débordement. Le `berserker` local
du groupe de l'identité générée (`:667-684`, lu en `:734`) reste à ratio 1 : son test garde la phrase seule.
**Aucun test existant ne lit deux Puissances de sources différentes sur un héros** : les lecteurs d'entrée
`might` de `test/` — `tutorial_engine_test.dart:172`, `might_orientation_test.dart:230`,
`passives_berserker_test.dart:138`, `passives_paladin_test.dart:101`, `stat_rule_conversion_test.dart:33` — n'en
voient qu'une source chacun (ceux de `passives_berserker_test.dart:84` et `passives_paladin_test.dart:73`
somment), et seul `effect_resolver_test.dart:46`, `:61` compte des entrées, de `poison`.

`dart analyze` propre et suite verte, comme chaque lot du programme.

---

## 9. La simulation

**Aucun réalignement ; aucune tâche ne touche le script.** `tool/simulations/d26_economy_sim.dart` ne lit de
`statRules` que le mode `convert` (`:808-816`) : la clé `ratio` est ignorée, et le taux de 0,5 y est déjà en dur
(`:1441`). La relance de fin de vague, faite par l'orchestrateur, doit rendre un diff vide contre
`tool/simulations/d26_reference_output.md` (D73).

Pour information : le script tient la Puissance temporaire **une entrée par gain** (`:1376`, `:1482`,
`:1500`, `:1555`, `:1589`, `:1611`) — plus fin que D36, qui réunit une même source. Les deux divergent sur deux
*Forme Démoniaque*, sur *Ferveur* d'un tour à l'autre, et sur Éveil de Puissance (1, 2, 2, 1 dans le script ;
1, 2, 3, 3 dans le jeu, aujourd'hui comme après E0). Aucune valeur de D56 à D62 ni de D67 n'en dépend.

---

## 10. Documentation et livraison — la part d'E0

**Pour `memory-bank-sync`**, à la fin de la vague :

| Quoi | Contenu |
|:---|:---|
| Un ADR neuf, « un statut par source et `ratio` de conversion » | A1 à A8 ; il **complète ADR-097** — `StatRule` gagne `ratio`, *Mur de Fer* ne vaut plus 10 Puissance au Berserker mais 5 — sans en amender aucune décision ; le passage unique d'ADR-095 tient. Il note que la conséquence d'ADR-097 « `might_regen` d'ennemi mort » devient **exactement vraie** : la Puissance d'Éveil d'un ennemi ne fusionne plus dans celle de son intention Buff (§4.3) |
| `_rules/04-00` | La fusion des statuts (§4.3 de la fiche et sa colonne « Empilable ») : même identifiant **et** même source ; la Puissance par source ; la source de la Puissance d'Éveil |
| `_rules/02-2` | L'encadré du Berserker : la conversion à 50 %, arrondie à l'entier supérieur — *Mur de Fer* donne 5 Puissance |
| À relire, que le diff peut périmer | `_patterns/19-00` (la ligne `statRules` de la table des clés : `ratio`, borné par le modèle) ; `_patterns/18-00` (la règle affichée avec son ratio) ; `_rules/08-00` (l'étape « Armure & Dégâts » : la règle en deux phrases) |

**Ce que le joueur voit en `0.5.3`, part E0** :
- le Berserker ne convertit plus que la moitié de son Armure en Puissance, arrondie au supérieur :
  *Mur de Fer* lui donne 5 Puissance pour le tour au lieu de 10, *Défense* 3, *Éveil* et *Cri de Guerre* 2 ;
  sa carte de classe et le tutoriel l'écrivent ;
- deux bonus de Puissance venus de sources différentes ne se confondent plus : *Forme Démoniaque* puis
  *Mur de Fer* donnent 7 Puissance ce tour-ci, puis 2 pendant trois tours — et non plus 12 pendant quatre ;
  la Puissance de *Rage* ne s'accumule plus dans celle de *Forme Démoniaque* ; le panneau des effets montre une
  ligne de Puissance par source, chacune avec sa durée.

Pas de lien dans `docs/ROADMAP.md`, pas de note de version propre au lot : la note est celle de la vague,
écrite à sa fin.

---

## 11. Alternatives écartées

| Idée | Motif |
|:---|:---|
| **Fusionner les `might` « à durée égale »** (revue, §8.2 idée 2) | Le mécanisme retenu par D36 est la source ; à durée égale, deux *Forme Démoniaque* jouées à deux tours d'écart ne fusionneraient plus, contre la clause « la même carte rejouée s'additionne » |
| **Une source sur tout statut** | Fait entrer dans le lot le lecteur de `shock`, les icônes des ennemis et un changement de la règle commune de toutes les altérations (A1) |
| **La source portée par la cible** — les statuts du héros seulement | La source est une propriété du poseur (A1) |
| **L'exemplaire comme source d'une carte** | Viderait la clause de D36 sur la carte même qu'il cite (A2) |
| **La conversion héritant de la source du gain** | Réunirait, sur une même carte, une Puissance durable et une Puissance d'un tour (A2) |
| **Un `if (id == 'might')` dans `addStatus`** | Un cas là où le mécanisme est général ; la portée s'écrit où les statuts se fabriquent (A1, §4.4) |
| **Une borne de `ratio` dans le descripteur de l'éditeur** | Un fait à deux endroits ; le chargement doit refuser de toute façon (A5) |
| **Un ratio en fraction de deux entiers** | D37 nomme un champ, `ratio` (A6) |
| **L'arrondi sur l'armure cumulée du tour** | `_convert` ne voit qu'un gain ; D37 raisonne montant par montant (A6) |
| **Les cartes d'armure réécrites en Puissance chez le Berserker** | Une fonctionnalité de rendu à part entière, dans quatre rendus (A7) — signalée pour la file |
| **Une ligne de Puissance sommée, ou nommée par sa source** | Sommée, elle cache deux durées ; nommée, elle fait lire le registre au panneau (A8) |
| **Une étape de migration de sauvegarde** | Rien à migrer : les statuts ne sont jamais écrits, les règles sont relues de la classe (§7) ; les sauvegardes ne se transfèrent pas avant la `1.0.0` |
