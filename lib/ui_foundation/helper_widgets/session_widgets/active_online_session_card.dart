import 'package:flutter/material.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_cover_image_widget.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

/// A card that displays the details of an active online session.
/// It shows:
/// - A header with "Active Session" and the role (teaching/learning).
/// - The video call URL as a tappable link.
/// - The proposed lesson for the session (tappable to view lesson details).
/// - The partner’s profile (photo and name), tappable to navigate to their profile.
/// - An "End Session" button at the bottom.
class ActiveOnlineSessionCard extends StatelessWidget {
  final OnlineSession session;
  final User currentUser;
  final User partner; // the other user in the session
  final Lesson lesson; // the lesson proposed for the session

  const ActiveOnlineSessionCard({
    super.key,
    required this.session,
    required this.currentUser,
    required this.partner,
    required this.lesson,
  });

  /// Determine the session role for the current user.
  /// If the current user is the mentor, they are teaching; otherwise, learning.
  bool get isTeaching => (currentUser.uid == session.mentorUid);

  String get sessionRoleText => isTeaching ? 'Teaching' : 'Learning';

  /// Builds the header that shows "Active Session" and the role.
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Text(
        'Active Session - $sessionRoleText',
        style: CustomTextStyles.subHeadline.copyWith(color: Colors.white),
      ),
    );
  }

  /// Builds a row for the video URL that is tappable.
  /// When tapped, it opens the URL using url_launcher.
  Widget _buildVideoUrl(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: InkWell(
        onTap: () async {
          // Use url_launcher to open the video URL.
          final url = session.videoCallUrl;
          if (url != null && url.isNotEmpty) {
            // You can call your _launchURL method here.
            // For example:
            // await launchURL(url);
          }
        },
        child: Text(
          session.videoCallUrl ?? 'No URL provided',
          style: CustomTextStyles.getLink(context),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Builds the partner column showing the partner's profile image and display name.
  Widget _buildPartnerColumn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ProfileImageWidgetV2.fromUser(
              partner,
              linkToOtherProfile: true,
            ),
          ),
          SizedBox(height: 8),
          Text(
            partner.displayName,
            style: CustomTextStyles.getBody(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the lesson column showing the proposed lesson.
  /// The lesson is tappable and navigates to the lesson detail page.
  Widget _buildLessonColumn(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to the lesson detail page.
        LessonDetailArgument.goToLessonDetailPage(context, lesson.id!);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (lesson.coverFireStoragePath != null)
            Align(
              alignment: Alignment.topRight,
              child: LessonCoverImageWidget(lesson.coverFireStoragePath),
            ),
          SizedBox(height: 8),
          Text(
            lesson.title,
            style: CustomTextStyles.getBody(context),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds the main content of the card.
  /// It arranges the partner profile column and the lesson column side by side.
  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: _buildPartnerColumn(context),
          ),
          Flexible(
            flex: 2,
            child: _buildLessonColumn(context),
          ),
        ],
      ),
    );
  }

  /// Builds the action button that ends the session.
  // Widget _buildEndSessionButton(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: ElevatedButton.icon(
  //       style: ElevatedButton.styleFrom(
  //         primary: Colors.red,
  //         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
  //       ),
  //       icon: Icon(Icons.stop),
  //       label: Text('End Session'),
  //       onPressed: () {
  //         // Implement your session termination logic.
  //         // For example: call a method to end the session.
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          _buildVideoUrl(context),
          _buildMainContent(context),
          // _buildEndSessionButton(context),
        ],
      ),
    );
  }
}
