enum TBEventType { add, update, delete }

mixin TBEventListener {
  void onTBDatabaseChanged(TBEventType event, int uniqueFieldId, int? id);
}

mixin TBoxEventListener {
  void onTBoxDatabaseChanged(TBEventType event, int? id);
}

class TBStreamEvent {
  final int uniqueFieldId;
  final TBEventType type;
  final int? id;
  TBStreamEvent({required this.uniqueFieldId, required this.type, this.id});
}
