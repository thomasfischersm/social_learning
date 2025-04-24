import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/instructor_dashboard_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';

/// Roster widget that lazily loads students for a given course,
/// with cursor-based pagination and default alphabetical sorting.
class InstructorDashboardRosterWidget extends StatefulWidget {
  /// The course whose roster to display. May be null while loading.
  final Course? course;

  const InstructorDashboardRosterWidget({
    super.key,
    required this.course,
  });

  @override
  InstructorDashboardRosterWidgetState createState() =>
      InstructorDashboardRosterWidgetState();
}

class InstructorDashboardRosterWidgetState
    extends State<InstructorDashboardRosterWidget> {
  final ScrollController _scrollController = ScrollController();
  final List<User> _students = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.course != null) {
      _loadNextPage();
    }
  }

  @override
  void didUpdateWidget(covariant InstructorDashboardRosterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reset and load if switching to a different course.
    if (oldWidget.course?.id != widget.course?.id) {
      _resetAndLoad();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _resetAndLoad() async {
    setState(() {
      _students.clear();
      _lastDoc = null;
      _hasMore = true;
      _isLoading = false;
    });
    if (widget.course != null) {
      await _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasMore || widget.course == null) return;
    setState(() => _isLoading = true);

    try {
      final page = await InstructorDashboardFunctions.getStudentPage(
        courseId: widget.course!.id!,
        startAfterDoc: _lastDoc,
        pageSize: 20,
        sort: StudentSortOption.alphabetical, // TODO: expose UI for sort choice
      );

      setState(() {
        _students.addAll(page.students);
        _lastDoc = page.lastDoc;
        _hasMore = page.hasMore;
      });
    } catch (e, stack) {
      debugPrint('Error fetching students for course ${widget.course?.id}: $e');
      debugPrint(stack.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.course == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      itemCount: _students.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _students.length) {
          // loading indicator at bottom
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = _students[index];
        final prof =
            user.getCourseProficiency(widget.course!)?.proficiency ?? 0.0;
        final profText = '${(prof * 100).toStringAsFixed(0)}%';

        final lastActivityTs = user.lastLessonTimestamp;
        final lastActiveText = lastActivityTs != null
            ? translateTimeStampToTimeAgo(lastActivityTs.toDate())
            : null;
        print('Last active: $lastActiveText and timestamp: $lastActivityTs');

        return InkWell(
            onTap: () {
              OtherProfileArgument.goToOtherProfile(context, user.id, user.uid);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                leading: ProfileImageWidget(
                  user,
                  context,
                  maxRadius: 20,
                  linkToOtherProfile: true,
                ),
                title: Text(
                  user.displayName,
                  style: CustomTextStyles.subHeadline,
                ),
                subtitle: Row(
                  children: [
                    Text(profText, style: CustomTextStyles.getBody(context)),
                    if (lastActiveText != null) ...[
                      const SizedBox(width: 8),
                      Text('Active $lastActiveText',
                          style: CustomTextStyles.getBodySmall(context)),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.instagramHandle != null)
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/icons/Instagram_Glyph_Black.svg',
                          width: 20,
                          height: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => UserFunctions.openInstaProfile(user),
                      ),
                    const SizedBox(width: 4),
                    _iconButton(Icons.email,
                        onPressed: () => UserFunctions.openEmailClient(user)),
                    const SizedBox(width: 4),
                    _iconButton(Icons.assignment, onPressed: () {}),
                  ],
                ),
              ),
            ));
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _iconButton(IconData icon, {required VoidCallback onPressed}) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }

  /// Converts a DateTime into a “time ago” string, e.g. “5m ago”, “2h ago”.
  String translateTimeStampToTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final w = (diff.inDays ~/ 7);
    if (w < 4) return '${w}w ago';
    final m = (diff.inDays ~/ 30);
    if (m < 12) return '${m}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }
}
