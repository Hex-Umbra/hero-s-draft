import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data/enemy_data.dart';
import '../models/data/hero_data.dart';
import '../models/data/skill_data.dart';
import '../models/data/game_data_registry.dart';

final gameDataLoaderProvider = FutureProvider<GameDataRegistry>((ref) async {
  final enemiesJson = await rootBundle.loadString('assets/data/enemies.json');
  final heroesJson = await rootBundle.loadString('assets/data/heroes.json');
  final skillsJson = await rootBundle.loadString('assets/data/skills.json');

  final enemiesList = jsonDecode(enemiesJson) as List;
  final heroesList = jsonDecode(heroesJson) as List;
  final skillsList = jsonDecode(skillsJson) as List;

  return GameDataRegistry(
    enemies: enemiesList.map((e) => EnemyData.fromJson(e as Map<String, dynamic>)).toList(),
    heroes: heroesList.map((e) => HeroData.fromJson(e as Map<String, dynamic>)).toList(),
    skills: skillsList.map((e) => SkillData.fromJson(e as Map<String, dynamic>)).toList(),
  );
});
