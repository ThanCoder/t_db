import 'dart:io';
import 'dart:typed_data';

class DBMetaStore {
  final File file;
  int lastId = 0;
  final Map<int, int> index = {};

  DBMetaStore(String dbPath) : file = File('$dbPath.lock');

  /// Save metadata as binary file
  Future<void> save() async {
    final builder = BytesBuilder();

    // lastId (4 bytes)
    final lastIdBytes = ByteData(4)..setUint32(0, lastId, Endian.little);
    builder.add(lastIdBytes.buffer.asUint8List());

    // index count (4 bytes)
    final countBytes = ByteData(4)..setUint32(0, index.length, Endian.little);
    builder.add(countBytes.buffer.asUint8List());

    // index entries (id: 4 bytes, offset: 8 bytes)
    for (final entry in index.entries) {
      final idBytes = ByteData(4)..setUint32(0, entry.key, Endian.little);
      final offsetBytes = ByteData(8)..setInt64(0, entry.value, Endian.little);
      builder.add(idBytes.buffer.asUint8List());
      builder.add(offsetBytes.buffer.asUint8List());
    }

    await file.writeAsBytes(builder.toBytes(), flush: true);
  }

  /// Load metadata from binary file
  Future<void> load() async {
    if (!await file.exists()) return;

    final bytes = await file.readAsBytes();
    final reader = ByteData.sublistView(bytes);

    int offset = 0;

    // lastId
    if (offset + 4 > reader.lengthInBytes) return; // safety check
    lastId = reader.getUint32(offset, Endian.little);
    offset += 4;

    // index count
    if (offset + 4 > reader.lengthInBytes) return;
    final count = reader.getUint32(offset, Endian.little);
    offset += 4;

    // index entries
    index.clear();
    for (int i = 0; i < count; i++) {
      if (offset + 12 > reader.lengthInBytes) return; // 4+8 bytes per entry
      final id = reader.getUint32(offset, Endian.little);
      offset += 4;
      final dataOffset = reader.getInt64(offset, Endian.little);
      offset += 8;
      index[id] = dataOffset;
    }
  }
}
