/// Format integer minor units without rounding through floating-point values.
String priceInput(int minor) =>
    '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';

String formatPkr(int minor) {
  final parts = priceInput(minor).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  return 'PKR $whole.${parts.last}';
}
