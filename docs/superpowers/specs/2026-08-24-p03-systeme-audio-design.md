# P-03 — Système audio — Conception

Date : 2026-08-24
Statut : **Design validé, non implémenté**
Chantier ROADMAP : **P-03** — Tier S, dernier chantier ouvert du Jalon 1 « Socle »
Sources amont :
- Audit animations & juice du 2026-07-25, §J1 « Audio — absent à 100 % » et item 13 du plan d'action
- `docs/ROADMAP.md` §2, fiche P-03

> **Le chantier n'est pas « ajouter des sons », c'est « installer un moteur qui tourne sans eux ».**
> Le sourcing (~15 bruitages, 4 musiques) est mené en parallèle du code : le jeu tournera plusieurs
> semaines avec un catalogue troué. Une architecture qui traite l'asset manquant comme une exception
> rendrait ces semaines invivables.
>
> Deux décisions structurantes en découlent. **Aucun appelant ne nomme jamais un fichier** — le code
> de jeu déclare un *moment*, jamais un son ; toute la résolution, donc toute la gestion du fichier
> absent, tient dans un seul objet. Et **le catalogue se déclare avant d'exister** : `audio.json`
> est autant le contrat du moteur que la liste de courses du sourcing.

---

## 1. Vérification préalable

Tous les constats ci-dessous ont été vérifiés contre le code le 2026-08-24. Deux d'entre eux
**corrigent la fiche P-03 de la ROADMAP** et sont marqués ⚠️.

| Constat | Vérification |
|:---|:---|
| Aucune dépendance audio | `pubspec.yaml` — ni `flame_audio` ni `audioplayers` |
| Aucun son dans le projet, aucun dossier `assets/audio/` | `pubspec.yaml` ne déclare que `assets/data/` et `assets/images/` |
| ⚠️ **Un seul `// TODO: Audio Hook` subsiste** — et c'est le seul TODO du projet, toutes catégories confondues | `grep -rn "TODO" lib/` → 1 occurrence, `floating_text.dart:166`. La ROADMAP en annonce « des TODO disséminés » : le constat date du 31/07 et est périmé |
| ⚠️ **Aucun écran de réglages n'existe** | `ls lib/ui/screens/` → 17 écrans, aucun `settings_screen.dart`. Le coût de sa création n'est chiffré nulle part |
| `shared_preferences` n'a qu'un seul usage, la sauvegarde de run | `save_service.dart` — clé unique, JSON versionné |
| `GameOverScreen` efface la sauvegarde à la mort du héros | `progress.md` §1, « Fin de run » |
| `triggerHitReactions()` est un entonnoir unique, héros et ennemis confondus | `combat_entity.dart:175`, appelé par `hero_card.dart:136`, `enemy_card.dart:222` et `:236` |
| `gameDataLoaderProvider` est un `FutureProvider<GameDataRegistry>` chargeant tous les JSON au démarrage | `game_data_service.dart:51` |
| `GameDataRegistry` agrège 8 catalogues | `game_data_registry.dart:11-18` |
| La séquence de riposte ennemie est étalée dans le temps (délais successifs) | `heros_draft_game.dart:360` — `_enemyRipostePhase()` |
| Le pattern de couture injectable par provider existe déjà, hérité de P-02 | `deckRandomProvider.overrideWithValue(...)`, `deck_controller_test.dart:190` |
| Les tests surchargent déjà `gameDataLoaderProvider` | `boss_card_draft_screen_test.dart:101` et 7 autres fichiers |
| 295 tests au vert, `dart analyze` sans aucune issue | `flutter test` / `dart analyze`, relevés le 2026-08-24 |
| Le jeu est distribué en **web et Windows** | `site/_site/versions.json`, chaîne de release ADR-079 |

---

## 2. Le problème

L'absence de son n'est pas le problème à résoudre — c'est le symptôme. Le problème tient en trois
contraintes qui, prises ensemble, excluent l'implémentation naïve.

**Le son doit arriver avant les fichiers.** Le sourcing est mené en parallèle. Un moteur qui suppose
ses assets présents produirait, pendant toute la durée du chantier, un jeu qui plante ou qui inonde
la console — donc un jeu qu'on cesse de lancer, donc un chantier qu'on cesse de tester.

**Le moment du déclenchement décide de la synchronisation.** La séquence d'effets de combat est
explicitement étalée dans le temps (`_enemyRipostePhase`, délais dégressifs, `Future.delayed`).
L'état change à l'instant T, l'animation correspondante joue à T+300 ms. Brancher le son sur le
*changement d'état* — ce que ferait un bus d'événements — produirait un son systématiquement en
avance sur son image.

**Le mapping ne peut pas vivre dans le code.** Le projet est piloté à 100 % par la donnée : ajouter
une carte n'exige aucune ligne de Dart. Un catalogue d'événements codé en dur ferait de l'audio la
seule exception à cette règle, et rendrait impossible de donner un son propre à une carte sans
recompiler.

---

## 3. Décisions retenues

| # | Décision | Motif |
|:---|:---|:---|
| **D1** | Un **directeur central** (`AudioDirector`) est le seul point d'entrée. Le code de jeu déclare un moment, jamais un fichier ni un volume | Concentre la résolution — donc la gestion de l'asset absent — dans un seul objet |
| **D2** | Le mapping moment → son est une **donnée** (`assets/data/audio.json`), avec une chaîne de repli à 4 niveaux | Cohérence avec le reste du projet ; un son par carte sans une ligne de Dart |
| **D3** | Les appels se posent **aux points d'animation**, pas aux changements d'état | Synchronisation son/image juste par construction |
| **D4** | `SilentAudioBackend` est le **défaut** ; `main.dart` est le seul endroit qui branche `FlameAudioBackend` | Les 295 tests existants restent muets sans qu'aucun ne soit modifié |
| **D5** | **L'audio ne peut jamais casser ni ralentir le jeu.** Fichier absent, JSON malformé, backend en échec → dégradation silencieuse | Asymétrie assumée avec `SaveService`, qui échoue durement : une sauvegarde corrompue est une perte de données, un son absent est cosmétique |
| **D6** | Les réglages vivent dans une **clé `shared_preferences` distincte**, indépendante de `SaveService` | `GameOverScreen` efface la sauvegarde : le volume ne doit pas mourir avec le héros |
| **D7** | Le catalogue est **déclaré avant d'exister**, gardé par deux garde-fous **asymétriques** : un test bloquant sur la cohérence des identifiants, un rapport non bloquant sur les fichiers absents | Le premier attrape les fautes de frappe, le second est le tableau de bord du sourcing et ne doit jamais rougir la CI |
| **D8** | **Pas de bus d'événements de jeu** | Il émettrait au changement d'état, donc en avance sur l'image (cf. §2). Le corriger imposerait d'émettre depuis la séquence d'animation, ce qui n'est plus qu'une indirection par-dessus D3. Le bus vaudra son coût quand un second abonné existera — historique des runs (P-11), vibrations, succès |

---

## 4. Architecture cible

```
lib/services/audio/
├── audio_backend.dart          ← interface : preload / playOnce / playLoop / stopLoop / setVolume
├── flame_audio_backend.dart    ← SEULE implémentation important flame_audio
├── silent_audio_backend.dart   ← no-op complet (défaut)
├── audio_director.dart         ← résolution moment → son → backend
├── music_conductor.dart        ← machine à états de la musique de fond
└── audio_settings.dart         ← AudioSettingsNotifier (Riverpod) + AudioSettings

lib/services/settings_service.dart   ← persistance des préférences (clé dédiée)
lib/models/data/audio_data.dart      ← modèle 1:1 de assets/data/audio.json
lib/ui/screens/settings_screen.dart  ← curseurs + coupure
```

**Emplacement : `lib/services/audio/`, et non `lib/game/services/`** comme le suggérait l'audit du
25/07. Le son est appelé aussi bien depuis le combat Flame que depuis des écrans purement Flutter
(accueil, boutique, draft). `lib/game/services/` héberge de la logique de jeu (`damage_pipeline`,
`effect_resolver`) ; `lib/services/` héberge l'infrastructure transverse (`save_service`,
`game_data_service`). L'audio est de la seconde famille. Écart assumé au diagnostic amont.

**Interface publique du directeur** — deux méthodes, et rien d'autre :

```dart
void onMoment(GameMoment moment, {Object? source});
void onScene(MusicScene scene);
```

**Providers.** `AudioDirector` ne porte aucun état métier : c'est un `Provider<AudioDirector>`, pas
un `Notifier`. Les réglages, eux, sont de l'état partagé : `AudioSettingsNotifier extends
Notifier<AudioSettings>`, exposé par `NotifierProvider` — conforme à la règle `CLAUDE.md`.

```dart
final audioBackendProvider = Provider<AudioBackend>((ref) => const SilentAudioBackend());
final audioDirectorProvider = Provider<AudioDirector>(...);
final audioSettingsProvider = NotifierProvider<AudioSettingsNotifier, AudioSettings>(...);
```

### 4.1 Comment la couche Flame atteint le directeur

`HerosDraftGame` **n'a aucun accès à Riverpod** — vérifié le 2026-08-24 : la classe est découplée
par quinze callbacks injectés depuis `GameScreen` (`game_screen.dart:243`). Un composant Flame ne
peut donc pas lire `audioDirectorProvider`.

Le directeur est **injecté comme collaborateur**, pas lu comme provider : `HerosDraftGame` gagne un
champ `final AudioDirector audio;`, que `GameScreen` remplit par `ref.read(audioDirectorProvider)`
au moment de la construction. Les entités l'atteignent par `game.audio`, `CombatEntity` disposant
déjà de `HasGameReference<HerosDraftGame>` (`combat_entity.dart:11`).

C'est un champ plutôt qu'un seizième callback : un callback par moment de jeu ferait exploser un
constructeur déjà large, et le directeur est précisément l'objet conçu pour être appelé directement.
La règle `CLAUDE.md` — les composants Flame ne lisent jamais l'état Riverpod — est respectée : la
lecture du provider a lieu dans la couche UI, Flame ne reçoit qu'une référence.

**La couture de test, et pourquoi elle est gratuite.** `audioBackendProvider` vaut
`SilentAudioBackend` **par défaut**, et `main.dart` le surcharge par `FlameAudioBackend` au
démarrage de l'application réelle. C'est l'inverse du réflexe habituel (défaut réel, surcharge en
test), et c'est délibéré : le défaut réel aurait imposé de toucher 51 fichiers de test pour que
`flutter test` reste muet.

---

## 5. Le contrat de données

`assets/data/audio.json`, chargé par `gameDataLoaderProvider` (`game_data_service.dart:51`) et
exposé dans `GameDataRegistry` comme les huit catalogues existants.

```json
{
  "schemaVersion": 1,
  "sounds": {
    "impact_normal":   { "file": "sfx/impact_normal.mp3", "volume": 0.8, "variants": 3 },
    "impact_crit":     { "file": "sfx/impact_crit.mp3",   "volume": 1.0 },
    "card_play_fire":  { "file": "sfx/card_play_fire.mp3" }
  },
  "moments": {
    "card_play":  { "default": "card_play_generic",
                    "byAnimation": { "fire": "card_play_fire", "ice": "card_play_ice" } },
    "impact":     { "default": "impact_normal" },
    "turn_start": { "default": "turn_start" }
  },
  "music": {
    "menu":   { "file": "music/menu.mp3" },
    "map":    { "file": "music/map.mp3" },
    "combat": { "file": "music/combat.mp3" },
    "boss":   { "file": "music/boss.mp3" }
  }
}
```

`audio.json` ne contient **aucun texte destiné au joueur** : la règle bilingue `_fr`/`_en` de
`CLAUDE.md` ne s'y applique pas. Les libellés de l'écran de réglages, eux, passent par les ARB
(§8).

### 5.1 La chaîne de repli

Pour `onMoment(GameMoment.cardPlay, source: carte)` :

1. champ `sfx` de la carte dans `cards.json` — **nouveau champ optionnel**
2. sinon `moments.card_play.byAnimation[carte.animation]` — réutilise le champ `animation` existant
3. sinon `moments.card_play.default`
4. sinon → **silence**, sans erreur

Les moments systémiques (début de tour, pioche, mana insuffisante, survol) n'ont pas de `source` et
atterrissent directement au niveau 3. Le champ `sfx` optionnel est ajouté au même titre à
`CardData`, `EnemyData` et `RelicData` ; les modèles correspondants de `lib/models/data/` sont mis à
jour, `null` par défaut, aucune migration de contenu nécessaire.

`variants: N` déclare N fichiers numérotés (`impact_normal_1.mp3` … `_3.mp3`) tirés au hasard à
chaque lecture, pour casser la répétition sur les sons les plus fréquents. Le champ est **optionnel
et vaut 1 par défaut** : le mécanisme existe, le sourcing décide s'il s'en sert.

### 5.2 Format des fichiers

**MP3**, 44,1 kHz — mono pour les bruitages, stéréo pour la musique. Pas d'OGG malgré son avantage
de taille : Safari ne le lit pas de façon fiable et le jeu est distribué en web. Bruitages courts
(< 1,5 s) ; musiques bouclables proprement.

`pubspec.yaml` déclare `assets/audio/` ; les chemins de `audio.json` sont relatifs à ce dossier.

---

## 6. Les moments de jeu et leurs points d'appel

| Moment | Point d'appel |
|:---|:---|
| `impact` · `impactCrit` · `armorHit` · `heal` | **`combat_entity.dart:175`** — `triggerHitReactions()` |
| `cardHover` | `heros_draft_game.dart:89` — `setHoveredCard()` |
| `cardPickup` · `cardPlay` | `card_animator.dart` |
| `enemyAttack` | `heros_draft_game.dart:360` — `_enemyRipostePhase()`, avant `dashAnimation()` |
| `enemyDeath` | `heros_draft_game.dart:220` — `resolvePendingDeaths()` |
| `turnStart` · `turnEnd` | `TurnPhaseManager` · `executeTurn()` (`heros_draft_game.dart:297`) |
| `cardDraw` | `DeckNotifier.drawCards()` (`deck_controller.dart`) |
| `manaGain` | `GainManaEffectStrategy` (`strategies.dart:94`) |
| `insufficientMana` | **Deux sites** : `effect_resolver.dart:99` (refus de carte) et `player_stats_manager.dart:438` (refus de compétence) |

**`triggerHitReactions()` est un entonnoir unique**, appelé aussi bien par `hero_card.dart:136` que
par `enemy_card.dart:222` et `:236`. **Quatre des quinze moments — ceux de l'impact, les plus
importants — se branchent en un seul endroit**, héros et ennemis couverts d'un coup.

Le diagnostic amont, qui annonçait ~15 hooks à disséminer, surestimait la dispersion réelle : les
quinze moments se posent dans **huit fichiers** — `combat_entity.dart`, `heros_draft_game.dart`
(quatre sites), `card_animator.dart`, `turn_phase_manager.dart`, `deck_controller.dart`,
`strategies.dart`, `effect_resolver.dart` et `player_stats_manager.dart`.

---

## 7. Musique

`MusicConductor` traduit une **scène** en piste, et rien d'autre. Quatre scènes pour quatre pistes :

| Scène | Écrans |
|:---|:---|
| `menu` | Accueil, Réglages, Notes de version, Dictionnaire, Sélection de classe |
| `map` | Carte du monde, Boutique, Événement, Repos, Forge, Échange de reliques |
| `combat` | Combat standard et élite |
| `boss` | Combat de boss |

**Transition** : fondu enchaîné de 400 ms. **Une scène déjà active est un no-op** — naviguer
Accueil → Notes de version → Accueil ne redémarre pas la musique. C'est le détail qui sépare une
bande-son d'un hoquet.

**Déverrouillage autoplay (web).** Les navigateurs bloquent tout audio avant un geste utilisateur.
Le directeur démarre donc dans l'état `locked` sur web ; un `Listener` unique à la racine de l'arbre
de widgets (`main.dart`) capte le premier pointeur, appelle `unlock()` et démarre la scène en
attente. **Les sons demandés pendant le verrouillage sont abandonnés, jamais mis en file** — une
file produirait une salve de sons périmés au déverrouillage. Sur Windows, l'état `locked` n'existe
pas.

---

## 8. Réglages et persistance

**`SettingsScreen`**, accessible depuis `HomeScreen` : trois curseurs (général, bruitages, musique)
et un interrupteur de coupure globale. Volume effectif = `général × catégorie` ; la coupure prime
sur les deux.

**`SettingsService`** — clé `shared_preferences` dédiée, JSON versionné (`schemaVersion`),
**indépendante de `SaveService`** (D6). Contrairement à `SaveService`, un JSON illisible ou une
version inconnue **retombe silencieusement sur les valeurs par défaut** : perdre son réglage de
volume ne justifie pas un écran d'erreur.

**Coupure en jeu** : une icône dans le HUD de `GameScreen`. Elle rejoint un groupe de contrôles
existant plutôt que d'occuper un nouveau coin — l'audit responsive du 05/08 relève que le HUD
déborde déjà en portrait téléphone. **La géométrie en portrait est à revalider à l'implémentation**,
c'est un point de vigilance explicite du plan.

**Localisation** : les libellés de l'écran passent par `lib/l10n/app_fr.arb` et `app_en.arb`
(`settingsTitle`, `volumeMaster`, `volumeSfx`, `volumeMusic`, `muteAll`), conformément à la règle
`CLAUDE.md` — les ARB pour l'UI, le JSON bilingue pour le contenu de jeu.

---

## 9. Mode dégradé

L'audio est le seul sous-système du projet auquel il est **interdit** de faire échouer le jeu (D5).

| Situation | Comportement |
|:---|:---|
| Fichier déclaré mais absent du disque | Marqué indisponible au préchargement, **un seul log en debug par identifiant**, `playOnce()` devient no-op |
| `audio.json` absent ou malformé | Sous-système entièrement désactivé, jeu silencieux, un log en debug. Aucune exception ne remonte |
| Identifiant de son inconnu à la résolution | Silence, sans erreur — c'est le niveau 4 de la chaîne de repli |
| Backend en échec à l'initialisation | Bascule sur `SilentAudioBackend`, le jeu continue |

Le préchargement est **asynchrone et non bloquant** : l'écran de démarrage ne l'attend pas. Un son
demandé avant la fin du préchargement est joué s'il est prêt, abandonné sinon.

---

## 10. Tests

`FakeAudioBackend` enregistre les appels reçus, ce qui rend chaque assertion directe.

| Zone | Ce qui est vérifié |
|:---|:---|
| Chaîne de repli | Les 4 niveaux, un test par niveau, y compris le silence final |
| Mode dégradé | Fichier absent → no-op, jamais d'exception ; `audio.json` malformé → sous-système désactivé, jeu fonctionnel |
| Points d'appel | Jouer une carte de feu émet `cardPlay` résolu sur la variante feu ; `triggerHitReactions` émet le bon moment pour chacun des 4 cas |
| Réglages | Aller-retour de persistance, coupure qui rend silencieux, volume effectif = produit des deux niveaux |
| Musique | Scène identique → pas de redémarrage ; changement de scène → fondu ; état `locked` → sons abandonnés ; `unlock()` → démarre la scène en attente |
| **Cohérence du catalogue (bloquant)** | Tout champ `sfx` d'un JSON de contenu correspond à un `sounds` déclaré. Échoue la CI. Transposition à l'audio de l'item 12 de l'audit du 25/07 |
| **Fichiers manquants (non bloquant)** | Rapport listant les fichiers déclarés absents du disque. Tableau de bord du sourcing, ne rougit jamais la CI |

**Non-régression** : les 295 tests existants doivent rester au vert **sans qu'aucun ne soit
modifié**. C'est la vérification qui valide D4, et elle fait partie des critères de fin.

---

## 11. Documentation et traçabilité

| Livrable | Emplacement |
|:---|:---|
| Décision d'architecture | `.obsidian_vault/_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md` — numéro vérifié libre le 2026-08-24 (dernier existant : ADR-081) |
| Fiche de règle | `.obsidian_vault/_rules/09-00-systeme-audio.md` — catalogue des moments, chaîne de repli, format des assets |
| Fiche de pattern | `.obsidian_vault/_patterns/16-00-architecture-du-systeme-audio.md` |
| ROADMAP | P-03 coché, **et son estimation corrigée** (§14) |
| Note joueur | Via le skill `patch-notes-writer`, en fin de chantier |

---

## 12. Hors périmètre

Explicitement écartés de ce chantier, et pourquoi :

- **Ducking** (atténuer la musique sous un bruitage fort) — confort réel, mais non nécessaire à la
  livraison. À rouvrir si le mixage le réclame après calibration.
- **Bus d'événements de jeu** — écarté par D8, pas oublié. Redevient pertinent au second abonné.
- **Vibrations / retour haptique** — même mécanisme d'appel, autre chantier.
- **Spatialisation, réverbération, mixage dynamique par acte** — hors sujet à ce stade.
- **Sons d'interface hors combat** (survol de bouton, ouverture d'écran) — le catalogue des 15
  moments couvre le combat et la boucle de jeu ; l'UI générale viendra si le besoin se confirme.
- **Le sourcing lui-même** — mené en parallèle, hors chiffrage (§14).

---

## 13. Risques

| Risque | Portée | Mitigation |
|:---|:---|:---|
| Les points d'appel se posent dans le chemin le plus emprunté du jeu (combat) | Régression de combat | Aucun appel ne modifie d'état ; le directeur est sans effet de bord observable. Les 295 tests existants font office de filet |
| Le HUD déborde déjà en portrait téléphone (audit du 05/08) | L'icône de coupure aggrave un défaut connu | Rejoindre un groupe de contrôles existant ; revalider la géométrie portrait à l'implémentation |
| Le déverrouillage autoplay web est difficile à tester automatiquement | Bug ne se manifestant qu'en navigateur | Test unitaire sur la machine à états `locked`/`unlocked` ; vérification manuelle sur le build web avant tag |
| La calibration des volumes ne peut pas se faire sans les vrais sons | Mixage faux à la livraison du moteur | Les volumes sont **des données** (`audio.json`), ajustables sans recompiler. La calibration est une passe de données, pas de code |
| Le catalogue reste troué longtemps | Chantier « livré » mais inaudible | Le rapport non bloquant de fichiers manquants rend l'avancement du sourcing visible à chaque exécution des tests |

---

## 14. Estimation

**6 à 9 jours, hors sourcing.** La fiche ROADMAP annonce 3-5 jours ; ce chiffrage est à corriger.

| Poste | Effort |
|:---|:---|
| Backends, directeur, chaîne de repli, `audio.json` + modèle | 2-3 j |
| Branchement des 8 points d'appel + tests associés | 1-2 j |
| `MusicConductor`, transitions, déverrouillage web | 1-2 j |
| `SettingsScreen`, `SettingsService`, ARB, coupure HUD | 1,5-2 j |
| Documentation (ADR, règle, pattern, ROADMAP) | 0,5 j |

L'écart avec le chiffrage d'origine s'explique par trois postes qu'il ne contenait pas : la
**musique** (le diagnostic du 31/07 ne chiffrait que les bruitages), l'**écran de réglages** créé de
zéro faute d'en avoir un, et le **mapping par données** plutôt qu'un catalogue codé en dur.

Le **sourcing** (~15 bruitages, 4 musiques) reste hors chiffrage : il est mené en parallèle et
constitue le vrai chemin critique de la livraison perçue.
