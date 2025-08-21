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
    FirestoreService.instance = null;
  });

  test('addCategory creates a category', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'cat');
    expect(cat?.name, 'cat');
  });

  test('addCategory assigns incrementing sortOrder', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final first =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'a');
    final second =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'b');
    expect(first?.sortOrder, 0);
    expect(second?.sortOrder, 1);
  });

  test('bulkCreateCategories creates sequential categories', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cats = await TeachableItemCategoryFunctions.bulkCreateCategories(
        courseId: 'c1', names: ['a', 'b', 'c']);
    expect(cats.map((c) => c.name), ['a', 'b', 'c']);
    expect(cats.map((c) => c.sortOrder), [0, 1, 2]);
  });

  test('updateCategory changes the name', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'old');
    await TeachableItemCategoryFunctions.updateCategory(
        categoryId: cat!.id!, name: 'new');
    final snap =
        await fake.collection('teachableItemCategories').doc(cat.id).get();
    expect(snap.data()!['name'], 'new');
  });

  test('deleteCategory removes category, items, and updates sortOrder', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat1 =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'c1');
    final cat2 =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'c2');
    final cat3 =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'c3');

    await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat2!.id!, name: 'i1');
    await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat2.id!, name: 'i2');

    await TeachableItemCategoryFunctions.deleteCategory(categoryId: cat2.id!);

    final cat2Snap =
        await fake.collection('teachableItemCategories').doc(cat2.id).get();
    expect(cat2Snap.exists, isFalse);
    final itemsSnap = await fake.collection('teachableItems').get();
    expect(itemsSnap.docs, isEmpty);
    final cat1Snap =
        await fake.collection('teachableItemCategories').doc(cat1!.id!).get();
    final cat3Snap =
        await fake.collection('teachableItemCategories').doc(cat3!.id!).get();
    expect(cat1Snap.data()!['sortOrder'], 0);
    expect(cat3Snap.data()!['sortOrder'], 1);
  });

  test('updateCategorySortOrder reorders categories', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final c1 =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'a');
    final c2 =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'b');
    final c3 =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'c');
    await TeachableItemCategoryFunctions.updateCategorySortOrder(
        movedCategory: c3!, newIndex: 1, allCategoriesForCourse: [c1!, c2!, c3]);
    final categories =
        await TeachableItemCategoryFunctions.getCategoriesForCourse('c1');
    expect(categories.map((c) => c.name), ['a', 'c', 'b']);
    expect(categories.map((c) => c.sortOrder), [0, 1, 2]);
  });

  test('getCategoriesForCourse returns sorted categories for a course', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    await fake.collection('courses').doc('c2').set({'title': 't2'});
    final a =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'a');
    final b =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'b');
    final c =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'c');
    await fake
        .collection('teachableItemCategories')
        .doc(a!.id!)
        .update({'sortOrder': 2});
    await fake
        .collection('teachableItemCategories')
        .doc(b!.id!)
        .update({'sortOrder': 0});
    await fake
        .collection('teachableItemCategories')
        .doc(c!.id!)
        .update({'sortOrder': 1});
    await TeachableItemCategoryFunctions.addCategory(courseId: 'c2', name: 'x');
    final result =
        await TeachableItemCategoryFunctions.getCategoriesForCourse('c1');
    expect(result.length, 3);
    expect(result.map((c) => c.name), ['b', 'c', 'a']);
  });
}
