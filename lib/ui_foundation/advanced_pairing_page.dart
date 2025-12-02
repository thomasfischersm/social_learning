import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart' as sl_user;
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class AdvancedPairingPage extends StatefulWidget {
  const AdvancedPairingPage({super.key});

  @override
  State<AdvancedPairingPage> createState() => _AdvancedPairingPageState();
}

class _AdvancedPairingPageState extends State<AdvancedPairingPage> {
  static const double _lessonCellWidth = 56;
  static const double _rowHeight = 44;
  static const double _levelHeaderHeight = 32;
  static const double _lessonHeaderHeight = 36;
  static const double _bottomPanelHeight = 96;

  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalNamesController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();

  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;
  bool _isHorizontalScrolled = false;
  int _groupCounter = 1;
  late List<_StudentGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = [
      _StudentGroup(id: 'group-$_groupCounter', isSelected: true),
    ];
    _horizontalHeaderController.addListener(_handleHorizontalScroll);
    _horizontalBodyController.addListener(_handleHorizontalScroll);
    _verticalBodyController.addListener(() {
      _syncVerticalScroll(_verticalBodyController, _verticalNamesController);
    });
    _verticalNamesController.addListener(() {
      _syncVerticalScroll(_verticalNamesController, _verticalBodyController);
    });
    _horizontalHeaderController.addListener(() {
      _syncHorizontalScroll(
          _horizontalHeaderController, _horizontalBodyController);
    });
    _horizontalBodyController.addListener(() {
      _syncHorizontalScroll(_horizontalBodyController, _horizontalHeaderController);
    });
  }

  void _handleHorizontalScroll() {
    final isScrolled =
        _horizontalBodyController.offset.abs() > 4 || _horizontalHeaderController.offset.abs() > 4;
    if (_isHorizontalScrolled != isScrolled) {
      setState(() {
        _isHorizontalScrolled = isScrolled;
      });
    }
  }

  void _syncHorizontalScroll(
      ScrollController primary, ScrollController secondary) {
    if (_isSyncingHorizontal) {
      return;
    }
    _isSyncingHorizontal = true;
    if (secondary.hasClients &&
        (secondary.offset - primary.offset).abs() > 1) {
      secondary.jumpTo(primary.offset);
    }
    _isSyncingHorizontal = false;
  }

  void _syncVerticalScroll(ScrollController primary, ScrollController secondary) {
    if (_isSyncingVertical) {
      return;
    }
    _isSyncingVertical = true;
    if (secondary.hasClients && (secondary.offset - primary.offset).abs() > 1) {
      secondary.jumpTo(primary.offset);
    }
    _isSyncingVertical = false;
  }

  @override
  void dispose() {
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    _verticalNamesController.dispose();
    _verticalBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(),
      bottomNavigationBar: BottomBarV2.build(context),
      body: CustomUiConstants.framePage(
        Consumer2<OrganizerSessionState, LibraryState>(
          builder: (context, organizerSessionState, libraryState, child) {
            final lessons = _sortedLessons(libraryState);
            final levelGroups = _buildLevelGroups(lessons, libraryState.levels);
            final participants =
                _sortedParticipants(organizerSessionState, lessons);
            final lessonIndexById = {
              for (int i = 0; i < lessons.length; i++) lessons[i].id!: i
            };

            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: _bottomPanelHeight + 16),
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

                            return Column(
                              children: [
                                _buildHeader(
                                  context,
                                  nameColumnWidth,
                                  lessons,
                                  levelGroups,
                                  lessonIndexById,
                                ),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: nameColumnWidth,
                                        child: Scrollbar(
                                          controller: _verticalNamesController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller: _verticalNamesController,
                                            child: Column(
                                              children: [
                                                for (final participant in participants)
                                                  _buildNameCell(
                                                    context,
                                                    participant,
                                                    organizerSessionState,
                                                    nameColumnWidth,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Scrollbar(
                                          controller: _horizontalBodyController,
                                          thumbVisibility: true,
                                          child: SingleChildScrollView(
                                            controller: _horizontalBodyController,
                                            scrollDirection: Axis.horizontal,
                                            child: SizedBox(
                                              width:
                                                  max(lessons.length * _lessonCellWidth, constraints.maxWidth),
                                              child: Scrollbar(
                                                controller: _verticalBodyController,
                                                thumbVisibility: true,
                                                child: SingleChildScrollView(
                                                  controller: _verticalBodyController,
                                                  child: Column(
                                                    children: [
                                                      for (final participant in participants)
                                                        _buildLessonRow(
                                                          participant,
                                                          organizerSessionState,
                                                          lessons,
                                                          lessonIndexById,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _buildGroupPanel(context, lessonIndexById),
              ],
            );
          },
        ),
        enableCourseLoadingGuard: true,
        enableScrolling: false,
      ),
    );
  }

  double _calculateNameColumnWidth(
    BuildContext context,
    BoxConstraints constraints,
    List<SessionParticipant> participants,
    OrganizerSessionState organizerSessionState,
  ) {
    final textStyle = CustomTextStyles.getBody(context);
    final fontSize = textStyle?.fontSize ?? 14.0;
    const basePadding = 16.0;

    double widestContent = 0;
    for (final participant in participants) {
      final user = organizerSessionState.getUser(participant);
      final displayName = user?.displayName ?? 'Unknown';
      final visibleName = _truncateName(
        displayName,
        _isHorizontalScrolled ? 6 : 10,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: visibleName, style: textStyle),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      final iconWidth = user?.profileFireStoragePath != null ? fontSize : 0.0;
      final spacing = user?.profileFireStoragePath != null ? 8.0 : 0.0;
      widestContent = max(
        widestContent,
        basePadding + iconWidth + spacing + textPainter.width,
      );
    }

    const minWidth = 120.0;
    final maxAllowedWidth = constraints.maxWidth * 0.45;
    return max(minWidth, min(widestContent, maxAllowedWidth));
  }

  String _truncateName(String name, int maxChars) {
    if (name.length <= maxChars) {
      return name;
    }
    return '${name.substring(0, maxChars)}...';
  }

  Widget _buildHeader(
    BuildContext context,
    double nameColumnWidth,
    List<Lesson> lessons,
    List<_LevelGroup> levelGroups,
    Map<String, int> lessonIndexById,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: _levelHeaderHeight,
              width: nameColumnWidth,
              color: Theme.of(context).colorScheme.surface,
            ),
            Container(
              height: _lessonHeaderHeight,
              width: nameColumnWidth,
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                'Student',
                style: CustomTextStyles.getBodyNote(context)
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Scrollbar(
            controller: _horizontalHeaderController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalHeaderController,
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  SizedBox(
                    height: _levelHeaderHeight,
                    child: Row(
                      children: [
                        for (final group in levelGroups)
                          Container(
                            width: _lessonCellWidth * group.lessonCount,
                            height: _levelHeaderHeight,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            color: Theme.of(context).colorScheme.surface,
                            child: Text(
                              'Level ${group.levelNumber}: ${group.levelTitle}',
                              style: CustomTextStyles.getBodyNote(context)
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: _lessonHeaderHeight,
                    child: Row(
                      children: [
                        for (int i = 0; i < lessons.length; i++)
                          _buildLessonHeaderCell(context, lessons[i], i + 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonHeaderCell(BuildContext context, Lesson lesson, int label) {
    return InkWell(
      onTap: () => DialogUtils.showInfoDialog(
        context,
        'Lesson $label',
        lesson.title,
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
    OrganizerSessionState organizerSessionState,
    double width,
  ) {
    final user = organizerSessionState.getUser(participant);
    final rowColor = _rowColor(context, participant, organizerSessionState);
    final textStyle = CustomTextStyles.getBody(context);
    final fontSize = textStyle?.fontSize ?? 14;
    final displayName = user?.displayName ?? 'Unknown';
    final compactName = _truncateName(
      displayName,
      _isHorizontalScrolled ? 6 : 10,
    );

    return Container(
      width: width,
      height: _rowHeight,
      color: rowColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildProfileImage(user, fontSize),
          if (user?.profileFireStoragePath != null) const SizedBox(width: 8),
          Expanded(
            child: Text(
              compactName,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(sl_user.User? user, double fontSize) {
    if (user?.profileFireStoragePath == null) {
      return const SizedBox();
    }

    return SizedBox(
      width: fontSize,
      height: fontSize,
      child: ProfileImageWidgetV2.fromUser(
        user!,
        maxRadius: fontSize / 2,
        enableDoubleTapSwitch: false,
        linkToOtherProfile: false,
      ),
    );
  }

  Widget _buildLessonRow(
    SessionParticipant participant,
    OrganizerSessionState organizerSessionState,
    List<Lesson> lessons,
    Map<String, int> lessonIndexById,
  ) {
    final rowColor = _rowColor(context, participant, organizerSessionState);

    return Container(
      color: rowColor,
      child: Row(
        children: [
          for (final lesson in lessons)
            InkWell(
              onTap: () => _handleToggleParticipant(lesson, participant),
              child: Container(
                width: _lessonCellWidth,
                height: _rowHeight,
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
                child: _buildLessonStateIcon(
                  context,
                  organizerSessionState,
                  participant,
                  lesson,
                  lessonIndexById,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonStateIcon(
    BuildContext context,
    OrganizerSessionState organizerSessionState,
    SessionParticipant participant,
    Lesson lesson,
    Map<String, int> lessonIndexById,
  ) {
    final user = organizerSessionState.getUser(participant);
    final graduated =
        user != null && organizerSessionState.hasUserGraduatedLesson(user, lesson);
    if (!graduated) {
      return const SizedBox();
    }

    final lessonLabel = lessonIndexById[lesson.id] != null
        ? 'L${lessonIndexById[lesson.id]! + 1}'
        : 'Grad';
    return Text(
      lessonLabel,
      style: CustomTextStyles.getBodyNote(context)
          ?.copyWith(color: Colors.green.shade700, fontWeight: FontWeight.bold),
    );
  }

  void _handleToggleParticipant(Lesson lesson, SessionParticipant participant) {
    // TODO: Implement pairing logic that toggles the participant into the
    // active group and locks the lesson for that group.
  }

  Color _rowColor(
      BuildContext context,
      SessionParticipant participant,
      OrganizerSessionState organizerSessionState) {
    final isInGroup = _groups.any((group) => group.memberIds.contains(participant.id));
    final teachDeficit = participant.teachCount - participant.learnCount;
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

  List<Lesson> _sortedLessons(LibraryState libraryState) {
    final lessons = List<Lesson>.from(libraryState.lessons ?? []);
    final levelById = {
      for (final level in libraryState.levels ?? []) level.id!: level
    };
    lessons.sort((a, b) {
      final aLevelOrder = levelById[a.levelId?.id]?.sortOrder ?? (1 << 30);
      final bLevelOrder = levelById[b.levelId?.id]?.sortOrder ?? (1 << 30);
      final levelCompare = aLevelOrder.compareTo(bLevelOrder);
      if (levelCompare != 0) {
        return levelCompare;
      }
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return lessons;
  }

  List<_LevelGroup> _buildLevelGroups(List<Lesson> lessons, List<Level>? levels) {
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
        levelTitle: level?.title ?? 'Unassigned',
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

  Widget _buildGroupPanel(
      BuildContext context, Map<String, int> lessonIndexById) {
    final lessonLabelById = {
      for (final entry in lessonIndexById.entries) entry.key: 'L${entry.value + 1}'
    };

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: _bottomPanelHeight,
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
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final group in _groups)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: group.isSelected,
                          onSelected: (_) => _selectGroup(group.id),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${group.memberIds.length}ppl: '
                                '${group.lessonId != null ? lessonLabelById[group.lessonId] ?? '--' : '--'}',
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.grey),
              onPressed: _addGroup,
            ),
          ],
        ),
      ),
    );
  }

  void _selectGroup(String groupId) {
    setState(() {
      _groups = _groups
          .map((g) => g.copyWith(isSelected: g.id == groupId))
          .toList(growable: false);
    });
  }

  void _addGroup() {
    setState(() {
      _groupCounter++;
      _groups.add(_StudentGroup(id: 'group-$_groupCounter'));
      _normalizeEmptyGroups();
    });
  }

  void _normalizeEmptyGroups() {
    final emptyGroups = _groups.where((group) => group.isEmpty).toList();
    if (emptyGroups.length <= 1) {
      return;
    }
    final groupsToKeep = _groups.where((group) => !group.isEmpty).toList();
    groupsToKeep.add(emptyGroups.first);
    if (!groupsToKeep.any((group) => group.isSelected)) {
      groupsToKeep.first = groupsToKeep.first.copyWith(isSelected: true);
    }
    _groups = groupsToKeep;
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
  final String id;
  final Set<String> memberIds;
  final String? lessonId;
  final bool isSelected;

  _StudentGroup({
    required this.id,
    this.lessonId,
    this.isSelected = false,
    Set<String>? memberIds,
  }) : memberIds = memberIds ?? {};

  bool get isEmpty => memberIds.isEmpty && lessonId == null;

  _StudentGroup copyWith({
    String? id,
    Set<String>? memberIds,
    String? lessonId,
    bool? isSelected,
  }) {
    return _StudentGroup(
      id: id ?? this.id,
      memberIds: memberIds ?? this.memberIds,
      lessonId: lessonId ?? this.lessonId,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
