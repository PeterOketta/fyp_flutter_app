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
  }
  void _retrieveCharacteristic() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _characteristic = args['characteristic'];
  }


  void _startEnrollment() async {
    _enrollmentFunctions.enrollUser(80,_updateEnrollmentStatus,_characteristic!);
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
            // Instructions
            Text(
              'Place the sensor on your garment as shown.',
              style: TextStyle(fontSize: 16.0),
            ),

            SizedBox(height: 20.0),

            // Bluetooth Status (Update based on real status)
            Text(
              'Bluetooth: Connected',
              style: TextStyle(fontSize: 16.0),
            ),

            SizedBox(height: 20.0),

            // Enrollment Button
            ElevatedButton(
              onPressed: _isEnrolling ? null : () {
                if (_characteristic == null) {
                  _retrieveCharacteristic();
                } else { // Change here
                  _startEnrollment();
                }
              },
              child: Text(_isEnrolling ? 'Enrolling...' : 'Start Enrollment'),
            ),

            SizedBox(height: 20.0),

            // Enrollment Status
            Text(_enrollmentStatus),
          ],
        ),
      ),
    );
  }
}
