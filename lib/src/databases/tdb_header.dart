import 'dart:convert';
import 'dart:io';

class TDBHeader {
  final String magic;
  final int version;

  const TDBHeader({required this.magic, required this.version});

  Future<void> writeHeader(File dbFile) async {
    if (magic.length != 4) {
      throw Exception('Write Magic String Count: `4` Required');
    }
    final raf = await dbFile.open(mode: FileMode.write);
    await raf.writeFrom(utf8.encode(magic));
    await raf.writeByte(version);
    await raf.close();
  }

  ///
  /// Return (magic,version)
  ///
  static Future<(String, int)> readHeader(
    RandomAccessFile raf, {
    String? requiredMagic,
    int? requiredVersion,
  }) async {
    final magicBytes = await raf.read(4);
    if (magicBytes.length != 4) {
      throw Exception(
        'Required Magic String Count: `4` And Got `${magicBytes.length}`',
      );
    }
    final magicStr = utf8.decode(magicBytes);
    if (requiredMagic != null && magicStr != requiredMagic) {
      throw Exception(
        'Magic Not Match!.Required: `$requiredMagic` And Got `$magicStr`',
      );
    }
    final versionInt = await raf.readByte();
    if (requiredVersion != null && versionInt != requiredVersion) {
      throw Exception(
        'Version Not Match!.Required: `$requiredVersion` And Got `$versionInt`',
      );
    }
    return (magicStr, versionInt);
  }
}
