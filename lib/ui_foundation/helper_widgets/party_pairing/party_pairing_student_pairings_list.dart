import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/download_url_cache_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_style.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class PartyPairingStudentPairingsList extends StatefulWidget {
  const PartyPairingStudentPairingsList({super.key});

  @override
  State<PartyPairingStudentPairingsList> createState() =>
      _PartyPairingStudentPairingsListState();
}

class _PartyPairingStudentPairingsListState
    extends State<PartyPairingStudentPairingsList> {
  String? _expandedPairingId;

  @override
  Widget build(BuildContext context) {
    return Consumer2<OrganizerSessionState, LibraryState>(
      builder: (context, organizerSessionState, libraryState, child) {
        List<SessionPairing> pairings =
            _getStudentPairings(organizerSessionState);
        List<Lesson> orderedLessons = libraryState.lessons ?? [];
        List<Widget> pairingCards = [];

        for (int index = 0; index < pairings.length; index++) {
          SessionPairing pairing = pairings[index];
          String pairingId =
              pairing.id ?? 'pairing-${pairing.roundNumber}-$index';
          Lesson? lesson = libraryState.findLesson(pairing.lessonId?.id);
          User? mentor = organizerSessionState.getUserById(pairing.mentorId?.id);
          List<User?> learners =
              _buildLearners(pairing, organizerSessionState);
          List<User?> sortedLearners = _sortedLearners(
            organizerSessionState: organizerSessionState,
            orderedLessons: orderedLessons,
            learners: learners,
          );

          pairingCards.add(
            _PartyPairingStudentPairingCard(
              pairingId: pairingId,
              roundNumber: pairing.roundNumber,
              lesson: lesson,
              mentor: mentor,
              learners: sortedLearners,
              isExpanded: _expandedPairingId == pairingId,
              onToggle: () => _toggleExpanded(pairingId),
            ),
          );

          if (index != pairings.length - 1) {
            pairingCards.add(const SizedBox(height: 12));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: pairingCards,
        );
      },
    );
  }

  void _toggleExpanded(String pairingId) {
    setState(() {
      if (_expandedPairingId == pairingId) {
        _expandedPairingId = null;
      } else {
        _expandedPairingId = pairingId;
      }
    });
  }

  List<SessionPairing> _getStudentPairings(
    OrganizerSessionState organizerSessionState,
  ) {
    List<SessionPairing> pairings =
        List<SessionPairing>.from(organizerSessionState.lastRound ?? []);
    List<String> instructorIds = organizerSessionState.sessionParticipants
        .where((participant) => participant.isInstructor)
        .map((participant) => participant.participantId.id)
        .toList();

    return pairings
        .where((pairing) => !_includesInstructor(pairing, instructorIds))
        .toList();
  }

  bool _includesInstructor(
    SessionPairing pairing,
    List<String> instructorIds,
  ) {
    List<String?> pairingIds = [
      pairing.mentorId?.id,
      pairing.menteeId?.id,
      ...pairing.additionalStudentIds.map((student) => student.id),
    ];

    return pairingIds.any((id) => id != null && instructorIds.contains(id));
  }

  List<User?> _buildLearners(
    SessionPairing pairing,
    OrganizerSessionState organizerSessionState,
  ) {
    List<User?> learners = [];
    User? mentee = organizerSessionState.getUserById(pairing.menteeId?.id);
    if (mentee != null) {
      learners.add(mentee);
    }
    for (DocumentReference learnerId in pairing.additionalStudentIds) {
      User? learner = organizerSessionState.getUserById(learnerId.id);
      learners.add(learner);
    }
    return learners;
  }

  List<User?> _sortedLearners({
    required OrganizerSessionState organizerSessionState,
    required List<Lesson> orderedLessons,
    required List<User?> learners,
  }) {
    Map<String, int> lessonIndexById = {
      for (int i = 0; i < orderedLessons.length; i++) orderedLessons[i].id!: i
    };

    List<User?> sortedLearners = List<User?>.from(learners);
    sortedLearners.sort((a, b) => _compareLearners(
          userA: a,
          userB: b,
          organizerSessionState: organizerSessionState,
          lessonIndexById: lessonIndexById,
        ));
    return sortedLearners;
  }

  int _compareLearners({
    required User? userA,
    required User? userB,
    required OrganizerSessionState organizerSessionState,
    required Map<String, int> lessonIndexById,
  }) {
    if (userA == null && userB == null) {
      return 0;
    }
    if (userA == null) {
      return 1;
    }
    if (userB == null) {
      return -1;
    }

    SessionParticipant? participantA =
        organizerSessionState.getParticipantByUserId(userA.id);
    SessionParticipant? participantB =
        organizerSessionState.getParticipantByUserId(userB.id);
    List<int> graduatedA = _graduatedLessonIndexes(
      participantA,
      organizerSessionState,
      lessonIndexById,
    );
    List<int> graduatedB = _graduatedLessonIndexes(
      participantB,
      organizerSessionState,
      lessonIndexById,
    );

    int highestA = graduatedA.isEmpty ? -1 : graduatedA.reduce(max);
    int highestB = graduatedB.isEmpty ? -1 : graduatedB.reduce(max);
    if (highestA != highestB) {
      return highestB.compareTo(highestA);
    }

    if (graduatedA.length != graduatedB.length) {
      return graduatedB.length.compareTo(graduatedA.length);
    }

    DateTime createdA = userA.created.toDate();
    DateTime createdB = userB.created.toDate();
    return createdA.compareTo(createdB);
  }

  List<int> _graduatedLessonIndexes(
    SessionParticipant? participant,
    OrganizerSessionState organizerSessionState,
    Map<String, int> lessonIndexById,
  ) {
    if (participant == null) {
      return [];
    }
    return organizerSessionState
        .getGraduatedLessons(participant)
        .map((lesson) => lessonIndexById[lesson.id] ?? -1)
        .toList();
  }
}

class _PartyPairingStudentPairingCard extends StatefulWidget {
  final String pairingId;
  final int roundNumber;
  final Lesson? lesson;
  final User? mentor;
  final List<User?> learners;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _PartyPairingStudentPairingCard({
    required this.pairingId,
    required this.roundNumber,
    required this.lesson,
    required this.mentor,
    required this.learners,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  State<_PartyPairingStudentPairingCard> createState() =>
      _PartyPairingStudentPairingCardState();
}

class _PartyPairingStudentPairingCardState
    extends State<_PartyPairingStudentPairingCard> {
  String? _coverPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadCoverPhoto();
  }

  @override
  void didUpdateWidget(covariant _PartyPairingStudentPairingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson?.coverFireStoragePath !=
        widget.lesson?.coverFireStoragePath) {
      _loadCoverPhoto();
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? image =
        (_coverPhotoUrl == null) ? null : NetworkImage(_coverPhotoUrl!);
    Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: widget.isExpanded
          ? _buildExpandedContent(context)
          : _buildCollapsedContent(context),
    );

    if (widget.isExpanded) {
      return BackgroundImageCard(
        image: image,
        style: const BackgroundImageStyle(
          washOpacity: 0.85,
          washColor: Colors.white,
          desaturate: 0.3,
          blurSigma: 1.5,
        ),
        child: content,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: content,
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoundAndLessonRow(context),
              const SizedBox(height: 12),
              _buildUserTable(context),
            ],
          ),
        ),
        _buildExpandButton(),
      ],
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCollapsedRow(context)),
        _buildExpandButton(),
      ],
    );
  }

  Widget _buildExpandButton() {
    return IconButton(
      onPressed: widget.onToggle,
      icon: Icon(widget.isExpanded
          ? Icons.arrow_drop_up
          : Icons.arrow_drop_down),
      color: Colors.grey,
      tooltip: widget.isExpanded ? 'Collapse pairing' : 'Expand pairing',
    );
  }

  Widget _buildRoundAndLessonRow(BuildContext context) {
    Lesson? lesson = widget.lesson;
    String roundPrefix = 'Round ${widget.roundNumber}';

    if (lesson == null) {
      return Text(
        '$roundPrefix - Lesson not assigned',
        style: CustomTextStyles.subHeadline,
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('$roundPrefix - ', style: CustomTextStyles.subHeadline),
        InkWell(
          onTap: () => LessonDetailArgument.goToLessonDetailPage(
            context,
            lesson.id!,
          ),
          child: Text(
            lesson.title,
            style: CustomTextStyles.subHeadline
                .copyWith(decoration: TextDecoration.underline),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsedRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStudentColumn(context, widget.mentor),
        const SizedBox(width: 8),
        Icon(Icons.arrow_right_alt_rounded, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _buildLearnerColumns(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _buildLessonLink(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildLearnerColumns(BuildContext context) {
    if (widget.learners.isEmpty) {
      return [_buildStudentColumn(context, null)];
    }

    return [
      for (User? learner in widget.learners)
        _buildStudentColumn(context, learner)
    ];
  }

  Widget _buildLessonLink(BuildContext context) {
    Lesson? lesson = widget.lesson;
    if (lesson == null) {
      return Text(
        'Lesson not assigned',
        style: CustomTextStyles.getBody(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return InkWell(
      onTap: () =>
          LessonDetailArgument.goToLessonDetailPage(context, lesson.id!),
      child: Text(
        lesson.title,
        style: CustomTextStyles.getBody(context)
            ?.copyWith(decoration: TextDecoration.underline),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildUserTable(BuildContext context) {
    List<TableRow> learnerRows = _buildLearnerRows(context);

    return Table(
      columnWidths: const {0: IntrinsicColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _buildUserTableRow(
          context: context,
          label: 'Mentor:',
          user: widget.mentor,
          bottomPadding: learnerRows.isEmpty ? 0 : 12,
        ),
        ...learnerRows,
      ],
    );
  }

  List<TableRow> _buildLearnerRows(BuildContext context) {
    if (widget.learners.isEmpty) {
      return [
        _buildUserTableRow(
          context: context,
          label: 'Learners:',
          user: null,
        ),
      ];
    }

    return [
      for (int i = 0; i < widget.learners.length; i++)
        _buildUserTableRow(
          context: context,
          label: i == 0 ? 'Learners:' : '',
          user: widget.learners[i],
          bottomPadding: i == widget.learners.length - 1 ? 0 : 8,
        ),
    ];
  }

  TableRow _buildUserTableRow({
    required BuildContext context,
    required String label,
    required User? user,
    double bottomPadding = 0,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Text(label, style: CustomTextStyles.getBodyNote(context)),
        ),
        Padding(
          padding: EdgeInsets.only(left: 12, bottom: bottomPadding),
          child: _buildUserRow(context, user),
        ),
        const SizedBox(),
      ],
    );
  }

  Widget _buildUserRow(BuildContext context, User? user) {
    if (user == null) {
      return Text('<Not assigned>', style: CustomTextStyles.getBody(context));
    }

    return InkWell(
      onTap: () =>
          InstructorClipboardArgument.navigateTo(context, user.id, user.uid),
      child: Row(
        children: [
          ProfileImageWidgetV2.fromUser(
            user,
            key: ValueKey(user.id),
            maxRadius: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user.displayName,
              style: CustomTextStyles.getBody(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentColumn(BuildContext context, User? user) {
    if (user == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Colors.black12,
            child: Icon(Icons.person_outline, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '<Not assigned>',
            style: CustomTextStyles.getBodyNote(context),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return InkWell(
      onTap: () =>
          InstructorClipboardArgument.navigateTo(context, user.id, user.uid),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileImageWidgetV2.fromUser(
            user,
            key: ValueKey(user.id),
            maxRadius: 20,
          ),
          const SizedBox(height: 4),
          Text(
            user.displayName,
            style: CustomTextStyles.getBodyNote(context),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _loadCoverPhoto() async {
    String? path = widget.lesson?.coverFireStoragePath;
    if (path == null) {
      setState(() {
        _coverPhotoUrl = null;
      });
      return;
    }

    try {
      DownloadUrlCacheState cacheState = context.read<DownloadUrlCacheState>();
      String? url = await cacheState.getDownloadUrl(path);
      if (mounted) {
        setState(() {
          _coverPhotoUrl = url;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _coverPhotoUrl = null;
        });
      }
    }
  }
}
