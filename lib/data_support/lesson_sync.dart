import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data_support/entity_sync.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class LessonSync extends EntitySync<Lesson> {
  LessonSync(Transaction transaction) : super('lessons', transaction);

  @override
  Future<void> loadFromDb() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await db.collection(collectionName).get();

    for (QueryDocumentSnapshot<Map<String, dynamic>> lessonSnapshot
        in querySnapshot.docs) {
      var lesson = Lesson.fromQuerySnapshot(lessonSnapshot);
      rawIdToDbEntity[lessonSnapshot.id] = lesson;
    }
  }

  @override
  Lesson loadFromJson(Map<String, dynamic> jsonEntity, String fullParentId) {
    return Lesson.fromJson(jsonEntity, fullParentId);
  }

  @override
  bool compareEntity(Lesson dbType, Lesson jsonType, int newSortOrder) {
    if (enableDebug) {
      print(' EQ (lesson): course ${jsonType.courseId == dbType.courseId}, '
          'title ${jsonType.title == dbType.title}, '
          'synopsis ${jsonType.synopsis == dbType.synopsis}, '
          'instructions ${jsonType.instructions == dbType.instructions}, '
          'sortOrder ${newSortOrder == dbType.sortOrder}');
    }
    return (dbType.courseId.path == jsonType.courseId.path) &&
        (dbType.levelId!.path == jsonType.levelId!.path) &&
        (dbType.title == jsonType.title) &&
        (dbType.synopsis == jsonType.synopsis) &&
        (dbType.instructions == jsonType.instructions) &&
        (dbType.cover == jsonType.cover) &&
        (dbType.recapVideo == jsonType.recapVideo) &&
        (dbType.lessonVideo == jsonType.lessonVideo) &&
        (dbType.practiceVideo == jsonType.practiceVideo) &&
        (dbType.sortOrder == newSortOrder);
  }
  String? cover;
  String? recapVideo;
  String? lessonVideo;
  String? practiceVideo;
  @override
  String createNewEntity(Lesson jsonType, String fullParentId, int newSortOrder) {
    var ref = db.collection(collectionName).doc();
    String rawParentId = fullParentId.substring(fullParentId.lastIndexOf('/') + 1);
    transaction.set(ref, <String, dynamic>{
      'courseId': jsonType.courseId,
      'levelId': db.collection('levels').doc(rawParentId),
      'sortOrder': newSortOrder,
      'title': jsonType.title,
      'synopsis': jsonType.synopsis,
      'instructions': jsonType.instructions,
      'cover': jsonType.cover,
      'recapVideo': jsonType.recapVideo,
      'lessonVideo': jsonType.lessonVideo,
      'practiceVideo': jsonType.practiceVideo,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isLevel': false,
      'graduationRequirements': jsonType.graduationRequirements,
    });

    return ref.id;
  }

  @override
  void updateEntity(
      Lesson dbType, Lesson jsonType, String fullParentId, int sortOrder) {
    print('Update lesson with level id $fullParentId');
    var docRef = createRef(dbType.id!);
    String rawParentId = fullParentId.substring(fullParentId.lastIndexOf('/') + 1);
    transaction.set(
        docRef,
        <String, dynamic>{
          'courseId': jsonType.courseId,
          'levelId': db.collection('levels').doc(rawParentId),
          'sortOrder': sortOrder,
          'title': jsonType.title,
          'synopsis': jsonType.synopsis,
          'instructions': jsonType.instructions,
          'cover': jsonType.cover,
          'recapVideo': jsonType.recapVideo,
          'lessonVideo': jsonType.lessonVideo,
          'practiceVideo': jsonType.practiceVideo,
          'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
          'isLevel': false,
          'graduationRequirements': jsonType.graduationRequirements,
        },
        SetOptions(merge: true));
  }

  @override
  Future<void> handleChildren(
      Map<String, dynamic> currentJson, Lesson? dbType, String? newLessonRawId, bool isLastInvocation) async {
    // There are no children.
  }
}
