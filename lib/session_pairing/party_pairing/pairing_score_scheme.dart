enum PairingScoreScheme {
  /// Higher raw is better.
  maximize,

  /// Lower raw is better.
  minimize,

  /// Lower dispersion is better (e.g., stddev/variance/IQR of per-person values).
  minimizeDispersion,
}