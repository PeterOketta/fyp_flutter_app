import 'dart:math';
import 'dart:io'; // Import for file I/O
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'; // Import for accessing directories
import 'package:onnxruntime/onnxruntime.dart';
import 'dart:typed_data';

class ECGVerification {
  OrtSession? _ortSession;
  List<List<double>>? iecgTemplate;

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

  Future<void> loadIECGTemplate() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/iecg_data.txt');
      String contents = await file.readAsString();

      // Split the loaded string by ';' to get segments
      List<String> segmentStrings = contents.split(';');

      // Parse each segment string into a list of doubles
      iecgTemplate = segmentStrings.map((segmentString) {
        List<String> values = segmentString.split(','); // Use ',' as the delimiter
        return values.map((value) => double.parse(value)).toList();
      }).toList();

      // Print the loaded template
      print('Loaded iECG template: $iecgTemplate');
    } catch (error) {
      print('Error loading iECG template: $error');
      // Handle the error (e.g., display feedback to the user)
    }
  }




  Future<bool> doesTemplateExist() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/iecg_data.txt');
      return await file.exists();
    } catch (error) {
      print('Error checking template existence: $error');
      return false;
    }
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
    final List<List<double>> result = [];
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

  Future<bool> verifyUser(List<int> ecgSegment, List<List<double>> iecgTemplate) async {
    const verificationThreshold = 0.15;

    List<List<double>> contextVectors = await runInference(ecgSegment);
    
    // Print the shapes of the vectors
    print('Shape of contextVectors: ${contextVectors.length} x ${contextVectors[0].length}');
    print('Shape of iecgTemplate: ${iecgTemplate.length} x ${iecgTemplate[0].length}');
    
    double similarityScore = _cosineSimilarity(contextVectors.expand((e) => e).toList(), iecgTemplate.expand((e) => e).toList());
    print(similarityScore);
    return similarityScore > verificationThreshold;
  }


  // Cosine Similarity Function
  // Cosine Similarity Function
  double _cosineSimilarity(List<double> vector1, List<double> vector2) {
    print('Length of vector1: ${vector1.length}');
    print('Length of vector2: ${vector2.length}');
    
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
