import 'package:t_db/src/t_db_event_listener.dart';
import 'package:t_db/t_db.dart';

void main() async {
  //
  final db = UserDB();
  await db.open('user.db');
  // debug log
  db.onDebugLog((message) {
    print('[Debug Log]: $message');
  });

  final myListener = MyListener();
  db.addListener(myListener);

  // await db.add(User(1, 'Aung', 20));
  // await db.add(User(2, 'Su', 21));
  // await db.add(User(3, 'Min', 22));
  await db.delete(1);
  // await db.update(User(5, 'Aung Ko Ko', 20));

  final list = await db.getAll();
  print(list);

  // db close
  await db.close();
}

class MyListener implements TDBEventListener {
  @override
  void onTBDatabaseChanged(TDBEvent event, int? id) {
    print('DB Event: $event, id: $id');
  }
}

class UserDB extends TDB<User> {
  // singel ton pattern
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
