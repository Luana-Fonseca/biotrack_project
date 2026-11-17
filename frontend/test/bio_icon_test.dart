import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biotrack/shared/widgets/bio_icon.dart';

void main() {
  const allIcons = [
    'leaf', 'calc', 'chart', 'book', 'user', 'plus', 'close', 'chev-r', 'chev-l', 'chev-d',
    'check', 'gas', 'twin', 'block', 'truck', 'esg', 'tree', 'money', 'route', 'file',
    'bell', 'globe', 'shield', 'logout', 'download', 'flame', 'award', 'trophy', 'edit',
    'camera', 'image', 'moon', 'lock', 'alert',
  ];

  for (final icon in allIcons) {
    testWidgets('BioIcon "$icon" builds and renders an SvgPicture without throwing', (tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: BioIcon(icon))));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unknown icon name degrades to an empty box instead of throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BioIcon('does-not-exist'))));
    expect(tester.takeException(), isNull);
  });
}
