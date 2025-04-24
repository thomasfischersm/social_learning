import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class InstructorDashboardRosterWidget extends StatelessWidget {
  const InstructorDashboardRosterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 10 static test students
    final students = [
      {
        'name': 'Alice Johnson',
        'proficiency': 0.75,
        'email': 'alice@example.com',
        'instagram': 'alice_insta',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      },
      {
        'name': 'Bob Smith',
        'proficiency': 0.40,
        'email': 'bob@example.com',
        'instagram': 'bob_s',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(minutes: 30))),
      },
      {
        'name': 'Carol Lee',
        'proficiency': 1.00,
        'email': 'carol@example.com',
        'instagram': 'carol_lee',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
      },
      {
        'name': 'David Brown',
        'proficiency': 0.85,
        'email': 'david@example.com',
        'instagram': 'david_b',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
      },
      {
        'name': 'Emma Williams',
        'proficiency': 0.25,
        'email': 'emma@example.com',
        'instagram': 'emma_w',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      },
      {
        'name': 'Frank Miller',
        'proficiency': 0.50,
        'email': 'frank@example.com',
        'instagram': 'frank_m',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      },
      {
        'name': 'Grace Davis',
        'proficiency': 0.15,
        'email': 'grace@example.com',
        'instagram': 'grace_d',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      },
      {
        'name': 'Henry Wilson',
        'proficiency': 0.60,
        'email': 'henry@example.com',
        'instagram': 'henry_w',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(days: 21))),
      },
      {
        'name': 'Irene Clark',
        'proficiency': 0.95,
        'email': 'irene@example.com',
        'instagram': 'irene_c',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(days: 90))),
      },
      {
        'name': 'Jack Lewis',
        'proficiency': 0.30,
        'email': 'jack@example.com',
        'instagram': 'jack_l',
        'lastActivity':
        Timestamp.fromDate(now.subtract(const Duration(days: 400))),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      itemCount: students.length,
      itemBuilder: (ctx, i) {
        final s = students[i];
        final prof = s['proficiency'] as double;
        final profText = '${(prof * 100).toStringAsFixed(0)}%';
        final profStyle = prof >= 1.0
            ? CustomTextStyles.getFullyLearned(context)!
            : CustomTextStyles.getPartiallyLearned(context)!;
        final lastActive = _timeAgo((s['lastActivity'] as Timestamp).toDate());

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            leading: const CircleAvatar(
              radius: 20,
              child: Icon(Icons.person, size: 20),
            ),
            title: Text(
              s['name'] as String,
              style: CustomTextStyles.subHeadline,
            ),
            subtitle: Text(
              '$profText • Active $lastActive',
              style: CustomTextStyles.getBodySmall(context),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconButton(Icons.camera_alt, onPressed: () {}),
                const SizedBox(width: 4),
                _iconButton(Icons.email, onPressed: () {}),
                const SizedBox(width: 4),
                _iconButton(Icons.assignment, onPressed: () {}),
              ],
            ),
          ),
        );
      },
    );
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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final w = (diff.inDays / 7).floor();
    if (w < 4) return '${w}w ago';
    final m = (diff.inDays / 30).floor();
    if (m < 12) return '${m}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
