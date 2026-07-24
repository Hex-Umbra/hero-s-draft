import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/missing_save_item.dart';
import '../../models/data/forge_upgrade_data.dart';

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

  Map<String, dynamic> toJson() => {
        'masterDeck': masterDeck.map((c) => c.toJson()).toList(),
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'hand': hand.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'exhaustPile': exhaustPile.map((c) => c.toJson()).toList(),
      };

  static (List<CardInstance>, List<MissingSaveItem>) _decodePile(
    List<dynamic>? rawPile,
  ) {
    final kept = <CardInstance>[];
    final missing = <MissingSaveItem>[];

    for (final entry in (rawPile ?? const [])) {
      final instance = CardInstance.fromJson(entry as Map<String, dynamic>);
      final freshData = CardData.getById(instance.data.id);
      if (freshData == null) {
        missing.add(
          MissingSaveItem(
            id: instance.data.id,
            nameFr: instance.data.nameFr,
            nameEn: instance.data.nameEn,
            category: 'card',
          ),
        );
        continue;
      }
      final (validUpgrades, upgradesMissing) =
          ForgeUpgradeData.filterValidRefs(instance.forgeUpgrades);
      missing.addAll(upgradesMissing);
      kept.add(instance.copyWith(data: freshData, forgeUpgrades: validUpgrades));
    }

    return (kept, missing);
  }

  static (DeckState, List<MissingSaveItem>) fromJsonWithReport(
    Map<String, dynamic> json,
  ) {
    final missing = <MissingSaveItem>[];

    final (masterDeck, m1) = _decodePile(json['masterDeck'] as List<dynamic>?);
    final (drawPile, m2) = _decodePile(json['drawPile'] as List<dynamic>?);
    final (hand, m3) = _decodePile(json['hand'] as List<dynamic>?);
    final (discardPile, m4) = _decodePile(json['discardPile'] as List<dynamic>?);
    final (exhaustPile, m5) = _decodePile(json['exhaustPile'] as List<dynamic>?);
    missing
      ..addAll(m1)
      ..addAll(m2)
      ..addAll(m3)
      ..addAll(m4)
      ..addAll(m5);

    return (
      DeckState(
        masterDeck: masterDeck,
        drawPile: drawPile,
        hand: hand,
        discardPile: discardPile,
        exhaustPile: exhaustPile,
      ),
      missing,
    );
  }
}

class DeckNotifier extends Notifier<DeckState> {
  @override
  DeckState build() {
    return const DeckState();
  }

  /// Vide complètement le deck (pour une nouvelle run)
  void clearDeck() {
    state = const DeckState();
  }

  /// Remplace intégralement l'état par une sauvegarde chargée
  void hydrate(DeckState savedState) {
    state = savedState;
  }

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

  /// Pioche [amount] cartes depuis la pioche actuelle uniquement (sans mélange de défausse mid-turn)
  void drawCards(int amount) {
    var currentDrawPile = List<CardInstance>.from(state.drawPile);
    var currentHand = List<CardInstance>.from(state.hand);

    final int toDraw = min(amount, currentDrawPile.length);
    for (int i = 0; i < toDraw; i++) {
      currentHand.add(currentDrawPile.removeLast());
    }

    state = state.copyWith(drawPile: currentDrawPile, hand: currentHand);
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

    state = state.copyWith(hand: [], discardPile: currentDiscardPile);
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

      final isExhausted = cardToPlay.data.isExhaust && !cardToPlay.forgeUpgrades.contains('enduring:1');

      if (cardToPlay.data.type == CardType.power || isExhausted) {
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

  /// Fusionne 3 cartes identiques en une carte de rareté supérieure
  void mergeCards(List<String> selectedIds, List<String> inheritedUpgrades) {
    if (selectedIds.length != 3) return;
    var currentMasterDeck = List<CardInstance>.from(state.masterDeck);

    final List<CardInstance> selectedCards = [];
    for (var id in selectedIds) {
      final cardIdx = currentMasterDeck.indexWhere((c) => c.uniqueId == id);
      if (cardIdx != -1) {
        selectedCards.add(currentMasterDeck[cardIdx]);
      }
    }

    if (selectedCards.length == 3) {
      if (selectedCards.any((c) => c.rarity == CardRarity.unique)) {
        return;
      }
      final baseCardData = selectedCards[0].data;
      final rarity = selectedCards[0].rarity;

      // Retire les 3 exemplaires
      currentMasterDeck.removeWhere((c) => selectedIds.contains(c.uniqueId));

      // Détermine la rareté suivante
      final nextRarityIndex = min(rarity.index + 1, CardRarity.values.length - 1);
      final nextRarity = CardRarity.values[nextRarityIndex];

      // Auto-fusionne les upgrades identiques (cumul des tiers)
      final Map<String, int> consolidatedMap = {};
      for (var upgrade in inheritedUpgrades) {
        final parts = upgrade.split(':');
        if (parts.length != 2) continue;
        final id = parts[0];
        final tier = int.tryParse(parts[1]) ?? 0;
        if (tier <= 0) continue;
        consolidatedMap[id] = (consolidatedMap[id] ?? 0) + tier;
      }

      var finalUpgrades = consolidatedMap.entries.map((e) => '${e.key}:${e.value}').toList();

      // Limite à la capacité de la rareté supérieure
      final capacity = baseCardData.baseMaxForgeUpgrades + nextRarityIndex;
      if (finalUpgrades.length > capacity) {
        finalUpgrades = finalUpgrades.sublist(0, capacity);
      }

      // Ajoute la carte de rareté supérieure avec les upgrades finalisés
      currentMasterDeck.add(
        CardInstance(
          data: baseCardData,
          rarity: nextRarity,
          forgeUpgrades: finalUpgrades,
        ),
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

  /// Améliore une carte définitivement (Forge) en augmentant sa rareté
  void upgradeCard(String uniqueId) {
    state = state.copyWith(
      masterDeck: state.masterDeck.map((c) {
        if (c.uniqueId == uniqueId) {
          final nextRarityIndex = min(c.rarity.index + 1, CardRarity.values.length - 1);
          return c.copyWith(rarity: CardRarity.values[nextRarityIndex]);
        }
        return c;
      }).toList(),
    );
  }

  /// Ajoute une amélioration de forge à une carte spécifique du Master Deck
  void addForgeUpgrade(String uniqueId, String upgrade) {
    state = state.copyWith(
      masterDeck: state.masterDeck.map((c) {
        if (c.uniqueId == uniqueId) {
          final updatedUpgrades = List<String>.from(c.forgeUpgrades)..add(upgrade);
          return c.copyWith(forgeUpgrades: updatedUpgrades);
        }
        return c;
      }).toList(),
    );
  }

  /// Met à jour les runes d'une carte après fusion
  void setForgeUpgrades(String uniqueId, List<String> upgrades) {
    state = state.copyWith(
      masterDeck: state.masterDeck.map((c) {
        if (c.uniqueId == uniqueId) {
          return c.copyWith(forgeUpgrades: upgrades);
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

final deckProvider = NotifierProvider<DeckNotifier, DeckState>(DeckNotifier.new);
