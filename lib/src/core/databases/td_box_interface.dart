abstract class TDBoxInterface<T> {
  ///
  /// ### Add Single
  ///
  /// `parentId` ?? `adapter.getParentId(value)`
  ///
  Future<T?> add(T value);

  Future<void> addAll(List<T> values);

  Future<bool> updateById(int id, T value);
  Future<bool> deleteById(int id);
  Future<void> deleteAll(List<int> idList);
  Future<List<T>> getAll();
  Future<T?> getOne(bool Function(T value) test);
  // query
  Future<List<T>> getQuery(bool Function(T value) test);

  // Stream
  Stream<T> getAllStream();
  Stream<List<T>> getQueryStream(bool Function(T value) test);
  Stream<T?> getOneStream(bool Function(T value) test);
}
