import 'dart:convert';
import 'dart:typed_data';

Uint8List encodeRecord(Map<String, dynamic> data) {
  final jsonStr = jsonEncode(data);
  final bytes = utf8.encode(jsonStr);
  final length = bytes.length;
  final buffer = BytesBuilder();
  buffer.addByte((length >> 24) & 0xFF);
  buffer.addByte((length >> 16) & 0xFF);
  buffer.addByte((length >> 8) & 0xFF);
  buffer.addByte(length & 0xFF);
  buffer.add(bytes);
  return buffer.toBytes();
}

Map<String, dynamic> decodeRecord(Uint8List bytes) {
  final length = ByteData.sublistView(bytes).getUint32(0);
  final jsonStr = utf8.decode(bytes.sublist(4, 4 + length));
  return jsonDecode(jsonStr);
}
