# S2 — Identité de classe — Conception

Date : 2026-08-07 · **Révisée le 2026-09-16 et le 2026-09-17**
Statut : **Lot A implémenté** (fusionné dans `main`, PR #38) — lots B à D non implémentés, **lot B reconçu le 2026-09-17** (§0.3) ; chantier frère P-49 implémenté (fusionné dans `main`, PR #39), voir sa [spec](2026-09-16-p49-passifs-partages-design.md)

> [!IMPORTANT]
> **Révision du 2026-09-16 — lire le §0 avant tout le reste.** La conception du 2026-08-07 a été
> re-vérifiée contre le code (`fc93efc`) par six passes indépendantes : trois chantiers l'avaient
> dépassée (P-48, P-40, P-30), et le rebase du 2026-09-05 n'avait corrigé que ses chemins. **Aucun
> arbitrage de conception n'est tombé** ; en revanche, le périmètre était sous-estimé d'environ
> moitié, une section aurait effacé les sauvegardes, et le propriétaire a pris les décisions du §0.1.
> La revue du plan du lot A, le même jour, a ajouté la décision D8 et la dépendance de P-49 au lot A.
> Toute référence `fichier:ligne` de ce document a été **re-mesurée le 2026-09-16**.
> La version antérieure reste lisible dans l'historique git.
>
> **Révision du 2026-09-17 — la Puissance.** Les trois puissances du lot A sont remplacées, au lot B, par
> une **Puissance unique que la classe oriente** : lire le §0.3 avant les §6 et §7. Les références des
> sections reconçues ont été mesurées le 2026-09-17 sur `56be78d`.

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
> Berserker **convertit** l'armure en Puissance, `iron_wall` et `defend_basic` restent dans son pool —
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
| D7 | Maîtrise d'Armure | **À refondre en bonus de passif**, pour rester cohérente avec les neuf passifs : stat globale ou stat par passif, **à trancher au brainstorm de P-49**. Le lot A n'y touche pas. **Tranchée le 2026-09-16** : une seule stat, *Maîtrise*, dont chaque passif déclare l'effet — [spec de P-49](2026-09-16-p49-passifs-partages-design.md), N1 | §5.4 |
| D8 | Sauvegardes et versions publiées | **Nouvelle clé `run_save`**, relue en repli sur `run_save_v1` ; une sauvegarde écrite par un build plus récent n'est **jamais effacée** | §4.3 |
| D9 | Stats de puissance *(2026-09-17)* | **Une seule Puissance, que la classe oriente** : la classe déclare ce que sa Puissance renforce, et plus aucun gain de puissance n'est converti. Remplace, au lot B, la scission en trois puissances du lot A. La Force devient la Puissance temporaire | §7.1 |
| D10 | Nom de la stat *(2026-09-17)* | **Puissance** en français, **Might** en anglais, `might` dans le code | §7.1, §7.4 |

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

### 0.3. Révision du 2026-09-17 — la Puissance

Au moment d'écrire le plan du lot B, ses deux questions ouvertes — la conversion du Mage porte-t-elle sur
la Force (§4.2), et sur le retrait d'une relique (§7.1) ? — ont révélé une même cause : les règles de
classe visaient la puissance **au moment du gain**. Tout ce qui défait un gain devait alors refaire la
conversion, et tout ce qui n'est pas un gain y échappait. Le propriétaire a retenu, contre deux autres
approches (§11), une **Puissance unique que la classe oriente au moment de la lecture** (D9), nommée
*Puissance* (D10) : le mécanisme de la Maîtrise de P-49, appliqué à la classe. Il a confirmé le même jour
les identités qui en découlent — le Paladin polyvalent, le Mage qui frappe par ses Compétences et ses
altérations, le Berserker par ses seules Attaques.

| Section | Ce qui change |
|:---|:---|
| §2, §12 | Le lot B se livre en deux parties : la Puissance à comportement identique, puis l'identité de classe |
| §3 | La scission en trois puissances est remplacée ; `statRules` ne convertit plus qu'une ressource |
| §4.1, §4.2 | Notes : ce que le lot A a livré reste, la scission est remplacée au lot B |
| §6.2, §6.3 | Les passifs gagnent de la Puissance ; les classes orientent au lieu de bloquer ou de convertir |
| §7 | Reconçue : orientation de la Puissance, conversion d'armure, textes joueur, sauvegarde, deux parties |
| §8.2, §8.3 | *Aiguisage* n'est plus scindée ; l'écran de sélection montre ce que renforce la Puissance |
| §9 | Le tutoriel et la console lisent l'orientation |
| §11 | Neuf alternatives ajoutées |

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
un **bonus de passif**. Sa forme exacte est une question ouverte de P-49 (§5.4) — tranchée depuis (§5.4).

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
| **P-49** | Passifs partagés : modèle, éligibilité par classe, point d'accès unique, Maîtrise — [spec de P-49](2026-09-16-p49-passifs-partages-design.md) | §5 |
| **B** | Partie 1 : la Puissance (`might`), à comportement identique. Partie 2 : l'orientation de la Puissance par classe, la conversion d'armure du Berserker, les neuf passifs, stats de départ différenciées | §6, §7 |
| **C** | Partie 1 : récompenses de niveau data-driven. Partie 2 : filtre d'*Affinité* et écran de sélection | §8 |
| **D** | Mise à jour fonctionnelle du tutoriel et de la console de debug | §9 |

L'ordre des lots — qui dépend de quoi, ce qui est livré — est tenu dans
[`docs/ROADMAP.md` §4](../../ROADMAP.md), programme « Identité de classe & catalogue ». Cette section en
donne les **causes** :

- **A avant P-49.** P-49 retire `RunState.passiveTrait` par une étape de migration v2 → v3 (§5.1, P11),
  qui s'ajoute à la chaîne que pose A (§4.3). Livré avant A, P-49 trouverait un `SaveService` qui efface
  toute version autre que 1. *(P11 abandonnée le 2026-09-16 ; P-49 retire la règle de Maîtrise que A a
  posée dans `StatGains` — la dépendance demeure, et A est fusionné.)*
- **A avant B.** La conversion d'armure du Berserker ne peut s'appliquer qu'au passage unique des gains,
  et la partie 1 de B réunit en une seule Puissance les trois que A a posées, lues par la règle
  d'attribution de A (`PowerRules`).
- **P-49 avant B.** Les neuf passifs ont besoin d'un modèle où vivre.
- **Dans B, la partie 1 avant la partie 2.** La partie 1 renomme et réunit sans rien changer au jeu : la
  suite existante suffit à la vérifier. La partie 2 change le comportement des trois classes sur une base
  déjà renommée (§7.6).
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

1. **Une Puissance unique que chaque classe oriente**, et un mécanisme de règles de stat par classe,
   pilotés en JSON, réutilisables pour toute classe future (§7.1).
2. **La scission de `attaque` en trois puissances** — `attackPower`, `skillPower`, `alterationPower` —
   à comportement identique au jeu actuel (§4.2), livrée au lot A puis **remplacée au lot B par la
   Puissance** (D9).
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
*(Depuis D9, aucune règle de classe ne vise plus la puissance au gain : la classe l'oriente à la lecture,
et le retrait d'une relique n'a plus rien à reconvertir — §7.1. Le passage unique garde tout son rôle
pour l'armure.)*

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
source `passive`, quelle que soit la ressource gagnée. **Tranché autrement par P-49** : la Maîtrise
s'applique au paramètre du passif avant son calcul, et la règle quitte `StatGains` ([spec de P-49](2026-09-16-p49-passifs-partages-design.md), §6.3).

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

> [!NOTE]
> **Remplacée au lot B par la décision D9 (2026-09-17).** La scission est livrée et fusionnée ; le lot B
> réunit les trois puissances en une seule, `might`, que la classe oriente (§7.1). La règle d'attribution
> par type de carte et par cible, décrite ci-dessous, reste celle qu'applique l'orientation. Le texte est
> conservé comme conception du lot A.

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
>
> **Tranchée le 2026-09-17 par D9, sans l'une ni l'autre** : la Force devient la Puissance temporaire, que
> la classe oriente comme la Puissance permanente. Le Mage ne tire plus rien de `demon_form` sur ses
> cartes Attaque, et aucune règle ne s'étend aux statuts (§7.1).

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

**Étapes suivantes :** P-49 ajoute l'étape v2 → v3 (§5) — **P-49 dépend donc du lot A** (§2). *(Abandonné le
2026-09-16 : avant la `1.0.0`, les sauvegardes ne se transfèrent pas — [spec de P-49](2026-09-16-p49-passifs-partages-design.md), N6.)* P-13
**n'étend pas ce blob** : la méta-progression aura son propre stockage, sous sa propre clé (§10).

---

## 5. Chantier frère P-49 — Passifs partagés

> **P-49 a sa propre spec : [spec de P-49](2026-09-16-p49-passifs-partages-design.md), écrite le 2026-09-16.** Elle fait foi ; elle relit une à une les
> décisions P1 à P12 ci-dessous (§1.2) et en déplace ou abandonne trois. Cette section ne le conçoit pas en entier : elle fixe la
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
| P8 | Les triggers manquants sont posés ici : `onDamageTaken`, et une facilité de comptage par tour et par combat — **déplacée au lot B le 2026-09-16** (spec de P-49, N2) | Voir §6.4 |
| P9 | **Déplacée au lot B le 2026-09-16** (spec de P-49, N2), inchangée sur le fond. `onDamageTaken` est ajouté à `RelicTrigger` **et dispatché pour les reliques aussi**, partout où le héros perd des PV : attaque ennemie (`lib/game/controllers/combat/turn_phase_manager.dart:114`), poison, appliqué directement par `EntityStats.takeDamage` (`status_effect_processor.dart:24`, depuis `RunController.startTurn`), dégâts d'événement (`event_controller.dart:68`, hors combat). La spec de P-49 choisit un point qui couvre les trois, ou écarte explicitement ceux qu'elle exclut | L'éditeur de contenu lit cet enum : un trigger ajouté sans dispatch serait proposé aux reliques et ne ferait rien. Posé sur la seule attaque ennemie, il laisserait *Ferveur* muette sur le poison |
| P10 | L'appel `TraitSystem.onTurnEnd` quitte `game_screen.dart:522` pour un controller | `CLAUDE.md` interdit la logique de jeu dans un écran, et la refonte touche cet appel |
| P11 | Étape de migration **v2 → v3** pour `RunState.passiveTrait` — **abandonnée le 2026-09-16** (spec de P-49, N6) | Le champ disparaît du modèle (P3). L'étape s'ajoute à la chaîne du lot A, d'où la dépendance de P-49 à A (§2) |
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

> [!NOTE]
> **Tranchée au brainstorm de P-49, le 2026-09-16 : ni l'une ni l'autre forme, un hybride.** Une seule
> stat, *Maîtrise*, et une seule récompense, *Affinité* ; chaque passif déclare dans son fichier le
> paramètre qu'un point augmente. Conception : [spec de P-49](2026-09-16-p49-passifs-partages-design.md), §3.3 et §6. Le texte ci-dessous est conservé
> pour la trace de la question.

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

*(Depuis D9, la Puissance n'est jamais interdite, seulement orientée, et le lot B ne livre aucun mode
`block` : R3 ne contraint aujourd'hui aucune paire. Elle reste la règle du jour où un blocage sera
ajouté — §7.1.)*

### 6.3. Les neuf passifs

Aucune valeur chiffrée : elles relèvent de l'équilibrage, pas de la conception. **La colonne
« Croissance » suit les décisions postérieures à la conception d'origine** : la Maîtrise, dont chaque
passif déclare l'effet par son bloc `mastery` (spec de P-49, N1), remplace `armorMastery` ; la Puissance
remplace les trois puissances (D9). Les neuf sont conçus
**un par classe** (`"classes"` à un élément) ; leur partage éventuel est une décision de contenu
ultérieure, que le modèle de P-49 rend possible sans changement de code. La Puissance le facilite : un
passif qui en donne sert toute classe, puisque chacune l'oriente (§7.1).

#### Paladin — Puissance : `attack`, `skill`, `alteration` · aucune règle de stat · Maîtrise de départ > 0

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| P1 | **Régénération d'Armure** *(existant, `regen_armor`)* | `endOfTurn` | Gain d'armure | Maîtrise |
| P2 | **Ferveur** | `onDamageTaken` | L'armure qui absorbe des dégâts octroie de la Puissance temporaire, à durée courte | Puissance |
| P3 | **Bénédiction** | `startOfTurn`, **avant le reset de §1.1** | L'armure survivante devient des PV | Maîtrise |

Seule classe dont la Puissance renforce tout : c'est son identité de généraliste, et le repère du
joueur qui découvre.

*Ferveur* referme une boucle propre : chez le Paladin, **encaisser devient une ressource offensive**. Il
tape parce qu'il tient, là où le Berserker tape parce qu'il meurt — les deux classes lisent le même
verbe à l'envers l'une de l'autre.

*Bénédiction* s'insère impérativement **avant** `armure: 0` dans `startTurn()` (`run_controller.dart:413`),
sinon il n'a rien à convertir. C'est le seul passif du jeu dont l'ordre d'exécution est contraignant ;
il doit être couvert par un test dédié.

#### Berserker — Puissance : `attack` · armure convertie en Puissance temporaire (1 tour) · `critChance` de départ > 0

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| B1 | **Rage** | `startOfTurn` | Puissance temporaire proportionnelle aux PV manquants | Puissance |
| B2 | **Soif de Sang** | `onAttackPlayed` | Vol de vie, croissant à mesure que les PV baissent | `critChance` |
| B3 | **Frénésie** | `onEnemyKilled` | Puissance temporaire et pioche à chaque ennemi abattu | Puissance |

*Rage* est la formule de `berserker_armor` redirigée vers la Puissance temporaire. Elle corrige au passage le défaut
relevé au diagnostic (§I.3.2) : le passif ne sera plus muet à pleine vie, un plancher étant possible.

**_Soif de Sang_ est le passif le plus cher des neuf** — l'inverse de ce que laissait croire la conception
du 2026-08-07. `lifesteal` est orphelin trois fois (§1.2) : B2 doit créer la **source** du statut, le
**hook** de soin après résolution des dégâts, et brancher son axe de croissance. `DamageEffectStrategy`
dispose déjà des stats du héros ; le hook s'y pose.

**Une Puissance tournée vers les seules Attaques se paie en axes de croissance.** Le Berserker n'a que
la Puissance et `critChance` ; ses trois passifs se distinguent par le *pattern* — attrition, soutien,
boule de neige — et non par la stat. Conforme à R2, mais c'est le coût réel de l'orientation, nommé ici
plutôt que découvert au playtest.

L'orientation est **souple** : les cartes `skill` restent jouables et leurs effets non offensifs (pioche,
mana, armure convertie) fonctionnent normalement. Seuls leurs dégâts ne profitent pas de la Puissance.

#### Mage — Puissance : `skill`, `alteration`

| | Passif | Trigger | Effet | Croissance |
|:---|:---|:---|:---|:---|
| M1 | **Flux de Mana** | `onSkillPlayed`, compteur | Mana supplémentaire pour le tour | Puissance |
| M2 | **Marque du Mage** | 1ʳᵉ attaque du tour | La cible devient `vulnerable` | Puissance |
| M3 | **Canalisation** | `endOfTurn` | Le mana non dépensé devient de l'armure | Maîtrise |

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
| `onDamageTaken` | ❌ **posé par le lot B** — déplacé de P-49 le 2026-09-16 (§5.1, P9) | P2 |
| Comptage par tour et par combat | ❌ **posé par le lot B** — déplacé de P-49 le 2026-09-16 (§5.1, P8) | M1 (« N compétences »), M2 (« 1ʳᵉ attaque du tour ») |

`onCardPlayed` perd son seul consommateur côté passif avec la disparition de `spell_armor` — deux reliques
l'utilisent encore (`mage_amulet`, `pen_nib`).

---

## 7. Lot B — La Puissance, `statRules` et stats de départ

> [!NOTE]
> **Reconçue le 2026-09-17** (D9, D10, §0.3). La conception du 2026-08-07 convertissait les gains de
> puissance au moment du gain : le Mage recevait de l'`alterationPower` à la place de l'`attackPower`.
> Cette section la remplace ; la version antérieure reste lisible dans l'historique git. Références
> mesurées le 2026-09-17 sur `56be78d`.

### 7.1. La Puissance et `statRules`

#### Le principe : la classe oriente la Puissance, elle ne convertit pas ses gains

L'identité d'une classe peut s'appliquer à deux moments : au **gain** d'une stat, ou à sa **lecture**,
quand une carte se résout. Les deux questions ouvertes de la révision du 2026-09-16 venaient toutes deux
du premier choix :

| Le Mage… | Au gain *(conception du 2026-08-07)* | À la lecture *(D9)* |
|:---|:---|:---|
| prend *Pierre à aiguiser* | +1 `alterationPower` est écrit | +1 Puissance est écrite ; sa classe dit ce qu'elle renforce |
| la sacrifie au Sanctuaire des reliques (`exchangeRelics`, `player_stats_manager.dart:404`) | Le retrait est un gain négatif (`removeRelicEffect`, `:382`) : il doit repasser par la même conversion, faute de quoi le Mage garde le bonus et sa puissance d'attaque tombe à −1 | −1 Puissance : retour exact à l'état de départ |
| joue *Forme Démoniaque* (+2 Force pendant 4 tours) | La Force est un statut, pas un gain : elle échappe à la conversion et renforce ses cartes Attaque | +2 Puissance temporaire, orientée comme la permanente |

À la lecture, **l'inverse d'un gain est exact par construction**, et un bonus temporaire suit la même
orientation que la stat permanente. Aucune règle n'est à se rappeler au prochain mécanisme qui retire ou
prête de la Puissance, méta-progression comprise.

C'est le mécanisme de la Maîtrise de P-49, appliqué à la classe : une seule stat, dont la donnée déclare
l'effet — là le passif, ici la classe.

#### La stat `might`

| Aujourd'hui | Au lot B |
|:---|:---|
| `EntityStats.attackPower`, `skillPower`, `alterationPower` (`entity_stats.dart:12-14`) | `EntityStats.might`, seule : `skillPower` et `alterationPower` disparaissent |
| `effectiveAttackPower`, `attackPower` plus les statuts `strength` (`entity_stats.dart:179`) | `effectiveMight`, `might` plus les statuts `might` |
| Statut `strength`, nommé « Attaque » ou « Force (Relique) » selon le site qui le crée | Statut `might`, la **Puissance temporaire** |
| Statut `strength_regen`, « Éveil d'Attaque » (`effect_resolver.dart:50`) | `might_regen`, « Éveil de Puissance » |
| `GainResource.attackPower`, `skillPower`, `alterationPower` (`stat_gains.dart:4`) | `GainResource.might` |
| `applyHeroStatModifier(attackAcc:)` (`draft_screen.dart:648`) et `DraftChoice.atkBoost` (`level_up_reward_service.dart:22`) | `mightAcc:` et `mightBoost` |
| `effectType` `gain_strength`, `charge_strength_turn`, `charge_strength_combat` des reliques et des événements | `gain_might`, `charge_might_turn`, `charge_might_combat` |
| `statusId` `strength` des cartes `demon_form` et `rage_form` | `might` |
| `playerAttaque`, entrée du budget de rencontre (`game_screen.dart:259` → `encounter_system.dart:98`) | `playerMight` |

**Les ennemis ne changent que de nom.** `EntityStats` leur est partagé (§1) : leur `might` est leur
puissance d'attaque (`combat_controller.dart:155`, `enemy_instance.dart:21-26`), et leur intention
« Buff » leur donne de la Puissance temporaire (`turn_phase_manager.dart:140-148`). Ils ne jouent aucune
carte : l'orientation ne les concerne pas.

**Code mort supprimé plutôt que renommé** : `applyAttackBuff` (`player_stats_manager.dart:439`, façade
`run_controller.dart:430`) n'a aucun appelant — comme la chaîne `bonusAttack` au lot A.

#### L'orientation : `mightTargets`

La classe déclare dans son `class.json` ce que sa Puissance renforce :

| Cible | Ce que la Puissance renforce |
|:---|:---|
| `attack` | Les dégâts d'un effet `damage` porté par une carte Attaque |
| `skill` | Les dégâts d'un effet `damage` porté par une carte Compétence |
| `alteration` | L'intensité d'un statut posé **sur un ennemi**, par une carte ou par l'une de ses runes — jamais sa durée |

La règle d'attribution du lot A (§4.2) est conservée telle quelle : une carte Pouvoir ou Statut n'est
jamais renforcée, un statut posé sur soi non plus — ce qui empêche la Puissance temporaire de se nourrir
d'elle-même.

- **Obligatoire et non vide.** `HeroData.fromJson` lève `FormatException` sur une clé absente, une liste
  vide ou une cible inconnue. Une classe dont la Puissance ne renforcerait rien est une faute de donnée,
  et une valeur par défaut ferait d'une clé oubliée une classe mal réglée sans que rien ne le dise.
- **`MightTarget`** est un enum sans dépendance, rangé dans `lib/models/might_target.dart` et importé par
  `EntityStats` et `HeroData`.
- **L'orientation est copiée dans les stats du héros**, champ `EntityStats.mightTargets`, là où ces stats
  naissent de la classe : `RunController.startNewRun` (`run_controller.dart:239`) et
  `TutorialMockState.baseStatsForHero` (`tutorial_engine.dart:55`). Par défaut, `{attack}` : c'est la
  valeur des ennemis et des stats de repli (`run_controller.dart:208`, `tutorial_engine.dart:25`, `:46`).
  Elle est sérialisée avec les stats.

**Pourquoi dans les stats, et non lue sur la classe à chaque résolution.** Les huit appels de
`PowerRules`, répartis dans cinq fichiers, ne tiennent que les stats du héros : côté Flame par
`game.heroCard` (`card_component.dart:344`, `card_text_renderer.dart:95`, `:357`), côté jeu par
`RunState` (`strategies.dart:34`, `:46`, `:148`, `effect_resolver.dart:182`), et dans le tutoriel
(`tutorial_engine.dart:347`). Copiée dans les stats, l'orientation les atteint tous **sans qu'un seul
appel change de forme**. La règle ne vit pas pour autant sur `EntityStats` (§11) : le modèle porte un
ensemble de valeurs, `PowerRules` leur correspondance avec `CardType` et `CardTarget`.

```dart
// Forme indicative — lib/game/systems/power_rules.dart
int damageBonusFor(CardType type) => switch (type) {
      CardType.attack => _mightFor(MightTarget.attack),
      CardType.skill => _mightFor(MightTarget.skill),
      CardType.power || CardType.status => 0,
    };

int statusBonusFor(CardTarget target) => switch (target) {
      CardTarget.singleEnemy || CardTarget.allEnemies => _mightFor(MightTarget.alteration),
      CardTarget.self || CardTarget.none => 0,
    };

int _mightFor(MightTarget target) =>
    mightTargets.contains(target) ? effectiveMight : 0;
```

**Une différence de lecture, voulue.** Au lot A, `skillPower` et `alterationPower` étaient lus sans
statut. `effectiveMight` compte la Puissance temporaire pour toutes les cibles : c'est ce qui permet à un
Mage sous *Forme Démoniaque* de renforcer ses altérations. Sans effet à la partie 1 (§7.6), où les deux
valent 0 partout.

**Un cumul à surveiller**, déjà relevé à la revue finale du lot A (`docs/ROADMAP.md` §4) : une carte qui
pose une altération et sa rune d'altération reçoivent chacune le bonus. Il devient réel à la partie 2, dès
qu'une classe oriente sa Puissance vers `alteration`.

#### Les orientations des trois classes

| Classe | `mightTargets` | Identité |
|:---|:---|:---|
| Paladin | `attack`, `skill`, `alteration` | Polyvalent : toutes ses cartes profitent de sa Puissance |
| Berserker | `attack` | Frappe en direct, et seulement ainsi : ses Compétences n'en profitent pas |
| Mage | `skill`, `alteration` | Frappe par ses Compétences et ses altérations : ses cartes Attaque n'en profitent pas |

**Conséquence assumée, confirmée par le propriétaire le 2026-09-17.** Toutes les cartes de dégâts du jeu
sont de type Attaque (§1), y compris *Projectile Magique*, la carte de classe du Mage, et les sorts neutres
*Boule de Feu*, *Trait de Glace* et *Coup de Tonnerre*. Jusqu'à ce que P-42 écrive des Compétences
offensives, la Puissance du Mage ne renforce donc aucun de ses dégâts : elle renforce l'intensité de ses
brûlures, gels, poisons et chocs.

**À surveiller à l'équilibrage, pas à la conception** : le Paladin tire parti de chaque point de Puissance
sur tout son deck.

#### Ce qui reste à `statRules` : convertir une ressource

L'orientation règle la Puissance. Reste une règle qui ne peut s'appliquer qu'au gain, parce qu'elle porte
sur une **ressource consommée** et non sur un bonus lu : l'armure du Berserker, remise à zéro chaque tour
(§1.1).

```jsonc
// Berserker
"statRules": [
  { "stat": "armor", "mode": "convert", "to": "status:might", "duration": 1 }
]

// Mage, Paladin — clé absente : aucune règle
```

- **Vocabulaire.** `stat` : une ressource de `GainResource` autre que la Puissance, `armor` ou `mana` ;
  `mode` : `convert` ; `to` : `status:might` au lot B.
- **La Puissance n'est jamais une `stat` de `statRules`.** La convertir au gain rouvrirait exactement les
  deux problèmes que l'orientation règle : `HeroData.fromJson` le refuse.
- **`block` n'est pas livré.** Son seul usage prévu, les Compétences du Berserker, est devenu une
  orientation : livré sans lecteur, ce serait du code mort. Il reste une extension possible, avec `cap` et
  `decay`, sans changement de forme.
- **Une liste, et non une table.** Le langage de chemins de l'éditeur de contenu
  (`lib/services/content_editor/field_path.dart`) sait désigner un élément de liste (`statRules[].mode`),
  pas une clé arbitraire d'une table.
- **Compatible avec l'autorité du répertoire (ADR-086).** La source des classes n'injecte que `id`
  (`lib/services/game_data_service.dart:116-117`) : écrire `statRules` ou `mightTargets` dans le fichier
  est légal.
- **`HeroData` doit les lire.** Sans champ ni lecture dans `HeroData.fromJson`, une clé serait chargée et
  jetée en silence — le mode d'échec le plus coûteux à diagnostiquer.
- **Les règles s'appliquent dans la fonction pure du lot A** (§4.1) : `StatGains.apply` les reçoit en
  paramètre obligatoire, celles de la classe pour le héros et une liste vide pour un ennemi. Toute source
  d'armure y passe : cartes, runes, passifs, reliques et statut `armor_regen`.

### 7.2. R5 — la règle qui protège l'économie

> **Une conversion ne peut jamais transformer une ressource éphémère en ressource permanente.**

L'armure est remise à zéro chaque tour (§1.1) ; la Puissance est une stat de run permanente, ajoutée à
chaque effet qu'elle renforce. Convertir l'armure en Puissance permanente ferait gagner au Berserker de la
puissance **définitive** à chaque `iron_wall` jouée (10 armure, 2 mana — carte neutre, donc présente dans
tous les decks). Le jeu serait cassé au troisième combat.

La conversion vise donc la **Puissance temporaire**, le statut `might`, qui porte une durée et se
décrémente comme tout statut (`entity_stats.dart`, `tickStatuses`) : l'armure d'un tour devient de la
Puissance d'un tour. La symétrie est exacte.

La même règle borne *Ferveur* (P2), dont le gain de Puissance est temporaire. Elle explique aussi pourquoi
un bonus temporaire reste un statut, au lieu d'être écrit dans la stat permanente le temps d'un effet (§11).

### 7.3. Stats de départ

| Classe | Levier | Justification |
|:---|:---|:---|
| Paladin | `mastery` > 0 | Amplifie son passif, quel qu'il soit, par le bloc `mastery` que celui-ci déclare |
| Berserker | `critChance` > 0 | Colle à « Orienté Dégâts » sans toucher à la Puissance |
| Mage | *(aucune stat)* | Son identité passe par l'orientation de sa Puissance et par ses trois passifs |

**`maxMana` reste à 3 pour les trois classes.** Les cartes coûtent 0 à 2 : un point de mana supplémentaire
représente environ **+33 % d'actions par tour**, de loin le levier le plus explosif du jeu — et c'est
précisément le sujet de **P-16**. Différencier le mana avant l'assainissement de son économie coulerait le
défaut dans le béton des classes.

`luck` reste à 0 partout. Le champ attend un porteur — une classe orientée hasard — pas un rééquilibrage.

**`critChance` est à ajouter à `HeroData`** ; `EntityStats` le porte déjà (`entity_stats.dart:19`).
Aujourd'hui, aucune classe ne déclare ni `critChance` ni `mastery`.

**Conséquence pour le tutoriel :** un Berserker à `critChance` > 0 rend les dégâts aléatoires. Traité au
lot D (§9.1).

### 7.4. Textes joueur

Un seul mot désormais : **Puissance**, **Might** en anglais. « Attaque » ne désigne plus que le type de
carte et l'intention d'attaque d'un ennemi ; « Force » et « ATK » disparaissent de ce que voit le joueur.

| Élément | Français | English |
|:---|:---|:---|
| Stat | Puissance | Might |
| Statut `might` : `statusStrength` devient `statusMight` (`status_effects_panel.dart:83`) | `Puissance : +{value}` | `Might: +{value}` |
| Statut `might_regen` : `statusMightRegen` | `Éveil de Puissance : +{value}` | `Might Awakening: +{value}` |
| Effet de carte : `cardDescStatusMight` (`card_component.dart:396`, `card_text_renderer.dart:410`, `ui_card_helpers.dart:388`) | `Gagne {amount} Puissance pendant {duration} tours.` | `Gains {amount} Might for {duration} turns.` |
| Effet de carte : `cardDescStatusMightRegen` | `Gagne {amount} Éveil de Puissance pendant {duration} tours.` | `Gains {amount} Might Awakening for {duration} turns.` |
| Intention d'ennemi : `intentBuff` (`enemy_intents_panel.dart:134`, `model_extensions.dart:107`) | `Buff Puissance : +{value}` | `Buff Might: +{value}` |
| Fiche d'un ennemi : `enemyStatsDesc` (`enemy_card.dart:205`) | `Santé : {hp}/{maxHp} PV.\nPuissance : {might}.\nArmure : {armor}.` | `Health: {hp}/{maxHp} HP.\nMight: {might}.\nArmor: {armor}.` |
| *Aiguisage* : `draftChoiceSharpeningDesc` (`draft_choice_labels.dart:72`) | `+{amount} Puissance` | `+{amount} Might` |
| Gain d'événement : `eventGainAttack` devient `eventGainMight` (`event_screen.dart:125`, `:259`) | `+{amount} Puissance` | `+{amount} Might` |
| Info-bulle de `StatType.attack` : `tooltipAttackTitle`, `tooltipAttackDesc` (`stat_badge.dart:519-520`) — **branche jamais construite**, `StatBadge` n'étant instancié qu'en `StatType.hp` (`enemy_card.dart:123`) : les clés gardent leur nom | `Puissance` ; `Renforce ce qu'oriente votre classe : Attaques, Compétences ou altérations.` | `Might`; `Strengthens what your class channels it into: Attacks, Skills or alterations.` |
| Les cibles en abrégé : `mightTargetAttackShort`, `mightTargetSkillShort`, `mightTargetAlterationShort`, dans cet ordre | `Attaques` · `Compétences` · `Altérations` | `Attacks` · `Skills` · `Alterations` |
| Fiche des stats (`stats_dialog.dart:175-177`) | Titre `Puissance` ; sous-titre : les cibles en abrégé, jointes par ` · ` | Title `Might`; subtitle: the short targets, joined by ` · ` |
| Mini-panneau des stats (`hero_mini_stats_panel.dart:100`) | `{n} Puissance` | `{n} Might` |
| Noms des statuts créés en code (`name:`) : « Attaque », « Force (Relique) », « Éveil d'Attaque » | « Puissance », « Puissance (Relique) », « Éveil de Puissance » | — *(les noms de statut ne sont qu'en français)* |

Les textes générés suivent ADR-090 : aucun écran ne compare l'identifiant d'une classe. **La forme longue
n'a pas de lecteur à la partie 1** : elle est écrite au lot C, pour l'écran de sélection (§8.3) — « les
dégâts de vos Attaques », « les dégâts de vos Compétences », « vos altérations » / « your Attack damage »,
« your Skill damage », « your alterations », deux cibles jointes par « et » / « and », trois par une
virgule puis « et » / « and ».

**Deux textes écrits en dur**, relevés à la rédaction du plan de la partie 1 :

| Site | Français | English |
|:---|:---|:---|
| Glossaire des statuts du tutoriel (`lib/tutorial/widgets/tutorial_elements_widget.dart:100-111`) | « Puissance » : « S'ajoute à ce que renforce votre classe » ; « Éveil de Puissance » : « Donne de la Puissance au début du tour » | « Might »: « Adds to what your class strengthens »; « Might Awakening »: « Grants Might at the start of the turn » |
| Carrousel des récompenses (`lib/ui/widgets/relic_carousel/draft_card_reel.dart:47-48`) | *Aiguisage* « +4 Puissance » ; *Affinité* « +2 Maîtrise », à la place de *Forge d'Acier*, oubliée par P-49 | — *(le carrousel n'est qu'en français)* |

**Données** — `description_fr` et `description_en`, ou `text_fr` et `text_en` pour un choix d'événement :

| Fichier | Français | English |
|:---|:---|:---|
| `cards/demon_form.json` | Gagne 2 Puissance pendant 4 tours. | Gain 2 Might for 4 turns. |
| `classes/berserker/cards/rage_form.json` | Applique 2 Puissance ce tour-ci. Pioche 1 carte. | Apply 2 Might this turn. Draw 1 card. |
| `relics/whetstone.json` | +1 Puissance de manière permanente pour toute la run. | +1 Might permanently for the entire run. |
| `relics/cursed_blade.json` | +2 Puissance de manière permanente pour toute la run. | +2 Might permanently for the entire run. |
| `relics/pen_nib.json` | Toutes les 5 cartes jouées, gagne 3 Puissance pour le tour en cours. | Every 5 cards played, gain 3 Might for the current turn. |
| `relics/shuriken.json` | Toutes les 3 attaques jouées dans un tour, gagne 1 Puissance pour le combat. | Every 3 Attacks played in a turn, gain 1 Might for combat. |
| `events/blessed_fountain.json` | Purifier son esprit (-12 PV Max, +1 Puissance) | Purify your mind (-12 Max HP, +1 Might) |
| `events/mysterious_altar.json` | Sacrifier votre sang (-15 PV, +1 Puissance) | Sacrifice your blood (-15 HP, +1 Might) |

**Tutoriel** (`lib/tutorial/tutorial_data.dart`) — trois phrases nomment la stat :

| Site (français, anglais) | Français | English |
|:---|:---|:---|
| Étape des cartes (`:141-143`, `:129-130`) | « Les dégâts imprimés sur une carte ne sont pas le chiffre final : la Puissance de votre héros s'y ajoute, selon ce que renforce sa classe, et la rareté multiplie la valeur de base. » | « The damage printed on a card is not the final number: your Hero's Might is added on top, depending on what their class strengthens, and rarity multiplies the base value. » |
| Étape des ennemis (`:237`, `:226`) | « Il en existe trois : Attaque, Défense et Buff Puissance. » | « There are three: Attack, Defend, and Buff Might. » |
| Même étape (`:243-245`, `:231-232`) | « …il monte avec le niveau de l'ennemi et sa Puissance accumulée, et se divise par deux tant qu'il est Gelé. » | « …it grows with the enemy's level and accumulated Might, and halves while they are Frozen. » |

Le reste de la prose du tutoriel n'est pas réécrit : c'est le lot D.

**Icônes, à la partie 2.** L'épée qui accompagne la stat (`SwordIcon` : `player_health_bar.dart:128`,
`stats_dialog.dart:174`, `hero_mini_stats_panel.dart:99` ; `FlameSwordIcon` : `stat_badge.dart:80`) et le
💪 du statut (`status_indicator.dart:146`) disent l'attaque physique, ce que D10 a écarté pour le nom. Tant
que les trois classes orientent leur Puissance vers `attack`, ils restent justes. À la partie 2, ils
deviennent l'éclair qui marque déjà le statut dans le panneau des statuts et sur les cartes
(`Icons.flash_on`, `Icons.bolt_rounded`), et ⚡ pour le statut. `FlameSwordIcon`, sans autre usage,
disparaît alors ; `SwordIcon` reste à l'écran de sélection jusqu'au retrait de `baseDamage` (§8.3).

### 7.5. La sauvegarde

**Aucune étape de migration : `SaveMigrator.currentVersion` reste à 2.** Avant la `1.0.0`, une sauvegarde
n'a pas à survivre à un changement de version (spec de P-49, N6).

| Écrit avant le lot B | Relu après |
|:---|:---|
| `heroStats.attackPower`, `skillPower`, `alterationPower` | Ignorés : `might`, absent, est lu à 0. **La Puissance accumulée est perdue** |
| `heroStats.mightTargets`, absent | `{attack}`, la valeur par défaut |
| Blob v1 (`attaque`) | Migré en v2 par l'étape du lot A, puis même sort que ci-dessus |

Aucun statut `strength` n'est à relire : les statuts sont vidés à la fin de chaque combat
(`map_progression_manager.dart:37`), avant la sauvegarde. La partie reste jouable. Une partie commencée
avant la partie 2 et rechargée après garde l'orientation `{attack}` jusqu'à sa fin ; ce n'est ni testé ni
annoncé.

### 7.6. Deux parties, deux livraisons

**Partie 1 — La Puissance, à comportement identique.**

- la stat `might`, `effectiveMight`, les statuts `might` et `might_regen`, `GainResource.might`, et le
  retrait de `skillPower` et `alterationPower` ;
- `MightTarget`, `mightTargets` sur `HeroData` et sur `EntityStats`, et `PowerRules` qui la lit ;
- **les trois classes déclarent `["attack"]`** : c'est exactement le jeu d'aujourd'hui, où `skillPower` et
  `alterationPower` valent 0 partout ;
- les `effectType` et `statusId` renommés dans les données, les textes du §7.4 et les libellés abrégés
  des cibles ;
- éditeur de contenu : `mightTargets` déclaré en `enumListKeys` sur le descripteur de classe, ce qui
  ouvre des cases à cocher sans nouveau type de champ (`entity_descriptor.dart:97` ; précédent :
  `eligibleCardTypes`, `:309`), et `["attack"]` au gabarit de classe ; console de debug : le réglage
  `attackPower` devient `might` (`debug_hero_tab.dart:40-43`) ;
- la suppression d'`applyAttackBuff`.

Mesuré le 2026-09-17 par `git grep -l` : les identifiants renommés figurent dans **37 fichiers de `lib/`**
(ARB compris, fichiers générés exclus), **23 de `test/`** et **8 d'`assets/data/`**.

**Critère d'acceptation** : la suite existante reste verte, et seules changent les attentes qui nomment un
identifiant renommé ou un texte du §7.4. Aucun dégât, aucune armure, aucune intensité ne change.

**Partie 2 — L'identité de classe.**

- les orientations du Mage et du Paladin (§7.1) ;
- `statRules`, la conversion d'armure du Berserker et les règles en paramètre obligatoire de
  `StatGains.apply` (§4.1, §7.1) ;
- les neuf passifs, leurs triggers et le hook `lifesteal` (§6) ;
- les stats de départ (§7.3) ;
- les icônes de la Puissance (§7.4).

Chaque partie a son plan, sa branche et sa PR (D4). La partie 1 se vérifie par la suite existante ; la
partie 2 part d'une base renommée et ne teste que l'identité de classe.

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

### 8.2. Partie 2 — Les récompenses conditionnées

#### Conditionnement par la classe — sans objet depuis D9

> [!NOTE]
> **Remplacé le 2026-09-17 par D9.** La conception d'origine scindait *Aiguisage* en trois récompenses,
> une par puissance, filtrées par `statRules`. Avec une seule Puissance que la classe oriente, *Aiguisage*
> reste **une** récompense, « +N Puissance », valable pour toutes les classes et sans filtre. La table de
> tirage garde ses **6 types de stat** (`level_up_reward_service.dart:148`), *Affinité* comprise, et
> *Aiguisage* ses paliers.

#### Conditionnement par le passif — neuf récompenses dédiées

> [!NOTE]
> **Remplacé le 2026-09-16 par la récompense unique *Affinité*** ([spec de P-49](2026-09-16-p49-passifs-partages-design.md), N1). Elle monte la
> Maîtrise, dont chaque passif déclare l'effet ; elle a pris la place de *Forge d'Acier* parmi les 6 types
> de stat. Reste au lot C : ne pas la tirer quand le passif actif ne déclare pas `mastery`. Le texte
> ci-dessous est conservé pour la trace.

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
- **ce que renforce sa Puissance**, généré depuis `mightTargets` dans la forme longue du §7.4, écrite à ce lot, et sa règle de
  stat en clair — « son Armure devient de la Puissance pour un tour » —, **générée à partir de la
  règle**, jamais écrite classe par classe : c'est la règle d'ADR-090, aucun écran ne compare `hero.id` ;
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

- **Les règles viennent de la fonction pure du lot A** (§4.1) et de `PowerRules` : aucune recopie de
  `statRules`, de la maîtrise ou de l'orientation de la Puissance dans `lib/tutorial/`.
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

- le réglage de Puissance, renommé mécaniquement à la partie 1 du lot B (`debug_hero_tab.dart:40-43`),
  gagne le choix des cibles de `mightTargets` ;
- la run affichée expose l'orientation de sa Puissance, ses règles de stat et son passif actif.

**Éditeur de contenu** (P-30 lot 2) :

- **Passifs** : le descripteur suit l'élargissement de `PassiveData` (P7) et valide `classes` comme une
  **liste de références vers des classes existantes**. Le validateur sait aujourd'hui vérifier une
  référence unique ou une liste de valeurs fixes (`lib/services/content_editor/entity_validator.dart`) : la
  liste de références est une extension à écrire. **C'est elle qui garantit qu'un passif créé depuis la
  console ne porte aucune classe mal orthographiée** (§5.2).
- **Classes** : `statRules` est validé — `stat` et `mode` bornés aux vocabulaires du moteur, `to` à une
  cible valide. Sans cela, l'éditeur laisserait écrire `"mode": "convrt"`, exactement le cas qu'il existe
  pour refuser. `mightTargets` l'est dès la partie 1 du lot B (§7.6).
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
| **Deux stats de puissance au lieu de trois** | Le Mage n'aurait plus qu'un axe de build, et `alterationPower` est précisément la stat qui manque au seul archétype sans courbe propre au héros (§4.2). *Dépassé le 2026-09-17 par D9 : une seule Puissance, que la classe oriente ; la variété de build passe par les passifs (R2) et les cartes.* |
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
| **Trois puissances, redirigées par la classe à la lecture** | Plus de choix de build — le Paladin entre Attaques et Compétences, le Mage entre Compétences et altérations —, mais trois nombres pour le joueur, et un « +1 Attaque » qui renforcerait en réalité les altérations d'un Mage : la confusion revient par l'affichage. Écarté par décision du propriétaire (D9). |
| **Convertir les gains de puissance au moment du gain** *(conception du 2026-08-07)* | Tout ce qui défait un gain — le sacrifice d'une relique au Sanctuaire, la fin d'un bonus — doit refaire la conversion, et un statut comme la Force y échappe. Chaque mécanisme futur rouvre la question (§7.1). Écarté par décision du propriétaire (D9). |
| **Étendre `statRules` aux statuts, pour convertir la Force du Mage** | Ne répare qu'un des deux trous, et fait porter à la donnée d'une classe la liste des statuts à convertir (§4.2). Rendu sans objet par D9. |
| **Renommer seulement la Force (`attackPowerTemp`)** | Le code s'éclaire, mais la conversion du Mage et le retrait de relique restent à régler. |
| **Écrire un bonus temporaire dans la stat permanente** | Le plus simple à lire, mais il faut le retirer à coup sûr — fin de durée, fin de combat, mort du héros —, et un seul oubli le rend permanent : le danger qu'écarte R5 (§7.2). La simplicité voulue s'obtient à l'affichage, qui additionne déjà les deux (`player_health_bar.dart:131`). |
| **Nommer la stat Force / Strength** | Le mot le plus répandu dans les textes actuels, mais il évoque le muscle et colle mal au Mage (D10). |
| **Nommer la stat Power, `power` dans le code** | *Power* est le nom anglais du type de carte Pouvoir, et `CardType.power` existe déjà (D10). |
| **Lire l'orientation sur la classe à chaque résolution** | Les lecteurs Flame de `PowerRules` ne tiennent que les stats du héros : il faudrait leur faire passer la classe, et changer les huit appels. Copiée dans les stats, l'orientation n'en change aucun (§7.1). |
| **Livrer le mode `block` de `statRules`** | Son seul usage, les Compétences du Berserker, est devenu une orientation : ce serait du code sans lecteur (§7.1). |

---

## 12. Périmètre et suite

### Dans P-41

- **Lot A** : le point de passage unique des gains, à source étiquetée, la fonction pure de règles, la scission des trois
  puissances, la chaîne de migration sous sa nouvelle clé et son étape v1 → v2, la suppression de la
  chaîne morte `bonusAttack`.
- **Lot B** : partie 1, la Puissance (`might`) à comportement identique ; partie 2, l'orientation de la
  Puissance par classe, `statRules` et la conversion d'armure, les neuf passifs, le hook `lifesteal`, les
  stats de départ.
- **Lot C** : les récompenses data-driven, le filtre d'*Affinité*, l'écran de sélection.
- **Lot D** : la mise à jour fonctionnelle du tutoriel et de la console de debug.

### Dans P-49 — [spec de P-49](2026-09-16-p49-passifs-partages-design.md)

Le modèle des passifs partagés, le point d'accès unique, la refonte de `TraitSystem` en Strategy, la
Maîtrise hybride et sa récompense *Affinité*, l'ADR qui remplace ADR-086 D4. Les triggers `onDamageTaken`
et de comptage passent au lot B ; l'étape de migration v2 → v3 est abandonnée. Frontière : §5.

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
