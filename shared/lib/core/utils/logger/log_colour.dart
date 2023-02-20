/// In rgb format
class LogColour {
  /// Red
  final int r;

  /// Green
  final int g;

  /// Blue
  final int b;

  const LogColour(this.r, this.g, this.b);

  @override
  String toString() {
    return "\x1b[38;2;$r;$g;${b}m";
  }
}
