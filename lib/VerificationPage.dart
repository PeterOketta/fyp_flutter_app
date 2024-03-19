import 'package:flutter/material.dart';
import 'verification_functions.dart'; // Import your verification functions
import '../utils/BluetoothUtils.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/BluetoothManager.dart';

class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  bool _isLoading = false;
  bool _verified = false;
  double _confidence = 0.0;
  final _verifier = ECGVerification();
  BluetoothUtils _bluetoothUtils = BluetoothUtils();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _verifier.loadModel();
      bool templateExists = await _verifier.doesTemplateExist();
      if (templateExists) {
        await _verifier.loadIECGTemplate();
      } else {
        print('Template does not exist');
      }
    } catch (e) {
      print('Error during initialization: $e');
      // Handle initialization errors
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processECGData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      BluetoothCharacteristic? _characteristic = BluetoothManager.getCharacteristic();
      if (_characteristic == null) {
        throw Exception('Bluetooth characteristic is null.');
      }

      if (_verifier.iecgTemplate == null) {
        throw Exception('iecgTemplate is not initialized.');
      }

      List<int> longECGSegment = await _bluetoothUtils.collectDataFromCharacteristic(Duration(seconds: 90), _characteristic);
      List<List<int>> segments = await _verifier.segmentECGData(longECGSegment, 200, 40);

      _confidence = 0.0; // Reset confidence

      for (List<int> segment in segments) {
        bool isVerified = await _verifier.verifyUser(segment, _verifier.iecgTemplate!);
        if (isVerified) {
          _confidence += 1.0 / segments.length; // Adjust based on your segment count
        }
      }

      if (_confidence >= 0.5) {
        print(_confidence);
        _verified = true;
        _navigateToProfile();
      }
    } catch (error) {
      print('Error during verification: $error');
      _handleVerificationFailure();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToProfile() {
    // Wait for 3 seconds before navigating to the next screen
    Future.delayed(const Duration(seconds: 10), () {
      Navigator.pushNamed(context, '/profile', arguments: {'profileName': 'Mike', 'confidence': _confidence});
    });
  }


  void _handleVerificationSuccess() {
    setState(() {
      _verified = true;
      _navigateToProfile();
    });
  }

  void _handleVerificationFailure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification failed. Please try again.')),
    );
  }

  void _retryVerification() {
    setState(() {
      _verified = false;
      _confidence = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const Text('Verifying ECG data...', style: TextStyle(color: Colors.white)),
            if (_verified)
              Text(
                'Verification Successful! (Confidence: ${(_confidence * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(color: Colors.green),
              ),
            ElevatedButton(
              onPressed: _isLoading || _verified ? null : () {
                _processECGData().then((_) {
                  if (_verified) {
                    _handleVerificationSuccess();
                  } else {
                    _handleVerificationFailure();
                  }
                });
              },
              child: Text(_verified ? 'Verified' : 'Authenticate'),
            ),
            ElevatedButton(
              onPressed: _verified ? null : _retryVerification,
              child: const Text('Retry'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/re-enroll'),
              child: const Text('Re-enroll'),
            ),
          ],
        ),
      ),
    );
  }
}
