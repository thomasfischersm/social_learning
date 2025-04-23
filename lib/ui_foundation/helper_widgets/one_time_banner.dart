import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A widget that shows a one-time [MaterialBanner] above [child].
///
/// - [prefsKey]: unique key in SharedPreferences to remember dismissal.
/// - [message]: the text to display in the banner.
/// - [leading]: optional leading icon/widget for the banner.
/// - [child]: the main content below the banner.
class OneTimeBanner extends StatefulWidget {
  final String prefsKey;
  final String message;
  final Widget? leading;
  final Widget child;

  const OneTimeBanner({
    Key? key,
    required this.prefsKey,
    required this.message,
    this.leading,
    required this.child,
  }) : super(key: key);

  @override
  _OneTimeBannerState createState() => _OneTimeBannerState();
}

class _OneTimeBannerState extends State<OneTimeBanner> {
  bool _loaded = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _initBannerState();
  }

  Future<void> _initBannerState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool(widget.prefsKey) ?? false;
    setState(() {
      _loaded = true;
      _visible = !dismissed;
    });
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(widget.prefsKey, true);
    setState(() {
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If we're not ready or the banner is dismissed, just show the child
    if (!_loaded || !_visible) {
      return widget.child;
    }

    // Otherwise, show the banner above the child
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MaterialBanner(
          leading: widget.leading,
          content: Text(widget.message),
          actions: [
            TextButton(
              onPressed: _dismiss,
              child: const Text('DISMISS'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        widget.child,
      ],
    );
  }
}
