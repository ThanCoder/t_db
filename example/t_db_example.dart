import 'package:t_db/t_db.dart';

void main() async {
  final db = TDB.getInstance();
  await db.open(
    'changed.db',
    config: DBConfig.getDefault().copyWith(saveLocalDBLock: false),
  );
  await db.changePath('test.db');

  db.setAdapter<User>(UserAdapter());
  db.setAdapter<Car>(CarAdapter());

  // db.addListener(DBListener());

  final box = db.getBox<User>();
  final carBox = db.getBox<Car>();
  box.addListener(BoxListener());

  print(await box.getAll());
  print(await carBox.getAll());
  // final res = await carBox.queryAll((value) => value.name.endsWith('Test'),);
  // print(res);
  // carBox.getAllStream().listen((data) {
  //   print(data);
  // });

  // print(await db.getById(4));

  print('lastId: ${db.getLastId}');
  print('deletedCount: ${db.getDeletedCount}');
  print('deletedSize: ${db.getDeletedSize}');
  print('uniqueFieldIdList: ${db.getUniqueFieldIdList}');

  await db.close();
}

class BoxListener implements TBoxEventListener {
  @override
  void onTBoxDatabaseChanged(TBEventType event, int? id) {
    print('[BoxListener]: event:$event - id: $id');
  }
}

class DBListener implements TBEventListener {
  @override
  void onTBDatabaseChanged(TBEventType event, int uniqueFieldId, int? id) {
    print(
      '[DBListener]: event:$event - uniqueFieldId: $uniqueFieldId - id: $id',
    );
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

class CarAdapter extends TDAdapter<Car> {
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
  String toString() {
    return 'ID: $autoId - Name: $name';
  }
}

class Car {
  final int autoId;
  final String name;
  Car({this.autoId = 0, required this.name});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'autoId': autoId, 'name': name};
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(autoId: map['autoId'] as int, name: map['name'] as String);
  }
  @override
  String toString() {
    return 'ID: $autoId - Name: $name';
  }
}
