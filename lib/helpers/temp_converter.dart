class TempConverter {
  static double convert({
    required double value,
    required String from,
    required String to,
  }) {
    if (from == to) return value;

    double c = value;

    switch (from) {
      case 'f':
        c = (value - 32) * 5 / 9;
        break;
      case 'k':
        c = value - 273.15;
        break;
    }

    switch (to) {
      case 'f':
        return c * 9 / 5 + 32;
      case 'k':
        return c + 273.15;
      default:
        return c;
    }
  }
}
