import 'package:cloud_firestore/cloud_firestore.dart';

class CourseProfile {
  final String? id;
  final DocumentReference courseId;

  String? topicAndFocus;
  String? scheduleAndDuration;
  String? targetAudience;
  String? groupSizeAndFormat;
  String? location;
  String? howStudentsJoin;
  String? toneAndApproach;
  String? anythingUnusual;

  final Timestamp? createdAt;
  final Timestamp? modifiedAt;

  CourseProfile({
    this.id,
    required this.courseId,
    this.topicAndFocus,
    this.scheduleAndDuration,
    this.targetAudience,
    this.groupSizeAndFormat,
    this.location,
    this.howStudentsJoin,
    this.toneAndApproach,
    this.anythingUnusual,
    this.createdAt,
    this.modifiedAt,
  });

  factory CourseProfile.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    return CourseProfile(
      id: snapshot.id,
      courseId: data['courseId'] as DocumentReference,
      topicAndFocus: data['topicAndFocus'] as String?,
      scheduleAndDuration: data['scheduleAndDuration'] as String?,
      targetAudience: data['targetAudience'] as String?,
      groupSizeAndFormat: data['groupSizeAndFormat'] as String?,
      location: data['location'] as String?,
      howStudentsJoin: data['howStudentsJoin'] as String?,
      toneAndApproach: data['toneAndApproach'] as String?,
      anythingUnusual: data['anythingUnusual'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      modifiedAt: data['modifiedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'topicAndFocus': topicAndFocus,
      'scheduleAndDuration': scheduleAndDuration,
      'targetAudience': targetAudience,
      'groupSizeAndFormat': groupSizeAndFormat,
      'location': location,
      'howStudentsJoin': howStudentsJoin,
      'toneAndApproach': toneAndApproach,
      'anythingUnusual': anythingUnusual,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}
