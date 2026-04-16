import 'dart:io';

import 'package:t_db/src/databases/indexed_db.dart';
import 'package:t_db/src/utils/tdb_box.dart';
import 'package:t_db/t_db.dart';

class TDB {
  // singleton
  static TDB? _instance;
  static TDB getInstance() {
    _instance ??= TDB();
    return _instance!;
  }

  final IndexedDB _indexedDB = IndexedDB();
  late File _dbFile;
  final Map<Type, TDBAdapter> _adapters = {};
  final Map<Type, TDBBox> _boxs = {};
  bool _isOpened = false;

  Future<void> open(String dbPath) async {
    _dbFile = File(dbPath);
    _indexedDB.setConfig(_dbFile);
    await _indexedDB.load();
    _isOpened = true;
  }

  ///
  /// ### Get Box`<T>`
  ///
  TDBBox<T> getBox<T>() {
    final box = _boxs[T];
    if (box == null) {
      throw Exception('No Adapter Registerd for type `$T`');
    }
    return box as TDBBox<T>;
  }

  ///
  /// ### Get Registered Adapter`<T>`
  ///
  TDBAdapter<T> getAdapter<T>() {
    final adapter = _adapters[T];
    if (adapter == null) {
      throw Exception('No Adapter Registerd for type `$T`');
    }
    return adapter as TDBAdapter<T>;
  }

  ///
  /// ### Set registerAdapterNotExists`<T>`
  ///
  /// Usage `db.registerAdapterNotExists<User>(UserAdapter());`
  ///
  Future<void> registerAdapterNotExists<T>(TDBAdapter<T> adapter) async {
    if (_adapters.containsKey(T)) return;

    final ids = _adapters.values.map((e) => e.adapterTypeId);
    if (ids.contains(adapter.adapterTypeId)) {
      throw Exception(
        """ Duplicate Adapter: `${adapter.runtimeType}` Unique id detected: `${adapter.adapterTypeId}`\n--- Please Changed ---
        @override
        int get adapterTypeId => `${adapter.adapterTypeId}`; <<<-----
        """,
      );
    }

    _adapters[T] = adapter;
    _boxs[T] = TDBBox<T>(db: this, indexedDB: _indexedDB, adapter: adapter);
  }

  ///
  /// ### Clear All Registered Adapter
  ///
  void clearAllAdapter() {
    _adapters.clear();
    _boxs.clear();
  }

  Future<void> close() async {
    if (!_isOpened) return;
    await _indexedDB.closeRaf();
  }

  int get version => _indexedDB.version;
  String get magic => _indexedDB.magic;
  int get deletedCount => _indexedDB.deletedCount;
  int get deletedSize => _indexedDB.deletedSize;
  int get lastIndex => _indexedDB.lastIndex;
}
