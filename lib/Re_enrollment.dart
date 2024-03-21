import 'package:flutter/material.dart';

class ReEnrollmentPage extends StatefulWidget {
  const ReEnrollmentPage({super.key});

  @override
  _ReEnrollmentPageState createState() => _ReEnrollmentPageState();
}

class _ReEnrollmentPageState extends State<ReEnrollmentPage> {
  final _verificationNumberController = TextEditingController();

  // ... state variables for loading, error, etc.

  Future<void> _verifyNumber() async {
    // TODO: Implement logic to fetch the correct number from storage or backend
    // TODO: Compare with _verificationNumberController.text.
    // TODO: If they match, navigate to EnrollmentPage
    // TODO: Handle errors and loading states
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Re-enrollment Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _verificationNumberController,
              decoration: const InputDecoration(labelText: 'Verification Number'),
            ),
            ElevatedButton(
              onPressed: _verifyNumber,
              child: const Text('Verify and Re-enroll'),
            ),
            ElevatedButton(
              onPressed: () {
                // Execute authentication model logic (to be implemented)
                Navigator.pushNamed(context, '/enroll');
              },
              child: const Text('For now'),
            ),
            // ... Display loading or error messages if needed
          ],
        ),
      ),
    );
  }
}
