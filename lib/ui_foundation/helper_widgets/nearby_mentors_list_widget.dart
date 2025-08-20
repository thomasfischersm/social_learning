import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

// TODO: Implement, just copied from Gemini
class NearbyMentorsListWidget extends StatelessWidget {
  final DocumentReference lessonId;
  final GeoPoint currentLocation;

  const NearbyMentorsListWidget({
    required this.lessonId,
    required this.currentLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('practiceRecords')
          .where('isGraduation', isEqualTo: true)
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('roughUserLocation')
          .limit(200)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return SelectableText('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final practiceRecords = snapshot.data!.docs;

        final menteeUids =
            practiceRecords.map((doc) => doc['menteeUid']).toSet();

        // Remove the current user from the list.
        ApplicationState applicationState =
            Provider.of<ApplicationState>(context, listen: false);
        menteeUids
            .removeWhere((uid) => uid == applicationState.currentUser!.uid);

        print(
            'Found ${practiceRecords.length} practice records and ${menteeUids.length} mentors for lessonId: $lessonId.id');

        if (menteeUids.isEmpty) {
          return Center(
              child: Text(
            'No nearby student has learned this lesson yet. Reach out to the instructor directly.',
            style: CustomTextStyles.getBody(context),
          ));
        }

        final Future<List<QuerySnapshot<Map<String, dynamic>>>> usersFuture =
            Future.wait([
          FirebaseFirestore.instance
              .collection('users')
              .where('uid', whereIn: menteeUids)
              .where('isGeoLocationEnabled', isEqualTo: true)
              .where('isProfilePrivate', isEqualTo: false)
              .get(),
          FirebaseFirestore.instance
              .collection('users')
              .where('uid', whereIn: menteeUids.toList())
              // This works if you store Calendly URLs as non-empty strings.
              .where('calendlyUrl', isGreaterThan: '')
              .where('isProfilePrivate', isEqualTo: false)
              .limit(5)
              .get()
        ]);

        return FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
          future: usersFuture,
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              print('Error: ${userSnapshot.error}');
              return SelectableText('Error: ${userSnapshot.error}');
            }

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final localUserDocs = userSnapshot.data![0].docs;
            final remoteUserDocs = userSnapshot.data![1].docs;

            final localUsers =
                localUserDocs.map((e) => User.fromSnapshot(e)).toList();

            // Clean up data in case the DB has bad data.
            localUsers.removeWhere((user) => user.location == null);

            List<MentorAndDistance> nearbyMentors = localUsers.map((user) {
              final distance = UserFunctions.haversineDistance(
                currentLocation,
                user.location!,
              );
              return MentorAndDistance(user, distance);
            }).toList();

            // Sort using the fine distance.
            nearbyMentors.sort((a, b) => a.distance!.compareTo(b.distance!));

            final remoteMentors = remoteUserDocs
                .map((e) => MentorAndDistance(User.fromSnapshot(e), null))
                .toList();
            nearbyMentors.insertAll(0, remoteMentors);

            double screenWidth = MediaQuery.of(context).size.width;

            return Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: IntrinsicColumnWidth(),
                2: FlexColumnWidth(2),
                3: IntrinsicColumnWidth(),
              },
              children: nearbyMentors.map((mentor) {
                double? distanceInMiles =
                    UserFunctions.toMiles(mentor.distance);
                String distanceText = distanceInMiles != null
                    ? '${distanceInMiles.toStringAsFixed(0)} miles'
                    : 'Online';
                return TableRow(
                  children: [
                    TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(distanceText,
                            style: CustomTextStyles.getBody(context))),
                    // const SizedBox(width: 8),
                    Padding(
                        padding: const EdgeInsets.only(
                            left: 8, right: 8, top: 4, bottom: 4),
                        child: SizedBox(
                            width: 50,
                            height: 50,
                            child: ProfileImageWidgetV2.fromUser(
                              mentor.user,
                              maxRadius: screenWidth * 0.10 / 2,
                              linkToOtherProfile: true,
                            ))),
                    // const SizedBox(width: 8),
                    TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Text(mentor.user.displayName,
                            style: CustomTextStyles.getBody(context))),
                    if (mentor.distance == null)
                      TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () {
                              UserFunctions.openCalendlyUrl(mentor.user);
                            },
                          ))
                    else
                      const TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: SizedBox.shrink()),
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

class MentorAndDistance {
  final User user;

  // final List<PracticeRecord> practiceRecords; // TODO: Show in the future how often the student has mentored this lesson.
  final double? distance;

  MentorAndDistance(this.user, this.distance /*, this.practiceRecords*/);
}
