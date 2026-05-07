import 'dart:io';
import 'dart:typed_data';

import 'package:t_db/src/core/utils/encoder.dart';
import 'package:t_db/t_db.dart';

///
/// ### Header (17 Bytes) : [Flag(1),uniqueFieldId(4),id(8),jsonDataLength(4)]
///
const int recordMetaHeaderSize = 17;

class RecordMeta {
  final bool isActive;
  final int id;
  final int uniqueFieldId;
  final int offset;
  final int dataSize;
  final int recordTotalSize;

  const RecordMeta({
    required this.isActive,
    required this.id,
    required this.uniqueFieldId,
    required this.offset,
    required this.dataSize,
    required this.recordTotalSize,
  });

  Future<Uint8List> readData(RandomAccessFile raf) async {
    // go data offset
    await raf.setPosition(offset + recordMetaHeaderSize);

    final data = await raf.read(dataSize);

    return data;
  }

  @override
  String toString() {
    return 'ID: $id - Offset: $offset';
  }

  static Future<RecordMeta> read(RandomAccessFile raf) async {
    final offset = await raf.position();

    // flag
    final flag = await raf.readByte();

    if (flag == -1) {
      throw Exception('Read Header Error ');
    }

    final uniqueFieldId = bytesToInt4(await raf.read(4));
    final id = bytesToInt8(await raf.read(8));
    final dataSize = bytesToInt4(await raf.read(4));

    final current = await raf.position();
    await raf.setPosition(current + dataSize);

    return RecordMeta(
      isActive: DBFlag.isActive(flag),
      id: id,
      uniqueFieldId: uniqueFieldId,
      offset: offset,
      dataSize: dataSize,
      recordTotalSize: recordMetaHeaderSize + dataSize,
    );
  }
}
