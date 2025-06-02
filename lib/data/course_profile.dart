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

  int defaultTeachableItemDurationInMinutes;
  int? totalCourseDurationInMinutes;
  int instructionalTimePercent;
  int? sessionCount;
  int? sessionDurationInMinutes;

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
    this.defaultTeachableItemDurationInMinutes = 15,
    this.totalCourseDurationInMinutes,
    this.instructionalTimePercent = 75,
    this.sessionCount,
    this.sessionDurationInMinutes,
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
      defaultTeachableItemDurationInMinutes: data['defaultTeachableItemDurationInMinutes'] as int? ?? 15,
      totalCourseDurationInMinutes: data['totalCourseDurationInMinutes'] as int?,
      instructionalTimePercent: data['instructionalTimePercent'] as int? ?? 75,
      sessionCount: data['sessionCount'] as int?,
      sessionDurationInMinutes: data['sessionDurationInMinutes'] as int?,
      createdAt: data['createdAt'] as Timestamp?,
      modifiedAt: data['modifiedAt'] as Timestamp?,
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
      'defaultTeachableItemDurationInMinutes': defaultTeachableItemDurationInMinutes,
      'totalCourseDurationInMinutes': totalCourseDurationInMinutes,
      'instructionalTimePercent': instructionalTimePercent,
      'sessionCount': sessionCount,
      'sessionDurationInMinutes': sessionDurationInMinutes,
      'createdAt': createdAt,
      'modifiedAt': modifiedAt,
    };
  }
}
