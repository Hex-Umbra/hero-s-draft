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
    
    state = state.copyWith(
      drawPile: newDrawPile,
      discardPile: [],
    );
  }

  /// Défausse toute la main à la fin du tour
  void discardHand() {
    var currentHand = List<CardInstance>.from(state.hand);
    var currentDiscardPile = List<CardInstance>.from(state.discardPile);
    
    currentDiscardPile.addAll(currentHand);
    currentHand.clear();
    
    state = state.copyWith(
      hand: currentHand,
      discardPile: currentDiscardPile,
    );
  }

  /// Joue une carte : la retire de la main et l'envoie dans la défausse (ou l'épuise si pouvoir)
  void playCard(CardInstance card) {
    var currentHand = List<CardInstance>.from(state.hand);
    var currentDiscardPile = List<CardInstance>.from(state.discardPile);
    var currentExhaustPile = List<CardInstance>.from(state.exhaustPile);

    currentHand.removeWhere((c) => c.uniqueId == card.uniqueId);

    if (card.data.type == CardType.power) {
      currentExhaustPile.add(card);
    } else {
      currentDiscardPile.add(card);
    }

    state = state.copyWith(
      hand: currentHand,
      discardPile: currentDiscardPile,
      exhaustPile: currentExhaustPile,
    );
  }

  /// Ajoute une carte au Master Deck avec système d'Auto-Merge
  void addCardToMasterDeck(CardInstance newCard) {
    var currentMasterDeck = List<CardInstance>.from(state.masterDeck);
    currentMasterDeck.add(newCard);

    // Vérification de la fusion
    bool merged = true;
    while (merged) {
      merged = false;
      // Parcourt le deck pour trouver 3 exemplaires identiques
      for (var card in currentMasterDeck) {
        var duplicates = currentMasterDeck.where((c) => c.data.id == card.data.id && c.level == card.level).toList();
        if (duplicates.length >= 3) {
          // Retire 3 exemplaires
          for (int i = 0; i < 3; i++) {
            currentMasterDeck.removeWhere((c) => c.uniqueId == duplicates[i].uniqueId);
          }
          // Ajoute la carte de niveau supérieur
          currentMasterDeck.add(CardInstance(
            data: card.data,
            level: card.level + 1,
          ));
          merged = true;
          break; // On relance la boucle
        }
      }
    }

    state = state.copyWith(masterDeck: currentMasterDeck);
  }

  /// Retire une carte spécifique du Master Deck (ex: Boutique)
  void removeCardFromMasterDeck(CardInstance cardToRemove) {
    var currentMasterDeck = List<CardInstance>.from(state.masterDeck);
    currentMasterDeck.removeWhere((c) => c.uniqueId == cardToRemove.uniqueId);
    state = state.copyWith(masterDeck: currentMasterDeck);
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
