import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/skill_data.dart';
import '../models/data/card_data.dart';
import '../models/data/event_data.dart';
import '../models/data/passive_data.dart';
import '../models/data/game_data_registry.dart';

final gameDataLoaderProvider = FutureProvider<GameDataRegistry>((ref) async {
  final enemiesJson = await rootBundle.loadString('assets/data/enemies.json');
  final heroesJson = await rootBundle.loadString('assets/data/heroes.json');
  final skillsJson = await rootBundle.loadString('assets/data/skills.json');
  final cardsJson = await rootBundle.loadString('assets/data/cards.json');
  final eventsJson = await rootBundle.loadString('assets/data/events.json');
  final passivesJson = await rootBundle.loadString('assets/data/passives.json');

  final enemiesList = jsonDecode(enemiesJson) as List;
  final heroesList = jsonDecode(heroesJson) as List;
  final skillsList = jsonDecode(skillsJson) as List;
  final cardsList = jsonDecode(cardsJson) as List;
  final eventsList = jsonDecode(eventsJson) as List;
  final passivesList = jsonDecode(passivesJson) as List;

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
    cards: cardsList
        .map((e) => CardData.fromJson(e as Map<String, dynamic>))
        .toList(),
    events: eventsList
        .map((e) => EventData.fromJson(e as Map<String, dynamic>))
        .toList(),
    passives: passivesList
        .map((e) => PassiveData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
});
