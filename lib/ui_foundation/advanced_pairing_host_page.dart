import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/graduation_status.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/advanced_pairing/student_session_history_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/circled_letter_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/sticky_header_table.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/util/text_width_util.dart';
import 'package:collection/collection.dart';

class AdvancedPairingHostPage extends StatefulWidget {
  const AdvancedPairingHostPage({super.key});

  @override
  State<AdvancedPairingHostPage> createState() =>
      _AdvancedPairingHostPageState();
}

class _AdvancedPairingHostPageState extends State<AdvancedPairingHostPage> {
  static const double _lessonCellWidth = 44;
  static const double _rowHeight = 44;
  static const double _levelHeaderHeight = 32;
  static const double _lessonHeaderHeight = 36;
  static const double _bottomPanelHeight = 96;

  bool _isHorizontalScrolled = false;
  int _roundCounter = 1;
  late List<_StudentGroup> _groups = [];
  List<_StudentGroup> _lastLoadedGroups = [];

  @override
  void initState() {
    super.initState();
    OrganizerSessionState organizerSessionState =
        context.read<OrganizerSessionState>();
    organizerSessionState.addListener(_maybeLoadExistingPairings);

    _maybeLoadExistingPairings();
  }

  @override
  void dispose() {
    OrganizerSessionState organizerSessionState =
        context.read<OrganizerSessionState>();
    organizerSessionState.removeListener(_maybeLoadExistingPairings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          Consumer2<OrganizerSessionState, LibraryState>(
            builder: (context, organizerSessionState, libraryState, child) {
              List<Lesson> lessons = libraryState.lessons ?? [];
              final levelGroups =
                  _buildLevelGroups(lessons, libraryState.levels);
              final participants =
                  _sortedParticipants(organizerSessionState, lessons);
              double learnToTeachRatio =
                  organizerSessionState.getLearnTeachRatio();

              return Column(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomUiConstants.getTextPadding(Text(
                          'Advanced Pairing',
                          style: CustomTextStyles.headline,
                        )),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final nameColumnWidth = _calculateNameColumnWidth(
                                context,
                                constraints,
                                participants,
                                organizerSessionState,
                              );

                              const tableGap = 4.0;

                              final minTableBodyWidth = max(
                                0.0,
                                constraints.maxWidth -
                                    nameColumnWidth -
                                    tableGap,
                              );

                              return StickyHeaderTable(
                                rowCount: participants.length,
                                columnCount: lessons.length,
                                rowHeaderWidth: nameColumnWidth,
                                columnWidth: _lessonCellWidth,
                                rowHeight: _rowHeight,
                                headerHeight:
                                    _levelHeaderHeight + _lessonHeaderHeight,
                                gap: tableGap,
                                minTableBodyWidth: minTableBodyWidth,
                                onHorizontalScrollOffsetChanged: (offset) {
                                  final isScrolled = offset.abs() > 4;
                                  if (_isHorizontalScrolled != isScrolled) {
                                    setState(() {
                                      _isHorizontalScrolled = isScrolled;
                                    });
                                  }
                                },
                                buildCorner: (context, width, _) => Column(
                                  children: [
                                    Container(
                                      height: _levelHeaderHeight,
                                      width: width,
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                    ),
                                    Container(
                                      height: _lessonHeaderHeight,
                                      width: width,
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Student',
                                        style: CustomTextStyles.getBodyNote(
                                                context)
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                buildColumnHeader: (context, _) => Column(
                                  children: [
                                    SizedBox(
                                      height: _levelHeaderHeight,
                                      child: Row(
                                        children: [
                                          for (final group in levelGroups)
                                            Container(
                                              width: _lessonCellWidth *
                                                  group.lessonCount,
                                              height: _levelHeaderHeight,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              alignment: Alignment.centerLeft,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surface,
                                              child: Text(
                                                'Level ${group.levelNumber}: ${group.levelTitle}',
                                                style: CustomTextStyles
                                                        .getBodyNote(context)
                                                    ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: _lessonHeaderHeight,
                                      child: Row(
                                        children: [
                                          for (int i = 0;
                                              i < lessons.length;
                                              i++)
                                            _buildLessonHeaderCell(
                                                context, lessons[i], i + 1),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                buildRowHeader: (context, rowIndex) {
                                  final participant = participants[rowIndex];
                                  return _buildNameCell(
                                    context,
                                    participant,
                                    learnToTeachRatio,
                                    organizerSessionState,
                                    libraryState,
                                    nameColumnWidth,
                                  );
                                },
                                buildCell: (context, rowIndex, columnIndex) {
                                  final participant = participants[rowIndex];
                                  final lesson = lessons[columnIndex];

                                  return Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                          width: 0.5,
                                        ),
                                        bottom: BorderSide(
                                          color: Theme.of(context).dividerColor,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: _buildLessonCellContent(
                                      context,
                                      organizerSessionState,
                                      participant,
                                      lesson,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  _buildGroupPanel(context, libraryState),
                ],
              );
            },
          ),
          enableCourseLoadingGuard: true,
          enableScrolling: false,
        ),
      ),
    );
  }

  double _calculateNameColumnWidth(
    BuildContext context,
    BoxConstraints constraints,
    List<SessionParticipant> participants,
    OrganizerSessionState organizerSessionState,
  ) {
    final textStyle = CustomTextStyles.getBodyNote(context);
    final fontSize = textStyle?.fontSize ?? 14.0;
    const basePadding = 16.0;
    final textDirection = Directionality.of(context);

    final visibleNames = <String>[];
    double maxIconWidth = 0;
    for (final participant in participants) {
      final user = organizerSessionState.getUser(participant);
      final displayName = user?.displayName ?? 'Unknown';
      final visibleName = _truncateName(
        displayName,
        _isHorizontalScrolled ? 6 : 10,
      );
      visibleNames.add(visibleName);

      if (user?.profileFireStoragePath != null) {
        maxIconWidth = max(maxIconWidth, fontSize * 2 + 8.0);
      }
    }

    final widestTextWidth = TextWidthUtil.calculateMaxWidth(
      context,
      visibleNames,
      textStyle: textStyle,
      textDirection: textDirection,
    );

    final widestContent = basePadding + maxIconWidth + widestTextWidth;

    final maxAllowedWidth = constraints.maxWidth * 0.45;
    return min(widestContent, maxAllowedWidth);
  }

  String _truncateName(String name, int maxChars) {
    if (name.length <= maxChars) {
      return name;
    }
    return '${name.substring(0, maxChars)}...';
  }

  Widget _buildLessonHeaderCell(
      BuildContext context, Lesson lesson, int label) {
    return InkWell(
      onTap: () => DialogUtils.showInfoDialog(
        context,
        'Lesson $label - ${lesson.title}',
        lesson.synopsis ?? '',
        () {},
      ),
      child: Container(
        width: _lessonCellWidth,
        height: _lessonHeaderHeight,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surface,
        child: Text(
          label.toString(),
          style: CustomTextStyles.getBodyNote(context)
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildNameCell(
    BuildContext context,
    SessionParticipant participant,
    double learnToTeachRatio,
    OrganizerSessionState organizerSessionState,
    LibraryState libraryState,
    double width,
  ) {
    final user = organizerSessionState.getUser(participant);
    final rowColor = _rowColor(
        context, participant, learnToTeachRatio, organizerSessionState);
    final textStyle = CustomTextStyles.getBodyNote(context);
    final fontSize = textStyle?.fontSize ?? 14;
    final displayName = user?.displayName ?? 'Unknown';
    final compactName = _truncateName(
      displayName,
      _isHorizontalScrolled ? 6 : 10,
    );

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: user == null ? null : () => _handleProfileTap(context, user),
        child: Container(
          width: width,
          height: _rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _buildProfileImage(user, fontSize * 2),
              if (user?.profileFireStoragePath != null)
                const SizedBox(width: 8),
              Expanded(
                child: Text(
                  compactName,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProfileTap(BuildContext context, User user) {
    StudentSessionHistoryDialog.show(context, user);
  }

  Widget _buildProfileImage(User? user, double fontSize) {
    if (user?.profileFireStoragePath == null) {
      return const SizedBox();
    }

    return SizedBox(
      width: fontSize,
      height: fontSize,
      child: ProfileImageWidgetV2.fromUser(
        user!,
        key: ValueKey(user.id),
        maxRadius: fontSize / 2,
        enableDoubleTapSwitch: false,
        linkToOtherProfile: false,
      ),
    );
  }

  Widget _buildLessonCellContent(
    BuildContext context,
    OrganizerSessionState organizerSessionState,
    SessionParticipant participant,
    Lesson lesson,
  ) {
    _StudentGroup? group = _groups.firstWhereOrNull((group) =>
        group.memberParticipantIds.contains(participant.id) &&
        group.lessonId == lesson.id);
    Color iconColor = Colors.grey.shade400;
    GraduationStatus graduationStatus =
        organizerSessionState.getGraduationStatus(participant, lesson);
    Color backgroundColor = _determineCellColor(graduationStatus);

    if (group != null) {
      bool isSelected = _groups.any((group) =>
          group.isSelected &&
          group.lessonId == lesson.id &&
          group.memberParticipantIds.contains(participant.id));
      bool isMentor = group.mentorParticipantId == participant.id;
      int groupIndex = _groups.indexOf(group);
      String groupLetter = String.fromCharCode('A'.codeUnitAt(0) + groupIndex);
      iconColor = isSelected ? Colors.black : Colors.grey.shade400;

      return InkWell(
        onTap: () => _handleToggleParticipant(lesson, participant),
        child: Container(
          color: backgroundColor,
          alignment: Alignment.center,
          child: CircledLetterWidget(
            letter: groupLetter,
            textStyle: CustomTextStyles.getBodySmall(context)
                ?.copyWith(fontWeight: FontWeight.bold),
            borderWidth: isMentor ? 2 : 1,
            color: iconColor,
          ),
        ),
      );
    } else {
      return Material(
        color: backgroundColor, // cell background
        child: InkWell(
          onTap: () => _handleToggleParticipant(lesson, participant),
          child: const SizedBox.expand(), // fills all available space
        ),
      );
    }
  }

  Color _determineCellColor(GraduationStatus graduationStatus) {
    switch (graduationStatus) {
      case GraduationStatus.untouched:
        return Colors.white;
      case GraduationStatus.practiced:
        return CustomTextStyles.partiallyLearnedColor;
      case GraduationStatus.practicedThisSession:
        return CustomTextStyles.partiallyLearnedThisSessionColor;
      case GraduationStatus.graduated:
        return CustomTextStyles.fullyLearnedColor;
    }
  }

  void _handleToggleParticipant(Lesson lesson, SessionParticipant participant) {
    if (lesson.id == null || participant.id == null) {
      return;
    }

    final organizerSessionState =
        Provider.of<OrganizerSessionState>(context, listen: false);
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    final batch = FirestoreService.instance.batch();

    int selectedGroupIndex = _getSelectedGroup();
    _StudentGroup selectedGroup = _groups[selectedGroupIndex];
    bool wasInSelected =
        selectedGroup.memberParticipantIds.contains(participant.id);
    bool isSameLevel =
        selectedGroup.lessonId != null && selectedGroup.lessonId == lesson.id;

    // Only change the lesson, not the participant.
    if (wasInSelected && !isSameLevel) {
      // Update the lesson locally.
      selectedGroup.lessonId = lesson.id;
      setState(() {});

      // Update the lesson in the cloud.
      String? groupId = selectedGroup.id;
      if (groupId != null) {
        SessionPairing? pairing = organizerSessionState.getPairingById(groupId);
        if (pairing != null) {
          organizerSessionState.updateLesson(lesson, pairing);
        }
      }
      return;
    }

    // Possibly remove the participant from another group.
    _dumpGroups(0);
    _removeParticipantFromAllGroups(
        participant.id!, organizerSessionState, libraryState, batch);
    _dumpGroups(1);

    // Update the lesson.
    selectedGroup.lessonId = lesson.id;

    // Add the participant and rebuild the participants.
    if (wasInSelected) {
      // Should already have been removed by _removeParticipantFromAllGroups.
    } else {
      selectedGroup.additionalLearnerParticipantIds.add(participant.id!);
    }
    _dumpGroups(2);
    _rebuildParticipants(
        selectedGroup,
        selectedGroup.memberParticipantIds.toList(),
        organizerSessionState,
        libraryState);
    _dumpGroups(3);

    // Persist the changes to Firebase.
    String? groupId = selectedGroup.id;
    if (groupId == null) {
      String? mentorUserId = organizerSessionState.getUser(participant)?.id;

      selectedGroup.id = organizerSessionState.addPairing(
          SessionPairing(
              null,
              docRef('sessions', organizerSessionState.currentSession!.id!),
              selectedGroup.round,
              docRef('users', mentorUserId!),
              null,
              docRef('lessons', lesson.id!), []),
          batch);
    } else if (selectedGroup.memberParticipantIds.isEmpty) {
      print('The group should already have been deleted.');
      setState(() {});
      batch.commit();
      return;
    } else {
      _updateStudentsAndLesson(selectedGroup, organizerSessionState, batch);
    }
    _dumpGroups(4);

    // Add an empty group if necessary.
    bool hasEmptyGroup =
        _groups.any((group) => group.memberParticipantIds.isEmpty);
    if (!hasEmptyGroup) {
      _groups.add(_StudentGroup(round: _roundCounter++));
    }

    setState(() {});
    batch.commit();
  }

  int _getSelectedGroup() {
    if (_groups.isEmpty) {
      _groups.add(_StudentGroup(round: _roundCounter++));
    }
    var selectedIndex = _groups.indexWhere((group) => group.isSelected);
    if (selectedIndex == -1) {
      _groups[0] = _groups[0].copyWith(isSelected: true);
      selectedIndex = 0;
    }
    return selectedIndex;
  }

  void _removeParticipantFromAllGroups(
      String participantId,
      OrganizerSessionState organizerSessionState,
      LibraryState libraryState,
      WriteBatch batch) {
    // TODO: Fix that this is not working consistently.
    for (_StudentGroup group in List.from(_groups)) {
      if (group.memberParticipantIds.contains(participantId)) {
        // Rebuild the group.
        List<String> participantIds = group.memberParticipantIds
            .where((id) => id != participantId)
            .toList();
        _rebuildParticipants(
            group, participantIds, organizerSessionState, libraryState);

        // Remove unnecessary empty groups.
        int emptyGroupCount =
            _groups.where((group) => group.memberParticipantIds.isEmpty).length;
        if (emptyGroupCount > 1) {
          // Implies that the current group is empty.
          _groups.remove(group);

          // Persist to Firebase.
          String? groupId = group.id;
          if (groupId != null) {
            organizerSessionState.removePairing(groupId, batch);
          }
        } else {
          // Persist to Firebase.
          _updateStudentsAndLesson(group, organizerSessionState, batch);
        }
      }
    }

    // Ensure that a group is selected.
    _ensureSelectedGroup();
  }

  void _updateStudentsAndLesson(_StudentGroup group,
      OrganizerSessionState organizerSessionState, WriteBatch batch) {
    String? mentorUserId = organizerSessionState
        .getUserByParticipantId(group.mentorParticipantId)
        ?.id;
    String? menteeUserId = organizerSessionState
        .getUserByParticipantId(group.learnerParticipantId)
        ?.id;
    List<String>? additionalStudentUserIds = group
        .additionalLearnerParticipantIds
        .map((id) => organizerSessionState.getUserByParticipantId(id)?.id)
        .whereType<String>()
        .toList();
    organizerSessionState.updateStudentsAndLesson(group.id!, mentorUserId,
        menteeUserId, additionalStudentUserIds, group.lessonId, batch);
  }

  SessionParticipant? _findParticipantById(
    String id,
    OrganizerSessionState organizerSessionState,
  ) {
    for (final participant in organizerSessionState.sessionParticipants) {
      if (participant.id == id) {
        return participant;
      }
    }
    return null;
  }

  Color _rowColor(BuildContext context, SessionParticipant participant,
      double learnToTeachRatio, OrganizerSessionState organizerSessionState) {
    final isInGroup = _groups
        .any((group) => group.memberParticipantIds.contains(participant.id));
    final teachDeficit =
        participant.teachCount * learnToTeachRatio - participant.learnCount;
    final intensity = min(teachDeficit.abs() / 5.0, 1.0);
    Color base = Theme.of(context).colorScheme.surfaceVariant;
    if (teachDeficit > 0) {
      base = Color.lerp(base, Colors.green.shade200, intensity) ?? base;
    } else if (teachDeficit < 0) {
      base = Color.lerp(base, Colors.red.shade200, intensity) ?? base;
    }
    if (isInGroup) {
      base = Color.lerp(base, Colors.black, 0.08) ?? base;
    }
    return base;
  }

  List<_LevelGroup> _buildLevelGroups(
      List<Lesson> lessons, List<Level>? levels) {
    final levelLookup = {for (final level in levels ?? []) level.id!: level};
    final groups = <_LevelGroup>[];
    int lessonCount = 0;
    String? currentLevelId;
    int nextLevelNumber = 1;

    void pushGroup() {
      if (currentLevelId == null || lessonCount == 0) {
        return;
      }
      final level = levelLookup[currentLevelId!];
      groups.add(_LevelGroup(
        levelNumber: nextLevelNumber++,
        levelTitle: level?.title ?? 'Flex Lessons',
        lessonCount: lessonCount,
      ));
    }

    for (final lesson in lessons) {
      final levelKey = lesson.levelId?.id ?? '_unassigned';
      if (levelKey != currentLevelId) {
        pushGroup();
        currentLevelId = levelKey;
        lessonCount = 0;
      }
      lessonCount++;
    }
    pushGroup();

    return groups;
  }

  List<SessionParticipant> _sortedParticipants(
    OrganizerSessionState organizerSessionState,
    List<Lesson> orderedLessons,
  ) {
    final participants = List<SessionParticipant>.from(
        organizerSessionState.sessionParticipants);
    final lessonIndexById = {
      for (int i = 0; i < orderedLessons.length; i++) orderedLessons[i].id!: i
    };

    participants.sort((a, b) {
      final userA = organizerSessionState.getUser(a);
      final userB = organizerSessionState.getUser(b);
      final graduatedA = organizerSessionState
          .getGraduatedLessons(a)
          .map((lesson) => lessonIndexById[lesson.id] ?? -1)
          .toList();
      final graduatedB = organizerSessionState
          .getGraduatedLessons(b)
          .map((lesson) => lessonIndexById[lesson.id] ?? -1)
          .toList();

      final highestA = graduatedA.isEmpty ? -1 : graduatedA.reduce(max);
      final highestB = graduatedB.isEmpty ? -1 : graduatedB.reduce(max);
      if (highestA != highestB) {
        return highestB.compareTo(highestA);
      }

      if (graduatedA.length != graduatedB.length) {
        return graduatedB.length.compareTo(graduatedA.length);
      }

      final createdA = userA?.created.toDate() ?? DateTime.now();
      final createdB = userB?.created.toDate() ?? DateTime.now();
      return createdA.compareTo(createdB);
    });

    return participants;
  }

  void _maybeLoadExistingPairings() {
    OrganizerSessionState organizerSessionState =
        context.read<OrganizerSessionState>();

    print(
        'Trying to load groupings. Got pairings ${organizerSessionState.allPairings.length}');
    Stopwatch stopWatch = Stopwatch()..start();
    List<SessionPairing> allPairings = organizerSessionState.allPairings
        .where((pairing) => !pairing.isCompleted)
        .toList();
    allPairings.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    // Update the round counter to be at least as much as is in the data store.
    _roundCounter = organizerSessionState.allPairings.fold<int>(_roundCounter,
        (prev, curr) {
      return max(prev, curr.roundNumber + 1);
    });

    // Find the currently select group.
    String? selectedGroupId =
        _groups.firstWhereOrNull((group) => group.isSelected)?.id;

    List<_StudentGroup> groups = [];

    for (final pairing in allPairings) {
      final group = _buildGroupFromPairing(
        pairing,
        organizerSessionState,
      );
      if (group != null) {
        group.isSelected = group.id == selectedGroupId;
        groups.add(group);
      }
    }

    bool hasEmptyGroup =
        groups.any((group) => group.memberParticipantIds.isEmpty);
    if (!hasEmptyGroup) {
      groups.add(_StudentGroup(round: _roundCounter++));
    }

    bool hasSelectedGroup = groups.any((group) => group.isSelected);
    if (!hasSelectedGroup) {
      groups.last.isSelected = true;
    }

    if (_StudentGroup.deepEquals(groups, _lastLoadedGroups)) {
      print('No new data from Firebase => Updating groups.');
      return;
    }
    _lastLoadedGroups = groups;

    stopWatch.stop();
    print(
        'Rebuilt ${groups.length} groups in ${stopWatch.elapsedMilliseconds}ms.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _groups = groups;
      });
    });
  }

  _StudentGroup? _buildGroupFromPairing(
      SessionPairing pairing, OrganizerSessionState organizerSessionState) {
    SessionParticipant? mentorParticipant =
        organizerSessionState.getParticipantByUserId(pairing.mentorId?.id);
    SessionParticipant? learnerParticipant =
        organizerSessionState.getParticipantByUserId(pairing.menteeId?.id);
    print('Mentor lookup: pairing.mentorId = ${pairing.mentorId?.id}, '
        'mentorParticipant = $mentorParticipant');

    List<String> additionalLearners = [];
    for (final additionalStudent in pairing.additionalStudentIds) {
      SessionParticipant? participant =
          organizerSessionState.getParticipantByUserId(additionalStudent.id);
      if (participant?.id != null) {
        additionalLearners.add(participant!.id!);
      }
    }

    print('Created a group from Firebase: '
        'id = ${pairing.id}, '
        'round = ${pairing.roundNumber}, '
        'lessonId = ${pairing.lessonId?.id}, '
        'mentorParticipantId = ${mentorParticipant?.id}, '
        'learnerParticipantId = ${learnerParticipant?.id}, '
        'additionalLearners = $additionalLearners');

    return _StudentGroup(
      id: pairing.id,
      round: pairing.roundNumber,
      lessonId: pairing.lessonId?.id,
      mentorParticipantId: mentorParticipant?.id,
      learnerParticipantId: learnerParticipant?.id,
      additionalLearnerIds: additionalLearners,
    );
  }

  Widget _buildGroupPanel(BuildContext context, LibraryState libraryState) {
    Map<String, String> lessonLabelById = {};
    List<Lesson>? lessons = libraryState.lessons;
    if (lessons != null) {
      for (int i = 0; i < lessons.length; i++) {
        String? lessonId = lessons[i].id;
        if (lessonId != null) {
          lessonLabelById[lessonId] = 'L${i + 1}';
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final group in _groups)
            InputChip(
              label: Text(
                '${group.memberParticipantIds.length}ppl: '
                '${group.lessonId != null ? lessonLabelById[group.lessonId] ?? '--' : '--'}',
              ),
              selected: group.isSelected,
              showCheckmark: false,
              onSelected: (_) => _selectGroup(group.id),
              deleteIcon: const Icon(
                Icons.info_outline,
                size: 18,
                color: Colors.grey,
              ),
              deleteButtonTooltipMessage: 'Group info',
              onDeleted: () => _showGroupInfoDialog(
                group,
                libraryState,
              ),
            ),
        ],
      ),
    );
  }

  void _showGroupInfoDialog(
    _StudentGroup group,
    LibraryState libraryState,
  ) {
    final organizerSessionState =
        Provider.of<OrganizerSessionState>(context, listen: false);
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    final applicationState =
        Provider.of<ApplicationState>(context, listen: false);

    final lesson = group.lessonId != null
        ? libraryState.findLesson(group.lessonId!)
        : null;
    final level = lesson?.levelId != null
        ? libraryState.findLevelByDocRef(lesson!.levelId!)
        : null;
    print('Showing group info dialog for ${group.memberParticipantIds}');
    final members = group.memberParticipantIds
        .map((id) => _buildGroupMemberInfo(id, group, organizerSessionState))
        .whereType<_GroupMemberInfo>()
        .toList();

    members.sort((a, b) {
      if (a.isMentor != b.isMentor) {
        return a.isMentor ? -1 : 1;
      }
      return a.user.displayName.compareTo(b.user.displayName);
    });

    int? lessonIndex =
        lesson != null ? libraryState.lessons?.indexOf(lesson) : null;
    String lessonLabel = lessonIndex != null ? 'L${lessonIndex + 1}' : '--';
    bool canGraduate = _canCurrentUserGraduate(applicationState, libraryState);

    DialogUtils.showOptionalActionDialogWithContent(
      context,
      'Group Details',
      'Complete Group',
      () => _completeGroup(group),
      SingleChildScrollView(
        child: Consumer<OrganizerSessionState>(builder: (context, _, __) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Level: ${level?.title ?? 'Unassigned level'}',
                style: CustomTextStyles.getBody(context)
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: lesson?.id == null
                    ? null
                    : () => _openLessonDetails(lesson!.id!),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson: ',
                      style: CustomTextStyles.getBody(context)
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        lesson != null
                            ? '$lessonLabel • ${lesson.title}'
                            : 'No lesson selected',
                        style: CustomTextStyles.getBody(context)?.copyWith(
                            color: lesson?.id != null
                                ? Theme.of(context).colorScheme.primary
                                : null,
                            decoration: lesson?.id != null
                                ? TextDecoration.underline
                                : null,
                            decorationColor: lesson?.id != null
                                ? Theme.of(context).colorScheme.primary
                                : null),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (members.isEmpty) const Text('No students in this group yet.'),
              for (final member in members)
                _buildGroupMemberRow(
                  member,
                  lesson,
                  organizerSessionState,
                  canGraduate,
                ),
            ],
          );
        }),
      ),
    );
  }

  _GroupMemberInfo? _buildGroupMemberInfo(
    String participantId,
    _StudentGroup group,
    OrganizerSessionState organizerSessionState,
  ) {
    SessionParticipant? participant =
        _findParticipantById(participantId, organizerSessionState);
    if (participant == null) {
      return null;
    }

    final user =
        organizerSessionState.getUserById(participant.participantId.id);
    print(
        'for participantId $participantId: Found participant $participant and $user');
    if (user == null) {
      return null;
    }

    return _GroupMemberInfo(
      user: user,
      isMentor: group.mentorParticipantId == participantId,
    );
  }

  Widget _buildGroupMemberRow(
    _GroupMemberInfo member,
    Lesson? lesson,
    OrganizerSessionState organizerSessionState,
    bool canGraduate,
  ) {
    final isGraduated = lesson != null &&
        _isLessonGraduated(member.user, lesson, organizerSessionState);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  member.user.displayName,
                  style: CustomTextStyles.getBody(context),
                  overflow: TextOverflow.ellipsis,
                ),
                if (member.isMentor) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Mentor',
                      style: CustomTextStyles.getBodyNote(context)?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Checkbox(
            value: isGraduated,
            onChanged: (!canGraduate ||
                    lesson == null ||
                    member.user.id == null)
                ? null
                : (_) =>
                    _handleGraduationToggle(member.user, lesson, isGraduated),
          ),
        ],
      ),
    );
  }

  bool _isLessonGraduated(
    User user,
    Lesson lesson,
    OrganizerSessionState organizerSessionState,
  ) {
    final userId = user.id;
    final lessonId = lesson.id;
    if (userId == null || lessonId == null) {
      return false;
    }

    return organizerSessionState.hasUserGraduatedLesson(user, lesson);
  }

  void _handleGraduationToggle(
    User user,
    Lesson lesson,
    bool alreadyGraduated,
  ) {
    if (user.id == null || lesson.id == null) {
      return;
    }

    if (alreadyGraduated) {
      DialogUtils.showInfoDialog(
        context,
        'Already Graduated',
        '${user.displayName} has already graduated "${lesson.title}".',
        () {},
      );
      return;
    }

    DialogUtils.showConfirmationDialog(
      context,
      'Graduate Lesson?',
      'Graduate ${user.displayName} for "${lesson.title}"?',
      () {
        final studentState = Provider.of<StudentState>(context, listen: false);
        studentState.recordTeachingWithCheck(lesson, user, true, null, context);
        setState(() {});
      },
    );
  }

  bool _canCurrentUserGraduate(
    ApplicationState applicationState,
    LibraryState libraryState,
  ) {
    final creatorId = libraryState.selectedCourse?.creatorId;
    final currentUser = applicationState.currentUser;
    return currentUser != null &&
        (currentUser.isAdmin ||
            (creatorId != null && creatorId == currentUser.uid));
  }

  void _openLessonDetails(String lessonId) {
    LessonDetailArgument.goToLessonDetailPage(context, lessonId);
  }

  void _selectGroup(String? groupId) {
    if (groupId == null) {
      // Select the last group.
      setState(() {
        for (int i = 0; i < _groups.length; i++) {
          _groups[i].isSelected = i == _groups.length - 1;
        }
      });
    } else {
      setState(() {
        for (_StudentGroup group in _groups) {
          group.isSelected = group.id == groupId;
        }
      });
    }
  }

  String? _findMentor(List<String> participantIds, String? lessonId,
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    print('_findMentor out of $participantIds');

    // Handle a case of only one participant.
    if (participantIds.isEmpty) {
      return null;
    } else if (participantIds.length == 1) {
      return participantIds.first;
    }

    // Find the student who graduated the lesson.
    Lesson lesson = libraryState.findLesson(lessonId!)!;
    List<String> qualifyingParticipantIds = [];
    for (String participantId in participantIds) {
      User? user = organizerSessionState.getUserByParticipantId(participantId);

      if (user == null) {
        print('User not found for participantId $participantId.');
        print(
            'Organizer Session State contains user Ids: ${organizerSessionState.participantUsers.map((user) => user.id)}');
        print(
            'Organizer Session State contains participant Ids: ${organizerSessionState.sessionParticipants.map((participant) => participant.id)}');
        print(
            'Organizer Session State contains participant Uids: ${organizerSessionState.sessionParticipants.map((participant) => participant.participantUid)}');
        continue;
      }

      if (organizerSessionState.hasUserGraduatedLesson(user, lesson)) {
        qualifyingParticipantIds.add(participantId);
      }
    }
    print(
        '_findMentor: The following users have graduated the selected lesson ($lessonId): $qualifyingParticipantIds');

    if (qualifyingParticipantIds.length == 1) {
      return qualifyingParticipantIds.first;
    }

    if (qualifyingParticipantIds.isEmpty) {
      qualifyingParticipantIds = List.from(participantIds);
    }

    // Find the student with the highest graduated lesson.
    List<String> reversedLessonIds = libraryState.lessons?.reversed
            .map((lesson) => lesson.id)
            .whereType<String>()
            .toList() ??
        [];
    for (String lessonId in reversedLessonIds) {
      Lesson? lesson = libraryState.findLesson(lessonId);
      if (lesson == null) {
        print('Couldn\'t find lesson: $lessonId');
        continue;
      }

      List<String> candidateParticipantIds = [];
      for (String participantId in qualifyingParticipantIds) {
        User? user =
            organizerSessionState.getUserByParticipantId(participantId)!;
        if (organizerSessionState.hasUserGraduatedLesson(user, lesson)) {
          candidateParticipantIds.add(participantId);
          print(
              'Found that participant $participantId has learned lesson ${lesson.title}');
        }
      }

      print('candidateParticipantIds is $candidateParticipantIds');
      if (candidateParticipantIds.length == 1) {
        return candidateParticipantIds.first;
      }

      if (candidateParticipantIds.length >= 2) {
        qualifyingParticipantIds = candidateParticipantIds;
        break;
      }
      print('Nobody graduated lesson ${lesson.title}. Trying the next lesson.');
    }

    // Find the student who was graduated first.
    print('About to sort participants: $qualifyingParticipantIds');
    qualifyingParticipantIds.sort((a, b) {
      User userA = organizerSessionState.getUserByParticipantId(a)!;
      User userB = organizerSessionState.getUserByParticipantId(b)!;
      return userA.created.compareTo(userB.created);
    });

    return qualifyingParticipantIds.first;
  }

  void _rebuildParticipants(_StudentGroup group, List<String> participantIds,
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    String? mentorParticipantId = _findMentor(
        participantIds, group.lessonId, organizerSessionState, libraryState);
    List<String> participantIdsCopy = List.from(participantIds);

    if (mentorParticipantId == null) {
      // Empty group.
      group.mentorParticipantId = null;
      group.learnerParticipantId = null;
      group.additionalLearnerParticipantIds = [];
      return;
    }

    print('Found mentor: $mentorParticipantId from $participantIds');
    group.mentorParticipantId = mentorParticipantId;
    participantIdsCopy.remove(mentorParticipantId);

    if (participantIdsCopy.isNotEmpty) {
      group.learnerParticipantId = participantIdsCopy.first;
      participantIdsCopy.remove(group.learnerParticipantId);
      group.additionalLearnerParticipantIds = List.from(participantIdsCopy);
      print(
          'Set learner to ${group.learnerParticipantId} and additional: ${group.additionalLearnerParticipantIds}');
    } else {
      group.learnerParticipantId = null;
      group.additionalLearnerParticipantIds = [];
    }
  }

  void _dumpGroups(int step) {
    print("Dumping group for step $step.");
    for (_StudentGroup group in _groups) {
      String msg = '- Group: ';
      if (group.mentorParticipantId != null) {
        msg += 'Mentor: ${group.mentorParticipantId}';
      }
      if (group.learnerParticipantId != null) {
        msg += ' Learner: ${group.learnerParticipantId}';
      }
      if (group.additionalLearnerParticipantIds.isNotEmpty) {
        msg += ' Additional: ${group.additionalLearnerParticipantIds}';
      }
      print(msg);
    }
  }

  void _ensureSelectedGroup() {
    bool hasSelectedGroup = _groups.any((group) => group.isSelected);
    if (!hasSelectedGroup) {
      _groups.last.isSelected = true;
    }
  }

  void _completeGroup(_StudentGroup group) {
    // Update in app.
    _groups.remove(group);
    setState(() {});

    // Update in Firebase.
    OrganizerSessionState organizerSessionState =
        context.read<OrganizerSessionState>();
    organizerSessionState.completePairing(group.id!);
  }
}

class _LevelGroup {
  final int levelNumber;
  final String levelTitle;
  final int lessonCount;

  _LevelGroup({
    required this.levelNumber,
    required this.levelTitle,
    required this.lessonCount,
  });
}

class _StudentGroup {
  String? id;
  int round;

  String? lessonId;
  bool isSelected;
  String? mentorParticipantId;
  String? learnerParticipantId;
  List<String> additionalLearnerParticipantIds;

  Set<String> get memberParticipantIds => {
        mentorParticipantId,
        learnerParticipantId,
        ...additionalLearnerParticipantIds
      }.whereType<String>().toSet();

  _StudentGroup({
    this.id,
    required this.round,
    this.lessonId,
    this.isSelected = false,
    this.mentorParticipantId,
    this.learnerParticipantId,
    List<String>? additionalLearnerIds,
  }) : additionalLearnerParticipantIds = additionalLearnerIds ?? [];

  bool get isEmpty => memberParticipantIds.isEmpty && lessonId == null;

  _StudentGroup copyWith({
    String? id,
    Set<String>? memberIds,
    String? lessonId,
    bool? isSelected,
    String? mentorId,
    String? learnerId,
    List<String>? additionalLearnerIds,
  }) {
    return _StudentGroup(
      id: id ?? this.id,
      round: this.round,
      lessonId: lessonId ?? this.lessonId,
      isSelected: isSelected ?? this.isSelected,
      mentorParticipantId: mentorId ?? this.mentorParticipantId,
      learnerParticipantId: learnerId ?? this.learnerParticipantId,
      additionalLearnerIds:
          additionalLearnerIds ?? this.additionalLearnerParticipantIds,
    );
  }

  void removeParticipant(SessionParticipant participant) {
    if (mentorParticipantId == participant.id) {
      mentorParticipantId = null;
    } else if (learnerParticipantId == participant.id) {
      learnerParticipantId = null;
    } else {
      additionalLearnerParticipantIds.remove(participant.id);
    }
  }

  static bool deepEquals(
      List<_StudentGroup> groupA, List<_StudentGroup> groupB) {
    if (groupA.length != groupB.length) {
      return false;
    }

    for (int i = 0; i < groupA.length; i++) {
      if (groupA[i].id != groupB[i].id ||
          // groupA[i].round != groupB[i].round ||
          groupA[i].lessonId != groupB[i].lessonId ||
          // groupA[i].isSelected != groupB[i].isSelected ||
          groupA[i].mentorParticipantId != groupB[i].mentorParticipantId ||
          groupA[i].learnerParticipantId != groupB[i].learnerParticipantId) {
        return false;
      }

      for (int j = 0;
          j < groupA[i].additionalLearnerParticipantIds.length;
          j++) {
        if (groupA[i].additionalLearnerParticipantIds[j] !=
            groupB[i].additionalLearnerParticipantIds[j]) {
          return false;
        }
      }
    }
    return true;
  }
}

/*
  String? id;
  DocumentReference sessionId;
  int roundNumber;
  DocumentReference? mentorId;
  DocumentReference? menteeId;
  DocumentReference? lessonId;
  List<DocumentReference> additionalStudentIds;
 */

class _GroupMemberInfo {
  final User user;
  final bool isMentor;

  _GroupMemberInfo({
    required this.user,
    required this.isMentor,
  });
}
