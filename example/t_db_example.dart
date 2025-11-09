import 'package:t_db/t_db.dart';

void main() async {
  final db = UserDB();
  await db.open('user.db');

  await db.insert(User(1, 'Aung', 20));
  await db.insert(User(2, 'Su', 21));
  await db.insert(User(3, 'Min', 22));

  // await db.update(User(2, 'old su and new Su Su', 21));
  print(await db.getAll());

  print('deleted: ${await db.delete(2)}');

  print(await db.getAll());
  // await db.changePath('user2.db');

  // await db.insert(User(1, 'Aung', 20));
  // await db.insert(User(2, 'Su', 21));
  // await db.insert(User(3, 'Min', 22));
  // print('user 2');
  // final users2 = await db.getAll();
  // print(users2);

  // print(users);
  // final user = await db.get(1);
  // print(user);

  // final found = await db.query((u) => u.id == 10,);
  // print(found);
  // await db.compact();
  // print('compact');
  // await db.close();
}

class UserDB extends TDB<User> {
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
