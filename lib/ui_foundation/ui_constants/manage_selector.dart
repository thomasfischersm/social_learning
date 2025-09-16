import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/course_profile.dart';
import '../../state/course_designer_state.dart';
import '../../state/library_state.dart';
import 'navigation_enum.dart';

class ManageSelector {
  static void navigateCleanDelayed(BuildContext context) {
    if (!context.mounted) {
      return;
    }

    Future<void>.delayed(Duration.zero, () async {
      if (!context.mounted) {
        return;
      }

      final libraryState =
          Provider.of<LibraryState>(context, listen: false);
      final courseDesignerState =
          Provider.of<CourseDesignerState>(context, listen: false);

      await courseDesignerState.ensureInitialized();

      if (!context.mounted) {
        return;
      }

      final target =
          _determineNavigationTarget(libraryState, courseDesignerState);
      target.navigateClean(context);
    });
  }

  static NavigationEnum _determineNavigationTarget(
    LibraryState libraryState,
    CourseDesignerState designerState,
  ) {
    if (_hasLevels(libraryState) || designerState.blocks.isNotEmpty) {
      return NavigationEnum.cmsSyllabus;
    }

    if (designerState.learningObjectives.isNotEmpty) {
      return NavigationEnum.courseDesignerSessionPlan;
    }

    if (designerState.skillRubric?.dimensions.isNotEmpty ?? false) {
      return NavigationEnum.courseDesignerLearningObjectives;
    }

    if (_hasAnyDependencies(designerState)) {
      return NavigationEnum.courseDesignerScope;
    }

    if (designerState.items.isNotEmpty) {
      return NavigationEnum.courseDesignerPrerequisites;
    }

    if (designerState.categories.isNotEmpty ||
        designerState.tags.isNotEmpty) {
      return NavigationEnum.courseDesignerInventory;
    }

    final courseProfile = designerState.courseProfile;
    if (courseProfile == null) {
      return NavigationEnum.courseDesignerProfile;
    }

    if (_courseProfileHasContent(courseProfile)) {
      return NavigationEnum.courseDesignerInventory;
    }

    // TODO: Navigate to cms_intro once the page is implemented.
    return NavigationEnum.courseDesignerIntro;
  }

  static bool _hasLevels(LibraryState libraryState) {
    final levels = libraryState.levels;
    return levels != null && levels.isNotEmpty;
  }

  static bool _courseProfileHasContent(CourseProfile profile) {
    final fields = [
      profile.topicAndFocus,
      profile.scheduleAndDuration,
      profile.targetAudience,
      profile.groupSizeAndFormat,
      profile.location,
      profile.howStudentsJoin,
      profile.toneAndApproach,
      profile.anythingUnusual,
    ];

    for (final field in fields) {
      if (field != null && field.trim().isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  static bool _hasAnyDependencies(CourseDesignerState designerState) {
    return designerState.items.any((item) =>
        (item.requiredPrerequisiteIds?.isNotEmpty ?? false) ||
        (item.recommendedPrerequisiteIds?.isNotEmpty ?? false));
  }
}
