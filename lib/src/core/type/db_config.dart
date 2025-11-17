// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: constant_identifier_names

const String DB_Magic = 'TDB';

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
  DBConfig({
    required this.dbVersion,
    required this.dbType,
    required this.saveLocalDBLock,
  });

  factory DBConfig.getDefault() {
    return DBConfig(
      dbVersion: DB_Version,
      dbType: DB_Type,
      saveLocalDBLock: true,
    );
  }
}
