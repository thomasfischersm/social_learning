import 'package:flutter/material.dart';

enum NavigationEnum {
  landing('/landing'),
  home('/home'),
  profile('/profile'),
  otherProfile('/other_profile'),
  profileComparison('/profile_comparison'),
  levelList('/level_list'),
  levelDetail('/level_detail'),
  lessonDetail('/lesson_detail'),
  signIn('/sign_in'),
  signOut('/sign_out'),
  cmsHome('/cms_home'),
  cmsDetail('/cms_detail'),
  cmsSyllabus('/cms_syllabus'),
  cmsLesson('/cms_lesson'),
  sessionHome('/session_home'),
  sessionCreateWarning('/session_create_warning'),
  sessionCreate('/session_create'),
  sessionHost('/session_host'),
  sessionStudent('/session_student'),
  onlineSessionWaitingRoom('/online_session_waiting_room'),
  onlineSessionActive('/online_session_active'),
  createCourse('/create_course'),
  codeOfConduct('/code_of_conduct'),
  onlineSessionReview('/online_session_review'),
  instructorDashBoard('/instructor_dashboard'),
  instructorClipboard('/instructor_clipboard'),
  courseGeneration('/course_generation'),
  courseGenerationReview('/course_generation_review'),
  courseDesignerIntro('/course_designer_intro'),
  courseDesignerProfile('/course_designer_profile'),
  courseDesignerInventory('/course_designer_inventory'),
  courseDesignerPrerequisites('/course_designer_prerequisites'),
  courseDesignerScope('/course_designer_scope'),
  courseDesignerLearningObjectives('/course_designer_learning_objectives'),
  courseDesignerSessionPlan('/course_designer_session_plan'),
  ;

  final String route;

  const NavigationEnum(this.route);

  void navigate(BuildContext context) {
    Navigator.of(context).pushNamed(route);
  }

  void navigateClean(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
        route, (route) => route.settings.name == NavigationEnum.home.route);
  }

  void navigateCleanDelayed(BuildContext context) {
    Future.delayed(Duration.zero, () {
      if (context.mounted) {
        navigateClean(context);
      }
    });
  }
}
