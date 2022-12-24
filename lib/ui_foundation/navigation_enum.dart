
enum NavigationEnum {
  landing_page('/landing'),
  home('/home'),
  profile('/profile'),
  lesson_list('/lesson_list'),
  lesson_detail('/lesson_detail'),
  sign_in('/sign_in'),
  sign_out('/sign_out'),;

  final String route;
  const NavigationEnum(this.route);
}