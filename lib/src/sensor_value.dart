/// Class to store one sample data point
class BPMSensorValue {
  /// timestamp of datapoint
  final DateTime time;

  /// value of datapoint
  final num value;

  const BPMSensorValue({required this.time, required this.value});

  /// Returns JSON mapped data point
  Map<String, dynamic> toJSON() => {'time': time, 'value': value};

  /// Map a list of data samples to a JSON formatted array.
  ///
  /// Map a list of [data] samples to a JSON formatted array. This is
  /// particularly useful to store [data] to database.
  static List<Map<String, dynamic>> toJSONArray(List<BPMSensorValue> data) =>
      List.generate(data.length, (index) => data[index].toJSON());
}
