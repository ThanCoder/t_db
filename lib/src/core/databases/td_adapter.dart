import 'dart:convert';
import 'dart:typed_data';

import 'package:t_db/src/core/utils/encoder.dart';

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

  String toJson(T value) => jsonEncode(toMap(value));
  Map<String, dynamic> fromJson(String source) => jsonDecode(source);

  // compressor
  Uint8List encodeRecord(String jsonData) =>
      encodeRecordCompress4Json(jsonData);

  String decodeRecord(Uint8List jsonDataBytes) =>
      decodeRecordCompress4Json(jsonDataBytes);
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
