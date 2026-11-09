import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'heart_bpm.dart';

/// Generate a simple heart BPM graph
class BPMChart extends StatelessWidget {
  /// Data series formatted for plotting.
  ///
  /// The first series is blue and the optional second series is green.
  final List<List<SensorValue>> _data;

  /// Generate the heart BPM graph from given list of [data] of type
  /// [SensorValue]
  BPMChart(
    /// List of [SensorValue] data points to be plotted
    List<SensorValue> data, {

    /// List of second series of [SensorValue] data points to be plotted
    List<SensorValue>? data2,
  }) : _data = [data, if (data2 != null) data2];

  @override
  Widget build(BuildContext context) {
    final series = _data.where((data) => data.isNotEmpty).toList();
    if (series.isEmpty) return const SizedBox.shrink();

    final values = series.expand((data) => data).toList();
    // fl_chart uses numeric x coordinates; elapsed time avoids large epoch values.
    final startTime = values
        .map((value) => value.time)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final spots = series.map((data) {
      return data
          .map(
            (value) => FlSpot(
              value.time.difference(startTime).inMicroseconds.toDouble(),
              value.value.toDouble(),
            ),
          )
          .toList();
    }).toList();
    final minY = values
        .map((value) => value.value.toDouble())
        .reduce((a, b) => a < b ? a : b);
    final maxY = values
        .map((value) => value.value.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final minX = spots
        .expand((data) => data)
        .map((spot) => spot.x)
        .reduce((a, b) => a < b ? a : b);
    final maxX = spots
        .expand((data) => data)
        .map((spot) => spot.x)
        .reduce((a, b) => a > b ? a : b);

    // Expand degenerate ranges so single-point and constant series remain visible.
    return LineChart(
      LineChartData(
        minX: minX == maxX ? minX - 1 : minX,
        maxX: minX == maxX ? maxX + 1 : maxX,
        minY: minY == maxY ? minY - 1 : minY,
        maxY: minY == maxY ? maxY + 1 : maxY,
        lineBarsData: [
          for (var i = 0; i < spots.length; i++)
            LineChartBarData(
              spots: spots[i],
              color: i == 0 ? Colors.blue : Colors.green,
              dotData: FlDotData(show: spots[i].length == 1),
            ),
        ],
        // Keep the chart compact by hiding axes, grid lines, and touch overlays.
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
