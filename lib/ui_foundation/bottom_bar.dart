import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'application_state.dart';
import 'navigation_enum.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        child: Consumer<ApplicationState>(
            builder: (context, value, child) => Row(
                  children: [
                    addIcon(context, Icons.home, NavigationEnum.home, true),
                    addIcon(context, Icons.school, NavigationEnum.lesson_list,
                        value.isCourseSelected && value.isLoggedIn),
                    addIcon(context, Icons.settings, NavigationEnum.profile,
                        value.isLoggedIn),
                  ],
                )));
  }

  IconButton addIcon(BuildContext context, IconData? icon,
      NavigationEnum destination, bool isEnabled) {
    var isSelected = ModalRoute.of(context)?.settings.name == destination.route;
    return IconButton(
      icon: Icon(icon),
      isSelected: isSelected,
      color: isSelected
          ? Colors.black
          : isEnabled
              ? Colors.black54
              : Colors.black26,
      onPressed: () {
        if (isEnabled) {
          Navigator.of(context).pushNamed(destination.route);
        }
      },
    );
  }
}
