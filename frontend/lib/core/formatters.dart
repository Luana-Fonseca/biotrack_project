String fmtNumber(num value, [int decimals = 0]) {
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final intPart = parts[0];
  final negative = intPart.startsWith('-');
  final digits = negative ? intPart.substring(1) : intPart;
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final grouped = (negative ? '-' : '') + buffer.toString();
  if (parts.length == 1) return grouped;
  return '$grouped,${parts[1]}';
}

String fmtBRL(num value) => 'R\$ ${fmtNumber(value, 2)}';

String fmtDateShort(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
}
