import 'package:flutter/material.dart';
import 'package:flutter_graph_view/flutter_graph_view.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/course_analytics_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class StudentNetworkAnalyticsPage extends StatelessWidget {
  const StudentNetworkAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courseAnalyticsState = context.watch<CourseAnalyticsState>();
    return Scaffold(
      appBar: const InstructorDashboardAppBar(
        currentNav: NavigationEnum.studentNetworkAnalytics,
        title: 'Student Network Analytics',
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Student Network Analytics',
                style: CustomTextStyles.subHeadline,
              ),
              const SizedBox(height: 16),
              Text(
                'This graph shows how students practiced together. '
                'Each edge represents at least one recorded practice session.',
                style: CustomTextStyles.getBodySmall(context) ??
                    Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FutureBuilder<_StudentNetworkGraphData>(
                future: _loadGraphData(courseAnalyticsState),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const _EmptyState(
                      message: 'Unable to load student connections.',
                    );
                  }
                  final data = snapshot.data;
                  if (data == null ||
                      data.vertexes.isEmpty ||
                      data.edges.isEmpty) {
                    return const _EmptyState(
                      message: 'No student connections recorded yet.',
                    );
                  }

                  return _StudentGraph(data: data);
                },
              ),
            ],
          ),
          enableCourseLoadingGuard: true,
          enableCreatorGuard: true,
          enableCourseAnalyticsGuard: true,
        ),
      ),
    );
  }
}

Future<_StudentNetworkGraphData> _loadGraphData(
    CourseAnalyticsState courseAnalyticsState) async {
  final users = await courseAnalyticsState.getCourseUsers();
  final practiceRecords = await courseAnalyticsState.getActualPracticeRecords();

  final Map<String, User> userByUid = {
    for (final user in users) user.uid: user,
  };

  final List<User> sortedUsers = userByUid.values.toList()
    ..sort((a, b) => a.sortName.compareTo(b.sortName));

  final List<Map<String, dynamic>> vertexes = [];
  for (final user in sortedUsers) {
    final initial = _initialFor(user);
    vertexes.add({
      'id': user.uid,
      'tag': initial,
      'tags': <String>[initial],
      'data': {
        'label': user.displayName.isNotEmpty
            ? user.displayName
            : user.sortName,
      },
    });
  }

  final Map<String, int> edgeCounts = {};
  for (final PracticeRecord record in practiceRecords) {
    if (record.mentorUid == record.menteeUid) {
      continue;
    }
    if (!userByUid.containsKey(record.mentorUid) ||
        !userByUid.containsKey(record.menteeUid)) {
      continue;
    }
    final key = '${record.mentorUid}::${record.menteeUid}';
    edgeCounts[key] = (edgeCounts[key] ?? 0) + 1;
  }

  final List<Map<String, dynamic>> edges = [];
  for (final entry in edgeCounts.entries) {
    final parts = entry.key.split('::');
    edges.add({
      'srcId': parts[0],
      'dstId': parts[1],
      'edgeName': 'Practices: ${entry.value}',
      'ranking': entry.value,
    });
  }

  final int practiceCount = edgeCounts.values.fold(0, (a, b) => a + b);

  return _StudentNetworkGraphData(
    vertexes: vertexes,
    edges: edges,
    users: sortedUsers,
    uniqueConnectionCount: edges.length,
    practiceCount: practiceCount,
  );
}

String _initialFor(User user) {
  final name = user.displayName.trim().isNotEmpty
      ? user.displayName.trim()
      : user.sortName.trim();
  if (name.isEmpty) {
    return '?';
  }
  return name.substring(0, 1).toUpperCase();
}

class _StudentGraph extends StatelessWidget {
  const _StudentGraph({required this.data});

  final _StudentNetworkGraphData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = CustomTextStyles.getBodySmall(context) ??
        theme.textTheme.bodySmall;

    final options = Options()
      ..backgroundBuilder = (ctx) => Container(color: Colors.transparent)
      ..textGetter = (vertex) {
        final dynamic raw = vertex.data;
        if (raw is Map<String, dynamic>) {
          final label = raw['label'];
          if (label is String && label.isNotEmpty) {
            return label;
          }
        }
        return vertex.id.toString();
      };

    options.graphStyle.tagColorByIndex = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
    ];
    options.graphStyle.vertexTextStyleGetter =
        (vertex, shape) => theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${data.users.length} students • '
          '${data.uniqueConnectionCount} connections • '
          '${data.practiceCount} practices',
          style: textStyle,
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
              ),
              child: FlutterGraphWidget(
                data: data.toGraphPayload(),
                algorithm: ForceDirected(),
                convertor: MapConvertor(),
                options: options,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentNetworkGraphData {
  const _StudentNetworkGraphData({
    required this.vertexes,
    required this.edges,
    required this.users,
    required this.uniqueConnectionCount,
    required this.practiceCount,
  });

  final List<Map<String, dynamic>> vertexes;
  final List<Map<String, dynamic>> edges;
  final List<User> users;
  final int uniqueConnectionCount;
  final int practiceCount;

  Map<String, dynamic> toGraphPayload() => {
        'vertexes': vertexes,
        'edges': edges,
      };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style:
            CustomTextStyles.getBodySmall(context) ?? Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
