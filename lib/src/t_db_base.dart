import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:t_db/src/db_meta_store.dart';
import 'package:t_db/src/record.dart';

abstract class TDB<T> {
  final Map<int, int> _index = {}; // id → offset
  int _lastId = 0;
  late RandomAccessFile _file;
  late DBMetaStore _metaStore;

  /// Convert T instance to [Map<String, dynamic>] (for binary storage)
  Map<String, dynamic> toMap(T value);
  T fromMap(Map<String, dynamic> map);

  /// Return ID of the instance (for auto increment / indexing)
  int getId(T value);

  /// Assign ID to the instance (for insert)
  void setId(T value, int id);

  Future<void> open(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    _file = await file.open(mode: FileMode.append);
    // index lock file
    _metaStore = DBMetaStore(path);
    await _loadMeta();
  }

  /// ✅ Get by ID
  Future<T?> get(int id) async {
    final offset = _index[id];
    if (offset == null) return null;
    final raf = await File(_file.path).open();
    await raf.setPosition(offset);
    final lengthBytes = await raf.read(4);
    final length = ByteData.sublistView(lengthBytes).getUint32(0);
    final data = await raf.read(length);
    await raf.close();
    return fromMap(jsonDecode(utf8.decode(data)));
  }

  /// ✅ Get all
  Future<List<T>> getAll() async {
    final file = File(_file.path);
    final raf = await file.open();
    final users = <T>[];

    for (final entry in _index.entries) {
      final offset = entry.value;
      await raf.setPosition(offset);
      final lengthBytes = await raf.read(4);
      final length = ByteData.sublistView(lengthBytes).getUint32(0);
      final data = await raf.read(length);
      final user = fromMap(jsonDecode(utf8.decode(data)));
      users.add(user);
    }

    await raf.close();
    return users;
  }

  /// ✅ Auto increment ID + Insert
  Future<T> insert(T value) async {
    final id = ++_lastId;
    setId(value, id);

    final bytes = encodeRecord(toMap(value));
    final offset = await _file.length();
    await _file.writeFrom(bytes);
    _index[getId(value)] = offset;
    await _saveMeta(); // ✅ Save meta after insert
    return value;
  }

  /// ✅ Update record by ID
  Future<bool> update(T value) async {
    if (!_index.containsKey(getId(value))) return false;
    // Append new data at end (overwrite မလုပ်ပါ)
    final bytes = encodeRecord(toMap(value));
    final offset = await _file.length();
    await _file.writeFrom(bytes);
    // Index ကို update လုပ်
    _index[getId(value)] = offset;
    await _saveMeta(); // ✅ Save meta after insert
    return true;
  }

  /// ✅ Delete record by ID (soft delete)
  Future<bool> delete(int id) async {
    if (!_index.containsKey(id)) return false;
    _index.remove(id);
    // file ထဲကနေ မဖျက်သေးပါ (Garbage collection နောက်မှ)
    await _saveMeta(); // ✅ Save meta after insert
    return true;
  }

  /// ✅ Query/filter support
  Future<List<T>> query(bool Function(T value) test) async {
    final all = await getAll();
    return all.where(test).toList();
  }

  Future<void> close() async => _file.close();

  /// meta `[.lock]` file
  Future<void> _saveMeta() async {
    // Update meta store values before saving
    _metaStore.lastId = _lastId;
    _metaStore.index
      ..clear()
      ..addAll(_index);

    // Save to binary .lock file
    await _metaStore.save();
    // check if compaction needed
    await _maybeCompact();
  }

  Future<void> _loadMeta() async {
    try {
      // Try load meta
      if (await _metaStore.file.exists()) {
        await _metaStore.load();

        // assign to DB
        _lastId = _metaStore.lastId;
        _index.clear();
        _index.addAll(_metaStore.index);
      } else {
        // .lock file မရှိရင် fallback
        print('Meta file not found. Rebuilding index from data file...');
        await rebuildIndex();
        await _saveMeta(); // rebuildပြီး save back to .lock
      }
    } catch (e) {
      print('Meta load failed: $e. Rebuilding index...');
      await rebuildIndex();
      await _saveMeta();
    }
  }

  /// rebuld index && not found `[.lock]` file
  Future<void> rebuildIndex() async {
    _index.clear();
    _lastId = 0;

    final raf = await File(_file.path).open();
    int offset = 0;

    while (true) {
      try {
        // read length (4 bytes)
        final lenBytes = await raf.read(4);
        if (lenBytes.length < 4) break;
        final length = ByteData.sublistView(lenBytes).getUint32(0, Endian.big);

        // read record
        final data = await raf.read(length);
        if (data.length < length) break;

        final map = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
        final id = map['id'] as int;
        _index[id] = offset;

        if (id > _lastId) _lastId = id;

        offset += 4 + length;
      } catch (_) {
        break;
      }
    }

    await raf.close();
  }

  /// DB Change Path
  Future<void> changePath(String newPath) async {
    // close old file
    await _file.close();

    // update file
    final file = File(newPath);
    if (!await file.exists()) await file.create(recursive: true);
    _file = await file.open(mode: FileMode.append);

    // update meta store
    _metaStore = DBMetaStore(newPath);

    // load or rebuild meta
    try {
      await _metaStore.load();
      _lastId = _metaStore.lastId;
      _index
        ..clear()
        ..addAll(_metaStore.index);
    } catch (e) {
      print('Meta load failed: $e. Rebuilding index...');
      await rebuildIndex();
      await _saveMeta();
    }
  }

  ///
  /// ✅ auto Remove deleted records and rebuild file
  ///
  Future<void> _maybeCompact() async {
    final deletedRatio = 1 - _index.length / _lastId;
    final fileSize = await _file.length();
    if (deletedRatio > 0.3 || fileSize > 50 * 1024 * 1024) {
      await compact(); // run in background
    }
  }

  ///
  /// ✅ Remove deleted records and rebuild file
  ///
  Future<void> compact() async {
    final tempFile = File('${_file.path}.tmp');
    final raf = await tempFile.open(mode: FileMode.write);

    final newIndex = <int, int>{};
    int offset = 0;

    for (final entry in _index.entries) {
      final id = entry.key;
      final oldOffset = entry.value;

      // read record from old file
      await _file.setPosition(oldOffset);
      final lenBytes = await _file.read(4);
      final length = ByteData.sublistView(lenBytes).getUint32(0, Endian.big);
      final data = await _file.read(length);

      // write to temp file
      await raf.writeFrom(lenBytes);
      await raf.writeFrom(data);

      // update new index
      newIndex[id] = offset;
      offset += 4 + length;
    }

    await raf.close();
    await _file.close();

    // replace old file
    final oldFile = File(_file.path);
    await oldFile.rename('${_file.path}.bak');
    await tempFile.rename(_file.path);

    // reopen DB file
    _file = await File(_file.path).open(mode: FileMode.append);

    // update index & save meta
    _index
      ..clear()
      ..addAll(newIndex);
    await _saveMeta();
  }
}
