enum TDBEvent { add, update, delete }

mixin TDBEventListener {
  void onTBDatabaseChanged(TDBEvent event, int? id);
}
