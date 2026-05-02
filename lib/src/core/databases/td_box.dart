import 'dart:async';

import 'package:t_db/src/core/databases/index_db.dart';
import 'package:t_db/t_db.dart';

class TDBox<T> {
  late final IndexDB _indexDB;
  late final TDAdapter<T> _adapter;
  TDBox({required IndexDB indexDB, required TDAdapter<T> adapter})
    : _indexDB = indexDB,
      _adapter = adapter;
  
  Future<List<T>> getAll() async {
    final uniqueFieldId = _adapter.getUniqueFieldId();
    final list = <T>[];
    for (var meta in _indexDB.records) {
      // skip
      if (meta.uniqueFieldId != uniqueFieldId) continue;

      final jsonDataBytes = await meta.readData(_indexDB.readRaf);
      final map = _adapter.fromJson(_adapter.decodeRecord(jsonDataBytes));
      list.add(_adapter.fromMap(map));
      // print(map);
    }
    return list;
  }

  // Future<T?> getById(int id) async {
  //   return await _db.getById<T>(id);
  // }

  // Future<T?> getOne(bool Function(T value) test) async {
  //   return await _db.getOne<T>(test);
  // }

  // Future<List<T>> queryAll(bool Function(T value) test) async {
  //   return await _db.queryAll<T>(test);
  // }

  // Stream<T> getAllStream() {
  //   return _db.getAllStream<T>();
  // }

  // Stream<T> queryAllStream(bool Function(T value) test) {
  //   return _db.queryAllStream<T>(test);
  // }

  // Future<int> add(T value) async {
  //   final newId = await _db.add<T>(value);
  //   return newId;
  // }

  // Future<void> addAll(List<T> values) async {
  //   await _db.addAll<T>(values);
  // }

  // Future<bool> deleteById(int id) async {
  //   return await _db.deleteById<T>(id);
  // }

  // Future<bool> delete(T value) async {
  //   return await _db.delete<T>(value);
  // }

  // Future<bool> deleteAll(List<int> idList) async {
  //   return await _db.deleteAll<T>(idList);
  // }

  // Future<bool> deleteAllRecord() async {
  //   return await _db.deleteAllRecord<T>();
  // }

  // Future<bool> updateById(int id, T value) async {
  //   final isUpdated = await _db.updateById<T>(id, value);
  //   return isUpdated;
  // }

  /// --- Event Listener ---

  final List<TBoxEventListener> _listener = [];

  void addListener(TBoxEventListener listener) {
    _listener.add(listener);
  }

  void removeListener(TBoxEventListener listener) {
    _listener.remove(listener);
  }

  void notify(TBEventType event, int? id) {
    // stream
    _streamController.add(TDBoxStreamEvent(type: event, id: id));

    for (var listener in _listener) {
      listener.onTBoxDatabaseChanged(event, id);
    }
  }

  // stream
  final _streamController = StreamController<TDBoxStreamEvent>.broadcast();
  Stream<TDBoxStreamEvent> get stream => _streamController.stream;
}

class TDBoxStreamEvent {
  final TBEventType type;
  final int? id;
  TDBoxStreamEvent({required this.type, this.id});
}
