import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/BluetoothUtils.dart';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
class EnrollmentFunctions {
  Interpreter? _interpreter;
  BluetoothUtils _bluetoothUtils = BluetoothUtils();
  Future<void> loadModel(String modelPath) async {
    _interpreter = await Interpreter.fromAsset(modelPath);
  }
  Future<List<List<int>>> segmentECGData(List<int> ecgData, int windowSize, int maxSegments) async {
  List<List<int>> segments = [];
  for (int i = 0; i < ecgData.length && segments.length < maxSegments; i += windowSize) {
  int endIndex = i + windowSize;
  if (endIndex > ecgData.length) endIndex = ecgData.length;
  segments.add(ecgData.sublist(i, endIndex));
  }
  return segments;
  }

  Future<List> runInference(List<int> ecgSegment) async {
    // 1. Prepare Input (assuming Float32List for input)
    List<double> inputData = ecgSegment.map((value) => value.toDouble()).toList();
    List<int> inputShape = _interpreter!.getInputTensor(0).shape;
    inputData = inputData.reshape(inputShape) as List<double>;
    var output = List.filled(150 * 128, 0).reshape([150, 128]);
    _interpreter!.run([inputData], output);
    return output;
  }


  Future<void> enrollUser(int duration, Function setStateCallback, BluetoothCharacteristic characteristic) async{
    setStateCallback(true, 'Enrolling...');
    try {
      // 2. Collect ECG Data
      List<int> longECGSegment = await _bluetoothUtils.collectDataFromCharacteristic(Duration(seconds: duration), characteristic);

      // 3. Segmentation
      List<List<int>> segments = segmentECGData(
          longECGSegment, 200, 40) as List<List<int>>;

      // 4. Model Inference (Repeated for each segment)
      List<double> accumulatedContextVectors = [];
      int enrollmentSegmentsCount = 0;
      const enrollmentThreshold = 40;

      while (enrollmentSegmentsCount < enrollmentThreshold &&
          segments.isNotEmpty) {
        List<int> segment = segments.removeAt(0);

        List<double> contextVector = await runInference(segment) as List<
            double>;

        accumulatedContextVectors.addAll(contextVector);

        enrollmentSegmentsCount += 1;

        // Progress Update
        setStateCallback(true, 'Enrolling (${enrollmentSegmentsCount * 100 ~/
            enrollmentThreshold}%');
      }

      // 5. iECG Calculation
      if (enrollmentSegmentsCount == enrollmentThreshold) {
        List<double> iecg = calculateIECG(
            accumulatedContextVectors.cast<List<double>>());
        // File Storage
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/iecg_data.txt');
          String iecgString = iecg.join(',');
          await file.writeAsString(iecgString);

        } catch (error) {
          print('Error storing iECG: $error');
        }
      } else {
        throw Exception('Enrollment failed: Not enough segments collected');
      }
    } catch (error) {
      print('Enrollment error: $error');
      setStateCallback(false, 'Enrollment failed. Please retry');
      rethrow;
    }
  }
  List<double> calculateIECG(List<List<double>> contextVectors) {
    if (contextVectors.isEmpty) {
      throw Exception('Cannot calculate iECG with no context vectors');
    }

    // 1. Transpose for Easier Averaging (optional)
    List<List<double>> transposed = transpose(contextVectors);

    // 2. Average across segments
    List<double> iecg = transposed.map((vector) => vector.reduce((a, b) => a + b) / vector.length).toList();

    // 3. Normalization (Example: Z-score normalization)
    double mean = iecg.reduce((a, b) => a + b) / iecg.length;
    double stdDev = calculateStandardDeviation(iecg);

    if (stdDev != 0.0) { // Avoid division by zero if all values are the same
      iecg = iecg.map((value) => (value - mean) / stdDev).toList();
    }

    return iecg;
  }
  // Simple standard deviation calculation (you may find a more optimized version)
  double calculateStandardDeviation(List<double> data) {
    double mean = data.reduce((a, b) => a + b) / data.length;
    num sumOfSquares = data.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumOfSquares / data.length);
  }

// Helper for transposing lists
  List<List<double>> transpose(List<List<double>> matrix) {
    List<List<double>> transposed = [];
    for (int i = 0; i < matrix[0].length; i++) {
      transposed.add(matrix.map((row) => row[i]).toList());
    }
    return transposed;
  }

}
