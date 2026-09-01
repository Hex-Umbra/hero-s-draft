### Statut

✅ **Livré le 2026-08-29**, branche `feat/audio-bruitages-en-wav`, 6 commits.
Complète [ADR-082](ADR-082-directeur-audio-central-et-mapping-par-donnees.md), qui décidait
*quel* son jouer sans rien dire de *quand* il atteint l'oreille. Ne la remplace pas.

### Contexte

Le moteur d'ADR-082 était livré et testé, mais aucun fichier n'existait encore : personne
n'avait donc jamais **entendu** le système. Le sourcing des 19 premiers bruitages a révélé
quatre défauts que le vert des tests ne pouvait pas voir, tous sur le trajet entre l'événement
de jeu et le haut-parleur.

1. **Latence et empilement.** Un délai audible entre le geste et le son ; en survol rapide,
   les sons s'accumulaient et se vidaient d'un coup dès que le joueur cessait d'agir.
2. **Une piste manquante criait.** `MusicConductor.onScene` allait droit au backend, sans
   garde de disponibilité, produisant une erreur par entrée de scène — jamais dédupliquée.
3. **Le premier son de la session était toujours perdu.**
4. **Le son de conséquence tombait à côté de son animation**, dans les deux sens : superposé
   au son de la carte pour les `buff`, séparé de 1,30 s pour les `magic`.

### Décision

**D1 — Un réservoir de lecteurs pré-armés par fichier, jamais `FlameAudio.play`.**
`FlameAudio.play` appelle `_preparePlayer`, qui instancie un `AudioPlayer` natif neuf puis
enchaîne `setAudioContext`, `setReleaseMode` et `play` : **quatre allers-retours séquentiels
de canal de plateforme avant le premier échantillon**. En rafale, chaque son lance sa propre
chaîne et toutes se résolvent ensemble — la signature d'un canal saturé. `AudioPool` paie ce
coût une fois au préchargement ; `playOnce` ne fait plus que réserver un lecteur prêt.

**D2 — Le mode reste `mediaPlayer`, pas `lowLatency`.** En `lowLatency`, `AudioPool.start`
n'enregistre pas `onPlayerComplete` : les lecteurs ne reviennent jamais au réservoir, qui se
viderait et rallouerait à chaque son, en fuyant. Sur Windows les deux modes empruntent le même
chemin natif. **Sur Android, `lowLatency` passerait par SoundPool et serait réellement plus
rapide** — à rouvrir si le mobile est visé.

**D3 — Deux préchargements distincts dans `AudioBackend`.** `preload` monte un réservoir
(bruitages) ; `preloadMusic` ne charge que les octets (musique, qui passe par l'unique lecteur
de fond). Depuis D1 les deux chemins n'ont plus rien de commun, et monter un réservoir de
lecteurs pour une piste de plusieurs minutes serait aussi inutile que coûteux.

**D4 — La garde de disponibilité de la musique est un cache *négatif*.** Le conducteur
mémorise ce qui **manque**, jamais ce qui existe. Un cache positif serait vide au premier
`onScene()` — `preloadAll()` n'étant jamais attendu — et refuserait une piste pourtant
présente, laissant l'écran muet jusqu'au changement de scène suivant. Prix assumé : une
tentative résiduelle au démarrage, quand la première demande précède la conclusion du
préchargement.

**D5 — Le système audio est réveillé au lancement.** Les deux providers sont paresseux et
aucun de leurs sites d'appel n'est un site de démarrage : le premier `ref.read` créait le
directeur, lançait `preloadAll()` sans l'attendre, et demandait dans la foulée un son dont le
réservoir n'existait pas. Le réveil rejoint les deux que `HerosDraftApp.build` fait déjà.

**D6 — L'animation déclare sa frappe d'impact.** `CardAnimator.playAnimation` distingue
`onImpact` — la carte atteint sa cible — de `onComplete`. Le **rendu** des coups (nombres
flottants et bruitages) est routé sur la frappe ; les dégâts, eux, étaient déjà appliqués dans
l'état bien avant. `HeroCard` reçoit le différé que seul `EnemyCard` possédait, sans quoi la
frappe n'aurait rien eu à rendre côté héros.

**D7 — `armorGain` est séparé d'`armorHit`.** Les deux branches opposées de
`triggerHitReactions` — perte et gain d'armure — appelaient le même moment : une carte
défensive jouait le son du coup encaissé.

### Preuves dans le code

- `lib/services/audio/flame_audio_backend.dart` — `SfxPool`, `SfxPoolFactory`, la fabrique
  réelle, et le seul import de `flame_audio` du projet. `test/unit/audio/flame_audio_backend_pool_test.dart`
  garde littéralement D1 : trois `playOnce` ne doivent créer aucun réservoir.
- `lib/services/audio/audio_backend.dart` — les deux préchargements et leurs contrats (D3).
- `lib/services/audio/music_conductor.dart` — `preloadAll()` et `_missingTracks` (D4), gardés
  par quatre tests dont *« avant la fin du prechargement, la lecture reste tentee »*, qui
  verrouille le choix du cache négatif.
- `lib/main.dart` — les deux `ref.watch` de réveil (D5).
- `lib/game/components/visual_effects/card_animator.dart` — `onImpact` sur les quatre
  animations ; `lib/game/components/entities/hero_card.dart` — `_pendingStats` (D6).
- `lib/game/components/entities/combat_entity.dart:208` — `armorGain` (D7).

### Conséquences

**Mesuré en jeu, avant puis après.** Les erreurs de lecture de boucle passent de 7 répétées à
1 ; les 31 réservoirs de bruitages sont désormais montés **au lancement, sans interaction**,
contre zéro auparavant. Cadences du son de conséquence : `melee` 0,30 s inchangé, `buff`
~0,016 s → 0,60 s, `status` 1,10 → 1,00 s, `magic` 1,30 → 1,10 s.

**Un changement visible assumé.** Les particules de soin et le dôme de bouclier naissaient à
t=0 ; ils partent maintenant avec la frappe. C'était l'objet même de D6 — que le visuel et le
son arrivent ensemble — mais ce n'est pas qu'un changement audible.

**Le réservoir a rendu bornés les avertissements du plugin.** `audioplayers` journalise un
`non-platform thread` par lecteur créé. Avant D1, un lecteur naissait par son joué, donc
l'avertissement tombait indéfiniment ; il est maintenant confiné à une rafale au préchargement
(31 lecteurs) plus une croissance modeste en jeu (18 sur une session complète mesurée).

**D6 n'est couvert par aucun test.** Le dépôt n'a pas `flame_test` et **aucun de ses 385 tests
ne pilote un composant Flame** : la cadence des `Effect` n'est vérifiable par rien aujourd'hui.
Les chiffres ci-dessus sont lus dans le code et confirmés à l'oreille, pas exécutés. C'est la
dette la plus nette laissée par ce chantier.

**Le réservoir se dimensionne seul, mais la première superposition d'un son garde l'ancienne
latence** — `minPlayers` vaut 1. Le porter à 2 coûterait 31 lecteurs de plus au démarrage ;
à trancher seulement si le défaut s'entend.

### Voir aussi

- Décision mère : [ADR-082](ADR-082-directeur-audio-central-et-mapping-par-donnees.md).
- Catalogue des moments : [`_rules/09-1`](../_rules/09-1-catalogue-des-moments.md).
- Pattern : [`_patterns/16-00`](../_patterns/16-00-architecture-du-systeme-audio.md) §16.7.
