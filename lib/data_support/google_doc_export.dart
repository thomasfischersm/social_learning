import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/docs/v1.dart';
import 'package:intl/intl.dart';
import 'package:social_learning/data_support/Json_curriculum_sync.dart';
import 'package:social_learning/globals.dart';

class GoogleDocExport {
  static Future<String?> export() async {
    // Sign in.
    var googleSignIn = await createClient();
    if (googleSignIn == null) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content: Text("Failed to get permission to access Google Docs."),
      ));
      return Future.value(null);
    }

    // Create Google doc.
    var authClient = await googleSignIn.authenticatedClient();
    var docsApi = DocsApi(authClient!);
    var docTitle =
        'Social Learning Export On ${DateFormat().format(DateTime.now())}';
    var doc = await docsApi.documents.create(Document(title: docTitle));

    // Export data.
    var documentId = doc.documentId;
    if (documentId != null) {
      await _exportCourses(docsApi, documentId, doc.revisionId!);
    }

    return documentId;
  }

  static Future<GoogleSignIn?> createClient() async {
    var googleSignIn = GoogleSignIn(
        clientId:
            '518330283384-41akqio9j5lhuqp5pb4e0jp29qo30ttp.apps.googleusercontent.com',
        scopes: <String>[
          'https://www.googleapis.com/auth/drive.file',
        ]);
    var account = await googleSignIn.signIn();

    if (account == null) {
      return Future.value(null);
    }

    return googleSignIn;
  }

  static Future<void> _exportCourses(
      DocsApi docsApi, String documentId, String revisionId) async {
    // Get and parse JSON.
    // String? rawJson = await JsonCurriculumSync.export();
    String? rawJson = await rootBundle.loadString('curriculum.json');
    if (rawJson == null) {
      return;
    }
    var json = const JsonDecoder().convert(rawJson);

    // var structuralElements = <StructuralElement>[];
    // var body = Body(content: structuralElements = structuralElements);
    var requests = <Request>[];
    int index = 1;

    // Export courses.
    var coursesJson = json['courses'];
    for (int i = 0; i < coursesJson.length; i++) {
      // id, title, description
      var courseJson = coursesJson[i];
      index += _addParagraphText(
          requests, index, 'Course: ${courseJson['title']}', 'HEADING_1');
      index += _addBulletedText(
          requests, index, 'ID: ${courseJson['id']}');
      index += _addBulletedText(requests, index,
          'Description: ${courseJson['description']}');
      index += _addTwoEmptyLines(requests);

      var levelsJson = courseJson['levels'];
      if (levelsJson != null) {
        for (int i = 0; i < levelsJson.length; i++) {
          var levelJson = levelsJson[i];
          // id, title, description, courseId
          index += _addParagraphText(
              requests, index, 'Level: ${levelJson['title']}', 'HEADING_2');
          index += _addBulletedText(
              requests, index, 'ID: ${levelJson['id']}');
          index += _addBulletedText(requests, index,
              'Course ID: ${levelJson['courseId']}');
          index += _addBulletedText(requests, index,
              'Description: ${levelJson['description']}');
          index += _addTwoEmptyLines(requests);

          var lessonsJson = levelJson['lessons'];
          if (lessonsJson != null) {
            for (int i = 0; i < lessonsJson.length; i++) {
              var lessonJson = lessonsJson[i];
              //       "id": "XSqol2tr5BWGsgpupl2u",
              // "courseId": "/courses/V4UYTsc7mK4oEHNLFXMU",
              // "levelId": "/levels/aMJr0w0sSgTvQoQb3KH3",
              // "title": "Warm-up 1: Flashlights",
              // "synopsis": "Builds specific strength for hand connection.",
              // "instructions": "1. Present your palms facing forward.\n2. Let your hand close a little.\n3. Press the two knuckles at the base of the index and middle finger forward.\n4. Repeatedly press and relax the two knuckles forward.\n\nNote:---\nIt's easy to simply open and close the hand and completely miss the point of the exercise. Recall how in yoga pose during downward dog, the inside of the palm often floats up. The exercise is to consciously push the palm down.\n\nMotivation---\nThe hand-to-hand connection is critical in acroyoga. People often fatigue and let the hand-to-hand connection deteriorate and hurt their partner. This somewhat tedious exercise helps you take better care of your partner.",
              // "cover": "assets/covers/level-1-warmup-1-flashlights.jpg",
              // "recapVideo": "https://youtube.com/shorts/i97ILmzPuOM",
              // "lessonVideo": "https://youtu.be/qA76XhZfuhQ",
              // "practiceVideo": null
              index += _addParagraphText(requests, index,
                  'Level: ${lessonJson['title']}', 'HEADING_3');
              index += _addBulletedText(
                  requests, index, 'ID: ${lessonJson['id']}');
              index += _addBulletedText(requests, index,
                  'Course ID: ${lessonJson['courseId']}');
              index += _addBulletedText(requests, index,
                  'Level ID: ${lessonJson['levelId']}');
              index += _addBulletedText(requests, index,
                  'Synopsis: ${lessonJson['synopsis']}');
              index += _addBulletedText(requests, index,
                  'Cover: ${lessonJson['cover']}');
              index += _addBulletedText(requests, index,
                  'Recap video: ${lessonJson['recapVideo']}');
              index += _addBulletedText(requests, index,
                  'Lesson video: ${lessonJson['lessonVideo']}');
              index += _addBulletedText(
                  requests,
                  index,
                  'Practice video: ${lessonJson['practiceVideo']}');
              index += _addTwoEmptyLines(requests);
              index += _addParagraphText(
                  requests, index, lessonJson['instructions'], 'NORMAL_TEXT');
              index += _addTwoEmptyLines(requests);
            }
          }
        }
      }
    }

    // Talk to the server.
    var request = BatchUpdateDocumentRequest(
        requests: requests,
        writeControl: WriteControl(targetRevisionId: revisionId));
    await docsApi.documents.batchUpdate(request, documentId);
  }

  static int _addParagraphText(
      requests, int index, String text, String namedStyleType) {
    text += '\n';

    requests.add(Request(
        insertText: InsertTextRequest(
            endOfSegmentLocation: EndOfSegmentLocation(), text: text)));
    requests.add(Request(
        updateParagraphStyle: UpdateParagraphStyleRequest(
            fields: 'namedStyleType',
            paragraphStyle: ParagraphStyle(namedStyleType: namedStyleType),
            range: Range(startIndex: index, endIndex: index + text.length - 1))));

    return text.length;
  }

  static int _addBulletedText(
      requests, int index, String text) {
    text += '\n';

    requests.add(Request(
        insertText: InsertTextRequest(
            endOfSegmentLocation: EndOfSegmentLocation(), text: text)));
    requests.add(Request(
        createParagraphBullets: CreateParagraphBulletsRequest(
            bulletPreset: 'BULLET_DISC_CIRCLE_SQUARE',
            range: Range(startIndex: index, endIndex: index + text.length - 1))));

    return text.length;
  }

  static int _addTwoEmptyLines(requests) {
    requests.add(Request(
        insertText: InsertTextRequest(
            endOfSegmentLocation: EndOfSegmentLocation(), text: "\n\n")));
    return 2;
  }
}
