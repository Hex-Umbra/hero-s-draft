import 'dart:math';

import '../../models/data/card_data.dart';

/// Le draft de depart : deux groupes, deux quotas (spec 2026-10-25, §4.9).
///
/// Le groupe du lot (les cartes du passif actif) et le groupe des neutres se
/// remplissent chacun jusqu'a son quota. Un lot de moins de deux cartes cede
/// sa part aux neutres, pour que le deck de depart garde cinq cartes.
class StarterDraft {
  static const int deckSize = 5;
  static const int lotQuotaCap = 2;

  /// Les cartes du lot du passif actif, triees pour l'affichage.
  final List<CardData> lot;

  /// Les cartes neutres offertes, triees pour l'affichage.
  final List<CardData> neutrals;

  const StarterDraft._(this.lot, this.neutrals);

  factory StarterDraft.of(Iterable<CardData> cards, String? activePassiveId) {
    final offered = cards.where((c) => c.isOfferable(activePassiveId)).toList()
      ..sort(CardData.compareByDisplayOrder);
    return StarterDraft._(
      offered.where((c) => c.passive != null).toList(),
      offered.where((c) => c.passive == null).toList(),
    );
  }

  /// Le lot puis les neutres : l'ordre dans lequel l'ecran les affiche.
  List<CardData> get pool => [...lot, ...neutrals];

  int get lotQuota => min(lotQuotaCap, lot.length);

  int get neutralQuota => deckSize - lotQuota;

  /// Vrai si `chosen` compte moins de cartes du groupe de `card` que son quota.
  bool accepts(Iterable<CardData> chosen, CardData card) {
    final inLot = card.passive != null;
    final picked = chosen.where((c) => (c.passive != null) == inLot).length;
    return picked < (inLot ? lotQuota : neutralQuota);
  }

  /// Vrai si `chosen` remplit exactement les deux quotas.
  bool isComplete(Iterable<CardData> chosen) {
    final picked = chosen.where((c) => c.passive != null).length;
    return picked == lotQuota && chosen.length - picked == neutralQuota;
  }
}
