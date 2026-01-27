enum PairingScoreWeight {
  fineTune(1),
  medium(2),
  important(3),
  critical(4);

  final int weight;

  const PairingScoreWeight(int baseWeight) : weight = baseWeight * baseWeight;
}