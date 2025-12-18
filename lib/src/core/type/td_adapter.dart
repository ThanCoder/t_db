abstract class TDAdapter<T> {
  int getUniqueFieldId();
  Map<String, dynamic> toMap(T value);
  T fromMap(Map<String, dynamic> map);
  int getId(T value);
  Type get getType => T;

  /// 🔑 IMPORTANT
  ///  ### For -> HBRelation
  ///
  dynamic getFieldValue(T value, String fieldName) => null;

  ///
  /// ### HBRelation
  ///
  ///You Need To Emplement -> `getFieldValue` Method
  ///
  List<HBRelation> relations() => [];
}

/// ### ✔️ Conclusion
///
/// `none` → `let developer handle`
///
/// `cascade` → `remove/update children together`
///
/// `restrict` → `prevent delete/update if children exist`
///
///
enum RelationAction {
  ///
  /// `none` → `let developer handle`
  ///
  none,

  ///
  /// `cascade` → `remove/update children together`
  ///
  cascade,

  ///
  /// `restrict` → `prevent delete/update if children exist`
  ///
  restrict,
}

class HBRelation {
  ///
  /// Child Box
  ///
  final Type targetType;

  ///
  /// child field (userId)
  ///
  final String foreignKey;

  final RelationAction onDelete;

  HBRelation({
    required this.targetType,
    required this.foreignKey,
    this.onDelete = RelationAction.none,
  });
}
