import 'package:flutter/material.dart';

class ECGDataScreen extends StatefulWidget {
  final List<int> parsedECGSamples;

  const ECGDataScreen({Key? key, required this.parsedECGSamples})
      : super(key: key);

  @override
  _ECGDataScreenState createState() => _ECGDataScreenState();
}

class _ECGDataScreenState extends State<ECGDataScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ECG Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Parsed ECG Samples:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.parsedECGSamples.length,
                itemBuilder: (context, index) {
                  return Text(
                    'Sample ${index + 1}: ${widget.parsedECGSamples[index]}',
                    style: TextStyle(fontSize: 16),
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
