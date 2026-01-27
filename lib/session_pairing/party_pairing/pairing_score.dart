import 'package:social_learning/session_pairing/party_pairing/pairing_score_type.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit_set.dart';

class PairingScore {
  final PairingUnitSet pairingUnitSet;
  final Map<PairingScoreType, List<double>> rawScores = {};
  final Map<PairingScoreType, double> weightedScores = {};
  double? totalScore;

  PairingScore(this.pairingUnitSet);

  void addRawScore(PairingScoreType type, double value) {
    rawScores.putIfAbsent(type, () => []).add(value);
  }
}