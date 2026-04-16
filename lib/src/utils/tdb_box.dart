import 'package:t_db/src/databases/indexed_db.dart';
import 'package:t_db/src/databases/tdb_recored.dart';
import 'package:t_db/t_db.dart';

class TDBBox<T> {
  final IndexedDB _indexedDB;
  final TDBAdapter<T> _adapter;
  const TDBBox({
    required TDB db,
    required IndexedDB indexedDB,
    required TDBAdapter<T> adapter,
  }) : _indexedDB = indexedDB,
       _adapter = adapter;

  ///
  /// ### Add `Box<T>`
  ///
  /// Return `generatedId`
  ///
  Future<int> add(T value) async {
    final map = _adapter.toMap(value);
    final generatedId = _indexedDB.generatedId();
    map['id'] = generatedId;
    map['auto_id'] = generatedId;

    await _indexedDB.add(
      TDBRecored(
        id: generatedId,
        adapterTypeId: _adapter.adapterTypeId,
        parentId: _adapter.parentId(value),
        data: _adapter.compress(_adapter.toJson(map)),
      ),
    );
    return generatedId;
  }

  ///
  /// ### Update By Id `Box<T>`
  ///
  ///
  Future<void> updateById(int id, T value) async {
    final map = _adapter.toMap(value);

    await _indexedDB.updateById(
      id,
      TDBRecored(
        id: id,
        adapterTypeId: _adapter.adapterTypeId,
        parentId: _adapter.parentId(value),
        data: _adapter.compress(_adapter.toJson(map)),
      ),
    );
  }

  ///
  /// ### Add `Box<T>`
  ///
  /// Return `generatedId`
  ///
  Future<void> addAll(List<T> values) async {
    final records = <TDBRecored>[];
    for (var value in values) {
      final map = _adapter.toMap(value);
      final generatedId = _indexedDB.generatedId();
      map['id'] = generatedId;
      map['auto_id'] = generatedId;

      records.add(
        TDBRecored(
          id: generatedId,
          adapterTypeId: _adapter.adapterTypeId,
          parentId: _adapter.parentId(value),
          data: _adapter.compress(_adapter.toJson(map)),
        ),
      );
    }
    return await _indexedDB.addMulti(records);
  }

  ///
  /// ### Read All `Box<List<T>>`
  ///
  Future<List<T>> getAll({int? parentId}) async {
    final raf = await _indexedDB.openReadRaf();
    final list = <T>[];
    for (var meta in _indexedDB.getAll(parentId: parentId)) {
      if (meta.adapterTypeId != -1 &&
          meta.adapterTypeId != _adapter.adapterTypeId) {
        continue;
      }
      final data = await meta.getData(raf);
      final map = _adapter.fromJson(_adapter.decompress(data));
      list.add(_adapter.fromMap(map));
      // print(meta.offset);
    }
    await raf.close();
    return list;
  }

  ///
  /// ### Delete By Id `Box<T>`
  ///
  /// childItemsWillDelete=true -> '`TDBAdapter` in `int parentId(T value) => -1;`'
  ///
  /// childItemsWillDelete=true -> All Child List Will Delele
  ///
  Future<void> deleteById(int id, {bool childItemsWillDelete = false}) async {
    await _indexedDB.deleteById(id);
    // child items will delete
    if (childItemsWillDelete) {
      final list = _indexedDB.getAll(parentId: id).map((e) => e.id).toList();
      await _indexedDB.deleteAllByIdList(list);
    }
  }

  ///
  /// ### Delete All `Box<List<T>>`
  ///
  Future<void> deleteAll() async {
    final values = await getAll();
    final ids = values.map((e) => _adapter.getId(e)).toList();
    await _indexedDB.deleteAllByIdList(ids);
  }
}
