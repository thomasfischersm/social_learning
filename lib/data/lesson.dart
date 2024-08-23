import 'package:cloud_firestore/cloud_firestore.dart';

class Lesson {
  String? id;
  DocumentReference courseId;
  DocumentReference? levelId;
  int sortOrder;
  String title;
  String? synopsis;
  String instructions;
  @Deprecated('Use fire storage instead')
  String? cover;
  String? coverFireStoragePath;
  String? recapVideo;
  String? lessonVideo;
  String? practiceVideo;
  @Deprecated('Use Level class instead')
  bool? isLevel;
  String creatorId;
  List<String>? graduationRequirements;

  Lesson(
      this.id,
      this.courseId,
      this.levelId,
      this.sortOrder,
      this.title,
      this.synopsis,
      this.instructions,
      this.cover,
      this.coverFireStoragePath,
      this.recapVideo,
      this.lessonVideo,
      this.practiceVideo,
      this.isLevel,
      this.creatorId,
      this.graduationRequirements);

  Lesson.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        levelId = e.data()['levelId'] as DocumentReference?,
        sortOrder = e.data()['sortOrder'] as int,
        title = e.data()['title'] as String,
        synopsis = e.data()['synopsis'] as String?,
        instructions = e.data()['instructions'] as String,
        cover = e.data()['cover'] as String?,
        coverFireStoragePath = e.data()['coverFireStoragePath'] as String?,
        recapVideo = e.data()['recapVideo'] as String?,
        lessonVideo = e.data()['lessonVideo'] as String?,
        practiceVideo = e.data()['practiceVideo'] as String?,
        isLevel = e.data()['isLevel'] as bool?,
        creatorId = e.data()['creatorId'] as String,
        graduationRequirements =
            e.data()['graduationRequirements'] as List<String>?;

  Lesson.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()?['courseId'] as DocumentReference,
        levelId = e.data()?['levelId'] as DocumentReference?,
        sortOrder = e.data()?['sortOrder'] as int,
        title = e.data()?['title'] as String,
        synopsis = e.data()?['synopsis'] as String?,
        instructions = e.data()?['instructions'] as String,
        cover = e.data()?['cover'] as String?,
        coverFireStoragePath = e.data()?['coverFireStoragePath'] as String?,
        recapVideo = e.data()?['recapVideo'] as String?,
        lessonVideo = e.data()?['lessonVideo'] as String?,
        practiceVideo = e.data()?['practiceVideo'] as String?,
        isLevel = e.data()?['isLevel'] as bool?,
        creatorId = e.data()?['creatorId'] as String,
        graduationRequirements =
            (e.data()?['graduationRequirements'] as List<dynamic>?)
                ?.map((item) => item as String)
                .toList();

  Lesson.fromJson(Map<String, dynamic> json, String fullLevelId)
      : id = json['id'],
        courseId = FirebaseFirestore.instance.doc(json['courseId']),
        levelId =
            FirebaseFirestore.instance.doc(json['levelId'] ?? fullLevelId),
        sortOrder = -1,
        title = json['title'],
        synopsis = json['synopsis'],
        instructions = json['instructions'],
        cover = json['cover'],
        coverFireStoragePath = json['coverFireStoragePath'],
        recapVideo = json['recapVideo'],
        lessonVideo = json['lessonVideo'],
        practiceVideo = json['practiceVideo'],
        isLevel = false,
        creatorId = '',
        graduationRequirements = json['graduationRequirements'];
}
