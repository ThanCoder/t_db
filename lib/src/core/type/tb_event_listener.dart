enum TBEventType { add, update, delete }

mixin TBEventListener {
  void onTBDatabaseChanged(TBEventType event, int uniqueFieldId, int? id);
}

mixin TBoxEventListener {
  void onTBoxDatabaseChanged(TBEventType event, int? id);
}
