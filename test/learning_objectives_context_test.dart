import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/learning_objective_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/teachable_item_inclusion_status.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('adding item to objective selects item if needed', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final category =
        await TeachableItemCategoryFunctions.addCategory(courseId: 'c1', name: 'cat');
    final item = await TeachableItemFunctions.addItem(
        courseId: 'c1', categoryId: category!.id!, name: 'i1');
    final objective = await LearningObjectiveFunctions.addObjective(
        courseId: 'c1', name: 'obj', sortOrder: 0);

    final context = await LearningObjectivesContext.create(
      courseId: 'c1',
      refresh: () {},
    );

    final loadedObj = context.learningObjectives.first;
    final loadedItem = context.items.first;
    expect(loadedItem.inclusionStatus, TeachableItemInclusionStatus.excluded);

    await context.addTeachableItemToObjective(
        objective: loadedObj, item: loadedItem);

    expect(context.learningObjectives.first.teachableItemRefs.length, 1);
    expect(loadedItem.inclusionStatus,
        TeachableItemInclusionStatus.explicitlyIncluded);
    final fetched = await TeachableItemFunctions.getItemById(loadedItem.id!);
    expect(fetched?.inclusionStatus,
        TeachableItemInclusionStatus.explicitlyIncluded);
  });
}
