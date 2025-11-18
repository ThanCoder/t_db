abstract class TDAdapter<T> {
  int getUniqueFieldId();
  Map<String, dynamic> toMap(T value);
  T fromMap(Map<String, dynamic> map);
}
