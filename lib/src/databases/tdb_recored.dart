import 'dart:io';
import 'dart:typed_data';

import 'package:t_db/src/utils/byte_data_extensions.dart';

enum RecordStatus { active, deleted }

class TDBRecored {
  final int id;
  final int adapterTypeId;
  final int parentId;
  final Uint8List data;
  final RecordStatus status;

  const TDBRecored({
    required this.id,
    required this.adapterTypeId,
    required this.parentId,
    required this.data,
    this.status = RecordStatus.active,
  });

  /// Header Structure (Total 22 bytes):
  /// status(1) + adapterTypeId(1) + id(8) + parentId(8) + dataSize(4) = 22 bytes
  static int get headerSize => 22;

  ///
  /// Return `headerStartOffset`
  ///
  Future<int> write(RandomAccessFile raf) async {
    final currentOffset = await raf.position();

    final header = ByteData(headerSize);

    header.setInt1Byte(0, status.index); // Offset 0 (Size 1)
    header.setInt1Byte(1, adapterTypeId); // Offset 1 (Size 1)
    header.setInt8Bytes(2, id); // Offset 2 (Size 8) -> 2+8 = 10
    header.setInt8Bytes(10, parentId); // Offset 10 (Size 8) -> 10+8 = 18
    header.setInt4Bytes(18, data.length); // Offset 18 (Size 4) -> 18+4 = 22

    final builder = BytesBuilder(copy: false);
    builder.add(header.buffer.asUint8List());
    builder.add(data); // JSON bytes

    await raf.writeFrom(builder.takeBytes());

    return currentOffset;
  }

  /// Header Structure (Total 22 bytes):
  /// status(1) + adapterTypeId(1) + id(8) + parentId(8) + dataSize(4) = 22 bytes
  ///
  /// Return (meta,status)
  ///
  static Future<(RecordMeta, RecordStatus)> getMeta(
    RandomAccessFile raf,
    int headerStartOffset,
  ) async {
    await raf.setPosition(headerStartOffset);
    // 2. Header bytes (22 bytes) ကို ဖတ်မယ်
    final Uint8List bytes = await raf.read(22);

    // 3. Bytes အပြည့်အဝ ပါ/မပါ စစ်မယ် (File အဆုံးနား ရောက်နေရင် ၂၂ မပြည့်တာမျိုး ဖြစ်နိုင်လို့)
    if (bytes.length < 22) {
      throw Exception("Header incomplete at offset $headerStartOffset");
    }

    final header = ByteData.sublistView(bytes);
    // headerSize = 22
    final statusIndex = header.getInt1Byte(0); // 0
    final adapterTypeId = header.getInt1Byte(1); // 1
    final id = header.getInt8Bytes(2); // 2 to 9
    final parentId = header.getInt8Bytes(10); // 10 to 17
    final dataSize = header.getInt4Bytes(18); // 18 to 21

    return (
      RecordMeta(
        id: id,
        offset: headerStartOffset,
        parentId: parentId,
        adapterTypeId: adapterTypeId,
        dataSize: dataSize,
      ),
      RecordStatus.values[statusIndex],
    );
  }
}

class RecordMeta {
  final int id;
  final int offset; // Disk ပေါ်က နေရာ
  final int parentId; // Relation ရှာဖို့
  final int adapterTypeId; // အမျိုးအစား ခွဲဖို့
  final int dataSize;

  RecordMeta({
    required this.id,
    required this.offset,
    required this.parentId,
    required this.adapterTypeId,
    required this.dataSize,
  });

  Future<Uint8List> getData(RandomAccessFile raf) async {
    final dataStartPosition = offset + TDBRecored.headerSize;
    await raf.setPosition(dataStartPosition);
    final data = await raf.read(dataSize);
    return data;
  }

  Future<void> deleteMark(RandomAccessFile raf) async {
    final current = await raf.position();
    try {
      // go first header pos
      await raf.setPosition(offset);

      await raf.writeByte(RecordStatus.deleted.index);

      // // ၄။ ရေးပြီးကြောင်း သေချာအောင် flush လုပ်မယ် (Optional - speed လိုချင်ရင် loop အပြင်မှာလုပ်)
      // await raf.flush();
    } catch (e) {
      //go current pos
      await raf.setPosition(current);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offset': offset,
      'parentId': parentId,
      'adapterTypeId': adapterTypeId,
      'dataSize': dataSize,
    };
  }

  factory RecordMeta.fromJson(Map<String, dynamic> json) {
    return RecordMeta(
      id: json['id'],
      offset: json['offset'],
      parentId: json['parentId'],
      adapterTypeId: json['adapterTypeId'],
      dataSize: json['dataSize'],
    );
  }

  RecordMeta copyWith({
    int? id,
    int? offset,
    int? parentId,
    int? adapterTypeId,
    int? dataSize,
  }) {
    return RecordMeta(
      id: id ?? this.id,
      offset: offset ?? this.offset,
      parentId: parentId ?? this.parentId,
      adapterTypeId: adapterTypeId ?? this.adapterTypeId,
      dataSize: dataSize ?? this.dataSize,
    );
  }
}

// // Main Index: ID သိတာနဲ့ အကုန်သိမယ်
// Map<int, RecordMeta> masterIndex = {};
