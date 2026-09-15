# Filtre de Classe sur les Pools de Cartes Proposées

**Date** : 08/09/2026
**Contexte** : découvert en marge du débat sur le moteur d'édition de contenu (menu de debug, lot 2), en vérifiant ce qu'exige réellement la création d'une nouvelle classe. Les cartes `characterSpecific` ne sont filtrées par classe dans aucun des pools d'offre : un paladin peut acheter une carte de mage en boutique.
**Statut** : Brainstorm — défaut mesuré, mécanisme proposé, **rien implémenté**. Reporté volontairement pour ne pas mêler une correction de gameplay au chantier d'outillage en cours.
**Règle visée** : pendant une run, une classe ne se voit proposer que ses propres cartes de signature, en plus des cartes globales.

---

## 1. Les cinq pools, mesurés

| Pool | Source | Filtre actuel | Verdict |
|:---|:---|:---|:---|
| Deck de départ | `starter_deck_draft_screen.dart:54-58` + `:93` | `category == global`, plus les `skills` de la classe | ✅ correct par construction |
| Boutique | `shop_controller.dart:44-50` | `type != status && rarity != unique` | ❌ **aucun filtre de classe** |
| Bonus de boss (`doubleXp`) | `reward_controller.dart:189-191` | `type != status && rarity != unique` | ❌ **aucun filtre de classe** |
| Draft de boss (`cards`) | `reward_controller.dart:170-186` → `boss_card_draft_screen.dart:56` | tiré du `masterDeck` du joueur | ✅ ne peut pas fuiter |
| Repos et Forge | `rest_card_selection_screen.dart:71`, `forge_fusion_screen.dart:135-142` | tirés du `masterDeck` | ✅ ne peuvent pas fuiter |

Le balayage est complet : **deux pools seulement** sont concernés. Tous les autres tirent du deck que le joueur possède déjà, où une carte d'une autre classe ne peut pas s'être glissée.

## 2. Ce qui est déjà correct et ne doit pas bouger

- **L'exclusion des cartes `unique` est intentionnelle** : une carte unique ne doit être ni dupliquée ni achetée. Elle reste, telle quelle, dans les deux pools.
- **L'exclusion des cartes `status`** de même.
- **Les cartes de signature arrivent d'office dans le deck de départ**, via `getHeroCards` (`hero_skills_link.dart:6-13`) appelé par `starter_deck_draft_screen.dart:93`. Elles ne transitent pas par le draft.
- **Le draft de départ ne doit surtout pas adopter le nouveau prédicat.** Il n'offre que des cartes `global` de façon délibérée : lui appliquer la règle « globales + les miennes » ferait apparaître les cartes de signature dans le pool de draft, alors qu'elles sont déjà ajoutées automatiquement. Le joueur pourrait les prendre une seconde fois. **Ce pool reste sur `category == global`.**

## 3. Pourquoi la règle n'a aujourd'hui aucun logement

Le prédicat d'éligibilité est **recopié à l'identique** aux deux endroits fautifs :

```dart
// shop_controller.dart:44-50
c.type != CardType.status && c.rarity != CardRarity.unique
// reward_controller.dart:189-191
c.type != CardType.status && c.rarity != CardRarity.unique
```

Il n'existe aucun endroit où la règle d'éligibilité d'une carte *pourrait* être écrite une seule fois. C'est la cause directe du défaut : ajouter la condition de classe demande aujourd'hui de penser à deux fichiers, et rien ne le rappellera au troisième pool créé.

## 4. Mécanisme proposé

Un prédicat unique porté par `CardData`, que tous les pools d'offre appellent :

```dart
/// Une carte est proposable à ce héros si elle n'est ni un statut ni une
/// carte unique, et si elle n'appartient à personne d'autre.
bool estProposableA(String heroClassId) =>
    type != CardType.status &&
    rarity != CardRarity.unique &&
    (heroClass == null || heroClass == heroClassId);
```

**Point d'attention sur la redondance des deux champs.** `category` (`card_data.dart:51`) et `heroClass` (`card_data.dart:52`) sont **tous deux injectés par le chargeur depuis le chemin du fichier** (`game_data_service.dart:72-85`) : `category == global` et `heroClass == null` sont deux façons de dire la même chose et ne peuvent pas diverger. Le prédicat n'en teste qu'un — `heroClass`, le plus direct. Ne pas tester les deux : un futur lecteur croirait à deux conditions distinctes.

**Câblage.** `ShopController` et `RewardController` sont des `Notifier` qui lisent déjà d'autres providers (`reward_controller.dart` lit `deckProvider`). L'identifiant de classe est disponible sans plomberie nouvelle, via `ref.read(runProvider).heroClassId` (`run_controller.dart:24`).

## 5. Portée réelle du chantier

Petite, et c'est l'intérêt de la noter maintenant : un prédicat, deux appels, deux signatures de méthode à élargir (`initializeShop` et `handleVictory` reçoivent déjà `allCards` — il leur faut en plus l'identifiant de classe, ou une lecture directe du `runProvider`).

**Le pool ne peut pas se vider.** Avec 17 cartes neutres et 2 cartes par classe, un joueur passe de 23 candidats à 19 avant exclusion des statuts et des uniques. Aucun repli sur un pool vide n'est nécessaire.

**Tests à écrire avec la correction :**
- sur N tirages de boutique pour un mage, aucune carte dont `heroClass` vaut `paladin` ou `berserker` ;
- le draft de départ continue de n'offrir que des cartes `global` — la garantie du §2, celle qu'une correction trop zélée casserait.

## 6. Comment ceci a été mesuré

Le 08/09/2026, sur `feat/menu-debug-lot-2` : recherche de toutes les sources de cartes (`gameData.cards`, `registry.cards`, `masterDeck`) dans `lib/`, puis lecture de chaque pool identifié. Volumes comptés sur `assets/data/` : 17 cartes neutres, 2 cartes par classe pour 3 classes, 25 reliques, 4 ennemis.

**Lien** : le défaut a été trouvé pendant l'analyse de ce qu'exige la création d'une classe complète, aux côtés d'un second point relevé le même jour — le codage en dur de la couleur et de l'icône de classe dans `stats_dialog.dart:47-54`, qui empêche une nouvelle classe d'être entièrement pilotée par la donnée. Celui-là est traité dans le chantier d'outillage, pas ici.
