# `TDB<T>` - Dart File-Based Custom Database

`TDB<T>` သည် Dart နှင့် Flutter အတွက် အသုံးပြုနိုင်သည့် generic, file-based custom database ဖြစ်သည်။  
`TDB<T>` is a generic, file-based custom database suitable for Dart and Flutter applications.

Object-based CRUD operations များအတွက် ဖန်တီးထားပြီး 2GB+ အရွယ်အစား database များကိုလည်း support လုပ်နိုင်သည်။  
It is designed for object-based CRUD operations and supports large databases (2GB+).

---

## Features / အင်္ဂါရပ်များ

- **Generic Type Support / အမျိုးအစား Generic အထောက်အပံ့**  
  Type `T` မည်သည့် object မဆို CRUD operations လုပ်နိုင်သည်။  
  Supports object-based operations for any type `T`.

- **File Storage / ဖိုင်သိုလှောင်မှု**  
  Records များကို binary format ဖြင့်သိမ်းဆည်းထားသည်။  
  Records are stored in binary format.

  `.lock` index file က `id → file offset` mapping ကို ထိန်းသိမ်းပြီး fast access ကို support လုပ်သည်။  
  A separate `.lock` index file keeps `id → file offset` mapping for fast access.

- **Indexing & Auto-Increment IDs / အညွှန်း & Auto-Increment ID**  
  `_index` map က record offsets များကို ထိန်းသိမ်းသည်။  
  The `_index` map maintains record offsets.

  `_lastId` က auto-increment ID ကို track လုပ်သည်။  
  `_lastId` tracks auto-increment IDs.

- **CRUD Operations / CRUD လုပ်ဆောင်ချက်များ**  
  `add(T value)` → record ကို insert လုပ်ပြီး auto-assigned ID နှင့် metadata ကို save လုပ်သည်။  
  `add(T value)` → Inserts a record with an auto-assigned ID and saves metadata.

  `get(int id)` → ID ဖြင့် single record ကို fetch လုပ်သည်။  
  `get(int id)` → Fetches a single record by ID.

  `getAll()` → record အားလုံးကို list အဖြစ် return လုပ်သည်။  
  `getAll()` → Returns all records as a list.

  `getAllLazyStream()` → memory-efficient lazy streaming support  
  `getAllLazyStream()` → Streams records lazily for memory efficiency.

  `update(T value)` → new record ကို append လုပ်ပြီး index ကို update လုပ်သည်။  
  `update(T value)` → Appends a new record and updates the index.

  `delete(int id)` → soft delete (index updated, data file ထဲရှိသေးသည်)  
  `delete(int id)` → Soft deletes a record (index updated, data remains until compaction).

- **Query Support / Query လုပ်ဆောင်ချက်**  
  `query()` → function ဖြင့် records filter လုပ်နိုင်သည်။  
  `query()` → Filters records using a function.

  `queryStream()` → filtered records ကို stream လုပ်၍ရနိုင်သည်။  
  `queryStream()` → Streams filtered records.

- **Compaction / ဖိုင်သန့်စင်မှု**  
  `_maybeCompact()` → database သန့်စင်ရန် အလိုအလျောက်စစ်ဆေးသည်။  
  `_maybeCompact()` → Automatically checks if compaction is needed.

  `compact()` → deleted records များကိုဖယ်ရှားပြီး DB file ကို rebuild လုပ်သည်။  
  `compact()` → Rebuilds the DB file, removing deleted records.

- **File Path Change / ဖိုင်လမ်းကြောင်းပြောင်းခြင်း**  
  `changePath()` → database file လမ်းကြောင်းကို ပြောင်းပြီး meta reload လုပ်နိုင်သည်။  
  `changePath()` → Changes the database file location and reloads meta.

- **Event Listener / အဖြစ်အပျက် နားထောင်သူ**  
  `_listener` → DB ပြောင်းလဲမှု (add, update, delete) ကို subscriber များအား notify လုပ်သည်။  
  `_listener` → Notifies subscribers of DB changes (add, update, delete).

---

## Usage Example (အသုံးပြုနည်း)

```Dart
final db = UserDB();
await db.open('user.db');

// debug log
db.onDebugLog((message) {
  print('[Debug Log]: $message');
});

// Add listener
db.addListener(MyListener());

// add
await db.add(User(1, 'Aung', 20));
await db.add(User(2, 'Su', 21));
await db.add(User(3, 'Min', 22));

// update
await db.update(User(2, 'old su and new Su Su', 21));

// delete
await await db.delete(2)

// change db path
await db.changePath('user2.db');
//get id
final user = await db.get(1);
// get all
final users = await db.getAll();
//query
final found = await db.query((value) => value.id == 10);

// Lazy stream
await for (final u in db.getAllLazyStream()) {
  print(u.name);
}

// db close
await db.close();
```

## Query && All && getOne

```Dart
// nomal
final users = await db.getAll();
final found = await db.query((value) => value.id == 1);
final user = await db.get(1);

// big data size
// all stream
await for (final user in db.getAllLazyStream()) {
print('User: ${user.id} - ${user.name}');
}
// query stream
await for (final user in db.queryStream((value) => value.id == 1)) {
print('User: ${user.id} - ${user.name}');
}

// ✅ Works fine, but single record → 1 element stream
await for (final user in db.getByStream(42)) {
  print('User: ${user.id} - ${user.name}');
}
```

## Adapter or Database Class

```Dart
class UserDB extends TDB<User> {
  // single ton pattern
  static UserDB? _instance;
  UserDB._();
  factory UserDB() {
    return _instance ??= UserDB._();
  }
  @override
  User fromMap(Map<String, dynamic> map) {
    return User.fromMap(map);
  }

  @override
  int getId(User value) {
    return value.id;
  }

  @override
  void setId(User value, int id) {
    value.id = id;
  }

  @override
  Map<String, dynamic> toMap(User value) {
    return value.toMap();
  }
}

class User {
  int id;
  String name;
  int age;

  User(this.id, this.name, this.age);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'age': age};

  factory User.fromMap(Map<String, dynamic> map) =>
      User(map['id'], map['name'], map['age']);
  @override
  String toString() {
    return 'id: $id - name: $name - age:$age\n';
  }
}
```

## Single Ton

```Dart
//singel ton
final db1 = UserDB(); // MyUserDB extends TDB<User>
final db2 = UserDB();
print(identical(db1, db2)); // true → တစ်ခုတည်း instance
```

## Remove deleted records and rebuild file

```Dart
// Remove deleted records and rebuild file
// don't need to used.
await db.compact();
print('compact');
```

## Database Listener

```Dart
final myListener = MyListener();
db.addListener(myListener);

// await db.add(User(1, 'Aung', 20));
// await db.add(User(2, 'Su', 21));
// await db.add(User(3, 'Min', 22));
await db.delete(1);
await db.update(User(5, 'Aung Ko Ko', 20));

final list = await db.getAll();
print(list);

// db close
await db.close();

class MyListener implements TDBEventListener {
  @override
  void onTBDatabaseChanged(TDBEvent event, int? id) {
    print('DB Event: $event, id: $id');
  }
}
```
