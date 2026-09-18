import '../models/data/level_up_reward_data.dart';

/// Les nombres que la prose du tutoriel écrit en toutes lettres. Au-delà,
/// c'est le chiffre — le catalogue n'ira pas jusque-là de sitôt, et écrire
/// « quatorze » en deux langues n'a pas de lecteur.
const Map<int, ({String fr, String en})> _spelled = {
  1: (fr: 'un', en: 'one'),
  2: (fr: 'deux', en: 'two'),
  3: (fr: 'trois', en: 'three'),
  4: (fr: 'quatre', en: 'four'),
  5: (fr: 'cinq', en: 'five'),
  6: (fr: 'six', en: 'six'),
  7: (fr: 'sept', en: 'seven'),
  8: (fr: 'huit', en: 'eight'),
};

String _count(int n, {required bool isFrench}) {
  final spelled = _spelled[n];
  if (spelled == null) return '$n';
  return isFrench ? spelled.fr : spelled.en;
}

/// « A, B et C » — une virgule entre les premiers, « et » avant le dernier.
String _join(List<String> names, {required bool isFrench}) {
  if (names.isEmpty) return '';
  if (names.length == 1) return names.single;
  final et = isFrench ? ' et ' : ' and ';
  return '${names.sublist(0, names.length - 1).join(', ')}$et${names.last}';
}

List<String> _namesOf(
  List<LevelUpRewardData> rewards,
  RewardPool pool, {
  required bool isFrench,
}) {
  final inPool = rewards.where((r) => r.pool == pool).toList()
    ..sort((a, b) {
      final byOrder = a.displayOrder.compareTo(b.displayOrder);
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
  return [for (final r in inPool) r.getName(isFrench ? 'fr' : 'en')];
}

/// Remplit, dans [body], les quatre placeholders que la prose du tutoriel
/// laisse au catalogue (spec P-41, §8.1) : `{rollableCount}`,
/// `{rollableNames}`, `{mythicCount}` et `{mythicNames}`.
///
/// Fonction **pure**, sans provider et sans singleton de registre : le
/// tutoriel reçoit son registre par `TutorialScreen.data` (ADR-081, vérifié par
/// `test/tutorial/tutorial_isolation_test.dart`). Un texte qui ne nomme aucun
/// placeholder traverse inchangé.
String fillRewardPlaceholders(
  String body,
  List<LevelUpRewardData> rewards, {
  required bool isFrench,
}) {
  final rollable = _namesOf(rewards, RewardPool.draft, isFrench: isFrench);
  final mythic = _namesOf(rewards, RewardPool.mythic, isFrench: isFrench);

  return body
      .replaceAll('{rollableCount}', _count(rollable.length, isFrench: isFrench))
      .replaceAll('{rollableNames}', _join(rollable, isFrench: isFrench))
      .replaceAll('{mythicCount}', _count(mythic.length, isFrench: isFrench))
      .replaceAll('{mythicNames}', _join(mythic, isFrench: isFrench));
}
