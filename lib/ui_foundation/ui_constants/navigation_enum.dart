
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
  createCourse('/create_course');

  final String route;
  const NavigationEnum(this.route);
}