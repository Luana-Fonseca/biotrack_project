import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biotrack/core/theme.dart';

void main() {
  testWidgets('app theme builds without throwing', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildAppTheme(), home: const Scaffold(body: SizedBox())));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark theme builds without throwing', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: buildAppDarkTheme(), home: const Scaffold(body: SizedBox())));
    expect(tester.takeException(), isNull);
  });
}
