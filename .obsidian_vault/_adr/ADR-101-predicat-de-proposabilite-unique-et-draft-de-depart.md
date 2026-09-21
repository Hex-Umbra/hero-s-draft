---
description: Single offerability predicate on CardData, and why the starter draft stays out of it
---

# ADR-101 — Le Prédicat de Proposabilité, Unique et Porté par `CardData` ; le Draft de Départ Reste Dehors

### Statut

✅ Accepté — 2026-09-21. Livré sur la branche `fix/filtre-cartes-de-classe`, commit `3727f09`.
**Complète [ADR-094](ADR-094-echelle-de-rarete-explicite-et-runes-non-cumulables.md)**, qui avait
posé `CardRarity.isAcquirable` ; **prérequis de P-42**, qui multipliera les cartes de classe.

### Contexte

Une carte de signature n'appartient qu'à sa classe. Rien dans le code ne le disait.

Le prédicat d'éligibilité d'une carte proposée était **recopié à l'identique** aux deux seuls pools
d'offre qui tirent du registre plutôt que du deck du joueur :

```dart
// shop_controller.dart, reward_controller.dart — deux copies, mot pour mot
c.type != CardType.status && c.rarity.isAcquirable
```

Ni `ShopController` ni `RewardController` ne lisait `runProvider.heroClassId`, et `CardData` ne
portait aucun prédicat de proposabilité. **C'était la cause directe du défaut, plus que le défaut
lui-même** : il n'existait aucun endroit où la règle *pouvait* s'écrire une seule fois, donc rien
n'aurait rappelé la condition de classe au troisième pool créé.

> [!IMPORTANT]
> **Le défaut était latent, pas observable.** Les six cartes de classe livrées sont toutes
> `rarity: "unique"`, et le sont depuis `f381e85` (2026-09-05) — antérieur au brainstorm du
> 08/09/2026 qui a décrit le défaut. `rarity.isAcquirable` les excluait donc déjà, toutes, des
> deux pools : **aucun joueur ne s'est jamais vu proposer la carte d'une autre classe.** La prémisse
> du brainstorm (« un paladin peut acheter une carte de mage en boutique ») était déjà fausse quand
> elle a été écrite ; son §1 relevait l'exclusion des `unique` sans la croiser avec la donnée.
> La fuite devient réelle **au premier signature non `unique`**, c'est-à-dire avec P-42.
> C'est pourquoi la correction est livrée **sans note de version** : rien n'a changé pour le joueur.

### Décision

**D1 — Un prédicat unique, porté par `CardData`.** `CardData.isOfferableTo(String heroClassId)`
porte la règle entière — statut, rareté, appartenance de classe — et les deux pools d'offre
l'appellent. La règle a désormais un domicile ; le troisième pool le trouvera.

**D2 — Le prédicat ne teste que `heroClass`, jamais `category` en plus.** Le chargeur injecte les
deux champs depuis **le même chemin de fichier** : `category == global` et `heroClass == null` sont
deux façons de dire la même chose et ne peuvent pas diverger. Les tester tous les deux ferait croire
à un futur lecteur qu'il y a deux conditions.

**D3 — Le draft de départ reste sur `category == global`, et n'adopte pas le prédicat.** Ce n'est
pas un oubli, c'est la règle. Les cartes de signature sont ajoutées **d'office** au deck de départ
par `getHeroCards` ; les offrir *aussi* au draft les rendrait prenables une seconde fois. C'est le
piège exact qu'une correction trop zélée tend, et il est gardé par un test — vérifié en appliquant
la correction fautive : le pool passe de 10 à 11 cartes offertes.

**D4 — Aucun repli sur pool vide.** Avec 17 cartes neutres, un joueur n'a jamais moins de 17
candidats après filtrage. Le cas ne se présente pas ; ne pas coder une branche pour lui.

### Preuves dans le code

| Élément | Emplacement |
|:---|:---|
| Le prédicat | `lib/models/data/card_data.dart` — `CardData.isOfferableTo` |
| La règle de rareté qu'il réemploie | `lib/models/data/card_data.dart` — `CardRarity.isAcquirable` (ADR-094) |
| Pool de boutique | `lib/game/controllers/shop_controller.dart` — `_getEligibleCards` |
| Pool du bonus de boss `doubleXp` | `lib/game/controllers/reward_controller.dart` — `handleVictory` |
| Le draft de départ, délibérément à part | `lib/ui/screens/starter_deck_draft_screen.dart` — `_generateDraftPool` |
| Tests du prédicat | `test/unit/card_offer_filter_test.dart` |
| Tests de fuite, 200 tirages par pool | `test/unit/shop_controller_test.dart`, `test/unit/reward_controller_test.dart` |
| Garde du draft de départ | `test/widget/starter_deck_draft_screen_test.dart` |
| Le brainstorm d'origine, réaligné | [08-09-2026_filtre_cartes_de_classe_Opus5.md](../../docs/possible_upgrades/08-09-2026_filtre_cartes_de_classe_Opus5.md) |

### Conséquences

- **P-42 n'a plus cette condition préalable.** Ses cartes de classe peuvent porter n'importe quelle
  rareté sans fuir d'une classe à l'autre.
- **Les deux pools ne dupliquent plus rien.** Ajouter une condition d'offre future — une rareté
  interdite en acte 1, une carte débloquée par méta-progression — se fait en un endroit.
- **Le brainstorm du 08/09 a été réaligné, pas réécrit.** Son §1, §3 et §4 citaient
  `rarity != CardRarity.unique`, l'état du code avant P-40 bloc 2 ; une note datée dit ce qui a
  changé et pourquoi le mécanisme proposé reste juste.
- **Une leçon sur les brainstorms** : le défaut y était mesuré sur le code sans être croisé avec la
  donnée. Un pool fautif dont tous les candidats sont déjà exclus par une autre règle est un défaut
  réel de structure et un non-défaut de gameplay — les deux méritent d'être distingués au moment
  d'écrire la note de version.
