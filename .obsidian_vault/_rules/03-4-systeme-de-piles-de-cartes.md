### 3.4. 🃏 Système de Piles de Cartes

Cinq piles logiques gérées par `DeckNotifier` :

```
[Master Deck]  ── Persistant entre combats. Source de vérité.
      │
      ▼ (startCombat: copie + shuffle, puis main d'ouverture)
[Draw Pile]  ──  Pioche: drawCards(amount, maxHandSize:)
      │    ▲               │
      │    │               ▼
      │    │            [Hand]  ──────►  [Discard Pile]  (playCard → si non-Power/non-Exhaust)
      │    │                                   │
      │    └── remélange automatique ◄─────────┘
      │        (uniquement si Draw Pile vide)
      │
      └──────────►  [Exhaust Pile]  (cartes Power, cartes isExhaust)
                      Retiré définitivement du combat en cours
```

> [!IMPORTANT]
> **Invariant de conservation.** À tout instant :
> `masterDeck.length == drawPile + hand + discardPile + exhaustPile`.
> Aucune carte ne se perd ni ne se duplique entre les piles. Cet invariant est asserté
> par `expectConservation()` dans chaque test du moteur de pioche.

#### Les deux règles de la pioche

**1. Remélange à sec.** La défausse retourne dans la pioche **uniquement** lorsque
celle-ci est vide, y compris au milieu d'une pioche. Une carte « Piocher 3 » sur une
pioche d'une seule carte tire cette carte, remélange, puis tire les deux suivantes.
Il n'existe **aucun** appel manuel de remélange : la règle n'est pas optionnelle.

**2. Arrêt net sur main pleine.** Quand la main atteint `GameConstants.maxHandSize`
(**10**), la pioche s'interrompt immédiatement — **sans consommer de carte et sans
déclencher de remélange**. Une main pleine sur pioche vide ne gaspille donc pas un cycle
de deck entier pour ne rien donner au joueur.

L'ordre de ces deux tests d'arrêt compte : main pleine est évaluée **avant** pioche vide.

#### Combien de cartes, et quand

| Moment | Nombre | Source |
|:---|:---|:---|
| Main d'ouverture d'un combat | `RunState.cardsPerTurn` | `TurnPhaseManager.startPlayerCombat()` |
| Début de chaque tour joueur | `RunState.cardsPerTurn` | `TurnPhaseManager.startPlayerTurn()` |
| Effet de carte (`draw`) ou rune `quick` | valeur de l'effet | `DrawEffectStrategy`, `EffectResolver.resolveCard()` |

`cardsPerTurn` vaut **5** par défaut et se modifie par relique — voir
[03-5-systeme-de-reliques.md](03-5-systeme-de-reliques.md), `scholars_satchel`.
Le tour 1 et le tour N+1 empruntent le même code : il n'y a plus de chemin d'ouverture
distinct.

#### Observabilité

`DeckState.reshuffleCount` compte les remélanges depuis le début du combat. Il est remis
à 0 par `startCombat()`, sérialisé, et vaut 0 sur toute sauvegarde antérieure au chantier.
L'écran de combat l'observe pour afficher la notification « Défausse remélangée ».

Conception complète — [ADR-078](../_adr/ADR-078-assainissement-du-systeme-de-pioche-remelange-a-sec.md).
