import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data_support/entity_sync.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data_support/lesson_sync.dart';

class LevelSync extends EntitySync<Level> {

  final LessonSync _lessonSync;

  LevelSync(Transaction transaction)
      : _lessonSync = LessonSync(transaction),
        super('levels', transaction);

  @override
  Future<void> loadFromDb() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await db.collection(collectionName).get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> levelSnapshot
        in querySnapshot.docs) {
      var level = Level.fromQuerySnapshot(levelSnapshot);
      rawIdToDbEntity[levelSnapshot.id] = level;
    }

    // Initiate sync for lesson children.
    await _lessonSync.loadFromDb();
  }

  @override
  Level loadFromJson(Map<String, dynamic> jsonEntity, String fullParentId) {
    return Level.fromJson(jsonEntity);
  }

  @override
  bool compareEntity(Level dbType, Level jsonType, int newSortOrder) {
    if (enableDebug) {
      print(
          ' EQ: course ${jsonType.courseId == dbType.courseId}, '
              'title ${jsonType.title == dbType.title}, '
              'description ${jsonType.description == dbType.description}, '
              'sortOrder ${newSortOrder == dbType.sortOrder}');
    }
    return (dbType.courseId.path == jsonType.courseId.path) &&
        (dbType.title == jsonType.title) &&
        (dbType.description == jsonType.description) &&
        (dbType.sortOrder == newSortOrder);
  }

  @override
  String createNewEntity(Level jsonType, String fullParentId, int newSortOrder) {
    var ref = db.collection(collectionName).doc();
    transaction.set(ref, <String, dynamic>{
      'courseId': jsonType.courseId,
      'title': jsonType.title,
      'description': jsonType.description,
      'sortOrder': newSortOrder,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    });

    return ref.id;
  }

  @override
  void updateEntity(
      Level dbType, Level jsonType, String fullParentId, int sortOrder) {
    var docRef = createRef(dbType.id!);
    transaction.set(
        docRef,
        <String, dynamic>{
          'courseId': jsonType.courseId,
          'title': jsonType.title,
          'description': jsonType.description,
          'sortOrder': sortOrder,
          'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
        },
        SetOptions(merge: true));
  }

  @override
  Future<void> handleChildren(
      Map<String, dynamic> currentJson, Level? dbType, String? newLevelRawId, bool isLastInvocation) async {
    String fullId;
    if (dbType != null) {
      fullId = '/$collectionName/${dbType.id}';
    } else {
      fullId = '/$collectionName/$newLevelRawId';
    }
    List<dynamic>? children = currentJson['lessons'];

    // print('Looking at  level\'s children ${children?.length}');
    if (children != null) {
      print('handling level\'s children.' + fullId);
      await _lessonSync.sync(children, fullId, isLastInvocation);
    }
  }
}
