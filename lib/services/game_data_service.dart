import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/skill_data.dart';
import '../models/data/card_data.dart';
import '../models/data/event_data.dart';
import '../models/data/passive_data.dart';
import '../models/data/relic_data.dart';
import '../models/data/game_data_registry.dart';

final gameDataLoaderProvider = FutureProvider<GameDataRegistry>((ref) async {
  final results = await Future.wait([
    rootBundle.loadString('assets/data/enemies.json'),
    rootBundle.loadString('assets/data/heroes.json'),
    rootBundle.loadString('assets/data/skills.json'),
    rootBundle.loadString('assets/data/cards.json'),
    rootBundle.loadString('assets/data/events.json'),
    rootBundle.loadString('assets/data/passives.json'),
    rootBundle.loadString('assets/data/relics.json'),
    rootBundle.loadString('assets/data/hero_cards.json'),
  ]);

  final enemiesList = jsonDecode(results[0]) as List;
  final heroesList = jsonDecode(results[1]) as List;
  final skillsList = jsonDecode(results[2]) as List;
  final cardsList = jsonDecode(results[3]) as List;
  final eventsList = jsonDecode(results[4]) as List;
  final passivesList = jsonDecode(results[5]) as List;
  final relicsList = jsonDecode(results[6]) as List;
  final heroCardsList = jsonDecode(results[7]) as List;

  final allCards = [
    ...cardsList,
    ...heroCardsList,
  ];

  return GameDataRegistry(
    enemies: enemiesList
        .map((e) => EnemyData.fromJson(e as Map<String, dynamic>))
        .toList(),
    heroes: heroesList
        .map((e) => HeroData.fromJson(e as Map<String, dynamic>))
        .toList(),
    skills: skillsList
        .map((e) => SkillData.fromJson(e as Map<String, dynamic>))
        .toList(),
    cards: allCards
        .map((e) => CardData.fromJson(e as Map<String, dynamic>))
        .toList(),
    events: eventsList
        .map((e) => EventData.fromJson(e as Map<String, dynamic>))
        .toList(),
    passives: passivesList
        .map((e) => PassiveData.fromJson(e as Map<String, dynamic>))
        .toList(),
    relics: relicsList
        .map((e) => RelicData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});
