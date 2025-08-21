import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/session_plan_activity_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_block_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_functions.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/session_play_activity_type.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('create session plan activity', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);
    final act = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan.id!,
      sessionPlanBlockId: block!.id!,
      activityType: SessionPlanActivityType.lesson,
      sortOrder: 0,
    );
    expect(act?.activityType, SessionPlanActivityType.lesson);
  });

  test('create activity with optional fields', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    await fake.collection('lessons').doc('l1').set({'title': 'L'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);
    final act = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan.id!,
      sessionPlanBlockId: block!.id!,
      activityType: SessionPlanActivityType.lesson,
      lessonId: 'l1',
      name: 'Activity',
      notes: 'Notes',
      overrideDuration: 15,
      sortOrder: 1,
    );
    expect(act?.lessonId?.id, 'l1');
    expect(act?.name, 'Activity');
    expect(act?.notes, 'Notes');
    expect(act?.overrideDuration, 15);
  });

  test('update activity fields and remove overrideDuration', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    await fake.collection('lessons').doc('l1').set({'title': 'L1'});
    await fake.collection('lessons').doc('l2').set({'title': 'L2'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);
    final act = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan.id!,
      sessionPlanBlockId: block!.id!,
      activityType: SessionPlanActivityType.lesson,
      lessonId: 'l1',
      name: 'Old',
      notes: 'Old notes',
      overrideDuration: 30,
      sortOrder: 0,
    );

    final updated = await SessionPlanActivityFunctions.update(
      activityId: act!.id!,
      activityType: SessionPlanActivityType.exercise,
      name: 'New',
      notes: 'New notes',
      lessonId: 'l2',
      overrideDuration: 45,
      sortOrder: 2,
    );

    expect(updated?.activityType, SessionPlanActivityType.exercise);
    expect(updated?.name, 'New');
    expect(updated?.notes, 'New notes');
    expect(updated?.lessonId?.id, 'l2');
    expect(updated?.overrideDuration, 45);
    expect(updated?.sortOrder, 2);

    final removed = await SessionPlanActivityFunctions.update(
      activityId: act.id!,
      overrideDuration: 0,
    );
    expect(removed?.overrideDuration, isNull);
  });

  test('delete activity removes document', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);
    final act = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan.id!,
      sessionPlanBlockId: block!.id!,
      activityType: SessionPlanActivityType.lesson,
      sortOrder: 0,
    );

    await SessionPlanActivityFunctions.delete(act!.id!);
    final fetched = await SessionPlanActivityFunctions.getById(act.id!);
    expect(fetched, isNull);
  });

  test('fetch by course, session plan, block, and id', () async {
    final course1 = fake.collection('courses').doc('c1');
    final course2 = fake.collection('courses').doc('c2');
    await course1.set({'title': 't1'});
    await course2.set({'title': 't2'});

    final plan1 = await SessionPlanFunctions.create(courseId: 'c1', name: 'p1');
    final plan2 = await SessionPlanFunctions.create(courseId: 'c2', name: 'p2');

    await fake.collection('sessionPlanBlocks').doc('block1').set({
      'courseId': course1,
      'sessionPlanId': fake.collection('sessionPlans').doc(plan1!.id!),
      'name': 'b1',
      'sortOrder': 0,
      'created': Timestamp.now(),
      'modified': Timestamp.now(),
    });
    await fake.collection('sessionPlanBlocks').doc('block2').set({
      'courseId': course1,
      'sessionPlanId': fake.collection('sessionPlans').doc(plan1.id!),
      'name': 'b2',
      'sortOrder': 1,
      'created': Timestamp.now(),
      'modified': Timestamp.now(),
    });
    await fake.collection('sessionPlanBlocks').doc('block3').set({
      'courseId': course2,
      'sessionPlanId': fake.collection('sessionPlans').doc(plan2!.id!),
      'name': 'b3',
      'sortOrder': 0,
      'created': Timestamp.now(),
      'modified': Timestamp.now(),
    });

    final act1 = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan1.id!,
      sessionPlanBlockId: 'block1',
      activityType: SessionPlanActivityType.lesson,
      sortOrder: 0,
    );
    final act2 = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan1.id!,
      sessionPlanBlockId: 'block1',
      activityType: SessionPlanActivityType.exercise,
      sortOrder: 1,
    );
    final act3 = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan1.id!,
      sessionPlanBlockId: 'block2',
      activityType: SessionPlanActivityType.breakTime,
      sortOrder: 0,
    );
    await SessionPlanActivityFunctions.create(
      courseId: 'c2',
      sessionPlanId: plan2.id!,
      sessionPlanBlockId: 'block3',
      activityType: SessionPlanActivityType.lesson,
      sortOrder: 0,
    );

    final byCourse = await SessionPlanActivityFunctions.getByCourse('c1');
    expect(byCourse.length, 3);

    final bySessionPlan =
        await SessionPlanActivityFunctions.getBySessionPlan(plan1.id!);
    expect(bySessionPlan.map((a) => a.id),
        [act1!.id, act2!.id, act3!.id]);

    final byBlock = await SessionPlanActivityFunctions.getByBlock('block1');
    expect(byBlock.map((a) => a.id), [act1.id, act2.id]);

    final fetched = await SessionPlanActivityFunctions.getById(act2.id!);
    expect(fetched?.id, act2.id);
  });

  test('batch update sort orders and block changes', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    await fake.collection('sessionPlanBlocks').doc('block1').set({
      'courseId': fake.collection('courses').doc('c1'),
      'sessionPlanId': fake.collection('sessionPlans').doc(plan!.id!),
      'name': 'b1',
      'sortOrder': 0,
      'created': Timestamp.now(),
      'modified': Timestamp.now(),
    });
    await fake.collection('sessionPlanBlocks').doc('block2').set({
      'courseId': fake.collection('courses').doc('c1'),
      'sessionPlanId': fake.collection('sessionPlans').doc(plan.id!),
      'name': 'b2',
      'sortOrder': 1,
      'created': Timestamp.now(),
      'modified': Timestamp.now(),
    });

    final act1 = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan.id!,
      sessionPlanBlockId: 'block1',
      activityType: SessionPlanActivityType.lesson,
      sortOrder: 0,
    );
    final act2 = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan.id!,
      sessionPlanBlockId: 'block1',
      activityType: SessionPlanActivityType.exercise,
      sortOrder: 1,
    );
    final act3 = await SessionPlanActivityFunctions.create(
      courseId: 'c1',
      sessionPlanId: plan.id!,
      sessionPlanBlockId: 'block2',
      activityType: SessionPlanActivityType.breakTime,
      sortOrder: 0,
    );

    act1!.sortOrder = 2;
    act2!
      ..sessionPlanBlockId = fake.collection('sessionPlanBlocks').doc('block2')
      ..sortOrder = 1;
    act3!
      ..sessionPlanBlockId = fake.collection('sessionPlanBlocks').doc('block1')
      ..sortOrder = 0;

    await SessionPlanActivityFunctions.updateSortOrdersAndBlockChanges(
        [act1, act2, act3]);

    final updated1 =
        await SessionPlanActivityFunctions.getById(act1.id!);
    final updated2 =
        await SessionPlanActivityFunctions.getById(act2.id!);
    final updated3 =
        await SessionPlanActivityFunctions.getById(act3.id!);

    expect(updated1?.sortOrder, 2);
    expect(updated1?.sessionPlanBlockId.id, 'block1');

    expect(updated2?.sortOrder, 1);
    expect(updated2?.sessionPlanBlockId.id, 'block2');

    expect(updated3?.sortOrder, 0);
    expect(updated3?.sessionPlanBlockId.id, 'block1');
  });
}
