enum OnlineTimeControl {
  blitz3(0, 180, 0, '3+0', 'Blitz'),
  blitz3Plus2(1, 180, 2, '3+2', 'Blitz'),
  blitz5(2, 300, 0, '5+0', 'Blitz'),
  blitz5Plus2(3, 300, 2, '5+2', 'Blitz'),
  rapid10(4, 600, 0, '10+0', 'Rapid'),
  rapid10Plus2(5, 600, 2, '10+2', 'Rapid'),
  rapid15(6, 900, 0, '15+0', 'Rapid'),
  rapid15Plus3(7, 900, 3, '15+3', 'Rapid'),
  classical30(8, 1800, 0, '30+0', 'Classical');

  final int wireValue;
  final int initialSeconds;
  final int incrementSeconds;
  final String label;
  final String category;

  const OnlineTimeControl(
    this.wireValue,
    this.initialSeconds,
    this.incrementSeconds,
    this.label,
    this.category,
  );

  Duration get initialDuration => Duration(seconds: initialSeconds);

  static OnlineTimeControl fromWire(int? v) {
    if (v == null) return OnlineTimeControl.blitz5;
    for (final tc in OnlineTimeControl.values) {
      if (tc.wireValue == v) return tc;
    }
    return OnlineTimeControl.blitz5;
  }
}
