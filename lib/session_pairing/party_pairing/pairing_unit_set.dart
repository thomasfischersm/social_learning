import 'package:social_learning/session_pairing/party_pairing/pairing_score.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit.dart';
import 'package:social_learning/session_pairing/party_pairing/scored_participant.dart';

class PairingUnitSet {
  final List<PairingUnit> pairingUnits;
  final List<ScoredParticipant> leftOverParticipants;

  late final PairingScore score;

  PairingUnitSet(this.pairingUnits, this.leftOverParticipants) {
    computeRawScore();
  }

  String createUniqueString() {
    // Make sure that all units and learners have a consistent sort order!!!

    List<String> unitStrings = pairingUnits.map((unit) => unit.createUniqueString()).toList();

    unitStrings.sort();

    return unitStrings.join('#');
  }

  PairingScore computeRawScore() {
    score = PairingScore(this);

    // Compute set level scores.
    score!.addRawScore(.minimizeUnpairedStudents, leftOverParticipants.length.toDouble());

    // Compute score for descendants.
    for (PairingUnit pairingUnit in pairingUnits) {
      pairingUnit.computeRawScore(score!);
    }

    for (ScoredParticipant participant in leftOverParticipants) {
      participant.computeRawScore(score!);
    };

    return score!;
  }
}