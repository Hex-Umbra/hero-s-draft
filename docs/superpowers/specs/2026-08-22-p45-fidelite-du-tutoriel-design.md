# P-45 — Fidélité du tutoriel — Conception

Date : 2026-08-22
Statut : **Design validé, non implémenté**
Chantier ROADMAP : **P-45** (à créer) — Tier A proposé
Sources amont :
- Audit de conformité du 2026-08-22, « Écarts du Tutoriel » — 50 écarts relevés sur les 13 étapes,
  8 systèmes jamais abordés, 5 incohérences trouvées côté jeu

> **Ce document ne corrige pas 50 bugs, il installe une règle.** L'audit amont a produit une liste
> de 50 écarts entre `lib/tutorial/` et le jeu. Les traiter un par un rendrait le tutoriel exact le
> jour de la livraison et faux six semaines plus tard — c'est exactement l'histoire des 50 écarts
> actuels, tous nés d'une recopie manuelle correcte à l'origine.
>
> La décision structurante de cette spec tient en une phrase : **le tutoriel n'invente jamais une
> donnée ni un visuel que le jeu sait déjà produire.** Elle élimine 13 écarts à la racine et les
> rend structurellement impossibles à réintroduire. Les 37 restants sont du texte pédagogique et de
> l'interaction — qu'aucun mécanisme ne peut dériver, et qui se corrigent donc à la main, une fois.

---

## 1. Vérification préalable

Tous les constats ci-dessous ont été vérifiés contre le code le 2026-08-22, ligne par ligne.
Deux d'entre eux **corrigent l'audit amont** et sont marqués ⚠️.

| Constat | Vérification |
|:---|:---|
| Le tutoriel compte 18 fichiers et 5 150 lignes | `lib/tutorial/` |
| Aucun fichier de `lib/tutorial/` n'importe `flutter_riverpod` | `grep -r flutter_riverpod lib/tutorial/` → 0 |
| `TutorialCard` et `TutorialEnemy` sont des POJOs locaux | `tutorial_engine.dart:4` et `:26` |
| Le héros du mock est figé à 80 PV / 3 mana | `tutorial_engine.dart:49` |
| Le palier d'XP du mock est figé à 100 | `tutorial_engine.dart:58` |
| `resetMockState()` réinitialise tout à chaque changement d'étape | `tutorial_engine.dart:102` |
| Dans `playCard`, le gain d'armure est imbriqué dans `if (enemy != null)` | `tutorial_engine.dart:227` englobe `:237` |
| `ProviderScope` enveloppe toute l'application | `main.dart:13` |
| `gameDataLoaderProvider` est un `FutureProvider` de lecture sur `rootBundle`, sans état de jeu | `game_data_service.dart:50-89` |
| `UiCard.fromData(card: CardData, …)` existe et n'a aucune dépendance Riverpod | `ui_card.dart:80` |
| `UiCard.fromInstance(card: CardInstance, …)` existe également | `ui_card.dart:50` |
| `EnemyIntentsPanel` consomme une `List<EnemyInstance>` et rien d'autre | `enemy_intents_panel.dart:7` |
| `DraftChoiceCard` est **déjà** réutilisé par le tutoriel | `tutorial_draft_widget.dart:3` |
| `EntityStats.takeDamage()` porte la formule d'absorption réelle | `entity_stats.dart:187-206` |
| `DamagePipeline.calculate()` est déterministe à `critChance: 0` | `damage_pipeline.dart:22-28` |
| L'armure du joueur est remise à `0` au début de chaque tour, avant tout le reste | `run_controller.dart:408-414` |
| Le système de compétences héroïques n'a aucun appelant | `skill_controller.dart:23,33` · `heros_draft_game.dart:315` |
| La légende annonce « Boss (XP & Or x2) », le code applique `*= 3` | `map_legend.dart:130` vs `reward_controller.dart:89-101` |
| `test/tutorial/` contient déjà 2 fichiers, 107 lignes | `tutorial_engine_test.dart`, `tutorial_progress_service_test.dart` |

### ⚠️ 1.1. Le champ `skills` de `heroes.json` porte des ids de **cartes**, pas de compétences

L'audit amont conclut que les six ids de `heroes.json` (`holy_shield`, `smite`, `reckless_strike`,
`rage_form`, `magic_missile`, `mana_surge`) sont des références cassées vers `skills.json`. **C'est
faux.**

Ce sont les six **cartes de classe** de `hero_cards.json`, résolues contre `registry.cards` par
`HeroSkillsLink.getHeroCards()` (`hero_skills_link.dart:6`) et ajoutées d'office au deck de départ
(`starter_deck_draft_screen.dart:85`). Elles existent toutes, la résolution fonctionne.

Le vrai défaut est une **homonymie** : le champ s'appelle `skills` alors qu'il porte des cartes,
pendant qu'un `skills.json` bien réel et totalement mort coexiste sous le même nom. Le renommage
est hors périmètre (§11), mais l'étape 03 doit être écrite en connaissance de cause.

### ⚠️ 1.2. Le catalogue compte 23 cartes, pas 17

`registry.cards` fusionne `cards.json` (17) et `hero_cards.json` (6) — `game_data_service.dart:74-77`.
Le catalogue réel est donc de **23 cartes : 12 Attaques, 9 Compétences, 2 Pouvoirs**, dont **17
communes et 6 uniques**, et **5 marquées `isExhaust`**.

Conséquence directe pour l'étape 12 (Fusion) : les six cartes de classe sont de rareté `unique` et
`DeckNotifier.mergeCards()` les refuse explicitement (`deck_controller.dart:279-281`). « Les cartes
de votre classe ne fusionnent jamais » est une règle enseignable, pas une note de bas de page.

---

## 2. Le problème

Le tutoriel est autonome par conception : `ChangeNotifier` local, `TutorialMockState`, zéro
Riverpod. La décision est bonne — elle protège la run de production de tout effet de bord — et elle
est documentée dans `_rules/08-00-systeme-de-tutoriel-autonome.md`.

Mais elle a été appliquée trop largement. En interdisant *tout* Riverpod, elle a interdit du même
geste l'accès aux **données**, qui ne portent aucun état. Chaque valeur du tutoriel a donc été
recopiée à la main une fois, puis le jeu a bougé.

Le résultat est mesurable : la Défense donne 4 armure au lieu de 5, la Boule de Feu 10 dégâts au
lieu de 6, le Slime a 20 PV au lieu de 18, le Talisman de Fer donne 4 armure en début de combat au
lieu de 2 par tour. Aucune de ces valeurs n'était fausse le jour où elle a été écrite.

La dérive factuelle est plus grave que la dérive numérique. Huit règles sont enseignées à l'envers,
et trois mécaniques annoncées n'existent tout simplement pas : la fusion automatique, les reliques
en boutique, l'intention ennemie « Affaiblissement ». Un joueur qui les croit attend un système
absent.

---

## 3. Décisions retenues

| # | Décision | Rationale |
|:--:|:---|:---|
| D1 | **Le tutoriel lit `gameDataLoaderProvider` en lecture seule** | Élimine 13 écarts à la racine et les rend impossibles à réintroduire |
| D2 | **Réutiliser les vrais widgets là où le widget *est* la leçon** | La fidélité visuelle devient gratuite ; le précédent existe (`DraftChoiceCard`) |
| D3 | **Conserver des maquettes maison là où le tutoriel doit annoter ou simplifier** | Réutiliser `HerosDraftGame` pour la vue d'ensemble coûterait plus que la fidélité gagnée |
| D4 | **Le parcours passe à 15 étapes**, choix de classe et draft de départ en 02 et 03 | Ce sont les deux seuls écrans qu'un joueur voit avant le premier combat |
| D5 | **Le parcours devient à état** : classe et deck persistent en aval | Rend concrètes les étapes Armure, Jouer, Fusion, aujourd'hui vagues |
| D6 | **Les étapes 02 et 03 sont verrouillées une fois franchies** | Revenir invaliderait l'aval ; c'est aussi le comportement du vrai jeu |
| D7 | **Côté jeu, seule la légende `x2` → `x3` est corrigée** | Il faut trancher pour savoir quoi écrire ; le reste est un chantier gameplay |
| D8 | **`x3` fait foi** — le code ne change pas, l'affichage s'aligne | Correctif d'affichage, aucun rééquilibrage |

### 3.1. La règle

> **Le tutoriel n'invente jamais une donnée ni un visuel que le jeu sait déjà produire.**
> Il n'écrit en dur que ce qui n'existe nulle part ailleurs : ses textes pédagogiques et ses
> annotations.

### 3.2. L'amendement de la règle d'autonomie

`_rules/08-00` dit aujourd'hui « **Zéro dépendance Riverpod** ». Elle devient :

> **Zéro provider d'*état*.** `runProvider`, `deckProvider`, `combatProvider`, `inventoryProvider`,
> `skillProvider`, `rewardProvider`, `shopProvider`, `eventProvider` et `checkpointProvider` restent
> interdits dans `lib/tutorial/` — c'est eux qui portaient le risque d'effet de bord sur la run.
> `gameDataLoaderProvider`, qui ne porte que de la donnée immuable chargée depuis `rootBundle`, est
> autorisé **en un seul point** : `lib/tutorial/tutorial_loader.dart`.

Le critère est vérifiable d'un `grep` : un seul fichier de `lib/tutorial/` importe
`flutter_riverpod`. Un test le vérifie (§9).

---

## 4. Architecture cible

### 4.1. `tutorial_loader.dart` — la frontière unique

```
HomeScreen
   └── TutorialLoader              (ConsumerWidget — SEUL point Riverpod)
          watch(gameDataLoaderProvider)
             ├── loading → indicateur
             ├── error   → message + retour
             └── data    → TutorialScreen(data: registry)
                              └── TutorialEngine(data: registry)
                                     └── 15 widgets d'étape   (aucun Riverpod)
```

`TutorialScreen` reste un `StatefulWidget` et reçoit le registre par constructeur. `HomeScreen`
pousse `TutorialLoader` au lieu de `TutorialScreen` (`home_screen.dart:188`).

Le registre est déjà en cache au moment où le joueur atteint le tutoriel — `gameDataLoaderProvider`
est un `FutureProvider`, résolu au premier accès. L'état `loading` sera donc rarement visible, mais
il doit exister.

### 4.2. Les POJOs cèdent la place aux modèles réels

| Aujourd'hui | Devient | Ce que ça débloque |
|:---|:---|:---|
| `TutorialCard` (`tutorial_engine.dart:4`) | `CardInstance` | `UiCard.fromInstance` : médaillon de mana réel, badges d'effets réels, bordure de rareté réelle |
| `TutorialEnemy` (`tutorial_engine.dart:26`) | `EnemyInstance` | `EnemyIntentsPanel` réel : les 4 paliers d'attaque, le recalcul par le niveau et le Gel |
| `heroHp` / `heroArmor` / `heroMana` en `int` nus | `EntityStats` | `takeDamage()` réel : l'étape Armure démontre la vraie absorption au lieu de la simuler |
| Calcul de dégâts maison (`tutorial_engine.dart:227-245`) | `DamagePipeline.calculate()` | Déterministe à `critChance: 0`, donc utilisable tel quel |

Les deux classes POJO sont **supprimées**. `TutorialMockState` conserve son rôle mais ne porte plus
que des modèles du jeu.

Le moteur reste un `ChangeNotifier` local : il ne gagne aucun provider, il manipule des instances
qu'il possède et qu'il est seul à muter.

### 4.3. `prepareStep()` et la tranche persistante

`resetMockState()` (`tutorial_engine.dart:102`) est remplacé par `prepareStep(int index)`.

`TutorialMockState` se scinde en deux tranches :

- **Persistante** — survit aux changements d'étape : `chosenHero` (`HeroData`), `activePassive`
  (`PassiveData`), `masterDeck` (`List<CardInstance>`), `heroStats` de base dérivées de la classe.
  Écrite uniquement par les étapes 02 et 03.
- **Scratch** — réinitialisée à chaque `prepareStep` : main courante, ennemi, armure du tour,
  mana du tour, XP de démonstration, drapeaux d'interaction.

### 4.4. Politique d'échec : fail fast

Les ids de démonstration sont dans nos propres assets. S'ils manquent, le build est cassé, pas le
tutoriel.

| Rôle | Id | Source |
|:---|:---|:---|
| Attaque de base | `strike_basic` | `cards.json` |
| Compétence d'armure | `defend_basic` | `cards.json` |
| Attaque élémentaire | `fireball` | `cards.json` |
| Ennemi d'entraînement | `slime` | `enemies.json` |
| Relique d'exemple | `iron_talisman` | `relics.json` |
| Classes | `paladin`, `berserker`, `mage` | `heroes.json` |

La résolution se fait par `firstWhere` **sans `orElse`** : elle lève si l'id manque. Le garde-fou
est le test de fidélité (§9), qui échoue en CI avant que le cas ne se produise à l'exécution.
C'est un choix délibéré : un `orElse` réintroduirait précisément les valeurs en dur que cette spec
supprime.

### 4.5. Widgets réutilisés, maquettes conservées

**Réutilisés** — le widget *est* la leçon :

| Widget du jeu | Étape | Écarts éliminés |
|:---|:---|:---|
| `UiCard.fromInstance` | 07, 08, 12 | 05·1, 05·3, 05·5, 10·3 |
| `EnemyIntentsPanel` | 11 | 09·4 |
| `StatusEffectsPanel` | 10 | — (cohérence visuelle) |
| `DraftChoiceCard` + `LevelUpRewardService` | 14 | 12·1, 12·2, 12·3, 12·4 |

**Conservées** — le tutoriel doit annoter, isoler ou ralentir :

| Maquette | Étape | Pourquoi |
|:---|:---|:---|
| Vue d'ensemble annotée | 06 | Les bulles numérotées sont la leçon ; le vrai combat ne peut pas les porter |
| Mini-carte | 04 | Une carte de 10 planchers est illisible dans une vignette |
| Galerie d'éléments animée | 10 | Elle simule le temps ; aucun écran du jeu ne fait ça |
| Démo comparative d'armure | 09 | Le côte-à-côte avec/sans n'existe pas en jeu |

---

## 5. Les deux nouvelles étapes

### 5.1. Étape 02 — Choix de classe

**Source** : `registry.heroes` (3 entrées) et `registry.passives` (3 entrées).

Affiche les trois héros avec leurs vraies valeurs — Paladin 100 PV, Berserker 80, Mage 60, tous à
3 mana — et le nom et la description bilingues de leur passif, lus depuis `passives.json`.

**Interaction** : choisir une classe. L'étape n'est franchissable qu'après le choix.

**Effet en aval** : `chosenHero`, `activePassive` et les `heroStats` initiales sont écrits dans la
tranche persistante. L'étape 09 (Armure) démontrera *ce* passif, avec sa vraie valeur.

**Ce qu'elle n'est pas** : une copie de `ClassSelectionScreen`. Elle en emprunte les données, pas la
mise en page — trois cartes simples suffisent, sans le carrousel ni l'accès au dictionnaire.

### 5.2. Étape 03 — Draft du deck de départ

**Source** : `registry.cards` filtré sur `category == global && type != status` — la même
expression que `starter_deck_draft_screen.dart:51-55`, soit les 17 cartes globales.

Le joueur choisit **5 cartes**. Les cartes de classe (`chosenHero.getHeroCards(registry)`) sont
ajoutées automatiquement et affichées comme telles, pour que la règle soit visible.

**Interaction** : sélection de 5 cartes exactement, comme le vrai écran.

**Effet en aval** : `masterDeck` est écrit dans la tranche persistante. L'étape 08 (Jouer) pioche
dedans ; l'étape 12 (Fusion) y prend trois exemplaires d'une carte réellement draftée.

**Simplification assumée** : le pool réel n'est pas mélangé ni tronqué — les 17 cartes sont
présentées. Le tutoriel enseigne la règle de composition, pas la tension du choix.

### 5.3. Le verrou

Une fois l'étape 03 franchie, `prevStep()` ne redescend plus en deçà de l'étape 04. Revenir sur le
choix de classe invaliderait le deck drafté et les statistiques du héros.

Le bouton « Précédent » est masqué sur 04, comme il l'est déjà sur 01
(`tutorial_screen.dart:322-335`).

---

## 6. Traitement des 50 écarts

Quatre classes de traitement. Les identifiants renvoient à l'audit amont ; la numérotation d'étape
y suit l'ancien parcours à 13 étapes, la colonne « Étape » donne la nouvelle position.

### 6.1. Éliminés par le mécanisme — 13

Aucun texte à écrire : ils disparaissent parce que la donnée et le widget viennent du jeu.

| Id | Étape | Éliminé par |
|:---|:---:|:---|
| 04·4 — 80/80 PV orphelins | 06 | `chosenHero` de l'étape 02 |
| 05·1 — coût en diamants au lieu du médaillon | 07 | `UiCard.fromInstance` |
| 05·3 — valeurs des 3 cartes de démo | 07 | `registry.cards` |
| 05·5 — types de cartes codés en dur | 07 | `CardData.type` |
| 06·3 — Slime 20 PV / 5 dégâts | 08 | `registry.enemies` |
| 09·4 — paliers d'attaque absents | 11 | `EnemyIntentsPanel` |
| 10·3 — « niveaux » de carte au lieu de raretés | 12 | `CardInstance.rarity` + `rarityMultiplier` |
| 12·1 — 3 choix figés | 14 | `LevelUpRewardService.generateChoices()` |
| 12·2 — « Forge d'Acier +4 Armure » | 14 | `draftChoiceSteelForgeDesc` |
| 12·3 — Vitalité rare, rareté du Miroir | 14 | idem |
| 12·4 — rareté Mythique et Chance absentes | 14 | idem |
| 13·3 — Talisman de Fer inexact | 15 | `registry.relics` |
| 13·4 — rareté « Peu commun » absente | 15 | `RelicRarity` |

### 6.2. Correction de texte — 16

Chaînes de `tutorial_data.dart` et libellés de widgets.

| Id | Étape | Correction |
|:---|:---:|:---|
| 02·1 | 04 | Le choix d'un nœud est **définitif** ; lire la légende avant de toucher |
| 03·2 | 05 | Retirer « procurez-vous des reliques » de la vignette Boutique |
| 03·4 | 05 | Boss « XP & Or » : **×3**, XP *et* or |
| 03·5 | 05 | Aligner le corps de l'étape sur les 8 vignettes du widget |
| 07·1 | 09 | L'armure retombe **toujours** à 0 au début de votre tour, quelle que soit la classe |
| 08·1 | 10 | Poison : la valeur **ne baisse jamais**, seule la durée décrémente |
| 08·2 | 10 | Brûlure : **début** du tour ennemi, **−1** par tick, disparaît à 0 |
| 08·3 | 10 | Électrocution : **chaque** coup reçu, pas le prochain |
| 08·4 | 10 | « Foudre » → **Électrocution** dans le corps de l'étape |
| 09·1 | 11 | L'intention est dans le **panneau en bas à droite**, pas au-dessus de l'ennemi |
| 09·2 | 11 | Supprimer le « ❓ » ; mentionner l'état « En attente » (sablier) |
| 10·1 | 12 | La fusion est **manuelle** : écran Deck, 3 cartes, bouton *Fusionner* |
| 10·2 | 12 | La rareté **ne change pas le coût** ; elle multiplie les valeurs |
| 11·1 | 13 | Palier d'XP : `100 × 1,5^(niveau−1)` |
| 13·1 | 15 | Retirer « ou à la Boutique » |
| 13·2 | 15 | Seul le boss « relique améliorée » en donne une |

### 6.3. Correction d'interaction — 5

Retouche de widget.

| Id | Étape | Correction |
|:---|:---:|:---|
| 04·1 | 06 | Repositionner « Fin de Tour » et le compteur au **centre vertical** du bord droit |
| 05·2 | 07 | Le tooltip s'ouvre à l'**appui simple** ; le survol ne fait qu'agrandir |
| 06·1 | 08 | La démo devient **glisser-déposer** ; le clic-pour-jouer est l'alternative |
| 06·2 | 08 | La cible d'une carte sur soi est la **carte Héros**, pas la barre PV/Mana |
| 09·3 | 11 | **Supprimer** la vignette « Affaiblissement / polluer le deck » |

### 6.4. Contenu à ajouter — 16

Nouvelles annotations ou sous-sections dans une étape existante.

| Id | Étape | Ajout |
|:---|:---:|:---|
| 02·2 | 04 | Structure de la carte : 10 planchers, goulot Élite au 5, Repos garanti au 8, 3 Boss au sommet |
| 03·1 | 05 | Autel des Reliques et Forge de Fusion |
| 03·3 | 05 | Le feu de camp a **3** options : soin 30 % PV max, forge, **retrait d'une carte** |
| 04·2 | 06 | Boutons « Mon Deck » et « Pause » en haut à droite |
| 04·3 | 08 | Double confirmation de fin de tour avec mana restant *(absorbé — §7.1)* |
| 05·4 | 07 | Le dégât final = valeur × rareté + forge + **Attaque du héros**, puis pipeline |
| 06·4 | 08 | Cycle des piles : 5 cartes/tour, main max 10, défausse en fin de tour, remélange, exil *(absorbé — §7.1)* |
| 07·2 | 09 | Les 3 passifs de classe, avec la valeur de **celui choisi** à l'étape 02 |
| 07·3 | 09 | La Maîtrise d'Armure |
| 08·5 | 10 | Les 5 statuts manquants, en tableau *(§7.2)* |
| 09·5 | 11 | La valeur d'intention est recalculée : niveau, Force, ×0,5 si Gelé |
| 10·4 | 12 | Héritage et consolidation des améliorations, plafond par rareté, **cartes uniques exclues** |
| 10·5 | 12 | La Forge de Fusion est un système distinct, payant |
| 11·2 | 13 | Les drafts s'empilent, l'XP est reportée, la carte reste verrouillée tant qu'il en reste |
| 11·3 | 13 | Deux compteurs de niveau : progression de carte et niveau d'XP |
| 13·5 | 15 | L'Autel des Reliques et les 7 déclencheurs |

**Répartition** : 13 éliminés · 16 texte · 5 interaction · 16 contenu = **50**.

---

## 7. Les trois arbitrages

### 7.1. L'étape 08 couvre le tour complet

L'ancienne étape 06 « Jouer des cartes » devient **« Jouer des cartes & finir le tour »**.

Le tutoriel n'enseigne aujourd'hui aucun cycle de tour — c'est son manque le plus coûteux, parce que
le rythme du combat en dépend entièrement. La séquence enseignée devient :

1. Piocher 5 cartes (`cardsPerTurn`)
2. Jouer par glisser-déposer, avec la zone d'annulation en bas d'écran
3. Le clic-pour-jouer comme alternative : appui sur la carte, puis sur la cible
4. Finir le tour — **double confirmation si du mana reste**
5. L'ennemi résout son intention
6. Retour au tour joueur : **armure à 0, mana au max**

Cette étape absorbe 04·3, 06·1, 06·2 et 06·4, et prépare 07·1 en le montrant avant de l'énoncer.

### 7.2. L'étape 10 ne passe pas à neuf animations

Les 4 élémentaires conservent leur simulation temporelle. Les 5 statuts manquants — Vulnérable,
Faiblesse, Force, Éveil d'Attaque, Métallisation — arrivent en **tableau récapitulatif** sur un
second écran de la même étape, avec leur icône, leur effet en une ligne et leur règle de tick.

Neuf animations noieraient la leçon, et les cinq ajoutés ne sont pas de même nature : trois sont
portés par des cartes que le joueur possédera (`demon_form`, `metallicize`), deux ne sont pas encore
appliqués par le jeu (`vulnerable`, `weakness` n'ont aucune source côté ennemi).

### 7.3. L'étape 11 perd sa quatrième vignette

L'intention « Affaiblissement / polluer votre deck » et le « ❓ » sont **supprimés**, pas reformulés.
`IntentType` ne compte que trois valeurs et aucune carte de type `status` n'existe dans le catalogue
de 23 : ces deux éléments décrivent des mécaniques absentes.

La place libérée accueille les 4 paliers d'attaque, qui arrivent gratuitement avec
`EnemyIntentsPanel`.

---

## 8. Le correctif côté jeu

`map_legend.dart:128-131` porte deux chaînes en dur, hors ARB :

```dart
label: Localizations.localeOf(context).languageCode == 'fr'
    ? "Boss (XP & Or x2)"
    : "Boss (2x XP & Gold)",
```

→ `x3` / `3x`. La clé ARB `legendBossXp` (« Boss (XP x2) »), inutilisée par la légende mais présente
dans les deux locales, est alignée dans la même passe pour éviter qu'une future réintégration ne
réintroduise le `x2`.

Aucun changement de comportement, aucun rééquilibrage : `reward_controller.dart` n'est pas touché.

---

## 9. Tests

| Fichier | État | Couverture |
|:---|:---|:---|
| `test/tutorial/tutorial_fixtures_test.dart` | **nouveau** | Les 8 ids requis existent **et** portent les propriétés dont la pédagogie dépend : `defend_basic` est une Compétence ciblant `self`, `fireball` applique `burn`, `slime` a bien un intent `attack`, `iron_talisman` est de déclencheur `startOfTurn`. Une évolution de données qui casse une leçon échoue en CI. |
| `test/tutorial/tutorial_isolation_test.dart` | **nouveau** | Aucun fichier de `lib/tutorial/` hormis `tutorial_loader.dart` n'importe `flutter_riverpod`. Rend la règle §3.2 exécutable. |
| `test/tutorial/tutorial_engine_test.dart` | **réécrit** | Les 5 tests actuels portent sur `resetMockState` et les POJOs supprimés. Nouveaux cas : persistance de la classe et du deck à travers `prepareStep`, verrou 02/03, dégâts passant par `DamagePipeline`, gain d'armure **hors** de la branche `enemy != null`. |
| `test/widget/tutorial_class_step_test.dart` | **nouveau** | Étape 02 : les 3 classes s'affichent avec leurs vraies valeurs, le choix débloque l'avancement |
| `test/widget/tutorial_starter_draft_test.dart` | **nouveau** | Étape 03 : sélection bornée à 5, cartes de classe ajoutées, deck écrit en tranche persistante |

`dart analyze` doit rester à zéro problème, `flutter test` vert.

---

## 10. Documentation et traçabilité

| Document | Action |
|:---|:---|
| `.obsidian_vault/_adr/ADR-081-*` | **Créer** — amendement de la règle d'autonomie : « zéro provider d'état » remplace « zéro Riverpod », frontière unique `tutorial_loader.dart` comme critère vérifiable |
| `.obsidian_vault/_rules/08-00-systeme-de-tutoriel-autonome.md` | **Réécrire** — 15 étapes, contrat de données, verrou 02/03. La fiche décrit aujourd'hui une étape 13 « carrousel » (c'est une carte statique) et une étape 04 montrant les Compétences (absentes du widget) : deux erreurs à corriger au passage |
| `.obsidian_vault/_memory_bank/decisionLog.md` | Indexer ADR-081 |
| `.obsidian_vault/_memory_bank/productContext.md` | Indexer la fiche 08-00 réécrite |
| `docs/ROADMAP.md` | **Créer P-45**, Tier A proposé |
| `assets/data/patch_notes.json` | Patch note via le skill `patch-notes-writer`, en fin de chantier |

La passe documentaire se fait par le skill `memory-bank-sync`, jamais à la main.

---

## 11. Hors périmètre

| Sujet | Pourquoi |
|:---|:---|
| Câbler une UI de compétences héroïques | Chantier gameplay à part entière. Tant qu'elles sont injouables, le tutoriel a **raison** de les ignorer |
| Renommer le champ `skills` de `heroes.json` en `classCards` | Touche le modèle, la sérialisation et les sauvegardes existantes (⚠️ 1.1) |
| La Brûlure non traitée pour le joueur | Sans effet aujourd'hui — aucun ennemi n'applique de statut |
| Les 6 autres systèmes jamais abordés | Or, coups critiques, événements, forge, sauvegarde/mort, dictionnaire de cartes. Chantier de contenu séparé, à arbitrer après P-45 |
| Réutiliser `HerosDraftGame` dans le tutoriel | Coût sans commune mesure avec la fidélité gagnée (D3) |

---

## 12. Risques

| Risque | Portée | Mitigation |
|:---|:---|:---|
| Le parcours à état complexifie le moteur | Moyenne | La scission persistant/scratch est explicite (§4.3) et testée ; le verrou évite les états invalides |
| `UiCard` est dimensionné pour les écrans du jeu, pas pour une vignette de tutoriel | Moyenne | Le tutoriel l'enveloppe déjà dans un `FittedBox` pour `DraftChoiceCard` — même technique |
| Une évolution de données casse une leçon sans casser le build | Faible | C'est précisément ce que couvre `tutorial_fixtures_test.dart` |
| Les deux nouvelles étapes rallongent l'onboarding | Faible | Elles remplacent une explication absente, pas une explication existante ; le bouton « Passer » reste |
| Régression sur `HomeScreen` (badge « NEW », rejouabilité) | Faible | `TutorialProgressService` n'est pas touché ; test existant conservé |

---

## 13. Estimation

| Lot | Effort | Difficulté |
|:---|:---:|:---:|
| Contrat de données : loader, modèles réels, `prepareStep` | 1 j | ★★★☆☆ |
| Étapes 02 et 03 | 1 j | ★★☆☆☆ |
| Les 37 corrections texte / interaction / contenu | 1,5 j | ★★☆☆☆ |
| Tests (2 réécrits, 4 nouveaux) | 0,5 j | ★★☆☆☆ |
| Correctif légende + documentation | 0,5 j | ★☆☆☆☆ |
| **Total** | **4,5 j** | **★★★☆☆** |

Apport : 🔥🔥🔥 — l'onboarding est le premier contact du joueur, et il enseigne aujourd'hui huit
règles à l'envers.
