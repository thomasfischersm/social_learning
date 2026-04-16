import 'package:social_learning/session_pairing/party_pairing/pairing_score.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score_type.dart';
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

  void debugPrint() {
    print('----- start pairing unit set ----');

    for (int i = 0; i < pairingUnits.length; i++) {
      print('$i. PairingUnit');
      PairingUnit pairingUnit = pairingUnits[i];
      print('Lesson: ${pairingUnit.lesson.title}');
      print('Mentor: ${pairingUnit.mentor.user.displayName}');

      for (ScoredParticipant scoredParticipant in pairingUnit.learners) {
        print('Learner: ${scoredParticipant.user.displayName}');
      }
      print('');
    }

    print('Leftover participants');
    for (ScoredParticipant scoredParticipant in leftOverParticipants) {
      print('- ${scoredParticipant.user.displayName}');
    }

    print('----- end pairing unit set ----');
  }

  void debugPrintSingleLine() {
    StringBuffer sb = StringBuffer();
    sb.write('PairingUnitSet: ');

    for (PairingUnit pairingUnit in pairingUnits) {
      sb.write('[${pairingUnit.lesson.title}=');
      sb.write('${pairingUnit.mentor.user.displayName}; ');
      for (ScoredParticipant scoredParticipant in pairingUnit.learners) {
        sb.write('${scoredParticipant.user.displayName}, ');
      }
      sb.write('] ');
    }

    sb.write('[leftover=');
    for (ScoredParticipant scoredParticipant in leftOverParticipants) {
      sb.write('${scoredParticipant.user.displayName}, ');
    }
    sb.write(']');

    sb.write(' score: ${score.totalScore}, weighted = {');
    for (MapEntry<PairingScoreType, double> entry in score.weightedScores.entries) {
      sb.write('${entry.key.name}=${entry.value}, ');
    }
    sb.write('}');

    sb.write(', raw = {');
    for (MapEntry<PairingScoreType, List<double>> entry in score.rawScores.entries) {
      sb.write('${entry.key.name}=(');
      for (double value in entry.value) {
        sb.write('$value, ');
      }
      sb.write(') ');
    }
    sb.write('}');

    print(sb);
  }
}