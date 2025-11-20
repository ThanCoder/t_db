import 'dart:io';

import 'package:t_db/src/core/db_lock.dart';
import 'package:t_db/t_db.dart';

class DBRW {
  static Future<bool> deleteById(
    int id, {
    required RandomAccessFile raf,
    required DBLock dbLock,
  }) async {
    final index = dbLock.recordList.indexWhere((e) => e.id == id);
    if (index == -1) return false;
    final record = dbLock.recordList[index];

    final dataOffset = record.offset;
    final endPos = await raf.position();
    // go to flag
    await raf.setPosition(
      dataOffset - 4 - 8 - 4 - 1,
    ); // 4=length,8=id,4=uniqueFieldId,1=flag
    await raf.writeByte(DBMeta.Flag_Delete);

    // go to end
    await raf.setPosition(endPos);

    // change memory
    dbLock.recordList.removeAt(index);
    dbLock.deletedCount++;
    dbLock.deletedSize += record.length;
    return true;
  }
}
