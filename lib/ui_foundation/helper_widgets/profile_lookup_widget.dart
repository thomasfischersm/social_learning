import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class ProfileLookupWidget extends StatefulWidget {
  final ApplicationState applicationState;

  const ProfileLookupWidget(this.applicationState, {super.key});

  @override
  ProfileLookupWidgetState createState() => ProfileLookupWidgetState();
}

class ProfileLookupWidgetState extends State<ProfileLookupWidget> {
  static const int _queryLimit = 10;
  static const int _minChars = 3;
  static const int _debounceTime = 300;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<User> _searchResults = [];

  GeoPoint? get _userLocation {
    return widget.applicationState.currentUser?.location;
  }

  // Perform the Firestore query based on search input
  Future<void> _searchUsers(String query) async {
    query = query.trim().toLowerCase();

    // Only search after 3 characters
    if (query.trim().length < _minChars) {
      // Clear search results.
      setState(() {
        _searchResults = [];
      });
      return;
    }

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore
        .instance
        .collection('users')
        .where('sortName', isGreaterThanOrEqualTo: query)
        .where('sortName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(_queryLimit)
        .get();

    // List<DocumentSnapshot<Map<String, dynamic>>> documents = querySnapshot.docs;
    List<User> users =
        querySnapshot.docs.map((doc) => User.fromSnapshot(doc)).toList();

    // Sort results by proximity to the user's location
    GeoPoint? userLocation = _userLocation;
    if (userLocation != null) {
      users.sort((a, b) {
        // Put an exact name match on top.
        if (a.displayName.trim().toLowerCase() == query.trim().toLowerCase()) {
          return -1;
        }

        GeoPoint? locationA = a.location;
        bool hasLocationA = (locationA != null) && a.isGeoLocationEnabled;
        GeoPoint? locationB = b.location;
        bool hasLocationB = (locationB != null) && b.isGeoLocationEnabled;

        // Put no locations at the back
        if (!hasLocationA && !hasLocationB) {
          // sort alphabetical
          return a.displayName.compareTo(b.displayName);
        } else if (!hasLocationA) {
          return 1;
        } else if (!hasLocationB) {
          return -1;
        }

        double distanceA = _calculateDistance(
          userLocation,
          locationA,
        );
        double distanceB = _calculateDistance(
          userLocation,
          locationB,
        );

        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      _searchResults = users.take(_queryLimit).toList(); // Limit to 10 results
    });
  }

  // Calculate distance between two points
  double _calculateDistance(GeoPoint userPos, GeoPoint otherPos) {
    return Geolocator.distanceBetween(
      userPos.latitude,
      userPos.longitude,
      otherPos.latitude,
      otherPos.longitude,
    );
  }

  // Handle text input and debounce Firestore queries
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: _debounceTime), () {
      _searchUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Input Field
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search for other students by name',
            border: OutlineInputBorder(),
          ),
          onChanged: (text) => _onSearchChanged(),
        ),
        // Search Results Dropdown
        Column(
            children: _searchResults.map((User otherUser) {
          // Calculate distance to user
          double? dist;
          GeoPoint? userLocation = _userLocation;
          GeoPoint? otherUserLocation = otherUser.location;
          if ((userLocation != null) &&
              (otherUserLocation != null) &&
              (widget.applicationState.currentUser?.isGeoLocationEnabled ??
                  false) &&
              otherUser.isGeoLocationEnabled) {
            dist = _calculateDistance(userLocation, otherUserLocation);

            // Convert to miles
            dist = dist / 1609.344;
          }

          return ListTile(
            onTap: () => _goToProfile(otherUser),
            leading: ProfileImageWidget(
              otherUser,
              context,
              maxRadius: 20,
            ),
            title: Text(
              otherUser.displayName,
              style: CustomTextStyles.getBody(context),
            ),
            subtitle: (dist != null)
                ? Text(
                    '${dist.toStringAsFixed(0)} miles away',
                    style: CustomTextStyles.getBodySmall(context),
                  )
                : null,
          );
        }).toList()),
      ],
    );
  }

  _goToProfile(User otherUser) {
    Navigator.pushNamed(
      context,
      NavigationEnum.otherProfile.route,
      arguments: OtherProfileArgument(otherUser.id, otherUser.uid),
    );
  }
}
