import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';

abstract class UserTableCell extends StatefulWidget {
  final User? user;
  final SessionPairing sessionPairing;
  final bool isEditable;
  final String selectHintText;

  const UserTableCell(
      this.user, this.sessionPairing, this.isEditable, this.selectHintText,
      {super.key});

  @override
  UserTableCellState createState() => UserTableCellState();

  void removeUser();

  List<DropdownMenuEntry<User>> getSelectableUsers();

  void selectUser(User? selectedUser);
}

class UserTableCellState extends State<UserTableCell> {
  @override
  Widget build(BuildContext context) {
    if (!widget.isEditable) {
      if (widget.user != null) {
        // Read-only cell
        return _buildReadonlyCell(false);
      } else {
        // Empty cell
        return SizedBox.shrink();
      }
    } else {
      if (widget.user != null) {
        // Deletable cell
        return _buildReadonlyCell(true);
      } else {
        // Editable cell
        return _buildEditableCell();
      }
    }
  }

  Widget _buildReadonlyCell(bool showDeleteButton) {
    return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: (Row(
          children: [
            InkWell(
                onTap: () => _goToProfile(widget.user),
                child: Text(widget.user?.displayName ?? '')),
            if (showDeleteButton)
              _createRemoveButton(widget.removeUser, context)
          ],
        )));
  }

  Widget _createRemoveButton(Function removeFunction, BuildContext context) {
    return InkWell(
        onTap: () => removeFunction(),
        child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(Icons.remove_circle_outline_rounded,
                color: Colors.blue,
                size:
                    Theme.of(context).textTheme.bodyLarge?.fontSize ?? 16.0)));
  }

  _goToProfile(User? user) {
    if (user != null) {
      ApplicationState applicationState =
          Provider.of<ApplicationState>(context, listen: false);
      User? currentUser = applicationState.currentUser;
      if (currentUser?.id == user.id) {
        // Don't go to your own profile.
        return;
      }

      OtherProfileArgument.goToOtherProfile(context, user.id, user.uid);
    }
  }

  Widget _buildEditableCell() {
    return Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 8),
        child: DropdownMenu<User>(
          dropdownMenuEntries: widget.getSelectableUsers(),
          hintText: widget.selectHintText,
          onSelected: (User? selectedUser) => widget.selectUser(selectedUser),
        ));
  }
}
