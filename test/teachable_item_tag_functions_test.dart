import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/data/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = FirebaseFirestore.instance;
  });

  test('addTag creates a tag', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final tag = await TeachableItemTagFunctions.addTag(courseId: 'c1', name: 't', color: 'blue');
    expect(tag?.name, 't');
  });
}
