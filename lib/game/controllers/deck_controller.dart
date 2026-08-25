import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/card_instance.dart';
import '../../models/data/card_data.dart';
import '../../models/missing_save_item.dart';
import '../../models/data/forge_upgrade_data.dart';
import '../../services/audio/audio_providers.dart';
import '../../services/audio/game_moment.dart';

class DeckState {
  final List<CardInstance> masterDeck;
  final List<CardInstance> drawPile;
  final List<CardInstance> hand;
  final List<CardInstance> discardPile;
  final List<CardInstance> exhaustPile;

  /// Nombre de remélanges défausse → pioche depuis le début du combat.
  /// Remis à 0 par `startCombat`. Observé par l'UI pour signaler l'événement.
  final int reshuffleCount;

  const DeckState({
    this.masterDeck = const [],
    this.drawPile = const [],
    this.hand = const [],
    this.discardPile = const [],
    this.exhaustPile = const [],
    this.reshuffleCount = 0,
  });

  DeckState copyWith({
    List<CardInstance>? masterDeck,
    List<CardInstance>? drawPile,
    List<CardInstance>? hand,
    List<CardInstance>? discardPile,
    List<CardInstance>? exhaustPile,
    int? reshuffleCount,
  }) {
    return DeckState(
      masterDeck: masterDeck ?? this.masterDeck,
      drawPile: drawPile ?? this.drawPile,
      hand: hand ?? this.hand,
      discardPile: discardPile ?? this.discardPile,
      exhaustPile: exhaustPile ?? this.exhaustPile,
      reshuffleCount: reshuffleCount ?? this.reshuffleCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'masterDeck': masterDeck.map((c) => c.toJson()).toList(),
        'drawPile': drawPile.map((c) => c.toJson()).toList(),
        'hand': hand.map((c) => c.toJson()).toList(),
        'discardPile': discardPile.map((c) => c.toJson()).toList(),
        'exhaustPile': exhaustPile.map((c) => c.toJson()).toList(),
        'reshuffleCount': reshuffleCount,
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
        reshuffleCount: json['reshuffleCount'] as int? ?? 0,
      ),
      missing,
    );
  }
}

class DeckNotifier extends Notifier<DeckState> {
  late final Random _random;

  @override
  DeckState build() {
    _random = ref.read(deckRandomProvider);
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

  /// Prépare les piles pour un nouveau combat et tire la main d'ouverture,
  /// en une seule affectation d'état. La main de départ respecte exactement
  /// les mêmes invariants que toutes les pioches suivantes.
  void startCombat({required int handSize, required int maxHandSize}) {
    final result = _drawInto(
      draw: List<CardInstance>.from(state.masterDeck)..shuffle(_random),
      hand: <CardInstance>[],
      discard: <CardInstance>[],
      amount: handSize,
      maxHandSize: maxHandSize,
      random: _random,
    );

    state = state.copyWith(
      drawPile: result.draw,
      hand: result.hand,
      discardPile: result.discard,
      exhaustPile: [],
      reshuffleCount: 0,
    );
  }

  /// Cœur de la pioche. Fonction pure : ne touche pas à `state`, mute les
  /// listes qu'on lui passe et rend le nombre de remélanges effectués.
  ///
  /// Deux conditions d'arrêt, dans cet ordre :
  ///  1. la main a atteint [maxHandSize] — on s'arrête sans consommer de carte
  ///     ni déclencher de remélange ;
  ///  2. pioche ET défausse vides — le deck est épuisé, sortie propre.
  static ({
    List<CardInstance> draw,
    List<CardInstance> hand,
    List<CardInstance> discard,
    int reshuffles,
  }) _drawInto({
    required List<CardInstance> draw,
    required List<CardInstance> hand,
    required List<CardInstance> discard,
    required int amount,
    required int maxHandSize,
    required Random random,
  }) {
    var reshuffles = 0;

    for (var i = 0; i < amount; i++) {
      if (hand.length >= maxHandSize) break;
      if (draw.isEmpty) {
        if (discard.isEmpty) break;
        draw
          ..addAll(discard)
          ..shuffle(random);
        discard.clear();
        reshuffles++;
      }
      hand.add(draw.removeLast());
    }

    return (draw: draw, hand: hand, discard: discard, reshuffles: reshuffles);
  }

  /// Pioche [amount] cartes. Remélange la défausse dans la pioche dès que
  /// celle-ci est vide, y compris au milieu d'une pioche. Une seule
  /// affectation de `state`, donc une seule notification Riverpod.
  void drawCards(int amount, {required int maxHandSize}) {
    final initialHandSize = state.hand.length;
    final result = _drawInto(
      draw: List<CardInstance>.from(state.drawPile),
      hand: List<CardInstance>.from(state.hand),
      discard: List<CardInstance>.from(state.discardPile),
      amount: amount,
      maxHandSize: maxHandSize,
      random: _random,
    );

    state = state.copyWith(
      drawPile: result.draw,
      hand: result.hand,
      discardPile: result.discard,
      reshuffleCount: state.reshuffleCount + result.reshuffles,
    );

    // Un seul son par appel, meme si plusieurs cartes sont piochees d'un
    // coup ("Piocher 2"), et seulement si au moins une carte a rejoint la
    // main (pioche ET defausse vides, ou main deja pleine : silence).
    if (result.hand.length > initialHandSize) {
      ref.read(audioDirectorProvider).onMoment(GameMoment.cardDraw);
    }
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

/// Source d'aléatoire de la pioche. Surchargeable en test via
/// `deckRandomProvider.overrideWithValue(Random(42))` pour rendre les
/// séquences de pioche reproductibles.
final deckRandomProvider = Provider<Random>((ref) => Random());

final deckProvider = NotifierProvider<DeckNotifier, DeckState>(DeckNotifier.new);
