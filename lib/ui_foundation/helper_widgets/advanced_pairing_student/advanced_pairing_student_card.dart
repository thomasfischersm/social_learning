import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/helper_widgets/advanced_pairing_student/record_pairing_practice_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_style.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/progress_checkbox.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class AdvancedPairingStudentCard extends StatefulWidget {
  final int roundNumber;
  final Lesson? lesson;
  final User? mentor;
  final List<User?> learners;
  final bool showGraduationCheckboxes;

  const AdvancedPairingStudentCard({
    super.key,
    required this.roundNumber,
    required this.lesson,
    required this.mentor,
    required this.learners,
    required this.showGraduationCheckboxes,
  });

  @override
  State<AdvancedPairingStudentCard> createState() =>
      _AdvancedPairingStudentCardState();
}

class _AdvancedPairingStudentCardState extends State<AdvancedPairingStudentCard> {
  String? _coverPhotoUrl;
  StreamSubscription? _graduationSubscription;
  Map<String, double> _learnerProgress = {};

  @override
  void initState() {
    super.initState();
    _loadCoverPhoto();
    _listenToLearnerProgress();
  }

  @override
  void didUpdateWidget(covariant AdvancedPairingStudentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson?.coverFireStoragePath !=
        widget.lesson?.coverFireStoragePath) {
      _loadCoverPhoto();
    }

    if (_shouldReloadGraduations(oldWidget)) {
      _listenToLearnerProgress();
    }
  }

  @override
  void dispose() {
    _graduationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image =
        (_coverPhotoUrl == null) ? null : NetworkImage(_coverPhotoUrl!);

    return BackgroundImageCard(
      image: image,
      style: const BackgroundImageStyle(
        washOpacity: 0.85,
        washColor: Colors.white,
        desaturate: 0.3,
        blurSigma: 1.5,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round ${widget.roundNumber}',
              style: CustomTextStyles.subHeadline,
            ),
            const SizedBox(height: 8),
            _buildLessonTitle(context),
            const SizedBox(height: 12),
            _buildUserRow(context, 'Mentor', widget.mentor),
            const SizedBox(height: 12),
            ..._buildLearnerRows(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonTitle(BuildContext context) {
    final lesson = widget.lesson;
    if (lesson == null) {
      return Text(
        'Lesson not assigned',
        style: CustomTextStyles.getBody(context),
      );
    }

    return InkWell(
      onTap: () =>
          LessonDetailArgument.goToLessonDetailPage(context, lesson.id!),
      child: Text(
        lesson.title,
        style: CustomTextStyles.headline,
      ),
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    String label,
    User? user, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Text('$label:', style: CustomTextStyles.getBodyNote(context)),
              const SizedBox(width: 12),
              if (user != null)
                Flexible(
                  child: Row(
                    children: [
                      ProfileImageWidgetV2.fromUser(
                        user,
                        maxRadius: 18,
                        linkToOtherProfile: true,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          user.displayName,
                          style: CustomTextStyles.getBody(context),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text('<Not assigned>', style: CustomTextStyles.getBody(context)),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing,
        ],
      ],
    );
  }

  List<Widget> _buildLearnerRows(BuildContext context) {
    final learners = widget.learners;
    if (learners.isEmpty) {
      return [
        _buildUserRow(context, 'Learner', null),
      ];
    }

    return [
      for (final learner in learners)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildUserRow(
            context,
            'Learner',
            learner,
            trailing: _buildLearnerProgress(learner),
          ),
        ),
    ];
  }

  Widget? _buildLearnerProgress(User? learner) {
    if (!widget.showGraduationCheckboxes || learner == null) {
      return null;
    }

    final lesson = widget.lesson;
    if (lesson == null) {
      return null;
    }

    final progressValue = _learnerProgress[learner.uid] ?? 0.0;
    return ProgressCheckbox(
      value: progressValue,
      onTap: () => _openRecordDialog(lesson, learner),
    );
  }

  Future<void> _loadCoverPhoto() async {
    final path = widget.lesson?.coverFireStoragePath;
    if (path == null) {
      setState(() {
        _coverPhotoUrl = null;
      });
      return;
    }

    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      if (!mounted) {
        return;
      }
      setState(() {
        _coverPhotoUrl = url;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _coverPhotoUrl = null;
      });
    }
  }

  void _listenToLearnerProgress() {
    _graduationSubscription?.cancel();

    final bool canShowProgress = widget.showGraduationCheckboxes;
    final lessonId = widget.lesson?.id;
    final learnerUids =
        widget.learners.whereType<User>().map((learner) => learner.uid).toList();

    if (!canShowProgress || lessonId == null || learnerUids.isEmpty) {
      setState(() {
        _learnerProgress = {};
      });
      return;
    }

    _graduationSubscription = PracticeRecordFunctions.listenLessonPracticeRecords(
      lessonId: lessonId,
      menteeUids: learnerUids,
    ).listen((records) {
      final lesson = widget.lesson;
      if (lesson == null) {
        return;
      }

      final recordsByLearner = <String, List<PracticeRecord>>{};
      for (final record in records) {
        recordsByLearner.putIfAbsent(record.menteeUid, () => []).add(record);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _learnerProgress = {
          for (final learnerId in learnerUids)
            learnerId: PracticeRecordFunctions.getLearnerLessonProgress(
              lesson: lesson,
              practiceRecords: recordsByLearner[learnerId] ?? const [],
            ),
        };
      });
    });
  }

  bool _shouldReloadGraduations(
    AdvancedPairingStudentCard oldWidget,
  ) {
    final didChangeLessonId = oldWidget.lesson?.id != widget.lesson?.id;
    final didChangeShowProgress =
        oldWidget.showGraduationCheckboxes != widget.showGraduationCheckboxes;

    final oldLearnerIds = oldWidget.learners
        .whereType<User>()
        .map((learner) => learner.uid)
        .toList();
    final newLearnerIds = widget.learners
        .whereType<User>()
        .map((learner) => learner.uid)
        .toList();

    final didChangeLearners = oldLearnerIds.length != newLearnerIds.length ||
        !oldLearnerIds.every(newLearnerIds.contains);

    return didChangeLessonId ||
        didChangeShowProgress ||
        didChangeLearners;
  }

  void _openRecordDialog(Lesson lesson, User learner) {
    RecordPairingPracticeDialog.show(context, lesson, learner);
  }
}
