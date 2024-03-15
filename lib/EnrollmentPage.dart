import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'Enrollment_functions.dart';

class EnrollmentScreen extends StatefulWidget {
  @override
  _EnrollmentScreenState createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  bool _isEnrolling = false;
  String _enrollmentStatus = 'Ready to Start';
  BluetoothCharacteristic? _characteristic;
  final _enrollmentFunctions = EnrollmentFunctions();

  @override
  void initState() {
    super.initState();
    _enrollmentFunctions.loadModel();
  }

  void _startEnrollment() async {
    await _enrollmentFunctions.enrollUser(80, _updateEnrollmentStatus);
    if (_isEnrolling == false) {
      Navigator.pushReplacementNamed(context, '/profile');
    }
  }

  void _updateEnrollmentStatus(bool isEnrolling, String status) {
    setState(() {
      _isEnrolling = isEnrolling;
      _enrollmentStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Your ECG Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Place the sensor on your garment as shown.',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            Text(
              'Bluetooth: Connected',
              style: TextStyle(fontSize: 16.0),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isEnrolling ? null : _startEnrollment,
              child: Text(_isEnrolling ? 'Enrolling...' : 'Start Enrollment'),
            ),
            SizedBox(height: 20.0),
            Text(_enrollmentStatus),
          ],
        ),
      ),
    );
  }
}