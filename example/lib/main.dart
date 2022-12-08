import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heart_bpm/heart_bpm.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart BPM Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isBPMEnabled = StreamController<bool>();
    isBPMEnabled.add(false);
    final List<BPMSensorValue> data = [];
    final List<BPMSensorValue> bpmValues = [];
    final chart1 = BPMChart();
    final chart2 = BPMChart();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart BPM Demo'),
      ),
      body: StreamBuilder<bool>(
        stream: isBPMEnabled.stream,
        builder: (context, snapshot) => Column(
          children: [
            snapshot.data ?? false
                ? BPMDialog(
                    context: context,
                    onRawData: (value) {
                      if (data.length >= 100) data.removeAt(0);
                      data.add(value);
                      // chart = BPMChart(data);
                      chart1.updateChartData(value);
                    },
                    onBPM: (value) {
                      if (bpmValues.length >= 100) bpmValues.removeAt(0);
                      final val = BPMSensorValue(
                          value: value.toDouble(), time: DateTime.now());
                      bpmValues.add(val);
                      chart2.updateChartData(val);
                    },
                    sampleDelay: 1000 ~/ 20,
                    // child: Container(
                    //   height: 50,
                    //   width: 100,
                    //   child: chart1,
                    // ),
                  )
                : const SizedBox(),
            snapshot.data ?? false
                ? Container(
                    decoration: BoxDecoration(border: Border.all()),
                    height: 180,
                    child: chart1,
                  )
                : const SizedBox(),
            snapshot.data ?? false
                ? Container(
                    decoration: BoxDecoration(border: Border.all()),
                    constraints: const BoxConstraints.expand(height: 180),
                    child: chart2,
                  )
                : const SizedBox(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.favorite_rounded),
                label: Text((snapshot.data ?? false)
                    ? "Stop measurement"
                    : "Measure BPM"),
                onPressed: () =>
                    isBPMEnabled.add(snapshot.data! ? false : true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
