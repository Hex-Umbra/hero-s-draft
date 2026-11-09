import 'effect_kind.dart';

/// L'icône et la couleur d'une sorte d'effet, par leur nom : la traduction en
/// `IconData` et `Color` vit dans `lib/ui/` (`effect_style.dart`).
class EffectIconEntry {
  final String icon;
  final String color;

  const EffectIconEntry({required this.icon, required this.color});
}

/// La table des icônes d'effet (spec P-42 T1 et P-44 lot 1, §3.7, A39) : pour
/// chaque sorte d'effet, l'icône et la couleur que la bande, la liste et le
/// panneau des statuts lui donnent, lues dans `assets/data/effect_icons.json`.
///
/// Un document de configuration, pas une entité : ni id, ni dossier.
class EffectIconTable {
  final Map<String, EffectIconEntry> _entries;

  const EffectIconTable(Map<String, EffectIconEntry> entries)
      : _entries = entries;

  const EffectIconTable.empty() : _entries = const {};

  /// L'entrée de [kind], `null` si la table ne la porte pas.
  EffectIconEntry? entryOf(String kind) => _entries[kind];

  /// Les sortes que la table porte.
  Iterable<String> get kinds => _entries.keys;

  /// Refuse, en nommant la clé : une clé qui n'est pas une sorte, `apply_status`
  /// nu compris ; une valeur qui n'est pas un objet à `icon` et `color`, deux
  /// textes non vides, sans autre clé.
  factory EffectIconTable.fromJson(Map<String, dynamic> json) {
    final entries = <String, EffectIconEntry>{};
    for (final MapEntry(key: kind, value: raw) in json.entries) {
      if (!EffectKind.isKind(kind)) {
        throw FormatException(
          'effect_icons : "$kind" n est pas une sorte d effet (damage, armor, '
          'heal, draw, gain_mana, status:<id>, crit, target:allEnemies)',
        );
      }
      if (raw is! Map<String, dynamic>) {
        throw FormatException(
          'effect_icons : "$kind" doit etre un objet a "icon" et "color"',
        );
      }
      for (final key in raw.keys) {
        if (key != 'icon' && key != 'color') {
          throw FormatException(
            'effect_icons : "$kind" porte une cle "$key" de trop',
          );
        }
      }
      String text(String key) {
        final value = raw[key];
        if (value is! String || value.isEmpty) {
          throw FormatException(
            'effect_icons : "$kind" doit porter "$key", un texte non vide',
          );
        }
        return value;
      }

      entries[kind] = EffectIconEntry(icon: text('icon'), color: text('color'));
    }
    return EffectIconTable(Map.unmodifiable(entries));
  }
}
