# 3.0.0

## ✅ Features

- **Pure Dart implementation** — No native dependencies
- **Binary storage format** — Fast read/write
- **Append‑only engine** — Durable and efficient
- **Custom data type support** using `TDAdapter<T>`
- **Auto‑increment IDs** for all records
- **Box-based access** similar to Hive (e.g., `db.getBox<User>()`)
- **Query and streaming API**
- **Event listeners** for add/update/delete
- **Automatic compaction** to reduce file size
- **Backup support during compaction**

## Version Compatibility

**Current Database Version: `3.0.0`**

Starting from version **3.0.0**, the database format has been fully updated.
Older database versions are **no longer supported** and **cannot be opened or migrated** automatically.

If you attempt to open a database created with a previous version, the system will reject it for compatibility and safety reasons.

**Important Notes:**

- Databases created with version **3.0.0 and above** are fully compatible with future releases.
- Databases created with versions **below 3.0.0** must be recreated or manually migrated.

## 2.0.0

- Added `TDB` -> Data Compress

## 0.2.1

- Added `maybeCompact` -> Optional in `add,addAll,update,delete`
- Added `isDBInitialized` -> init Usage
- Added `addAll` -> `Multi Add Record`

## 0.1.0

- Initial version.
