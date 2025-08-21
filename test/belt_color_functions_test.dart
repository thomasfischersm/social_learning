import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
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

  test('getBeltColor returns white for zero progress', () {
    final color = BeltColorFunctions.getBeltColor(0);
    expect(color, BeltColorFunctions.colors.first);
  });

  test('getBeltColor returns black for full proficiency', () {
    final color = BeltColorFunctions.getBeltColor(1);
    expect(color, BeltColorFunctions.colors.last);
  });

  test('getBeltColor returns purple for half proficiency', () {
    final color = BeltColorFunctions.getBeltColor(0.5);
    expect(color, BeltColorFunctions.colors[4]);
  });

  test('getBeltColor throws ArgumentError when proficiency below zero', () {
    expect(() => BeltColorFunctions.getBeltColor(-0.1), throwsArgumentError);
  });

  test('getBeltColor throws ArgumentError when proficiency above one', () {
    expect(() => BeltColorFunctions.getBeltColor(1.1), throwsArgumentError);
  });

  test('getBeltColor interpolates between adjacent colors for non integer proficiency', () {
    final color = BeltColorFunctions.getBeltColor(0.33);
    final colorIndex =
        (BeltColorFunctions.colors.length - 1) * 0.33;
    final lowerIndex = colorIndex.floor();
    final upperIndex = colorIndex.ceil();
    final lowerColor = BeltColorFunctions.colors[lowerIndex];
    final upperColor = BeltColorFunctions.colors[upperIndex];
    expect(color, isNot(equals(lowerColor)));
    expect(color, isNot(equals(upperColor)));
  });
}
