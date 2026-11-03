import 'package:flutter_test/flutter_test.dart';
import 'package:roguelike_card_game/models/data/card_data.dart';
import 'package:roguelike_card_game/models/data/hero_data.dart';
import 'package:roguelike_card_game/models/data/lot_rules.dart';
import 'package:roguelike_card_game/models/data/passive_data.dart';
import 'package:roguelike_card_game/models/data/passive_feeds.dart';
import 'package:roguelike_card_game/models/data/relic_data.dart';
import 'package:roguelike_card_game/models/data/stat_rule.dart';

/// Les règles d'une carte de lot (spec §3.3) : ce qu'elle touche de `feeds`,
/// et A7 sur l'Armure payée sous une classe qui la convertit.
void main() {
  CardData card({
    CardType type = CardType.attack,
    List<CardEffect> effects = const [CardEffect(type: 'damage', value: 6)],
    int hpCost = 0,
    int armorCost = 0,
  }) => CardData(
    id: 'carte',
    cost: 1,
    hpCost: hpCost,
    armorCost: armorCost,
    type: type,
    rarity: CardRarity.common,
    target: CardTarget.singleEnemy,
    effects: effects,
    passive: 'lot',
  );

  PassiveData passive(List<String> feeds) => PassiveData(
    id: 'lot',
    trigger: RelicTrigger.startOfTurn,
    effectType: 'gain_armor',
    value: 1,
    feeds: feeds,
  );

  HeroData hero({List<StatRule> statRules = const []}) => HeroData(
    id: 'berserker',
    classCard: 'x',
    maxHp: 50,
    maxMana: 3,
    statRules: statRules,
  );

  const convertArmor = StatRule(
    stat: RuleStat.armor,
    mode: RuleMode.convert,
    to: RuleTarget.statusMight,
  );

  test('une carte touche feeds par son type, un effet, un statut pose, un '
      'cout, une source de scaleWith', () {
    final byType = card(type: CardType.skill, effects: const []);
    final byEffect = card(
      type: CardType.skill,
      effects: const [CardEffect(type: 'heal', value: 2)],
    );
    final byStatus = card(
      type: CardType.skill,
      effects: const [
        CardEffect(type: 'apply_status', value: 1, statusId: 'burn'),
      ],
    );
    final byCost = card(type: CardType.skill, effects: const [], hpCost: 3);
    final byScale = card(
      type: CardType.skill,
      effects: const [
        CardEffect(
          type: 'armor',
          value: 1,
          scaleWith: ScaleWith(source: ScaleSource.missingHp, ratio: 1),
        ),
      ],
    );
    expect(PassiveFeeds.touches(byType, ['skill']), isTrue);
    expect(PassiveFeeds.touches(byEffect, ['heal']), isTrue);
    expect(PassiveFeeds.touches(byStatus, ['status:burn']), isTrue);
    expect(PassiveFeeds.touches(byCost, ['cost:hp']), isTrue);
    expect(PassiveFeeds.touches(byScale, ['scale:missingHp']), isTrue);
    expect(PassiveFeeds.touches(byType, ['power', 'status:burn']), isFalse);

    final shown = card(
      effects: const [
        CardEffect(
          type: 'damage',
          value: 2,
          scaleWith: ScaleWith(source: ScaleSource.armor, ratio: 1),
        ),
      ],
      armorCost: 4,
    );
    expect(PassiveFeeds.exhibitedBy(shown), {
      'attack',
      'damage',
      'scale:armor',
      'cost:armor',
    });
  });

  test('une carte qui ne touche rien est signalee', () {
    final faults = LotRules.faultsOf(card(), passive: passive(['skill']));
    expect(faults, hasLength(1));
    expect(faults.single, contains('lot'));
  });

  test('costs.armor est une faute sous une classe qui convertit l Armure, '
      'pas ailleurs', () {
    final costly = card(armorCost: 4);
    final feeds = passive(['cost:armor']);
    final faults = LotRules.faultsOf(
      costly,
      passive: feeds,
      heroClass: hero(statRules: const [convertArmor]),
    );
    expect(faults, hasLength(1));
    expect(faults.single, contains('berserker'));
    expect(LotRules.faultsOf(costly, passive: feeds, heroClass: hero()), isEmpty);
  });

  test('costs.hp n est jamais une faute d A7', () {
    final faults = LotRules.faultsOf(
      card(hpCost: 4),
      passive: passive(['cost:hp']),
      heroClass: hero(statRules: const [convertArmor]),
    );
    expect(faults, isEmpty);
  });
}
