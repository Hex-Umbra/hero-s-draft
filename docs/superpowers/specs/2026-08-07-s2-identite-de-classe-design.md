# S2 — Identité de classe — Conception

Date : 2026-08-07 · **Révisée le 2026-09-16**
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — lots B à D et chantier frère P-49 non implémentés

> [!IMPORTANT]
> **Révision du 2026-09-16 — lire le §0 avant tout le reste.** La conception du 2026-08-07 a été
> re-vérifiée contre le code (`fc93efc`) par six passes indépendantes : trois chantiers l'avaient
> dépassée (P-48, P-40, P-30), et le rebase du 2026-09-05 n'avait corrigé que ses chemins. **Aucun
> arbitrage de conception n'est tombé** ; en revanche, le périmètre était sous-estimé d'environ
> moitié, une section aurait effacé les sauvegardes, et le propriétaire a pris les décisions du §0.1.
> La revue du plan du lot A, le même jour, a ajouté la décision D8 et la dépendance de P-49 au lot A.
> Toute référence `fichier:ligne` de ce document a été **re-mesurée le 2026-09-16**.
> La version antérieure reste lisible dans l'historique git.

Chantier ROADMAP : **P-41**, Tier B (`docs/ROADMAP.md` §4) — lot S2 du programme **P-40 → P-44**
Sources amont :
- `docs/analysis_reports/05082026_etat_des_lieux_heros_et_cartes_Opus5.md` (diagnostic du 05/08)
- `docs/analysis_reports/05082026_brainstorm_heros_et_cartes_Opus5.md` (brainstorm du 05/08)
- `docs/Idées améliorations classe et cartes.md` (idées du propriétaire du projet)

> **Ce document couvre un lot sur cinq du programme.** Le découpage du programme est porté par
> [`docs/ROADMAP.md` §4](../../ROADMAP.md) sous les identifiants **P-40 → P-44** ; S2 y est **P-41**.
>
> **S2 en est le lot racine**, au sens technique et non par ordre de préférence : ses décisions
> déterminent la composition des pools de S3. Une seule règle de stat suffit à le montrer. Si le
> Berserker **convertit** l'armure en Force, `iron_wall` et `defend_basic` restent dans son pool —
> elles y lisent simplement autrement. S'il la **bloque**, ces deux cartes doivent en être retirées,
> sous peine qu'il drafte des cartes qui ne font littéralement rien. On ne peut donc pas écrire les
> pools de S3 avant d'avoir tranché ici. La réciproque ne tient pas : les neuf passifs se conçoivent
> sans connaître la liste des cartes.
>
> **Et S2 se teste seul.** La règle R4 (§6.2) interdit à un passif de dépendre du pool : les neuf
> sont jouables avec le catalogue actuel de **23 cartes** (17 neutres, 2 par classe — re-compté le
> 2026-09-16), sans que S3 existe.

---

## 0. Révision du 2026-09-16

### 0.1. Décisions du propriétaire

| # | Sujet | Décision | Section |
|:---|:---|:---|:---|
| D1 | Sauvegardes existantes | **Écrire une vraie chaîne de migration**, la première du projet | §4.3 |
| D2 | Modèle des passifs | **Répertoire propre et partagé** : c'est le passif qui déclare les classes qui peuvent le prendre. Chantier frère **P-49** | §5 |
| D3 | Récompenses de niveau | **Les rendre data-driven** avant d'en ajouter | §8.1 |
| D4 | Découpage | **Lots distincts**, chacun avec son plan, sa branche et sa PR | §2 |
| D5 | Tutoriel et console de debug | **Un lot dédié** (lot D) pour leur mise à jour fonctionnelle | §9 |
| D6 | Méta-progression | **Pour plus tard** (P-13), mais **préparée ici** et documentée dans la ROADMAP | §10 |
| D7 | Maîtrise d'Armure | **À refondre en bonus de passif**, pour rester cohérente avec les neuf passifs : stat globale ou stat par passif, **à trancher au brainstorm de P-49**. Le lot A n'y touche pas | §5.4 |
| D8 | Sauvegardes et versions publiées | **Nouvelle clé `run_save`**, relue en repli sur `run_save_v1` ; une sauvegarde écrite par un build plus récent n'est **jamais effacée** | §4.3 |

### 0.2. Ce que la re-vérification a changé

| Constat | Effet sur la conception |
|:---|:---|
| Trois gains d'armure et de mana écrivent par `copyWith`, **hors** de `setHeroStats` ; le seul gain de puissance (récompense *Aiguisage*) n'était pas recensé | Le passage unique compte **13 sites**, non 10 (§4.1) |
| `effectiveAttaque` : **3** sites de résolution et **3** d'affichage, non 2 + 1 ; **5** constructions `attaque: 0`, non 2 | Le coût de la scission augmente (§4.2) |
| Le tutoriel (P-45, 2026-08-23) porte **sa propre copie** du calcul des dégâts et des gains d'armure | Les règles deviennent une **fonction pure**, partagée par le jeu et le tutoriel (§4.1) |
| La Maîtrise d'Armure d'une récompense de niveau est **calibrée pour ne s'appliquer qu'aux passifs** | Le passage unique étiquette la **source** du gain, et le lot A reste à comportement identique (§4.1) |
| Incrémenter `schemaVersion` aujourd'hui **efface** la sauvegarde | La migration est une infrastructure à construire, pas un incrément (§4.3) |
| Le ciblage vit sur la **carte** (`CardTarget`), pas sur l'effet | La règle d'`alterationPower` lit `card.data.target` (§4.2) |
| Les runes `burning`, `freezing`, `shocking` font déjà grandir une altération | L'argument de §4.2 est réécrit ; ces runes scalent avec `alterationPower` |
| `passiveSlots` et `activePassives` **n'existent pas** — l'ancienne §5.3 les décrivait au présent | Remplacés par le point d'accès unique de P-49 (§5) |
| `lifesteal` n'est ni appliqué, ni lu, ni fourni par aucune donnée | *Soif de Sang* est le passif **le plus cher** des neuf (§6.3) |
| Les récompenses de niveau sont du **code**, recopié à la main dans deux autres surfaces | « C'est du contenu, pas de l'architecture » était faux (§8.1) |
| L'éditeur de contenu (P-30) exige `baseDamage` et ne sait valider ni une table ni une liste de références | Ajustements mécaniques dans les lots, fonctionnels au lot D (§9) |
| **Déjà fait** : `PassiveData.fallback()` supprimé le 2026-09-04 (`5901185`) ; sites d'armure du système de compétences supprimés par P-40 | Retirés du périmètre |
| *Revue du plan du lot A* : toutes les versions web partagent le même stockage, et les builds publiés effacent toute version autre que 1 | La clé change une fois, et aucun build n'efface plus une sauvegarde plus récente (§4.3, D8) |
| *Revue du plan du lot A* : l'étape v2 → v3 de P-49 s'ajoute à la chaîne du lot A | P-49 dépend du lot A (§2) |
| *Revue du plan du lot A* : `RunState.effectiveAttaque` n'alimente qu'un champ jamais lu, `HeroCard.bonusAttack` | La chaîne morte est supprimée au lot A au lieu d'être renommée (§4.2) |

---

## 1. Vérification préalable

Re-mesurée le **2026-09-16** sur `fc93efc`.

| Constat | Vérification |
|:---|:---|
| `TraitSystem` est une chaîne `if/else` sur 3 `effectType` | `lib/game/systems/trait_system.dart` — gains d'armure aux lignes 21, 26, 41, 57 |
| `PassiveData` ne porte qu'un seul `value`, sans durée ni seuil | `lib/models/data/passive_data.dart:13` |
| `RelicTrigger` compte 9 valeurs | `lib/models/data/relic_data.dart:5` |
| `onAttackPlayed` / `onSkillPlayed` / `onPowerPlayed` sont dispatchés | `lib/game/controllers/combat_controller.dart:230-236` |
| Sur les 25 reliques, **`onSkillPlayed` et `onPowerPlayed` n'ont aucun consommateur** ; `onAttackPlayed` en a **deux** (`kunai`, `shuriken`) | `assets/data/relics/`, re-compté le 2026-09-16 |
| Les 12 effets `damage` du catalogue sont **tous** portés par des cartes de type `attack` | `assets/data/cards/` et `assets/data/classes/*/cards/`, re-compté le 2026-09-16 |
| `EntityStats` porte `critChance` ; `HeroData` ne l'expose pas | `lib/models/entity_stats.dart:17` · `lib/models/data/hero_data.dart` |
| `EntityStats.attaque` est **partagé avec les ennemis** | `lib/game/controllers/combat_controller.dart:154` · `lib/models/enemy_instance.dart:21-24` |
| Une version de sauvegarde inconnue **efface la sauvegarde** | `lib/services/save_service.dart:28` (`_schemaVersion = 1`), `:88` (`clear`) · figé par `test/unit/save_service_test.dart:142` |
| `addCardToHand` n'existe pas | 0 occurrence dans `lib/` et `test/` |
| `TraitSystem.onTurnEnd` est appelé **depuis un écran** | `lib/ui/screens/game_screen.dart:522` — contraire à `CLAUDE.md` |

### 1.1. L'armure est remise à zéro à chaque début de tour

`startTurn()` exécute `armure: 0` **avant tout le reste** (`lib/game/controllers/run_controller.dart:413`),
et `TraitSystem.onTurnStart` en dernier (`:427`). L'armure est donc une ressource **strictement
éphémère**, valable un tour.

C'est le constat le plus structurant : il invalide toute conversion de l'armure vers une stat
permanente (§7.2) et il fixe le point d'ancrage du passif *Bénédiction* (§6.3).

### 1.2. `lifesteal` est un statut orphelin trois fois

| Élément | État |
|:---|:---|
| Création du statut | ✅ `lib/game/controllers/run/player_stats_manager.dart:475`, façade `run_controller.dart:446` |
| Icône | ✅ `lib/game/components/entities/status_indicator.dart:155` |
| Panneau HUD | ✅ `status_effects_panel.dart:111-115` |
| Localisation bilingue | ✅ `app_fr.arb:211` · `app_en.arb:513` |
| **Un appelant de la création** | ⛔ **aucun** depuis P-40 — conservée délibérément pour P-41 (`ced306e`) |
| **Consommation dans le calcul de dégâts** | ⛔ **aucune occurrence dans `damage_pipeline.dart`** |
| **Une donnée qui le produit** | ⛔ **aucune** |

Le statut n'existe qu'en façade : il s'affiche et ne fait rien. *Soif de Sang* (§6.3) doit donc créer
sa source, son hook **et** son axe de croissance. P-41 **donne un appelant** à `applyLifestealBuff`,
ou la supprime : la laisser sans appelant, c'est du code mort.

### 1.3. `armorMastery` ne s'applique qu'aux passifs — et c'est calibré ainsi

`entity_stats.dart:11` documente le champ comme « Bonus permanent ajouté à **chaque** gain d'armure ».
Le code ne l'applique qu'aux quatre sites de `TraitSystem` :

| Source de gain d'armure | Site | `armorMastery` appliqué ? |
|:---|:---|:---:|
| Passifs | `trait_system.dart:21, 26, 41, 57` | ✅ |
| Cartes | `lib/game/services/effects/strategies.dart:92` | ❌ |
| Rune `hardened` | `lib/game/services/effect_resolver.dart:241` | ❌ |
| Relique `gain_armor` | `player_stats_manager.dart:211` | ❌ |
| Relique `charge_armor_turn` (Encensoir) | `player_stats_manager.dart:383` | ❌ |
| Statut `armor_regen` | `lib/game/controllers/combat/status_effect_processor.dart:39` | ❌ |
| Tutoriel | `lib/tutorial/tutorial_engine.dart:354` | ❌ |

**Ce n'est pas un bug latent : c'est le commentaire qui ment.** La Maîtrise d'Armure s'obtient en
cours de partie par la récompense *Forge d'Acier* (de +1 en commun à +7 en légendaire), dont le code
dit explicitement qu'elle a été calibrée pour ne s'appliquer qu'aux passifs
(`lib/game/services/level_up_reward_service.dart:166` : « elle s'ajoute à chaque gain d'armure
**du passif** […] elle compose plus fort que les autres récompenses, d'où une progression
distincte »).

L'appliquer à chaque gain serait donc une **modification d'équilibrage visible** — +7 d'armure sur
chaque `iron_wall` d'un joueur ayant tiré une Forge d'Acier légendaire.

**Décision D7 (2026-09-16) : ne pas la généraliser, la refondre.** Le problème n'est pas le périmètre
de la maîtrise mais son nom et sa forme : une stat qui ne sert qu'aux passifs, mais qui ne vaut que pour
l'armure, n'a plus de sens face à neuf passifs dont la plupart ne produisent pas d'armure. Elle devient
un **bonus de passif**. Sa forme exacte est une question ouverte de P-49 (§5.4).

### 1.4. Le tutoriel est une seconde implémentation du jeu

`lib/tutorial/` n'a pas le droit de lire un provider d'état (ADR-081) : il porte sa propre résolution
des effets. Tout mécanisme que P-41 ajoute au jeu doit donc **y être branché aussi**, ou le premier
combat que voit un joueur diverge silencieusement du jeu réel.

| Point de contact | Site |
|:---|:---|
| Calcul des dégâts | `tutorial_engine.dart:345` |
| Gain d'armure | `tutorial_engine.dart:354` |
| Constructions `attaque: 0` | `tutorial_engine.dart:29, 50, 60` |
| Déterminisme revendiqué (« `critChance: 0` ») | `tutorial_engine.dart:327` |
| Un passif par classe (`firstWhere` sans repli) | `lib/tutorial/tutorial_fixtures.dart:54` |

---

## 2. Découpage

| Lot | Contenu | Section |
|:---|:---|:---|
| **A** | Point de passage unique des gains, scission de `attaque` en trois puissances, chaîne de migration de sauvegarde sous une nouvelle clé | §4 |
| **P-49** | Passifs partagés : modèle, éligibilité par classe, point d'accès unique, cadre des triggers | §5 |
| **B** | `statRules`, les neuf passifs, stats de départ différenciées | §6, §7 |
| **C** | Partie 1 : récompenses de niveau data-driven. Partie 2 : nouvelles récompenses et écran de sélection | §8 |
| **D** | Mise à jour fonctionnelle du tutoriel et de la console de debug | §9 |

L'ordre des lots — qui dépend de quoi, ce qui est livré — est tenu dans
[`docs/ROADMAP.md` §4](../../ROADMAP.md), programme « Identité de classe & catalogue ». Cette section en
donne les **causes** :

- **A avant P-49.** P-49 retire `RunState.passiveTrait` par une étape de migration v2 → v3 (§5.1, P11),
  qui s'ajoute à la chaîne que pose A (§4.3). Livré avant A, P-49 trouverait un `SaveService` qui efface
  toute version autre que 1.
- **A avant B.** Les stats de départ de B donnent de l'`armorMastery` au Paladin : le passage unique doit
  exister avant, pour que la règle d'application de la maîtrise soit posée en un seul point. Et deux des
  neuf passifs de B (M1, M2) ont pour axe de croissance une puissance que crée A.
- **P-49 avant B.** Les neuf passifs ont besoin d'un modèle où vivre.
- **La partie 1 de C est indépendante** : elle peut avancer en parallèle de A.
- **D en dernier**, parce qu'il expose et enseigne les mécanismes livrés par tous les autres.

> [!IMPORTANT]
> **Invariant de découpage : chaque lot laisse `dart analyze` propre et la suite verte.** Un lot
> porte donc, dans le tutoriel et la console de debug, **les ajustements mécaniques sans lesquels le
> build casse** — un champ renommé, une clé obligatoire retirée. Le **lot D** porte tout ce qui est
> **fonctionnel** : exposer, éditer et enseigner les nouveaux mécanismes. Un lot qui laisserait le
> tutoriel incompilable « en attendant D » n'est pas livrable.

---

## 3. Ce que P-41 livre

1. **Un mécanisme de règles de stat par classe**, piloté en JSON, réutilisable pour toute classe et
   toute stat future (§7).
2. **La scission de `attaque` en trois puissances** — `attackPower`, `skillPower`, `alterationPower` —
   à comportement identique au jeu actuel (§4.2).
3. **Neuf passifs sélectionnables**, sur le modèle partagé de P-49 (§5, §6).
4. **Des stats de départ réellement différenciées**, et un écran de sélection qui cesse de mentir (§7.3, §8.3).
5. **Des récompenses de niveau data-driven**, conditionnées par la classe et par le passif actif (§8).
6. **La première chaîne de migration de sauvegarde** du projet (§4.3).
7. **Un tutoriel et une console de debug à jour** de tout ce qui précède (§9).

Et, en conséquence directe :

- Le trigger orphelin `onSkillPlayed` trouve son premier consommateur (M1). `onPowerPlayed` reste
  sans consommateur : le refermer relève des reliques, pas des passifs.
- Le statut `vulnerable` trouve sa première source (M2) — aujourd'hui, aucun fichier de
  `assets/data/` ne l'applique.
- `lifesteal` cesse d'être décoratif (B2).
- La méta-progression (P-13) trouve ses points d'accroche posés (§10).

---

## 4. Lot A — Passage unique des gains, scission des puissances, migration

**Ce lot ne change pas le comportement du jeu.** Tout ce qu'il construit est vérifiable par la suite
existante, qui doit rester verte sans qu'une seule de ses attentes soit modifiée — hormis celles qui
nomment `attaque` et le test de §4.3.

### 4.1. Le point de passage unique des gains

> [!NOTE]
> **Le principe, en clair.** Aujourd'hui, chaque endroit du code qui donne de l'armure au héros fait
> lui-même l'addition — « armure actuelle + 10 » pour `iron_wall`, « armure actuelle + 3 » pour une
> relique — puis écrit le résultat. Une règle comme « le Berserker ne garde pas son armure, elle devient
> de la Force » ne peut s'appliquer qu'**au moment du gain**, avant l'écriture. Il faudrait donc la
> recopier à chacun de ces endroits, et en oublier un suffit pour que la règle ne s'applique pas —
> c'est exactement ce qui est arrivé à la Maîtrise d'Armure (§1.3).
>
> Le **point de passage unique** inverse cela : aucun endroit ne fait plus l'addition lui-même. Tous
> appellent une seule fonction — « donne 10 d'armure, venant d'une carte » —, et c'est elle, et elle
> seule, qui connaît les règles de la classe avant d'écrire. Une règle ajoutée là s'applique partout,
> d'office, y compris dans le tutoriel.

`setHeroStats()` est un **setter de valeur absolue** — son propre commentaire le dit
(`run_controller.dart:345` : « Modifie la valeur exacte d'un champ »). Ses appelants calculent eux-mêmes
le total (`stats.armure + X`) avant d'appeler. La méthode ne voit donc jamais un gain, seulement un
résultat : **rien ne peut y être intercepté.**

Le recensement du 2026-08-07 cherchait les appels à `setHeroStats`, pas les **gains**. Il en manquait
trois, qui écrivent par `copyWith` et échapperaient à un point de passage posé sur la seule méthode :

| Ressource | Site | Source | Passe par `setHeroStats` ? |
|:---|:---|:---|:---:|
| Armure | `strategies.dart:92` | Carte | ✅ |
| Armure | `effect_resolver.dart:241` | Rune `hardened` | ✅ |
| Armure | `trait_system.dart:21, 26, 41, 57` | Passifs | ✅ |
| Armure | `player_stats_manager.dart:383` | Relique `charge_armor_turn` | ✅ |
| Armure | `player_stats_manager.dart:211` | Relique `gain_armor` | ❌ `copyWith` |
| Armure | `status_effect_processor.dart:39` | Statut `armor_regen` | ❌ `copyWith` |
| Mana | `strategies.dart:108` | Carte | ✅ |
| Mana | `effect_resolver.dart:170` | Rune | ✅ |
| Mana | `player_stats_manager.dart:201` | Relique `gain_mana` | ❌ `copyWith` |
| Puissance | `player_stats_manager.dart:49` | `applyHeroStatModifier` : récompense *Aiguisage* (`draft_screen.dart:643`), reliques `whetstone` et `cursed_blade` en début de run (`:218`) et leur retrait, en gain négatif (`:407`), événements `blessed_fountain` et `mysterious_altar` (`event_controller.dart:77`) | ❌ `copyWith` |

Soit **9 gains d'armure, 3 de mana et 1 de puissance**, auxquels s'ajoute le tutoriel (§1.4).

**Le gain de puissance n'avait été recensé nulle part**, ni le 2026-08-07 ni par la re-vérification.
C'est pourtant le seul du jeu : sans lui dans le passage unique, les règles de `statRules` qui visent une
puissance — celle du Mage, `attackPower → alterationPower` — ne s'appliqueraient à rien. Et il ne sert
pas qu'à la récompense de niveau : deux reliques, leur retrait et deux événements l'empruntent aussi
(tableau ci-dessus), donc la même règle (§7.1).

Hors du périmètre du passage unique, et volontairement : les autres montées permanentes portées par
`applyHeroStatModifier` (`player_stats_manager.dart:45-53` — `maxPv`, `maxMana` et le mana courant qui
le suit, `armorMastery`, `luck`, `critChance`, `critMultiplier`). Aucune règle de stat ne les vise.

**Les règles sont une fonction pure.** Le tutoriel ne peut pas appeler `RunController` (ADR-081).
Plutôt que de recopier les règles dans le tutoriel — exactement la recopie qui avait produit les 50
écarts de P-45 —, l'application d'un gain est une **fonction pure** sur `EntityStats`, sans provider,
appelée par les deux :

```dart
// Forme indicative — le lot A livre `StatGains.apply(stats, gain)`, le lot B y ajoute `rules`.
EntityStats applyGain(EntityStats stats, StatGain gain, List<StatRule> rules);
```

**Au lot B, les règles sont un paramètre obligatoire.** Chaque site d'appel décide explicitement : les
règles de la classe pour le héros, une liste vide pour un ennemi, et le compilateur désigne tous les sites
à mettre à jour. `StatusEffectProcessor.processPlayerStatuses`, qui ne reçoit que des stats, doit recevoir
les règles de son appelant, `RunController.startTurn`. Une liste vide par défaut laisserait `metallicize`
(`armor_regen` sur soi) donner de l'armure au Berserker sans passer par sa conversion.

**Le gain porte sa source.** `StatGain` étiquette sa provenance — `passive`, `card`, `rune`, `relic`,
`status`, `progression` (tout ce qui passe par `applyHeroStatModifier`) et `enemyIntent` (l'intention
« défense » d'un ennemi). C'est ce qui permet au lot A de rester à comportement identique : la maîtrise d'armure
s'applique **aux gains de source `passive` seulement**, comme aujourd'hui, et le commentaire de
`entity_stats.dart:11` est corrigé pour dire ce que fait le code. L'étiquette de source est aussi
exactement ce dont aura besoin le futur **bonus de passif** (§5.4) : il ne s'appliquera qu'aux gains de
source `passive`, quelle que soit la ressource gagnée.

**Livrable :**

- la fonction pure et son type de gain étiqueté ;
- `grant(StatGain)` sur `RunController`, qui y délègue ;
- la conversion des **13 sites**, du site de gain d'armure du tutoriel et des deux gains d'armure
  d'ennemi (statut `armor_regen`, intention « défense »), pour que la règle ne souffre aucune exception ;
- `setHeroStats()` **supprimé** : ses neuf appelants sont tous des gains, et les remises à zéro passent
  déjà par `copyWith`.

**Critère d'acceptation :** hors remises à zéro, restaurations et constructions, aucune ligne de
`lib/` n'écrit `armure:` ou `currentMana:` par addition en dehors de la fonction pure — à l'exception,
voulue, de la remontée du mana courant qui suit une hausse de `maxMana` (ci-dessus).

### 4.2. La scission des stats de puissance

#### Pourquoi maintenant, et seulement maintenant

Les 12 effets `damage` du catalogue sont **tous** portés par des cartes de type `attack` (§1), et aucune
des 9 cartes `skill` n'inflige de dégâts. Scinder `attaque` ne change donc **rien au comportement du
jeu actuel** : c'est un refactor à résultat identique.

Le split ne devient un levier qu'au moment où S3 écrira les premières cartes `skill` offensives. Fait
après S3, il obligerait à ré-équilibrer une trentaine de cartes. **C'est la fenêtre.**

#### Les trois stats et leur règle d'attribution

| Stat | S'applique à |
|:---|:---|
| `attackPower` | Effet `damage` porté par une carte de type `attack` |
| `skillPower` | Effet `damage` porté par une carte de type `skill` |
| `alterationPower` | Effet `apply_status` porté par une carte dont la cible est un ennemi (`singleEnemy`, `allEnemies`) — **et** les runes d'altération (voir plus bas) |
| *(aucune)* | Cartes de type `power` et `status` : aucun effet `damage` n'y existe aujourd'hui. La règle est **totale** : un tel effet n'est scalé par aucune puissance, par construction |

**Le ciblage se lit sur la carte, pas sur l'effet.** `CardEffect` ne porte que `type`, `value`,
`statusId` et `duration` (`lib/models/data/card_data.dart:49`) ; la cible est une propriété de la carte
(`CardTarget`, `card_data.dart:47`). `ApplyStatusEffectStrategy` branche déjà ainsi. Limite assumée :
une carte qui appliquerait à la fois un statut à l'ennemi et un buff à soi verrait les deux scalés par
`alterationPower`. Aucune carte du catalogue n'est dans ce cas.

**Garde-fou sur `alterationPower`.** Sans la restriction « cible ennemie », la Force ciblée soi
scalerait avec `alterationPower`, la Force nourrirait les dégâts, et l'altération se bouclerait sur
elle-même. La ligne de partage tombe exactement sur le catalogue : sur **7 effets `apply_status`**,
quatre visent l'ennemi (`fireball` → `burn`, `ice_bolt` → `freeze`, `poison_stab` → `poison`,
`thunder_clap` → `shock`) et trois visent soi (`demon_form` et `rage_form` → `strength`,
`metallicize` → `armor_regen`). **`rage_form` est la seule carte `skill` du catalogue à appliquer un
statut** : c'est le cas à tester pour vérifier que `skillPower` et `alterationPower` ne se marchent pas
dessus.

**`strength` alimente `attackPower`.** La Force s'ajoute aux dégâts de toute carte `attack`
(`entity_stats.dart`, `effectiveAttaque`).

> [!WARNING]
> **Question ouverte, à trancher au lot B.** La conception du 2026-08-07 en tirait une « conséquence
> utile » : un Mage qui convertit `attackPower` ne tirerait plus rien de `demon_form`. **Ce n'est pas
> vrai en l'état** : la règle de conversion agit sur les **gains** de la stat `attackPower`, pas sur la
> Force, qui est un statut. Le Mage joue des cartes `attack` (`magic_missile`) et y garderait tout le
> bonus de Force. Deux lectures possibles :
> - la conversion porte aussi sur la Force appliquée au Mage, qui devient alors de l'`alterationPower`
>   temporaire — `demon_form` devient bien une carte Berserker/Paladin ;
> - la conversion ne porte que sur la stat permanente, et `demon_form` reste utile au Mage sur ses
>   rares cartes `attack`.
>
> La première tient la promesse d'origine mais étend `statRules` aux statuts. La seconde est plus
> simple mais perd le tri automatique des pools pour S3.

**Les runes d'altération scalent aussi.** Les runes de forge `burning`, `freezing` et `shocking` ajoutent
valeur et durée à `burn`, `freeze` et `shock`. Elles sont résolues **en ligne**, dans
`effect_resolver.dart:174`, hors du registre de stratégies : une implémentation posée dans la seule
`ApplyStatusEffectStrategy` ne les atteindrait pas. On obtiendrait alors un poison de carte qui scale
et une brûlure de rune qui ne scale pas — sur l'archétype même que la stat doit servir. Les deux chemins
appliquent donc `alterationPower`.

#### Le trou que ça comble

Une altération ne grandit aujourd'hui que de deux façons : le multiplicateur de rareté
(`effect_resolver.dart:217`) et les trois runes d'altération. **Les deux sont liées à la carte, aucune à
la run** : aucune relique, aucune récompense de niveau ne fait monter un poison ou une brûlure — et les
runes sont réservées aux cartes `attack` (`effect_resolver.dart:174`). La classe annoncée « Orientée
Altération » est la seule sans courbe de progression propre au héros. `alterationPower` la lui donne.

#### Où vit la scission

`EntityStats` est partagé avec les ennemis (§1). `attaque` y devient `attackPower` — l'ennemi lit
toujours sa puissance d'attaque, sous un autre nom —, et `skillPower`, `alterationPower` s'y ajoutent,
à 0 par défaut. Aucun ennemi ne les renseigne.

La **règle d'attribution** — quelle puissance renforce quel effet — ne vit pas sur `EntityStats` : c'est
une règle de héros, qui ferait dépendre le modèle partagé de `card_data.dart`, donc du registre de
données. Elle est une fonction pure du lot A, rangée à côté du passage unique, et la résolution d'une
carte, ses runes, le tutoriel et l'aperçu des dégâts lisent la même.

#### Inventaire des sites

| Nature | Sites |
|:---|:---|
| Résolution des dégâts | `strategies.dart:32`, `:44` · `tutorial_engine.dart:345` |
| Affichage de dégâts prévus sur une carte | `lib/game/components/card_component.dart:343` · `lib/game/components/widgets/card_text_renderer.dart:94`, `:356` |
| Getter `RunState.effectiveAttaque` (`run_controller.dart:43`) | **Code mort, supprimé par le lot A** : son seul consommateur, `lib/game/systems/state_sync_system.dart:39`, alimente `HeroCard.bonusAttack`, un champ transmis mais jamais lu |
| Affichage de la stat brute | `lib/ui/widgets/map/dialogs/stats_dialog.dart:170` · `lib/ui/widgets/map/hero_mini_stats_panel.dart:100` |
| Affichage de l'attaque effective en combat | `lib/ui/screens/game_screen.dart:500` → `CombatBottomHud` → `lib/ui/widgets/hud/player_health_bar.dart:131` |
| Entrée d'équilibrage : budget de rencontre | `lib/ui/screens/game_screen.dart:260` → `lib/game/systems/encounter_system.dart:98` |
| Montée permanente de la stat (récompense, reliques, événements — §4.1) | `player_stats_manager.dart:49` — passe par le passage unique |
| Constructions `attaque: 0` côté héros | `run_controller.dart:221` (`build()`), `:254` (`startNewRun()`) · `tutorial_engine.dart:29`, `:50`, `:60` |
| Côté ennemi | `combat_controller.dart:154` · `enemy_instance.dart:21-24` · affichage `lib/game/components/entities/enemy_card.dart:128`, `:197`, `:208`, `:212` · ennemis du tutoriel `tutorial_engine.dart:274`, `lib/tutorial/widgets/tutorial_enemy_intents_widget.dart:85` |
| Console de debug *(renommage mécanique ; trois réglages au lot D)* | `lib/ui/widgets/debug/tabs/debug_hero_tab.dart:40-43` |

Les **cinq** constructions doivent être traitées ensemble, sous peine qu'une partie neuve, une partie
rechargée et le tutoriel n'aient pas la même forme de statistiques.

### 4.3. La chaîne de migration de sauvegarde

**Constat.** `SaveService` sérialise un blob unique sous `run_save_v1`, avec `_schemaVersion = 1`
(`save_service.dart:28`). `load` n'a **aucune lecture par version** : une version différente lève, tombe
dans le `catch` et **efface la sauvegarde** (`:88`), comportement figé par
`save_service_test.dart:142`. Incrémenter la version, comme le prescrivait la conception du 2026-08-07,
aurait donc supprimé toutes les parties en cours.

**Les builds déjà publiés ne se corrigent plus.** Toutes les versions web sont servies depuis la même
origine, un dossier `/v<version>/` par build (`site/nginx.reference.conf:18`, `:30`), et restent en ligne
(`site/versions.html:25`) : elles partagent le même stockage, donc la même clé. Les cinq builds publiés,
de `v0.4.7` à `v0.5.1`, effacent tous une sauvegarde de version autre que 1. Écrire une v2 sous
`run_save_v1` ferait donc effacer la partie en cours dès que le joueur rouvre une ancienne version depuis
la page des versions et clique « Continuer » — et ce code-là ne peut plus être modifié. Les builds Windows
partagent probablement, eux aussi, un même fichier de préférences (non vérifié).

**Précédent.** P-40 (retrait de la clé `skills`) et P-48 (renommage des ids de passifs) ont changé le
contenu du blob **sans incrémenter** : une clé retirée était ignorée, une référence morte signalée par
`MissingSaveItem`. Cette tolérance a fonctionné tant que les changements étaient des suppressions.

**Décision D1 : une vraie chaîne de migration.**

- Une suite d'étapes `vN → vN+1`, chacune **fonction pure** sur le JSON décodé, testable isolément, et
  **indexée par la version qu'elle quitte**.
- La version courante est **déclarée**, jamais déduite du nombre d'étapes, et un test vérifie qu'une
  étape existe pour chaque version antérieure. Une étape supprimée, ou deux branches qui ajoutent chacune
  la leur, échouent au test ou à la fusion au lieu de renuméroter la chaîne en silence.
- `load` applique, dans l'ordre, les étapes qui séparent la version lue de la version courante.
- **Seule une donnée illisible reste traitée comme corrompue**, et effacée : JSON invalide, version
  absente, non entière ou inférieure à 1.

**Décision D8 : la clé change une fois, et aucun build n'efface une sauvegarde plus récente.**

- Le jeu écrit désormais sous **`run_save`**, que les builds publiés ignorent. La version vit dans le
  blob : la clé ne changera plus.
- `load` lit `run_save`, et à défaut l'ancienne clé `run_save_v1`, migrée depuis v1. `save` écrit
  `run_save` puis retire `run_save_v1` : jusqu'à la première sauvegarde du nouveau build, la partie reste
  lisible par les anciens ; ensuite elle n'y est plus proposée, au lieu d'y être effacée. `clear` retire
  les deux clés, `hasSave` regarde les deux.
- Une version **supérieure** à la version courante — une sauvegarde écrite par un build plus récent —
  est **refusée sans être effacée**, et l'écran d'accueil dit pourquoi elle ne s'ouvre pas. Sans cela,
  chaque build deviendrait à son tour l'ancien build qui efface les parties des suivants.
- `save_service_test.dart:142` est réécrit en conséquence : une version future est refusée et conservée ;
  une version antérieure migre.

**Étape v1 → v2 (lot A)** :

| Champ ancien | Champ nouveau | Règle |
|:---|:---|:---|
| `run.heroStats.attaque` | `attackPower` | Report à l'identique |
| — | `skillPower`, `alterationPower` | Absents du blob v1 : lus à 0 par `EntityStats.fromJson`, comme `luck` ou `critChance` avant eux |

Aucun ennemi n'est sérialisé : `SaveService` n'est jamais appelé en combat.

**Étapes suivantes :** P-49 ajoute l'étape v2 → v3 (§5) — **P-49 dépend donc du lot A** (§2). P-13
**n'étend pas ce blob** : la méta-progression aura son propre stockage, sous sa propre clé (§10).

---

## 5. Chantier frère P-49 — Passifs partagés

> **P-49 a sa propre spec, à écrire.** Cette section ne le conçoit pas en entier : elle fixe la
> **frontière** avec P-41 et consigne les décisions déjà prises le 2026-09-16, pour qu'elles ne se
> perdent pas d'ici là.

**Pourquoi un chantier à part.** L'ancienne §5.3 faisait tenir le modèle des passifs dans P-41, sur un
seam `passiveSlots` qui n'existait pas. Le propriétaire a élargi l'ambition : des passifs **partagés
entre classes**, préparant une méta-progression où des passifs se **débloquent par personnage**. C'est
un modèle de donnée à part entière, pas un détail de P-41.

### 5.1. Décisions prises

| # | Décision | Motif |
|:---|:---|:---|
| P1 | Les passifs restent **à plat** sous `assets/data/passives/`, comme `relics/` et `events/` | Le répertoire existe déjà : P-48 l'a laissé à plat (ADR-086, D4). Un passif partagé n'appartient à aucune classe, donc à aucun dossier de classe |
| P2 | **C'est le passif qui déclare les classes qui peuvent le prendre** : `"classes": ["mage", "paladin"]`. Sans ce champ, le passif est ouvert à toutes les classes | Ajouter un passif partagé = **créer un seul fichier**, sans toucher aux classes. C'est aussi la forme qu'appelle un déblocage par personnage |
| P3 | `HeroData.passiveTrait` disparaît de `class.json` | Le lien s'inverse (P2) |
| P4 | **Un point d'accès unique** : les passifs disponibles pour une classe = éligibles **et** débloqués. Tant que P-13 n'existe pas, « débloqué » vaut « tous » | P-13 branchera son stockage derrière ce point, **sans toucher au reste** |
| P5 | **Tout lecteur passe par ce point d'accès** : écran de sélection, tutoriel, éligibilité des récompenses de passif | Un lecteur qui lirait `classes` directement contournerait le déblocage le jour où P-13 arrive |
| P6 | **Un seul passif actif par run** : `RunState.activePassive` reste singulier | Voir §11. Plusieurs emplacements relèvent de P-13 |
| P7 | `PassiveData` s'élargit — durée, seuil, ratio, stat cible — et `TraitSystem` devient une Strategy par `effectType`, sur le modèle d'ADR-061 | Neuf passifs ajouteraient neuf branches à la chaîne `if/else` |
| P8 | Les triggers manquants sont posés ici : `onDamageTaken`, et une facilité de comptage par tour et par combat | Voir §6.4 |
| P9 | `onDamageTaken` est ajouté à `RelicTrigger` **et dispatché pour les reliques aussi**, partout où le héros perd des PV : attaque ennemie (`lib/game/controllers/combat/turn_phase_manager.dart:114`), poison, appliqué directement par `EntityStats.takeDamage` (`status_effect_processor.dart:24`, depuis `RunController.startTurn`), dégâts d'événement (`event_controller.dart:68`, hors combat). La spec de P-49 choisit un point qui couvre les trois, ou écarte explicitement ceux qu'elle exclut | L'éditeur de contenu lit cet enum : un trigger ajouté sans dispatch serait proposé aux reliques et ne ferait rien. Posé sur la seule attaque ennemie, il laisserait *Ferveur* muette sur le poison |
| P10 | L'appel `TraitSystem.onTurnEnd` quitte `game_screen.dart:522` pour un controller | `CLAUDE.md` interdit la logique de jeu dans un écran, et la refonte touche cet appel |
| P11 | Étape de migration **v2 → v3** pour `RunState.passiveTrait` | Le champ disparaît du modèle (P3). L'étape s'ajoute à la chaîne du lot A, d'où la dépendance de P-49 à A (§2) |
| P12 | Un ADR **remplace la décision D4 d'ADR-086** à la livraison | D4 renvoyait explicitement à P-41 |

### 5.2. Ce qu'on perd, et ce qui le compense

Pour une carte de classe, **le dossier impose l'appartenance** : le chargeur refuse une carte mal rangée.
Un passif partagé ne peut pas offrir cette garantie — `"classes": ["paladn"]` se charge sans erreur.

Deux filets la remplacent :

- **`test/unit/referential_integrity_test.dart`**, qui vérifie déjà que `passiveTrait` désigne un passif
  existant (`:35-43`), vérifie désormais que chaque id de `classes` désigne une classe existante. Il
  couvre **tout** passif, y compris écrit à la main.
- **L'éditeur de contenu**, qui refusera une classe inconnue à la saisie (§9.2). Cette garantie ne vaut
  que pour un passif **créé ou modifié par l'éditeur** : aujourd'hui, le validateur sait vérifier une
  référence unique ou une liste de valeurs fixes, pas une liste de références.

### 5.3. Hors de P-49

Le stockage des déblocages, la sauvegarde de profil, les conditions et coûts de déblocage, l'interface de
déblocage, et plusieurs passifs actifs : **tout cela est P-13** (§10).

### 5.4. Question ouverte — la Maîtrise d'Armure devient un bonus de passif (D7)

**Aujourd'hui.** `armorMastery` — de +1 à +7 par la récompense *Forge d'Acier* — s'ajoute aux gains
d'armure **des passifs seulement** (§1.3). Face à neuf passifs dont six ne produisent pas d'armure, elle
ne servirait qu'à trois d'entre eux (P1, P3, M3), et son nom ne dit plus ce qu'elle fait.

**Décision du propriétaire (2026-09-16).** La refondre en **bonus de passif**, qui augmente ce que
produit le passif actif. « Bonus Passifs » est un nom de travail. Deux formes, **à trancher au
brainstorm de P-49** :

| | Stat globale | Stat par passif |
|:---|:---|:---|
| **Principe** | Une seule stat augmente l'effet de tout passif | Chaque passif progresse sur son propre chiffre |
| **Récompense** | Une seule, héritière de *Forge d'Acier*, valable pour toutes les classes | Neuf, une par passif — **c'est déjà ce que prévoit §8.2** |
| **Pour** | Simple, lisible, survit à un changement de passif | Chaque passif grandit sur ce qui le définit : seuil, ratio, durée |
| **Contre** | Un « +N » doit avoir un sens pour neuf effets de nature différente : armure, Force, mana, vol de vie, durée de `vulnerable` | Recoupe presque entièrement §8.2 : la question devient « la Maîtrise d'Armure disparaît-elle au profit des récompenses de passif ? » |

**Ce que la réponse touchera, quelle qu'elle soit :**

- **R1** (§6.2) : P1, P3 et M3 ont aujourd'hui `armorMastery` pour axe de croissance ;
- les **stats de départ** (§7.3) : le Paladin démarre avec de la maîtrise ;
- la récompense *Forge d'Acier* et le test de valeurs des récompenses (§8.1) ;
- la **sauvegarde** : `armorMastery` est sérialisé avec les stats du héros, donc renommer ou retirer le
  champ demande une étape de migration (§4.3) ;
- la relique **`kunai`**, dont l'effet `charge_armor_mastery_combat` pose un statut `armor_mastery` que
  lit `effectiveArmorMastery` (`player_stats_manager.dart:269-289`, `entity_stats.dart:156-164`) ;
- la **prose du tutoriel**, qui enseigne la *Forge d'Acier* comme de la Maîtrise « ajoutée à l'Armure
  que produit votre passif » (`lib/tutorial/tutorial_data.dart:317-318`, `:327-329`).

**Le lot A n'y touche pas.** Il garde la maîtrise telle qu'aujourd'hui, et son étiquette de source
`passive` est précisément ce dont les deux formes auront besoin.

---

## 6. Lot B — Les neuf passifs

### 6.1. Ce que ce lot écrit

Les neuf passifs sont du **contenu** sur le modèle de P-49 : neuf fichiers sous `assets/data/passives/`
et neuf stratégies. Les trois passifs existants (`regen_armor`, `berserker_armor`, `spell_armor`) sont
repris ou remplacés comme indiqué §6.3.

### 6.2. Le cadre des passifs

Cinq règles, pour que les neuf passifs ne soient pas neuf cas particuliers.

| | Règle |
|:---|:---|
| **R1** | Un passif = un trigger + **un axe de croissance nommé**. La récompense associée n'est pas inventée, elle est déduite de cet axe. |
| **R2** | Les trois passifs d'une classe pointent vers **trois façons de jouer**, pas vers trois puissances. Sinon le joueur ne choisit pas, il prend le meilleur. |
| **R3** | Aucun passif ne produit une ressource que `statRules` interdit à sa classe. |
| **R4** | Aucun passif ne se déclenche sur **moins de 40 % du pool jouable**. |
| **R5** | Une conversion ne transforme jamais une ressource éphémère en ressource permanente (§7.2). |

**R4 formalise un défaut existant.** `spell_armor` est conditionné aux cartes `skill` : 6 des 17 cartes
neutres, et 9 des 23 du pool complet (39 %) — re-compté le 2026-09-16. Un passif Paladin adossé aux
soins serait pire : le jeu ne compte que **2 cartes de soin** (`heal_potion`, `holy_shield`). D'où le
principe corollaire :

> **Un passif ne doit pas amplifier le pool. Il doit produire lui-même son déclencheur.**

C'est ce qui sauve *Bénédiction* (§6.3) : au lieu d'« amplifier les soins », il convertit l'armure
survivante en PV. Zéro carte de soin requise.

**R3 et le partage des passifs.** Avec P-49, un passif peut être éligible à plusieurs classes. R3 se
vérifie alors **pour chaque classe déclarée** : un passif qui produit de l'armure ne peut pas déclarer
une classe qui la bloque.

### 6.3. Les neuf passifs

Aucune valeur chiffrée : elles relèvent de l'équilibrage, pas de la conception. **La colonne
« Croissance » de P1, P3 et M3 (`armorMastery`) dépend de la question ouverte §5.4.** Les neuf sont conçus
**un par classe** (`"classes"` à un élément) ; leur partage éventuel est une décision de contenu
ultérieure, que le modèle de P-49 rend possible sans changement de code.

#### Paladin — aucune règle de stat · `armorMastery` de départ > 0

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| P1 | **Régénération d'Armure** *(existant, `regen_armor`)* | `endOfTurn` | Gain d'armure | `armorMastery` |
| P2 | **Ferveur** | `onDamageTaken` | L'armure qui absorbe des dégâts octroie de la Force, à durée courte | `attackPower` |
| P3 | **Bénédiction** | `startOfTurn`, **avant le reset de §1.1** | L'armure survivante devient des PV | `armorMastery` |

Seule classe à conserver l'accès aux trois puissances : c'est son identité de généraliste, et le repère
du joueur qui découvre.

*Ferveur* referme une boucle propre : chez le Paladin, **encaisser devient une ressource offensive**. Il
tape parce qu'il tient, là où le Berserker tape parce qu'il meurt — les deux classes lisent le même
verbe à l'envers l'une de l'autre.

*Bénédiction* s'insère impérativement **avant** `armure: 0` dans `startTurn()` (`run_controller.dart:413`),
sinon il n'a rien à convertir. C'est le seul passif du jeu dont l'ordre d'exécution est contraignant ;
il doit être couvert par un test dédié.

#### Berserker — `armure → strength(1)` · `skillPower: block` · `critChance` de départ > 0

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| B1 | **Rage** | `startOfTurn` | Force proportionnelle aux PV manquants | `attackPower` |
| B2 | **Soif de Sang** | `onAttackPlayed` | Vol de vie, croissant à mesure que les PV baissent | `critChance` |
| B3 | **Frénésie** | `onEnemyKilled` | Force et pioche à chaque ennemi abattu | `attackPower` |

*Rage* est la formule de `berserker_armor` redirigée vers la Force. Elle corrige au passage le défaut
relevé au diagnostic (§I.3.2) : le passif ne sera plus muet à pleine vie, un plancher étant possible.

**_Soif de Sang_ est le passif le plus cher des neuf** — l'inverse de ce que laissait croire la conception
du 2026-08-07. `lifesteal` est orphelin trois fois (§1.2) : B2 doit créer la **source** du statut, le
**hook** de soin après résolution des dégâts, et brancher son axe de croissance. `DamageEffectStrategy`
dispose déjà des stats du héros ; le hook s'y pose.

**Le blocage de `skillPower` se paie en axes de croissance.** Le Berserker n'a que `attackPower` et
`critChance` ; ses trois passifs se distinguent par le *pattern* — attrition, soutien, boule de neige — et
non par la stat. Conforme à R2, mais c'est le coût réel du blocage, nommé ici plutôt que découvert au
playtest.

Le blocage est **souple** : les cartes `skill` restent jouables et leurs effets non offensifs (pioche,
mana, armure convertie) fonctionnent normalement. Seul leur scaling de dégâts est nul.

#### Mage — `attackPower → alterationPower`

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| M1 | **Flux de Mana** | `onSkillPlayed`, compteur | Mana supplémentaire pour le tour | `skillPower` |
| M2 | **Marque du Mage** | 1ʳᵉ attaque du tour | La cible devient `vulnerable` | `alterationPower` |
| M3 | **Canalisation** | `endOfTurn` | Le mana non dépensé devient de l'armure | `armorMastery` |

**M1 et M3 sont activement opposés** : l'un récompense de vider sa main, l'autre de garder du mana. Le même
deck ne peut pas viser les deux. C'est ce qui fait du choix de passif une vraie décision.

**M2 est celui qui compte.** Seul passif qui rende la promesse « Orienté Altération » de la classe, il donne
à `vulnerable` sa première source — le statut est pleinement consommé (`damage_pipeline.dart:46`) mais
aucun fichier de `assets/data/` ne l'applique —, et il ne dépend d'aucune carte : R4 est satisfait dès
aujourd'hui, avant S3.

Le passif `spell_armor` actuel disparaît. Sa fonction — survivre à 60 PV — est reprise par M3, mais en la
faisant **payer** : le Mage ne se protège que s'il accepte de jouer moins.

### 6.4. Triggers

| Trigger | État au 2026-09-16 | Consommé par |
|:---|:---|:---|
| `startOfTurn` | ✅ vivant | P3, B1 |
| `endOfTurn` | ✅ vivant | P1, M3 |
| `onAttackPlayed` | ✅ vivant — `kunai`, `shuriken` | B2, M2 |
| `onSkillPlayed` | ✅ dispatché, **aucune relique** | M1 |
| `onPowerPlayed` | ✅ dispatché, **aucune relique** | *(aucun passif)* |
| `onEnemyKilled` | ✅ vivant — 2 reliques | B3 |
| `onDamageTaken` | ❌ **posé par P-49** (§5.1, P9) | P2 |
| Comptage par tour et par combat | ❌ **posé par P-49** (§5.1, P8) | M1 (« N compétences »), M2 (« 1ʳᵉ attaque du tour ») |

`onCardPlayed` perd son seul consommateur côté passif avec la disparition de `spell_armor` — deux reliques
l'utilisent encore (`mage_amulet`, `pen_nib`).

---

## 7. Lot B — `statRules` et stats de départ

### 7.1. La forme de la donnée

Une **liste de règles** dans `assets/data/classes/<id>/class.json`. Le blocage dur et la conversion sont
**deux valeurs de la même donnée**, décidées classe par classe :

```jsonc
// Berserker
"statRules": [
  { "stat": "armure",     "mode": "convert", "to": "status:strength", "duration": 1 },
  { "stat": "skillPower", "mode": "block" }
]

// Mage
"statRules": [
  { "stat": "attackPower", "mode": "convert", "to": "alterationPower", "ratio": 1.0 }
]

// Paladin — aucune règle
```

Modes retenus : `block` (le gain est annulé) et `convert` (le gain est redirigé). Le modèle est extensible —
`cap`, `decay` — sans changement de forme.

**Une liste, et non la table de la conception du 2026-08-07.** Le langage de chemins de l'éditeur de
contenu (`lib/services/content_editor/field_path.dart`) sait désigner un élément de liste
(`statRules[].mode`), pas une clé arbitraire d'une table. Sous forme de table, `statRules` ne pourrait pas
être validé par l'éditeur sans étendre ce langage.

**Compatible avec l'autorité du répertoire (ADR-086).** La source des classes n'injecte que `id`
(`lib/services/game_data_service.dart:116`) : `statRules` n'est imposé par aucun répertoire, l'écrire dans
le fichier est légal.

**`HeroData` doit le lire.** Sans champ ni lecture dans `HeroData.fromJson`, la clé serait chargée et jetée
en silence — le mode d'échec le plus coûteux à diagnostiquer.

**Les règles s'appliquent dans la fonction pure du lot A** (§4.1). C'est ce qui les rend applicables au
tutoriel sans recopie.

**Toutes les sources passent par la règle.** Le seul site de gain de puissance ne sert pas qu'à la
récompense de niveau : les reliques `whetstone` et `cursed_blade`, leur retrait et deux événements
l'empruntent aussi (§4.1). La conversion du Mage s'y appliquera donc d'office. Reste à trancher au lot B :
un retrait de relique, gain négatif de source `progression`, est-il converti comme l'a été le gain ?

### 7.2. R5 — la règle qui protège l'économie

> **Une conversion ne peut jamais transformer une ressource éphémère en ressource permanente.**

L'armure est remise à zéro chaque tour (§1.1) ; `attackPower` est une stat de run permanente, ajoutée à
chaque effet `damage`. Convertir l'armure en `attackPower` ferait gagner au Berserker de la puissance
**définitive** à chaque `iron_wall` jouée (10 armure, 2 mana — carte neutre, donc présente dans tous les
decks). Le jeu serait cassé au troisième combat.

La conversion vise donc le **statut** `strength`, qui porte une durée et se décrémente comme tout statut
(`entity_stats.dart`, `tickStatuses`) : l'armure d'un tour devient de la Force d'un tour. La symétrie est
exacte.

La même règle borne *Ferveur* (P2), dont le gain de Force est à durée courte et non permanent.

### 7.3. Stats de départ

| Classe | Levier | Justification |
|:---|:---|:---|
| Paladin | `armorMastery` > 0 | Amplifie son propre passif à chaque fin de tour |
| Berserker | `critChance` > 0 | Colle à « Orienté Dégâts » sans toucher aux puissances |
| Mage | *(aucune stat)* | Son identité passe par `statRules` et ses trois passifs |

**`maxMana` reste à 3 pour les trois classes.** Les cartes coûtent 0 à 2 : un point de mana supplémentaire
représente environ **+33 % d'actions par tour**, de loin le levier le plus explosif du jeu — et c'est
précisément le sujet de **P-16**. Différencier le mana avant l'assainissement de son économie coulerait le
défaut dans le béton des classes.

`luck` reste à 0 partout. Le champ attend un porteur — une classe orientée hasard — pas un rééquilibrage.

**`critChance` est à ajouter à `HeroData`** ; `EntityStats` le porte déjà (`entity_stats.dart:17`).
Aujourd'hui, aucune classe ne déclare ni `critChance` ni `armorMastery`.

**Conséquence pour le tutoriel :** un Berserker à `critChance` > 0 rend les dégâts aléatoires. Traité au
lot D (§9.1).

---

## 8. Lot C — Récompenses de niveau et écran de sélection

### 8.1. Partie 1 — Récompenses data-driven

**Constat.** Les récompenses de niveau sont du **code**, pas de la donnée :

| Élément | Site |
|:---|:---|
| 8 valeurs d'enum, dont 6 types de stat tirables | `lib/game/services/level_up_reward_service.dart:8` |
| Tirage codé en dur | `level_up_reward_service.dart:148` — `rng.nextInt(6)` |
| Valeurs par rareté | `switch` dans le même service |
| Libellés | fichiers ARB |
| Liste recopiée à la main — prose du tutoriel | `lib/tutorial/tutorial_data.dart:321` |
| Liste recopiée à la main — défilement du carrousel | `lib/ui/widgets/relic_carousel/draft_card_reel.dart` |
| Valeurs verrouillées, 6 types × 5 raretés | `test/unit/level_up_reward_values_test.dart` |

Les deux mythiques (Trèfle, Miroir) sont construits hors du tirage.

**Décision D3 : les rendre data-driven avant d'en ajouter.**

- Un fichier par récompense, conformément à la règle « une entité, un fichier » de `CLAUDE.md` —
  répertoire et forme exacte fixés au plan.
- Chaque fichier porte sa table de valeurs par rareté et ses libellés **bilingues en ligne** (`_fr`,
  `_en`), comme tout contenu de jeu : les libellés quittent les ARB.
- Le tirage lit le registre ; le `rng.nextInt(6)` disparaît.
- La prose du tutoriel et le carrousel lisent le registre : les deux copies manuelles disparaissent.
- `level_up_reward_values_test.dart` devient un test **sur la donnée** et continue de verrouiller les 30
  combinaisons existantes, **à valeurs identiques**. Ce test est le critère d'acceptation de la partie 1.
- Le comportement de *Sagesse* (plafonnée à 2 sur deux paliers) est **conservé tel quel** : il relève de
  P-16, et le test l'assume déjà nommément.

**Cette partie est indépendante de tout le reste de P-41** et peut avancer en parallèle du lot A.

### 8.2. Partie 2 — Les nouvelles récompenses

#### Conditionnement par la classe — automatique

*Aiguisage* se scinde en trois récompenses (`attackPower`, `skillPower`, `alterationPower`). Le filtre
n'est pas une table à écrire : **c'est `statRules` lui-même**. Un Berserker ne tire jamais `skillPower`
parce que sa classe le bloque ; un Mage ne tire jamais `attackPower` parce que sa classe le convertit.
Les reliques et les événements qui en donnent restent, et leur gain est converti (§7.1).

Le tirage passe de **6 à 8 types de stat**, dont chaque classe n'en voit qu'une partie. Les trois
puissances **héritent des paliers d'*Aiguisage***, sans en inventer, et entrent dans le test de valeurs.

#### Conditionnement par le passif — neuf récompenses dédiées

Une récompense dédiée par passif, améliorant ses chiffres propres — seuil de *Flux de Mana*, ratio de
*Rage*, durée de *Marque du Mage*.

**Ces neuf récompenses ne se concurrencent jamais.** Une seule est éligible dans une run donnée, celle du
passif actif : la table de tirage effective compte **8 types de stat plus celle-là — 9, non 17**. L'éligibilité
se lit **par le point d'accès de P-49** (§5.1, P5).

Avec la partie 1 livrée, ces neuf récompenses sont réellement du contenu : neuf fichiers.

### 8.3. L'écran de sélection

`lib/ui/screens/class_selection_screen.dart:345` affiche `playerClass.baseDamage` — 5 / 15 / 10 — alors que
la run démarre à 0 pour tous (`run_controller.dart:254`, `attaque: 0 // Force de base à 0`). **L'écran ment
au joueur au moment le plus structurant de la run.** P-30 et P-48 n'y ont rien changé : P-30 a porté la
couleur et l'image de classe par la donnée, P-48 l'ordre d'affichage.

`baseDamage` est retiré de `class.json` et de `HeroData` : le champ n'a aucun consommateur de jeu côté héros,
et le rétablir est explicitement écarté (§11).

**Ajustement mécanique dans le même commit :** l'éditeur de contenu exige `baseDamage` pour une classe
(`lib/services/content_editor/entity_descriptor.dart:328`) et le met dans son gabarit (`:341`). Les deux
sont retirés avec le champ, sans quoi la suite de l'éditeur rougit.

L'écran affiche à la place ce qui diffère réellement :

- PV max et stats de départ non nulles ;
- les règles de `statRules` en clair — « ne peut pas se blinder », « ne renforce pas ses compétences » —,
  **générées à partir de la paire stat / mode**, jamais écrites classe par classe : c'est la règle d'ADR-090,
  aucun écran ne compare `hero.id` ;
- le **choix du passif** parmi les passifs disponibles pour la classe, **lus par le point d'accès de P-49**.

### 8.4. Hors périmètre

Le rééquilibrage des valeurs et des paliers de rareté des récompenses existantes — *Sagesse* en tête —
**reste à P-16**, qui exige une re-mesure que ce chantier ne fait pas. P-41 doit seulement **ne pas
aggraver**.

---

## 9. Lot D — Tutoriel et console de debug

Ce lot porte la **mise à jour fonctionnelle** ; les ajustements mécaniques ont été faits dans chaque lot
(§2, invariant).

### 9.1. Tutoriel

Contrainte : le tutoriel ne lit aucun provider d'état (ADR-081).

- **Les règles viennent de la fonction pure du lot A** (§4.1) : aucune recopie de `statRules`, de la
  maîtrise ou des puissances dans `lib/tutorial/`.
- **Déterminisme.** Le tutoriel compte aujourd'hui sur `critChance: 0` pour être déterministe
  (`tutorial_engine.dart:327`) — ce qui ne tient que parce qu'aucune classe n'a de critique. Avec un
  Berserker à `critChance` > 0 (§7.3), le tutoriel **force** la valeur à 0. C'est une **exception
  explicite et testée** à la fidélité au jeu d'ADR-081 : un tutoriel dont les dégâts varient ne peut pas
  annoncer ce que fera une carte.
- **Choix du passif.** L'étape de choix de classe propose les passifs disponibles, lus par le point d'accès
  de P-49 ; `tutorial_fixtures.dart:54` cesse de supposer un passif unique.
- **L'étape « Armure »** se valide aujourd'hui sur l'armure gagnée pendant l'étape. Pour une classe qui
  convertit l'armure, elle ne peut plus être franchie telle quelle. Contrainte à respecter au plan : **le
  tutoriel n'enseigne jamais une règle que la classe choisie ne suit pas.**
- **Les récompenses** enseignées lisent le registre de la partie 1 du lot C.
- Tests : `tutorial_engine_test` et `tutorial_fixtures_test`.

### 9.2. Console de debug

**Menu de debug** (manipulateur de run, P-30 lot 1) :

- le réglage unique `attaque` (`debug_hero_tab.dart:40-43`) devient **trois réglages de puissance** ;
- la run affichée expose ses règles de stat et son passif actif.

**Éditeur de contenu** (P-30 lot 2) :

- **Passifs** : le descripteur suit l'élargissement de `PassiveData` (P7) et valide `classes` comme une
  **liste de références vers des classes existantes**. Le validateur sait aujourd'hui vérifier une
  référence unique ou une liste de valeurs fixes (`lib/services/content_editor/entity_validator.dart`) : la
  liste de références est une extension à écrire. **C'est elle qui garantit qu'un passif créé depuis la
  console ne porte aucune classe mal orthographiée** (§5.2).
- **Classes** : `statRules` est validé — `stat` et `mode` bornés aux vocabulaires du moteur, `to` à une
  cible valide. Sans cela, l'éditeur laisserait écrire `"mode": "convrt"`, exactement le cas qu'il existe
  pour refuser.
- **Création guidée de classe** (`class_recipe.dart`) : elle crée aujourd'hui une classe avec ses cartes de
  signature, sans passif. Une classe sans aucun passif disponible afficherait un choix vide à la sélection :
  la recette **garantit au moins un passif disponible** pour la classe créée.
- **Récompenses de niveau** : nouvelle catégorie éditable, issue de la partie 1 du lot C. Le compte des
  catégories déclarées change (`test/unit/content_editor/entity_descriptor_test.dart:30`).

---

## 10. Préparation de la méta-progression (P-13)

La méta-progression est **pour plus tard** (décision D6). P-41 et P-49 en posent les **points
d'accroche** ; ils ne livrent ni stockage, ni déblocage, ni interface.

| Point d'accroche | Conception | Ce que P-13 y branchera |
|:---|:---|:---|
| Éligibilité des passifs par classe, en donnée (`classes`) | §5.1, P2 | Les conditions et coûts de déblocage, par personnage |
| Point d'accès unique « passifs disponibles = éligibles et débloqués » | §5.1, P4 et P5 | La lecture de l'état de déblocage — derrière ce point, sans toucher à ses lecteurs |
| Chaîne de migration de sauvegarde | §4.3 | Le passage de `RunState.activePassive` à plusieurs emplacements, s'il est retenu |
| Récompenses de passif éligibles par le point d'accès | §8.2 | Rien : elles suivent le déblocage d'elles-mêmes |

Le chantier qui pose chacun de ces points, et **ce qui reste entièrement à P-13**, sont tenus dans
`docs/ROADMAP.md`, section P-13 — source unique du reste à faire. Un point de conception le concerne et
vit donc ici : **la méta-progression aura son propre stockage, sous sa propre clé**, distinct du blob de
run de `SaveService`. Une run et un profil n'ont ni la même durée de vie, ni le même moment d'effacement :
la sauvegarde de run est effacée à la mort du héros.

---

## 11. Alternatives écartées

| Idée | Motif |
|:---|:---|
| **Rendre `baseDamage` réel** | La puissance d'attaque est ajoutée **par cible** sur les AoE (`strategies.dart:44`). Un Berserker démarrant à 15 ferait de `sweep` (1 mana) une carte à 18 dégâts par ennemi. C'est très probablement la raison de la neutralisation d'origine. |
| **Différencier `maxMana`** | §7.3 — levier le plus explosif du jeu, et sujet de P-16. |
| **Convertir l'armure en `attackPower`** | §7.2 — viole R5, casse le jeu au troisième combat. |
| **Deux stats de puissance au lieu de trois** | Le Mage n'aurait plus qu'un axe de build, et `alterationPower` est précisément la stat qui manque au seul archétype sans courbe propre au héros (§4.2). |
| **Quatre stats (`healPower`)** | Deux cartes de soin dans tout le jeu : stat sans substrat. |
| **Un passif Paladin adossé aux soins** | R4 — se déclencherait sur 2 cartes sur 23. Remplacé par *Bénédiction*. |
| **Passif Berserker générant une carte en main** | `addCardToHand` n'existe pas (§1). Le précédent — provenance, épuisement, comptage dans la taille du deck — appartient à S5. Remplacé par *Frénésie*. |
| **Plusieurs passifs actifs d'emblée** | Chaque paire devient une interaction à équilibrer, et le choix perd son coût. Relève de P-13 (§10). |
| **Appliquer la maîtrise d'armure à tous les gains dès le lot A** | §1.3 — la récompense *Forge d'Acier* est calibrée pour les seuls passifs. Ce serait une modification d'équilibrage cachée dans un lot à comportement identique. Écarté aussi sur le fond par le propriétaire (D7) : la maîtrise n'est pas à étendre mais à **refondre en bonus de passif** (§5.4). |
| **Recopier les règles de stat dans le tutoriel** | La recopie manuelle est ce qui avait produit les 50 écarts de P-45. Remplacée par une fonction pure partagée (§4.1). |
| **Incrémenter `schemaVersion` sans migration** | Efface toutes les sauvegardes en cours (§4.3). |
| **Garder la clé `run_save_v1` en passant à la v2** | Les builds publiés jusqu'à `0.5.1`, servis depuis la même origine et restés en ligne, effaceraient la partie en cours au premier « Continuer » (§4.3). Écarté par décision du propriétaire (D8). |
| **Traiter une sauvegarde plus récente comme corrompue** | Chaque build deviendrait à son tour l'ancien build qui efface les parties des suivants. Écarté par décision du propriétaire (D8). |
| **Déduire la version courante du nombre d'étapes** | Supprimer une étape obsolète ferait passer toute sauvegarde pour plus récente, et deux branches parallèles se renuméroteraient en silence (§4.3). |
| **Les règles de puissance sur `EntityStats`** | Le modèle est partagé avec les ennemis et n'importe que `meta` et `status_effect.dart` : il dépendrait du registre de données pour une règle de héros (§4.2). |
| **Suivre le précédent : tolérance de clé, sans version** | Suffisait pour des suppressions de champ. Écarté par décision du propriétaire (D1) au profit d'une vraie chaîne, qui servira aussi P-49 et P-13. |
| **Ranger les passifs dans `classes/<id>/passives/`** | Le dossier imposerait une classe propriétaire unique : un passif ne pourrait plus être partagé (§5.1). |
| **Chaque classe liste ses passifs dans `class.json`** | Ajouter un passif partagé obligerait à modifier le fichier de chaque classe concernée. Écarté au profit de P2 (§5.1). |
| **`statRules` en table** | Non validable par l'éditeur de contenu sans étendre son langage de chemins (§7.1). |
| **`onDamageTaken` réservé aux passifs, dans un enum séparé** | Deux enums de triggers à maintenir. Écarté au profit d'un dispatch aussi pour les reliques (§5.1, P9). |
| **Écrire les nouvelles récompenses en Dart** | Chaque récompense future aurait demandé de toucher environ cinq fichiers de code. Écarté par décision du propriétaire (D3). |
| **Un seul chantier** | Une PR géante, et un problème sur une partie bloque tout. Écarté par décision du propriétaire (D4). |

---

## 12. Périmètre et suite

### Dans P-41

- **Lot A** : le point de passage unique des gains, à source étiquetée, la fonction pure de règles, la scission des trois
  puissances, la chaîne de migration sous sa nouvelle clé et son étape v1 → v2, la suppression de la
  chaîne morte `bonusAttack`.
- **Lot B** : `statRules`, les neuf passifs, le hook `lifesteal`, les stats de départ.
- **Lot C** : les récompenses data-driven, les récompenses de puissance et de passif, l'écran de sélection.
- **Lot D** : la mise à jour fonctionnelle du tutoriel et de la console de debug.

### Dans P-49 — spec à écrire

Le modèle des passifs partagés, le point d'accès unique, la refonte de `TraitSystem` en Strategy, les
triggers `onDamageTaken` et de comptage, l'étape de migration v2 → v3 — d'où sa dépendance au lot A —,
l'ADR qui remplace ADR-086 D4. Frontière et décisions : §5.

### Hors P-41

Les autres lots du programme — **P-42** (pools de cartes), **P-43** (économie de deck), **P-44**
(profondeur de cartes) — sont décrits, chiffrés et ordonnés dans
[`docs/ROADMAP.md` §4](../../ROADMAP.md), section « Programme *Identité de classe & catalogue* ».
**Ce document ne les redécrit pas** : la ROADMAP est la source unique du reste à faire.

**P-40 est livré** (2026-09-15) et a tenu la seule condition que cette conception lui posait : ne pas
emporter `applyLifestealBuff()` avec la chaîne `skills.json` (§1.2).

**Le filtre de classe des cartes de signature** — les cartes de classe non `unique` proposées à toutes les
classes en boutique et sur le bonus de boss — n'est pas dans P-41 : il se traite avant ou avec **P-42**, qui
touche les mêmes pools.

### La tension à garder en tête pour S3 (P-42) et S4 (P-43)

Les documents amont portent deux objectifs opposés sans les nommer : « le joueur n'obtient pas assez de
copies des mêmes cartes » (concentrer le pool) et « comment élargir le pool ? » (diversifier).

Les pools par classe les réconcilient : le catalogue global grossit tandis que le pool **effectif d'une
run** rétrécit. C'est le mécanisme central de S3, et il conditionne la forme de la récompense de carte de
S4 — qui devra être **biaisée vers les doublons**, faute de quoi elle aggravera le problème qu'elle est
censée résoudre.

---

*Conception. Aucune valeur d'équilibrage chiffrée : elles relèvent des plans d'implémentation et du
playtest. Les chantiers `P-xx` cités renvoient à `docs/ROADMAP.md`, source unique du reste à faire.*
