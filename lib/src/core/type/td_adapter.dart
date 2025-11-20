abstract class TDAdapter<T> {
  int getUniqueFieldId();
  Map<String, dynamic> toMap(T value);
  T fromMap(Map<String, dynamic> map);
  int getId(T value);

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
enum RelationAction { none, cascade, restrict }

class HBRelation {
  ///
  /// Parent Box
  ///
  final Type parentClass;

  ///
  /// Child Box
  ///
  final Type childClass;

  ///
  /// `Child` → `Parent link field name`
  ///
  final String foreignField;
  final RelationAction onDelete;
  final RelationAction onUpdate;

  HBRelation({
    required this.parentClass,
    required this.childClass,
    required this.foreignField,
    this.onDelete = RelationAction.none,
    this.onUpdate = RelationAction.none,
  });
}
