import 'package:cloud_firestore/cloud_firestore.dart';

@Deprecated("Maybe not a good idea")
class LessonStatus {
  String id;
  String lessonId;
  String studentUid;
  bool isGraduated;
  int practiceCount;
  int teachCount;

  LessonStatus(this.id, this.lessonId, this.studentUid, this.isGraduated,
      this.practiceCount, this.teachCount);

  LessonStatus.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        lessonId = e.data()['lessonId'] as String,
        studentUid = e.data()['studentUid'] as String,
        isGraduated = e.data()['isGraduated'] as bool,
        practiceCount = e.data()['practiceCount'] as int,
        teachCount = e.data()['teachCount'] as int;
}
