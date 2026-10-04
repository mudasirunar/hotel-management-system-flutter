/// Guest records already contain canonical, domain-validated values.
String formatCnic(String digits) =>
    '${digits.substring(0, 5)}-${digits.substring(5, 12)}-${digits.substring(12)}';

String maskedCnic(String digits) =>
    '•••••-••••${digits.substring(9, 12)}-${digits.substring(12)}';

String formatPhone(String phone) =>
    '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
