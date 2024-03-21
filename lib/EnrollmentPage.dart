import 'package:flutter/material.dart';
import 'Enrollment_functions.dart';
class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  _EnrollmentScreenState createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  bool _isEnrolling = false;
  bool _enrollmentDone = false;
  String _enrollmentStatus = 'Ready to Start';
  final _enrollmentFunctions = EnrollmentFunctions();

  @override
  void initState() {
    super.initState();
    _enrollmentFunctions.loadModel();
  }

  void _startEnrollment() async {
    await _enrollmentFunctions.enrollUser(65, _updateEnrollmentStatus);
    setState(() {
        _enrollmentDone = true;
      });
  }

  void _updateEnrollmentStatus(bool isEnrolling, String status) {
    setState(() {
      _isEnrolling = isEnrolling;
      _enrollmentStatus = status;
    });
  }

  void _navigateToProfile() {
    Navigator.pushReplacementNamed(context, '/profile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Create Your ECG Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Place on your garment as shown.',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 20.0),
            Image.asset(
              'assets/sensor_placement.png', 
              width: 250, 
              height: 250, 
            ), 
            const SizedBox(height: 20.0),
            const Text(
              'Bluetooth: Connected',
              style: TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _isEnrolling ? null : _startEnrollment,
              child: Text(_isEnrolling ? 'Enrolling...' : 'Start Enrollment'),
            ),
            const SizedBox(height: 20.0),
            Text(_enrollmentStatus),
            Visibility(
              visible: _enrollmentDone,
              child: ElevatedButton(
                onPressed: _navigateToProfile,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
