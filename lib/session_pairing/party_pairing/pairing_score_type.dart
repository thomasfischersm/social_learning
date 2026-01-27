import 'package:social_learning/session_pairing/party_pairing/pairing_score_scheme.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score_scope.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score_weight.dart';

enum PairingScoreType {
  // Unit scope
  diversePartners(.unit, .fineTune, .maximize),
  balanceHostAccess(.unit, .fineTune, ..minimizeDispersion),
  reduceTeachingDeficit(.unit, .important, .minimizeDispersion),

  // Group scope
  finishLevelBeforeMovingOn(.group, .fineTune, .minimize)
  balanceStudentDistance(.group, .fineTune, .minimizeDispersion),
  learnNearestLesson(.group, .medium, .minimize),

  // Set scope
  prioritizeRareLessons(.set, .important, ..maximize),
  minimizeUnpairedStudents(.set, .critical, ..minimize),
  ;

  final PairingScoreScope scope;
  final PairingScoreWeight weight;
  final PairingScoreScheme scheme;

  const PairingScoreType(this.scope, this.weight, this.scheme);
}