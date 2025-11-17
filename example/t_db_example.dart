import 'package:t_db/t_db.dart';

void main() async {
  final db = TDB.getInstance();
  await db.open('test.db');

  // print(await db.add({'name': 'Than'}));
  // print(await db.add({'name': 'ThanCoder'}));
  // print(await db.add({'name': 'Mg Mg'}));

  // print(await db.getAll());

  await db.close();
}
