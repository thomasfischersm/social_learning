import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/data/data_helpers/course_profile_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_designer_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

import '../state/course_designer_state.dart';

class CourseDesignerProfilePage extends StatefulWidget {
  const CourseDesignerProfilePage({super.key});

  @override
  State<CourseDesignerProfilePage> createState() =>
      _CourseDesignerProfilePageState();
}

class _CourseDesignerProfilePageState extends State<CourseDesignerProfilePage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final topicController = TextEditingController();
  final scheduleController = TextEditingController();
  final audienceController = TextEditingController();
  final groupFormatController = TextEditingController();
  final locationController = TextEditingController();
  final joinInfoController = TextEditingController();
  final toneController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  Future<void> _loadData() async {
    print('CourseDesignerProfilePage: Loading data for course');
    var courseDesignerState = context.read<CourseDesignerState>();
    courseDesignerState.ensureInitialized();
    CourseProfile? courseProfile = courseDesignerState.courseProfile;


    topicController.text = courseProfile?.topicAndFocus ?? '';
    scheduleController.text = courseProfile?.scheduleAndDuration ?? '';
    audienceController.text = courseProfile?.targetAudience ?? '';
    groupFormatController.text = courseProfile?.groupSizeAndFormat ?? '';
    locationController.text = courseProfile?.location ?? '';
    joinInfoController.text = courseProfile?.howStudentsJoin ?? '';
    toneController.text = courseProfile?.toneAndApproach ?? '';
    notesController.text = courseProfile?.anythingUnusual ?? '';

    print('CourseDesignerProfilePage: Data loaded');
  }

  Future<void> _save() async {
    var courseDesignerState = context.read<CourseDesignerState>();
    CourseProfile? courseProfile = courseDesignerState.courseProfile;
    LibraryState libraryState = context.read<LibraryState>();
    String courseId = libraryState.selectedCourse!.id!;

    final updatedProfile = CourseProfile(
      id: courseProfile?.id,
      courseId: docRef('courses', courseId),
      topicAndFocus: topicController.text.trim(),
      scheduleAndDuration: scheduleController.text.trim(),
      targetAudience: audienceController.text.trim(),
      groupSizeAndFormat: groupFormatController.text.trim(),
      location: locationController.text.trim(),
      howStudentsJoin: joinInfoController.text.trim(),
      toneAndApproach: toneController.text.trim(),
      anythingUnusual: notesController.text.trim(),
    );

    if (_hasProfileChanged(courseProfile, updatedProfile)) {
      courseDesignerState.saveCourseProfile(updatedProfile);
    }

    if (mounted) {
      NavigationEnum.courseDesignerInventory.navigateClean(context);
    }
  }

  @override
  void dispose() {
    topicController.dispose();
    scheduleController.dispose();
    audienceController.dispose();
    groupFormatController.dispose();
    locationController.dispose();
    joinInfoController.dispose();
    toneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar:
          CourseDesignerAppBar(title: 'Learning Lab', scaffoldKey: scaffoldKey),
      drawer: const CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
      body: Consumer<CourseDesignerState>(builder: (context, courseDesignerState, _) {

        return courseDesignerState.status != CourseDesignerStateStatus.initialized
            ? const Center(child: CircularProgressIndicator())
            : Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(
            enableScrolling: true,
            enableCreatorGuard: true,
            enableCourseLoadingGuard: true,
            // Inside the build method:
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CourseDesignerCard(
                    title: 'Step 1: Course Profile',
                    body: Text(
                      'Get clear on the course context and guide the AI to support you effectively.',
                      style: CustomTextStyles.getBody(context),
                    )),
                _buildCard('Course Details', [
                  _field(
                    context,
                    'Course topic & focus',
                    'What is the course about? What key topics or skills will you focus on?',
                    topicController,
                  ),
                  _field(
                    context,
                    'Schedule & duration',
                    'E.g. one-time 3-hour workshop or 6 weekly 90-minute classes.',
                    scheduleController,
                  ),
                ]),
                _buildCard('Audience & Format', [
                  _field(
                    context,
                    'Who is it for?',
                    'Describe who typically joins, even if you say it’s for “everyone.” What are their backgrounds, goals, or quirks?',
                    audienceController,
                  ),
                  _field(
                    context,
                    'Group size & format',
                    'E.g. 1–5 students, lots of new people each week. Lecture or hands-on?',
                    groupFormatController,
                  ),
                ]),
                _buildCard('Location & Joining', [
                  _field(
                    context,
                    'Location',
                    'E.g. Midtown NYC studio, classroom, park, Zoom…',
                    locationController,
                  ),
                  _field(
                    context,
                    'How do students join?',
                    'E.g. \$15 per class, first class free, bring yoga mat…',
                    joinInfoController,
                  ),
                ]),
                _buildCard('Tone & Notes', [
                  _field(
                    context,
                    'Tone & teaching approach',
                    'Describe your teaching style. What matters to you when teaching this course?',
                    toneController,
                  ),
                  _field(
                    context,
                    'Anything unusual or worth noting?',
                    'E.g. multilingual students, final recital, outdoor setting, no consistent group…',
                    notesController,
                  ),
                ]),
              ],
            ),
          ),
        );}));
      }

  Widget _buildCard(String title, List<Widget> fields) {
    return CourseDesignerCard(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            fields[i],
          ],
        ],
      ),
    );
  }

  Widget _field(BuildContext context, String label, String help,
      TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: CustomTextStyles.getBodyEmphasized(context)),
        const SizedBox(height: 4),
        Text(help, style: CustomTextStyles.getBodyNote(context)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          style: CustomTextStyles.getBody(context),
        ),
      ],
    );
  }

  bool _hasProfileChanged(CourseProfile? oldProfile, CourseProfile newProfile) {
  if (oldProfile == null) {
    return true;
  }
    return oldProfile.topicAndFocus != newProfile.topicAndFocus ||
        oldProfile.scheduleAndDuration != newProfile.scheduleAndDuration ||
        oldProfile.targetAudience != newProfile.targetAudience ||
        oldProfile.groupSizeAndFormat != newProfile.groupSizeAndFormat ||
        oldProfile.location != newProfile.location ||
        oldProfile.howStudentsJoin != newProfile.howStudentsJoin ||
        oldProfile.toneAndApproach != newProfile.toneAndApproach ||
        oldProfile.anythingUnusual != newProfile.anythingUnusual;
  }
}
