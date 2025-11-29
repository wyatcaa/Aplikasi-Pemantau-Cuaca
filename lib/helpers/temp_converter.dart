class TempConverter {
  static double convert({
    required double value,
    required String from,
    required String to,
  }) {
    if (from == to) return value;

    double c = value;

    // Convert TO CELSIUS first
    switch (from) {
      case 'f':
        c = (value - 32) * 5 / 9;
        break;
      case 'k':
        c = value - 273.15;
        break;
      case 'r':
        c = value * 5 / 4;
        break;
    }

    // Convert FROM CELSIUS to target
    switch (to) {
      case 'f':
        return c * 9 / 5 + 32;
      case 'k':
        return c + 273.15;
      case 'r':
        return c * 4 / 5;
      default:
        return c;
    }
  }
}
