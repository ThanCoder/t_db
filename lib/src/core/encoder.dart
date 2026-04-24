import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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

Uint8List intToBytes4(int value) {
  final buff = ByteData(4)..setInt32(0, value);
  return buff.buffer.asUint8List();
}

int bytesToInt4(Uint8List bytes) {
  final buffer = ByteData.sublistView(bytes);
  return buffer.getInt32(0);
}

Uint8List intToBytes8(int value) {
  final buff = ByteData(8)..setInt64(0, value);
  return buff.buffer.asUint8List();
}

int bytesToInt8(Uint8List bytes) {
  final buffer = ByteData.sublistView(bytes);
  return buffer.getInt64(0);
}

// zlib
Uint8List encodeRecordCompress4(Map<String, dynamic> data) {
  final jsonBytes = utf8.encode(jsonEncode(data));
  final compressed = ZLibEncoder().convert(jsonBytes);
  final lengthBytes = ByteData(4)..setUint32(0, compressed.length, Endian.big);
  return Uint8List.fromList([
    ...lengthBytes.buffer.asUint8List(),
    ...compressed,
  ]);
}

Map<String, dynamic> decodeRecordCompress4(Uint8List bytes) {
  final view = ByteData.sublistView(bytes);
  final length = view.getUint32(0, Endian.big);
  final compressed = bytes.sublist(4, 4 + length);
  final decompressed = ZLibDecoder().convert(compressed);
  final jsonStr = utf8.decode(decompressed);
  return jsonDecode(jsonStr);
}
