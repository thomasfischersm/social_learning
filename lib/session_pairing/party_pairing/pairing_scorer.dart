import 'dart:math';

import 'package:social_learning/session_pairing/party_pairing/pairing_score.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score_scheme.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score_type.dart';

class PairingScorer {
  static void score(PairingScore a, PairingScore b) {
    // Reset weighted scores.
    a.weightedScores.clear();
    b.weightedScores.clear();

    // Calculate weighted scores.
    _computeWeightedScores(a, b);

    // Compute the grand score.
    _computeTotalScore(a);
    _computeTotalScore(b);
  }

  static void _computeWeightedScores(PairingScore a, PairingScore b) {
    for (PairingScoreType type in PairingScoreType.values) {
      List<double>? rawScoresA = a.rawScores[type];
      List<double>? rawScoresB = b.rawScores[type];
      if (rawScoresA == null ||
          rawScoresA.isEmpty ||
          rawScoresB == null ||
          rawScoresB.isEmpty) {
        continue;
      }

      switch (type.scheme) {
        case PairingScoreScheme.maximize:
        case PairingScoreScheme.minimize:
          double sumA = rawScoresA.reduce((value, element) => value + element);
          double sumB = rawScoresB.reduce((value, element) => value + element);
          double total = sumA + sumB;

          if (total == 0) {
            // Can only happen if both values have the same absolute value but
            // opposite sign.
            total = 1;
            if (sumA == sumB) {
              // Both sums must be null. Thus, this score doesn't add meaning.
              continue;
            } else if (sumA > sumB) {
              sumA = 1;
              sumB = 0;
            } else {
              sumA = 0;
              sumB = 1;
            }
          }

          if (type.scheme == PairingScoreScheme.maximize) {
            a.weightedScores[type] = sumA / total;
            b.weightedScores[type] = sumB / total;
          } else {
            a.weightedScores[type] = sumB / total;
            b.weightedScores[type] = sumA / total;
          }
          break;
        case PairingScoreScheme.minimizeDispersion:
          // Use standard deviation as the "dispersion" metric:
          // lower stddev => better => higher weight.
          final sdA = _stdDev(rawScoresA);
          final sdB = _stdDev(rawScoresB);

          // Convert "lower is better" into weights in [0,1] that sum to 1
          // using inverse-normalization.
          const eps = 1e-9;
          final gA = 1.0 / (sdA + eps);
          final gB = 1.0 / (sdB + eps);
          final total = gA + gB;

          final wA = total == 0.0 ? 0.5 : (gA / total);
          final wB = total == 0.0 ? 0.5 : (gB / total);

          a.weightedScores[type] = wA;
          b.weightedScores[type] = wB;
          break;
      }
    }
  }

  static double _stdDev(List<double> xs) {
    if (xs.length <= 1) return 0.0;

    final mean = xs.reduce((a, b) => a + b) / xs.length;
    var sumSq = 0.0;
    for (final x in xs) {
      final d = x - mean;
      sumSq += d * d;
    }
    final variance = sumSq / xs.length; // population variance
    return sqrt(variance);
  }

  static void _computeTotalScore(PairingScore a) {
    double total = 0.0;

    for (final entry in a.weightedScores.entries) {
      final type = entry.key;
      final weightedScore = entry.value;

      total += weightedScore * type.weight.weight;
    }

    a.totalScore = total;
  }
}
