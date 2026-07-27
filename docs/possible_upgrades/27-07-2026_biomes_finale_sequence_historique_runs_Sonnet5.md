# Biomes, Finale de Séquence & Historique des Runs — Hero's Draft

**Date** : 27/07/2026
**Contexte** : Brainstorm parti d'une question de variété de contenu par Acte (biomes) qui a débouché sur une inspiration *Risk of Rain 2* pour une première condition de victoire du jeu, elle-même amenant un besoin d'historique de runs.
**Statut** : Brainstorm — conception fonctionnelle validée par échange, aucune stat/asset chiffré, **rien encore implémenté**.
**Portée** : Trois sous-systèmes distincts mais liés. Chacun est écrit pour pouvoir être détaché plus tard en spec + plan d'implémentation indépendant.

---

## 0. Vue d'ensemble et relations entre les 3 systèmes

```
[Biomes]  ── donne son identité visuelle/mécanique à chaque Acte
   │
   ▼
[Séquence de 5 Actes en boucle] ── la position 5 de chaque boucle est un point de bascule
   │
   ▼
[Finale de Séquence] (optionnelle, inspirée RoR2) ── offre une sortie de run propre (Victoire)
   │
   ▼
[Historique des Runs] ── archive le résultat (Victoire ou Défaite) de toute run terminée
```

Les Biomes sont indépendants des deux autres systèmes (pure variété de contenu). La Finale de Séquence dépend du concept de "séquence en boucle de 5" introduit par les Biomes. L'Historique des Runs dépend de la Finale (il lui faut un état de Victoire à enregistrer, en plus de la Défaite déjà existante).

---

## 1. Système de Biomes

### 1.1. Vue d'ensemble
Granularité **par Acte** : toute la carte générée d'un Acte partage un biome. Rôle mécanique (filtre le pool d'ennemis disponibles) **et** visuel réel (asset image dédié, pas un simple accent de couleur). Séquence en boucle de 5 positions ; à chaque position, un biome est tiré au hasard parmi 3 variantes candidates.

### 1.2. Roster proposé (5 séquences × 3 variantes)

| Séquence (Actes) | Biomes candidats |
|:---|:---|
| **1** (Actes 1, 6, 11, 16...) | Forêt Verdoyante · Prairie Paisible · Village Abandonné |
| **2** (Actes 2, 7, 12...) | Marais Brumeux · Crypte Ancienne · Forêt Pétrifiée |
| **3** (Actes 3, 8, 13...) | Cavernes Souterraines · Ruines Englouties · Camp de Bandits |
| **4** (Actes 4, 9, 14...) | Pics Enneigés · Terres Désolées de Cendres · Sanctuaire Corrompu |
| **5** (Actes 5, 10, 15...) | Volcan en Éruption · Antre du Dragon · Abîme Maudit |

> [!NOTE]
> La position 5 coïncide avec les paliers déjà existants tous les 5 actes (déblocage de tier ADR-072, Autel d'Échange garanti). La carte "monte en danger visuel" au même rythme que le danger mécanique — cohérence narrative gratuite. C'est aussi la position choisie pour accrocher la Finale de Séquence (§2).

### 1.3. Modèle de données
- **`assets/data/biomes.json`** (nouveau) : `id`, `name_fr`/`name_en`, `sequencePosition` (1-5), `backgroundAsset` (chemin image).
- **Nouveau dossier `assets/images/biomes/`** (15 fichiers attendus) + déclaration dans `pubspec.yaml`.
- **`EnemyData`** (`lib/models/data/enemy_data.dart`) : nouveau champ optionnel `biomes: List<String>` (tag). Absent ou vide = disponible dans tous les biomes — **rétrocompatible à 100%** avec les 4 ennemis actuels et les 25 candidats de `27-07-2026_nouveaux_ennemis_par_tier_Sonnet5.md`, aucune régression.

### 1.4. Algorithme Acte → Biome
Fonction déterministe (ex. `EncounterSystem.getBiomeForAct(act)`) :
1. `position = ((act - 1) % 5) + 1`
2. Filtre les biomes dont `sequencePosition == position`
3. Tire un biome au hasard dans ce sous-groupe via un **random seedé par l'Acte** (`Random(act)`), même précédent que l'Autel d'Échange de Reliques (`Random((node.id.hashCode ^ act).abs())`). Résultat stable et recalculable à la demande — **aucun champ à ajouter à `RunState`/au schéma de sauvegarde**.

### 1.5. Intégration dans la génération d'ennemis
`generateEnemiesForLevel` filtre `availableEnemies` par tag biome, **exactement comme le filtre de tier existant** (`enemy.tier <= unlockedTier`, `encounter_system.dart:260-264`), avec le même repli sur le pool complet si le filtre viderait la sélection. Filtre parallèle au tier, zéro risque de casser le scaling ADR-070/071/072.

### 1.6. Affichage visuel
- Asset image réel par biome (rupture assumée avec la philosophie 100% procédurale actuelle de `ScreenScaffold`, qui ne fait aujourd'hui que des dégradés — zéro image de fond dans tout le projet à ce jour).
- **Scope proposé pour une première itération : `MapScreen` uniquement.** Le fond de combat (`GameScreen`) resterait en scope 2 pour ne pas doubler le besoin en illustrations (15 → 30) dès le départ.
- **Repli obligatoire** si l'image d'un biome n'existe pas encore (le code peut précéder l'art) : retombe sur le dégradé `ScreenScaffold` actuel plutôt que de crasher — même logique de dégradation gracieuse que `MissingSaveItem` pour le contenu de sauvegarde manquant.

### 1.7. Effort & risque
- **Code : petit-moyen** — nouveau modèle `BiomeData`, chargement via `GameDataService`/`GameDataRegistry` (pattern `FutureProvider` existant), un champ sur `EnemyData`, un filtre de plus dans `generateEnemiesForLevel`, un fallback visuel sur `MapScreen`.
- **Art : le vrai goulot d'étranglement** — 15 illustrations à produire/sourcer, entièrement hors de ce qui peut être généré en code.

---

## 2. Finale de Séquence *(inspirée Risk of Rain 2)*

### 2.1. Vue d'ensemble
À la résolution du floor Boss de **chaque Acte en position 5 de la séquence** (Acte 5, 10, 15, 20...), un **4ème choix optionnel** s'ajoute aux 3 nœuds de boss existants (x=0 clonage de cartes, x=1 triple XP/or, x=2 relique premium) : le **Portail Final**. Directement inspiré du téléporteur de Risk of Rain 2, qui offre à chaque étape le choix entre continuer la boucle ou accéder à une sortie de fin de run.

### 2.2. Règles de disponibilité et de choix
- **Optionnel, dès l'Acte 5** (première séquence déjà éligible — pas de gate derrière plusieurs boucles).
- Le joueur choisit librement entre un des 3 boss classiques (la run continue normalement, boucle vers l'acte suivant, endless inchangé) et le Portail Final.
- Rien ne force la clôture : un joueur qui veut continuer en endless indéfiniment peut toujours ignorer le Portail à chaque occurrence.

### 2.3. Boss de Cycle
Plutôt que de concevoir un boss de Finale différent par séquence dès la V1 (pas réaliste vu le bestiaire actuel de 4 ennemis), le Portail Final mène à un **unique "Boss de Cycle"**, scalé par le nombre de boucles de 5 actes déjà complétées — même principe que Mithrix dans Risk of Rain 2, qui reste le même boss indépendamment du nombre de boucles effectuées avant de l'affronter.

### 2.4. Résolution
- Vaincre le Boss de Cycle déclenche un nouvel **écran de Victoire** (`VictoryScreen`), distinct de `GameOverScreen` — **première condition de victoire du jeu à ce jour** (actuellement les actes continuent indéfiniment, seule la mort termine une run).
- Comme une mort, la victoire **efface la sauvegarde active** (`SaveService.clear()`) : la run est définitivement terminée, retour à `HomeScreen`.
- Juste avant l'effacement, la run est enregistrée dans l'Historique des Runs (§3) avec le résultat "Victoire".

### 2.5. Points d'implémentation identifiés
- Extension conditionnelle de la génération de l'étage Boss (`MapGeneratorService`/`MapNodeGenerator`, étage `floors-1`) : un 4ème nœud n'apparaît que lorsque l'Acte en cours est en position 5 de la séquence.
- Nouveau `MapNodeType` (ex. `finale`) ou variante de `BossRewardType`.
- Nouveau `VictoryScreen` (miroir structurel de `GameOverScreen`).
- Conception des stats/pattern du Boss de Cycle et de sa formule de scaling par nombre de boucles — non détaillée ici, à faire dans une spec dédiée.

### 2.6. Effort & risque
**Moyen** — touche la génération de carte (cas conditionnel supplémentaire sur l'étage final), demande un nouveau boss dédié avec sa propre formule de scaling, et un nouvel écran. Contenu isolé (n'affecte pas le scaling des combats normaux/élites/boss existants).

---

## 3. Historique des Runs

### 3.1. Vue d'ensemble
Archive persistante de **toutes** les runs terminées (Victoire via la Finale, ou Défaite via la mort), consultable depuis l'écran d'accueil. Séparée du `SaveService` existant, qui ne gère que la run *active* et est effacé à chaque fin de run.

### 3.2. Modèle de données proposé (`RunSummary`)

| Champ | Détail |
|:---|:---|
| `date` | Horodatage de fin de run |
| `outcome` | `victory` / `defeat` |
| `heroClass` | Héros joué (Paladin/Berserker/Mage) |
| `actReached`, `floorReached` | Progression atteinte |
| `totalDamageDealt` | Dégâts totaux infligés sur la run |
| `enemiesKilled` | Nombre d'ennemis vaincus |
| `goldEarned` | Or total récolté |
| `relicsObtained` | Liste de reliques (snapshot bilingue nom, même logique que `MissingSaveItem` pour survivre à un retrait de contenu ultérieur) |
| `finalDeck` | Snapshot du deck au moment de la fin de run |
| `durationSeconds` (ou nombre de tours) | Durée de la run |

### 3.3. Stockage
- Nouveau **`RunHistoryService`**, clé `shared_preferences` dédiée, séparée de celle de `SaveService`.
- **Liste complète et illimitée** (décision validée) — pas de plafond ni de purge automatique des entrées les plus anciennes.

> [!NOTE]
> `shared_preferences` n'est pas conçu pour des listes volumineuses (tout est chargé/désérialisé en un bloc JSON). Décision assumée : si la taille de la liste devient un problème de performance en usage réel prolongé, la migration vers un stockage local structuré (ex. `sqlite`/`drift`/`hive`) sera l'échappatoire naturelle — non nécessaire pour une première version.

### 3.4. Interface
- Nouvel écran **`RunHistoryScreen`**, accessible depuis `HomeScreen`.
- Liste des runs, les plus récentes en premier, chaque entrée sélectionnable pour afficher le détail complet (`RunSummary`).

### 3.5. Écriture
- Appelée systématiquement à la toute fin de n'importe quelle run — aussi bien dans `GameOverScreen` (Défaite) que dans le nouveau `VictoryScreen` (Victoire) — **juste avant** l'appel à `SaveService.clear()`.

### 3.6. Effort & risque
**Petit-moyen** — nouveau service de persistance (mirroring du pattern déjà établi par `SaveService`), un nouveau modèle sérialisable, un nouvel écran de listing + détail. Aucun impact sur les systèmes existants au-delà des deux points d'écriture (mort, victoire).

---

## 4. Prérequis mécaniques globaux (récapitulatif)

- **Biomes** : nouveau fichier `biomes.json` + dossier d'assets + champ `biomes` sur `EnemyData` + filtre dans `generateEnemiesForLevel` + fallback visuel `MapScreen`.
- **Finale de Séquence** : génération conditionnelle d'un 4ème nœud à l'étage Boss (position de séquence 5 uniquement), nouveau Boss de Cycle avec sa propre formule de scaling par boucle, nouveau `VictoryScreen`.
- **Historique des Runs** : nouveau `RunHistoryService` + `RunSummary` + `RunHistoryScreen`, deux points d'écriture (mort, victoire).
- Aucun de ces trois chantiers ne touche aux formules de combat existantes (ADR-070/071/072) ni au schéma de `RunState`/`SaveService` pour la run active.

## 5. Prochaines étapes possibles

1. Prioriser lequel des trois sous-systèmes attaquer en premier — ils sont largement indépendants, mais la Finale de Séquence dépend conceptuellement du découpage en séquences de 5 actes introduit par les Biomes (même si elle peut être codée sans attendre les assets visuels des biomes).
2. Passer le sous-système retenu par un brainstorm dédié (spec dans `docs/superpowers/specs/`) pour chiffrer les détails encore ouverts (stats/pattern du Boss de Cycle, liste exacte des champs de `RunSummary`, formule de scaling par boucle).
3. Pour les Biomes spécifiquement : lancer la production des 15 illustrations en parallèle du code, puisque c'est le facteur limitant réel de ce chantier.
