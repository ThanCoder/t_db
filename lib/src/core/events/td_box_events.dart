import 'package:t_db/src/core/type/tb_event_listener.dart';

class TDBoxStreamEvent {
  const TDBoxStreamEvent();
}

class TDBoxStreamCRUDEvent extends TDBoxStreamEvent {
  final TBEventType type;
  final int id;
  final int uniqueFieldId;

  const TDBoxStreamCRUDEvent({
    required this.type,
    required this.id,
    required this.uniqueFieldId,
  });

  @override
  String toString() =>
      '''TDBoxStreamEvent(type: ${type.name}, id: $id, uniqueFieldId: $uniqueFieldId)''';
}

class TDBoxStreamErrorEvent extends TDBoxStreamEvent {
  final TBEventType type;
  final int id;
  final int uniqueFieldId;
  final String errorMessage;

  const TDBoxStreamErrorEvent({
    required this.type,
    required this.id,
    required this.uniqueFieldId,
    required this.errorMessage,
  });

  @override
  String toString() {
    return '''TDBoxStreamErrorEvent(type: $type, id: $id, uniqueFieldId: $uniqueFieldId, errorMessage: $errorMessage)''';
  }
}
