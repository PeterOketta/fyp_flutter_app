import 'dart:math';
import 'dart:io'; // Import for file I/O
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart'; // Import for accessing directories

class ECGVerification {
  Interpreter? _interpreter;
  List<double>? iecgTemplate;

  Future<void> loadModel(String modelPath) async {
    // Load TFLite Model
    _interpreter = await Interpreter.fromAsset(modelPath);
  }

  Future<void> loadIECGTemplate() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/iecg_data.txt');
      String contents = await file.readAsString();
      iecgTemplate = contents.split(',').map((val) => double.parse(val)).toList();
    } catch (error) {
      print('Error loading iECG template: $error');
      // Handle the error (e.g., display feedback to the user)
    }
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

  Future<bool> verifyUser(List<int> ecgSegment, List<double> iecgTemplate) async {
    const verificationThreshold = 0.4;

    List<double> contextVector = await runInference(ecgSegment) as List<
        double>;// Interpreter used within runInference
    double similarityScore = _cosineSimilarity(contextVector, iecgTemplate);
    return similarityScore > verificationThreshold;
  }

  // Cosine Similarity Function
  double _cosineSimilarity(List<double> vector1, List<double> vector2) {
  assert(vector1.length == vector2.length, "Vectors must have the same length");

  double dotProduct = 0.0;
  double normA = 0.0;
  double normB = 0.0;

  for (int i = 0; i < vector1.length; i++) {
  dotProduct += vector1[i] * vector2[i];
  normA += vector1[i] * vector1[i];
  normB += vector2[i] * vector2[i];
  }

  return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  }

