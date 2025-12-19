import 'dart:async';
import 'dart:io';

import 'package:t_db/src/core/db_lock.dart';
import 'package:t_db/src/core/encoder.dart';
import 'package:t_db/src/core/rw/binary_rw.dart';
import 'package:t_db/src/core/rw/db_rw.dart';
import 'package:t_db/src/core/type/db_config.dart';
import 'package:t_db/src/core/type/db_meta.dart';
import 'package:t_db/src/core/type/db_record.dart';
import 'package:t_db/src/core/type/tb_event_listener.dart';
import 'package:t_db/src/core/type/td_adapter.dart';
import 'package:t_db/src/core/type/td_box.dart';
import 'package:t_db/src/core/type/tdb_header.dart';

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
  final Map<Type, TDAdapter> _adapter = {};
  final Map<Type, TDBox> _box = {};
  final Map<Type, List<HBRelation>> _cascadeRules = {};

  ///
  /// ## Open Database
  ///
  Future<void> open(String dbPath, {DBConfig? config}) async {
    await close();

    dbFile = File(dbPath);
    _config = config ?? DBConfig.getDefault();

    _dbLock = DBLock(
      dbFile: dbFile,
      lockFile: File('$dbPath.lock'),
      saveLocalLockFile: _config.saveLocalDBLock,
    );
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
  /// ## Change Database Path
  ///
  Future<void> changePath(String dbPath) async {
    await close();
    await open(dbPath);
  }

  ///
  /// ## Restart Database Path
  ///
  /// Reset DB Class
  ///
  Future<void> restart() async {
    await close();
    if (_dbLock.lockFile.existsSync()) {
      await _dbLock.lockFile.delete();
    }
    await open(dbFile.path);
  }

  /// --- Adapter ---

  ///
  /// ### Set Adapter`<T>`
  ///
  ///Usage //`db.setAdapter<User>(UserAdapter());`
  ///
  void setAdapter<T>(TDAdapter<T> adapter) {
    _adapter[T] = adapter;
    _box[T] = TDBox<T>(this);
    // cascade rules
    _cascadeRules[T] = adapter.relations();
    _checkAdapterUinqueId<T>(adapter);
  }

  ///
  /// ### Get Adapter`<T>`
  ///
  TDAdapter<T> _getAdapter<T>() {
    final adapter = _adapter[T];
    if (adapter == null) {
      throw Exception('No Adapter Registerd for type `$T`');
    }
    return adapter as TDAdapter<T>;
  }

  ///
  /// ## Get CascadeRules List
  ///
  List<HBRelation> _getCascadeRules<T>() => _cascadeRules[T] ?? [];

  ///
  /// ### Get Box`<T>`
  ///
  /// Usage -> db.getBox`<T>`()
  ///
  TDBox<T> getBox<T>() {
    final box = _box[T];
    if (box == null) {
      throw Exception('Box<$T> not found. Did you setAdapter<$T>()?');
    }
    return box as TDBox<T>;
  }

  ///
  /// check adapter unique id
  ///
  void _checkAdapterUinqueId<T>(TDAdapter<T> adapter) {
    final ids = <int>{};
    for (var map in _adapter.values) {
      final id = map.getUniqueFieldId();
      if (ids.contains(id)) {
        throw Exception(
          "Duplicate Adapter: `${adapter.runtimeType}` Unique id detected: `$id`",
        );
      }
      ids.add(id);
    }
  }

  ///
  /// --- Record ---
  ///

  ///
  /// ### Get All`<T>`
  ///
  Future<List<T>> getAll<T>() async {
    final adapter = _getAdapter<T>();
    final filtered = (await getAllRecord())
        .where((e) => e.uniqueFieldId == adapter.getUniqueFieldId())
        .toList();
    List<T> list = [];
    final raf = await dbFile.open();

    for (var record in filtered) {
      await raf.setPosition(record.offset);
      final map = decodeRecordCompress4(await raf.read(record.length));
      list.add(adapter.fromMap(map));
    }
    return list;
  }

  ///
  /// ### Get All Stream`<T>`
  ///
  Stream<T> getAllStream<T>() async* {
    final adapter = _getAdapter<T>();
    final filtered = (await getAllRecord())
        .where((e) => e.uniqueFieldId == adapter.getUniqueFieldId())
        .toList();
    final raf = await dbFile.open();

    for (var record in filtered) {
      await raf.setPosition(record.offset);
      final map = decodeRecordCompress4(await raf.read(record.length));
      yield adapter.fromMap(map);
    }
  }

  /// --- Query ---

  ///
  /// ### Query All`<T>`
  ///
  Future<List<T>> queryAll<T>(bool Function(T value) test) async {
    final adapter = _getAdapter<T>();
    final filtered = (await getAllRecord())
        .where((e) => e.uniqueFieldId == adapter.getUniqueFieldId())
        .toList();
    List<T> list = [];
    final raf = await dbFile.open();

    for (var record in filtered) {
      await raf.setPosition(record.offset);
      final map = decodeRecordCompress4(await raf.read(record.length));
      final data = adapter.fromMap(map);
      if (!test(data)) continue;
      list.add(data);
    }
    return list;
  }

  ///
  /// ### query All Stream`<T>`
  ///
  Stream<T> queryAllStream<T>(bool Function(T value) test) async* {
    final adapter = _getAdapter<T>();
    final filtered = (await getAllRecord())
        .where((e) => e.uniqueFieldId == adapter.getUniqueFieldId())
        .toList();
    final raf = await dbFile.open();

    for (var record in filtered) {
      await raf.setPosition(record.offset);
      final map = decodeRecordCompress4(await raf.read(record.length));
      final data = adapter.fromMap(map);
      if (test(data)) {
        yield data;
      }
    }
  }

  ///
  /// ## Get Record By Id
  ///
  Future<T?> getById<T>(int id) async {
    final adapter = _getAdapter<T>();

    final raf = await dbFile.open();

    final index = _dbLock.recordList.indexWhere((e) => e.id == id);
    if (index == -1) return null;
    final record = _dbLock.recordList[index];
    // set offset
    await raf.setPosition(record.offset);
    final map = decodeRecordCompress4(await raf.read(record.length));
    // close
    await raf.close();

    return adapter.fromMap(map);
  }

  ///
  /// ## Get Record By Id
  ///
  Future<T?> getOne<T>(bool Function(T value) test) async {
    await for (var value in getAllStream<T>()) {
      if (test(value)) return value;
    }
    return null;
    // return adapter.fromMap(map);
  }

  ///
  /// ## Add Record
  ///
  ///Return Added `autoId`
  ///
  Future<int> add<T>(T value, {bool saveLock = true}) async {
    final adapter = _getAdapter<T>();
    final map = adapter.toMap(value);

    _dbLock.lastId++;
    final newId = _dbLock.lastId;
    map['autoId'] = newId;
    final (offset, length) = await BinaryRW.writeRecord(
      _raf,
      map: map,
      uniqueFieldId: adapter.getUniqueFieldId(),
      newId: newId,
    );
    _dbLock.recordList.add(
      DBRecord(
        id: newId,
        uniqueFieldId: adapter.getUniqueFieldId(),
        offset: offset,
        length: length,
      ),
    );
    if (saveLock) {
      await _dbLock.save();
    }
    // notify
    notify<T>(TBEventType.add, adapter.getUniqueFieldId(), newId);
    return newId;
  }

  ///
  /// ## Add Record
  ///
  ///Return Added `autoId`
  ///
  Future<void> addAll<T>(List<T> values) async {
    final adapter = _getAdapter<T>();

    for (var value in values) {
      final map = adapter.toMap(value);

      _dbLock.lastId++;
      final newId = _dbLock.lastId;
      map['autoId'] = newId;

      final (offset, length) = await BinaryRW.writeRecord(
        _raf,
        map: map,
        uniqueFieldId: adapter.getUniqueFieldId(),
        newId: newId,
      );
      _dbLock.recordList.add(
        DBRecord(
          id: newId,
          uniqueFieldId: adapter.getUniqueFieldId(),
          offset: offset,
          length: length,
        ),
      );
    }

    // save lock
    await _dbLock.save();
    // notify
    notify<T>(TBEventType.add, adapter.getUniqueFieldId(), null);
  }

  ///
  /// ### Deleted Record
  ///
  Future<bool> deleteById<T>(int id, {bool saveLock = true}) async {
    final adapter = _getAdapter<T>();
    // 🔥 relations first
    await _deleteRelation<T>(id);

    final isDeleted = await DBRW.deleteById(id, raf: _raf, dbLock: _dbLock);

    // relation

    // save
    if (saveLock) {
      await _dbLock.save();
    }
    // notify
    notify<T>(TBEventType.delete, adapter.getUniqueFieldId(), id);
    // auto compack
    await _maybeCompact();
    return isDeleted;
  }

  ///
  /// ### Deleted Record
  ///
  Future<bool> delete<T>(T value, {bool saveLock = true}) async {
    final adapter = _getAdapter<T>();

    // 🔥 relations first
    await _deleteRelation<T>(adapter.getId(value));

    final isDeleted = await DBRW.deleteById(
      adapter.getId(value),
      raf: _raf,
      dbLock: _dbLock,
    );
    // relation

    // save
    if (saveLock) {
      await _dbLock.save();
    }
    // notify
    notify<T>(
      TBEventType.delete,
      adapter.getUniqueFieldId(),
      adapter.getId(value),
    );
    // auto compack
    await _maybeCompact();
    return isDeleted;
  }

  ///
  /// ### Deleted All Record with `List<ID>`
  ///
  Future<bool> deleteAll<T>(List<int> idList) async {
    final adapter = _getAdapter<T>();
    for (var id in idList) {
      // 🔥 relations first
      await _deleteRelation<T>(id);

      final index = _dbLock.recordList.indexWhere((e) => e.id == id);
      if (index == -1) return false;
      final record = _dbLock.recordList[index];

      final dataOffset = record.offset;
      final endPos = await _raf.position();
      // go to flag
      await _raf.setPosition(
        dataOffset - 4 - 8 - 4 - 1,
      ); // 4=length,8=id,4=uniqueFieldId,1=flag
      await _raf.writeByte(DBMeta.Flag_Delete);

      // go to end
      await _raf.setPosition(endPos);

      // change memory
      _dbLock.recordList.removeAt(index);
      _dbLock.deletedCount++;
      _dbLock.deletedSize += record.length;
    }

    // save
    await _dbLock.save();
    // notify
    notify<T>(TBEventType.delete, adapter.getUniqueFieldId(), null);
    // auto compack
    await _maybeCompact();
    return true;
  }

  ///
  /// ### Deleted All Record
  ///
  Future<bool> deleteAllRecord<T>() async {
    final adapter = _getAdapter<T>();

    for (var record in _dbLock.recordList) {
      if (record.uniqueFieldId != adapter.getUniqueFieldId()) continue;

      final dataOffset = record.offset;
      final endPos = await _raf.position();
      // go to flag
      await _raf.setPosition(
        dataOffset - 4 - 8 - 4 - 1,
      ); // 4=length,8=id,4=uniqueFieldId,1=flag
      await _raf.writeByte(DBMeta.Flag_Delete);

      // go to end
      await _raf.setPosition(endPos);

      // change memory
      _dbLock.deletedCount++;
      _dbLock.deletedSize += record.length;
    }
    // clear record list
    _dbLock.recordList.clear();
    // save
    await _dbLock.save();
    // notify
    notify<T>(TBEventType.delete, adapter.getUniqueFieldId(), null);
    // auto compack
    await _maybeCompact();
    return true;
  }

  ///
  /// ### Update Record
  ///
  Future<bool> updateById<T>(int id, T value, {bool saveLock = true}) async {
    final adapter = _getAdapter<T>();
    final map = adapter.toMap(value);

    final index = _dbLock.recordList.indexWhere((e) => e.id == id);
    if (index == -1) return false;
    final record = _dbLock.recordList[index];

    final dataOffset = record.offset;
    final endPos = await _raf.position();
    // go to flag
    await _raf.setPosition(
      dataOffset - 4 - 8 - 4 - 1,
    ); // 4=length,8=id,4=uniqueFieldId,1=flag
    await _raf.writeByte(DBMeta.Flag_Delete);

    // go to end
    await _raf.setPosition(endPos);

    // change memory
    _dbLock.recordList.removeAt(index);
    _dbLock.deletedCount++;
    _dbLock.deletedSize += record.length;

    // update
    map['autoId'] = id;
    final (offset, length) = await BinaryRW.writeRecord(
      _raf,
      map: map,
      uniqueFieldId: 1,
      newId: id,
    );
    _dbLock.recordList.add(
      DBRecord(
        id: id,
        uniqueFieldId: adapter.getUniqueFieldId(),
        offset: offset,
        length: length,
      ),
    );
    // save
    if (saveLock) {
      await _dbLock.save();
    }
    // notify
    notify<T>(TBEventType.update, adapter.getUniqueFieldId(), id);
    // auto compack
    await _maybeCompact();
    return true;
  }

  ///
  /// ### All Record
  ///
  Future<List<DBRecord>> getAllRecord() async {
    return _dbLock.recordList;
  }

  ///
  /// --- Relation ---
  ///

  Future<void> _deleteRelation<T>(int deleteId) async {
    final rules = _getCascadeRules<T>();
    if (rules.isEmpty) return;

    for (var rule in rules) {
      final type = rule.targetType;
      final box = _box[type]!;
      final adapter = _adapter[type]!;

      final childList = await box.queryAll((value) {
        final fieldValue = adapter.getFieldValue(value, rule.foreignKey);
        return deleteId == fieldValue;
      });
      if (childList.isEmpty) continue;

      switch (rule.onDelete) {
        case RelationAction.none:
          // ❌ do nothing
          break;
        case RelationAction.restrict:
          // 🚫 block parent delete
          throw Exception('Delete restricted: $T has related $type');
        case RelationAction.cascade:
          // 🔥 cascade delete children
          for (final child in childList) {
            await box.deleteById(adapter.getId(child));
          }
          break;
      }
    }
  }

  ///
  /// ### Database Auto Clean Up
  ///
  Future<void> _maybeCompact() async {
    // auto compact
    if (!_config.autoCompact) return;

    // Small DB → compact only when deletion accumulates
    int minDeletedCount = _config.minDeletedCount; // entries
    int minDeletedSize = _config.minDeletedSize; // bytes

    // No need to compact if DB cleaned recently
    if (_dbLock.deletedCount < minDeletedCount &&
        _dbLock.deletedSize < minDeletedSize) {
      return;
    }

    // Run compaction
    await compact(saveBackup: _config.saveBackupDBCompact);
  }

  ///
  /// ### Database Clean Up Or Rebuild
  ///
  Future<void> compact({bool saveBackup = true}) async {
    await BinaryRW.compact(dbFile: dbFile, saveBackup: saveBackup);
    await _dbLock.rebuild();
  }

  ///
  /// ## Database Is Opened
  ///
  bool get isOpened {
    try {
      _raf;
      return true;
    } catch (e) {
      return false;
    }
  }

  ///
  /// ## Close Database
  ///
  Future<void> close() async {
    if (!isOpened) return;
    await _raf.close();
  }

  ///
  /// ### Check Data Record
  ///
  bool get isDataRecordCreatedExists {
    if (isOpened) {
      return _raf.lengthSync() > BinaryRW.headerByteLength;
    }
    return false;
  }

  ///
  /// ### Get DB Header
  ///
  Future<TDBHeader> getHeader() async {
    final raf = await dbFile.open();
    final (magic, version, type) = await BinaryRW.readHeader(raf);
    await raf.close();
    return TDBHeader(magic: magic, version: version, type: type);
  }

  ///
  /// ### Database Added LastId
  ///
  int get getLastId => _dbLock.lastId;

  ///
  /// ### Database Deleted Count
  ///
  int get getDeletedCount => _dbLock.deletedCount;

  ///
  /// ### Database Deleted Size
  ///
  int get getDeletedSize => _dbLock.deletedSize;

  ///
  /// ### Database Unique Field List
  ///
  List<int> get getUniqueFieldIdList => _dbLock.uniqueFieldIdList;

  ///
  /// --- Static ----
  ///
  /// ### Get Header From DB Path
  ///
  static Future<TDBHeader?> getHeaderFromPath(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    final raf = await file.open();
    final (magic, version, type) = await BinaryRW.readHeader(raf);
    await raf.close();

    return TDBHeader(magic: magic, version: version, type: type);
  }

  ///
  /// --- Event Listener ---
  ///
  final List<TBEventListener> _listener = [];

  void addListener(TBEventListener listener) {
    _listener.add(listener);
  }

  void removeListener(TBEventListener listener) {
    _listener.remove(listener);
  }

  void notify<T>(TBEventType event, int uniqueFieldId, int? id) {
    // stream
    _streamController.add(
      TBStreamEvent(uniqueFieldId: uniqueFieldId, type: event, id: id),
    );
    for (var listener in _listener) {
      listener.onTBDatabaseChanged(event, uniqueFieldId, id);
    }
    // send box notify
    final box = _box[T];
    if (box == null) return;
    box.notify(event, id);
  }

  // stream
  final _streamController = StreamController<TBStreamEvent>.broadcast();
  Stream<TBStreamEvent> get stream => _streamController.stream;
}
