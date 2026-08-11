# Système de Carte : Structure des Nœuds et Identité Visuelle

**Date** : 11/08/2026
**Contexte** : Analyse du système de carte du monde existant (`MapGeneratorService` et ses quatre sous-services, `MapScreen`, `MapNodeWidget`, `MapConnectionPainter`, `MapProgressionManager`) à la recherche d'améliorations, avec une insistance particulière sur le rendu visuel de la carte et des nœuds. L'analyse a fait remonter dix-sept constats répartis en trois familles : structure du code de rendu, qualité visuelle, et variété de génération.
**Statut** : Brainstorm — pistes validées par échange, **rien encore implémenté**.
**Objectif retenu** : la génération est saine et testée, elle ne bouge pas. Le chantier porte sur le **rendu** et sur le **socle de données qui le pilote**. L'ordre importe : tant que l'identité visuelle d'un nœud est réécrite dans quatre fichiers, chaque amélioration visuelle coûte quatre fois son prix, et chaque nouveau type de nœud aussi.

---

## 1. État des lieux du système actuel

### 1.1 Pipeline de génération

Quatre étapes séquentielles orchestrées par `MapGeneratorService.generateMap` (`map_generator_service.dart:14`) :

| Étape | Service | Rôle |
|:---|:---|:---|
| 1 | `MapNodeGenerator` | 10 étages, 2 à 5 nœuds par étage, positions, contraintes structurelles |
| 2 | `MapConnectionBuilder` | DAG étage → étage+1, offsets −1/0/+1, passe anti-orphelins |
| 3 | `MapValidator` | Quotas globaux + règle anti-répétition (jamais 3 Élite ou 3 Repos d'affilée) |
| 4 | `MapContentPlacer` | Autel des Reliques (acte ≥ 5), Forge de Fusion (25 %) |

Squelette forcé, identique à chaque acte : étage 0 en combat, étage 5 en chokepoint Élite à nœud unique, étage 8 en repos garanti, étage 9 avec exactement 3 boss porteurs de récompenses distinctes (`cards`, `doubleXp`, `improvedRelic`).

Quotas dans `GameConstants.nodeQuotas` (`game_constants.dart:25`) : combat 12-22, élite 3-6, repos 3-6, boutique 2-5, événement 4-9. Poids de tirage en dur dans `getRandomNodeType` (`map_node_generator.dart:6`) : 60 / 15 / 10 / 10 / 5.

### 1.2 Chaîne de rendu

**La carte est du Flutter pur — aucun composant Flame n'y intervient.** `MapScreen` (418 lignes) empile dans un `InteractiveViewer` un `CustomPaint` pour les liaisons, puis un `MapNodeWidget` par nœud en positionnement absolu, puis le `PlayerPawn`. Fond : un `RadialGradient` beige défini deux fois, dans `ScreenScaffold` et à nouveau dans `MapScreen` (`map_screen.dart:227-237`).

---

## 2. Ce qui est solide et ne doit pas bouger

- **La décomposition en quatre services** est exemplaire et documentée dans `_patterns/03-2-mapgeneratorservice-generateur-de-graphe-de-c.md`.
- **La couverture de tests est réelle** : 11 tests de génération (`test/unit/map_generator_test.dart`) couvrant l'absence de culs-de-sac, l'accessibilité de tous les nœuds, le chokepoint, le repos garanti, et les quotas vérifiés sur de multiples runs successifs ; plus 5 tests widget (`test/unit/map_screen_test.dart`).
- **`map_screen.dart` fait 418 lignes**, pas 2 471 comme l'affirme encore `progress.md` §4. La dette de taille est close depuis le 24/07.
- **Le path highlighting** (`map_path_highlighter.dart`) et **le pion animé** existent déjà : deux des trois priorités de l'analyse archivée de mai 2026 sont livrées.
- **Les pointillés animés** évitent délibérément `Path` au profit d'un calcul clampé, avec un commentaire justifiant le choix par une fuite mémoire WASM (`map_connection_painter.dart:65`). C'est du code réfléchi, à ne pas « simplifier ».

---

## 3. Constats — famille « structure du code de rendu »

### 3.1 L'identité visuelle d'un nœud est écrite quatre fois

Le couple icône + couleur + libellé est réécrit à la main dans :

1. `map_node_widget.dart:81-125` — le `switch` de rendu
2. `map_node_widget.dart:34-73` — un **second** `switch`, pour les tooltips
3. `map_legend.dart:83-136` — la légende, en dur
4. `tutorial_map_widget.dart` et `tutorial_node_types_widget.dart` — de nouveau en dur

C'est le constat central du document. Ajouter un sprite n'est pas « modifier un widget » : c'est modifier quatre fichiers en maintenant quatre listes synchronisées. Ajouter les nœuds Trésor et Mystère prévus en **P-31** coûte exactement le même prix.

**La synchronisation est déjà cassée** : la clé `legendBossXp` existe dans les deux fichiers ARB et n'est référencée nulle part dans `lib/` — elle a été contournée par un ternaire codé en dur (`map_legend.dart:130`).

### 3.2 Violation de la règle de localisation du projet

`CLAUDE.md` impose des variantes `_fr` / `_en` sur toute entrée à texte visible. L'Autel des Reliques et la Forge de Fusion utilisent à la place des `isFr ? "..." : "..."` en dur dans le code UI (`map_node_widget.dart:47-61`, `map_legend.dart:109-119`). Aucune clé ARB n'existe pour ces deux types.

### 3.3 Le décalage magique `+80.0` est recopié à cinq endroits

`map_connection_painter.dart:51` et `:54`, `map_node_widget.dart:131`, `player_pawn.dart:15`, `map_screen.dart:343`. Modifier un seul de ces cinq désaligne silencieusement les liaisons, les nœuds, le pion ou la caméra les uns par rapport aux autres.

### 3.4 Le painter refait une recherche linéaire à chaque frame

`MapConnectionPainter` est construit avec `repaint: animation` et exécute un `firstWhere` sur la liste complète des nœuds pour **chaque** liaison, **à chaque frame** (`map_connection_painter.dart:44`), le tout dans un `try/catch`. Sur une carte de ~35 nœuds cela représente plusieurs milliers de comparaisons par frame, en continu, tant que l'écran est affiché. Les segments devraient être calculés une fois et réutilisés.

### 3.5 `bossEnemyId` est un champ mort

Déclaré `String? bossEnemyId;` (`map_node_generator.dart:42`), **jamais assigné**, puis transmis au `MapNode` (`:74`). Il vaut donc toujours `null`, et le test l'entérine (`expect(bossNode.bossEnemyId, isNull)`). En aval, `game_screen.dart:224` le lit systématiquement à `null` : la sélection de boss nommés est une fonctionnalité inachevée, pas un mécanisme actif. `CLAUDE.md` interdit le code mort en dépôt.

### 3.6 `MapNode.position` est typé `Vector2`

Un modèle de données couplé à un type Flame, contraire à la séparation des couches de `CLAUDE.md`. Déjà identifié — voir **P-26**, hors périmètre ici.

---

## 4. Constats — famille « visuel »

### 4.1 Les cinq types partagent la même silhouette

Cercle de 70 px, fond `#1A1A2E`, bordure colorée. Toute la différenciation repose sur une icône de 35 px et sur la couleur. Conséquences : aucune lecture en vision périphérique, et un joueur daltonien perd la quasi-totalité de l'information.

### 4.2 Le nœud le plus fréquent est le moins lisible

Le combat normal est rendu en `Colors.white70` (`map_node_widget.dart:84`). C'est le type le plus nombreux de la carte — 12 à 22 nœuds — et c'est celui dont le glyphe a le plus faible contraste, sur un médaillon sombre lui-même posé sur un fond beige clair.

### 4.3 Les liaisons sont indifférenciées

Toutes les connexions sont peintes du même pointillé brun animé. Rien ne distingue le chemin réellement parcouru, les liaisons encore accessibles, et les branches définitivement abandonnées. Le joueur ne peut pas relire son propre parcours.

### 4.4 L'état « complété » sort de la direction artistique

`opacity: 0.4` plus une `Icons.check_circle` verte (`map_node_widget.dart:204-205`). C'est le seul élément de l'écran qui n'obéit à aucune charte — un vert Material sur une carte parchemin.

### 4.5 Le pion est générique

`Icons.person_pin` bleu (`player_pawn.dart:31`), alors que `hero_berserker.png`, `hero_mage.png` et `hero_paladin.png` existent déjà dans `assets/images/` et que `runState` connaît la classe jouée.

### 4.6 Le fond est identique de l'acte 1 à l'acte 12

`RadialGradient` sur trois beiges, sans texture ni grain. Aucune progression ressentie, aucune identité de lieu. Sujet voisin de **P-12 Biomes**.

### 4.7 L'espacement horizontal respire de façon irrégulière

`posX = (x + 0.5) * (1000 / rowWidth)` (`map_node_generator.dart:64`). Un étage à 2 nœuds les écarte de 500 px, un étage à 5 nœuds de 200 px — pour des nœuds de 70 px de diamètre. La carte alterne visuellement entre le vide et l'encombrement, sans que cela porte le moindre sens.

### 4.8 Il n'y a pas de zoom

`scaleEnabled: false` (`map_screen.dart:218`). Impossible d'embrasser l'acte entier pour planifier une route — ce qui est pourtant l'intérêt principal d'une carte visible dès le départ. La molette est par ailleurs détournée en défilement vertical (`map_screen.dart:202-211`).

### 4.9 La légende est statique

Dix entrées codées en dur, affichées quel que soit le contenu réel de la carte. Elle annonce l'Autel des Reliques dès l'acte 1, alors que `MapContentPlacer` ne peut le poser qu'à partir de l'acte 5 (`map_content_placer.dart:10`).

---

## 5. Constats — famille « génération »

### 5.1 Chaque acte a le même squelette

`floors = 10` et `maxWidth = 5` sont en dur, le chokepoint tombe toujours à l'étage 5, le repos toujours à l'étage 8. La difficulté des rencontres progresse, la topologie non. C'est le principal levier de variété inexploité du système.

### 5.2 Un point de la roadmap peut être rayé

`ROADMAP.md` §7 demande de « vérifier que la règle anti-répétition de nœuds fonctionne réellement, et que les quotas par acte sont respectés ». **Les deux sont couverts par des tests qui passent** (`map_generator_test.dart`, tests « anti-repetition » et « quotas are balanced and respected across many runs »). Le point est déjà traité.

---

## 6. Pistes retenues par l'échange

### 6.1 Socle : `assets/data/map_nodes.json`

Le projet est intégralement data-driven — cartes, ennemis, héros, reliques, compétences, événements. Les types de nœuds sont la **seule** exception : un `enum` Dart doublé de visuels codés en dur dans les widgets.

La piste retenue est d'aligner les nœuds sur le reste du jeu, avec une portée **présentation + réglages** : par entrée, le sprite, l'icône de repli, la couleur, la forme, les libellés et descriptions bilingues, **et** le poids de tirage, les quotas et les règles de placement.

Contrainte assumée : l'`enum MapNodeType` reste. Il pilote le routage vers les écrans (`map_screen.dart:391`) et le comportement en combat (`encounter_system`, `reward_controller`). Le JSON décrit ce qu'un type **est et fait**, pas son existence — même logique que `RelicTrigger`.

Indexation par **variante visuelle** et non par valeur d'enum : le type `boss` porte trois sous-variantes distinctes (`cards`, `doubleXp`, `improvedRelic`), chacune avec son icône, sa couleur et son libellé. Les indexer séparément est ce qui supprime la dernière poche de duplication.

Modèle `MapNodeData` aligné sur `RelicData` (`nameFr` / `nameEn`, `getName(locale)`, `fromJson` avec repli), ajouté au `GameDataRegistry`.

**Aucun rééquilibrage dans la même passe.** Les poids et quotas transcrits en JSON reproduisent exactement les valeurs actuelles. C'est ce qui permet aux 11 tests de génération de garder leurs assertions inchangées et de servir de filet. Retoucher l'équilibrage devient ensuite trivial — c'est précisément le bénéfice acheté.

### 6.2 Encodage du visuel : sprite avec repli sur icône

Champ `sprite` (chemin, nullable) et champ `icon` (clé texte résolue par une `const Map<String, IconData>` en Dart).

Justification technique : Flutter élague la police d'icônes Material au build. Un `IconData(codePoint)` construit dynamiquement depuis du JSON produit des carrés vides en release, sauf à compiler avec `--no-tree-shake-icons`. Une table `const` de références `Icons.*` échappe à ce piège.

Bénéfice : tant que `sprite` vaut `null`, le rendu reste identique à l'actuel. Le jour où une illustration est déposée dans `assets/images/`, renseigner le champ suffit — `pubspec.yaml` déclare déjà le dossier entier, aucune configuration à toucher.

### 6.3 Traitement retenu du nœud : cartouche gravé

Comparaison de quatre traitements sur le fond parchemin réel du jeu. Retenu : **forme par type + encre sombre sur médaillon clair + double anneau**.

- **Forme par type** — cercle pour le combat, hexagone pour l'élite, carré arrondi pour la boutique, losange pour le repos, écu pour le boss. La silhouette devient le canal principal, la couleur une confirmation. Règle du même coup la lisibilité périphérique et le cas daltonien.
- **Encre sur parchemin** — médaillon clair (`#FAF0DC`), glyphe et bordure sombres. Corrige le contraste du nœud combat et raccorde les nœuds au parti pris parchemin, au lieu de flotter dessus comme des corps étrangers sombres.
- **Taille hiérarchique** — élite et boss plus grands que les nœuds ordinaires, pour que l'enjeu se lise avant l'icône.

**Aucun de ces trois éléments ne demande d'asset graphique.** Formes en `ClipPath` ou `CustomPainter`, couleurs en données. Les sprites, lorsqu'ils existeront, viendront se loger **au centre du médaillon** : ils remplacent le glyphe, pas le cadre. Cadre et sprite sont donc deux chantiers indépendants et séquentiables.

### 6.4 Trois régimes de liaison

Encre pleine pour le chemin parcouru, pointillé vif pour l'accessible, tracé fantôme pour l'abandonné.

**Aucun nouvel état n'est nécessaire** : tout se dérive de `isCompleted` et `currentNodeId`. Une liaison est parcourue si ses deux extrémités sont complétées, accessible si elle part du nœud courant, abandonnée si son étage est derrière le joueur sans avoir été empruntée. Le painter reçoit une catégorie par segment — et comme le constat 3.4 impose de toute façon de précalculer les segments, les deux corrections tiennent dans la même passe.

### 6.5 Pion et sceau

Pion porteur du **portrait de la classe jouée** — les trois PNG existent, `runState` connaît la classe, c'est un `Image.asset` conditionnel. Sceau de cire à la place de la coche verte Material sur les nœuds complétés.

### 6.6 Fond : texture procédurale, sans illustration

Grain de parchemin, taches d'encre et bords brunis générés par `CustomPainter`. Zéro asset, cohérent avec le rendu intégralement procédural du projet. La variation par acte passe par la **teinte** plutôt que par le dessin.

Ce choix laisse **P-12 Biomes** intact et indépendant : les 15 illustrations pourront s'ajouter par-dessus cette texture plus tard, ou la remplacer, sans que le présent chantier en dépende.

---

## 7. Ce que ce document ne couvre pas

- **P-12 Biomes** — traité comme chantier distinct, voir 6.6.
- **P-31 Nœuds Trésor et Mystère** — deviennent des entrées JSON une fois le socle en place, mais restent une décision de game design à part.
- **P-26** — découplage de `MapNode` d'avec `Vector2`.
- **Variété topologique par acte** (constat 5.1) — la plus grosse piste de game design du document, volontairement laissée ouverte : elle demande un vrai travail d'équilibrage, pas une décision de rendu.
- **Écrans Boutique et Repos en overlay** plutôt qu'en `Navigator.push`, piste de l'analyse archivée de mai 2026 jamais tranchée.

---

## 8. Effort & risque

| Bloc | Effort estimé | Risque |
|:---|:---:|:---|
| Socle `map_nodes.json` + `MapNodeData` + registre d'icônes | 1 à 1,5 j | Faible — 11 tests existants en filet, rendu inchangé par construction |
| Suppression des 4 duplications + conformité l10n | 0,5 j | Faible — mécanique, mais touche le tutoriel |
| Cartouche gravé (formes, contraste, hiérarchie de taille) | 1 à 1,5 j | Moyen — c'est du rendu neuf, à valider en playtest |
| Trois régimes de liaison + précalcul des segments | 0,5 j | Faible — gain de perf au passage |
| Pion héros + sceau de cire | 0,25 j | Nul |
| Texture de fond procédurale | 0,5 à 1 j | Moyen — un `CustomPainter` de texture peut coûter cher s'il est mal mis en cache |

**Le socle (blocs 1 et 2) a une propriété rare : il ne change strictement rien à l'écran.** Toute différence visuelle constatée après ces deux blocs est une régression, ce qui les rend faciles à valider.

Rappel de cadrage : la roadmap place **l'audio** comme le plus gros gain de game feel par heure investie, très loin devant tout le reste. Ce chantier-ci n'est pas l'urgence du projet. Son intérêt propre est son effet de levier — il débloque simultanément P-31, une part de P-12, et la mise en conformité de localisation.

---

## 9. Points ouverts

- **Faut-il activer le zoom** (`scaleEnabled`) en même temps que le reste ? Techniquement trivial, mais interagit avec le détournement actuel de la molette et avec le recentrage automatique de caméra.
- **Régulariser l'espacement horizontal** (constat 4.7) touche `MapNodeGenerator`, donc la génération — que le présent chantier s'était donné pour règle de ne pas modifier. À isoler.
- **Quel style d'illustration** pour les futurs sprites de nœuds ? Les 8 PNG existants sont des portraits d'ennemis et de héros ; un sceau gravé monochrome ne suivrait pas la même logique qu'une vignette peinte.
- **Faut-il supprimer `bossEnemyId` ou le câbler ?** Le supprimer respecte la règle « pas de code mort » ; le câbler ouvre les boss nommés par acte.

---

## 10. Ce que ce chantier rend possible

- **P-31** (Trésor, Mystère) passe d'un chantier à quatre fichiers à une entrée JSON.
- **P-12** peut se poser par-dessus la texture procédurale sans refonte.
- Le **rééquilibrage de la carte** (poids, quotas, densité d'élites) devient une édition de données, testable sans recompilation.
- La **variété topologique par acte** (5.1) devient abordable, le catalogue étant déjà le bon endroit où accrocher des surcharges par acte.
- La **conformité de localisation** du projet est rétablie sur son dernier îlot non conforme connu.
