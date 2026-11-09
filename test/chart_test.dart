import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:heart_bpm/chart.dart';
import 'package:heart_bpm/heart_bpm.dart';

void main() {
  testWidgets('renders no chart when all series are empty', (tester) async {
    await tester.pumpWidget(MaterialApp(home: BPMChart([], data2: [])));

    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('plots both sensor series by elapsed time', (tester) async {
    final start = DateTime(2026, 1, 1);
    final firstSeries = [
      SensorValue(time: start, value: 60),
      SensorValue(time: start.add(const Duration(seconds: 2)), value: 80),
    ];
    final secondSeries = [
      SensorValue(time: start, value: 70),
      SensorValue(time: start.add(const Duration(seconds: 2)), value: 90),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 180,
          child: BPMChart(firstSeries, data2: secondSeries),
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final series = chart.data.lineBarsData;
    expect(series, hasLength(2));
    expect(series[0].spots, [const FlSpot(0, 60), const FlSpot(2000000, 80)]);
    expect(series[1].spots, [const FlSpot(0, 70), const FlSpot(2000000, 90)]);
    expect(chart.data.minY, 60);
    expect(chart.data.maxY, 90);
  });

  testWidgets('supports a single constant sample', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 180,
          child: BPMChart([SensorValue(time: DateTime(2026, 1, 1), value: 72)]),
        ),
      ),
    );

    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.minX, -1);
    expect(chart.data.maxX, 1);
    expect(chart.data.minY, 71);
    expect(chart.data.maxY, 73);
  });
}
