# TDB — Lightweight Binary Database for Dart

TDB is a high‑performance, append‑only binary database engine written in pure Dart. It is designed for speed, low memory usage, and easy integration into Flutter or server applications. TDB supports custom data models using adapters, auto‑increment IDs, record querying, event listeners, and automatic compaction.

---

## Version Compatibility

**Current Database Version: `1.2.0`**

Starting from version **1.2.0**, the database format has been fully updated.
Older database versions are **no longer supported** and **cannot be opened or migrated** automatically.

If you attempt to open a database created with a previous version, the system will reject it for compatibility and safety reasons.

**Important Notes:**

- Databases created with version **1.2.0 and above** are fully compatible with future releases.
- Databases created with versions **below 3.0.0** must be recreated or manually migrated.

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
- **Database HBRelation** -> Database Relation
- **Backup support during compaction**

---

## 📦 Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  t_db: ^1.2.0
```

---

## 🚀 Quick Start

### 1. Create Model & Adapter

```dart
class User {
  final int autoId; //need field for autoId
  final String name;
  User({this.autoId = 0, required this.name});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'autoId': autoId, 'name': name};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(autoId: map['autoId'] as int, name: map['name'] as String);
  }
  @override
  String toString() {
    return 'ID: $autoId - Name: $name';
  }
}

class UserAdapter extends TDAdapter<User> {
  @override
  User fromMap(Map<String, dynamic> map) {
    return User.fromMap(map);
  }

  @override
  int getUniqueFieldId() {
    return 1; // must be unique for each model
  }

  @override
  Map<String, dynamic> toMap(User value) {
    return value.toMap();
  }
}
```

---

### 2. Open Database

```dart
final db = TDB.getInstance();
await db.open('test.db');

db.setAdapter<User>(UserAdapter());
```

---

## HBRelation

```dart
enum RelationAction {
  none,// `none` → `let developer handle`
  cascade,// `cascade` → `remove/update children together`
  restrict,// `restrict` → `prevent delete/update if children exist`
}

// parent
class UserAdapter extends TDAdapter<User> {
  @override
  List<HBRelation> relations() {
    return [
      HBRelation(
        targetType: Car,
        foreignKey: 'userId',
        onDelete: RelationAction.cascade,
      ),
    ];
  }
}
// target
class CarAdapter extends TDAdapter<Car> {
  @override
  getFieldValue(Car value, String fieldName) {
    if (fieldName == 'userId') return value.userId;   /// 🔑 IMPORTANT
  }
}
```

## ✨ Basic Operations

### Add

```dart
final id = await db.add<User>(User(name: 'Than'));
printf(id); // auto-increment ID
```

### Get All

```dart
final users = await db.getAll<User>();
```

### Query

```dart
final result = await db.queryAll<User>((u) => u.name.startsWith('T'));
```

### Update

```dart
await db.updateById<User>(1, User(name: 'Updated'));
```

### Delete

```dart
await db.deleteById<User>(1);
```

### You can listen for changes

```dart
db.stream.listen((event) {
  print(event.type);   // add, delete, update
  print(event.id);      // affected record
  print(event.uniqueFieldId) //uniqueFieldId
});
```

---

## 📦 Box API

`TDBox<T>` is a typed data container created automatically when you call `db.setAdapter<T>()`.
It provides an easy, safe CRUD interface on top of the TDB core.

---

> **Note About `autoId` Field**
>
> Every model class used with TDB **must include an `autoId` field**.
> This field will be automatically populated by the database during insertion.
>
> Example:
>
> ```dart
> class User {
>   final int autoId;     // MUST exist — TDB writes newId into this field
>   final String name;
>
>   User({ this.autoId = 0, required this.name });
> }
> ```
>
> If `autoId` is missing:
>
> - The database cannot assign a generated ID back into the object
> - Update / Delete operations may not function correctly
> - Querying by ID becomes impossible

`TDBox<T>` is a typed data container created automatically when you call `db.setAdapter<T>()`.
It provides an easy, safe CRUD interface on top of the TDB core.

---

### 🔧 How Box Works Internally

A Box is connected to:

- the database instance (`TDB`)
- the registered adapter for type `T`

When you call:

```dart
final box = db.getBox<User>();
```

TDB internally maps:

- adapter → serialization
- box → CRUD access by type

Each Box only accesses records that match its adapter's unique field ID.

---

### 📌 TDBox`<T>` Class Structure

```dart
class TDBox<T> {
  final TDB _db;
  TDBox(this._db);

  Future<List<T>> getAll();
  Future<List<T>> queryAll(bool Function(T value) test);
  Stream<T> getAllStream();
  Stream<T> queryAllStream(bool Function(T value) test);
  Future<T?> getOne(bool Function(T value) test);

  Future<int> add(T value);
  Future<void> addAll(List<T> values);
  Future<bool> deleteById(int id);
  Future<void> deleteAll(List<int> idList);
  Future<bool> updateById(int id, T value);
  Future<bool> update(T value);

  final List<TBoxEventListener> _listener = [];
  void addListener(TBoxEventListener listener);
  void removeListener(TBoxEventListener listener);
  void notify(TBEventType event, int? id);
}
```

---

(Similar to Hive)
TDB provides a simple Box API through `TDBox<T>`.
A Box is automatically created when you call `db.setAdapter<T>()`.

### Creating and Using a Box

```dart
final userBox = db.getBox<User>();
```

### Box Methods

`TDBox<T>` provides convenient CRUD and query helpers:

#### Get All

```dart
final users = await userBox.getAll();
```

#### Query

```dart
final adults = await userBox.queryAll((u) => u.age >= 18);
```

#### Stream All

```dart
await for (final user in userBox.getAllStream()) {
  print(user);
}
```

#### Stream Query

```dart
await for (final user in userBox.queryAllStream((u) => u.isActive)) {}
```

#### Add

```dart
final id = await userBox.add(User(name: "Aung"));
```

#### Add Multiple

```dart
await userBox.addAll([user1, user2, user3]);
```

#### Update

```dart
await userBox.updateById(1, User(name: "Updated"));
```

#### Delete

```dart
await userBox.deleteById(3);
```

#### Delete Multiple

```dart
await userBox.deleteAll([1, 2, 3]);
```

---

## 🔔 Box Event Listener

`TDBox<T>` supports reactive data listening.
Events: `add`, `update`, `delete`.

### Add Listener

```dart
userBox.addListener(TBoxEventListener(
  onTBoxDatabaseChanged: (event, id) {
    print('Box event: $event  id: $id');
  },
));
```

### Remove Listener

```dart
userBox.removeListener(listener);
```

---

(Similar to Hive)
When you register an adapter, TDB automatically creates a box:

```dart
final userBox = db.getBox<User>();
```

### You can listen for changes

```dart
userBox.stream.listen((event) {
  print(event.type);   // add, delete, update
  print(event.id);      // affected record
});
```

---

## 🔍 Streaming API

### Read All Stream

```dart
await for (var user in db.getAllStream<User>()) {
  print(user.name);
}
```

---

## 🧹 Auto Compaction

The database grows over time because of append-only writes. Deleted or updated records are cleaned automatically based on configuration:

```dart
DBConfig(
  autoCompact: true,
  minDeletedCount: 20,
  minDeletedSize: 4096,
  saveBackupDBCompact: true,
);
```

You can also run compaction manually:

```dart
await db.compact();
```

---

## 🔄 Event Listener

```dart
db.addListener(TBEventListener(
  onTBDatabaseChanged: (event, typeId, id) {
    print('Event: $event, type: $typeId, id: $id');
  },
));
```

---

## 📁 Database Structure

Each record is stored as:

```
[length][id][typeId][flag][payload]
```

- `length` — record byte size
- `id` — auto increment
- `typeId` — from adapter
- `flag` — normal or deleted
- `payload` — compressed or uncompressed map data

---

## 🛑 Closing Database

```dart
await db.close();
```

---

# DBConfig

`DBConfig` defines all configuration options for how the database behaves internally, including versioning, type signature, compaction rules, backups, and locking.

---

## Configuration Fields

### `dbVersion`

- **Type:** `int`
- **Description:** Database format version.
  Must fit into **1 byte (0–255)**.
  Used to validate database compatibility.

### `dbType`

- **Type:** `String`
- **Expected Length:** **4 bytes**
- **Default:** `TDBT`
- Identifies the file as a valid TDB database.

### `saveLocalDBLock`

- **Type:** `bool`
- When enabled, the engine creates a local lock file to prevent accidental corruption from concurrent access.

### `minDeletedCount`

- **Type:** `int`
- Minimum number of deleted entries required before auto-compaction can run.

### `minDeletedSize`

- **Type:** `int`
- Minimum total deleted data size (in bytes) required before auto-compaction can run.

### `saveBackupDBCompact`

- **Type:** `bool`
- If enabled, a backup file is created each time a compaction occurs.

### `autoCompact`

- **Type:** `bool`
- When enabled, the database automatically performs compaction after `update` or `delete` operations once thresholds are reached.

---

## Default Configuration

The built-in default settings are:

```dart
dbVersion: 1,
dbType: 'TDBT',
saveLocalDBLock: true,
minDeletedCount: 100,
minDeletedSize: 1024 * 1024, // 1MB
saveBackupDBCompact: true,
autoCompact: true,
```

To get the default config:

```dart
final config = DBConfig.getDefault();
```

---

## Copying With Modifications

You can easily override specific fields using `copyWith()`:

```dart
final config = DBConfig.getDefault().copyWith(
  dbVersion: 2,
  autoCompact: false,
);
```

## 🧪 Safe to Use In:

- Flutter mobile apps
- Desktop apps
- CLI tools
- Local server storage

Not suitable for:

- Multi-process access
- High-concurrency server DB

---

## 📌 Notes

- Each model **must have a unique `getUniqueFieldId()`**
- Database is **append-only**, so compaction is necessary

---

## 📄 License

MIT
