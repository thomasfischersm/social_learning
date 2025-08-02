import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/online_session_review_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/online_session_review.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/online_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/star_rating_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

// TODO: Add lesson, user, and if learning or teaching.
class OnlineSessionReviewPage extends StatefulWidget {
  const OnlineSessionReviewPage({super.key});

  @override
  State<OnlineSessionReviewPage> createState() =>
      OnlineSessionReviewPageState();
}

class OnlineSessionReviewPageState extends State<OnlineSessionReviewPage> {
  late OnlineSessionReview _review;
  late String _otherUserUid;
  late String _otherUserLabel;
  int _partnerRating = 0;
  int _lessonRating = 0;

  final TextEditingController publicReviewController = TextEditingController();
  final TextEditingController improvementFeedbackController =
      TextEditingController();
  final TextEditingController keepDoingFeedbackController =
      TextEditingController();
  final TextEditingController reportDetailsController = TextEditingController();

  bool _blockUser = false;
  bool _reportUser = false;
  bool _isFormComplete = false;

  @override
  void initState() {
    print('OnlineSessionReviewPage.initState start');
    super.initState();

    // For our rating, we consider the form complete when both ratings are > 0.
    publicReviewController.addListener(_checkFormComplete);
    improvementFeedbackController.addListener(_checkFormComplete);
    keepDoingFeedbackController.addListener(_checkFormComplete);
    reportDetailsController.addListener(_checkFormComplete);
    _checkFormComplete();
  }

  void _checkFormComplete() {
    // Form is complete if both ratings have been provided.
    bool isComplete = (_partnerRating > 0 && _lessonRating > 0);
    if (isComplete != _isFormComplete) {
      setState(() {
        _isFormComplete = isComplete;
      });
    }
  }

  @override
  void dispose() {
    publicReviewController.dispose();
    improvementFeedbackController.dispose();
    keepDoingFeedbackController.dispose();
    reportDetailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    // Call the helper function to update the pending review.
    await OnlineSessionReviewFunctions.fillOutReview(
      reviewId: _review.id!,
      partnerRating: _partnerRating,
      lessonRating: _lessonRating,
      publicReview: publicReviewController.text.trim().isEmpty
          ? null
          : publicReviewController.text.trim(),
      improvementFeedback: improvementFeedbackController.text.trim().isEmpty
          ? null
          : improvementFeedbackController.text.trim(),
      keepDoingFeedback: keepDoingFeedbackController.text.trim().isEmpty
          ? null
          : keepDoingFeedbackController.text.trim(),
      blockUser: _blockUser,
      reportUser: _reportUser,
      reportDetails: reportDetailsController.text.trim().isEmpty
          ? null
          : reportDetailsController.text.trim(),
    );

    if (mounted) {
      OnlineSessionState onlineSessionState =
          Provider.of<OnlineSessionState>(context, listen: false);
      onlineSessionState.completeReview();
      NavigationEnum.sessionHome.navigateClean(context);
    }
  }

  Future<void> _skipReview() async {
    OnlineSessionState onlineSessionState =
        Provider.of<OnlineSessionState>(context, listen: false);

    var reviewId = _review.id;
    if (reviewId != null) {
      await OnlineSessionReviewFunctions.deleteReview(reviewId);
    }

    onlineSessionState.completeReview();

    if (mounted) {
      NavigationEnum.sessionHome.navigateClean(context);
    }
  }

  Widget _buildStarRatingSection({
    required String label,
    required int currentRating,
    required ValueChanged<int> onRatingChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: CustomTextStyles.getBody(context),
        ),
        const SizedBox(width: 8),
        StarRatingWidget(
          initialRating: currentRating,
          onRatingChanged: (rating) {
            onRatingChanged(rating);
            _checkFormComplete();
          },
          starSize: 32,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Review'),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _isFormComplete
            ? Theme.of(context).primaryColor
            : Theme.of(context).disabledColor,
        onPressed: _isFormComplete ? _submitReview : null,
        child: const Icon(Icons.check),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          SingleChildScrollView(
            child: Consumer2<OnlineSessionState, LibraryState>(
                builder: (context, onlineSessionState, libraryState, child) {
              // Get the pending review from the state.
              OnlineSessionReview? pendingReview =
                  onlineSessionState.pendingReview;
              if (pendingReview == null) {
                return const Center(child: CircularProgressIndicator());
              }
              _review = pendingReview;
              _otherUserUid =
                  _review.isMentor ? _review.learnerUid : _review.mentorUid;
              _otherUserLabel = _review.isMentor ? 'Learner' : 'Mentor';
              print('OnlineSessionReviewPage has set fields $_otherUserLabel');

              return FutureBuilder(
                  future: UserFunctions.getUserByUid(_otherUserUid),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    User otherUser = userSnapshot.data!;
                    Lesson? lesson =
                        libraryState.findLesson(_review.lessonId.id);
                    if (lesson == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            margin: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16.0),
                                      topRight: Radius.circular(16.0),
                                    ),
                                  ),
                                  child: Text(
                                    'Review the last online session',
                                    style: CustomTextStyles.subHeadline,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_otherUserLabel: ${otherUser.displayName}',
                                        style:
                                            CustomTextStyles.getBody(context),
                                      ),
                                      _buildStarRatingSection(
                                        label: '$_otherUserLabel Rating:',
                                        currentRating: _partnerRating,
                                        onRatingChanged: (rating) {
                                          setState(() {
                                            _partnerRating = rating;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Lesson: ${lesson.title}',
                                        style:
                                            CustomTextStyles.getBody(context),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      _buildStarRatingSection(
                                        label: 'Lesson Rating:',
                                        currentRating: _lessonRating,
                                        onRatingChanged: (rating) {
                                          setState(() {
                                            _lessonRating = rating;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: publicReviewController,
                                        decoration: const InputDecoration(
                                          labelText: 'Public Review (optional)',
                                          border: OutlineInputBorder(),
                                        ),
                                        minLines: 2,
                                        maxLines: 4,
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller:
                                            improvementFeedbackController,
                                        decoration: InputDecoration(
                                          label: Text(
                                            'What is one thing that ${otherUser.displayName} could improve? (optional)',
                                            maxLines: null,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        minLines: 2,
                                        maxLines: 4,
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: keepDoingFeedbackController,
                                        decoration: InputDecoration(
                                          label: Text(
                                            'What is one thing that ${otherUser.displayName} did well and should keep doing? (optional)',
                                            maxLines: null,
                                          ),
                                          border: OutlineInputBorder(),
                                        ),
                                        minLines: 2,
                                        maxLines: 4,
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _blockUser,
                                            onChanged: (value) {
                                              setState(() {
                                                _blockUser = value ?? false;
                                              });
                                            },
                                          ),
                                          const Text(
                                              'Block User (under development)'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _reportUser,
                                            onChanged: (value) {
                                              setState(() {
                                                _reportUser = value ?? false;
                                              });
                                            },
                                          ),
                                          const Text(
                                              'Report User (under development)'),
                                        ],
                                      ),
                                      if (_reportUser)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: TextField(
                                            controller: reportDetailsController,
                                            decoration: const InputDecoration(
                                              labelText:
                                                  'Report Details (optional)',
                                              border: OutlineInputBorder(),
                                            ),
                                            minLines: 2,
                                            maxLines: 4,
                                          ),
                                        ),
                                      Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: _skipReview,
                                            child: Text(
                                              'Skip',
                                              style: CustomTextStyles.getBody(
                                                  context),
                                            ),
                                          ))
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    });
                  });
            }),
          ),
        ),
      ),
    );
  }
}
