import 'dart:async';
import 'dart:io';

import 'package:t_db/src/core/databases/index_db.dart';
import 'package:t_db/src/core/events/td_box_events.dart';
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

  /// --- Event Listener ---
  // stream
  final _boxStreamController = StreamController<TDBoxStreamEvent>.broadcast();
  Stream<TDBoxStreamEvent> get boxStream => _boxStreamController.stream;

  ///
  /// ## Open Database
  ///
  Future<void> open(String dbPath, {DBConfig? config}) async {
    if (isOpened) return;
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
  Future<void> restart({DBConfig? config}) async {
    await close();
    await open(_indexDB.dbFile.path, config: config);
  }

  /// --- Adapter ---

  ///
  /// ### Set Adapter`<T>`
  ///
  ///Usage //`db.setAdapter<User>(UserAdapter());`
  ///
  void setAdapter<T>(TDAdapter<T> adapter) {
    final ids = _adapter.values.map((e) => e.getUniqueFieldId()).toList();
    if (ids.contains(adapter.getUniqueFieldId())) {
      throw Exception(
        "Duplicate Adapter: `${adapter.runtimeType}` Unique id detected: `${adapter.getUniqueFieldId()}`",
      );
    }
    _adapter[T] = adapter;
    _box[T] = TDBox<T>(
      indexDB: _indexDB,
      adapter: adapter,
      streamController: _boxStreamController,
    );
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
    _box[T] = TDBox<T>(
      indexDB: _indexDB,
      adapter: adapter,
      streamController: _boxStreamController,
    );
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
  /// ### Manual Compact
  ///
  Future<void> compact() async {
    await _indexDB.compact();
  }

  // ---- Static ----- //
  ///
  /// ### Read Header
  ///
  /// Return (magic,version,type)
  ///
  static Future<(String, int, String)> readHeader(
    String dbPath, {
    String? requiredType,
    int? requiredVersion,
  }) async {
    final file = File(dbPath);
    if (!file.existsSync()) {
      throw Exception('DB File Not Found!');
    }
    final raf = await file.open(mode: FileMode.read);

    final (magic, version, type) = await BinaryRW.readHeader(raf);
    if (requiredType != null) {
      if (type != requiredType) {
        throw Exception(
          'Invalid DB Database `Type`: Excepted `$requiredType` Got `$type`',
        );
      }
    }
    if (requiredVersion != null) {
      if (version != requiredVersion) {
        throw Exception(
          'Invalid DB Database `Version`: Excepted `$requiredVersion` Got `$version`',
        );
      }
    }
    return (type, version, type);
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

  int get version => _indexDB.version;

  String get magic => _indexDB.magic;

  String get type => _indexDB.type;

  ///
  /// ### Database Added LastId
  ///
  int get lastId => _indexDB.lastId;

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
  List<int> get getUniqueFieldIdList =>
      _indexDB.records.values.map((e) => e.uniqueFieldId).toSet().toList();
}
