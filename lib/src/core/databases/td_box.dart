import 'dart:async';

import 'package:t_db/src/core/databases/index_db.dart';
import 'package:t_db/src/core/databases/td_box_interface.dart';
import 'package:t_db/src/core/events/td_box_events.dart';
import 'package:t_db/t_db.dart';

class TDBox<T> extends TDBoxInterface<T> {
  late final IndexDB _indexDB;
  late final TDAdapter<T> _adapter;
  late final StreamController<TDBoxStreamEvent> _streamController;

  TDBox({
    required IndexDB indexDB,
    required TDAdapter<T> adapter,
    required StreamController<TDBoxStreamEvent> streamController,
  }) : _indexDB = indexDB,
       _adapter = adapter,
       _streamController = streamController;

  @override
  Future<T?> add(T value) async {
    final id = _indexDB.getGeneratedId;
    // print('add id: $id');
    try {
      // map['autoId'] = id;
      final map = _adapter.toMap(value);
      final newValue = _adapter.fromMap(_adapter.setAutoId(map, id));
      final jsonData = _adapter.encodeRecord(_adapter.toJson(newValue));
      await _indexDB.addRecord(
        id: id,
        jsonData: jsonData,
        uniqueFieldId: _adapter.getUniqueFieldId(),
      );
      // event
      notify(TBEventType.add, id, _adapter.getUniqueFieldId());

      return newValue;
    } catch (e) {
      notify(
        TBEventType.add,
        id,
        _adapter.getUniqueFieldId(),
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  @override
  Future<void> addAll(List<T> values) async {
    for (var value in values) {
      final id = _indexDB.getGeneratedId; //auto id

      final map = _adapter.toMap(value);
      final newValue = _adapter.fromMap(_adapter.setAutoId(map, id));
      final jsonData = _adapter.encodeRecord(_adapter.toJson(newValue));
      await _indexDB.addRecord(
        jsonData: jsonData,
        id: id,
        uniqueFieldId: _adapter.getUniqueFieldId(),
      );

      notify(TBEventType.add, id, _adapter.getUniqueFieldId());
    }
    // disk ထဲရေးသွင်း
    await _indexDB.writeFlush();
  }

  @override
  Future<void> deleteAll(List<int> idList) async {
    for (var id in idList) {
      await _indexDB.deleteById(id);
    }
    // disk ထဲရေးသွင်း
    await _indexDB.writeFlush();
  }

  @override
  Future<bool> deleteById(int id) async {
    final isDeleted = await _indexDB.deleteById(id);
    // disk ထဲရေးသွင်း
    await _indexDB.writeFlush();
    // autoCompact
    await _indexDB.mabyCompact();

    notify(
      TBEventType.delete,
      id,
      _adapter.getUniqueFieldId(),
      errorMessage: isDeleted ? null : 'Deleted Failed!',
    );

    return isDeleted;
  }

  @override
  Future<List<T>> getAll() async {
    final uniqueFieldId = _adapter.getUniqueFieldId();
    final list = <T>[];
    for (var meta in _indexDB.records.values) {
      // skip
      if (meta.uniqueFieldId != uniqueFieldId) continue;

      final jsonDataBytes = await meta.readData(_indexDB.readRaf);
      final map = _adapter.fromJson(_adapter.decodeRecord(jsonDataBytes));
      // print('get id : ${meta.id}');
      list.add(_adapter.fromMap(_adapter.setAutoId(map, meta.id)));
      // print(map);
    }
    return list;
  }

  @override
  Stream<T> getAllStream() async* {
    final uniqueFieldId = _adapter.getUniqueFieldId();
    for (var meta in _indexDB.records.values) {
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
  Future<bool> updateById(int id, T value) async {
    final map = _adapter.toMap(value);
    final jsonData = _adapter.encodeRecord(
      _adapter.toJson(_adapter.fromMap(_adapter.setAutoId(map, id))),
    );
    final isUpdated = await _indexDB.updateById(
      id,
      uniqueFieldId: _adapter.getUniqueFieldId(),
      jsonData: jsonData,
    );
    notify(
      TBEventType.update,
      id,
      _adapter.getUniqueFieldId(),
      errorMessage: isUpdated ? null : 'Update Failed!',
    );

    return isUpdated;
  }

  void notify(
    TBEventType type,
    int id,
    int uniqueFieldId, {
    String? errorMessage,
  }) {
    // stream
    if (errorMessage != null) {
      _streamController.add(
        TDBoxStreamErrorEvent(
          type: type,
          id: id,
          uniqueFieldId: uniqueFieldId,
          errorMessage: errorMessage,
        ),
      );
      return;
    }
    _streamController.add(
      TDBoxStreamCRUDEvent(type: type, id: id, uniqueFieldId: uniqueFieldId),
    );
  }
}
