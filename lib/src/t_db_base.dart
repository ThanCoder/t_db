import 'dart:async';
import 'dart:io';

import 'package:t_db/src/core/databases/index_db.dart';
import 'package:t_db/src/core/rw/binary_rw.dart';
import 'package:t_db/src/core/type/db_config.dart';
import 'package:t_db/src/core/databases/td_adapter.dart';
import 'package:t_db/src/core/databases/td_box.dart';

class TDB {
  ///
  /// ## Singleton
  ///
  static TDB? _instance;
  static TDB getInstance() {
    _instance ??= TDB();
    return _instance!;
  }

  final _indexDB = IndexDB();
  final Map<Type, TDAdapter> _adapter = {};
  final Map<Type, TDBox> _box = {};

  ///
  /// ## Open Database
  ///
  Future<void> open(String dbPath, {DBConfig? config}) async {
    _indexDB.setConfig(
      dbFile: File(dbPath),
      config: config ?? DBConfig.getDefault(),
    );

    await _indexDB.init();
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
    if (_indexDB.lockFile.existsSync()) {
      await _indexDB.lockFile.delete();
    }
    await open(_indexDB.dbFile.path);
  }

  /// --- Adapter ---

  ///
  /// ### Set Adapter`<T>`
  ///
  ///Usage //`db.setAdapter<User>(UserAdapter());`
  ///
  void setAdapter<T>(TDAdapter<T> adapter) {
    _adapter[T] = adapter;
    _box[T] = TDBox<T>(indexDB: _indexDB,adapter: adapter);
    _checkAdapterUinqueId<T>(adapter);
  }

  ///
  /// ### Set Adapter`<T>`
  ///
  ///Usage //`db.setAdapter<User>(UserAdapter());`
  ///
  void setAdapterNotExists<T>(TDAdapter<T> adapter) {
    final ids = _adapter.values.map((e) => e.getUniqueFieldId()).toList();
    //တူနေရင် မထည့်တော့ဘူး
    if (ids.contains(adapter.getUniqueFieldId())) return;

    _adapter[T] = adapter;
    _box[T] = TDBox<T>(indexDB: _indexDB,adapter: adapter);
    _checkAdapterUinqueId<T>(adapter);
  }

  ///
  /// ### Added -> All Adapter Clear
  ///
  void clearAdapter() {
    _adapter.clear();
    _box.clear();
  }


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
  /// ## Database Is Opened
  ///
  bool get isOpened {
    return _indexDB.isOpened;
  }

  ///
  /// ## Close Database
  ///
  Future<void> close() async {
    if (!isOpened) return;
    await _indexDB.close();
  }

  ///
  /// ### Check Data Record
  ///
  bool get isDataRecordCreatedExists {
    if (isOpened) {
      return _indexDB.dbFile.lengthSync() > BinaryRW.headerByteLength;
    }
    return false;
  }

  ///
  /// ### Get DB Header
  ///
  // Future<TDBHeader> getHeader() async {
  //   final raf = await dbFile.open();
  //   final (magic, version, type) = await BinaryRW.readHeader(raf);
  //   await raf.close();
  //   return TDBHeader(magic: magic, version: version, type: type);
  // }

  ///
  /// ### Database Added LastId
  ///
  int get getLastId => _indexDB.lastId;

  ///
  /// ### Database Deleted Count
  ///
  int get deletedCount => _indexDB.deletedCount;

  ///
  /// ### Database Deleted Size
  ///
  int get deletedSize => _indexDB.deletedSize;

  ///
  /// ### Database Unique Field List
  ///
  // List<int> get getUniqueFieldIdList => _indexDB.uniqueFieldIdList;

  ///
  /// --- Static ----
  ///
  /// ### Get Header From DB Path
  ///
  // static Future<TDBHeader?> getHeaderFromPath(String path) async {
  //   final file = File(path);
  //   if (!file.existsSync()) return null;
  //   final raf = await file.open();
  //   final (magic, version, type) = await BinaryRW.readHeader(raf);
  //   await raf.close();

  //   return TDBHeader(magic: magic, version: version, type: type);
  // }

  ///
  /// --- Event Listener ---
  ///
  // final List<TBEventListener> _listener = [];

  // void addListener(TBEventListener listener) {
  //   _listener.add(listener);
  // }

  // void removeListener(TBEventListener listener) {
  //   _listener.remove(listener);
  // }

  // void notify<T>(TBEventType event, int uniqueFieldId, int? id) {
  // stream
  //   _streamController.add(
  //     TBStreamEvent(uniqueFieldId: uniqueFieldId, type: event, id: id),
  //   );
  //   for (var listener in _listener) {
  //     listener.onTBDatabaseChanged(event, uniqueFieldId, id);
  //   }
  //   // send box notify
  //   final box = _box[T];
  //   if (box == null) return;
  //   box.notify(event, id);
  // }

  // stream
  //   final _streamController = StreamController<TBStreamEvent>.broadcast();
  //   Stream<TBStreamEvent> get stream => _streamController.stream;
}
