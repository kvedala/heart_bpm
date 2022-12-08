import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'sensor_value.dart';

/// Obtains heart beats per minute using camera sensor
///
/// Using the smartphone camera, the widget estimates the skin tone variations
/// over time. These variations are due to the blood flow in the arteries
/// present below the skin of the fingertips.
class BPMDialog extends StatefulWidget {
  /// Callback used to notify the caller of updated BPM measurement
  ///
  /// Should be non-blocking as it can affect
  final void Function(int) onBPM;

  /// Callback used to notify the caller of updated raw data sample
  ///
  /// Should be non-blocking as it can affect
  final void Function(BPMSensorValue)? onRawData;

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
  final _alpha = StreamController<double>();

  /// Additional child widget to display
  final Widget? child;

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
  BPMDialog({
    Key? key,
    required this.context,
    required this.onBPM,
    this.sampleDelay = 2000 ~/ 30,
    this.onRawData,

    /// Smoothing factor
    ///
    /// Factor used to compute exponential moving average of the realtime data
    /// using the formula:
    /// ```
    /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
    /// ```
    double alpha = 0.8,
    this.child,
  }) : super(key: key) {
    _alpha.add(alpha);
  }

  /// Set the smoothing factor for exponential averaging
  ///
  /// the scaling factor [alpha] is used to compute exponential moving average of the
  /// realtime data using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```
  void updateAlpha(double a) {
    if (a <= 0) {
      throw Exception("$BPMDialog: smoothing factor cannot be 0 or negative");
    }
    if (a > 1) {
      throw Exception("$BPMDialog: smoothing factor cannot be greater than 1");
    }
    _alpha.add(a);
  }

  @override
  State<BPMDialog> createState() => _HeartBPPView();
}

class _HeartBPPView extends State<BPMDialog> {
  /// Camera controller
  CameraController? _controller;

  /// Used to set sampling rate
  bool _processing = false;

  /// Current value
  int currentValue = 0;

  /// to ensure camara was initialized
  bool isCameraInitialized = false;

  /// the exponential smoothing factor whose value is updated from the widget
  double alpha = 0;

  @override
  void initState() {
    super.initState();
    widget._alpha.stream.listen((event) {
      alpha = event;
    });
    _initController().onError((error, stackTrace) => null);
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
    await _controller!.dispose();
    // while (_processing) {}
    // _controller = null;
  }

  /// Initialize the camera controller
  ///
  /// Function to initialize the camera controller and start data collection.
  Future<void> _initController() async {
    if (_controller != null) return;

    // 1. get list of all available cameras
    List<CameraDescription> cameras = await availableCameras();
    // 2. assign the preferred camera with low resolution and disable audio
    _controller = CameraController(cameras.first, ResolutionPreset.low,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.yuv420);

    // 3. initialize the camera
    await _controller!.initialize();

    // 4. set torch to ON and start image stream
    Future.delayed(const Duration(milliseconds: 500))
        .then((value) => _controller!.setFlashMode(FlashMode.torch));

    // 5. register image streaming callback
    _controller!.startImageStream((image) {
      if (!_processing && mounted) {
        _processing = true;
        _scanImage(image);
      }
    });

    setState(() {
      isCameraInitialized = true;
    });
  }

  static const int windowLength = 50;
  final List<BPMSensorValue> measureWindow = List<BPMSensorValue>.filled(
      windowLength, BPMSensorValue(time: DateTime.now(), value: 0),
      growable: true);

  void _scanImage(CameraImage image) async {
    // make system busy
    // setState(() {
    //   _processing = true;
    // });

    // get the average value of the image
    double avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;

    measureWindow.removeAt(0);
    measureWindow.add(BPMSensorValue(time: DateTime.now(), value: avg));

    _smoothBPM(avg).then((value) {
      widget.onRawData!(
        // call the provided function with the new data sample
        BPMSensorValue(
          time: DateTime.now(),
          value: avg,
        ),
      );

      Future<void>.delayed(Duration(milliseconds: widget.sampleDelay))
          .then((onValue) {
        if (mounted) {
          setState(() {
            _processing = false;
          });
        }
      });
    });
  }

  /// Smooth the raw measurements using Exponential averaging
  /// the scaling factor [alpha] is used to compute exponential moving average of the
  /// realtime data using the formula:
  /// ```
  /// $y_n = alpha * x_n + (1 - alpha) * y_{n-1}$
  /// ```
  Future<int> _smoothBPM(double newValue) async {
    double maxVal = 0, avg = 0;

    for (var element in measureWindow) {
      avg += element.value / measureWindow.length;
      if (element.value > maxVal) maxVal = element.value as double;
    }

    double threshold = (maxVal + avg) / 2;
    int counter = 0, previousTimestamp = 0;
    double tempBPM = 0;
    for (int i = 1; i < measureWindow.length; i++) {
      // find rising edge
      if (measureWindow[i - 1].value < threshold &&
          measureWindow[i].value > threshold) {
        if (previousTimestamp != 0) {
          counter++;
          tempBPM += 60000 /
              (measureWindow[i].time.millisecondsSinceEpoch -
                  previousTimestamp); // convert to per minute
        }
        previousTimestamp = measureWindow[i].time.millisecondsSinceEpoch;
      }
    }

    if (counter > 0) {
      tempBPM /= counter;
      tempBPM = (1 - alpha) * currentValue + alpha * tempBPM;
      setState(() {
        currentValue = tempBPM.toInt();
        // _bpm = _tempBPM;
      });
      widget.onBPM(currentValue);
    }

    // double newOut = widget.alpha * newValue + (1 - widget.alpha) * _pastBPM;
    // _pastBPM = newOut;
    return currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isCameraInitialized
          ? Column(
              children: [
                Container(
                  constraints:
                      const BoxConstraints.tightFor(width: 100, height: 130),
                  child: _controller!.buildPreview(),
                ),
                Text(currentValue.toStringAsFixed(0)),
                widget.child == null ? const SizedBox() : widget.child!,
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
