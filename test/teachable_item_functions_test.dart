import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
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

  test('addItem creates a teachable item', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'cat');
    final item = await TeachableItemFunctions.addItem(courseId: 'c1', categoryId: cat!.id!, name: 'item');
    expect(item?.name, 'item');
  });
}
