import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class OnlineMentorsListWidget extends StatelessWidget {
  final DocumentReference lessonId;

  const OnlineMentorsListWidget({
    required this.lessonId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // First, query practice records to ensure that the user has graduated the lesson.
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('practiceRecords')
          .where('isGraduation', isEqualTo: true)
          .where('lessonId', isEqualTo: lessonId)
          // No need to order by location when using online mentors.
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SelectableText('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final practiceRecords = snapshot.data!.docs;

        // Extract the set of user UIDs that have graduated the lesson.
        final menteeUids =
            practiceRecords.map((doc) => doc['menteeUid'] as String).toSet();

        // Remove the current user from the list if desired.
        final applicationState =
            Provider.of<ApplicationState>(context, listen: false);
        menteeUids.remove(applicationState.currentUser!.uid);

        if (menteeUids.isEmpty) {
          return Center(
            child: Text(
              'No online mentors available.',
              style: CustomTextStyles.getBody(context),
            ),
          );
        }

        // Now query the users collection to only fetch those graduated users
        // who are online, have a Calendly URL, and are public.
        final Future<QuerySnapshot<Map<String, dynamic>>> usersFuture =
            FirebaseFirestore.instance
                .collection('users')
                .where('uid', whereIn: menteeUids.toList())
                // This works if you store Calendly URLs as non-empty strings.
                .where('calendlyUrl', isGreaterThan: '')
                .where('isProfilePrivate', isEqualTo: false)
                .limit(5)
                .get();

        return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: usersFuture,
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return SelectableText('Error: ${userSnapshot.error}');
            }

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final userDocs = userSnapshot.data!.docs;

            if (userDocs.isEmpty) {
              return Center(
                child: Text(
                  'No online mentors available at the moment.',
                  style: CustomTextStyles.getBody(context),
                ),
              );
            }

            // Map the documents to your User model.
            final List<User> mentors =
                userDocs.map((doc) => User.fromSnapshot(doc)).toList();

            // Sort mentors by display name (or any other criteria you prefer).
            mentors.sort((a, b) => a.displayName.compareTo(b.displayName));

            double screenWidth = MediaQuery.of(context).size.width;

            return Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: FlexColumnWidth(2)
              },
              children: mentors.map((mentor) {
                return TableRow(
                  children: [
                    TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text('online',
                            style: CustomTextStyles.getBody(context))),
                    // const SizedBox(width: 8),
                    Padding(
                        padding: const EdgeInsets.only(
                            left: 8, right: 8, top: 4, bottom: 4),
                        child: SizedBox(
                            width: 50,
                            height: 50,
                            child: ProfileImageWidgetV2.fromUser(
                              mentor,
                              maxRadius: screenWidth * 0.10 / 2,
                              linkToOtherProfile: true,
                            ))),
                    // const SizedBox(width: 8),
                    TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(mentor.displayName,
                            style: CustomTextStyles.getBody(context))),
                  ],
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
