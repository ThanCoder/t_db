import 'package:t_db/t_db.dart';

void main() async {
  final db = TDB.getInstance();
  db.registerAdapterNotExists<Post>(PostAdapter());
  db.registerAdapterNotExists<PostContent>(PostContentAdapter());

  await db.open('test.db');

  final box = db.getBox<Post>();
  final content = db.getBox<PostContent>();

  // await box.add(Post(title: 'post one'));
  // await box.add(Post(title: 'post two'));
  // await box.add(Post(title: 'post three'));

  // await box.deleteById(4, childItemsWillDelete: true);
  // final list = await box.getAll();

  // await box.updateById(6, list.first.copyWith(title: 'updated post three'));

  for (var post in await box.getAll()) {
    print('id: ${post.id} - title: ${post.title}');
    // await content.add(
    //   PostContent(postId: post.id, content: 'Content ${post.title}'),
    // );
  }
  for (var co in await content.getAll()) {
    print('id: ${co.id} - parentId: ${co.postId} - content: ${co.content}');
  }
  // print(await box.getAll());

  print('lastIndex: ${db.lastIndex}');
  print('magic: ${db.magic}');
  print('version: ${db.version}');
  print('deletedCount: ${db.deletedCount}');
  print('deletedSize: ${db.deletedSize}');

  await db.close();
}

class PostAdapter extends TDBAdapter<Post> {
  @override
  int get adapterTypeId => 1;

  @override
  Post fromMap(Map<String, dynamic> map) {
    return Post.fromJson(map);
  }

  @override
  int getId(Post value) {
    return value.id;
  }

  @override
  Map<String, dynamic> toMap(Post value) {
    return value.toJson();
  }
}

class PostContentAdapter extends TDBAdapter<PostContent> {
  @override
  int get adapterTypeId => 2;

  @override
  int parentId(PostContent value) {
    return value.postId;
  }

  @override
  PostContent fromMap(Map<String, dynamic> map) {
    return PostContent.fromJson(map);
  }

  @override
  int getId(PostContent value) {
    return value.id;
  }

  @override
  Map<String, dynamic> toMap(PostContent value) {
    return value.toJson();
  }
}

class Post {
  final int id; //auto generated id
  final String title;

  const Post({this.id = 0, required this.title});

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title};
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(id: json['id'], title: json['title']);
  }

  Post copyWith({int? id, String? title}) {
    return Post(id: id ?? this.id, title: title ?? this.title);
  }
}

class PostContent {
  final int id; //auto generated id
  final int postId;
  final String content;

  const PostContent({this.id = 0, required this.postId, required this.content});

  Map<String, dynamic> toJson() {
    return {'id': id, 'postId': postId, 'content': content};
  }

  factory PostContent.fromJson(Map<String, dynamic> json) {
    return PostContent(
      id: json['id'],
      postId: json['postId'],
      content: json['content'],
    );
  }
}
