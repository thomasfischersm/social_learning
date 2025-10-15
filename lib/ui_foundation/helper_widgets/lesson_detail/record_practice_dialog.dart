import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/student_state.dart';

import 'package:social_learning/data/user.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class RecordPracticeDialog extends StatefulWidget {
  final Lesson lesson;

  const RecordPracticeDialog(this.lesson, {super.key});

  @override
  State<StatefulWidget> createState() => RecordPracticeDialogState();

  static void showRecordDialog(BuildContext context, Lesson lesson) {
    showDialog(
        context: context,
        builder: (context) {
          return RecordPracticeDialog(lesson);
        });
  }
}

class RecordPracticeDialogState extends State<RecordPracticeDialog> {
  final GlobalKey _learnerFieldKey = GlobalKey();

  User? _selectedLearner;
  bool _isReadyToGraduate = false;
  List<bool> _graduationRequirementsMet = [];
  double? _learnerFieldWidth;

  @override
  void initState() {
    super.initState();

    if (widget.lesson.graduationRequirements != null) {
      _graduationRequirementsMet =
          List.filled(widget.lesson.graduationRequirements!.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Record Lesson"),
      scrollable: true,
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              Navigator.pop(context);
            });
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _recordPractice, child: const Text('Record')),
      ],
      content: _buildContent(context),
    );
  }

  void _recordPractice() {
    print('Record pressed');
    User? localLearner = _selectedLearner;
    if (localLearner != null) {
      setState(() {
        Provider.of<StudentState>(context, listen: false)
            .recordTeachingWithCheck(widget.lesson, localLearner,
                _isReadyToGraduate, _graduationRequirementsMet, context);
        Navigator.pop(context);
      });
    }
  }

  void _updateLearnerFieldWidth() {
    final context = _learnerFieldKey.currentContext;
    if (context == null) return;
    final newWidth = context.size?.width;
    if (newWidth != null && newWidth != _learnerFieldWidth) {
      setState(() {
        _learnerFieldWidth = newWidth;
      });
    }
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomUiConstants.getTextPadding(Text(
            'Records that you taught a lesson.',
            style: CustomTextStyles.getBody(context))),
        Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth()
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                    child: Text('Mentor:',
                        style: CustomTextStyles.getBody(context))),
                Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ProfileImageWidgetV2
                                        .fromCurrentUser()))),
                        Expanded(
                            flex: 3,
                            child: Text('You',
                                style: CustomTextStyles.getBody(context))),
                      ],
                    )),
              ]),
              TableRow(children: [
                Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                    child: Text('Learner:',
                        style: CustomTextStyles.getBody(context))),
                Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildLearnerAutocomplete()),
              ]),
            ]),
        ..._generateGraduationRequirementsChecks(),
        ListTileTheme(
            horizontalTitleGap: 0,
            child: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                value: _isReadyToGraduate,
                onChanged: _checkGraduationRequirements()
                    ? (value) {
                        setState(() {
                          _isReadyToGraduate = value ?? false;
                        });
                      }
                    : null,
                title: Text('The learner is ready to teach this lesson.',
                    style: CustomTextStyles.getBodyEmphasized(context)))),
      ],
    );
  }

  Widget _buildLearnerAutocomplete() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateLearnerFieldWidth();
    });
    return Autocomplete<User>(
      displayStringForOption: (user) => user.displayName,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<User>.empty();
        }
        return await UserFunctions.findUsersByPartialDisplayName(
            textEditingValue.text, 10);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        Widget child;
        if (_selectedLearner != null) {
          child = InkWell(
              onTap: () {
                setState(() {
                  _selectedLearner = null;
                  textController.clear();
                });
                focusNode.requestFocus();
              },
              child: Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: AspectRatio(
                              aspectRatio: 1,
                              child: ProfileImageWidgetV2.fromUser(
                                  _selectedLearner!)))),
                  Expanded(
                      flex: 3,
                      child: Row(children: [
                        Text(_selectedLearner!.displayName,
                            style: CustomTextStyles.getBody(context)),
                        SizedBox(width: 4),
                        Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        )
                      ])),
                ],
              ));
        } else {
          child = TextField(
            controller: textController,
            focusNode: focusNode,
            style: CustomTextStyles.getBody(context),
            decoration:
                const InputDecoration(hintText: 'Start typing the name.'),
          );
        }
        return SizedBox(
            key: _learnerFieldKey, width: double.infinity, child: child);
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
            alignment: Alignment.topLeft,
            child: Material(
                elevation: 4,
                child: SizedBox(
                    width: _learnerFieldWidth,
                    height: 200,
                    child: ListView.builder(
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final user = options.elementAt(index);
                          var profileFireStoragePath =
                              user.profileFireStoragePath;
                          return InkWell(
                              onTap: () => onSelected(user),
                              child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(children: [
                                    if (profileFireStoragePath != null)
                                      Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: SizedBox.square(
                                              dimension: 32,
                                              child:
                                                  ProfileImageWidgetV2.fromUser(
                                                      user))),
                                    Expanded(
                                        child: Text(user.displayName,
                                            style: CustomTextStyles.getBody(
                                                context))),
                                  ])));
                        }))));
      },
      onSelected: (User selection) {
        setState(() {
          _selectedLearner = selection;
        });
      },
    );
  }

  List<Widget> _generateGraduationRequirementsChecks() {
    List<Widget> rows = [];
    var graduationRequirements = widget.lesson.graduationRequirements;
    if (graduationRequirements == null) {
      return rows;
    }

    for (String requirement in graduationRequirements) {
      var index = rows.length;
      rows.add(ListTileTheme(
          horizontalTitleGap: 0,
          child: CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              title:
                  Text(requirement, style: CustomTextStyles.getBody(context)),
              value: index < _graduationRequirementsMet.length
                  ? _graduationRequirementsMet[index]
                  : false,
              onChanged: (value) {
                setState(() {
                  _graduationRequirementsMet[index] = value ?? false;
                  _isReadyToGraduate =
                      _isReadyToGraduate && _checkGraduationRequirements();
                });
              })));
    }
    return rows;
  }

  bool _checkGraduationRequirements() {
    for (bool requirement in _graduationRequirementsMet) {
      if (!requirement) {
        return false;
      }
    }
    return true;
  }
}
