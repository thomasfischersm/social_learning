enum TeachableItemInclusionStatus {
  explicitlyExcluded,     // -1
  excluded,     // 0
  includedAsPrerequisite,   // 1
  explicitlyIncluded,     // 2
}

extension TeachableItemInclusionStatusX on TeachableItemInclusionStatus {
  int toInt() {
    switch (this) {
      case TeachableItemInclusionStatus.explicitlyExcluded: return -1;
      case TeachableItemInclusionStatus.excluded: return 0;
      case TeachableItemInclusionStatus.includedAsPrerequisite: return 1;
      case TeachableItemInclusionStatus.explicitlyIncluded: return 2;
    }
  }

  static TeachableItemInclusionStatus fromInt(int value) {
    switch (value) {
      case -1: return TeachableItemInclusionStatus.explicitlyExcluded;
      case 0: return TeachableItemInclusionStatus.excluded;
      case 1: return TeachableItemInclusionStatus.includedAsPrerequisite;
      case 2: return TeachableItemInclusionStatus.explicitlyIncluded;
      default: return TeachableItemInclusionStatus.excluded; // Fallback
    }
  }

  String get label {
    switch (this) {
      case TeachableItemInclusionStatus.explicitlyExcluded:
        return 'Excluded';
      case TeachableItemInclusionStatus.excluded:
        return 'Not Included';
      case TeachableItemInclusionStatus.includedAsPrerequisite:
        return 'Included (by prerequisite)';
      case TeachableItemInclusionStatus.explicitlyIncluded:
        return 'Included';
    }
  }
}
