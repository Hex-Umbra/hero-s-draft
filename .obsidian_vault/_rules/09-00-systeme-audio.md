## 9. Système Audio

Aucun appelant ne nomme jamais un fichier son : le code de jeu déclare un **moment**
(`GameMoment`) ou une **scène musicale** (`MusicScene`), et un directeur central résout le
reste contre `assets/data/audio.json`. Pourquoi cette architecture plutôt que des appels
dispersés : [ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md).
Comment les couches se connectent entre elles :
[`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md).

C'est la fiche à lire pour donner un son à une carte, un ennemi, une relique, ou pour
comprendre pourquoi un moment reste silencieux.

### 9.1. Les 14 moments et leurs déclencheurs

| Moment (`GameMoment`) | Déclencheur |
|:---|:---|
| `cardHover` | `HerosDraftGame.setHoveredCard()` — `lib/game/heros_draft_game.dart:97` |
| `cardPickup` | **Deux sites mutuellement exclusifs, un par geste de prise en main** : `CardInteractionHandler.onTapDown()`, quand la carte devient la carte focalisée par un clic (`lib/game/components/widgets/card_interaction_handler.dart:39`), et `CardInteractionHandler.onDragStart()`, dans la branche où la carte n'était pas déjà focalisée avant ce geste (`card_interaction_handler.dart:70`). `onTapDown` s'exécute toujours en premier sur un même geste (arène de gestes Flutter) et détermine donc lequel des deux émet : jamais les deux, jamais aucun des deux pour un glisser ou un clic qui focalise |
| `cardPlay` | `CardAnimator.playAnimation()`, au tout début de l'animation de jeu — résolu via `CardData` comme `AudioSource` (`sfx` propre, puis `animation`, puis défaut) — `lib/game/components/visual_effects/card_animator.dart:140` |
| `impact` / `impactCrit` | `CombatEntity.triggerHitReactions()`, perte de PV actuels — `lib/game/components/entities/combat_entity.dart:212` |
| `armorHit` | Même méthode, perte **ou** gain d'armure — `combat_entity.dart:196` et `:205` |
| `heal` | Même méthode, gain de PV actuels — `combat_entity.dart:246`. **Voir l'avertissement §9.5** |
| `enemyAttack` | `HerosDraftGame._enemyRipostePhase()`, avant `dashAnimation()` — `heros_draft_game.dart:388` |
| `enemyDeath` | **Deux sites** : `HerosDraftGame.resolvePendingDeaths()` (mort différée pendant une animation de carte, `heros_draft_game.dart:238`) et `StateSyncSystem._applyCombatState()` (suppression immédiate hors animation — poison, effets passifs — `lib/game/systems/state_sync_system.dart:113`) |
| `cardDraw` | `DeckNotifier.drawCards()` — `lib/game/controllers/deck_controller.dart:226` |
| `manaGain` | `GainManaEffectStrategy` — `lib/game/services/effects/strategies.dart:109` |
| `insufficientMana` | **Quatre sites** : `HerosDraftGame._handlePlayerTargeting()` (`heros_draft_game.dart:295`), `PlayerStatsManager` — refus de compétence héroïque (`player_stats_manager.dart:441`), `HeroCard` (`hero_card.dart:89`) et `CardInteractionHandler` (`card_interaction_handler.dart:135`) — refus au clic/glisser sur la carte elle-même |
| `turnStart` | `TurnPhaseManager.startPlayerTurn()`, avant le tick des reliques et statuts — `lib/game/controllers/combat/turn_phase_manager.dart:49` |
| `turnEnd` | `HerosDraftGame.executeTurn()`, juste après la garde de validité du tour — `heros_draft_game.dart:314` |

Les moments systémiques (tour, pioche, mana, survol) n'ont pas de `source` et se résolvent
directement au niveau 3 de la chaîne de repli (§9.2). `triggerHitReactions()` est un entonnoir
unique, appelé aussi bien par `hero_card.dart` que par `enemy_card.dart` : quatre moments — les
plus fréquents en combat — se branchent en un seul endroit, héros et ennemis couverts d'un coup.

### 9.2. La chaîne de repli (4 niveaux)

Résolue par `AudioDirector._resolve()` (`lib/services/audio/audio_director.dart`) :

1. **`source.sfx`** — son propre déclaré sur l'entité elle-même. `CardData`, `EnemyData` et
   `RelicData` implémentent tous trois `AudioSource`.
2. **`moments.<moment>.byAnimation[source.animation]`** — repli par type d'animation. **Seul
   `CardData` porte un `animation` non nul** (`melee`/`magic`/`buff`) ; `EnemyData` et
   `RelicData` renvoient toujours `null` pour ce champ, donc ne peuvent jamais atteindre ce
   niveau — pour eux, seul le niveau 1 (`sfx`) existe au-delà du défaut.
3. **`moments.<moment>.default`** — son par défaut du moment. Seul niveau atteint par les
   moments systémiques, qui n'ont pas de `source`.
4. **Silence, sans erreur.** Un moment sans `default` ni correspondance se tait — c'est l'état
   normal d'un catalogue en cours de sourcing, jamais une exception.

> [!NOTE]
> `RelicData.sfx` est un cas à part : le champ existe et `AudioSource` est bien implémenté, mais
> **aucun `GameMoment` de relique n'existe** — rien n'appelle jamais `onMoment(..., source:
> uneRelique)`. Niveau 1 est donc inatteignable pour une relique, pas seulement le niveau 2 :
> déclarer `"sfx"` sur une relique ne produit aucun son aujourd'hui. Statut identique à celui que
> `_patterns/16-00` §16.4 documente pour `fadeMs` — une limitation connue et assumée, pas un bug.
> Le test de catalogue (§9.4) continue de garder ces identifiants pour le jour où un moment de
> relique sera ajouté.

### 9.3. Format des assets et contrat de nommage des variantes

- **MP3**, 44,1 kHz — mono pour les bruitages, stéréo pour la musique. Pas d'OGG : Safari ne le
  lit pas de façon fiable et le jeu est distribué en web.
- Bruitages courts (< 1,5 s) ; musiques bouclables proprement.
- Chemins déclarés dans `assets/data/audio.json`, relatifs à `assets/audio/` (`pubspec.yaml`
  déclare `assets/audio/sfx/` et `assets/audio/music/` séparément).
- **Variantes.** `"variants": N` sur une entrée de `sounds` attend `N` fichiers numérotés,
  dérivés du nom déclaré en insérant le suffixe **avant l'extension** : `sfx/impact_normal.mp3`
  avec `variants: 3` attend `impact_normal_1.mp3`, `_2` et `_3`. Un fichier est tiré au hasard à
  chaque lecture (`AudioDirector._pickFile`) pour casser la répétition sur les sons les plus
  fréquents. Champ optionnel, vaut `1` par défaut. **Cette dérivation n'a qu'un seul
  propriétaire dans le code**, `SoundData.expectedFiles` — voir `_patterns/16-00` pour pourquoi
  ça compte.

### 9.4. Donner un son à une carte, un ennemi ou une relique

1. Poser le fichier sous `assets/audio/sfx/`.
2. Déclarer une entrée dans `sounds` d'`assets/data/audio.json` (`file`, `volume` optionnel,
   `variants` optionnel).
3. Référencer son identifiant depuis le champ optionnel `"sfx"` de l'entrée JSON de la carte,
   de l'ennemi ou de la relique.

Aucune ligne de Dart requise. Le test bloquant `test/unit/audio/audio_catalogue_test.dart`
échoue si le `sfx` déclaré ne correspond à aucune entrée de `sounds` — faute de frappe attrapée
avant la CI, pas en jeu.

> [!WARNING]
> Pour une **relique**, l'étape 3 seule ne suffit pas à produire un son : voir la note §9.2 sur
> `RelicData.sfx`, aujourd'hui inerte faute de `GameMoment` de relique. Les trois étapes restent
> valables pour une carte ou un ennemi.

### 9.5. Avertissement pour tout contenu qui modifie les PV max en combat

> [!WARNING]
> `triggerHitReactions()` (`lib/game/components/entities/combat_entity.dart`) déclenche
> `GameMoment.heal` sur **toute hausse de PV actuels, sans distinguer sa cause**. Aujourd'hui,
> cela ne produit aucun faux positif — mais pour deux raisons qui ne sont **pas des garde-fous
> audio** et que le contenu ne doit pas supposer stables : la toute première synchronisation de
> stats d'une entité passe par le constructeur du composant, pas par `updateStats` ; et
> `GameScreen` est dépilé avant que les gains de niveau ou les modificateurs de récompense
> n'appliquent leurs PV max — l'écran qui aurait affiché le soin a déjà disparu.
>
> **Toute relique ou compétence qui augmenterait les PV max d'une entité pendant un combat**
> (par opposition à entre deux combats) ferait sonner un soin qui n'en est pas un. Le même
> défaut existe pour l'armure et y est déjà corrigé par le paramètre `suppressArmorChange` de
> `triggerHitReactions` — un mécanisme équivalent serait à ajouter côté soin **avant** de
> livrer un tel contenu, pas après avoir constaté le bruit parasite en jeu.

### 9.6. État du sourcing

Le catalogue est déclaré avant d'exister ([ADR-082](../_adr/ADR-082-directeur-audio-central-et-mapping-par-donnees.md),
D7), gardé par un test bloquant (§9.4) et un rapport non bloquant. Le compte de fichiers
manquants est un fait vivant qui change à chaque livraison de sourcing : il vit dans
`docs/ROADMAP.md` (chantier P-03), pas ici, pour ne pas devoir re-mesurer cette fiche à chaque
fichier livré. Relevé à la demande :

```bash
flutter test test/unit/audio/audio_sourcing_report_test.dart --reporter expanded
```

Ce test ne peut jamais faire échouer la CI — c'est un tableau de bord, pas une assertion.
