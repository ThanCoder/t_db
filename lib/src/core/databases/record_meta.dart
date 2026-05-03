import 'dart:io';
import 'dart:typed_data';

import 'package:t_db/src/core/utils/encoder.dart';

///
/// ### Header (17 Bytes) : [Flag(1),uniqueFieldId(4),id(8),jsonDataLength(4)]
///
const int recordMetaHeaderSize = 17;

class RecordMeta {
  final int id;
  final int uniqueFieldId;
  final int offset;
  final int dataSize;
  final int recordTotalSize;

  const RecordMeta({
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

  static Future<RecordMeta> readFromIndexDB(RandomAccessFile raf) async {
    final headerOffset = (await raf.position() - 1);

    final uniqueFieldId = bytesToInt4(await raf.read(4));
    final id = bytesToInt8(await raf.read(8));
    final dataSize = bytesToInt4(await raf.read(4));

    final current = await raf.position();
    await raf.setPosition(current + dataSize);

    return RecordMeta(
      id: id,
      uniqueFieldId: uniqueFieldId,
      offset: headerOffset,
      dataSize: dataSize,
      recordTotalSize: recordMetaHeaderSize + dataSize,
    );
  }

  static Future<RecordMeta> read(
    RandomAccessFile raf, {
    required int headerOffset,
  }) async {
    await raf.setPosition(headerOffset);

    // flag
    final _ = await raf.readByte();

    final uniqueFieldId = bytesToInt4(await raf.read(4));
    final id = bytesToInt8(await raf.read(8));
    final dataSize = bytesToInt4(await raf.read(4));

    final current = await raf.position();
    await raf.setPosition(current + dataSize);

    return RecordMeta(
      id: id,
      uniqueFieldId: uniqueFieldId,
      offset: headerOffset,
      dataSize: dataSize,
      recordTotalSize: recordMetaHeaderSize + dataSize,
    );
  }
}
