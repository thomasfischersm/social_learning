enum TeachableItemInclusionStatus {
  explicitlyExcluded(-1, 'Excluded'),
  excluded(0, 'Not Included'),
  includedAsPrerequisite(1, 'Included (by prerequisite)'),
  explicitlyIncluded(2, 'Included');

  const TeachableItemInclusionStatus(this.value, this.label);

  final int value;
  final String label;

  int toInt() => value;

  static TeachableItemInclusionStatus fromInt(int value) {
    switch (value) {
      case -1:
        return TeachableItemInclusionStatus.explicitlyExcluded;
      case 0:
        return TeachableItemInclusionStatus.excluded;
      case 1:
        return TeachableItemInclusionStatus.includedAsPrerequisite;
      case 2:
        return TeachableItemInclusionStatus.explicitlyIncluded;
      default:
        return TeachableItemInclusionStatus.excluded; // Fallback
    }
  }
}
