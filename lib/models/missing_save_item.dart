class MissingSaveItem {
  final String id;
  final String nameFr;
  final String nameEn;
  final String category;

  const MissingSaveItem({
    required this.id,
    required this.nameFr,
    required this.nameEn,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MissingSaveItem &&
          other.id == id &&
          other.nameFr == nameFr &&
          other.nameEn == nameEn &&
          other.category == category);

  @override
  int get hashCode => Object.hash(id, nameFr, nameEn, category);

  @override
  String toString() =>
      'MissingSaveItem(id: $id, category: $category, nameFr: $nameFr, nameEn: $nameEn)';
}
