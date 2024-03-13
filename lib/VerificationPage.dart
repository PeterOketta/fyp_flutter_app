import 'package:flutter/material.dart';
import 'verification_functions.dart'; // Import your verification functions
import '../utils/BluetoothUtils.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
class AuthenticationPage extends StatefulWidget {
  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  bool _isLoading = false;
  bool _verified = false;
  double _confidence = 0.0;
  final _verifier = ECGVerification();
  BluetoothCharacteristic? _characteristic;
  BluetoothUtils _bluetoothUtils = BluetoothUtils();

  @override
  void initState() {
    super.initState();
    _loadModel();
    _retrieveCharacteristic();
  }
  void _retrieveCharacteristic() {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _characteristic = args['characteristic'];
  }
  Future<void> _loadModel() async {
    setState(() { _isLoading = true; });
    try {
      await _verifier.loadModel('assets/attention_model.tflite');
      await _verifier.loadIECGTemplate();
    } catch (e) {
      // Handle errors appropriately
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _processECGData() async {
    setState(() { _isLoading = true; });
    try {
      List<int> longECGSegment = await _bluetoothUtils.collectDataFromCharacteristic(Duration(seconds: 80), _characteristic!);
      List<List<int>> segments = _verifier.segmentECGData(longECGSegment, 200, 40) as List<List<int>>;

      _confidence = 0.0; // Reset confidence

      for (List<int> segment in segments) {
        bool isVerified = await _verifier.verifyUser(segment.cast<int>(), _verifier.iecgTemplate!);
        if (isVerified) {
          _confidence += 1.0 / segments.length; // Adjust based on your segment count
        }
      }

      if (_confidence >= 0.6) {
        _verified = true;
        _navigateToProfile();
      }
    } catch (e) {
      // ... Handle errors ...
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile', arguments: {'profileName': 'Mike', 'confidence': _confidence});
  }

  void _handleVerificationSuccess() => setState(() {
    _verified = true;
    _navigateToProfile();
  });


  void _handleVerificationFailure() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification failed. Please try again.'))
  );

  void _retryVerification() => setState(() {
    _verified = false;
    _confidence = 0.0;
  });

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
              Text('Verification Successful! (Confidence: ${(_confidence * 100).toStringAsFixed(1)}%)', style: const TextStyle(color: Colors.green)),
            ElevatedButton(
              onPressed: _isLoading || _verified ? null : () {
                _processECGData().then((_) {
                  if (_verified) {_handleVerificationSuccess();}
                  else{ _handleVerificationFailure();}
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











