import 'dart:convert';
import 'dart:io';

import 'package:t_db/src/core/rw/binary_rw.dart';
import 'package:t_db/src/core/type/db_meta.dart';
import 'package:t_db/src/core/type/db_record.dart';

class DBLock {
  final File dbFile;
  final File lockFile;
  final bool saveLocalLockFile;
  List<DBRecord> recordList = [];
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
      final source = await lockFile.readAsString();
      final map = jsonDecode(source) as Map<String, dynamic>;
      _parse(map);
      return;
    }
    await _rebuild();
  }

  ///
  /// ### Save DB Lock File
  ///
  Future<void> save() async {
    if (!saveLocalLockFile) return;
    final map = {
      'recordList': recordList.map((e) => e.toMap()).toList(),
      'lastId': lastId,
      'deletedSize': deletedSize,
      'deletedCount': deletedCount,
    };
    final json = JsonEncoder.withIndent(' ').convert(map);
    await lockFile.writeAsString(json);
  }

  ///
  /// ### Parse Lock File Data
  ///
  Future<void> _parse(Map<String, dynamic> map) async {
    final list = map['recordList'] as List<dynamic>;
    recordList = list.map((map) => DBRecord.fromMap(map)).toList();
    lastId = map['lastId'];
    deletedSize = map['deletedSize'];
    deletedCount = map['deletedCount'];
  }

  ///
  /// ### Rebuild Lock File From Database
  ///
  Future<void> _rebuild() async {
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

      recordList.add(
        DBRecord(
          id: id,
          uniqueFieldId: uniqueFieldId,
          offset: dataOffset,
          length: length,
        ),
      );
    }
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
