import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/firestore_service.dart';

DocumentReference<Map<String, dynamic>> docRef(
        String collectionName, String docId) =>
    // The Firebase SDK expects document paths without a leading slash.
    // Using a leading slash causes lookups to fail when working with
    // FakeFirebaseFirestore in tests, resulting in "not-found" errors.
    FirestoreService.instance.doc('$collectionName/$docId');
