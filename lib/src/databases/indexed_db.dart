import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:t_db/src/databases/tdb_header.dart';
import 'package:t_db/src/databases/tdb_recored.dart';
import 'package:t_db/src/utils/byte_data_extensions.dart';

class IndexedDB {
  late File _dbFile;
  late File _dbLockFile;
  late RandomAccessFile _writeRaf;

  void setConfig(File dbFile) {
    _dbFile = dbFile;
    _dbLockFile = File('${dbFile.path}.lock');
  }

  Future<RandomAccessFile> openReadRaf() async {
    return await _dbFile.open();
  }

  late String _magic;
  late int _version;
  int _deletedCount = 0;
  int _deletedSize = 0;
  int _lastIndex = 0;
  final Map<int, RecordMeta> _masterIndex = {};
  final Map<int, List<int>> _childrenOfParent = {};
  final bool _usedLockFile = false;

  int get version => _version;
  String get magic => _magic;
  int get deletedCount => _deletedCount;
  int get deletedSize => _deletedSize;
  int get lastIndex => _lastIndex;
  bool get usedLockFile => _usedLockFile;

  Future<void> load() async {
    if (!_dbFile.existsSync()) {
      // write header
      await TDBHeader(magic: 'TDB2', version: 2).writeHeader(_dbFile);
    }
    if (_usedLockFile && _dbLockFile.existsSync()) {
      await _buildIndexFromLockFile();
    } else {
      await _buildIndexInDatabase();
      await saveIndexLockFile();
    }

    _writeRaf = await _dbFile.open(mode: FileMode.append);
  }

  int generatedId() {
    _lastIndex++;
    return _lastIndex;
  }

  ///
  /// ### Get All RecordMeta
  ///
  List<RecordMeta> getAll({int? parentId}) {
    if (parentId != null) {
      final results = <RecordMeta>[];
      final childList = _childrenOfParent[parentId] ?? [];
      for (var id in childList) {
        final rec = _masterIndex[id];
        if (rec == null) continue;
        results.add(rec);
      }
      return results;
    }
    return _masterIndex.values.toList();
  }

  ///
  /// ### Add Single
  ///
  Future<void> add(TDBRecored record) async {
    final headerStartOffset = await record.write(_writeRaf);

    final meta = RecordMeta(
      id: record.id,
      offset: headerStartOffset,
      parentId: record.parentId,
      adapterTypeId: record.adapterTypeId,
      dataSize: record.data.length,
    );

    // add RAM
    _masterIndex[meta.id] = meta;
    if (meta.id > _lastIndex) _lastIndex = meta.id;
    if (meta.parentId != -1) {
      _childrenOfParent.putIfAbsent(meta.parentId, () => []).add(meta.id);
    }

    // ၅။ OS Buffer ထဲက data တွေကို Disk ပေါ် အကုန်ရောက်အောင် တွန်းပို့
    await _writeRaf.flush();
    await saveIndexLockFile();
  }

  ///
  /// ### Update Single
  ///
  Future<void> updateById(int id, TDBRecored record) async {
    final oldMeta = _masterIndex[id];
    if (oldMeta == null) throw Exception('Update ID:`$id` Not Found!.');
    //delete
    await oldMeta.deleteMark(_writeRaf);

    if (_childrenOfParent.containsKey(oldMeta.parentId)) {
      _childrenOfParent[oldMeta.parentId]!.remove(id);
    }
    _deletedCount++;
    _deletedSize += oldMeta.dataSize;

    //append လုပ်ပြီးတော့ offset အသစ်ပြန်ယူမယ်
    final headerStartOffset = await record.write(_writeRaf);

    final updatedMeta = oldMeta.copyWith(
      id: record.id,
      offset: headerStartOffset,
      adapterTypeId: record.adapterTypeId,
      parentId: record.parentId,
      dataSize: record.data.length,
    );

    // Update RAM
    _masterIndex[id] = updatedMeta;
    if (updatedMeta.id > _lastIndex) _lastIndex = updatedMeta.id;
    if (updatedMeta.parentId != -1) {
      _childrenOfParent
          .putIfAbsent(updatedMeta.parentId, () => [])
          .add(updatedMeta.id);
    }
    //ရေးပြီးကြောင်း
    await _writeRaf.flush();
  }

  ///
  /// ### Add Multiple
  ///
  Future<void> addMulti(List<TDBRecored> records) async {
    for (var record in records) {
      final headerStartOffset = await record.write(_writeRaf);
      final meta = RecordMeta(
        id: record.id,
        offset: headerStartOffset,
        parentId: record.parentId,
        adapterTypeId: record.adapterTypeId,
        dataSize: record.data.length,
      );

      // add RAM
      _masterIndex[meta.id] = meta;
      if (meta.id > _lastIndex) _lastIndex = meta.id;
      if (meta.parentId != -1) {
        _childrenOfParent.putIfAbsent(meta.parentId, () => []).add(meta.id);
      }
    }
    // ၅။ OS Buffer ထဲက data တွေကို Disk ပေါ် အကုန်ရောက်အောင် တွန်းပို့
    await _writeRaf.flush();
  }

  ///
  /// ### Delete By Id
  ///
  Future<void> deleteById(int id) async {
    final meta = _masterIndex[id];
    if (meta == null) throw Exception('Delete ID:`$id` Not Found!.');

    await meta.deleteMark(_writeRaf);

    // RAM ပေါ်က Index တွေကနေ ဖျက်
    _masterIndex.remove(id);
    if (_childrenOfParent.containsKey(meta.parentId)) {
      _childrenOfParent[meta.parentId]!.remove(id);
    }

    _deletedCount++;
    _deletedSize += meta.dataSize;

    //ရေးပြီးကြောင်း
    await _writeRaf.flush();
  }

  ///
  /// ### Delete All By IdList
  ///
  Future<void> deleteAllByIdList(List<int> idList) async {
    for (var id in idList) {
      final meta = _masterIndex[id];
      if (meta == null) throw Exception('Delete ID:`$id` Not Found!.');

      await meta.deleteMark(_writeRaf);

      // RAM ပေါ်က Index တွေကနေ ဖျက်
      _masterIndex.remove(id);
      if (_childrenOfParent.containsKey(meta.parentId)) {
        _childrenOfParent[meta.parentId]!.remove(id);
      }

      _deletedCount++;
      _deletedSize += meta.dataSize;
    }
    //ရေးပြီးကြောင်း
    await _writeRaf.flush();
  }

  ///
  /// build index from lock file
  ///
  Future<void> _buildIndexFromLockFile() async {
    try {
      if (_dbLockFile.lengthSync() < 4) {
        await _dbLockFile.delete();
        return;
      }
      final raf = await _dbLockFile.open(mode: FileMode.read);
      final size = ByteData.sublistView(await raf.read(4)).getInt4Bytes(0);
      final data = utf8.decode(await raf.read(size));
      final map = jsonDecode(data);
      // set
      _lastIndex = map['lastIndex'] ?? 0;
      _deletedCount = map['deletedCount'] ?? 0;
      _magic = map['magic']!;
      _version = map['version'] ?? 0;
      _deletedSize = map['deletedSize'] ?? 0;

      for (var item in map['meta_list'] ?? []) {
        final meta = RecordMeta.fromJson(item);
        _masterIndex[meta.id] = meta;
        if (meta.parentId != -1) {
          _childrenOfParent.putIfAbsent(meta.parentId, () => []).add(meta.id);
        }
      }

      await raf.close();
    } catch (e) {
      print('[IndexedDB:_buildIndexFromLockFile]: $e');
    }
  }

  ///
  /// ### Save Current Index
  ///
  Future<void> saveIndexLockFile() async {
    if (!_usedLockFile) return;
    final map = {
      'lastIndex': lastIndex,
      'magic': magic,
      'version': version,
      'deletedCount': deletedCount,
      'deletedSize': deletedCount,
      'meta_list': _masterIndex.values.map((e) => e.toJson()).toList(),
    };
    final raf = await _dbLockFile.open(mode: FileMode.write);
    final buffer = utf8.encode(jsonEncode(map));
    final header = ByteData(4);
    header.setInt4Bytes(0, buffer.length);

    await raf.writeFrom(header.buffer.asUint8List());
    await raf.writeFrom(buffer);
    await raf.close();
  }

  ///
  /// Build Index
  ///
  Future<void> _buildIndexInDatabase() async {
    _clearCache();
    if (!_dbFile.existsSync()) return;
    final size = await _dbFile.length();
    if (size < 5) return;
    final raf = await _dbFile.open();
    final (magic, version) = await TDBHeader.readHeader(raf); //need config
    // set
    _magic = magic;
    _version = version;

    int currentPos = 5;
    while (currentPos < size) {
      try {
        final (meta, status) = await TDBRecored.getMeta(raf, currentPos);

        if (status == RecordStatus.active) {
          _masterIndex[meta.id] = meta;
          if (meta.parentId != -1) {
            _childrenOfParent.putIfAbsent(meta.parentId, () => []).add(meta.id);
          }
        } else {
          // delete
          _deletedCount++;
          _deletedSize += meta.dataSize;
        }
        // calc index
        if (meta.id > _lastIndex) _lastIndex = meta.id;

        // ခုန်ကျော်မယ်
        currentPos = meta.offset + TDBRecored.headerSize + meta.dataSize;
      } catch (e) {
        // print('[IndexedDB:_buildIndex]: $e');
        break;
      }
    }

    await raf.close();
  }

  Future<void> closeRaf() async {
    await _writeRaf.close();
  }

  void _clearCache() {
    _deletedCount = 0;
    _deletedSize = 0;
    _lastIndex = 0;
    _childrenOfParent.clear();
    _masterIndex.clear();
  }

  ///
  /// ### Delete Lock File
  ///
  Future<void> deleteLockFile() async {
    if (_dbLockFile.existsSync()) {
      await _dbLockFile.delete();
    }
  }
}
