import 'package:flutter/material.dart';

import 'package:heart_bpm/heart_bpm.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heart BPM Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Heart BPM Demo'),
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.favorite_rounded),
          label: Text("Measure BPM"),
          onPressed: () async => await showDialog(
            context: context,
            builder: (context) => HeartBPMDialog(
              context: context,
              onData: (value) => print(value),
            ),
          ),
        ),
      ),
    );
  }
}
