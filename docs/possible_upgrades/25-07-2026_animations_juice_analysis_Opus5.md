# Analyse complète des animations & du « Juice » — Hero's Draft

**Date** : 25/07/2026
**Branche analysée** : `feature/combat_scaling`
**Périmètre** : `lib/game/` (Flame), `lib/ui/` (Flutter), `assets/data/`, `docs/animations/`
**État de l'analyseur au moment de l'audit** : `dart analyze` → *No issues found*

---

## 1. Résumé exécutif

Le système d'animation est **entièrement procédural** : aucune spritesheet, aucune `SpriteAnimation`, 8 PNG statiques dans `assets/images/`. Tout passe par les `Effect` de Flame et du dessin `Canvas` à la main. C'est un choix cohérent avec le budget artistique du projet, et la base technique est saine (séparation `CardAnimator` / `CardComponent`, système data-driven via la clé `animation` du JSON).

Mais l'audit révèle trois écarts majeurs :

| Axe | Verdict | Détail |
|---|---|---|
| **Variété par type d'attaque** | ⚠️ Illusoire | 7 clés JSON (`melee`, `magic`, `buff`, `poison`, `fire`, `ice`, `lightning`) mais **4 séquences réelles** — les 4 clés élémentaires appellent la même fonction avec une couleur différente. |
| **Animations par carte** | ❌ Inexistant | **Aucune** des 6 cartes uniques de classe n'a de visuel propre. `smite` (Paladin) et une frappe commune sont pixel pour pixel identiques. |
| **Performance** | ⚠️ 3 points chauds | Reconstruction du `TextPaint` à chaque frame dans `FloatingText`, spawn de particules non throttlé à 60 Hz pendant le drag, ~18 `MaskFilter.blur` par frame pendant le ciblage. |
| **Cohérence** | ⚠️ Dérive | Palette élémentaire dupliquée en 3 versions divergentes, priorités z contournées par des littéraux, 12 courbes / 22 durées sans convention, documentation fausse sur 4 points. |
| **Juice global** | ❌ Trou béant | **Audio : 0 %.** Aucun screenshake caméra en combat, aucun hit-stop, aucun état idle, aucun feedback de relique/mana. |

**La recommandation n°1, très loin devant toutes les autres** : l'audio. Le projet n'a aucun son (`flame_audio` n'est même pas dans `pubspec.yaml`, une seule trace : un `TODO` en `lib/game/components/floating_text.dart:166`). Aucune amélioration d'animation ne rendra autant de « game feel » par heure investie.

---

## 2. Cartographie de l'existant

### 2.1 Animations de cartes jouées — `lib/game/components/visual_effects/card_animator.dart`

Dispatch en `card_animator.dart:147-174` sur `card.data.animation` :

| Clé JSON | Méthode | Contenu réel |
|---|---|---|
| `melee` (défaut) | `_playMeleeAnimation` (`:224`) | Flash blanc de la carte → anticipation 40 px → dash vers la cible → scale 0 → `SlashEffect` rouge |
| `magic` | `_playMagicAnimation` (`:287`) | Bordure cyan → montée 30 px → pulse elastic → scale 0. **Aucun impact.** |
| `buff` | `_playBuffAnimation` (`:330`) | Bordure blanche → montée 100 px → fade. Particules **uniquement** si l'effet contient `heal` ou `armor` (`:333-343`) |
| `poison` / `fire` / `ice` / `lightning` | `_playStatusAnimation` (`:177`) | **Une seule et même séquence**, seule la `Color` change (`:155-169`). Montée + rotation → dash → scale 0. **Aucun impact.** |

### 2.2 Répartition dans les données

23 cartes au total (17 dans `cards.json`, 6 dans `hero_cards.json`) :

```
buff       : 11  (48 %)
melee      :  5  (22 %)
magic      :  3  (13 %)
poison     :  1
fire       :  1
ice        :  1
lightning  :  1
```

Près de la moitié du contenu joue donc la séquence la plus pauvre du lot (un simple fondu vers le haut).

### 2.3 Effets visuels autonomes

| Composant | Fichier | Rôle |
|---|---|---|
| `SlashEffect` | `visual_effects/slash_effect.dart` | Trait diagonal + glow + cœur blanc, 0,3 s |
| `ShieldDome` | `card_animator.dart:480` | Demi-dôme cyan pulsé sur le héros, 0,8 s |
| `RibbonTrail` | `visual_effects/ribbon_trail.dart` | Ruban tapered pendant le drag |
| `TargetingLine` | `visual_effects/targeting_line.dart` | Bézier + 16 points défilants + flèche |
| `EffectIcon` | `components/effect_icon.dart` | 7 pictogrammes vectoriels (bouclier, goutte, flamme, flocon, éclair, épées croisées, étoile) |
| `FloatingText` | `components/floating_text.dart` | Chiffres de dégâts, 4 variantes (standard / crit / poison / bouclier) |
| `CrossParticle` | `card_animator.dart:457` | Croix de soin |

### 2.4 Réactions d'entité — `components/entities/combat_entity.dart`

- `shakeAndFlashAnimation` (`:48`) — bump d'échelle + shake haute fréquence + `ColorEffect` ; 3 intensités (normal / poison / crit)
- `shieldHitAnimation` (`:22`) — bump léger + bordure cyan
- `dashAnimation` (`:138`) — aller-retour 50 px
- `spawnDamageParticles` (`:105`) — burst radial 12/15/35 particules

### 2.5 Ce qui n'existe pas

- ❌ Audio (0 occurrence dans tout `lib/`)
- ❌ Screenshake caméra en combat (seul `ui/widgets/relic_carousel/draft_card_reel.dart` en a un, côté Flutter)
- ❌ Hit-stop / freeze frame
- ❌ États idle (respiration, flottement)
- ❌ Feedback de dépense de mana, de proc de relique, de proc de passif
- ❌ Mise en scène de victoire / défaite en combat
- ❌ Tests sur la couche animation
- ❌ Réglages joueur (vitesse d'animation, mode « effets réduits »)

---

## 3. Axe A — Améliorations des animations existantes

### A1. Le héros n'attaque jamais 🔴

Quand le joueur joue une carte `melee`, seule **la carte** vole vers l'ennemi. Le `HeroCard` reste immobile. `dashAnimation()` n'est appelé que pour les compétences (`heros_draft_game.dart:340`, `ui/screens/game_screen.dart:321`).

Conséquence : la lecture « qui frappe qui » est cassée. Le héros est un spectateur de son propre combat. C'est probablement **le déficit de juice le plus visible** après l'audio.

**Correctif** : lunge du héros synchronisé sur la phase d'impact de `_playMeleeAnimation`, avec un léger recul (recoil) au retour.

### A2. Aucun moment d'impact pour `magic`, `buff` et les élémentaires 🔴

`_playMagicAnimation` et `_playStatusAnimation` se terminent toutes deux par `ScaleEffect.to(Vector2.all(0.0))` puis `onComplete()` — la carte disparaît, point. Le seul retour visuel est ensuite le `shakeAndFlashAnimation` de l'ennemi, déclenché par le diff de stats.

Ironie : la méthode `spawnImpactParticles` **existe** (`card_animator.dart:398`) et n'est **jamais appelée**. C'est du code mort, ce qui viole la règle « No dead code » de `CLAUDE.md`.

### A3. Mort d'ennemi sans mise en scène 🟠

Fade + `ScaleEffect.to(zero)` en 0,4 s. Aucune particule, aucun flash, aucune pause. Le moment le plus gratifiant du combat est le moins animé.

Aggravant : **la logique est dupliquée** entre `heros_draft_game.dart:232-243` et `systems/state_sync_system.dart:110-124`.

### A4. Repositionnement des ennemis instantané 🟠

`systems/layout_system.dart:121` : `enemyCards[i].position = Vector2(...)`. Écriture directe, sans tween. Quand un ennemi meurt, les survivants **se téléportent**. Très visible et cassant à partir de 3 ennemis — donc de plus en plus visible avec le nouveau cap par acte de la branche courante.

### A5. Pioche sans décalage (stagger) 🟠

`state_sync_system.dart:85` place toutes les nouvelles cartes au même point `(40, size.y - 40)`, puis `layoutHand()` les anime **toutes en même temps** sur 0,7 s (`layout_system.dart:57`). 5 cartes qui partent du même pixel et arrivent simultanément se lisent comme un seul bloc, pas comme une pioche.

**Correctif** : un `delay` de ~60 ms × index sur chaque `EffectController`.

### A6. `ShieldDome` en unités absolues 🟡

`card_animator.dart:503` : `radius = 70.0 * pulse`, en dur. Ne tient compte ni de `game.scaleFactor` (qui varie de 0,85 à 2,5) ni de la taille réelle du héros. Sur grand écran, le dôme est trop petit et se décale du sprite.

### A7. Les cartes `buff` non-heal/non-armor ne produisent rien 🟡

`card_animator.dart:333-343` : particules seulement si `heal` ou `armor`. Une carte de pioche, de gain de mana ou d'auto-buff (`apply_status` sur soi) n'a qu'un fondu vers le haut — soit 48 % du contenu qui joue la séquence la plus terne.

---

## 4. Axe B — Variété selon le type d'attaque

### B1. 4 séquences pour 7 clés 🔴

`poison`, `fire`, `ice`, `lightning` → `_playStatusAnimation(target, <Color>, onComplete)`. Le joueur ne perçoit **aucune différence** entre une carte de feu et une carte de glace au-delà d'une teinte. La promesse data-driven du système n'est pas tenue.

### B2. La documentation décrit des effets qui n'existent pas 🔴

`docs/animations/card_animations_system.md` affirme :
- §3 `magic` : *« la carte prend une teinte violette […] puis explose en particules pourpres »* → la bordure est **cyan** (`card_animator.dart:292`) et **il n'y a pas de particules**
- §3 `buff` : *« la carte devient dorée »* → elle devient **blanche** (`:331`)
- §3 élémentaires : *« Impact : Explosion de 30 particules denses de la couleur de l'élément »* → **inexistant**
- §4 : *« La logique réside dans `lib/game/components/card_component.dart` »* → elle a été déplacée dans `card_animator.dart`

La doc décrit donc une **intention de design jamais implémentée**. C'est en réalité un excellent cahier des charges pour l'axe B.

### B3. Le `SlashEffect` est invariant 🟠

`slash_effect.dart:64-67` trace toujours la même diagonale `(0,0) → (size.x, size.y)`, toujours en `Colors.redAccent` (`card_animator.dart:265, 273`), même pour une carte de glace ou de feu déclarée `melee`. Après 20 combats, l'œil ne le voit plus.

Leviers gratuits : angle aléatoire, 1 à 3 traits selon la magnitude, couleur = couleur élémentaire de la carte.

### B4. Aucune modulation par la magnitude des dégâts 🟠

Une frappe à 5 et une frappe à 40 produisent exactement le même slash, le même shake, le même nombre de particules. La seule variable est le booléen `isCritical` (`combat_entity.dart:55, 71-72, 231`).

**Correctif** : passer d'un booléen à un ratio continu `dégâts / PV max` qui pilote intensité du shake, nombre de particules, amplitude du screenshake, durée du hit-stop.

### B5. Deux sources de vérité pour « l'élément » 🟠

- Source 1 : le champ JSON `animation` (`fire`, `ice`, …)
- Source 2 : `CardComponent._determineDamageType()` (`card_component.dart:200-242`), qui devine l'élément en cherchant des **mots-clés dans le nom localisé de la carte** (`« feu »`, `« fire »`, `« brûlure »`, `« glace »`, `« foudre »`…)

Cette seconde source alimente `getElementalColor()`, utilisée par la traînée de drag, la `TargetingLine` et le tooltip. Elle est fragile (elle repose sur des chaînes traduites), difficile à maintenir en bilingue, et peut **contredire** le champ `animation`.

### B6. Intents ennemis binaires 🟡

`heros_draft_game.dart:379-383` : `attack` → `dashAnimation()`, tout le reste → `EffectIcon`. Aucune variation par archétype (slime / squelette / orc) ni par statut de boss. Un boss qui charge son attaque ultime a le même dash qu'un gobelin.

---

## 5. Axe C — Animations spécifiques par carte (cartes uniques de classe)

### C1. Aucune carte unique n'a de signature visuelle 🔴

| Carte | Classe | `animation` | Visuel |
|---|---|---|---|
| `holy_shield` | Paladin | `buff` | identique à toute carte buff |
| `smite` | Paladin | `melee` | identique à `strike_basic` |
| `reckless_strike` | Berserker | `melee` | identique à `strike_basic` |
| `rage_form` | Berserker | `buff` | identique à toute carte buff |
| `magic_missile` | Mage | `magic` | identique à toute carte magic |
| `mana_surge` | Mage | `buff` | identique à toute carte buff |

Ce sont les cartes de rareté `unique`, les plus identitaires du jeu, et **elles ne se distinguent visuellement à l'usage d'aucune commune**.

### C2. Incohérence : la rareté se voit dans la main mais disparaît à l'usage 🟠

`card_component.dart:145-194` (`getRarityShineColors`) produit une bordure iridescente progressive selon la rareté **et le nombre d'upgrades de forge** — un très beau travail. Mais dès que la carte est jouée, tout ce langage visuel s'évapore : la bordure est écrasée en blanc ou cyan par l'animator (`:187, :292, :331`).

Le joueur qui a investi 5 upgrades de forge sur sa carte unique n'en voit **aucune trace** au moment où elle frappe.

### C3. Le champ `animation` n'est ni typé ni validé 🟠

`lib/models/data/card_data.dart:55` : `final String? animation;` — chaîne libre, parsée en `:117`. Une faute de frappe (`"maigc"`) retombe silencieusement sur `melee` via le `default:` du switch (`card_animator.dart:170-173`). Aucun test, aucune validation au chargement.

### C4. Le modèle manque un niveau de granularité 🟠

Aujourd'hui `animation` désigne une **famille**. Il n'existe pas de moyen d'exprimer « famille = melee, mais avec la signature *châtiment sacré* ».

**Architecture recommandée** — rester data-driven, éviter un `switch` qui gonfle :

```dart
// lib/game/services/effects/card_vfx_registry.dart
typedef VfxBuilder = void Function(CardAnimator anim, EnemyCard? target, VoidCallback done);

class CardVfxRegistry {
  static const _signatures = <String, VfxBuilder>{
    'smite'          : _smiteHoly,       // colonne de lumière + slash doré
    'reckless_strike': _recklessCleave,  // triple slash + recul du héros
    'magic_missile'  : _arcaneHoming,    // 3 projectiles à tête chercheuse
    'holy_shield'    : _consecration,    // dôme doré + runes
    'rage_form'      : _bloodAura,       // aura rouge pulsée sur le héros
    'mana_surge'     : _manaBloom,       // vortex bleu convergent
  };

  static VfxBuilder resolve(CardData data) =>
      _signatures[data.id] ?? FamilyVfx.forFamily(data.animation);
}
```

Le JSON gagne un champ optionnel `"vfx": "<id>"` (avec repli sur `id` puis sur `animation`), et le registre reste fermé à la modification côté `CardAnimator`.

**Note de faisabilité** : avec 23 cartes seulement, une passe complète « une signature par carte » est aujourd'hui réaliste. Elle ne le sera plus à 80 cartes — c'est le bon moment pour poser le registre.

---

## 6. Axe D — Performance

### D1. 🔴 `FloatingText` : layout de texte complet à chaque frame

`floating_text.dart:134-160` — le setter `opacity` appelle `_updateTextStyle()`, qui **reconstruit un `TextPaint`** et l'assigne à `textRenderer`. Or dans Flame 1.37, le setter `TextComponent.textRenderer` appelle `updateBounds()` → `_textRenderer.format(_text)` → **layout de texte complet** (`flame-1.37.0/lib/src/components/text_component.dart:36-48`).

L'`OpacityEffect.fadeOut` tourne pendant 1,2 s → **~72 layouts de texte par texte flottant**. Un crit AoE sur 6 ennemis = 6 textes simultanés = **~430 layouts** sur 1,2 s, plus l'allocation de 6 × 72 `TextStyle` + `TextPaint` + listes de `Shadow`.

C'est le point chaud n°1, et il se déclenche précisément au moment où l'on veut la meilleure fluidité.

**Correctifs possibles**, par ordre de simplicité :
1. Quantifier l'alpha par paliers de 1/16 et ne reconstruire que sur changement de palier → −94 % de layouts
2. Pré-générer 16 `TextPaint` à la construction et indexer
3. Overrider `render()` avec un `canvas.saveLayer(bounds, Paint()..color = white.withOpacity(o))` et ne jamais toucher au `textRenderer`

### D2. 🔴 `spawnTrailParticles` non throttlé

`card_component.dart:546-554` — appelé dans `update()` **sans aucun throttle** tant que `isDragging`. À 60 fps :

- 60 `ParticleSystemComponent` créés/seconde, ajoutés à la racine du jeu (donc 60 opérations/s dans la file de cycle de vie de Flame)
- lifespan 0,6 s → **~36 composants et ~108 particules vivants en permanence**
- chaque particule alloue un `Paint()` neuf (`card_animator.dart:43, 55`) et un `Vector2`

Le nettoyage est correct (`ParticleSystemComponent.update` s'auto-retire quand `particle.shouldRemove`), mais le **churn d'allocation** est permanent pendant tout le drag → pression GC → micro-saccades exactement pendant l'interaction la plus sensible au toucher.

**Correctif** : accumulateur `dt`, 1 spawn toutes les ~33 ms (soit ÷2), et `Paint` partagés en `static final`.

### D3. 🔴 ~18 `MaskFilter.blur` par frame pendant le ciblage

Trois sources qui se cumulent exactement au même moment :

| Source | Fichier | Coût / frame |
|---|---|---|
| `TargetingLine` | `targeting_line.dart:44-109` | 1 path flou + **16 cercles, chacun avec son propre `MaskFilter.blur`** + flèche floue + cercle d'impact flou = **19 blurs** |
| Highlight de tous les ennemis | `card_animation_system.dart:115-123` allume **tous** les ennemis ; `enemy_card.dart:309-318` dessine un RRect avec `MaskFilter.blur(outer)` | **N blurs** (N = nb d'ennemis) |
| Glow de la carte focus | `card_renderer.dart:63-69` | 1 blur + 1 `LinearGradient.createShader()` reconstruit chaque frame (`:44-48`) |

`MaskFilter.blur` force une passe de rendu hors écran par opération. À l'acte 6 (6 ennemis avec le nouveau cap `getMaxEnemiesForNormalCombat`), on est à **~26 blurs/frame en continu** pendant que le joueur vise. C'est le point chaud n°2.

**Correctifs** : dessiner les points de la ligne comme un seul `Path` avec **un seul** blur ; remplacer le glow `outer` des ennemis par un RRect semi-transparent non flou (ou un blur unique appliqué à un layer groupé) ; mettre en cache le shader du foil et ne le reconstruire que si `foilTime` a bougé d'un seuil.

### D4. 🟠 `EffectIcon` reconstruit ses `Path` et `Paint` à chaque frame

`effect_icon.dart:49-313` — `_drawVector()` est appelé depuis `render()` et reconstruit intégralement les `Path` (flamme, goutte, éclair, flocon…) et jusqu'à 3 `Paint` par frame, dont un avec `MaskFilter`. Le flocon est le pire : boucle de 6 itérations × 6 `drawLine` = 36 draw calls + `save`/`restore`.

**Correctif** : `Path` en `static final` par type d'icône, `Paint` réutilisés avec seule la couleur mise à jour.

### D5. 🟠 Pas de budget de particules

Aucun plafond global. Un crit AoE à 6 ennemis produit dans la même frame : 6 × 35 = **210 particules**, 6 `SlashEffect`, 6 `FloatingText` (donc 6 × le coût D1), 6 `shakeAndFlashAnimation` avec 8 `MoveEffect` chacun = **48 effets** simultanés.

**Correctif** : un `VfxBudget` central qui dégrade le `count` quand le nombre de composants VFX actifs dépasse un seuil, plus un `qualityLevel` exposé dans les réglages.

### D6. 🟡 `CardTextRenderer.refreshVisuals` reconstruit tous les `TextPainter`

Appelé pour **toutes** les cartes de la main à chaque `_applyState` (`state_sync_system.dart:61-63`) et à chaque changement de hover/focus (`card_animation_system.dart:19, 36, 57, 83`). `refreshVisuals` (`card_text_renderer.dart:42`) reconstruit `namePainter`, `descPainter`, tous les `badges`, `usagePainter`, `typePainter`, `starsPainter` — chacun avec un `.layout()`.

Un simple survol de la souris sur la main provoque donc 2 reconstructions complètes (sortie + entrée). Acceptable en l'état, mais à surveiller si la main grandit.

---

## 7. Axe E — Cohérence

### E1. 🔴 La palette élémentaire existe en 3 versions divergentes

| Élément | `getElementalColor` (`card_component.dart:244`) | `card_animator` dispatch (`:155-169`) | `EffectIcon` (`effect_icon.dart`) | `FloatingText` shadows (`:45-68`) |
|---|---|---|---|---|
| Poison | `0xFF10B981` | `0xFF10B981` | `0xFF10B981` / `0xFF047857` / `0xFF34D399` | `greenAccent` + `lightGreenAccent` |
| Glace | `cyanAccent` | `lightBlueAccent` | `lightBlueAccent` / `0xFF0284C7` | — |
| Feu | `orangeAccent` | `orangeAccent` | `deepOrangeAccent` / `0xFFF97316` | — |
| Foudre | `amberAccent` | `yellowAccent` | `yellowAccent` / `0xFFFACC15` | — |

La glace est cyan dans la traînée de drag et bleu clair dans l'animation de jeu. La foudre est ambre puis jaune. Il n'existe **aucun token central**.

### E2. 🔴 Bug visible — échelle absolue dans la zone d'annulation

`components/widgets/card_interaction_handler.dart:94-96` :

```dart
if (cancelling) {
  add(ScaleEffect.to(Vector2.all(0.9),  ...));   // absolu
} else {
  add(ScaleEffect.to(Vector2.all(1.25), ...));   // absolu
}
```

Or `onDragStart` (`:64`) a posé `scale = game.scaleFactor * 0.88 * 1.25`. Avec `scaleFactor` variant de **0,85 à 2,5** (`heros_draft_game.dart:46`), la carte **change brutalement de taille** dès qu'elle entre puis ressort de la zone d'annulation, sur tout écran dont la hauteur ≠ 800 px. Sur un écran haut, elle rétrécit de moitié.

### E3. 🟠 Priorités z contournées par des littéraux

`GameConstants` définit proprement 7 constantes de priorité (`game_constants.dart:6-12`)… puis elles sont ignorées :

| Emplacement | Valeur en dur | Collision |
|---|---|---|
| `combat_entity.dart:171` (`FloatingText`) | `200` | = `priorityCardTrail` |
| `enemy_card.dart:332` (`EffectIcon`) | `200` | idem |
| `hero_card.dart:159` (`EffectIcon`) | `200` | idem |
| `card_interaction_handler.dart:61` (carte draggée) | `200` | idem |
| `card_animator.dart:390` (particules de soin) | `100` | = `priorityCardHovered` |
| `SlashEffect` (`card_animator.dart:262, 271`) | *aucune* → `0` | = priorité des `EnemyCard` |

Résultat : l'ordre de rendu entre un texte flottant et une carte draggée est **indéterminé** (il dépend de l'ordre d'insertion), et le `SlashEffect` ne passe au-dessus de l'ennemi que par chance.

### E4. 🟠 Dérive de position possible : shake + repositionnement concurrents

`shakeAndFlashAnimation` (`combat_entity.dart:73-83`) empile 5 à 8 `MoveEffect.by(..., alternate: true)` — des déplacements **relatifs**. En parallèle, `repositionEnemies()` (`layout_system.dart:121`) écrit `position` **en absolu**.

Si un ennemi meurt pendant qu'un autre est en train de trembler, `repositionEnemies()` est appelé (`heros_draft_game.dart:246`) et repositionne la cible tandis que ses `MoveEffect.by` sont encore en vol → la moitié restante du shake s'applique depuis la **nouvelle** base, et la position finale dérive. Scénario parfaitement atteignable en AoE.

### E5. 🟠 Asymétrie de configuration

Les **timings de combat** sont proprement centralisés dans `GameConstants` (`:33-47`), tout comme les 20 constantes de `FloatingText` (`:49-95`). Mais **toutes les durées et courbes d'animation** sont en dur dans les composants : `0.4`/`elasticOut` (`card_animator.dart:79`), `0.1`/`easeOut` (`card_animation_system.dart:24`), `0.35`/`easeOutCubic` (`layout_system.dart:57`)…

Le projet a donc démontré qu'il sait centraliser, mais ne l'a fait que sur deux îlots.

**Chiffres** : 12 courbes différentes utilisées (23× `easeOut`, 13× `easeIn`, 10× `easeOutQuad`, 8× `elasticOut`, 8× `easeInOut`, 7× `easeOutCubic`, 7× `easeOutBack`, 2× `bounceOut`…) et 22 valeurs de durée distinctes. Aucune convention documentée.

### E6. 🟠 Logique de mort dupliquée

Le bloc `OpacityEffect` + `ScaleEffect.to(zero)` + `removeFromParent` est écrit **deux fois** : `heros_draft_game.dart:232-243` et `state_sync_system.dart:110-124`. Toute amélioration de la mort (particules, hit-stop) devra être faite deux fois ou sera oubliée dans une des branches.

### E7. 🟠 Documentation obsolète

`docs/animations/card_animations_system.md` est faux sur 4 points (cf. §B2), dont un pointeur de fichier périmé. Un contributeur qui suit ce guide écrira au mauvais endroit.

### E8. 🟡 Code mort

`CardAnimator.spawnImpactParticles` (`card_animator.dart:398-425`) — défini, jamais appelé. Contraire à la règle « No dead code » de `CLAUDE.md`.

### E9. 🟡 Aucun test sur la couche animation

24 fichiers de tests unitaires, aucun ne couvre `CardAnimator`, `LayoutSystem`, `CardAnimationSystem` ni la validité du champ `animation` des JSON.

---

## 8. Autres points essentiels pour le « Juice »

### J1. 🔴🔴 Audio — absent à 100 %

Zéro son dans tout le projet. Pas de dépendance `flame_audio`. Une seule trace d'intention : le `TODO` de `floating_text.dart:166`.

C'est **le levier de juice le plus rentable du projet**, très largement devant tout le reste de ce rapport. Le retour perçu par heure investie est sans commun avec n'importe quelle amélioration visuelle. ~15 événements suffisent pour transformer la sensation :

`card_hover`, `card_pickup`, `card_play_melee`, `card_play_magic`, `card_play_buff`, `impact_normal`, `impact_crit`, `armor_hit`, `heal`, `enemy_death`, `card_draw`, `mana_gain`, `turn_start`, `turn_end`, `insufficient_mana`.

Architecture suggérée : un `SfxService` sous `lib/game/services/`, injecté via Riverpod, avec `preloadAll()` au démarrage et un pooling ; les composants Flame ne l'appellent jamais directement — les hooks se posent aux mêmes points que les animations existantes.

### J2. 🔴 Screenshake caméra — absent en combat

`FlameGame` expose `camera.viewfinder`, sur lequel un `MoveEffect` bruité coûte quasiment rien. Aujourd'hui le seul screenshake du jeu est dans le carrousel de reliques (`draft_card_reel.dart:114-122`) — donc l'écran tremble quand on **gagne une relique**, mais pas quand on encaisse un coup de boss. Incohérence de priorité expressive.

### J3. 🔴 Hit-stop — absent

40 à 80 ms de gel sur un crit ou un coup fatal est l'astuce la moins chère et la plus efficace du game feel. Implémentable en jouant sur `timeScale` ou en insérant une pause dans la séquence d'effets.

### J4. 🟠 Rythme du tour ennemi — croissance linéaire non maîtrisée

Calcul depuis `GameConstants` et `_enemyRipostePhase` (`heros_draft_game.dart:364-395`) :

```
600 (début) + 400 (ticks) + N × (200 dash + 400 résolution) + 300 (fin)
```

| Ennemis | Durée du tour ennemi |
|---|---|
| 2 | 2,5 s |
| 4 | 3,7 s |
| 6 | 4,9 s |
| 8 | 6,1 s |

Or la branche courante (`feature/combat_scaling`) fait précisément croître le nombre d'ennemis : `getMaxEnemiesForNormalCombat(act) = 1 + (act-1)` — **+1 ennemi par acte**, sans plafond apparent dans la formule de pas. À l'acte 8, le joueur regarde 6 secondes d'animation non interruptible **à chaque tour**.

**Correctifs** : paralléliser les intents non-attaque (aucune raison de les sérialiser), rendre les délais dégressifs quand N croît (`delai = base * (1 / (1 + 0.15 * (N-2)))`), et surtout ajouter un geste « accélérer » (tap = ×3) — un standard du genre.

### J5. 🟠 Aucun feedback de dépense de mana

La carte part, le compteur du HUD change. Aucun lien visuel entre les deux. Un cristal qui se détache du médaillon de coût et vole vers le HUD suffirait à créer la causalité.

### J6. 🟠 Aucun feedback de proc de relique / passif

Dans un roguelike deckbuilder, le moment « ma relique vient de se déclencher » est un pilier du plaisir (Slay the Spire fait clignoter et pulser l'icône). Ici, rien : l'effet s'applique silencieusement dans le pipeline.

### J7. 🟠 Aucun état idle

Ni héros ni ennemis ne bougent entre deux actions. L'écran de combat est littéralement figé pendant tout le tour du joueur. Une oscillation sinusoïdale déphasée par entité (`position.y += sin(t * f + phase) * 2`) coûte quasi rien et change radicalement la perception de vivant. Les entités ont déjà un `update(double dt)` accumulant `_totalTime` (`enemy_card.dart:297-305`, `hero_card.dart:52-59`) — l'infrastructure est là.

### J8. 🟠 Ticks de statut sans mise en scène

Le poison et la brûlure passent par le chemin générique `triggerHitReactions`. Aucune animation de **source** : l'icône de statut sur l'ennemi ne pulse pas, il n'y a pas de lien visuel entre « le statut » et « les dégâts qu'il inflige ».

### J9. 🟠 Pas de télégraphe d'intention

L'intent ennemi n'a aucune animation avant sa résolution — juste le dash au moment de frapper. Le joueur ne voit jamais l'ennemi « charger » son coup. C'est une occasion manquée de tension.

### J10. 🟡 Victoire / défaite sans mise en scène

Aucune séquence de fin de combat.

### J11. 🟡 Aucun réglage joueur

Ni vitesse de combat, ni mode « effets réduits ». C'est attendu sur ce genre, et c'est aussi la soupape de sécurité performance sur mobile bas de gamme — le pendant naturel de l'axe D.

### J12. 🟡 Variété visuelle des ennemis

4 ennemis dans `enemies.json`, 4 sprites. Comme il n'y a aucune animation de sprite, la seule variété perceptible en combat viendra des **VFX** — ce qui renforce encore l'importance de J1/B1/B6.

---

## 9. Plan de route priorisé

### P0 — Fondations & correctifs (1 sprint, impact immédiat)

| # | Action | Fichiers | Effort |
|---|---|---|---|
| 1 | Créer `lib/game/vfx_tokens.dart` : palette élémentaire unique, durées, courbes, priorités z. Migrer tous les littéraux. | nouveau + ~10 fichiers | M |
| 2 | Corriger l'échelle absolue de la zone d'annulation (E2) | `card_interaction_handler.dart:94-96` | XS |
| 3 | Assigner les priorités z depuis `GameConstants`, ajouter `prioritySlash` / `priorityFloatingText` / `priorityEffectIcon` distincts (E3) | 5 fichiers | S |
| 4 | Extraire la mort d'ennemi dans une méthode unique `EnemyCard.playDeath()` (E6) | `enemy_card.dart`, `heros_draft_game.dart`, `state_sync_system.dart` | S |
| 5 | Corriger la dérive shake/reposition : passer le shake sur un enfant conteneur plutôt que sur l'entité (E4) | `combat_entity.dart`, `layout_system.dart` | S |
| 6 | **Perf** : cacher les `TextPaint` de `FloatingText` par paliers d'alpha (D1) | `floating_text.dart` | S |
| 7 | **Perf** : throttler `spawnTrailParticles` à ~30 Hz + `Paint` statiques (D2) | `card_component.dart`, `card_animator.dart` | XS |
| 8 | **Perf** : un seul `Path` + un seul blur pour `TargetingLine` (D3) | `targeting_line.dart` | S |
| 9 | **Perf** : `Path`/`Paint` en cache dans `EffectIcon` (D4) | `effect_icon.dart` | S |
| 10 | Supprimer `spawnImpactParticles` **ou** le brancher sur les impacts magic/status (E8 + A2) | `card_animator.dart` | XS |
| 11 | Mettre `docs/animations/card_animations_system.md` en conformité avec le code (E7) | doc | XS |
| 12 | Ajouter un test qui valide que tout `animation` des JSON correspond à une clé connue (C3, E9) | `test/unit/` | S |

### P1 — Juice à fort rendement (le cœur du sujet)

| # | Action | Impact |
|---|---|---|
| 13 | **Audio** : `flame_audio`, `SfxService`, ~15 événements branchés (J1) | 🔥🔥🔥 |
| 14 | **Hit-stop + screenshake** pilotés par la magnitude `dégâts / PV max`, avec plafond (J2, J3, B4) | 🔥🔥🔥 |
| 15 | **Le héros attaque** : lunge synchronisé sur `_playMeleeAnimation` + recoil (A1) | 🔥🔥 |
| 16 | **Impacts réels** pour `magic` / `status` / `buff` : burst, onde de choc, flash (A2, A7) | 🔥🔥 |
| 17 | **Idle breathing** déphasé sur héros et ennemis (J7) | 🔥🔥 |
| 18 | **Reposition animée** des ennemis + **stagger** de la pioche (A4, A5) | 🔥🔥 |
| 19 | **Mort mise en scène** : flash → burst → dissolve + micro hit-stop (A3) | 🔥🔥 |
| 20 | **Rythme du tour ennemi** : parallélisation des non-attaques, délais dégressifs, geste « accélérer » (J4) | 🔥🔥 |
| 21 | Feedback de dépense de mana (J5) et de proc de relique (J6) | 🔥 |

### P2 — Variété & signature

| # | Action |
|---|---|
| 22 | `animation` → enum typé + `CardVfxRegistry` avec repli famille (C3, C4) |
| 23 | Signature VFX pour les **6 cartes uniques de classe** + template documenté (C1) |
| 24 | Différencier réellement feu / glace / foudre / poison — le cahier des charges est déjà écrit dans la doc actuelle (B1, B2) |
| 25 | `SlashEffect` paramétré : angle aléatoire, 1-3 traits selon magnitude, couleur élémentaire (B3) |
| 26 | Faire survivre la rareté et les upgrades de forge dans l'animation de jeu (C2) |
| 27 | Unifier les deux sources de vérité de « l'élément » — supprimer `_determineDamageType()` par mots-clés au profit du champ JSON (B5) |
| 28 | Variété d'intent par archétype d'ennemi et par boss + télégraphe (B6, J9) |
| 29 | `VfxBudget` + réglages joueur (vitesse d'animation, effets réduits) (D5, J11) |

---

## 10. Points de vérification

Avant de considérer chaque lot terminé :

- `dart analyze` → 0 issue (règle `CLAUDE.md`)
- `flutter test` → vert, avec le nouveau test de validation des clés `animation`
- Vérification manuelle du **frame budget** en combat AoE à 6 ennemis, pendant le ciblage (le pire cas : D1 + D3 cumulés) — c'est le scénario à mesurer, pas un combat à 2 ennemis
- Toute nouvelle chaîne visible au joueur en `_fr` **et** `_en` (règle `CLAUDE.md`)
- Toute constante d'animation nouvelle dans `vfx_tokens.dart`, jamais en dur dans un composant

---

## 11. Conclusion

La fondation technique est bonne : la séparation `CardAnimator` / `CardComponent` / `CardRenderer` est propre, le pilotage par JSON est le bon choix, et le travail sur les bordures de rareté et la `TargetingLine` montre un vrai souci du détail.

Le problème n'est pas la qualité des animations existantes — c'est leur **couverture** et leur **cohérence** :

1. Le système promet 7 animations et en livre 4.
2. Les cartes les plus identitaires du jeu (les uniques de classe) n'ont aucune identité visuelle.
3. Le héros ne participe pas visuellement à ses propres attaques.
4. **Il n'y a aucun son.**

Les points 1 à 3 relèvent d'un travail incrémental bien cadré, dont le plan P0/P1/P2 ci-dessus donne l'ordre. Le point 4 est d'une autre nature : c'est la moitié manquante du game feel, et aucune quantité de particules ne la compensera.
