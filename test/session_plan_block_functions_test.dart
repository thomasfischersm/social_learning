import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/session_plan_block_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_functions.dart';
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

  test('create session plan block', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);
    expect(block?.name, 'b');
  });

  test('update session plan block', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);

    final updated = await SessionPlanBlockFunctions.update(
        blockId: block!.id!, name: 'b2', sortOrder: 5);
    expect(updated?.name, 'b2');
    expect(updated?.sortOrder, 5);

    final missing = await SessionPlanBlockFunctions.update(
        blockId: 'missing', name: 'x');
    expect(missing, isNull);
  });

  test('delete session plan block', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);

    await SessionPlanBlockFunctions.delete(block!.id!);
    final fetched = await SessionPlanBlockFunctions.getById(block.id!);
    expect(fetched, isNull);
  });

  test('get blocks by course', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    await fake.collection('courses').doc('c2').set({'title': 't2'});
    final plan1 = await SessionPlanFunctions.create(courseId: 'c1', name: 'p1');
    final plan2 = await SessionPlanFunctions.create(courseId: 'c2', name: 'p2');
    final block1 = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan1!.id!, name: 'b1', sortOrder: 0);
    final block2 = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan1.id!, name: 'b2', sortOrder: 1);
    await SessionPlanBlockFunctions.create(
        courseId: 'c2', sessionPlanId: plan2!.id!, name: 'other', sortOrder: 0);

    final blocks = await SessionPlanBlockFunctions.getByCourse('c1');
    final ids = blocks.map((b) => b.id).toSet();
    expect(ids, {block1!.id, block2!.id});
  });

  test('get blocks by session plan ordered by sortOrder', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b1', sortOrder: 1);
    await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan.id!, name: 'b0', sortOrder: 0);

    final blocks = await SessionPlanBlockFunctions.getBySessionPlan(plan.id!);
    expect(blocks.length, 2);
    expect(blocks.first.sortOrder, lessThan(blocks.last.sortOrder));
  });

  test('get session plan block by id', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);

    final fetched = await SessionPlanBlockFunctions.getById(block!.id!);
    expect(fetched?.name, 'b');
  });

  test('batch update sort orders', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block1 = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b1', sortOrder: 0);
    final block2 = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan.id!, name: 'b2', sortOrder: 1);
    final block3 = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan.id!, name: 'b3', sortOrder: 2);

    block1!.sortOrder = 2;
    block2!.sortOrder = 0;
    block3!.sortOrder = 1;
    await SessionPlanBlockFunctions.batchUpdateSortOrders(
        [block1, block2, block3]);

    final blocks = await SessionPlanBlockFunctions.getBySessionPlan(plan.id!);
    expect(blocks.map((b) => b.id), [block2.id, block3.id, block1.id]);
  });
}
