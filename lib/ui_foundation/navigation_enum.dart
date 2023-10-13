
enum NavigationEnum {
  landing_page('/landing'),
  home('/home'),
  profile('/profile'),
  levelList('/level_list'),
  levelDetail('/level_detail'),
  lessonList('/lesson_list'),
  lessonDetail('/lesson_detail'),
  signIn('/sign_in'),
  signOut('/sign_out'),
  cmsHome('/cms_home'),
  cmsLesson('/cms_detail'),
  sessionHome('/session_home'),
  sessionCreateWarning('/session_create_warning'),
  sessionCreate('/session_create');

  final String route;
  const NavigationEnum(this.route);
}