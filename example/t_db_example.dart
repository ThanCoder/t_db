import 'package:t_db/t_db.dart';

void main() async {
  // print(await TDB.readHeader('test.db'));

  final db = TDB.getInstance();

  await db.open(
    // '/home/thancoder/Downloads/Apyar App/apyar.db',
    'test.db',
    config: DBConfig.getDefault().copyWith(saveLocalDBLock: false),
  );
  db.setAdapter<User>(UserAdapter());

  await db.compact();

  final userBox = db.getBox<User>();

  // await userBox.add(User(name: 'user one'));
  // await userBox.add(User(name: 'user two'));
  // await userBox.add(User(name: 'user three'));
  // await userBox.deleteById(3);
  // await userBox.updateById(3, User(name: 'three update'));

  for (var user in await userBox.getAll()) {
    print(user);
  }
  print(db.getUniqueFieldIdList);

  print('magic: ${db.magic}');
  print('type: ${db.type}');
  print('version: ${db.version}');
  print('lastId: ${db.lastId}');
  print('deletedCount: ${db.deletedCount}');
  print('deletedSize: ${db.deletedSize}');
  await db.close();
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

  @override
  int getId(User value) {
    return value.autoId;
  }
}

class CarAdapter extends TDAdapter<Car> {
  @override
  getFieldValue(Car value, String fieldName) {
    if (fieldName == 'userId') return value.userId;
  }

  @override
  Car fromMap(Map<String, dynamic> map) {
    return Car.fromMap(map);
  }

  @override
  int getUniqueFieldId() {
    return 2;
  }

  @override
  Map<String, dynamic> toMap(Car value) {
    return value.toMap();
  }

  @override
  int getId(Car value) {
    return value.autoId;
  }
}

class User {
  final int autoId;
  final String name;
  User({this.autoId = 0, required this.name});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'autoId': autoId, 'name': name};
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(autoId: map['autoId'] as int, name: map['name'] as String);
  }
  @override
  String toString() => '''User(autoId: $autoId, name: $name)''';

  User copyWith({int? autoId, String? name}) {
    return User(autoId: autoId ?? this.autoId, name: name ?? this.name);
  }
}

class Car {
  final int autoId;
  final int userId;
  final String name;
  Car({this.autoId = 0, required this.userId, required this.name});

  @override
  String toString() {
    return 'ID: $autoId - Name: $name userId: $userId';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'autoId': autoId, 'userId': userId, 'name': name};
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      autoId: map['autoId'] as int,
      userId: map['userId'] as int,
      name: map['name'] as String,
    );
  }
}
