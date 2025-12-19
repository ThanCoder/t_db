class TDBHeader {
  final String magic;
  final int version;
  final String type;
  TDBHeader({required this.magic, required this.version, required this.type});

  TDBHeader copyWith({String? magic, int? version, String? type}) {
    return TDBHeader(
      magic: magic ?? this.magic,
      version: version ?? this.version,
      type: type ?? this.type,
    );
  }
}
