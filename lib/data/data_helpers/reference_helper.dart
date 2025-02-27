import 'package:cloud_firestore/cloud_firestore.dart';

DocumentReference<Map<String, dynamic>> docRef(
        String collectionName, String docId) =>
    FirebaseFirestore.instance.doc('/$collectionName/$docId');
