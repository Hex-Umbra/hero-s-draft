# Analyse Technique des Évolutions Futures - Rapport 2 (Flutter / Flame / Riverpod)

Ce document fait suite au premier rapport d'analyse et se concentre sur l'implémentation technique des concepts avancés introduits dans le second prototype d'évolution (`2_proto_futures_evols.md`).

## 1. Profondeur du Gameplay & Mécaniques de Combat

### A. Système d'Altérations d'État (Buffs/Debuffs)
*   **Le concept :** Ajouter des modificateurs temporaires ou permanents (Poison, Régénération, Puissance).
*   **Implémentation technique :** 
    *   **Modèles :** Créer un modèle `StatusEffect` avec un identifiant, un type (buff/debuff), une valeur et une durée (tours).
    *   **Logic (Riverpod) :** Mettre à jour `EntityStats` (ou le controller associé) pour inclure une `List<StatusEffect>`.
    *   **Calcul :** Modifier le `EffectResolver` pour qu'il prenne en compte ces statuts lors du calcul final des dégâts ou des soins (ex: `finalDamage = baseDamage * powerMultiplier`).
    *   **UI :** Afficher des icônes miniatures sous la barre de vie des entités avec un compteur numérique pour la durée/valeur.

### B. Types de Cartes Spéciaux (Pouvoirs et Malédictions)
*   **Le concept :** Cartes à effets permanents ou cartes nuisibles ajoutées au deck.
*   **Implémentation technique :**
    *   **Enum :** Ajouter un `CardType { attack, skill, power, curse }` au modèle `CardData`.
    *   **Pouvoirs :** Lors de l'activation d'une carte "Power", l'ajouter à une liste `activePowers` dans le `RunController`. Ces pouvoirs émettent des modifications globales (ex: +1 Mana par tour).
    *   **Malédictions :** Utiliser la méthode `deckController.addToDeck(curseCard)` pendant un combat. Ces cartes n'ont souvent pas d'effet positif et sont détruites à la fin du combat ou nécessitent un coût pour être jouées.

### C. Reliques et Objets Passifs
*   **Le concept :** Objets collectés durant la run modifiant les règles du jeu.
*   **Implémentation technique :**
    *   **Architecture :** Utiliser un système de "Hooks". Les reliques s'abonnent à des événements via Riverpod (ex: `ref.listen(deckProvider)` pour réagir à une pioche).
    *   **Stockage :** `List<RelicData>` dans le `RunState`. Chaque relique possède une logique `apply(GameState state)` déclenchée aux moments clés.

---

## 2. Interface et Expérience Utilisateur (UI/UX)

### A. Identité Sonore (BGM & SFX)
*   **Implémentation technique :** 
    *   Utiliser le package `flame_audio`.
    *   Créer un `AudioManager` (Singleton ou Provider) gérant le cache des sons (`FlameAudio.audioCache.loadAll`).
    *   **BGM :** `FlameAudio.bgm.play('battle_theme.mp3')` avec gestion du volume et transitions fluides (fade-in/out).
    *   **SFX :** Déclencher les bruits d'impact (`playSfx('hit.wav')`) directement dans les méthodes d'animation des composants Flame.

### B. VFX Avancés et "Juice"
*   **Implémentation technique (Flame) :**
    *   **Particules :** Utiliser `ParticleSystemComponent` pour créer des effets de sang ou d'étincelles lors des impacts. Configurer le `Lifespan` et l'accélération pour un rendu dynamique.
    *   **Screen Shake :** Implémenter une extension sur `CameraComponent` pour appliquer une vibration aléatoire de faible amplitude (`intensity`) pendant une durée déterminée lors d'un coup critique.
    *   **Combat Log :** Un widget Flutter `ListView.builder` superposé (Overlay) qui écoute un `LogProvider` et affiche les dernières actions ("Joueur utilise Frappe : 10 dégâts").

---

## 3. Structure de Run et Solidification Technique

### A. World Map (Navigation Procédurale)
*   **Le concept :** Un arbre de progression permettant de choisir son chemin.
*   **Implémentation technique :** 
    *   **Algorithme :** Générer un graphe acyclique dirigé (DAG) simple au début de la run.
    *   **UI :** Créer un `MapScreen` en Flutter. Chaque nœud est un `IconButton` ou un widget personnalisé. Utiliser un `CustomPainter` pour dessiner les lignes de connexion entre les nœuds accessibles.

### B. Tests et Robustesse
*   **Implémentation technique :**
    *   **Unit Tests :** Tester le `EffectResolver` de manière exhaustive (cas limites des buffs, calcul des armures, cumul de poison).
    *   **Widget Tests :** Vérifier que les écrans de Draft et de Sélection de classe réagissent correctement aux clics et affichent les bonnes données.
    *   **i18n :** Utiliser `flutter_localizations`. Déplacer toutes les chaînes de caractères des JSON et de l'UI vers des fichiers `.arb` ou des dictionnaires JSON par langue (`fr.json`, `en.json`).

---

## Feuille de Route Suggérée (Priorisation 2)

Pour cette seconde phase d'évolution, voici l'ordre recommandé :

1.  **Mécaniques (P1) :** Implémenter le système de Buffs/Debuffs de base, car il est le pilier de la profondeur stratégique.
2.  **Audio & Juice (P1) :** Ajouter les sons et les premières particules pour transformer radicalement l'expérience utilisateur.
3.  **Progression (P2) :** Mettre en place la World Map et le système d'Or/Boutique pour étendre la durée de vie d'une run.
4.  **Solidification (P3) :** Finaliser avec les tests automatisés et l'optimisation des assets (Sprite Sheets).
