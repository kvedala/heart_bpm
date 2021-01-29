library heart_bpm;

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'heart_bpm.dart';

/// Generate a simple heart BPM graph
class BPMChart extends StatelessWidget {
  /// Data series formatted to be plotted
  final List<charts.Series<SensorValue, DateTime>> _data;

  /// Generate the heart BPM graph from given list of [data] of type
  /// [SensorValue]
  BPMChart(
    /// List of [SensorValue] data points to be plotted
    List<SensorValue> data, {

    /// List of second series of [SensorValue] data points to be plotted
    List<SensorValue> data2,
  }) : _data = data2 == null
            ? [_updateChartData(data)]
            : [_updateChartData(data), _updateChartData(data2, 2)];

  /// Function to convert as list of [SensorValue] to [Series] ready for
  /// plotting
  static charts.Series<SensorValue, DateTime> _updateChartData(
      List<SensorValue> data,
      [int seriesNumber = 1]) {
    return charts.Series<SensorValue, DateTime>(
      id: "BPM",
      colorFn: (datum, index) => seriesNumber == 1
          ? charts.MaterialPalette.blue.shadeDefault
          : charts.MaterialPalette.green.shadeDefault,
      domainFn: (datum, index) => datum.time,
      measureFn: (datum, index) => datum.value,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    num min = _data[0]
            .data
            .reduce((value, element) =>
                (value.value < element.value) ? value : element)
            .value,
        max = _data[0]
            .data
            .reduce((value, element) =>
                (value.value > element.value) ? value : element)
            .value;

    return charts.TimeSeriesChart(
      _data,
      primaryMeasureAxis: charts.NumericAxisSpec(
        showAxisLine: false,
        renderSpec: charts.NoneRenderSpec(),
        viewport: charts.NumericExtents(min, max),
        tickProviderSpec:
            charts.StaticNumericTickProviderSpec(<charts.TickSpec<num>>[
          charts.TickSpec<num>(min),
          charts.TickSpec<num>(max),
        ]),
      ),
      domainAxis: charts.DateTimeAxisSpec(
        renderSpec: charts.NoneRenderSpec(),
        showAxisLine: false,
        // viewport: charts.DateTimeExtents(
        //   start: _data[0].data.first.time,
        //   end: _data[0].data.last.time,
        // ),
        // tickProviderSpec: charts.AutoDateTimeTickProviderSpec(),
      ),
      // Optionally pass in a [DateTimeFactory] used by the chart. The factory
      // should create the same type of [DateTime] as the data provided. If none
      // specified, the default creates local date time.
      dateTimeFactory: const charts.LocalDateTimeFactory(),
    );
  }
}
