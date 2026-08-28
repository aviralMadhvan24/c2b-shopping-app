class CurrencyFormatter {
  /// Formats a number as Indian Rupee with proper comma separation.
  /// e.g. 69900 → ₹69,900 | 1499 → ₹1,499 | 28 → ₹28
  static String formatINR(double amount) {
    // Handle the whole number part
    final intPart = amount.toInt();
    final isWholeNumber = (amount - intPart).abs() < 0.01;

    final numStr = intPart.toString();
    final formatted = _addIndianCommas(numStr);

    if (isWholeNumber) {
      return '₹$formatted';
    } else {
      final decimal = ((amount - intPart) * 100).round().toString().padLeft(2, '0');
      return '₹$formatted.$decimal';
    }
  }

  /// Adds commas to a number string following Indian numbering system
  /// (XX,XX,XXX pattern after the first 3 digits from right)
  static String _addIndianCommas(String numStr) {
    if (numStr.length <= 3) return numStr;

    // Last 3 digits
    final lastThree = numStr.substring(numStr.length - 3);
    final remaining = numStr.substring(0, numStr.length - 3);

    // Add commas every 2 digits from right in the remaining part
    final buffer = StringBuffer();
    for (int i = 0; i < remaining.length; i++) {
      if (i > 0 && (remaining.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(remaining[i]);
    }
    buffer.write(',');
    buffer.write(lastThree);
    return buffer.toString();
  }
}
