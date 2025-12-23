enum SessionType {
  automaticManual(1),
  powerMode(2),
  partyModeDuo(3),
  partyModeTrio(4);

  const SessionType(this.value);

  final int value;

  int toInt() => value;

  static SessionType fromInt(int? value) {
    switch (value) {
      case 1:
        return SessionType.automaticManual;
      case 2:
        return SessionType.powerMode;
      case 3:
        return SessionType.partyModeDuo;
      case 4:
        return SessionType.partyModeTrio;
      default:
        return SessionType.automaticManual;
    }
  }
}
