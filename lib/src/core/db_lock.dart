import 'dart:io';

import 'package:t_db/src/core/encoder.dart';
import 'package:t_db/src/core/rw/binary_rw.dart';
import 'package:t_db/src/core/type/db_meta.dart';
import 'package:t_db/src/core/type/db_record.dart';

class DBLock {
  final File dbFile;
  final File lockFile;
  final bool saveLocalLockFile;
  List<DBRecord> recordList = [];
  List<int> uniqueFieldIdList = [];
  int lastId = 0;
  int deletedSize = 0;
  int deletedCount = 0;

  DBLock({
    required this.dbFile,
    required this.lockFile,
    this.saveLocalLockFile = true,
  });

  Future<void> load() async {
    if (lockFile.existsSync() && saveLocalLockFile) {
      // load
      // final source = await lockFile.readAsString();
      // final map = jsonDecode(source) as Map<String, dynamic>;
      final raf = await lockFile.open(mode: FileMode.read);
      final length = bytesToInt4(await raf.read(4));
      final map = decodeRecord(await raf.read(length));
      await _parse(map);
      await raf.close();
      return;
    }
    await rebuild();
  }

  ///
  /// ### Save DB Lock File
  ///
  Future<void> save() async {
    if (!saveLocalLockFile) return;
    final map = {
      'lastId': lastId,
      'deletedSize': deletedSize,
      'deletedCount': deletedCount,
      'uniqueFieldIdList': uniqueFieldIdList,
      'recordList': recordList.map((e) => e.toMap()).toList(),
    };
    // final json = JsonEncoder.withIndent(' ').convert(map);
    // await lockFile.writeAsString(json);
    final raf = await lockFile.open(mode: FileMode.write);
    final mapBytes = encodeRecord(map);
    await raf.writeFrom(intToBytes4(mapBytes.length));
    await raf.writeFrom(mapBytes);
    await raf.close();
  }

  ///
  /// ### Parse Lock File Data
  ///
  Future<void> _parse(Map<String, dynamic> map) async {
    final list = map['recordList'] as List<dynamic>;
    final idList = map['uniqueFieldIdList'] as List<dynamic>;
    lastId = map['lastId'];
    deletedSize = map['deletedSize'];
    deletedCount = map['deletedCount'];
    uniqueFieldIdList = List<int>.from(idList);
    recordList = list.map((map) => DBRecord.fromMap(map)).toList();

    await Future.delayed(Duration.zero);
  }

  ///
  /// ### Rebuild Lock File From Database
  ///
  Future<void> rebuild() async {
    deletedCount = 0;
    deletedSize = 0;
    recordList.clear();
    uniqueFieldIdList.clear();
    List<int> fieldList = [];

    final raf = await dbFile.open();
    await BinaryRW.readHeader(raf);

    while (true) {
      final flag = await raf.readByte();
      if (flag == -1) break; //EOF

      final (uniqueFieldId, id, length, dataOffset, _) =
          await BinaryRW.readRecord(raf, skipData: true);
      // is deleted mark
      if (DBMeta.isDeleted(flag)) {
        deletedCount++;
        deletedSize += length;
        continue;
      }
      fieldList.add(uniqueFieldId);

      recordList.add(
        DBRecord(
          id: id,
          uniqueFieldId: uniqueFieldId,
          offset: dataOffset,
          length: length,
        ),
      );
    }
    uniqueFieldIdList.addAll(fieldList.toSet().toList());
    // last id
    lastId = recordList.isEmpty
        ? 0
        : recordList
              .map((e) => e.id)
              .reduce((value, element) => value > element ? value : element);
    await raf.close();
    // save lock
    await save();
  }
}
