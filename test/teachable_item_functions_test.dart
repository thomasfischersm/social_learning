import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_inclusion_status.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('addItem creates a teachable item', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'cat');
    final item = await TeachableItemFunctions.addItem(courseId: 'c1', categoryId: cat!.id!, name: 'item');
    expect(item?.name, 'item');
  });

  test('bulkCreateItems inserts multiple items', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final catRef = fake.collection('teachableItemCategories').doc('cat1');
    await catRef.set({
      'courseId': fake.collection('courses').doc('c1'),
      'name': 'cat',
      'sortOrder': 0,
      'createdAt': Timestamp.now(),
      'modifiedAt': Timestamp.now(),
    });
    final courseRef = fake.collection('courses').doc('c1');
    final items = [
      TeachableItem(
        courseId: courseRef,
        categoryId: catRef,
        name: 'i1',
        notes: 'n1',
        sortOrder: 0,
        durationInMinutes: 5,
        inclusionStatus: TeachableItemInclusionStatus.excluded,
        createdAt: Timestamp.now(),
        modifiedAt: Timestamp.now(),
      ),
      TeachableItem(
        courseId: courseRef,
        categoryId: catRef,
        name: 'i2',
        notes: 'n2',
        sortOrder: 1,
        durationInMinutes: 6,
        inclusionStatus: TeachableItemInclusionStatus.excluded,
        createdAt: Timestamp.now(),
        modifiedAt: Timestamp.now(),
      ),
    ];
    final created = await TeachableItemFunctions.bulkCreateItems(items);
    expect(created.length, 2);
    final snapshot = await fake.collection('teachableItems').get();
    expect(snapshot.docs.length, 2);
    expect(created.first.name, 'i1');
  });

  test('updateItem updates fields and deleteItem reorders', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'cat');
    final i1 = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat!.id!, name: 'i1');
    final i2 = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat.id!, name: 'i2');
    await TeachableItemFunctions.updateItem(
      itemId: i1!.id!,
      name: 'i1u',
      notes: 'note',
      durationInMinutes: 10,
      inclusionStatus: TeachableItemInclusionStatus.explicitlyIncluded,
    );
    final updated = await TeachableItemFunctions.getItemById(i1.id!);
    expect(updated?.notes, 'note');
    expect(updated?.durationInMinutes, 10);
    expect(updated?.inclusionStatus,
        TeachableItemInclusionStatus.explicitlyIncluded);

    await TeachableItemFunctions.deleteItem(itemId: i1.id!);
    final remaining = await TeachableItemFunctions.getItemsForCourse('c1');
    expect(remaining.length, 1);
    expect(remaining.first.id, i2!.id);
    expect(remaining.first.sortOrder, 0);
  });

  test('updateItemSortOrder reorders within and across categories', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat1 = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'c1');
    final cat2 = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'c2');
    final i1 = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat1!.id!, name: 'i1');
    final i2 = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat1.id!, name: 'i2');
    final i3 = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat1.id!, name: 'i3');
    final list = await TeachableItemFunctions.getItemsForCourse('c1');
    await TeachableItemFunctions.updateItemSortOrder(
        allItemsAcrossCategories: list,
        movedItem: i3!,
        newCategoryRef: fake.collection('teachableItemCategories').doc(cat1.id!),
        newIndex: 0);
    var after = await TeachableItemFunctions.getItemsForCourse('c1');
    final cat1Items = after
        .where((e) => e.categoryId.id == cat1.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(cat1Items.first.id, i3.id);

    await TeachableItemFunctions.updateItemSortOrder(
        allItemsAcrossCategories: after,
        movedItem: cat1Items.first,
        newCategoryRef:
            fake.collection('teachableItemCategories').doc(cat2!.id!),
        newIndex: 0);
    after = await TeachableItemFunctions.getItemsForCourse('c1');
    final cat2Items = after
        .where((e) => e.categoryId.id == cat2.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(cat2Items.first.id, i3.id);
  });

  test('getItemsForCourse and getItemById retrieve items', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'cat');
    final item = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat!.id!, name: 'i1');
    final list = await TeachableItemFunctions.getItemsForCourse('c1');
    expect(list.length, 1);
    final fetched = await TeachableItemFunctions.getItemById(item!.id!);
    expect(fetched?.name, 'i1');
  });

  test('updateInclusionStatuses and updateDurationOverride modify fields',
      () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final cat = await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'cat');
    final i1 = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat!.id!, name: 'i1');
    final i2 = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: cat.id!, name: 'i2');
    i1!.inclusionStatus = TeachableItemInclusionStatus.explicitlyIncluded;
    TeachableItemFunctions.updateInclusionStatuses({i1}, {i2!});
    await Future.delayed(const Duration(milliseconds: 10));
    var first = await TeachableItemFunctions.getItemById(i1.id!);
    var second = await TeachableItemFunctions.getItemById(i2.id!);
    expect(first?.inclusionStatus,
        TeachableItemInclusionStatus.explicitlyIncluded);
    expect(second?.inclusionStatus, TeachableItemInclusionStatus.excluded);

    await TeachableItemFunctions.updateDurationOverride(first!, 15);
    first = await TeachableItemFunctions.getItemById(i1.id!);
    expect(first?.durationInMinutes, 15);
  });
}
