# ⚔️ Hero's Draft - Roguelike Deckbuilder

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Flame](https://img.shields.io/badge/Flame-%23E040FB.svg?style=for-the-badge&logo=flame&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-%23000000.svg?style=for-the-badge&logo=dart&logoColor=white)

**Hero's Draft** est un Roguelike Deckbuilder dynamique, pensé pour offrir un "game feel" percutant et une architecture technique irréprochable. Développé avec **Flutter** et le moteur **Flame**, le jeu propose des combats tactiques, une progression procédurale sur carte, et une architecture 100% *Data-Driven*.

Site officiel: https://heros-draft.vilarserver.com/

---

## ✨ Key Features (Gameplay & Game Feel)

Le jeu a été conçu pour offrir une expérience fluide, réactive et stratégique, s'inspirant des références du genre tout en y ajoutant une forte dose de dynamisme (Visual Juice).

*   **🃏 Dynamic Combat & Visual Juice** : Le maniement des cartes est organique (tilt, inertie lors du glisser-déposer). Jouer une carte déclenche une séquence d'attaque percutante avec recul d'anticipation, impact visuel, tremblements d'écran (shake) et explosions de particules.
*   **🗺️ Strategic World Map** : L'exploration n'est plus linéaire. Les joueurs naviguent sur un graphe procédural généré dynamiquement. La carte inclut des chemins animés, des culs-de-sac stratégiques (chokepoints) et différents types de nœuds : Combats, Élites, Boss, Boutiques, Feux de camp et Événements narratifs.
*   **⚙️ Deep Mechanics & Traits** : 
    *   **Classes Uniques** : Paladin, Berserker, Mage, chacun possédant des traits passifs exclusifs (ex: régénération d'armure, gain de puissance selon les PV manquants).
    *   **Altérations d'État** : Gestion complète des buffs/debuffs (Poison, Force, Faiblesse, Régénération).
    *   **Système de Reliques** : Objets passifs modifiant l'économie de la partie.
*   **💰 Deckbuilding & Economy** : Gestion stricte du Mana (réinitialisé chaque tour), système de Draft post-combat avec **Auto-Merge** (fusionner 3 cartes identiques pour les améliorer), et une Boutique interactive pour affiner son deck ou retirer des cartes.

---

## 🏗️ Under the Hood (Architecture Technique)

Hero's Draft n'est pas qu'un jeu, c'est un moteur de deckbuilder robuste et extensible.

### The Power Couple : Flame 🤝 Riverpod
Le projet sépare strictement le rendu de la logique métier :
*   **Riverpod (Cerveau)** : Gère l'état global. Le `RunController` supervise les statistiques du joueur, les reliques et la progression sur la carte. Le `DeckController` gère la logique des piles (Main, Pioche, Défausse, Épuisement) de manière purement logique.
*   **Flame (Muscles)** : Gère la boucle de jeu, les entités (`PositionComponent`) et les animations. Les composants Flame écoutent les changements de Riverpod pour se mettre à jour, garantissant qu'aucun bug visuel ne puisse corrompre l'état de la partie.
*   **Flutter (Interface)** : Gère le HUD, les barres de vie, les modales fluides (Boutique, Repos) et les tooltips interactifs par-dessus le canvas Flame.

### 100% Data-Driven Heart
Pas de cartes ou d'ennemis codés en dur. Tout le contenu du jeu est externalisé dans des fichiers JSON (`assets/data/`). Le moteur lit ces fichiers au démarrage. 
Pour équilibrer le jeu, nerfer un ennemi ou modifier le coût en mana d'une carte, il suffit de changer une ligne dans un JSON, sans jamais recompiler le code métier.

### Responsivité Dynamique
Le jeu intègre un système de scaling sur mesure. Le moteur Flame s'adapte à la hauteur de l'écran, recalculant instantanément la taille et la position relative des cartes, des ennemis et de l'arène, garantissant une expérience parfaite du mobile au moniteur 4K.

---

## 🛠️ Developer Guide

### Lancer le projet
Hero's Draft est un projet Flutter standard. Assurez-vous d'avoir Flutter SDK (>= 3.11.4) installé.

```bash
# Récupérer les dépendances
flutter pub get

# Lancer sur l'appareil par défaut
flutter run

# Lancer les tests (génération de carte, résolution d'effets, etc.)
flutter test
```

### Modding (Ajouter du contenu)
Grâce à l'architecture Data-Driven, étendre le jeu est trivial. **Une entité = un fichier**, et
**le répertoire fait autorité** : une carte rangée dans `classes/paladin/cards/` *est* une carte du
paladin, le chargeur l'en déduit, sans qu'aucun champ du fichier n'ait à le dire.

```
assets/data/
├── cards/<id>.json              # carte neutre
├── relics/<id>.json             # idem pour events/, forge_upgrades/, passives/
├── classes/<id>/                # un dossier auto-suffisant par classe
│   ├── class.json
│   ├── icon.png
│   └── cards/<id>.json          # cartes propres à la classe
└── enemies/<id>/                # un dossier auto-suffisant par ennemi
    ├── enemy.json
    └── sprite.png
```

1. **Créez un fichier** dans le bon répertoire — le nom du fichier **est** l'`id` de l'entité
   (`relics/iron_talisman.json` → `"id": "iron_talisman"`), en `snake_case` ASCII minuscule.
   Pour une classe ou un ennemi, c'est un **dossier** que l'on crée, image comprise ; l'`id` vient
   alors du nom du dossier. Le plus simple reste de copier une entité voisine et d'en changer les
   valeurs (nom, coût, effets, pv) — copier un fichier n'écrase plus jamais du contenu existant.
2. **Lancez `dart run tool/sync_assets.dart`** pour régénérer la section `assets:` de
   `pubspec.yaml`. Les déclarations d'assets de Flutter ne sont récursives à aucun niveau : chaque
   nouveau dossier de classe ou d'ennemi exige sa propre ligne, et un dossier non déclaré se charge
   en développement puis disparaît en build, **sans le moindre message**. `--check` sort en 1 si la
   section a dérivé ; la CI s'en sert.
3. **Relancez l'application.** La nouvelle carte ou le nouvel ennemi est déjà dans le jeu, pris en
   compte par la Boutique, les récompenses et le système de combat !

*Note : n'écrivez pas les champs que le répertoire impose — `heroClass` et `category` dans le
fichier d'une carte font échouer le chargement. Seul l'`id` peut être redéclaré, à condition d'être
identique, parce qu'il rend le fichier lisible hors de son contexte.*

*Note : toute entrée à texte visible porte ses deux variantes `_fr` et `_en`.*

*Note: Pensez à toujours lancer `dart analyze` après une modification du code.*

---

## Publier une version

1. Faire rédiger les patch notes par le skill `patch-notes-writer` — il écrit
   l'entrée dans `assets/data/patch_notes.json` et synchronise `pubspec.yaml`
   ainsi que `site/_site/versions.json`, dont il rafraîchit aussi les liens de
   repli dans `site/index.html` et `site/versions.html`.
2. Committer et pousser sur `main`.
3. Poser le tag correspondant :

   ```bash
   git tag v0.4.8
   git push origin v0.4.8
   ```

Le pipeline vérifie que le tag, `pubspec.yaml`, `patch_notes.json` et
l'entrée `current` de `site/_site/versions.json` concordent, puis déploie le
web sur `/v0.4.8/` et publie une pre-release GitHub avec le build Windows.

En cas d'échec, « Re-run failed jobs » est sûr sur tous les jobs. Si le tag
lui-même est erroné, le supprimer (`git push --delete origin v0.4.8`), corriger,
et le reposer.

---

## 🚀 Roadmap & Status

Le moteur de base et l'architecture complète sont **terminés et fonctionnels** (Phases 1 à 12 validées).

**À venir :**
*   **Musique** : les 4 pistes musicales restent à sourcer (chantiers P-46 et P-47). Le moteur audio et les 31 bruitages sont livrés depuis la version 0.5.0.
*   **Plus de Profondeur** : Nouvelles reliques, nouveaux archétypes de cartes (Malédictions à jouer) et de nouveaux événements narratifs.
*   **Polissage Final** : Équilibrage des derniers pourcentages, animations spécifiques aux boss, et préparation pour les plateformes de distribution.
