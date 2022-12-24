
enum NavigationEnum {
  langing_page('/landing'),
  home('/home'),
  profile('/profile'),
  lesson_list('/lesson_list'),
  lesson_detail('/lesson_detail'),
  sign_in('/sign_in');

  final String route;
  const NavigationEnum(this.route);
}