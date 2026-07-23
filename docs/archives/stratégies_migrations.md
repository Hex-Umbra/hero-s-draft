# Rapport Détaillé de Stratégie de Migration : Roguelike Card Game

## 1. Contexte et Objectifs
Ce document présente une étude approfondie sur l'évolution technologique du projet "Roguelike Card Game". L'objectif est d'évaluer si le maintien de la stack actuelle (Flutter/Flame) est optimal pour un déploiement multiplateforme total ou si une migration vers des moteurs plus spécialisés "Jeu Vidéo" (Godot, LÖVE) offrirait un meilleur avantage stratégique.

## 2. Analyse de l'Architecture Actuelle (Flutter & Flame)
Le projet utilise actuellement Flutter pour la gestion de l'interface utilisateur et Flame pour le rendu du jeu.

*   **Philosophie :** "UI-First". Le jeu est traité comme une application réactive.
*   **Composants Clés :**
    *   `lib/main.dart` : Point d'entrée.
    *   `lib/game/heros_draft_game.dart` : Moteur de jeu Flame.
    *   `lib/data/models/` : Logique métier et statistiques (Dart).
*   **Avantages identifiés :**
    *   Productivité exceptionnelle pour les menus, inventaires et dialogues (Widgets Flutter).
    *   Déploiement fluide sur Mobile, Web et Desktop avec une seule base de code.
*   **Limites identifiées :**
    *   Flame est moins mature que des moteurs comme Godot pour les effets visuels complexes (particules, shaders).
    *   L'export Web peut souffrir de temps de chargement plus longs dus au runtime Flutter.

## 3. Évaluation des Alternatives Technologiques

### 3.1. L'option TypeScript / Web-Tech
Bien que TypeScript soit puissant, l'approche Web (React + Capacitor + Electron) a été jugée moins intégrée que Flutter pour un jeu vidéo complet. Elle demande de jongler avec plusieurs wrappers pour atteindre toutes les plateformes, ce qui contredit l'objectif de "base de code unique simple".

### 3.2. Godot Engine (L'alternative de puissance)
Godot se présente comme le successeur logique si le projet dépasse les capacités de Flame.

*   **Langages :** 
    *   **C# :** Permet une migration directe (90% de similitude syntaxique avec Dart).
    *   **GDScript :** Idéal pour le prototypage rapide.
*   **Points Forts :**
    *   **Système de Scènes :** Permet de structurer chaque carte comme un objet indépendant avec son propre visuel et sa propre logique.
    *   **UI System :** Très proche des `Row` et `Column` de Flutter via les `HBoxContainer` et `VBoxContainer`.
    *   **Système de Ressources :** Permet de transformer les fichiers comme `entity_stats.dart` en fichiers de données éditables visuellement (`.tres`).
*   **Portabilité :** Excellente. Export natif sur toutes les plateformes cibles.

### 3.3. LÖVE / Lua (L'alternative minimaliste)
LÖVE est un framework "code-only" extrêmement performant.

*   **Langage :** Lua (via LuaJIT), reconnu pour sa rapidité et sa simplicité.
*   **Points Forts :** Poids final du jeu minuscule, démarrage instantané, liberté totale d'architecture.
*   **Défis Majeurs :**
    *   **Taxe UI :** Contrairement à Flutter ou Godot, LÖVE n'a pas de système de boutons ou de fenêtres intégré. Tout doit être codé mathématiquement (détection de collision de souris, états de survol).
    *   **Typage :** Lua n'est pas typé, ce qui augmente le risque de bugs dans la gestion complexe des statistiques de cartes par rapport au Dart/C#.

## 4. Comparatif Technique de Migration

| Critère | Flutter (Actuel) | Godot (C#) | LÖVE (Lua) |
| :--- | :--- | :--- | :--- |
| **Complexité Logique** | Typage Fort (Sûr) | Typage Fort (Sûr) | Typage Dynamique (Flexible/Risqué) |
| **Développement UI** | Native (Widget-based) | Intégrée (Node-based) | Manuelle (Canvas-based) |
| **Performance Jeu** | Bonne | Excellente (GPU optimisé) | Exceptionnelle (LuaJIT) |
| **Écosystème Assets** | Standard | Avancé (Import auto) | Basique (Chargement manuel) |
| **Coût de Migration** | 0 (État actuel) | Moyen (~3 semaines) | Très élevé (> 2 mois) |

## 5. Étude de Cas : Migration de la Logique de Combat
Exemple basé sur la méthode `takeDamage` du modèle de statistiques.

### Dart (Original)
```dart
void takeDamage(int damage) {
  int effectiveDamage = (damage - defense).clamp(0, damage);
  currentHp = (currentHp - effectiveDamage).clamp(0, maxHp);
}
```

### Godot C# (Transition naturelle)
```csharp
// On utilise Mathf pour les calculs et on conserve le typage
public void TakeDamage(int damage) {
    int effectiveDamage = Mathf.Max(0, damage - Defense);
    CurrentHp = Mathf.Clamp(CurrentHp - effectiveDamage, 0, MaxHp);
}
```

### LÖVE Lua (Transition structurelle)
```lua
-- On doit recréer manuellement la structure de classe
function EntityStats:takeDamage(damage)
    local effective = math.max(0, damage - self.defense)
    self.currentHp = math.max(0, math.min(self.maxHp, self.currentHp - effective))
end
```

## 6. Synthèse et Recommandations Finales

1.  **Recommandation Court Terme :** Conserver **Flutter/Flame**. Le projet est déjà structuré et fonctionnel. La productivité sur l'UI (qui représente 70% d'un jeu de cartes) est imbattable.
2.  **Recommandation Moyen Terme (Migration) :** Si le besoin d'effets visuels avancés ou d'un éditeur de niveaux/cartes se fait sentir, **Godot en C#** est l'unique choix rationnel. Il permet de récupérer la quasi-totalité de la logique Dart tout en offrant un environnement de jeu professionnel.
3.  **Mise en garde :** La migration vers **LÖVE** est déconseillée pour ce type de projet spécifique, car l'effort nécessaire pour reconstruire un système d'interface utilisateur équivalent à celui de Flutter serait disproportionné par rapport au gain de performance.

## 7. Conclusion
Le projet possède une base solide. Une migration n'est pas une nécessité technique immédiate mais une option stratégique. Le choix de Godot garantirait la pérennité du projet sur le long terme pour des ambitions graphiques plus élevées, tout en respectant l'exigence initiale de multiplateforme unique.
