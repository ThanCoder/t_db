// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: constant_identifier_names

const String DB_Magic = 'TDBJ';

///
/// ## DB Type
///
const String DB_Type = 'TDBT';
const int DB_Version = 1;

class DBConfig {
  ///
  /// ### DB Version length: excepted 1 bytes
  ///
  final int dbVersion;

  ///
  /// ### DB type length: expected 4 bytes
  ///
  /// Default `TDBT`
  ///
  final String dbType;

  ///
  /// ### DB type length: expected 4 bytes
  ///
  final bool saveLocalDBLock;

  ///
  /// ###
  ///
  final int minDeletedCount;

  ///
  /// ###
  ///
  final int minDeletedSize;

  ///
  /// ### When DB Compact and create Old DB backup.
  ///
  final bool saveBackupDBCompact;

  ///
  /// ### When DB `update,delete` and database auto compact.
  ///
  final bool autoCompact;

  DBConfig({
    required this.dbVersion,
    required this.dbType,
    required this.saveLocalDBLock,
    required this.minDeletedCount,
    required this.minDeletedSize,
    required this.saveBackupDBCompact,
    required this.autoCompact,
  });

  ///
  /// ### Default Setting
  ///
  ///```dart
  /// dbVersion: 1,
  /// dbType: 'TDBT',
  /// saveLocalDBLock: true,
  /// minDeletedCount: 100,
  /// minDeletedSize: 1024 * 1024, //1MB
  /// saveBackupDBCompact: true,
  /// autoCompact: true, // When DB `update,delete` and database auto compact.
  ///```
  factory DBConfig.getDefault() {
    return DBConfig(
      dbVersion: 1,
      dbType: DB_Type,
      saveLocalDBLock: true,
      minDeletedCount: 100,
      minDeletedSize: 1024 * 1024,
      saveBackupDBCompact: true,
      autoCompact: true,
    );
  }

  DBConfig copyWith({
    int? dbVersion,
    String? dbType,
    bool? saveLocalDBLock,
    int? minDeletedCount,
    int? minDeletedSize,
    bool? saveBackupDBCompact,
    bool? autoCompact,
  }) {
    return DBConfig(
      dbVersion: dbVersion ?? this.dbVersion,
      dbType: dbType ?? this.dbType,
      saveLocalDBLock: saveLocalDBLock ?? this.saveLocalDBLock,
      minDeletedCount: minDeletedCount ?? this.minDeletedCount,
      minDeletedSize: minDeletedSize ?? this.minDeletedSize,
      saveBackupDBCompact: saveBackupDBCompact ?? this.saveBackupDBCompact,
      autoCompact: autoCompact ?? this.autoCompact,
    );
  }
}
