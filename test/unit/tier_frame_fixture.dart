import 'package:roguelike_card_game/models/data/tier_frame_data.dart';

/// Les cinq cadres de B73, tels que `assets/data/tier_frames.json` les livre
/// (spec P-05, vague 2, §4.1).
const List<TierFrame> testTierFrames = [
  TierFrame(tier: 1, width: 88, height: 120, windowX: 12, windowY: 12),
  TierFrame(tier: 2, width: 96, height: 128, windowX: 16, windowY: 16),
  TierFrame(tier: 3, width: 104, height: 136, windowX: 20, windowY: 20),
  TierFrame(tier: 4, width: 112, height: 144, windowX: 24, windowY: 24),
  TierFrame(tier: 5, width: 120, height: 152, windowX: 28, windowY: 28),
];

/// Le cadre du [tier] dans [testTierFrames].
TierFrame testFrameOf(int tier) =>
    testTierFrames.firstWhere((frame) => frame.tier == tier);
