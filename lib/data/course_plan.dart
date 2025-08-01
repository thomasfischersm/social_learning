import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';

class CoursePlan {
  String? id;
  DocumentReference courseId;
  String planJson; // input plan
  String? generatedJson; // output from ChatGPT (levels + lessons)
  Timestamp? created;

  CoursePlan({
    this.id,
    required this.courseId,
    required this.planJson,
    this.generatedJson,
    this.created,
  });

  CoursePlan.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        planJson = e.data()['planJson'] as String,
        generatedJson = e.data()['generatedJson'] as String?,
        created = e.data()['created'] as Timestamp?;

  CoursePlan.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
      : id = doc.id,
        courseId = doc.data()?['courseId'] as DocumentReference,
        planJson = doc.data()?['planJson'] as String,
        generatedJson = doc.data()?['generatedJson'] as String?,
        created = doc.data()?['created'] as Timestamp?;

  Map<String, dynamic> toMap() => {
    'courseId': courseId,
    'planJson': planJson,
    if (generatedJson != null) 'generatedJson': generatedJson,
    'created': created ?? FieldValue.serverTimestamp(),
  };

  DocumentReference get docRef => docRef('coursePlans', id!);

  static CollectionReference<Map<String, dynamic>> get collection =>
      FirebaseFirestore.instance.collection('coursePlans');
}