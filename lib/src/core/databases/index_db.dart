import 'dart:io';
import 'dart:typed_data';

import 'package:t_db/src/core/databases/record_meta.dart';
import 'package:t_db/src/core/type/db_config.dart';
import 'package:t_db/src/core/utils/encoder.dart';
import 'package:t_db/src/core/rw/binary_rw.dart';
import 'package:t_db/src/core/type/db_meta.dart';

class IndexDB {
  late final File dbFile;
  late final File lockFile;
  late final RandomAccessFile _writeRaf;
  late final RandomAccessFile _readRaf;
  late DBConfig _config;

  RandomAccessFile get readRaf => _readRaf;

  final List<RecordMeta> _records = [];
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

  List<RecordMeta> get records => _records;
  int get lastId => _lastId;
  int get deletedSize => _deletedSize;
  int get deletedCount => _deletedCount;

  void setConfig({required File dbFile, required DBConfig config}) {
    this.dbFile = dbFile;
    lockFile = File('${dbFile.path}.lock');
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

    while (await _readRaf.position() < size) {
      final flag = await _readRaf.readByte();
      if (flag == -1) break; //EOF

      final meta = await RecordMeta.readFromIndexDB(_readRaf);

      if (DBFlag.isActive(flag)) {
        _records.add(meta);
      } else {
        //delete
        _deletedCount++;
        _deletedSize += meta.recordTotalSize;
      }
      // set index
      if (meta.id > _lastId) _lastId = meta.id;
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
    required Uint8List jsonData,
  }) async {
    final offset = await _writeRaf.position();

    await _writeRaf.writeByte(DBFlag.Flag_Active);
    // unique field id
    await _writeRaf.writeFrom(intToBytes4(uniqueFieldId));
    // db id
    await _writeRaf.writeFrom(intToBytes8(getGeneratedId));
    // write data length
    await _writeRaf.writeFrom(intToBytes4(jsonData.length)); // json length byte

    // write data
    await _writeRaf.writeFrom(jsonData);

    // add memory
    final newMeta = await RecordMeta.read(_readRaf, headerOffset: offset);
    _records.add(newMeta);

    await _writeRaf.flush();

    return offset;
  }

  ///
  /// ### Delete By Id
  ///
  Future<bool> deleteById(int id) async {
    final index = _records.indexWhere((e) => e.id == id);
    if (index == -1) return false;

    final lastOffset = await _writeRaf.position();

    // go header offset
    final record = _records[index];
    await _writeRaf.setPosition(record.offset);

    //delete mark
    await _writeRaf.writeByte(DBFlag.Flag_Delete);

    //go back end position
    await _writeRaf.setPosition(lastOffset);

    // dist ထဲရေးသွင်း
    await _writeRaf.flush();

    return true;
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

  Future<void> close() async {
    await _readRaf.close();
    await _writeRaf.close();
  }
}
