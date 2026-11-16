# P-53, les charges élémentaires — partie 2 : les animations de rupture — Plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (méthode fixée par l'orchestrateur). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal :** les trois ruptures se voient sans lire — la gangue du Gel (G-a), l'onde du Feu vague par vague (F-a), le halo de la Foudre chargée et son bonus à chaque coup (L-b) —, Flame ne lisant que l'état que la partie 1 livre, complété d'un journal des coups.

**Architecture :** un seul complément d'état, testé, en tête (Task 1) : chaque coup qui reçoit un bonus de Foudre le note sur le défenseur (`EntityStats.chargeHits`, hors sauvegarde, sur le modèle de `lastActionWasCrit`), et le compte rendu de vague perd ses dégâts nominaux. Puis trois tâches Flame sans test automatique (D77) : les états qui durent (gangue, halo) sont des enfants de la carte, posés et retirés par une seule méthode qui compare l'ancienne et la nouvelle piste, commune aux deux chemins d'`EnemyCard` et à `HeroCard` ; l'onde est jouée par `CombatVisualSystem` sur le compte rendu de vague, les voisins retenant leur état jusqu'à l'arrivée de la boule de feu.

**Tech Stack :** Flutter, Flame 1.17 (`Effect`, `ParticleSystemComponent`), Riverpod 2.5 (`Notifier`), `flutter_test`.

**Spec :** `docs/superpowers/specs/2026-11-15-p53-charges-elementaires-design.md` — §10 « Partie 2 », et ce qu'elle couvre : §5.2, §4.10 (le déroulé de Flame), §4.11, les tests manuels marqués 2 de §9.1 (M5, M6, M16), les réponses du propriétaire de §1.2 (P-c : **G-a, F-a, L-b**, maquettes `docs/presentations/2026-11-15_charges_elementaires_maquettes.pptx`, p. 7, 9, 12). Options écartées de la spec : `…-design-verifications.md`. **Ne rouvrir aucun arbitrage de la spec ni du plan de la partie 1.**

Branche : `feat/v0.5.9-p53-charges-elementaires`, sans en créer. Base de tests : **1766** (mesurée le 16/11 sur `9325e082`). Total attendu à la fin : **1772**.

---

## Contraintes globales

Recopiées du fichier d'orchestration (`docs/possible_upgrades/01-10-2026_orchestration_chantier_economie_et_catalogue_Fable5.md` §3.5) ; elles valent pour chaque tâche :

- `dart analyze` rend `No issues found!` et `flutter test` est entièrement vert **à la fin de chaque tâche**.
- Ne rien pousser, n'ouvrir aucune PR, ne rien commiter sur `main`, n'invoquer aucun skill de livraison — ni `finishing-a-development-branch`, ni `patch-notes-writer`, ni `memory-bank-sync`.
- **Jamais `dart format`** ; Write / Edit plutôt que heredoc.
- Les fichiers que `flutter` régénère sont suivis par git — `macos/Flutter/GeneratedPluginRegistrant.swift`, et sous `linux/flutter/` et `windows/flutter/` les `generated_plugin_registrant.*` et `generated_plugins.cmake` : ne jamais indexer leur modification, `git add` **par chemin**, jamais `git add -A` ; les restaurer par `git restore` s'ils apparaissent modifiés.
- Après toute retouche d'un ARB : `flutter gen-l10n`, et les trois `lib/l10n/app_localizations*.dart` régénérés entrent dans le commit (aucune n'est prévue ici).
- Après une suppression ou un déplacement sous `assets/` : supprimer `build/unit_test_assets` avant de croire un `real_bundle_load_test` rouge (aucun n'est prévu ici).
- Tout texte joueur d'un JSON porte `_fr` **et** `_en` ; un id est le nom de son fichier, en `snake_case` ; un dossier neuf sous `assets/` demande `dart run tool/sync_assets.dart`.
- Les trois couches de `CLAUDE.md` ne se mélangent pas : **Flame lit l'état, ne calcule aucune règle**, ne lit aucun provider ; pas de code sans lecteur, pas de code mort, pas de bloc commenté.
- Commits en français, `type(portee): message`, sans accents ni apostrophes, terminés par la ligne `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Ne toucher ni à `assets/data/patch_notes.json`, ni au champ `version:` de `pubspec.yaml`, ni à `site/`.
- **Aucun test d'écran neuf** (D77) : aucun `testWidgets(` ajouté ; les animations passent aux tests manuels (spec §9.1, M5, M6, M16). Seule la Task 1, complément d'état de la partie 1 (spec §10), écrit des tests.
- Animations non bloquantes (`CLAUDE.md`) : `Effect` et `onComplete`, ou `Future.delayed` dans une méthode `async` ; jamais d'attente dans la boucle de jeu. Z-ordre par `priority`.
- Un test qui joue une charge surcharge `chargeCatalogProvider` par `shippedChargeOverride()` (`test/unit/shipped_data.dart`) ; des quatre fichiers de test touchés en Task 1, `multi_hit_test`, `charge_symmetry_test` et `combat_controller_test` le font déjà, `charge_rules_test` lit le catalogue par `shippedChargeCatalog()`.

## Review Focus

Les cinq modes d'échec les plus risqués qu'aucun test ne garde encore. Les tâches Flame n'ont pas de test automatique (D77) : leur garde est le test manuel nommé, complété en Task 5 pour l'agent des tests manuels.

1. **Le bonus par coup sur les trois chemins.** Un coup sur un ennemi passe par `EnemyCard.updateStats` direct (une signature, hors animation de carte) ou différé (`_pendingVisualInstance`, une carte) ; un coup sur le héros, par `HeroCard._applyStats` (`hero_card.dart:172-176`) en phase ennemie. Un chemin oublié n'affiche rien, un chemin doublé affiche deux fois. → **Task 1** garde l'état (tests 3 et 6) ; **Task 2** lit le journal dans `CombatEntity.triggerHitReactions`, que les trois chemins appellent ; garde : **M16-L1 à L3**. Aucun ennemi ne pose de Foudre en `0.5.9`, et la fermeture du tour du joueur (`turn_phase_manager.dart:63-80`, appelée en `:109` ; `charge_rules.dart:330-359`) remet à 0 une Foudre chargée du héros ; mais le tiroir de debug, non modal, reste ouvert : 2 Foudre posées pendant le tour du joueur survivent à la fermeture (sous le seuil, `charge_rules.dart:336`), une 3e posée pendant la phase ennemie, entre deux attaques, charge le héros (`charge_rules.dart:86-100`) — le chemin du héros se voit ainsi sous les trois options de Q-P2.
2. **Le journal des coups perdu ou sauvegardé.** `copyWith`, `takeDamage`, `addStatus`, `tickStatuses` le gardent ; `toJson` ne l'écrit pas ; `clearCombatEffects` le vide. Perdu, un « +6 » ne s'affiche pas ; sauvegardé, il grossit d'une run à l'autre. → **Task 1**, test 2.
3. **Un coup noté à tort** : *Coup de Tonnerre* frappe avant de poser (aucun bonus) ; une cible d'éclaboussure de *Ricochant* note **son** bonus, pas celui de la cible principale. → **Task 1**, tests 4 et 5.
4. **Le voisin figé d'une vague.** Un voisin retient son état jusqu'à l'arrivée de sa boule de feu ; si la boule n'arrive pas (carte retirée, voisin lui-même porteur, voisin mort pendant la vague), ses PV et ses icônes restent ceux d'avant. → **Task 4** (le filet `resolvePendingHits()` après chaque délai de vague) ; garde : **M16-F1** (M6 rejoué : à la fin, 48, 64, 48 lus sur les PV des trois cartes).
5. **Une gangue ou un halo qui survit à son état, ou qui naît deux fois** : gel consommé à l'action perdue, Foudre retombée à la fermeture de phase, « Retirer les charges » du debug ; naissance sur les deux chemins d'`EnemyCard`. → **Tasks 2 et 3**, une seule méthode de transition ; garde : **M16-G1 à G3, M16-L4**.

Les autres trous remontés pour la partie 2 (plan de la partie 1, Review Focus « → partie 2 » ; vérifications de la spec §5 ; compte rendu de vague S6, S10, S11) :

- le bonus par coup sur les deux chemins d'`EnemyCard` et sur le héros chargé (`hero_card.dart:173`) → Review Focus 1 ;
- les dégâts du compte rendu de vague sont nominaux, avant Armure (S6) : aucune animation ne les affiche ; **retirés** en Task 1 ;
- les champs écrits sans lecteur (S11) : `FireResolution.tranches`, `splashes`, `chargeId`, `FireSplash.targetId`, `charge` → lus par F-a (Task 4) ; `FireResolution.damage`, `FireSplash.damage` → retirés (Task 1) ; `ChargeTrack.ruptures` → lu par `HeroCard` (Task 4) ;
- le Feu affiché en vert Poison sur un porteur empoisonné (S10, `combat_entity.dart:181-185`) → Task 4, garde **M16-F2** ;
- `EnemyCard.flameAnimation()` (`enemy_card.dart:358-367`), copie de `buffAnimation` → **retirée** par F-a (Task 4).

## Décisions du plan

Classe T, tranchées par les filtres de §5 du fichier d'orchestration ; les options écartées sont dans le rendu du rédacteur.

- **Q2 — transmettre les coups un à un à Flame** (L-b). **Par l'état : un journal des coups sur le défenseur**, `EntityStats.chargeHits`, une entrée par coup qui reçoit un bonus de Foudre (`ChargeRules.hitBonus` > 0), notée au seul point de passage de chaque coup du héros, `DamageEffectStrategy._strike` (`strategies.dart:97-122`, cartes et signatures), et à l'attaque d'un ennemi (`turn_phase_manager.dart:188-197`) ; Flame affiche les entrées que le nouvel état a de plus que l'ancien, dans `CombatEntity.triggerHitReactions` — le précédent de `lastActionWasCrit` (`entity_stats.dart:28`, lu en `combat_entity.dart:214`). Le journal vit avec le porteur, si bien que les trois chemins de Review Focus 1 le voient sans câblage neuf ; il n'est pas sauvegardé et se vide avec les statuts. *Filtre 5.* Il s'implémente comme un complément de la partie 1, règle, état et test, **en Task 1, avant toute animation** (spec §10).
- **Le compte rendu de vague réduit à ses lecteurs.** `FireResolution.damage` et `FireSplash.damage` disparaissent : nominaux (S6), ils ne s'affichent pas — les chiffres de l'onde sont ceux des réactions aux coups d'aujourd'hui, PV et Armure réels (maquette p. 9, « −36 », `#F87171`). *Filtre 8* (pas de code sans lecteur), puis *6*.
- **`ChargeTrack.ruptures` reste, lu par `HeroCard`** : le Feu du héros se résout sans compte rendu (`ChargeRules.resolveOwnFire`) ; une rupture comptée sur une piste `explode` est le seul fait d'état qui dit qu'une tranche a explosé (`thresholdGrowth: 0` laisse le seuil inchangé). *Filtre 5* (Flame lit une transition d'état, spec §4.11).
- **Les états qui durent sont des enfants de la carte**, posés et retirés à la transition de leur piste par une seule méthode, `CombatEntity.refreshChargeVisuals`, appelée par l'unique méthode d'application d'`EnemyCard` (ses deux chemins) et par `HeroCard._applyStats` ; la transition se lit sur la sorte de la rupture et l'état de la piste, sans catalogue : `skipAction` en attente → gangue (45 %) ; `weakenDealt` actif → gangue pâle (25 %) et givre aux coins ; `amplifyHits` actif → halo. *Filtre 4* (la sorte, pas l'élément), puis *5*.
- **La gangue du héros se voit pendant son tour gelé** (piste `weakenDealt` active), pas pendant l'attente : la spec dit « pendant tout son tour gelé », et la ligne du panneau dit déjà l'attente. *Filtre 6.*
- **Le givre aux coins passe sous les cartes** (`priority` −50, au-dessus du fond à −100) : il ne cache ni la main ni les cartes. *Filtre 6.*
- **Le voisin attend sa boule de feu** par le chemin différé qui existe : `EnemyCard.holdVisualStats()` fait différer `updateStats` comme le fait une carte animée, et l'arrivée de la boule appelle `resolvePendingVisualStats()` ; filet : `HerosDraftGame` appelle `resolvePendingHits()` (idempotent, `heros_draft_game.dart:274-279`) après chaque délai de vague. *Filtre 5*, puis *8*.
- **Le Feu ne se teinte plus du Poison** : `triggerHitReactions` reçoit `fireDamage` ; un ennemi nommé par un compte rendu neuf (porteur ou voisin) et le héros dont le Feu s'est résolu dans la transition le passent à vrai. Chez le héros, un tour qui résout Feu et Poison ensemble s'affiche en Feu. *Filtre 6* (la maquette p. 9 dessine le Feu en rouge).
- **Un éclair par porteur**, quel que soit son nombre de tranches (maquette p. 9, « un seul éclair pour les trois tranches de B ») ; une boule par voisin et par porteur — B, voisin de A et de C, en reçoit deux et s'embrase deux fois. **Un seul « +N 🔥 » par voisin et par vague**, N la somme de ses `FireSplash.charge` dans la vague, à la première arrivée, avec ses dégâts (maquette p. 9 validée par le propriétaire, réponse P-c : « −24 » et « +2 🔥 » sur B en vague 2 ; décision de l'orchestrateur) ; l'émoji lu par `statusEmoji(chargeId)` (*filtre 4* : une future charge `explode` montrerait le sien) ; rien pour N = 0 (voisin mort).
- **Le héros porteur sous le seuil rougeoie** (0,2 s), comme un porteur ennemi sous le seuil : F-a ne dit que « l'éclair seul » pour le héros. *Filtre 6.*
- **Le délai de vague passe à 800 ms** : 0,35 s d'éclair, 0,25 s de boule, puis la pause de 0,2 s (spec §5.2 ; §4.10 disait « environ 600 ms »). *Filtre 6.*
- **Le bonus s'affiche à l'impact, un texte par coup, décalés de 100 ms** ; le total « −N » garde son moment d'aujourd'hui, réglé sur le son de l'impact (`heros_draft_game.dart:251-257`). *Filtre 8.*
- **Le serrement de la gangue** (1 → 0,97 → 1) se joue sur l'échelle de la carte pendant la montée, creux à mi-course (maquette p. 7), en retirant d'abord les `ScaleEffect` en cours comme le font les réactions d'aujourd'hui (`combat_entity.dart:24`, `:52`).

**Q-P2, classe P, ouverte — ce qui s'affiche à chaque coup sous le seuil** (maquettes : `docs/presentations/2026-11-16_charges_elementaires_q-p2_maquettes.pptx`). La réponse du propriétaire dit « le bonus en jaune à chaque coup » ; la maquette de L-b (p. 12) ne dessine que la cible chargée (« +6 ») ; sous le seuil, D86 donne aussi un bonus, +1 par point (*Rafale* sur un ennemi neuf : trois coups à +1). Options :
- **(a)** tout coup qui reçoit un bonus l'affiche ; sous le seuil dans un jaune atténué (`amberAccent`, la couleur de `status:shock`, `effect_icons.json:16`), chargé en jaune vif `#FFEA00` — la couleur dit le doublement ;
- **(b)** seul un coup sur une cible chargée affiche son bonus (la maquette telle quelle) ; sous le seuil, le total d'aujourd'hui seul ;
- **(c)** tout coup qui reçoit un bonus l'affiche, dans le même jaune `#FFEA00`, chargé ou non (la réponse à la lettre).

**Recommandation : (c)** — c'est la réponse à la lettre ; le halo dit déjà qui est chargé, une seconde couleur ne dirait rien de plus ; et la Foudre sous le seuil, celle que *Coup de Tonnerre* prépare, se lit coup par coup. Le plan est écrit pour les trois : sous (a) et (b), `ChargeHit` porte `charged` ; **sous (c), `ChargeHit` ne porte que `bonus`** et les assertions de Task 1 sur `charged` ne s'écrivent pas (Task 1, Step 1 ; Task 2, Step 3).

---

## Carte des fichiers

| Fichier | Responsabilité | Tâches |
|:---|:---|:---:|
| `lib/models/charge_track.dart` | `ChargeHit`, une entrée du journal des coups | 1 |
| `lib/models/entity_stats.dart` | `chargeHits`, hors sauvegarde, vidé par `clearCombatEffects` | 1 |
| `lib/game/systems/charge_rules.dart` | `ChargeRules.noteHit` ; `fireWave` n'écrit plus de dégâts nominaux | 1 |
| `lib/models/fire_wave_report.dart` | `FireResolution` et `FireSplash` sans `damage` | 1 |
| `lib/game/services/effects/strategies.dart`, `lib/game/controllers/combat/turn_phase_manager.dart` | Chaque coup note son bonus, sur l'ennemi et sur le héros | 1 |
| `lib/game/components/entities/combat_entity.dart` | Le bonus par coup ; `refreshChargeVisuals` (halo, gangues, givre) ; `fireDamage` ; `emberFlash` ; `releaseFrost` | 2, 3, 4 |
| `lib/game/components/entities/enemy_card.dart` | Une méthode d'application pour les deux chemins ; `frozenTurnAnimation` ; `holdVisualStats` ; `flameAnimation` retirée | 2, 3, 4 |
| `lib/game/components/entities/hero_card.dart` | Transitions du héros ; son Feu résolu (éclair ou rougeoiement) | 2, 4 |
| `lib/game/components/visual_effects/charge_halo.dart` *(nouveau)* | `ChargeHalo` — L-b | 2 |
| `lib/game/components/visual_effects/frost_shell.dart` *(nouveau)* | `FrostShell`, `FrostVignette` — G-a | 3 |
| `lib/game/components/visual_effects/fire_wave_effects.dart` *(nouveau)* | `FireBurst`, `Fireball` — F-a | 4 |
| `lib/game/systems/combat_visual_system.dart` | `playFireWave` | 4 |
| `lib/game/systems/state_sync_system.dart` | Retenir les voisins, lancer l'onde | 4 |
| `lib/game/components/entities/status_indicator.dart` | `_getEmoji` devient `statusEmoji`, public | 4 |
| `lib/game/heros_draft_game.dart`, `lib/game/game_constants.dart` | L'action perdue de l'ennemi gelé ; le filet des vagues ; les délais | 3, 4 |
| `test/unit/charge_rules_test.dart`, `multi_hit_test.dart`, `charge_symmetry_test.dart`, `combat_controller_test.dart` | Le journal des coups ; le compte rendu sans dégâts | 1 |

---

### Task 1: Le journal des coups et le compte rendu réduit à ses lecteurs — complément de la partie 1

**Files :**
- Modify : `lib/models/charge_track.dart` ; `lib/models/entity_stats.dart:23-48`, `:50-86`, `:168` ; `lib/game/systems/charge_rules.dart:200-208`, `:232-240`, `:255-284`, `:398-415` ; `lib/models/fire_wave_report.dart:3-35` ; `lib/game/services/effects/strategies.dart:112-120` ; `lib/game/controllers/combat/turn_phase_manager.dart:188-197`
- Test : `test/unit/charge_rules_test.dart` (groupe neuf ; `:315-339`, `:420-442`) ; `test/unit/multi_hit_test.dart` (groupe « resolution », `:154`) ; `test/unit/charge_symmetry_test.dart` ; `test/unit/combat_controller_test.dart:646-669`

**Interfaces :**
- Consumes : `ChargeRules.hitBonus(EntityStats defender, ChargeCatalog charges)` (`charge_rules.dart:403`) ; `ChargeTrack`, `ChargeState`, `RuptureKind` ; `RunController.updateHeroStats`.
- Produces :
  - `@immutable class ChargeHit` (dans `charge_track.dart`) : `final int bonus`, `final bool charged` ; `const ChargeHit(this.bonus, {required this.charged})` ; `==` / `hashCode`. **Sous Q-P2 (c)** : `final int bonus` seul, `const ChargeHit(this.bonus)` ;
  - `EntityStats.chargeHits` : `List<ChargeHit>`, constructeur `List<ChargeHit> chargeHits = const []` stocké `List.unmodifiable`, `copyWith({…, List<ChargeHit>? chargeHits})` ; **ni `toJson` ni `fromJson`** ; `clearCombatEffects()` le vide aussi ;
  - `static EntityStats ChargeRules.noteHit(EntityStats defender, ChargeCatalog charges)` : `hitBonus` nul → `defender` elle-même ; sinon une entrée de plus à la fin, `bonus` = `hitBonus`, `charged` = une piste `amplifyHits` de `defender` est `brokenActive` ;
  - `FireSplash({required String targetId, required int charge})` ; `FireResolution({required String bearerId, required String chargeId, required int tranches, required List<FireSplash> splashes})`.

- [ ] **Step 1 : les tests.** Ennemis et héros neufs à 100 PV, catalogue livré.
  - `charge_rules_test.dart`, groupe neuf `les coups` :
    1. `noteHit note le bonus de chaque coup, rien sans Foudre` — sans Foudre : `same(ChargeRules.noteHit(s, catalog), s)` ; 2 Foudre posées par `pose` : `chargeHits == [ChargeHit(2, charged: false)]` ; une Foudre de plus (chargé à 3), puis `noteHit` : `[ChargeHit(2, charged: false), ChargeHit(6, charged: true)]` ;
    2. **(Review Focus 2)** `le journal des coups survit a takeDamage, addStatus, tickStatuses et copyWith ; toJson ne l ecrit pas ; clearCombatEffects le vide` — sur le modèle du test de la piste (`:158-182`) : après chacun, `chargeHits` égale la liste d'avant ; `toJson()` n'a pas de clé `chargeHits` ; `EntityStats.fromJson(stats.toJson()).chargeHits` est vide ; `clearCombatEffects().chargeHits` est vide ;
  - `multi_hit_test.dart`, groupe « resolution » :
    3. **(Review Focus 1)** `Rafale d etincelles note trois coups : +1 sur un ennemi neuf, +6 sur un ennemi a 2 points` — `playShipped('spark_barrage')` : `enemy().chargeHits == List.filled(3, ChargeHit(1, charged: false))` ; sur un ennemi à 2 Foudre posées par la règle (comme `:281-291`) : `List.filled(3, ChargeHit(6, charged: true))` ;
    4. **(Review Focus 3)** `Coup de Tonnerre frappe avant de poser : aucun coup note` — `playShipped('thunder_clap')` sur un ennemi neuf : `enemy().chargeHits` vide, `ChargeRules.points(enemy(), 'shock') == 1` ;
    5. **(Review Focus 3)** `Ricochant : chaque cible eclaboussee note son propre bonus` — `fight([foe(), foe(statuses: [status('shock', 2)]), foe()])`, `playShipped('strike_basic', runes: const ['splash:1'])` sur le premier : `enemy(1).chargeHits == [ChargeHit(2, charged: false)]`, `enemy(0)` et `enemy(2)` sans entrée ;
  - `charge_symmetry_test.dart` :
    6. **(Review Focus 1)** `Foudre du heros chargee : +2 par point, chaque coup ennemi note` — sur le modèle de `:208-217`, `poseOnHero(shock, 3)` : après `resolveEnemyIntent('A')` (attaque 10), le héros perd **16** et `hero().chargeHits == [ChargeHit(6, charged: true)]`.
  - **Sous Q-P2 (c)** : les mêmes tests, `ChargeHit(n)` sans `charged`.
  - Le compte rendu sans dégâts, assertions réécrites, sans test neuf : `charge_rules_test.dart:323-335` → `(bearerId, chargeId, tranches) == ('B', 'test_fire', 1)` et `splashes.map((s) => (s.targetId, s.charge)) == [('A', 1), ('C', 1)]` (les PV restent gardés par `row.map(lost)`, `:318`) ; `:436-439` → `splashes.map((s) => (s.targetId, s.charge)) == [('A', 1)]`, et `lost(row[0]) == 48` (36 en vague 1, puis 12), qui garde les 12 dégâts de A que l'assertion retirée portait ; `combat_controller_test.dart:652-659` → `(bearerId, tranches) == ('B', 3)` et `[('A', 3), ('C', 3)]` (les PV : `:660`).
- [ ] **Step 2 : faire rougir.** `flutter test test/unit/charge_rules_test.dart test/unit/multi_hit_test.dart test/unit/charge_symmetry_test.dart test/unit/combat_controller_test.dart` → échec de compilation (`ChargeHit`, `chargeHits`, `noteHit` absents ; `damage` encore exigé).
- [ ] **Step 3 : l'état.** `ChargeHit`, `EntityStats.chargeHits` et `ChargeRules.noteHit` aux interfaces ci-dessus ; le commentaire du champ dit qu'il ne sert qu'à l'affichage, qu'il grossit le temps d'un combat et que `clearCombatEffects` le vide. `FireResolution` et `FireSplash` perdent `damage` ; leurs commentaires ne parlent plus de dégâts — celui de `FireSplash` (`fire_wave_report.dart:3-4`) que du Feu reçu, celui de `FireResolution` (`:18-19`, « les dégâts qu'il prend ») que de ses tranches et de ce que ses explosions posent. `fireWave` cesse de les écrire (`charge_rules.dart:272-276`, `:278-284`), et le record `blasts` perd ses champs `selfDamage` et `splashDamage` (`:200-208`, `:232-240`), sans lecteur une fois `damage` retiré ; les calculs locaux qui alimentent `hits` (`resolved.selfDamage`, `:219` ; la variable `splashDamage`, `:228-231`) restent.
- [ ] **Step 4 : noter chaque coup.** `_strike` : la cible prend `ChargeRules.noteHit(enemy.stats, charges).takeDamage(…)` au lieu de `enemy.stats.takeDamage(…)` — le bonus se lit sur l'état d'avant le coup, celui que lit le pipeline. `resolveEnemyIntent`, branche `attack` : le catalogue lu une fois (il l'est déjà en `:193`), `runController.updateHeroStats((s) => ChargeRules.noteHit(s, charges))` avant `runController.takeDamage(dmg, isCrit: isCrit)`.
- [ ] **Step 5 : vérifier.** `flutter test` sur les quatre fichiers → vert ; `git grep -n "damage" -- lib/models/fire_wave_report.dart` → rien ; `dart analyze` → `No issues found!` ; `flutter test` → **1772** (1766 + 6).
- [ ] **Step 6 : commit.** `feat(p53): chaque coup note son bonus de Foudre, le compte rendu sans degats nominaux`.

### Task 2: L-b — le halo et le bonus à chaque coup

**Files :**
- Create : `lib/game/components/visual_effects/charge_halo.dart`
- Modify : `lib/game/components/entities/combat_entity.dart:155-251` ; `lib/game/components/entities/enemy_card.dart:244-269` ; `lib/game/components/entities/hero_card.dart:172-176`
- Test : aucun neuf (D77) ; `test/unit/heros_draft_game_targeting_test.dart`, `test/unit/flame_image_prefix_test.dart` lancés

**Interfaces :**
- Consumes : `EntityStats.chargeHits`, `ChargeHit` (Task 1) ; `ChargeTrack.state`, `ChargeTrack.rupture.kind`.
- Produces :
  - `class ChargeHalo extends PositionComponent` : `ChargeHalo({required Vector2 size})` (la taille de la carte) ; `static const Color color = Color(0xFFFFEA00)` ; naissance 0,2 s (opacité 0 → 1), puis pulsation de période 0,6 s, creux à 35 % (maquette p. 11) ; un contour flou autour de la carte, sans éclair, sans étincelle ; `void fadeOut()` — fondu de 0,2 s puis retrait ;
  - `void CombatEntity.refreshChargeVisuals(EntityStats oldStats, EntityStats newStats)` — pour cette tâche, une piste `amplifyHits` `brokenActive` qui apparaît pose un `ChargeHalo` enfant de la carte (`priority` au-dessus du sprite) ; qui disparaît, `fadeOut()` ;
  - `static const int CombatEntity.chargeHitStaggerMs = 100` ;
  - `void EnemyCard._applyInstance(EnemyInstance next)` — l'unique application d'un état : `triggerHitReactions`, `refreshChargeVisuals`, `instance = next`, badges, indicateurs ; appelée par la branche directe d'`updateStats` et par `resolvePendingVisualStats`.

- [ ] **Step 1 : `ChargeHalo`**, aux valeurs de spec §5.2 (L-b) et de la maquette p. 12 ; rendu dans `render`, pulsation dans `update`, comme la lueur de sélection d'`EnemyCard` (`enemy_card.dart:319-342`).
- [ ] **Step 2 : un seul chemin d'application.** `EnemyCard._applyInstance` remplace les deux copies d'aujourd'hui (`:254-257`, `:263-266`) ; `HeroCard._applyStats` appelle `refreshChargeVisuals(stats, newStats)` après `triggerHitReactions` et avant `stats = newStats`.
- [ ] **Step 3 : le bonus à chaque coup.** Dans `triggerHitReactions` (`combat_entity.dart:176`) : si `newStats.chargeHits` est plus long que `oldStats.chargeHits`, chaque entrée au-delà de l'ancienne longueur fait naître un `FloatingText` `'+${hit.bonus}'`, la k-ième après `k × chargeHitStaggerMs`, au-dessus de la carte, décalées horizontalement pour ne pas se recouvrir ; le « −N » d'aujourd'hui ne change ni de texte ni de moment. Une longueur plus courte (un combat neuf, `clearCombatEffects`) n'affiche rien. Couleur et filtre **selon Q-P2** : (a) `charged` → `ChargeHalo.color`, sinon `Colors.amberAccent` ; (b) seules les entrées `charged`, en `ChargeHalo.color` ; (c) toutes, en `ChargeHalo.color`.
- [ ] **Step 4 : vérifier.** `flutter test test/unit/heros_draft_game_targeting_test.dart test/unit/flame_image_prefix_test.dart` → vert ; `dart analyze` → `No issues found!` ; `flutter test` → **1772**, sans test neuf ; `git diff main -- test | grep -c '^+.*testWidgets('` → `0`.
- [ ] **Step 5 : commit.** `feat(p53): le halo de la Foudre chargee et son bonus a chaque coup`.

### Task 3: G-a — la gangue de l'ennemi gelé et du héros gelé

**Files :**
- Create : `lib/game/components/visual_effects/frost_shell.dart`
- Modify : `lib/game/components/entities/combat_entity.dart` (`refreshChargeVisuals`) ; `lib/game/components/entities/enemy_card.dart` ; `lib/game/heros_draft_game.dart:405-411` ; `lib/game/game_constants.dart:9-16`, `:60-76`

**Interfaces :**
- Consumes : `refreshChargeVisuals` (Task 2) ; `EnemyInstance.skippingCharge` (`String?`) ; `EnemyCard._brokenNameOf` (`enemy_card.dart:241-242`).
- Produces :
  - `class FrostShell extends PositionComponent` : `FrostShell({required Vector2 size, required double opacity})` ; `static const Color veilColor = Color(0xFF81D4FA)`, `static const double enemyOpacity = 0.45`, `heroOpacity = 0.25` ; à la pose, le voile, bordé d'un liseré blanc, monte du bas vers le haut en 0,4 s ; `void shatter()` — six à huit éclats blancs et bleu clair projetés autour de la carte en 0,4 s, puis retrait ; `void fadeOut()` — fondu de 0,2 s puis retrait ;
  - `class FrostVignette extends PositionComponent` : un givre `veilColor` aux quatre coins de l'écran, à la taille du jeu (`onGameResize`) ; fondu d'entrée de 0,3 s ; `void fadeOut()` ;
  - `CombatEntity.refreshChargeVisuals`, complétée : une piste `skipAction` `brokenPending` qui apparaît → `FrostShell(opacity: enemyOpacity)` enfant de la carte, et le serrement (échelle de base × 1 → 0,97 → 1, sur les 0,4 s de la montée, creux à mi-course) ; qui disparaît → `fadeOut()` de la gangue **si elle est encore tenue** ; une piste `weakenDealt` `brokenActive` qui apparaît → `FrostShell(opacity: heroOpacity)` et une `FrostVignette` ajoutée au jeu ; qui disparaît → `fadeOut()` des deux ;
  - `FrostShell? CombatEntity.releaseFrost()` — cesse de tenir la gangue et la rend (nulle s'il n'y en a pas) ; la gangue reste affichée, mais aucune transition ne la retrouve plus ;
  - `void EnemyCard.frozenTurnAnimation()` — **d'abord** `releaseFrost()`, puis trois secousses en 0,3 s, puis `shatter()` de la gangue rendue (si elle n'est pas nulle), et le nom de l'état rompu de `instance.skippingCharge` (« Gelé ») en `FloatingText` couleur `FrostShell.veilColor` au-dessus de la carte ;
  - `GameConstants.combatDelayFrozenShakeMs = 300`, `GameConstants.priorityFrostVignette = -50`.

- [ ] **Step 1 : `FrostShell` et `FrostVignette`**, aux valeurs de spec §5.2 (G-a) et de la maquette p. 7.
- [ ] **Step 2 : les transitions** dans `refreshChargeVisuals` (interfaces ci-dessus). `frozenTurnAnimation()` cesse de tenir la gangue **dès son début**, avant les secousses : l'état consommé s'applique à la frame qui suit `onResolveEnemyIntent` (`state_sync_system.dart:35-38`), à peu près à la fin des secousses, avant ou après selon les frames (Step 3 attend `combatDelayFrozenShakeMs`, 300 ms), et le passage « en attente » → « aucun » ne trouve alors plus de gangue tenue à faire fondre, quel que soit l'ordre des frames ; la gangue rendue se brise à la fin des secousses.
- [ ] **Step 3 : l'action perdue.** `_enemyRipostePhase`, branche `enemy.skipsAction` (`heros_draft_game.dart:405-411`) : `enemy.frozenTurnAnimation()`, délai `combatDelayFrozenShakeMs`, puis `onResolveEnemyIntent(enemy.id)` et le délai `combatDelayAfterIntentResolveMs` d'aujourd'hui ; toujours **avant** le test `intent == null` (A13).
- [ ] **Step 4 : vérifier.** `flutter test test/unit/heros_draft_game_targeting_test.dart test/unit/flame_image_prefix_test.dart` → vert ; `dart analyze` → `No issues found!` ; `flutter test` → **1772**, sans test neuf.
- [ ] **Step 5 : commit.** `feat(p53): la gangue du Gel, sur l ennemi et sur le heros`.

### Task 4: F-a — l'onde, vague par vague

**Files :**
- Create : `lib/game/components/visual_effects/fire_wave_effects.dart`
- Modify : `lib/game/systems/combat_visual_system.dart:6-24` ; `lib/game/systems/state_sync_system.dart:8`, `:20-22`, `:132-165` ; `lib/game/components/entities/enemy_card.dart:250-269`, `:358-367` ; `lib/game/components/entities/hero_card.dart:147-176` ; `lib/game/components/entities/combat_entity.dart:176-185` ; `lib/game/components/entities/status_indicator.dart:123`, `:143`, `:226` ; `lib/game/heros_draft_game.dart:392-397` ; `lib/game/game_constants.dart:69-70`

**Interfaces :**
- Consumes : `FireWaveReport`, `FireResolution` (`bearerId`, `chargeId`, `tranches`, `splashes`), `FireSplash` (`targetId`, `charge`) (Task 1) ; `ChargeTrack.ruptures` ; `ChargeRules.points` ; `HerosDraftGame.resolvePendingHits()`.
- Produces :
  - `class FireBurst extends PositionComponent` : `FireBurst({required Vector2 position, required double radius, void Function()? onComplete})` ; `static const Color core = Color(0xFFFF6D00)`, `edge = Color(0xFFFFAB40)`, `static const double seconds = 0.35` ; un éclair radial qui s'ouvre jusqu'à `radius` et s'efface, puis `onComplete` et retrait ;
  - `class Fireball extends PositionComponent` : `Fireball({required Vector2 from, required Vector2 to, required void Function() onArrive})`, `static const double seconds = 0.25` ;
  - `void CombatEntity.emberFlash()` — une teinte `FireBurst.core` sur le sprite, 0,2 s (le rougeoiement, l'embrasement) ;
  - `CombatEntity.triggerHitReactions(EntityStats oldStats, EntityStats newStats, {bool suppressArmorChange = false, bool fireDamage = false})` — `fireDamage` vrai : jamais la teinte ni le texte du Poison ;
  - `EnemyCard.updateStats(EnemyInstance next, {bool fireDamage = false})` (le drapeau suit l'état retenu jusqu'à son application) ; `void EnemyCard.holdVisualStats()` — `updateStats` diffère tant qu'il tient, comme sous `game.isCardAnimating` ; `resolvePendingVisualStats()` le relâche ; `flameAnimation()` disparaît ;
  - `void EnemyCard._applyInstance(EnemyInstance next, {bool fireDamage = false})` — la méthode de Task 2 gagne le drapeau, qu'elle passe à `triggerHitReactions` ;
  - `void CombatVisualSystem.playFireWave(FireWaveReport report)` ;
  - `String statusEmoji(String id)` (`_getEmoji` rendu public, ses deux appels suivent) ;
  - `GameConstants.combatDelayFireWaveMs = 800` (600 aujourd'hui) ; son commentaire cite la spec §5.2 (0,6 s d'animation, 0,2 s de pause).

- [ ] **Step 1 : `FireBurst`, `Fireball`, `emberFlash`**, aux valeurs de spec §5.2 (F-a) et de la maquette p. 9.
- [ ] **Step 2 : `playFireWave`.** Pour chaque résolution, la carte du porteur (`bearerId`) : `tranches ≥ 1` → `FireBurst` centré sur elle, rayon `1,5 × size.x × scale.x` ; à sa fin, une `Fireball` vers chaque voisin de `splashes`, dont l'arrivée appelle sur le voisin `resolvePendingVisualStats()` (ses dégâts, par les réactions d'aujourd'hui) et `emberFlash()` ; **à la première arrivée sur un voisin dans la vague seulement**, si N > 0, un `FloatingText` `'+N ${statusEmoji(chargeId)}'` en `FireBurst.edge`, N la somme des `charge` de ses `FireSplash` dans tout le compte rendu (B en vague 2 de l'exemple : « −24 » et « +2 🔥 » à la première boule, l'embrasement seul à la seconde) ; `tranches == 0` → `emberFlash()` du porteur seul. Une carte absente est sautée. Aucune attente : les enchaînements passent par `onComplete` et `onArrive`.
- [ ] **Step 3 : `StateSyncSystem`.** Un compte rendu neuf (`!identical(report, _lastFireWaveReport)`, comme aujourd'hui) : **avant** la boucle de mise à jour (`:132-147`), `holdVisualStats()` sur la carte de chaque `targetId` ; dans la boucle, `updateStats(instance, fireDamage: true)` pour toute carte nommée par le compte rendu (porteur ou voisin) ; après, `game.combatVisualSystem?.playFireWave(report)` à la place des `flameAnimation()` (`:155-165`). Un porteur, non retenu, montre ses dégâts au début de l'éclair ; un voisin, à l'arrivée de sa boule. **Un porteur qui est aussi voisin** (deux porteurs adjacents, la vague simultanée de la spec A11) : la retenue prime — ses dégâts, les siens et ceux de l'explosion voisine, s'affichent ensemble à l'arrivée de la première boule, et le filet de Step 4 les relâche si elle n'arrive pas ; aucune règle de plus.
- [ ] **Step 4 : le filet.** `_enemyRipostePhase` (`heros_draft_game.dart:392-397`) : après chaque délai `combatDelayFireWaveMs`, `resolvePendingHits()` puis `onResolveFireWave()` — aucun état retenu ne survit à sa vague, ni n'atteint `onResolveEnemyStatuses()`.
- [ ] **Step 5 : le héros porteur.** `HeroCard._applyStats` : pour chaque piste `explode` présente dans l'ancien et le nouvel état, `ruptures` qui monte → `FireBurst` centré sur le héros (l'éclair seul, sans boule) ; sinon, des points de cette charge qui tombent à 0 → `emberFlash()` ; l'un ou l'autre → `fireDamage: true` à `triggerHitReactions`. Le retrait de debug, qui vide les pistes, ne déclenche rien.
- [ ] **Step 6 : vérifier.** `git grep -n "flameAnimation\|_getEmoji" -- lib` → rien ; `flutter test test/unit/heros_draft_game_targeting_test.dart test/unit/flame_image_prefix_test.dart` → vert ; `dart analyze` → `No issues found!` ; `flutter test` → **1772**, sans test neuf.
- [ ] **Step 7 : commit.** `feat(p53): l onde du Feu vague par vague, le Feu ne se teinte plus du Poison`.

### Task 5: La vérification finale

**Files :** aucun, sauf correction d'un écart trouvé ici (dans la tâche fautive, recommitée).

- [ ] **Step 1 : l'analyse et les tests.** `dart analyze` → `No issues found!` ; `flutter test` → `+1772: All tests passed!`.
- [ ] **Step 2 : les contrôles de spec §11**, inchangés depuis la partie 1 : `git grep -n -E "(s|status)\.id [!=]= '(burn|freeze|shock)'" -- lib` → rien ; `git grep -n "ProportionalStatus.freeze" -- lib test` → rien ; `git diff main -- test | grep -c '^+.*testWidgets('` → `0` ; `dart run tool/sync_assets.dart --check` → code 0.
- [ ] **Step 3 : les lecteurs et les couches.** `git grep -n "chargeHits" -- lib/game/components` → `combat_entity.dart` ; `git grep -n "\.ruptures" -- lib/game/components` → `hero_card.dart` ; `git grep -n -E "\.(tranches|splashes|chargeId|targetId|charge)\b" -- lib/game/systems/combat_visual_system.dart` → au moins une ligne **par champ** (`tranches`, `splashes`, `chargeId`, `targetId`, `charge`) ; `git grep -n "\.targetId" -- lib/game/systems/state_sync_system.dart` → au moins une ligne ; `git grep -n "damage" -- lib/models/fire_wave_report.dart` → rien ; `git grep -n -E "flutter_riverpod|chargeCatalogProvider" -- lib/game/components lib/game/systems/combat_visual_system.dart lib/game/systems/state_sync_system.dart` → rien ; `git status --short` ne montre aucun fichier de plateforme généré indexé, ni `patch_notes.json`, ni `site/`, ni la ligne `version:` de `pubspec.yaml`.
- [ ] **Step 4 : à recopier pour l'agent des tests manuels — M16 détaillé** (spec §9.1, M5, M6, M16 ; les chiffres sont ceux de la spec, sans Puissance) :
  - **M16-G1** (M1) : au second *Trait de Glace*, la gangue bleue monte du bas en ~0,4 s, la carte se serre à peine ; elle reste tout le tour du joueur ;
  - **M16-G2** (M2) : à son action, l'ennemi gelé ne fonce pas ; sa carte tremble trois fois, la gangue éclate en six à huit éclats, « Gelé » flotte ; au tour d'après, aucune gangue ;
  - **M16-G3** (M9) : héros gelé par le debug — rien de neuf pendant l'attente ; à son tour gelé, gangue pâle sur sa carte et givre aux quatre coins, sous les cartes de la main ; au tour d'après, l'un et l'autre ont disparu ; « Retirer les charges » pendant son tour gelé les retire aussi ;
  - **M16-F1** (M6, Review Focus 4) : trois vagues, l'une après l'autre ; en vague 1, un éclair sur B puis une boule vers A et une vers C, qui s'embrasent, montrent « −36 » et « +3 🔥 » à l'arrivée de leur boule ; en vague 2, deux boules sur B ; en vague 3, B rougeoie seul ; à la fin, 48, 64, 48 de PV perdus **lus sur les cartes**, et aucune carte n'a gardé ses PV d'avant une vague ;
  - **M16-F2** (M5, S10) : *Embrasement* sur l'ennemi du milieu, fin du tour — en vague 1, une tranche : un éclair sur le porteur et « −12 », puis deux boules, chaque voisin s'embrase avec « −12 » et « +1 🔥 » ; en vague 2, les deux voisins rougeoient seuls, « −2 » chacun ; un voisin en intention de Défense voit son Armure absorber (« −N » bleu de l'Armure, P-d) ; un voisin ou un porteur qui porte aussi du Poison montre les dégâts du Feu en rouge, ceux de son Poison en vert, après la chaîne ;
  - **M16-F3** (M10) : le héros à 5 Feu prend un éclair seul et « −16 » au début de son tour ; à 2 Feu, un rougeoiement et « −4 » ;
  - **M16-L1** (M8, chemin différé) : la *Rafale* qui charge la cible fait naître le halo jaune, qui pulse ; trois « +6 » en jaune, décalés, avec « −27 » ;
  - **M16-L2** (chemin direct) : une signature de dégâts (Mage, *Projectile Magique*) sur un ennemi chargé (3 Foudre par le debug) affiche « +6 », sous les trois options de Q-P2 ;
  - **M16-L3** (héros) : 3 Foudre sur le héros par le debug pendant son tour : le halo naît aussitôt sur sa carte et s'éteint au début de la phase ennemie ; au tour suivant, tiroir de debug laissé ouvert, 2 Foudre sur le héros (comme M10), fin du tour : la première attaque ennemie affiche « +2 » sous Q-P2 (a) et (c), rien de plus sous (b) ; avant une attaque suivante, une 3e Foudre par le debug : le halo naît sur sa carte, chaque attaque qui suit affiche « +6 » sous les trois options, et le halo s'éteint à la fin de la phase ennemie (`turn_phase_manager.dart:155`) ;
  - **M16-L4** : le halo d'un ennemi chargé, et celui du héros chargé pendant son tour, s'éteignent au début de la phase ennemie ; celui du héros chargé pendant la phase ennemie, à sa fin (M16-L3) ;
  - **M16-L5, selon Q-P2** : *Rafale* sur un ennemi neuf — (a) trois « +1 » en jaune atténué ; (b) aucun bonus affiché ; (c) trois « +1 » en jaune.
- [ ] **Step 5 : rendre** à l'orchestrateur le total de tests, la sortie de `dart analyze`, la liste des commits de la partie (depuis le commit qui ajoute ce plan) et toute décision prise en cours d'exécution.
