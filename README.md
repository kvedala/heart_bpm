# heart_bpm

Widget to measure heart rate in beats per minute using the camera of smartphone.

## Working principle

Covering the camera lens with the fingertip enables the camera to
measure the subtle changes in skin tone. These are proportional to
the changes in the blood flow through the arteries just below the
skin of the fingertip. This is in-turn correlated to the heart beats.
Hence, the variations in the skin tone can be approximated to the
instances of heart beats. Measuring the time differences between
the peaks provides `Beats per Minute`.

These values are not stable and hence, an [exponential moving average
filter](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average)
is implemented. The smoothing factor &alpha;, can be controlled by the
user from the calling widget.

## Implementation

To access the camera, the module utilizes the
[`camera`](https://pub.dev/packages/camera) package. Hence, the
requirements to use this package have the same requirements.

### Android

Minimum android SDK version: 21

Change the minimum Android sdk version to 21 (or higher) in your
`android/app/build.gradle` file.

```gradle
minSdkVersion 21
```

### iOS

iOS 10.0 of higher is needed to use the camera plugin. If compiling
for any version lower than 10.0 make sure to check the iOS version
before using the camera plugin. For example, using the
[`device_info`](https://pub.dev/packages/device_info) plugin.

Add two rows to the file `ios/Runner/Info.plist`:

- one with the key Privacy - Camera Usage Description and a usage
  description.
- and one with the key Privacy - Microphone Usage Description and a
  usage description.

Or in text format add the key:

```xml
<key>NSCameraUsageDescription</key>
<string>Heart BPM plugin would like to use camera to measure your heart rate.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Can I use the mic please?</string>
```

The microphone key is required though the feature is not being used
and no audio is enabled in the implementation.

## Getting Started

The module can be used simply by accessing it as a widget.

1. Import the module:

   ```dart
   import 'package:heart_bpm/heart_bpm.dart';
   ```

2. Access the widget as simply as:

    ```dart
    /// list to store raw values in
    List<SensorValue> data = [];

    /// variable to store measured BPM value
    int bpmValue;

    @override
    Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text('Heart BPM Demo'),
        ),
        body: Column(
        children: [
            isBPMEnabled ? HeartBPMDialog(
                    context: context,
                    onRawData: (value) {
                        setState(() {
                            // add raw data points to the list
                            // with a maximum length of 100
                            if (data.length == 100)
                                data.removeAt(0);
                            data.add(value);
                        });
                    },
                    onBPM: (value) => setState(() {
                        bpmValue = value;
                    }),
                )
              : SizedBox(),
          Center(
            child: ElevatedButton.icon(
                icon: Icon(Icons.favorite_rounded),
                label: Text(isBPMEnabled
                    ? "Stop measurement" : "Measure BPM"),
                onPressed: () => setState(() =>
                    isBPMEnabled = !isBPMEnabled
                ),
            ),
          ),
        ],
      ),
    );
    ```

## Contributors

| Contributor       | Profile Picture                                                                                              |
|-------------------|--------------------------------------------------------------------------------------------------------------|
| Karl Mathuthu     | [![Karl Mathuthu](https://avatars.githubusercontent.com/Karlmathuthu?s=100)](https://github.com/Karlmathuthu) |
| Krishna Vedala    | [![Krishna Vedala](https://avatars.githubusercontent.com/kvedala?s=100)](https://github.com/kvedala)      |
