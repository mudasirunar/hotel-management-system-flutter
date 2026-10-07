/// Formatting utility for Pakistani Rupee amounts.
final class AppMoneyFormat {
  const AppMoneyFormat._();

  /// Formats an integer amount in PKR minor units (paisa) into a clean currency string.
  /// Example: 1500000 -> "PKR 15,000"
  static String formatPKRFromMinor(int minor) {
    final whole = (minor ~/ 100).toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]},',
    );
    return 'PKR $whole';
  }

  /// Formats a whole PKR amount into currency string.
  /// Example: 15000 -> "PKR 15,000"
  static String formatPKR(int amountPKR) => formatPKRFromMinor(amountPKR * 100);
}
