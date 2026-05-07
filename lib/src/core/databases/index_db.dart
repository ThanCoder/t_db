import 'dart:io';
import 'dart:typed_data';

import 'package:t_db/src/core/databases/record_meta.dart';
import 'package:t_db/src/core/type/db_config.dart';
import 'package:t_db/src/core/utils/encoder.dart';
import 'package:t_db/src/core/rw/binary_rw.dart';
import 'package:t_db/src/core/type/db_meta.dart';

class IndexDB {
  late File dbFile;
  late RandomAccessFile _writeRaf;
  late RandomAccessFile _readRaf;
  late DBConfig _config;

  RandomAccessFile get readRaf => _readRaf;

  final Map<int, RecordMeta> _records = {};
  // Map<int,List<RecordMeta>>
  int _lastId = 0;
  int _deletedSize = 0;
  int _deletedCount = 0;
  late String _magic;
  late String _type;
  late int _version;

  String get magic => _magic;
  String get type => _type;
  int get version => _version;

  Map<int, RecordMeta> get records => _records;
  int get lastId => _lastId;
  int get deletedSize => _deletedSize;
  int get deletedCount => _deletedCount;

  void setConfig({required File dbFile, required DBConfig config}) {
    this.dbFile = dbFile;
    _config = config;
  }

  Future<void> init() async {
    if (!dbFile.existsSync()) {
      final raf = await dbFile.open(mode: FileMode.write);
      await BinaryRW.writeHeader(
        raf,
        version: _config.dbVersion,
        type: _config.dbType,
      );
      await raf.close();
    }
    _readRaf = await dbFile.open(mode: FileMode.read);
    _writeRaf = await dbFile.open(mode: FileMode.writeOnlyAppend);

    await _load();
  }

  int get getGeneratedId {
    _lastId++;
    return _lastId;
  }

  Future<void> _load() async {
    final size = await dbFile.length();

    // read header
    final (magic, version, type) = await BinaryRW.readHeader(_readRaf);
    _magic = magic;
    _version = version;
    _type = type;
    _records.clear();
    _lastId = 0;

    while (await _readRaf.position() < size) {
      try {
        final meta = await RecordMeta.read(_readRaf);

        if (meta.isActive) {
          _records[meta.id] = meta;
        } else {
          //delete
          _deletedCount++;
          _deletedSize += meta.recordTotalSize;
        }
        // set index
        if (meta.id > _lastId) _lastId = meta.id;
      } catch (e) {
        break;
      }
    }

    // print(_records);
  }

  ///
  /// ### Add
  ///
  /// Return (record header start offset)
  ///
  Future<int> addRecord({
    int uniqueFieldId = -1,
    required int id,
    required Uint8List jsonData,
  }) async {
    final offset = await _writeRaf.position();

    await _writeRaf.writeByte(DBFlag.Flag_Active);
    // unique field id
    await _writeRaf.writeFrom(intToBytes4(uniqueFieldId));
    // db id
    await _writeRaf.writeFrom(intToBytes8(id));
    // write data length
    await _writeRaf.writeFrom(intToBytes4(jsonData.length)); // json length byte

    // write data
    await _writeRaf.writeFrom(jsonData);

    // add memory
    final newMeta = RecordMeta(
      isActive: true,
      id: id,
      uniqueFieldId: uniqueFieldId,
      offset: offset,
      dataSize: jsonData.length,
      recordTotalSize: recordMetaHeaderSize + jsonData.length,
    );
    _records[newMeta.id] = newMeta;

    return offset;
  }

  ///
  /// ### Update by id
  ///
  Future<bool> updateById(
    int id, {
    int uniqueFieldId = -1,
    required Uint8List jsonData,
  }) async {
    final isDeleted = await deleteById(id, writeDiskFlush: true);
    // delete မလုပ်နိုင်ဘူး
    if (!isDeleted) return false;
    // add data
    await addRecord(id: id, uniqueFieldId: uniqueFieldId, jsonData: jsonData);
    // autoCompact
    await mabyCompact();
    return true;
  }

  ///
  /// ### Delete By Id
  ///
  Future<bool> deleteById(int id, {bool writeDiskFlush = false}) async {
    final meta = _records[id];

    if (meta == null) return false;

    final lastOffset = await _writeRaf.position();

    // go header offset
    await _writeRaf.setPosition(meta.offset);

    //delete mark
    await _writeRaf.writeByte(DBFlag.Flag_Delete);
    // remove RAM
    _records.remove(id);
    _deletedCount++;
    _deletedSize += meta.recordTotalSize;

    //go back end position
    await _writeRaf.setPosition(lastOffset);

    // dist ထဲရေးသွင်း
    if (writeDiskFlush) {
      await writeFlush();
      await mabyCompact();
    }

    return true;
  }

  /// ---- Compact ----

  Future<void> mabyCompact() async {
    if (deletedCount == 0) return;
    if (deletedCount > _config.minDeletedCount &&
        deletedSize > _config.minDeletedSize) {
      await compact();
    }
  }

  Future<void> compact() async {
    if (_deletedCount == 0) return;

    final compactFile = File('${dbFile.path}.compact-tem');
    final compactRaf = await compactFile.open(mode: FileMode.write);

    await BinaryRW.writeHeader(
      compactRaf,
      version: _config.dbVersion,
      type: _config.dbType,
    );

    final bufferSize = 1024 * 1024;
    final buffer = Uint8List(bufferSize);

    for (var meta in _records.values) {
      // go meta header
      await readRaf.setPosition(meta.offset);
      int bytesToRead = meta.recordTotalSize;

      while (bytesToRead > 0) {
        final currentReadSize = bytesToRead > bufferSize
            ? bufferSize
            : bytesToRead;

        final bytesRead = await readRaf.readInto(buffer, 0, currentReadSize);
        // ရေးထည့်မယ်
        await compactRaf.writeFrom(buffer, 0, bytesRead);

        //ဖတ်ပြီးသားကို နှုတ်ချထား
        bytesToRead -= currentReadSize;
      }
    }

    await compactRaf.close();
    //rename
    if (dbFile.existsSync()) {
      await dbFile.delete();
    }
    await compactFile.rename(dbFile.path);
  }

  bool get isOpened {
    try {
      _writeRaf;
      _readRaf;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> writeFlush() async {
    await _writeRaf.flush();
  }

  Future<void> close() async {
    await _readRaf.close();
    await _writeRaf.close();
  }
}
