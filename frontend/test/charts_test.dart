import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:biotrack/shared/widgets/bar_comparison.dart';
import 'package:biotrack/shared/widgets/charts.dart';

void main() {
  testWidgets('BioLineChart renders with a typical 12-point series', (tester) async {
    final values = List.generate(12, (i) => (i * 10).toDouble());
    final labels = List.generate(12, (i) => 'M$i');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BioLineChart(values: values, labels: labels))));
    expect(tester.takeException(), isNull);
  });

  testWidgets('BioLineChart does not throw with a single point (avoids div-by-zero in step calc)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BioLineChart(values: [42], labels: ['A']))));
    expect(tester.takeException(), isNull);
  });

  testWidgets('BioLineChart does not throw with all-zero points (avoids div-by-zero in max scaling)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BioLineChart(values: [0, 0, 0], labels: ['A', 'B', 'C']))));
    expect(tester.takeException(), isNull);
  });

  testWidgets('BioLineChart renders a dashed projected tail without throwing', (tester) async {
    final values = List.generate(9, (i) => (i * 10).toDouble());
    final labels = List.generate(9, (i) => 'M$i');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: BioLineChart(values: values, labels: labels, filled: true, projectedFromIndex: 6)),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('BioLineChart ignores an out-of-range projectedFromIndex instead of throwing', (tester) async {
    final values = List.generate(5, (i) => (i * 10).toDouble());
    final labels = List.generate(5, (i) => 'M$i');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: BioLineChart(values: values, labels: labels, projectedFromIndex: 50)),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('BarComparison renders with a specific fossil-fuel label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BarComparison(leftLabel: 'Combustível fóssil', leftValue: 1300, rightLabel: 'Biometano', rightValue: 520)),
    ));
    expect(find.text('Combustível fóssil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BarComparison does not throw when both values are zero (fresh account, no calculations yet)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BarComparison(leftLabel: 'Fóssil', leftValue: 0, rightLabel: 'Biometano', rightValue: 0)),
    ));
    expect(tester.takeException(), isNull);
  });
}
