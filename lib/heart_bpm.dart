library heart_bpm;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'chart.dart';

/// Class to store one sample data point
class SensorValue {
  /// timestamp of datapoint
  final DateTime time;

  /// value of datapoint
  final double value;

  SensorValue({@required this.time, @required this.value});

  /// Returns JSON mapped data point
  Map<String, dynamic> toJSON() => {'time': time, 'value': value};

  /// Map a list of data samples to a JSON formatted array.
  ///
  /// Map a list of [data] samples to a JSON formatted array. This is
  /// particularly useful to store [data] to database.
  static List<Map<String, dynamic>> toJSONArray(List<SensorValue> data) =>
      List.generate(data.length, (index) => data[index].toJSON());
}

/// Obtains heart beats per minute using camera sensor
///
/// Using the smartphone camera, the widget estimates the skin tone variations
/// over time. These variations are due to the blood flow in the arteries
/// present below the skin of the fingertips.
class HeartBPMDialog extends StatefulWidget {
  /// Callback used to notify the caller of updated data sample
  ///
  /// Should be non-blocking as it can affect
  final void Function(SensorValue) onData;

  /// Camera sampling rate in milliseconds
  final int sampleDelay;

  /// Parent context
  final BuildContext context;

  /// Smoothing factor
  ///
  /// Factor used to compute exponential moving average of the realtime data
  /// using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```
  double alpha = 0.6;

  /// Additional child widget to display
  final Widget child;

  /// Obtains heart beats per minute using camera sensor
  ///
  /// Using the smartphone camera, the widget estimates the skin tone variations
  /// over time. These variations are due to the blood flow in the arteries
  /// present below the skin of the fingertips.
  ///
  /// This is a [Dialog] widget and hence needs to be displayer using [showDialog]
  /// function. For example:
  /// ```
  /// await showDialog(
  ///   context: context,
  ///   builder: (context) => HeartBPMDialog(
  ///     onData: (value) => print(value),
  ///   ),
  /// );
  /// ```
  HeartBPMDialog({
    Key key,
    @required this.context,
    this.sampleDelay = 1000 ~/ 30,
    @required this.onData,
    this.alpha = 0.6,
    this.child,
  });

  /// Set the smoothing factor for exponential averaging
  ///
  /// the scaling factor [alpha] is used to compute exponential moving average of the
  /// realtime data using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```
  void setAlpha(double a) {
    if (a <= 0)
      throw Exception(
          "$HeartBPMDialog: smoothing factor cannot be 0 or negative");
    if (a > 1)
      throw Exception(
          "$HeartBPMDialog: smoothing factor cannot be greater than 1");
    alpha = a;
  }

  @override
  _HeartBPPView createState() => _HeartBPPView();
}

class _HeartBPPView extends State<HeartBPMDialog> {
  /// Camera controller
  CameraController _controller;

  /// Used to set sampling rate
  bool _processing = false;

  /// Current value
  double currentValue = 0;

  /// to ensure camara was initialized
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void dispose() {
    _deinitController();
    super.dispose();
  }

  /// Deinitialize the camera controller
  void _deinitController() async {
    isCameraInitialized = false;
    if (_controller == null) return;
    // await _controller.stopImageStream();
    await _controller.dispose();
    // while (_processing) {}
    // _controller = null;
  }

  /// Initialize the camera controller
  ///
  /// Function to initialize the camera controller and start data collection.
  Future<void> _initController() async {
    if (_controller != null) return;
    try {
      // 1. get list of all available cameras
      List<CameraDescription> _cameras = await availableCameras();
      // 2. assign the preferred camera with low resolution and disable audio
      _controller = CameraController(_cameras.first, ResolutionPreset.low,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);

      // 3. initialize the camera
      await _controller.initialize();

      // 4. set torch to ON and start image stream
      Future.delayed(Duration(milliseconds: 500))
          .then((value) => _controller.setFlashMode(FlashMode.torch));

      // 5. register image streaming callback
      _controller.startImageStream((image) {
        if (!_processing && mounted) _scanImage(image);
      });

      setState(() {
        isCameraInitialized = true;
      });
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static const int windowLength = 150;
  static List<SensorValue> measureWindow = List<SensorValue>.filled(
      windowLength, SensorValue(time: DateTime.now(), value: 0),
      growable: true);
  List<SensorValue> differenceWindow = List<SensorValue>.filled(
      windowLength, SensorValue(time: DateTime.now(), value: 0),
      growable: true);

  void _scanImage(CameraImage image) async {
    // make system busy
    setState(() {
      _processing = true;
    });

    // get the average value of the image
    double _avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;

    setState(() {
      measureWindow.removeAt(0);
      measureWindow.add(SensorValue(time: DateTime.now(), value: _avg));
    });

    const List<int> walshKernel = [-1, 1, 1, -1];
    const int kernelLength = 4;
    const int kernelLength2 = kernelLength >> 1;

    for (int i = 0; i < windowLength; i++) {
      double convolutionValue = 0;
      for (int j = 0; j <= kernelLength2; j++) {
        if ((i - j) >= 0) {
          // print('i - j = $i - $j = ${i - j}');
          convolutionValue += measureWindow[i - j].value * walshKernel[j];
        }
        if ((j + i) < windowLength &&
            (i + j != i - j) &&
            (j + kernelLength2) < kernelLength) {
          // print('i + j = $i + $j = ${i + j}');
          convolutionValue +=
              measureWindow[i + j].value * walshKernel[j + kernelLength2];
        }
      }
      differenceWindow[i] =
          SensorValue(time: measureWindow[i].time, value: convolutionValue);
    }

    setState(() {
      currentValue = _smoothBPM(_avg);
    });

    // call the provided function with the new data sample
    widget.onData(SensorValue(
      time: DateTime.now(),
      value: currentValue,
    ));

    Future<void>.delayed(Duration(milliseconds: widget.sampleDelay))
        .then((onValue) {
      if (mounted)
        setState(() {
          _processing = false;
        });
    });
  }

  /// Smoothing factor for exponential averaging
  double _alpha = 0.8;

  /// variable to store previous sample value
  double _pastBPM = 0;

  /// Smooth the raw measurements using Exponential averaging
  /// the scaling factor [alpha] is used to compute exponential moving average of the
  /// realtime data using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```
  double _smoothBPM(double newValue) {
    double newOut = _alpha * newValue + (1 - _alpha) * _pastBPM;
    _pastBPM = newOut;
    return newOut;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        constraints: BoxConstraints.tightFor(height: 300),
        child: isCameraInitialized
            ? Column(
                children: [
                  Container(
                    constraints:
                        BoxConstraints.tightFor(width: 100, height: 150),
                    child: CameraPreview(_controller),
                  ),
                  Text(currentValue.toStringAsFixed(0)),
                  // widget.child == null ? SizedBox() : widget.child
                  Container(
                    constraints: BoxConstraints.tight(Size(250, 75)),
                    child: BPMChart(measureWindow),
                  ),
                ],
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}
