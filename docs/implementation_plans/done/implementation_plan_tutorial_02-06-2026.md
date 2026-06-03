# Plan d'Implémentation : Tutoriel Hero's Draft

> **Décisions validées :** Tutoriel bilingue FR/EN ✅ — Rejouable depuis le menu ✅ — Interaction carte = tap simple (recommandé) ✅

## Objectif

Créer un tutoriel **standalone** et complet qui enseigne tous les concepts du jeu dans son propre répertoire (`lib/tutorial/`), sans dépendre de la progression de la vraie run. Le tutoriel se terminera par l'effet hover sur le draft, intégré dans la vraie `DraftScreen`.

---

## Architecture & Philosophie

> [!IMPORTANT]
> Le tutoriel vit dans `lib/tutorial/` et est **complètement auto-suffisant**. Il possède ses propres états, ses propres widgets simplifiés et ses propres données mockées. Il ne touche **aucun provider Riverpod de production** (pas de `runProvider`, pas de `deckProvider`, pas de `combatProvider`).

Le flux est un **tunnel séquentiel d'étapes** (`TutorialStep`) géré par un `TutorialEngine` (simple `ChangeNotifier`). Chaque étape se compose de :
- Un **widget d'illustration** (mini-simulation interactive ou visuel statique)
- Un **panneau de texte explicatif** avec titre + description
- Un **bouton de progression** (Suivant / Essayer / Terminer)

L'écran principal (`TutorialScreen`) est un `PageView` sans swipe manuel — seul le bouton de progression avance.

---

## Étapes du Tutoriel (13 étapes)

| # | Concept | Interaction |
|---|---------|-------------|
| 1 | Bienvenue & Présentation du jeu | Visuel statique |
| 2 | La Carte du Monde (Map) | Mini-map interactive (nœuds cliquables) |
| 3 | Les Types de Rencontres | Galerie des 5 types de nœuds |
| 4 | Le Combat — Vue d'ensemble | Illustration annotée du layout |
| 5 | Les Cartes & le Mana | Main de cartes mockée, drag simulé |
| 6 | Jouer une carte | Interaction réelle : jouer une carte sur un ennemi |
| 7 | Armure & Dégâts | Simulation de dégâts avec/sans armure |
| 8 | Les Effets Élémentaires (Statuts) | Galerie des effets : Poison, Feu, Glace, Foudre |
| 9 | Les Ennemis & leurs Intentions | Lecture des icônes d'intention |
| 10 | La Fusion de Cartes | Simulation de merge (3 → 1) |
| 11 | L'Expérience & le Level Up | Barre XP animée, gain de niveau |
| 12 | Le Draft de Récompenses | `DraftCardReel` mockés, choix simulé |
| 13 | Les Reliques (Élite & Boss) | `RelicCarouselScreen` simplifié |

---

## Proposed Changes

### Phase 1 — Infrastructure Tutoriel

---

#### [NEW] `lib/tutorial/tutorial_engine.dart`

Cœur du système. `TutorialEngine extends ChangeNotifier` :
- `int currentStepIndex` — étape courante (0-12)
- `TutorialMockState mockState` — état simulé du tutoriel (PV, mana, main de cartes, etc.)
- `void nextStep()` — avance à l'étape suivante
- `void prevStep()` — retour (optionnel)
- `bool get isLastStep` — vrai à l'étape 12
- `void resetMockState()` — réinitialise l'état simulé entre étapes

**`TutorialMockState`** — POJO simple (pas de Riverpod) :
```dart
class TutorialMockState {
  int heroHp = 80; int heroMaxHp = 80;
  int heroMana = 3; int heroMaxMana = 3;
  int heroArmor = 0;
  List<TutorialCard> hand = [];
  List<TutorialCard> deck = [];
  TutorialEnemy? enemy;
  int playerXp = 0; int xpToNextLevel = 100;
  int playerLevel = 1;
}
```

**`TutorialCard`** — version allégée de `CardInstance` sans dépendance au modèle de prod :
```dart
class TutorialCard {
  final String id, nameEn, nameFr;
  final int cost, damage, armor;
  final String? effectType; // 'poison', 'fire', 'ice', 'lightning'
  final bool isAoe;
}
```

**`TutorialEnemy`** — version allégée :
```dart
class TutorialEnemy {
  String name; int hp; int maxHp;
  int armor; String intentIcon; int intentValue;
  List<String> activeStatuses;
}
```

---

#### [NEW] `lib/tutorial/tutorial_step.dart`

Définition d'une étape :
```dart
class TutorialStep {
  final String titleFr, titleEn;
  final String bodyFr, bodyEn;
  final TutorialStepType type;
  final String? highlightZone; // zone à surbrillance
}

enum TutorialStepType {
  welcome, map, nodeTypes, combatOverview,
  cards, playCard, armorDamage, elements,
  enemies, merge, xp, draft, relics,
}
```

---

#### [NEW] `lib/tutorial/tutorial_data.dart`

Constante statique `List<TutorialStep> kTutorialSteps` : la liste complète des 13 étapes avec textes FR/EN.

---

#### [NEW] `lib/tutorial/tutorial_progress_service.dart`

Service de persistance (`SharedPreferences`) :
- `static Future<bool> hasCompletedTutorial()` — lu au lancement
- `static Future<void> markTutorialCompleted()` — écrit à la fin
- `static Future<void> resetTutorial()` — debug/reset

Utilisé dans `HomeScreen` pour afficher une pastille "Nouveau" sur le bouton tutoriel si jamais vu.

---

### Phase 2 — Écran Principal & Widgets Tutoriel

---

#### [NEW] `lib/tutorial/tutorial_screen.dart`

`TutorialScreen extends StatefulWidget` — l'écran hôte :
- Crée un `TutorialEngine` local (pas de provider global)
- `PageController _pageController` (non swipeable, scroll programmé)
- `AnimatedBuilder` sur `_engine` → rebuild à chaque `nextStep()`
- Layout fixe en 2 zones :
  - **Zone haute (60% screen)** : widget d'illustration de l'étape
  - **Zone basse (40% screen)** : panneau de texte + boutons
- Bouton "✕ Passer" en haut à droite → `Navigator.pop()`
- Barre de progression (13 pointillés, l'actif en amber)

**Navigation** : lancement via `Navigator.push()` depuis `HomeScreen`.
**Complétion** : appelle `TutorialProgressService.markTutorialCompleted()` puis `Navigator.pop()`.

---

#### [NEW] `lib/tutorial/widgets/` *(répertoire des widgets propres au tuto)*

##### `lib/tutorial/widgets/tutorial_welcome_widget.dart`
Logo du jeu animé + texte d'intro. Pas d'interaction.

##### `lib/tutorial/widgets/tutorial_map_widget.dart`
Mini-map interactive avec 5-6 nœuds factices (`TutorialMapNode`). Le joueur peut **taper un nœud** pour voir son tooltip. Icônes des 5 types. Pas de connexion aux vrais providers.

Architecture :
- `CustomPaint` pour les connexions
- Nœuds `GestureDetector` avec tooltips animés
- Réutilise le **style visuel** de `MapNodeWidget` mais sans logique de navigation

##### `lib/tutorial/widgets/tutorial_node_types_widget.dart`
Grille 2×3 des types de nœuds avec icône + nom + description courte :
- ⚔️ Combat — rencontre standard
- 👑 Élite — groupe puissant, récompense relique
- 🏪 Boutique — acheter cartes et objets
- 🏕️ Repos — soins ou forge d'une carte
- 🎭 Événement — choix narratif
- 💀 Boss — fin d'acte, relique garantie

##### `lib/tutorial/widgets/tutorial_combat_overview_widget.dart`
Capture annotée du layout de combat. Un `Stack` avec des flèches et labels pointant les zones (HUD joueur, zone ennemis, main de cartes, bouton fin de tour). Les annotations apparaissent successivement (délai animé). Entièrement statique — pas de Flame.

##### `lib/tutorial/widgets/tutorial_cards_widget.dart`
Affiche 3 cartes mockées (`TutorialCard`) en bas de l'écran comme en combat. Les cristaux de mana au-dessus. Chaque carte a un coût affiché. Interaction : taper sur une carte la "sélectionne" (bordure amber). Explication inline : "Chaque cristal 💎 = 1 mana. Cette carte coûte 2 mana."

Réutilise visuellement `UiCard` mais passe des données mockées.

##### `lib/tutorial/widgets/tutorial_play_card_widget.dart`
**Étape interactive clé.** Un ennemi (Slime tutoriel, 20 PV) et une main de 2 cartes :
- "Frappe Basique" (coût 1, 6 dégâts)
- "Défense" (coût 1, +4 armure)

Le joueur **doit** jouer une carte pour continuer. Réplique fidèlement le drag-and-drop (ou tap pour sélectionner + tap sur ennemi). Utilise uniquement `TutorialEngine.mockState` — aucune logique de prod.

Animation : chiffre de dégâts flottant (réutilise `FloatingText` de Flame ou un équivalent Flutter simple).

##### `lib/tutorial/widgets/tutorial_armor_widget.dart`
Split-screen animé :
- Gauche : héros sans armure prend 10 dégâts → −10 PV
- Droite : héros avec 4 armure prend 10 dégâts → armure = 0, −6 PV

Bouton "Voir la différence" → lance les deux animations simultanément avec des `AnimatedContainer` sur les barres de PV/armure.

##### `lib/tutorial/widgets/tutorial_elements_widget.dart`
Galerie scrollable horizontale des 4 effets de statut. Chaque carte d'effet :
```
[Icône grande]
Nom de l'effet
"Inflige X dégâts par tour pendant Y tours."
Exemple visuel (barre qui se vide)
```
Effets couverts : 🟢 Poison, 🔥 Brûlure, ❄️ Gel, ⚡ Foudre.

##### `lib/tutorial/widgets/tutorial_enemy_intents_widget.dart`
Liste des 4 icônes d'intention avec explication :
- Épée rouge → va attaquer (valeur affichée)
- Bouclier bleu → va se défendre
- Flèche violette → va se renforcer
- ❓ → intention cachée (actes avancés)

Chaque icône est tappable pour voir une description plus longue. Réutilise visuellement les icônes de `EnemyIntentsPanel`.

##### `lib/tutorial/widgets/tutorial_merge_widget.dart`
Animation interactive de la fusion :
1. Affiche 3 cartes "Frappe Basique Niv.1" identiques
2. Bouton "Fusionner" → animation de combinaison (les 3 cartes glissent vers le centre, effet de flash)
3. Résultat : 1 carte "Frappe Basique Niv.2" avec stats améliorées
4. Texte : "Fusionner 3 cartes identiques les améliore !"

Animations via `AnimationController` + `Tween<Offset>`.

##### `lib/tutorial/widgets/tutorial_xp_widget.dart`
Barre XP interactive :
1. Barre XP = 0/100
2. Bouton "Battre un ennemi" → +35 XP animé (barre se remplit)
3. Bouton encore → +35 XP
4. Bouton encore → barre atteint 100, animation Level Up (flash doré, "+1 Niveau !")
5. Texte explicatif sur le draft de récompenses qui suit.

##### `lib/tutorial/widgets/tutorial_draft_widget.dart`
3 `DraftCardReel` mockés **non-animés** (initialement landed = true, pas de slot-machine). Les cartes sont directement lisibles. Taper une carte → animation de scale-up (1.0 → 1.15) + bordure dorée animée + `onTap` qui marque "choisi". Texte : "Choisissez une amélioration après chaque level up."

> [!NOTE]
> C'est ici que l'effet hover/sélection du draft est développé et testé. Le même code `AnimatedScale` + bordure sera ensuite copié dans la vraie `DraftScreen`.

##### `lib/tutorial/widgets/tutorial_relics_widget.dart`
Version simplifiée du `RelicCarouselScreen` :
- 1 relique factice affichée (ex: "Talisman de Fer")
- Description : "Obtenu après chaque Elite ou Boss"
- Liste des raretés avec couleurs (Commun → Légendaire)
- Bouton "Collecter" → animation de collection

---

### Phase 3 — Intégration & Finitions

---

#### [MODIFY] `lib/ui/screens/home_screen.dart`

Ajouter un bouton "📖 TUTORIEL" entre "JOUER" et "DICTIONNAIRE" :
```dart
OutlinedButton(
  onPressed: () => Navigator.push(context,
    MaterialPageRoute(builder: (_) => const TutorialScreen())),
  child: const Text('TUTORIEL'),
)
```

Le bouton est toujours visible (tutoriel rejouable). Pastille "NOUVEAU" si `hasCompletedTutorial() == false`, gérée via `FutureBuilder`.

---

#### [MODIFY] `lib/ui/screens/draft_screen.dart`

Ajouter `AnimatedScale` + effet de sélection sur les `DraftCardReel`. Logique développée dans `tutorial_draft_widget.dart` et copiée ici.

Chaque `DraftCardReel` enveloppé dans :
```dart
AnimatedScale(
  scale: _selectedIndex == index ? 1.12 : (hoveredIndex == index ? 1.05 : 1.0),
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOut,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: _selectedIndex == index
          ? [BoxShadow(color: Colors.amber.withAlpha(200), blurRadius: 20, spreadRadius: 4)]
          : [],
    ),
    child: DraftCardReel(...),
  ),
)
```

Sur desktop/web : `MouseRegion` pour le hover.
Sur mobile : `GestureDetector` + `onTapDown` + `onTapUp` pour simuler le hover.

---

## Fichiers Récapitulatifs

### Nouveaux fichiers
```
lib/tutorial/
├── tutorial_engine.dart         ← TutorialEngine (ChangeNotifier), TutorialMockState
├── tutorial_step.dart           ← TutorialStep, TutorialStepType
├── tutorial_data.dart           ← kTutorialSteps (constantes, 13 étapes)
├── tutorial_progress_service.dart ← SharedPreferences (hasCompleted, markCompleted)
├── tutorial_screen.dart         ← Écran principal hôte (PageController)
└── widgets/
    ├── tutorial_welcome_widget.dart
    ├── tutorial_map_widget.dart
    ├── tutorial_node_types_widget.dart
    ├── tutorial_combat_overview_widget.dart
    ├── tutorial_cards_widget.dart
    ├── tutorial_play_card_widget.dart     ← Étape interactive principale
    ├── tutorial_armor_widget.dart
    ├── tutorial_elements_widget.dart
    ├── tutorial_enemy_intents_widget.dart
    ├── tutorial_merge_widget.dart
    ├── tutorial_xp_widget.dart
    ├── tutorial_draft_widget.dart         ← Source de vérité pour l'effet hover
    └── tutorial_relics_widget.dart
```

### Fichiers modifiés
```
lib/ui/screens/home_screen.dart   ← +bouton Tutoriel, pastille "NOUVEAU"
lib/ui/screens/draft_screen.dart  ← +AnimatedScale hover/sélection sur DraftCardReel
```

### Dépendances à ajouter (pubspec.yaml)
- `shared_preferences: ^2.x.x` — si pas déjà présent (pour `TutorialProgressService`)

---

## Questions Ouvertes

> [!NOTE]
> **Interaction de la carte jouée** (étape 6) : Simplifié en **tap-to-select + tap-enemy** (pas de drag Flame). Tap sur une carte → elle se surligne. Tap sur l'ennemi → dégâts appliqués. Retenu par défaut.

> [!NOTE]
> **`shared_preferences`** : À vérifier si la dépendance est déjà dans `pubspec.yaml`. Si non, il faudra l'ajouter.

### Décisions validées ✅

| Question | Décision |
|----------|----------|
| Langue du tutoriel | **Bilingue FR/EN** — textes en FR+EN dans `TutorialData`, servis via `Localizations.localeOf(context)` |
| Rejouabilité | **Toujours rejouable** — bouton visible en permanence dans le menu, `markTutorialCompleted()` sert uniquement à masquer la pastille "NOUVEAU" |

---

## Plan de Vérification

### Tests automatisés
- `flutter test test/tutorial/tutorial_engine_test.dart` — vérifie la progression des étapes, reset du mock state
- `flutter test test/tutorial/tutorial_progress_service_test.dart` — vérifie la persistance SharedPreferences

### Vérification manuelle
1. Lancer l'app → bouton "TUTORIEL" visible dans le menu principal
2. Parcourir toutes les 13 étapes sans erreur
3. Étape 6 : jouer une carte → l'ennemi prend des dégâts dans la simulation
4. Étape 10 : appuyer sur "Fusionner" → animation de merge correcte
5. Étape 11 : cliquer 3× "Battre un ennemi" → Level Up animé déclenché
6. Étape 12 : tapper une carte de draft → effet de scale-up + bordure dorée
7. Fin du tutoriel → retour au menu, pastille "NOUVEAU" disparaît
8. Relancer le tutoriel depuis le menu → fonctionne
9. Vérifier la vraie `DraftScreen` : hover/sélection sur les cartes de récompense fonctionnel
10. `dart analyze` → 0 erreur

