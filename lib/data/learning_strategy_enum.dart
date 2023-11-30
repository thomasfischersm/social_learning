
enum LearningStrategyEnum {
  completeBeforeAdvance(1),
  advanceFast(2),
  balanced(3);

  final int value;
  const LearningStrategyEnum(this.value);

  static get preferred => completeBeforeAdvance;
}