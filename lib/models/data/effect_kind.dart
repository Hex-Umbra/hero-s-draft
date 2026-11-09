import 'card_data.dart';

/// La sorte d'un effet, telle que la bande et la liste de combat la nomment
/// (spec A39) : la clé de la table d'icônes d'effet.
abstract final class EffectKind {
  /// Le critique : ce n'est pas un effet de carte, c'est un bonus de chances.
  static const crit = 'crit';

  /// La cible « tous les ennemis » d'une évolution.
  static const allEnemies = 'target:allEnemies';

  /// Les types d'effet qui sont leur propre sorte.
  static const plain = {'damage', 'armor', 'heal', 'draw', 'gain_mana'};

  static final _statusKind = RegExp(r'^status:[a-z][a-z0-9]*(_[a-z0-9]+)*$');

  /// La sorte de [effect] : `status:<statusId>` pour un `apply_status`, son
  /// type sinon.
  static String of(CardEffect effect) => effect.type == 'apply_status'
      ? 'status:${effect.statusId}'
      : effect.type;

  /// Vrai si [key] est une sorte : un de [plain], [crit], [allEnemies], ou
  /// `status:<id>` à l'id en `snake_case`. La seule écriture du vocabulaire.
  static bool isKind(String key) =>
      plain.contains(key) ||
      key == crit ||
      key == allEnemies ||
      _statusKind.hasMatch(key);
}
