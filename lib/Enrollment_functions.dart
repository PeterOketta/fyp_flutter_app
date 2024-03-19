import 'dart:math';
import 'package:flutter/services.dart';
import '../utils/BluetoothUtils.dart';
import '../utils/BluetoothManager.dart';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:onnxruntime/onnxruntime.dart';

class EnrollmentFunctions {
  OrtSession? _ortSession;
  BluetoothUtils _bluetoothUtils = BluetoothUtils();

  Future<void> loadModel() async {
    try {
      await OrtEnv.instance.init();
      const assetFileName = 'assets/HLSTM_converted_model.onnx';
      final rawAssetFile = await rootBundle.load(assetFileName);
      final bytes = rawAssetFile.buffer.asUint8List();

      final sessionOptions = OrtSessionOptions(); // If needed, customize options here

      _ortSession = OrtSession.fromBuffer(bytes, sessionOptions);
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

  Future<List<List<double>>> runInference(List<int> ecgSegment) async {
    print('Running inference...');
    if (_ortSession == null) {
      await loadModel();
    }

    if (_ortSession == null) {
      print('Failed to load the model');
      throw Exception('Failed to load the model.');
    }

    // Reshape input data (assuming ecgSegment has a length of 200)
    final List<List<int>> ecgSegment2D = [ecgSegment]; // Create a 2D list

    // Convert to Float32List
    final Float32List ecgSegmentFloat32 = Float32List.fromList(
      ecgSegment2D.expand((row) => row).map((value) => value.toDouble()).toList(),
    );

    // Adjust your batch size if needed
    final shape = [1, 200, 1];
    final inputOrt = OrtValueTensor.createTensorWithDataList(ecgSegmentFloat32, shape);
    final inputs = {'input_1': inputOrt};
    final runOptions = OrtRunOptions(); // Create run options if needed
    final outputs = await _ortSession!.runAsync(runOptions, inputs);
    inputOrt.release();
    runOptions.release();

    // Process the outputs and convert them to the desired format
    final result = <List<double>>[];
    for (final outputData in outputs![0]?.value as List<List<List<double>>>) {
      for (final row in outputData) {
        result.add(row);
      }
    }

    // Release the OrtValue objects
    outputs.forEach((element) {
      element?.release();
    });

    return result;
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

      List<List<List<double>>> accumulatedContextVectors = [];
      int enrollmentSegmentsCount = 0;
      const enrollmentThreshold = 40;

      while (enrollmentSegmentsCount < enrollmentThreshold && segments.isNotEmpty) {
        List<int> segment = segments.removeAt(0);
        print('Segment before inference: $segment');
        List<List<double>> contextVector = await runInference(segment);
        print('Context vector: $contextVector');
        accumulatedContextVectors.add(contextVector);

        enrollmentSegmentsCount += 1;

        setStateCallback(true, 'Enrolling (${enrollmentSegmentsCount * 100 ~/ enrollmentThreshold}%');
      }

      if (enrollmentSegmentsCount == enrollmentThreshold) {
        print('Calculating iECG...');
        List<List<double>> iecg = calculateIECG(accumulatedContextVectors);

        // Save iECG template to file
        await saveIECGTemplate(iecg);

        print('iECG data stored successfully');
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

  Future<void> saveIECGTemplate(List<List<double>> iecg) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/iecg_data.txt');
      String iecgString = iecg.map((vector) => vector.join(',')).join(';'); // Separate vectors with ';' and values with ','
      await file.writeAsString(iecgString);
    } catch (error) {
      print('Error storing iECG: $error');
      throw Exception('Error storing iECG: $error');
    }
  }
List<List<double>> calculateIECG(List<List<List<double>>> contextVectors) {
  if (contextVectors.isEmpty) {
    throw Exception('Cannot calculate iECG with no context vectors');
  }

  int vectorLength = contextVectors[0][0].length; // Length of individual vectors (128)
  int numSegments = contextVectors.length; // Number of segments

  // Initialize iECG with the correct shape
  List<List<double>> iecg = List.generate(
    200, 
    (_) => List.filled(vectorLength, 0.0), // Initialize with size vectorLength (128)
  ); 

  for (int i = 0; i < 200; i++) { // Loop through feature indices
    for (int j = 0; j < vectorLength; j++) { // Loop through vector indices
      // Extract all values at feature index 'i' and vector index 'j'
      List<double> valuesAtIndex = contextVectors.map((segment) => segment[i][j]).toList(); 

      // Calculate mean for valuesAtIndex
      double mean = valuesAtIndex.reduce((a, b) => a + b) / valuesAtIndex.length; 

      // Store mean at the corresponding position in iecg
      iecg[i][j] = mean; 
    }
  }

  // Print the shape of the calculated iECG template
  print('Shape of iECG template: ${iecg.length} x ${iecg[0].length}');

  return iecg;
}







  double calculateStandardDeviation(List<double> data) {
    double mean = data.reduce((a, b) => a + b) / data.length;
    num sumOfSquares = data.map((value) => pow(value - mean, 2)).reduce((a, b) => a + b);
    return sqrt(sumOfSquares / data.length);
  }
}
