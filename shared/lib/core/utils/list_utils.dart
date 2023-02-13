class ListUtils {
  /// Always use this method if you want to compare list equality by comparing the individual elements of the list instead
  /// of the default comparison of the list references themselves!
  static bool equals(List<dynamic>? l1, List<dynamic>? l2) {
    if (l1 == null || l2 == null || l1.length != l2.length) {
      return false;
    }
    for (int i = 0; i < l1.length; ++i) {
      if (l1.elementAt(i) != l2.elementAt(i)) {
        return false;
      }
    }
    return true;
  }
}
