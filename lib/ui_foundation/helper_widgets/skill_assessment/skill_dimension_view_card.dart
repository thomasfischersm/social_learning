import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Displays a skill dimension with degree buttons and shows the description of
/// the currently selected degree. The degree that was part of the assessment is
/// highlighted most strongly.
class SkillDimensionViewCard extends StatefulWidget {
  final SkillDimension dimension;
  final int selectedDegree;
  final Map<String, int> lessonStatuses;

  const SkillDimensionViewCard({
    super.key,
    required this.dimension,
    required this.selectedDegree,
    required this.lessonStatuses,
  });

  @override
  State<SkillDimensionViewCard> createState() => _SkillDimensionViewCardState();
}

class _SkillDimensionViewCardState extends State<SkillDimensionViewCard> {
  late int _viewedDegree;

  @override
  void initState() {
    super.initState();
    _viewedDegree = widget.selectedDegree;
  }

  @override
  void didUpdateWidget(covariant SkillDimensionViewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasDegreeChanged =
        oldWidget.selectedDegree != widget.selectedDegree ||
            oldWidget.dimension.id != widget.dimension.id;
    if (hasDegreeChanged && _viewedDegree != widget.selectedDegree) {
      setState(() {
        _viewedDegree = widget.selectedDegree;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.dimension.degrees.firstWhere(
      (d) => d.degree == _viewedDegree,
      orElse: () => widget.dimension.degrees.first,
    );

    final libraryState = context.watch<LibraryState>();
    final lessons = <Lesson>[];
    for (final ref in selected.lessonRefs) {
      final lesson = libraryState.findLesson(ref.id);
      if (lesson != null && lesson.id != null) {
        lessons.add(lesson);
      }
    }

    final dimensionDescription = widget.dimension.description;
    final hasDimensionDescription =
        dimensionDescription != null && dimensionDescription.trim().isNotEmpty;

    return CustomCard(
      title: widget.dimension.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDimensionDescription) ...[
            const SizedBox(height: 2),
            _buildDescriptionBox(
              dimensionDescription,
              label: 'Dimension description',
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: widget.dimension.degrees.map((degree) {
              final isAssessment = degree.degree == widget.selectedDegree;
              final isViewing = degree.degree == _viewedDegree;
              Color? background;
              Color? foreground;
              TextStyle textStyle = Theme.of(context).textTheme.bodySmall!;
              if (isAssessment) {
                background = Theme.of(context).colorScheme.primary;
                foreground = Colors.white;
                textStyle = textStyle.copyWith(color: foreground);
              } else if (isViewing) {
                background =
                    Theme.of(context).colorScheme.primary.withOpacity(0.2);
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: background,
                      foregroundColor: foreground,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _viewedDegree = degree.degree;
                      });
                    },
                    child: Text(
                      degree.name,
                      style: textStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildDescriptionBox(
            selected.description,
            label: 'Degree description',
          ),
          if (lessons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Practice',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ...lessons.map((lesson) => _buildLessonRow(context, lesson)),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonRow(BuildContext context, Lesson lesson) {
    final status = _statusForLesson(lesson);
    final style = _textStyleForStatus(context, status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('•', style: style),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
                onTap: () => _openLesson(lesson),
                child: Text(
                  lesson.title,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.start, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            tooltip: 'Start lesson',
            onPressed: () => _openLesson(lesson),
          ),
        ],
      ),
    );
  }

  int _statusForLesson(Lesson lesson) {
    final lessonId = lesson.id;
    if (lessonId == null) {
      return 0;
    }
    return widget.lessonStatuses[lessonId] ?? 0;
  }

  TextStyle _textStyleForStatus(BuildContext context, int status) {
    final base = CustomTextStyles.getBodyNote(context) ??
        Theme.of(context).textTheme.bodyMedium ??
        const TextStyle();
    if (status >= 2) {
      return CustomTextStyles.getFullyLearned(context) ??
          base.copyWith(color: CustomTextStyles.fullyLearnedColor);
    }
    if (status == 1) {
      return base.copyWith(color: Theme.of(context).colorScheme.onSurface);
    }
    return base.copyWith(color: Theme.of(context).disabledColor);
  }

  void _openLesson(Lesson lesson) {
    final lessonId = lesson.id;
    if (lessonId == null) {
      return;
    }
    Navigator.pushNamed(
      context,
      NavigationEnum.lessonDetail.route,
      arguments: LessonDetailArgument(lessonId),
    );
  }

  Widget _buildDescriptionBox(
    String? text, {
    required String label,
  }) {
    final value = text ?? '';
    return SizedBox(
      width: double.infinity,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        isEmpty: value.trim().isEmpty,
        child: Text(value),
      ),
    );
  }
}
