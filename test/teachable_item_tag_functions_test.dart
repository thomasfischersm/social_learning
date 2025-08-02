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
    FirestoreService.instance = null;
  });

  test('addTag creates a tag', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final tag = await TeachableItemTagFunctions.addTag(courseId: 'c1', name: 't', color: 'blue');
    expect(tag?.name, 't');
  });

  test('updateTag updates name and color', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final tag = await TeachableItemTagFunctions.addTag(
        courseId: 'c1', name: 'old', color: 'red');

    await TeachableItemTagFunctions.updateTag(
        tagId: tag!.id!, name: 'new', color: 'blue');

    final snapshot =
        await fake.collection('teachableItemTags').doc(tag.id!).get();
    expect(snapshot.data()!['name'], 'new');
    expect(snapshot.data()!['color'], 'blue');
  });

  test('deleteTag removes tag and its references from items', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final tag = await TeachableItemTagFunctions.addTag(
        courseId: 'c1', name: 'tag', color: 'red');

    final tagRef = fake.collection('teachableItemTags').doc(tag!.id!);
    await fake.collection('teachableItems').doc('i1').set({
      'tagIds': [tagRef],
    });

    await TeachableItemTagFunctions.deleteTag(tagId: tag.id!);

    final tagSnapshot =
        await fake.collection('teachableItemTags').doc(tag.id!).get();
    expect(tagSnapshot.exists, false);

    final itemSnapshot =
        await fake.collection('teachableItems').doc('i1').get();
    final tagIds = itemSnapshot.data()!['tagIds'] as List;
    expect(tagIds, isEmpty);
  });

  test('getTagsForCourse returns tags in alphabetical order', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    await fake.collection('courses').doc('c2').set({'title': 'x'});

    await TeachableItemTagFunctions.addTag(
        courseId: 'c1', name: 'beta', color: 'blue');
    await TeachableItemTagFunctions.addTag(
        courseId: 'c1', name: 'alpha', color: 'red');
    await TeachableItemTagFunctions.addTag(
        courseId: 'c2', name: 'gamma', color: 'green');

    final tags = await TeachableItemTagFunctions.getTagsForCourse('c1');
    expect(tags.map((t) => t.name).toList(), ['alpha', 'beta']);
  });

  test('getTagsForCourse returns empty list when course has no tags', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final tags = await TeachableItemTagFunctions.getTagsForCourse('c1');
    expect(tags, isEmpty);
  });
}
