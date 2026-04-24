# TDB — Lightweight Binary Database for Dart

TDB is a high‑performance, append‑only binary database engine written in pure Dart. It is designed for speed, low memory usage, and easy integration into Flutter or server applications. TDB supports custom data models using adapters, auto‑increment IDs, record querying, event listeners, and automatic compaction.

---

## Version Compatibility

**Current Database Version: `2.0.0`**

Starting from version **2.0.0**, the database format has been fully updated.
Older database versions are **no longer supported** and **cannot be opened or migrated** automatically.

If you attempt to open a database created with a previous version, the system will reject it for compatibility and safety reasons.

## ✅ Features

- **Pure Dart implementation** — No native dependencies
- **Binary storage format** — Fast read/write
- **Append‑only engine** — Durable and efficient
- **Custom data type support** using `TDAdapter<T>`
- **Auto‑increment IDs** for all records
- **Box-based access** similar to Hive (e.g., `db.getBox<User>()`)
- **Query and streaming API**
- **Automatic compaction** to reduce file size
- **Backup support during compaction**

---

## 📦 Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  t_db: ^2.0.0
```

---

## 🚀 Quick Start

### 1. Create Model & Adapter

```dart
class User {
  final int id; //auto generated id
  final String name;
  User({this.id = 0, required this.name});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'name': name};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(id: map['id'] as int, name: map['name'] as String);
  }
  @override
  String toString() {
    return 'ID: $id - Name: $name';
  }
}

class UserAdapter extends TDAdapter<User> {
  @override
  User fromMap(Map<String, dynamic> map) {
    return User.fromMap(map);
  }

  @override
  int get adapterTypeId => 1; //unique field id

   @override
  int parentId(User value) { //set parentId if needed parent id
    return value.parentId;
  }

   @override
  int getId(User value) { // user id
    return value.id;
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

db.registerAdapterNotExists<User>(UserAdapter());
```

---

## 📦 Box API

`TDBBox<T>` is a typed data container created automatically when you call `db.registerAdapterNotExists<T>()`.
It provides an easy, safe CRUD interface on top of the TDB core.

---

> **Note About `id` Field**
>
> Every model class used with TDB **must include an `id` field**.
> This field will be automatically populated by the database during insertion.
>
> Example:
>
> ```dart
> class User {
>   final int id;     // MUST exist — TDB writes newId into this field
>   final String name;
>
>   User({ this.id = 0, required this.name });
> }
> ```
>
> If `id` is missing:
>
> - The database cannot assign a generated ID back into the object
> - Update / Delete operations may not function correctly
> - Querying by ID becomes impossible

`TDBBox<T>` is a typed data container created automatically when you call `db.registerAdapterNotExists<T>()`.
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

(Similar to Hive)
TDB provides a simple Box API through `TDBBox<T>`.
A Box is automatically created when you call `db.registerAdapterNotExists<T>()`.

### Creating and Using a Box

```dart
final userBox = db.getBox<User>();
```

### Box Methods

`TDBBox<T>` provides convenient CRUD and query helpers:

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

## 🛑 Closing Database

```dart
await db.close();
```

---

## Config Copying With Modifications

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

- Each model **must have a unique `adapterTypeId`**
- Database is **append-only**, so compaction is necessary

---

## 📄 License

MIT
