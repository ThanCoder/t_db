import 'dart:convert';
import 'dart:typed_data';

import 'package:t_db/src/utils/tdb_compressor.dart';

abstract class TDBAdapter<T> {
  int get adapterTypeId;
  int parentId(T value) => -1;
  int getId(T value);

  Map<String, dynamic> toMap(T value);
  T fromMap(Map<String, dynamic> map);

  // json convert
  String toJson(Map<String, dynamic> map) => jsonEncode(map);
  Map<String, dynamic> fromJson(String source) => jsonDecode(source);

  // compress
  Uint8List compress(String json) {
    return TDBCompressor.compress(json);
  }

  String decompress(Uint8List compressedBytes) {
    return TDBCompressor.decompress(compressedBytes);
  }
}
