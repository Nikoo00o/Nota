/// In rgb format
class LogColour {
  /// Red: 0 to 255
  final int r;

  /// Green: 0 to 255
  final int g;

  /// Blue: 0 to 255
  final int b;

  const LogColour(this.r, this.g, this.b);

  @override
  String toString() {
    if(r >= 255 && g >= 255 && b >= 255){
      return "\x1B[0m";
    }
    return "\x1B[38;2;$r;$g;${b}m";
  }
}
