import 'dart:async';

import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

import 'sensor_value.dart';

/// Generate a simple heart BPM graph
class BPMChart extends StatelessWidget {
  /// Data series formatted to be plotted
  final List<BPMSensorValue> _data = [];

  /// Generate the heart BPM graph from given list of [data] of type
  /// [BPMSensorValue]
  BPMChart({Key? key}) : super(key: key);

  final _streamer = StreamController<charts.Series<BPMSensorValue, DateTime>>();

  /// Function to convert as list of [SensorValue] to [Series] ready for
  /// plotting
  void updateChartData(BPMSensorValue data, [int seriesNumber = 1]) {
    _data.add(data);
    _streamer.add(charts.Series<BPMSensorValue, DateTime>(
      id: "BPM",
      colorFn: (datum, index) => seriesNumber == 1
          ? charts.MaterialPalette.blue.shadeDefault
          : charts.MaterialPalette.green.shadeDefault,
      domainFn: (datum, index) => datum.time,
      measureFn: (datum, index) => datum.value,
      data: _data,
    ));
  }

  final List<charts.Series<BPMSensorValue, DateTime>> _chartData = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<charts.Series<BPMSensorValue, DateTime>>(
      stream: _streamer.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        if (_chartData.length >= 100) _chartData.removeAt(0);
        _chartData.add(snapshot.data!);
        final min = _data
                .reduce((value, element) =>
                    (value.value < element.value) ? value : element)
                .value,
            max = _data
                .reduce((value, element) =>
                    (value.value > element.value) ? value : element)
                .value;
        return charts.TimeSeriesChart(
          _chartData,
          primaryMeasureAxis: charts.NumericAxisSpec(
            showAxisLine: false,
            renderSpec: const charts.NoneRenderSpec(),
            viewport: charts.NumericExtents(min, max),
            tickProviderSpec:
                charts.StaticNumericTickProviderSpec(<charts.TickSpec<num>>[
              charts.TickSpec<num>(min),
              charts.TickSpec<num>(max),
            ]),
          ),
          domainAxis: const charts.DateTimeAxisSpec(
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
      },
    );
  }
}
