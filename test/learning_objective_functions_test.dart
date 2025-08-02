import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_mocks/cloud_firestore_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/learning_objective_functions.dart';
import 'package:social_learning/data/firestore_service.dart';

void main() {
  late MockFirestoreInstance fake;

  setUp(() {
    fake = MockFirestoreInstance();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('addObjective creates and fetches objective', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);
    final list = await LearningObjectiveFunctions.getObjectivesForCourse('c1');
    expect(list.first.name, 'obj');
    expect(obj.name, 'obj');
  });

  test('getObjectivesForCourse returns empty when none exist', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final list = await LearningObjectiveFunctions.getObjectivesForCourse('c1');
    expect(list, isEmpty);
  });

  test('getObjectivesForCourse returns all objectives for course', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'o1', sortOrder: 0);
    await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'o2', sortOrder: 1);
    final list = await LearningObjectiveFunctions.getObjectivesForCourse('c1');
    expect(list.map((e) => e.name), containsAll(['o1', 'o2']));
  });

  test('saveObjective creates new objective', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.saveObjective(
        courseId: 'c1', sortOrder: 0, name: 'obj', description: 'desc');
    expect(obj, isNotNull);
    final snap =
        await fake.collection('learningObjectives').doc(obj!.id!).get();
    expect(snap['name'], 'obj');
    expect(snap['description'], 'desc');
  });

  test('saveObjective updates existing objective', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final created = await LearningObjectiveFunctions.saveObjective(
        courseId: 'c1', sortOrder: 0, name: 'orig');
    final teachRef = fake.collection('teachableItems').doc('t1');
    await teachRef.set({'name': 'item'});
    final updated = await LearningObjectiveFunctions.saveObjective(
        id: created!.id,
        courseId: 'c1',
        sortOrder: 1,
        name: 'updated',
        description: 'd',
        teachableItemIds: [teachRef]);
    expect(updated!.name, 'updated');
    final snap =
        await fake.collection('learningObjectives').doc(updated.id!).get();
    expect(snap['description'], 'd');
    final ids = List<DocumentReference>.from(snap['teachableItemIds']);
    expect(ids, contains(teachRef));
  });

  test('addTeachableItem and removeTeachableItem modify IDs', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);
    final itemRef = fake.collection('teachableItems').doc('ti1');
    await itemRef.set({'name': 'item'});
    await LearningObjectiveFunctions.addTeachableItem(
        objectiveId: obj.id!, teachableItemRef: itemRef);
    var snap =
        await fake.collection('learningObjectives').doc(obj.id!).get();
    var ids = List<DocumentReference>.from(snap['teachableItemIds']);
    expect(ids, contains(itemRef));
    await LearningObjectiveFunctions.removeTeachableItem(
        objectiveId: obj.id!, teachableItemRef: itemRef);
    snap = await fake.collection('learningObjectives').doc(obj.id!).get();
    ids = List<DocumentReference>.from(snap['teachableItemIds']);
    expect(ids, isEmpty);
  });

  test('updateObjective trims name and description', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'orig', sortOrder: 0);
    final updated = await LearningObjectiveFunctions.updateObjective(
        id: obj.id!, name: ' new ', description: ' desc ');
    expect(updated.name, 'new');
    expect(updated.description, 'desc');
    final snap =
        await fake.collection('learningObjectives').doc(obj.id!).get();
    expect(snap['name'], 'new');
    expect(snap['description'], 'desc');
  });

  test('deleteObjective removes document', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);
    await LearningObjectiveFunctions.deleteObjective(obj);
    final snap =
        await fake.collection('learningObjectives').doc(obj.id!).get();
    expect(snap.exists, isFalse);
  });

  test('addItemToObjective adds teachable item ref', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);
    await fake.collection('teachableItems').doc('ti1').set({'n': 'n'});
    final updated = await LearningObjectiveFunctions.addItemToObjective(
        objectiveId: obj.id!, teachableItemId: 'ti1');
    expect(updated!.teachableItemRefs.length, 1);
    final snap =
        await fake.collection('learningObjectives').doc(obj.id!).get();
    final refs = List<DocumentReference>.from(snap['teachableItemRefs']);
    expect(refs.length, 1);
    expect(refs.first.id, 'ti1');
  });

  test('replaceItemInObjective swaps teachable item ref', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);
    await fake.collection('teachableItems').doc('old').set({'n': 'o'});
    await fake.collection('teachableItems').doc('new').set({'n': 'n'});
    await LearningObjectiveFunctions.addItemToObjective(
        objectiveId: obj.id!, teachableItemId: 'old');
    await LearningObjectiveFunctions.replaceItemInObjective(
        objectiveId: obj.id!,
        oldTeachableItemId: 'old',
        newTeachableItemId: 'new');
    final snap =
        await fake.collection('learningObjectives').doc(obj.id!).get();
    final refs = List<DocumentReference>.from(snap['teachableItemRefs']);
    expect(refs.length, 1);
    expect(refs.first.id, 'new');
  });

  test('removeItemFromObjective removes teachable item ref', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final obj = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);
    await fake.collection('teachableItems').doc('ti1').set({'n': 'n'});
    await LearningObjectiveFunctions.addItemToObjective(
        objectiveId: obj.id!, teachableItemId: 'ti1');
    final updated = await LearningObjectiveFunctions.removeItemFromObjective(
        objectiveId: obj.id!, teachableItemId: 'ti1');
    expect(updated!.teachableItemRefs, isEmpty);
    final snap =
        await fake.collection('learningObjectives').doc(obj.id!).get();
    final refs = List<DocumentReference>.from(snap['teachableItemRefs']);
    expect(refs, isEmpty);
  });
}
