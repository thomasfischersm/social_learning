import 'package:social_learning/session_pairing/party_pairing/pairing_score_type.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit_set.dart';

/// The score has two versions. The raw score is calculated based on only
/// the PairingUnitSet itself. The weighted score normalizes the raw score
/// relative to another PairingUnitSet.
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