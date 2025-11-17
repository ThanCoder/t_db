import 'dart:io';

import 'package:t_db/src/core/db_lock.dart';
import 'package:t_db/src/core/rw/binary_rw.dart';
import 'package:t_db/src/core/type/db_config.dart';
import 'package:t_db/src/core/type/db_record.dart';

class TDB {
  ///
  /// ## Singleton
  ///
  static TDB? _instance;
  static TDB getInstance() {
    _instance ??= TDB();
    return _instance!;
  }

  late File dbFile;
  late RandomAccessFile _raf;
  late DBLock _dbLock;
  late DBConfig _config;

  ///
  /// ## Open Database
  ///
  Future<void> open(String dbPath, {DBConfig? config}) async {
    _config = config ?? DBConfig.getDefault();

    dbFile = File(dbPath);
    _dbLock = DBLock(dbFile: dbFile, lockFile: File('$dbPath.lock'));
    if (!dbFile.existsSync()) {
      final raf = await dbFile.open(mode: FileMode.write);
      await BinaryRW.writeHeader(
        raf,
        version: _config.dbVersion,
        type: _config.dbType,
      );
      await raf.close();
    }
    _raf = await dbFile.open(mode: FileMode.writeOnlyAppend);
    await _dbLock.load();
  }

  ///
  /// ## Add Database
  ///
  ///Return Added `autoId`
  ///
  Future<int> add(Map<String, dynamic> map) async {
    _dbLock.lastId++;
    final newId = _dbLock.lastId;
    final res = await BinaryRW.writeRecord(
      _raf,
      map: map,
      uniqueFieldId: 1,
      newId: newId,
    );
    _dbLock.recordList.add(
      DBRecord(id: newId, uniqueFieldId: 1, offset: res.$1, length: res.$2),
    );
    return newId;
  }

  Future<List<DBRecord>> getAll() async {
    return _dbLock.recordList;
  }

  ///
  /// ## Close Database
  ///
  Future<void> close() async => await _raf.close();
}
