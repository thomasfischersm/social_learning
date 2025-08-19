import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/instructor_dashboard_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget.dart';

/// Roster widget that loads students lazily, allows sorting & filtering.
class InstructorDashboardRosterWidget extends StatefulWidget {
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

  String? _nameFilter;
  StudentSortOption _selectedSort = StudentSortOption.recent;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.course != null) _resetAndLoad();
  }

  @override
  void didUpdateWidget(covariant InstructorDashboardRosterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course?.id != widget.course?.id) _resetAndLoad();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max > 0 && _scrollController.position.pixels > max - 200) {
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
    await _loadNextPage(clear: true);
  }

  Future<void> _loadNextPage({bool clear = false}) async {
    if (_isLoading || !_hasMore || widget.course == null) return;
    setState(() => _isLoading = true);

    try {
      final page = await InstructorDashboardFunctions.getStudentPage(
        courseId: widget.course!.id!,
        startAfterDoc: _lastDoc,
        pageSize: 20,
        sort: _selectedSort,
        nameFilter: _nameFilter,
      );
      if (mounted) {
        setState(() {
          if (clear) {
            _students.clear();
          }

          _students.addAll(page.students);
          _lastDoc = page.lastDoc;
          _hasMore = page.hasMore;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading students: $e\n$st');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _labelForSort(StudentSortOption opt) {
    switch (opt) {
      case StudentSortOption.recent:
        return 'Recently Active';
      case StudentSortOption.advanced:
        // TODO: Probably remove because it's a pain to implement.
        return 'Most Advanced';
      case StudentSortOption.newest:
        // TODO: Implement the created field on user.
        return 'Newest';
      case StudentSortOption.atRisk:
        // TODO: Test
        return 'At Risk';
      case StudentSortOption.alphabetical:
      default:
        return 'A → Z';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.course == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        // Filter & Sort Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  decoration: CustomUiConstants.getFilledInputDecoration(
                    context,
                    hintText: 'Search students…',
                    enabledColor: Colors.grey.shade300,
                  ).copyWith(
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (text) {
                    final f = text.trim();

                    if (f.length < 3 && _nameFilter == null) {
                      // The user needs to type at least three letters.
                      return;
                    }

                    setState(() {
                      _nameFilter = f.length >= 3 ? f : null;
                    });
                    _resetAndLoad();
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Sort dropdown
              DropdownButton<StudentSortOption>(
                value: _selectedSort,
                items: StudentSortOption.values
                    .where((opt) => opt != StudentSortOption.advanced)
                    .map((opt) {
                  return DropdownMenuItem(
                    value: opt,
                    child: Text(_labelForSort(opt)),
                  );
                }).toList(),
                onChanged: (newOpt) {
                  if (newOpt != null && newOpt != _selectedSort) {
                    setState(() => _selectedSort = newOpt);
                    _resetAndLoad();
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Student list or empty message
        Expanded(
          child: _students.isEmpty && !_hasMore
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No students found',
                        style: CustomTextStyles.getBody(context)?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters.',
                        style: CustomTextStyles.getBodySmall(context)?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  itemCount: _students.length + (_hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= _students.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _buildStudentRow(_students[i], context);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStudentRow(User user, BuildContext context) {
    ApplicationState applicationState = context.read<ApplicationState>();

    final prof = user.getCourseProficiency(widget.course!)?.proficiency ?? 0.0;
    final profText = '${(prof * 100).toStringAsFixed(0)}%';

    final ts = user.lastLessonTimestamp;
    final lastActive = ts != null ? _timeAgo(ts.toDate()) : null;

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
          title: Text(user.displayName, style: CustomTextStyles.subHeadline),
          subtitle: Row(
            children: [
              Text(profText, style: CustomTextStyles.getBody(context)),
              if (lastActive != null) ...[
                const SizedBox(width: 8),
                Text('Active $lastActive',
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
              if (user.id != applicationState.currentUser?.id)
                _iconButton(Icons.assignment,
                    onPressed: () => _onClipboardButtonPressed(user))
              else
                const SizedBox(width: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _onClipboardButtonPressed(User user) {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);

    if (user.id == applicationState.currentUser?.id) {
      // Doesn't make sense to open clipboard for self.
      return;
    }

    InstructorClipboardArgument.navigateTo(context, user.id, user.uid);
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

  /// Converts DateTime to 'time ago'.
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final w = diff.inDays ~/ 7;
    if (w < 4) return '${w}w ago';
    final m = diff.inDays ~/ 30;
    if (m < 12) return '${m}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
