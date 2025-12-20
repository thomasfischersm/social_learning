import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_style.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class AdvancedPairingStudentCard extends StatefulWidget {
  final int roundNumber;
  final Lesson? lesson;
  final User? mentor;
  final List<User?> learners;

  const AdvancedPairingStudentCard({
    super.key,
    required this.roundNumber,
    required this.lesson,
    required this.mentor,
    required this.learners,
  });

  @override
  State<AdvancedPairingStudentCard> createState() =>
      _AdvancedPairingCardState();
}

class _AdvancedPairingCardState extends State<AdvancedPairingStudentCard> {
  String? _coverPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadCoverPhoto();
  }

  @override
  void didUpdateWidget(covariant AdvancedPairingStudentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson?.coverFireStoragePath !=
        widget.lesson?.coverFireStoragePath) {
      _loadCoverPhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    final image =
        (_coverPhotoUrl == null) ? null : NetworkImage(_coverPhotoUrl!);

    return BackgroundImageCard(
      image: image,
      style: const BackgroundImageStyle(
        washOpacity: 0.75,
        washColor: Colors.white,
        desaturate: 0.2,
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

  Widget _buildUserRow(BuildContext context, String label, User? user) {
    return Row(
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
          child: _buildUserRow(context, 'Learner', learner),
        ),
    ];
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
}
