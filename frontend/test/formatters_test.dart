import 'package:flutter_test/flutter_test.dart';

import 'package:biotrack/core/formatters.dart';

void main() {
  test('fmtNumber adds thousands separators', () {
    expect(fmtNumber(1234567), '1.234.567');
    expect(fmtNumber(850), '850');
  });

  test('fmtNumber respects decimals', () {
    expect(fmtNumber(1234.5, 1), '1.234,5');
  });

  test('fmtBRL prefixes with R\$', () {
    expect(fmtBRL(1234.5), 'R\$ 1.234,50');
  });
}
