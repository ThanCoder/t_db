class DBRecord {
  final int id;
  final int uniqueFieldId;
  final int offset;
  final int length;
  DBRecord({
    required this.id,
    required this.uniqueFieldId,
    required this.offset,
    required this.length,
  });

  DBRecord copyWith({int? id, int? uniqueFieldId, int? offset, int? length}) {
    return DBRecord(
      id: id ?? this.id,
      uniqueFieldId: uniqueFieldId ?? this.uniqueFieldId,
      offset: offset ?? this.offset,
      length: length ?? this.length,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uniqueFieldId': uniqueFieldId,
      'offset': offset,
      'length': length,
    };
  }

  factory DBRecord.fromMap(Map<String, dynamic> map) {
    return DBRecord(
      id: map['id'] as int,
      uniqueFieldId: map['uniqueFieldId'] as int,
      offset: map['offset'] as int,
      length: map['length'] as int,
    );
  }

  @override
  String toString() {
    return 'ID: $id';
  }
}
