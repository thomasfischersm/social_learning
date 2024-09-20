import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class EnableLocationButton extends StatefulWidget {
  final ApplicationState applicationState;

  const EnableLocationButton(this.applicationState, {super.key});

  @override
  EnableLocationButtonState createState() => EnableLocationButtonState();
}

class EnableLocationButtonState extends State<EnableLocationButton> {
  late bool _isGeoLocationEnabled;

  @override
  void initState() {
    super.initState();

    _isGeoLocationEnabled =
        widget.applicationState.currentUser?.isGeoLocationEnabled ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      TextButton(
        onPressed: _toggleLocationPermission,
        child: Text(_isGeoLocationEnabled
            ? 'Disable geo location'
            : 'Enable geo location'),
      ),
      Text('(Find nearby students.)', style: CustomTextStyles.getBodySmall(context))
    ]);
  }

  Future<void> _toggleLocationPermission() async {
    var user = widget.applicationState.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('User not logged in. Cannot update location')));
      return;
    }

    if (user.isGeoLocationEnabled) {
      await UserFunctions.disableGeoLocation(widget.applicationState);

    } else {
      bool success =
          await UserFunctions.enableGeoLocation(widget.applicationState);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required!')));
      }
    }

    setState(() {
      _isGeoLocationEnabled = widget.applicationState.currentUser?.isGeoLocationEnabled ?? false;
    });
  }
}
