import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/firestore_service.dart';

DocumentReference<Map<String, dynamic>> docRef(
        String collectionName, String docId) =>
    FirestoreService.instance.doc('/$collectionName/$docId');
