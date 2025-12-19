import 'dart:convert';
import 'dart:io';

import 'package:t_db/src/core/encoder.dart';
import 'package:t_db/src/core/type/db_config.dart';
import 'package:t_db/src/core/type/db_meta.dart';



class BinaryRW {
  ///
  /// 
  /// ### DB Header Byte Length
  ///
  static int get headerByteLength => 9;

  ///
  /// Write DB Header
  ///
  /// Write `magic`,`version`,`DB type`
  ///
  /// `type` == `4` count limited
  ///
  static Future<void> writeHeader(
    RandomAccessFile raf, {
    required int version,
    required String type,
  }) async {
    if (type.length != 4) {
      throw Exception(
        'Invalid DB type length: expected 4 bytes, got ${type.length}.',
      );
    }

    await raf.writeFrom(utf8.encode(DB_Magic));
    await raf.writeByte(version);
    await raf.writeFrom(utf8.encode(type));
  }

  ///
  /// ### Read Header
  ///
  /// Return `(magic,version,type)`
  ///
  static Future<(String, int, String)> readHeader(RandomAccessFile raf) async {
    final magicBytes = await raf.read(4);
    if (magicBytes.isEmpty) {
      throw Exception('Magic: Not Found!');
    }
    final magic = utf8.decode(magicBytes);
    if (magic != DB_Magic) {
      throw Exception(
        'Invalid DB Database Magic: excepted $DB_Magic got $magic',
      );
    }

    final version = await raf.readByte();
    final typeBytes = await raf.read(4);

    return (magic, version, utf8.decode(typeBytes));
  }

  ///
  /// ### Write Record
  ///
  /// Return Data `(offset,length)`
  ///
  static Future<(int, int)> writeRecord(
    RandomAccessFile raf, {
    required Map<String, dynamic> map,
    required int uniqueFieldId,
    required int newId,
  }) async {
    final jsonData = encodeRecordCompress4(map);

    await raf.writeByte(DBMeta.Flag_Active);
    // unique field id
    await raf.writeFrom(intToBytes4(uniqueFieldId));
    // db id
    await raf.writeFrom(intToBytes8(newId));
    // write data length
    await raf.writeFrom(intToBytes4(jsonData.length)); // json length byte
    final offset = await raf.position();
    // write data
    await raf.writeFrom(jsonData);

    return (offset, jsonData.length);
  }

  ///
  /// ### Read Record
  ///
  /// Return Data `(uniqueFieldId,id,length,dataOffset,data?)`
  ///
  ///if skipData=true ? `Map data`:`null`
  ///
  static Future<(int, int, int, int, Map<String, dynamic>?)> readRecord(
    RandomAccessFile raf, {
    bool skipData = false,
  }) async {
    Map<String, dynamic>? data;

    final uniqueFieldId = bytesToInt4(await raf.read(4));
    final id = bytesToInt8(await raf.read(8));
    final length = bytesToInt4(await raf.read(4));
    final current = await raf.position();
    if (skipData) {
      await raf.setPosition(current + length);
    } else {
      data = decodeRecordCompress4(await raf.read(length));
    }

    return (uniqueFieldId, id, length, current, data);
  }

  ///
  /// ### Read Record With Data
  ///
  ///
  ///if skipData=true ? `Map data`:`null`
  ///
  static Future<Map<String, dynamic>?> readRecordData(
    RandomAccessFile raf, {
    required int dataLength,
    required int dataOffset,
  }) async {
    await raf.setPosition(dataOffset);
    final data = decodeRecordCompress4(await raf.read(dataLength));

    return data;
  }

  static Future<void> compact({
    required File dbFile,
    bool saveBackup = true,
  }) async {
    final raf = await dbFile.open(mode: FileMode.read);
    final tmpFile = File('${dbFile.path}.tmp');
    final outRaf = await tmpFile.open(mode: FileMode.writeOnlyAppend);
    final dbLockFile = File('${dbFile.path}.lock');

    final (magic, version, type) = await BinaryRW.readHeader(raf);
    await BinaryRW.writeHeader(outRaf, version: version, type: type);

    while (true) {
      final flag = await raf.readByte();
      if (flag == -1) break; //EOF

      final uniqueFieldId = bytesToInt4(await raf.read(4));
      final id = bytesToInt8(await raf.read(8));
      final length = bytesToInt4(await raf.read(4));
      final current = await raf.position();
      // is deleted mark
      if (DBMeta.isDeleted(flag)) {
        await raf.setPosition(current + length);
      } else {
        final jsonDataBytes = await raf.read(length);
        // add tem file
        await outRaf.writeByte(DBMeta.Flag_Active);
        // unique field id
        await outRaf.writeFrom(intToBytes4(uniqueFieldId));
        // db id
        await outRaf.writeFrom(intToBytes8(id));
        // write data length
        await outRaf.writeFrom(intToBytes4(length)); // json length byte
        // write data
        await outRaf.writeFrom(jsonDataBytes);
      }
    }
    // close file
    await raf.close();
    await outRaf.close();
    // backup
    if (saveBackup) {
      await dbFile.rename('${dbFile.path}.bak');
    } else {
      // delete
      await dbFile.delete();
    }
    if (dbLockFile.existsSync()) {
      await dbLockFile.delete();
    }

    // rename main db
    await tmpFile.rename(dbFile.path);
  }
}
