import 'dart:async';

import 'package:t_db/src/core/databases/index_db.dart';
import 'package:t_db/src/core/databases/td_box_interface.dart';
import 'package:t_db/t_db.dart';

class TDBox<T> extends TDBoxInterface<T> {
  late final IndexDB _indexDB;
  late final TDAdapter<T> _adapter;
  TDBox({required IndexDB indexDB, required TDAdapter<T> adapter})
    : _indexDB = indexDB,
      _adapter = adapter;

  // stream
  final _streamController = StreamController<TDBoxStreamEvent>.broadcast();
  Stream<TDBoxStreamEvent> get stream => _streamController.stream;

  @override
  Future<T?> add(T value) async {
    try {
      final id = _indexDB.getGeneratedId;
      // map['autoId'] = id;
      final map = _adapter.setAutoId(value, id);
      final newValue = _adapter.fromMap(map);
      final jsonData = _adapter.encodeRecord(_adapter.toJson(newValue));
      await _indexDB.addRecord(
        jsonData: jsonData,
        uniqueFieldId: _adapter.getUniqueFieldId(),
      );
      return newValue;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> addAll(List<T> values) {
    // TODO: implement addAll
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAll(List<int> idList) {
    // TODO: implement deleteAll
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteById(int id) {
    // TODO: implement deleteById
    throw UnimplementedError();
  }

  @override
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

  @override
  Stream<T> getAllStream() async* {
    final uniqueFieldId = _adapter.getUniqueFieldId();
    for (var meta in _indexDB.records) {
      // skip
      if (meta.uniqueFieldId != uniqueFieldId) continue;

      final jsonDataBytes = await meta.readData(_indexDB.readRaf);
      final map = _adapter.fromJson(_adapter.decodeRecord(jsonDataBytes));
      yield _adapter.fromMap(map);
    }
  }

  @override
  Future<T?> getOne(bool Function(T value) test) async {
    for (var item in await getAll()) {
      if (test(item)) {
        return item;
      }
    }
    return null;
  }

  @override
  Stream<T?> getOneStream(bool Function(T value) test) async* {
    await for (var item in getAllStream()) {
      if (test(item)) {
        yield item;
        return;
      }
    }
    yield null;
  }

  @override
  Future<List<T>> getQuery(bool Function(T value) test) async {
    final list = <T>[];

    for (var item in await getAll()) {
      if (test(item)) {
        list.add(item);
      }
    }
    return list;
  }

  @override
  Stream<List<T>> getQueryStream(bool Function(T value) test) async* {
    final list = <T>[];

    await for (var item in getAllStream()) {
      if (test(item)) {
        list.add(item);
      }
    }
    yield list;
  }

  @override
  Future<bool> updateById(int id, T value) {
    // TODO: implement updateById
    throw UnimplementedError();
  }

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
}

class TDBoxStreamEvent {
  final TBEventType type;
  final int? id;
  TDBoxStreamEvent({required this.type, this.id});
}
