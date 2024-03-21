import 'package:flutter/material.dart';

class ECGDataScreen extends StatefulWidget {
  final List<int> parsedECGSamples;

  const ECGDataScreen({super.key, required this.parsedECGSamples});

  @override
  _ECGDataScreenState createState() => _ECGDataScreenState();
}

class _ECGDataScreenState extends State<ECGDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ECG Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Parsed ECG Samples:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.parsedECGSamples.length,
                itemBuilder: (context, index) {
                  return Text(
                    'Sample ${index + 1}: ${widget.parsedECGSamples[index]}',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
