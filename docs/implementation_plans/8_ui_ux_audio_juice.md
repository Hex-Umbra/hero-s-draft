# Plan d'Implémentation 8 : Interface et Expérience Utilisateur (UI/UX, Audio & Juice)

Ce document détaille le plan pour implémenter la Section 2 de l'analyse technique des évolutions futures (`docs/possible_upgrades/2_analyse_techniques_evols.md`). L'objectif est de transformer l'expérience de jeu par l'ajout de sons, d'effets visuels avancés et d'une interface plus vivante.

## Phase 1 : Identité Sonore (BGM & SFX)

L'objectif est d'ajouter une immersion sonore complète en utilisant `flame_audio`.

### 1.1 Configuration et Assets
- Ajouter `flame_audio` à `pubspec.yaml` (si pas déjà fait).
- Créer le répertoire `assets/audio/sfx/` et `assets/audio/bgm/`.
- Sourcing des assets (placeholder ou définitifs) :
  - BGM : `battle_theme.mp3`, `boss_theme.mp3`.
  - SFX : `hit.wav`, `heal.wav`, `shield.wav`, `card_draw.wav`, `card_play.wav`, `power_up.wav`.

### 1.2 AudioManager
- Créer `lib/services/audio_manager.dart`.
- Implémenter un service (Riverpod ou Singleton) pour :
  - Précharger les sons au démarrage.
  - Gérer la lecture en boucle de la BGM avec transition (Fade).
  - Jouer des SFX avec gestion du volume global.

### 1.3 Intégration
- Déclencher `card_draw.wav` dans `DeckController`.
- Déclencher `card_play.wav` dans `EffectResolver` ou `CardComponent`.
- Déclencher `hit.wav` lors de l'appel à `takeDamage` dans les composants Flame.

---

## Phase 2 : VFX Avancés et "Juice"

Ajouter du répondant visuel aux actions pour rendre le jeu "vivant".

### 2.1 Système de Particules
- Utiliser `ParticleSystemComponent` de Flame.
- Créer des préréglages (Presets) :
  - **Impact** : Particules rouges/jaunes éclatant lors d'un dégât.
  - **Soin** : Particules vertes montant vers le haut.
  - **Bouclier** : Éclats bleus/blancs circulaires.
- Intégrer le déclenchement dans `HeroCard` et `EnemyCard`.

### 2.2 Screen Shake (Secousses de caméra)
- Implémenter une méthode `shake()` sur `HerosDraftGame`.
- Utiliser `MoveEffect` sur la caméra ou un composant conteneur pour appliquer une vibration aléatoire.
- Déclencher lors de coups critiques ou d'attaques puissantes d'ennemis.

### 2.3 Combat Log
- Créer un widget Flutter `CombatLogOverlay` superposé au jeu Flame.
- Utiliser un `StateProvider<List<String>>` pour stocker les 5 derniers messages.
- Afficher les actions : "Vous jouez Frappe (10 dégâts)", "Gobelin utilise Morsure (5 dégâts)".

---

## Phase 3 : Polissage des Composants Flame

### 3.1 Animations de Cartes
- Améliorer `CardComponent` :
  - Ajout d'une ombre portée dynamique lors du drag.
  - Effet de "brillance" pour les cartes de rareté Épique/Rare (utiliser un `CustomPainter` ou un effet de shader simple).

### 3.2 Intentions Ennemies
- Rendre les icônes d'intention plus expressives.
- Ajouter une petite animation de "battement de coeur" (Pulse) sur l'icône d'intention pour attirer l'œil.

---

## Phase 4 : Interface Flutter (HUD)

### 4.1 Transitions d'Écran
- Utiliser des transitions de page personnalisées (Slide/Fade) entre `Home`, `Draft` et `Game`.

### 4.2 Feedback de Mana/Vie
- Animer les barres de vie (LinearProgressIndicator) pour qu'elles "glissent" vers la nouvelle valeur au lieu de sauter.

---

## Phase 5 : Validation et Tests

- **Vérification Audio** : S'assurer que les sons ne se chevauchent pas de manière désagréable (limiter le nombre de sons d'impact simultanés).
- **Performance** : Vérifier que le système de particules n'impacte pas le FPS sur mobile (utiliser `CompositedParticle` si nécessaire).
- **UX** : Tester la lisibilité du combat log pendant une phase d'action rapide.
