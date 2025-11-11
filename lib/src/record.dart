import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// Uint8List encodeRecord(Map<String, dynamic> data) {
//   final jsonStr = jsonEncode(data);
//   final bytes = utf8.encode(jsonStr);
//   final length = bytes.length;
//   final buffer = BytesBuilder();
//   buffer.addByte((length >> 24) & 0xFF);
//   buffer.addByte((length >> 16) & 0xFF);
//   buffer.addByte((length >> 8) & 0xFF);
//   buffer.addByte(length & 0xFF);
//   buffer.add(bytes);
//   return buffer.toBytes();
// }

Uint8List encodeRecord(Map<String, dynamic> data) {
  final jsonBytes = utf8.encode(jsonEncode(data));
  final lengthBytes = ByteData(4)..setUint32(0, jsonBytes.length, Endian.big);
  return Uint8List.fromList([
    ...lengthBytes.buffer.asUint8List(),
    ...jsonBytes,
  ]);
}

Map<String, dynamic> decodeRecord(Uint8List bytes) {
  final length = ByteData.sublistView(bytes).getUint32(0);
  final jsonStr = utf8.decode(bytes.sublist(4, 4 + length));
  return jsonDecode(jsonStr);
}

// zlib
Uint8List encodeRecordCompress(Map<String, dynamic> data) {
  final jsonBytes = utf8.encode(jsonEncode(data));
  final compressed = ZLibEncoder().convert(jsonBytes);
  final lengthBytes = ByteData(4)..setUint32(0, compressed.length, Endian.big);
  return Uint8List.fromList([
    ...lengthBytes.buffer.asUint8List(),
    ...compressed,
  ]);
}

Map<String, dynamic> decodeRecordCompress(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  final length = view.getUint32(0, Endian.big);
  final compressed = bytes.sublist(4, 4 + length);
  final decompressed = ZLibDecoder().convert(compressed);
  final jsonStr = utf8.decode(decompressed);
  return jsonDecode(jsonStr);
}
