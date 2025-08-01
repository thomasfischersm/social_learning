import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/data/data_helpers/course_profile_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/instructor_nav_actions.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

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

  bool isLoading = true;
  String? _courseId;
  CourseProfile? _courseProfile;

  @override
  void initState() {
    super.initState();
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    final selectedCourse = libraryState.selectedCourse;

    if (selectedCourse?.id != null) {
      _loadData(selectedCourse!.id!);
    } else {
      libraryState.addListener(_libraryStateListener);
    }
  }

  void _libraryStateListener() {
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    final selectedCourse = libraryState.selectedCourse;

    if (selectedCourse?.id != null) {
      libraryState.removeListener(_libraryStateListener);
      _loadData(selectedCourse!.id!);
    }
  }

  Future<void> _loadData(String courseId) async {
    _courseId = courseId;
    setState(() => isLoading = true);

    _courseProfile = await CourseProfileFunctions.getCourseProfile(courseId);

    topicController.text = _courseProfile?.topicAndFocus ?? '';
    scheduleController.text = _courseProfile?.scheduleAndDuration ?? '';
    audienceController.text = _courseProfile?.targetAudience ?? '';
    groupFormatController.text = _courseProfile?.groupSizeAndFormat ?? '';
    locationController.text = _courseProfile?.location ?? '';
    joinInfoController.text = _courseProfile?.howStudentsJoin ?? '';
    toneController.text = _courseProfile?.toneAndApproach ?? '';
    notesController.text = _courseProfile?.anythingUnusual ?? '';

    setState(() => isLoading = false);
  }

  Future<void> _save() async {
    if (_courseId == null) return;

    final updatedProfile = CourseProfile(
      id: _courseProfile?.id,
      courseId: docRef('courses', _courseId!),
      topicAndFocus: topicController.text.trim(),
      scheduleAndDuration: scheduleController.text.trim(),
      targetAudience: audienceController.text.trim(),
      groupSizeAndFormat: groupFormatController.text.trim(),
      location: locationController.text.trim(),
      howStudentsJoin: joinInfoController.text.trim(),
      toneAndApproach: toneController.text.trim(),
      anythingUnusual: notesController.text.trim(),
    );

    if (_hasProfileChanged(_courseProfile!, updatedProfile)) {
      _courseProfile =
          await CourseProfileFunctions.saveCourseProfile(updatedProfile);
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
      appBar: AppBar(
        title: const Text('Learning Lab'),
        leading: CourseDesignerDrawer.hamburger(scaffoldKey),
        actions: InstructorNavActions.createActions(context),
      ),
      drawer: const CourseDesignerDrawer(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.save),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: CustomUiConstants.framePage(
                enableScrolling: true,
                enableCreatorGuard: true,
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
            ),
    );
  }

  Widget _buildCard(String title, List<Widget> fields) {
    return CourseDesignerCard(
      title: title,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0)
              const SizedBox(height: CourseDesignerTheme.kCourseDesignerSpacingLarge),
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
        const SizedBox(height: CourseDesignerTheme.kCourseDesignerSpacingMedium),
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

  bool _hasProfileChanged(CourseProfile oldProfile, CourseProfile newProfile) {
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
