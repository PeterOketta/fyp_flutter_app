import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../utils/BluetoothUtils.dart';
import '../utils/BluetoothManager.dart';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';

class EnrollmentFunctions {
  Interpreter? _interpreter;
  BluetoothUtils _bluetoothUtils = BluetoothUtils();

  Future<void> loadModel() async {
    try {
      final modelData = await rootBundle.load('assets/output_attention_model.tflite');
      _interpreter = await Interpreter.fromBuffer(modelData.buffer.asUint8List());
      print('Model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<List<List<int>>> segmentECGData(List<int> ecgData, int windowSize, int maxSegments) async {
    List<List<int>> segments = [];
    for (int i = 0; i < ecgData.length && segments.length < maxSegments; i += windowSize) {
      int endIndex = i + windowSize;
      if (endIndex > ecgData.length) endIndex = ecgData.length;
      segments.add(ecgData.sublist(i, endIndex));
    }
    print('Segments: $segments');
    return segments;
  }

  Future<List> runInference(List<int> ecgSegment) async {
    print('Running inference...');
    if (_interpreter == null) {
      await loadModel();
    }

    if (_interpreter == null) {
      print('Failed to load the model');
      throw Exception('Failed to load the model.');
    }

    List<double> inputData = ecgSegment.map((value) => value.toDouble()).toList();
    print('Input to model: $inputData');
    List<int> inputShape = _interpreter!.getInputTensor(0).shape;
    inputData = inputData.reshape(inputShape) as List<double>;
    var output = List.filled(150 * 128, 0).reshape([150, 128]);
    _interpreter!.run([inputData], output);
    print('Inference completed');
    return output;
  }

  Future<void> enrollUser(int duration, Function setStateCallback) async {
    setStateCallback(true, 'Enrolling...');
    try {
      print('Starting enrollment process...');
      BluetoothCharacteristic? characteristic = BluetoothManager.getCharacteristic();

      if (characteristic == null) {
        throw Exception('Bluetooth characteristic not found.');
      }

      List<int> longECGSegment = await _bluetoothUtils.collectDataFromCharacteristic(Duration(seconds: duration), characteristic);
      print('Collected Data: $longECGSegment');

      List<List<int>> segments = await segmentECGData(longECGSegment, 200, 40);

      List<double> accumulatedContextVectors = [];
      int enrollmentSegmentsCount = 0;
      const enrollmentThreshold = 40;

      while (enrollmentSegmentsCount < enrollmentThreshold && segments.isNotEmpty) {
        List<int> segment = segments.removeAt(0);

        List<double> contextVector = await runInference(segment) as List<double>;

        accumulatedContextVectors.addAll(contextVector);

        enrollmentSegmentsCount += 1;

        setStateCallback(true, 'Enrolling (${enrollmentSegmentsCount * 100 ~/ enrollmentThreshold}%');
      }

      if (enrollmentSegmentsCount == enrollmentThreshold) {
        print('Calculating iECG...');
        List<double> iecg = calculateIECG(accumulatedContextVectors.cast<List<double>>());
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/iecg_data.txt');
          String iecgString = iecg.join(',');
          await file.writeAsString(iecgString);
          print('iECG data stored successfully');
        } catch (error) {
          print('Error storing iECG: $error');
        }
      } else {
        print('Enrollment failed: Not enough segments collected');
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

    List<List<double>> transposed = transpose(contextVectors);

    List<double> iecg = transposed.map((vector) => vector.reduce((a, b) => a + b) / vector.length).toList();

    double mean = iecg.reduce((a, b) => a + b) / iecg.length;
    double stdDev = calculateStandardDeviation(iecg);

    if (stdDev != 0.0) {
      iecg = iecg.map((value) => (value - mean) / stdDev).toList();
    }

    return iecg;
  }

  double calculateStandardDeviation(List<double> data) {
    double mean = data.reduce((a, b) => a + b) / data.length;
    num sumOfSquares = data.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumOfSquares / data.length);
  }

  List<List<double>> transpose(List<List<double>> matrix) {
    List<List<double>> transposed = [];
    for (int i = 0; i < matrix[0].length; i++) {
      transposed.add(matrix.map((row) => row[i]).toList());
    }
    return transposed;
  }
}