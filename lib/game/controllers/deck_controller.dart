import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';

class DeckState {
  final List<CardInstance> masterDeck;
  final List<CardInstance> drawPile;
  final List<CardInstance> hand;
  final List<CardInstance> discardPile;
  final List<CardInstance> exhaustPile;

  const DeckState({
    this.masterDeck = const [],
    this.drawPile = const [],
    this.hand = const [],
    this.discardPile = const [],
    this.exhaustPile = const [],
  });

  DeckState copyWith({
    List<CardInstance>? masterDeck,
    List<CardInstance>? drawPile,
    List<CardInstance>? hand,
    List<CardInstance>? discardPile,
    List<CardInstance>? exhaustPile,
  }) {
    return DeckState(
      masterDeck: masterDeck ?? this.masterDeck,
      drawPile: drawPile ?? this.drawPile,
      hand: hand ?? this.hand,
      discardPile: discardPile ?? this.discardPile,
      exhaustPile: exhaustPile ?? this.exhaustPile,
    );
  }
}

class DeckNotifier extends StateNotifier<DeckState> {
  DeckNotifier() : super(const DeckState());

  /// Initialise le master deck au début d'une run
  void initializeStarterDeck(List<CardInstance> initialDeck) {
    state = state.copyWith(masterDeck: initialDeck);
  }

  /// Prépare les piles pour un nouveau combat
  void initializeCombat() {
    final newDrawPile = List<CardInstance>.from(state.masterDeck);
    newDrawPile.shuffle(Random());

    state = state.copyWith(
      drawPile: newDrawPile,
      hand: [],
      discardPile: [],
      exhaustPile: [],
    );
  }

  /// Pioche [amount] cartes
  void drawCards(int amount) {
    var currentDrawPile = List<CardInstance>.from(state.drawPile);
    var currentHand = List<CardInstance>.from(state.hand);
    var currentDiscardPile = List<CardInstance>.from(state.discardPile);

    for (int i = 0; i < amount; i++) {
      if (currentDrawPile.isEmpty) {
        if (currentDiscardPile.isEmpty) {
          // Plus aucune carte à piocher dans la défausse non plus
          break;
        }
        // Mélange la défausse dans la pioche
        currentDrawPile = List<CardInstance>.from(currentDiscardPile);
        currentDrawPile.shuffle(Random());
        currentDiscardPile.clear();
      }

      currentHand.add(currentDrawPile.removeLast());
    }

    state = state.copyWith(
      drawPile: currentDrawPile,
      hand: currentHand,
      discardPile: currentDiscardPile,
    );
  }

  /// Mélange la défausse dans la pioche manuellement
  void shuffleDiscardIntoDraw() {
    var newDrawPile = List<CardInstance>.from(state.drawPile);
    var currentDiscardPile = List<CardInstance>.from(state.discardPile);

    newDrawPile.addAll(currentDiscardPile);
    newDrawPile.shuffle(Random());

    state = state.copyWith(drawPile: newDrawPile, discardPile: []);
  }

  /// Défausse toute la main à la fin du tour
  void discardHand() {
    final currentHand = List<CardInstance>.from(state.hand);
    final currentDiscardPile = List<CardInstance>.from(state.discardPile);

    if (currentHand.isEmpty) return;

    currentDiscardPile.addAll(currentHand);
    
    state = state.copyWith(
      hand: [], 
      discardPile: currentDiscardPile,
    );
  }

  /// Joue une carte : la retire de la main et l'envoie dans la défausse (ou l'épuise si pouvoir)
  void playCard(CardInstance card) {
    var currentHand = List<CardInstance>.from(state.hand);
    var currentDiscardPile = List<CardInstance>.from(state.discardPile);
    var currentExhaustPile = List<CardInstance>.from(state.exhaustPile);

    // Trouver l'index pour ne supprimer qu'un seul exemplaire si doublons (sécurité)
    final index = currentHand.indexWhere((c) => c.uniqueId == card.uniqueId);

    if (index != -1) {
      final cardToPlay = currentHand.removeAt(index);

      if (cardToPlay.data.type == CardType.power || cardToPlay.data.isExhaust) {
        currentExhaustPile.add(cardToPlay);
      } else {
        currentDiscardPile.add(cardToPlay);
      }

      state = state.copyWith(
        hand: currentHand,
        discardPile: currentDiscardPile,
        exhaustPile: currentExhaustPile,
      );
    }
  }

  /// Ajoute une carte au Master Deck
  void addCardToMasterDeck(CardInstance newCard) {
    state = state.copyWith(masterDeck: [...state.masterDeck, newCard]);
  }

  /// Fusionne 3 cartes identiques en une carte de niveau supérieur
  void mergeCards(String cardId, int level) {
    var currentMasterDeck = List<CardInstance>.from(state.masterDeck);

    // Trouve les 3 exemplaires
    var duplicates = currentMasterDeck
        .where((c) => c.data.id == cardId && c.level == level)
        .toList();

    if (duplicates.length >= 3) {
      // Retire les 3 exemplaires (en utilisant uniqueId pour être sûr)
      final idsToRemove = duplicates.take(3).map((c) => c.uniqueId).toSet();
      currentMasterDeck.removeWhere((c) => idsToRemove.contains(c.uniqueId));

      // Ajoute la carte de niveau supérieur
      currentMasterDeck.add(
        CardInstance(data: duplicates[0].data, level: level + 1),
      );

      state = state.copyWith(masterDeck: currentMasterDeck);
    }
  }

  /// Retire une carte spécifique du Master Deck (ex: Boutique ou Oubli)
  void removeCardById(String uniqueId) {
    var currentMasterDeck = List<CardInstance>.from(state.masterDeck);
    currentMasterDeck.removeWhere((c) => c.uniqueId == uniqueId);
    state = state.copyWith(masterDeck: currentMasterDeck);
  }

  /// Améliore une carte (niveau +1) définitivement (Forge)
  void upgradeCard(String uniqueId) {
    state = state.copyWith(
      masterDeck: state.masterDeck.map((c) {
        if (c.uniqueId == uniqueId) {
          return c.copyWith(level: c.level + 1);
        }
        return c;
      }).toList(),
    );
  }

  /// Retire une carte spécifique du Master Deck (ex: Boutique)
  void removeCardFromMasterDeck(CardInstance cardToRemove) {
    removeCardById(cardToRemove.uniqueId);
  }

  /// Ajoute une carte spécifique directement dans la défausse (ex: blessure d'ennemi)
  void addCardToDiscardPile(CardInstance newCard) {
    var currentDiscardPile = List<CardInstance>.from(state.discardPile);
    currentDiscardPile.add(newCard);
    state = state.copyWith(discardPile: currentDiscardPile);
  }
}

final deckProvider = StateNotifierProvider<DeckNotifier, DeckState>((ref) {
  return DeckNotifier();
});
