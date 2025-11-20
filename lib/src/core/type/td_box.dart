import 'package:t_db/src/core/type/tb_event_listener.dart';
import 'package:t_db/src/t_db_base.dart';

class TDBox<T> {
  final TDB _db;
  // final TDAdapter _adapter;
  TDBox(this._db);

  Future<List<T>> getAll() async {
    return await _db.getAll<T>();
  }

  Future<T?> getById(int id) async {
    return await _db.getById<T>(id);
  }

  Future<T?> getOne(bool Function(T value) test) async {
    return await _db.getOne<T>(test);
  }

  Future<List<T>> queryAll(bool Function(T value) test) async {
    return await _db.queryAll<T>(test);
  }

  Stream<T> getAllStream() {
    return _db.getAllStream<T>();
  }

  Stream<T> queryAllStream(bool Function(T value) test) {
    return _db.queryAllStream<T>(test);
  }

  Future<int> add(T value) async {
    final newId = await _db.add<T>(value);
    return newId;
  }

  Future<void> addAll(List<T> values) async {
    await _db.addAll<T>(values);
  }

  Future<bool> deleteById(int id) async {
    final isDeleted = await _db.deleteById<T>(id);
    return isDeleted;
  }

  Future<void> deleteAll(List<int> idList) async {
    await _db.deleteAll<T>(idList);
  }

  Future<bool> updateById(int id, T value) async {
    final isUpdated = await _db.updateById<T>(id, value);
    return isUpdated;
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
    for (var listener in _listener) {
      listener.onTBoxDatabaseChanged(event, id);
    }
  }
}
