import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import '../utils/extra.dart';
import 'ecg_data_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;

  List<int> _parsedECGSamples = [];

  @override
  void initState() {
    super.initState();
    _initializeSubscriptions();
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  void _initializeSubscriptions() {
    _scanResultsSubscription = FlutterBluePlus.scanResults
        .listen(_handleScanResults, onError: _handleError);
    _isScanningSubscription = FlutterBluePlus.isScanning
        .listen(_handleIsScanning, onError: _handleError);
  }

  void _handleScanResults(List<ScanResult> results) {
    _scanResults = results;
    _updateState();
  }

  void _handleIsScanning(bool state) {
    _isScanning = state;
    _updateState();
  }

  void _handleError(dynamic error) {
    Snackbar.show(ABC.b, prettyException("Error:", error), success: false);
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startScan() async {
    try {
      _systemDevices = await FlutterBluePlus.systemDevices;
      print('System devices: $_systemDevices');
    } catch (e) {
      _showErrorSnackbar("System Devices Error:", e);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      print('Scan started');
    } catch (e) {
      _showErrorSnackbar("Start Scan Error:", e);
    }
    _updateState();
  }

  Future<void> _stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      print('Scan stopped');
    } catch (e) {
      _showErrorSnackbar("Stop Scan Error:", e);
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      print('Connected to device: ${device.name}');
      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() ==
              "b7981234-6189-d7a6-5241-39acc25f2471") {
            await characteristic.setNotifyValue(true);

            // Set a flag to control the duration of the connection
            bool shouldContinue = true;

            // Start a timer to disconnect after a specific duration (e.g., 60 seconds)
            Future.delayed(const Duration(seconds: 10), () {
              shouldContinue = false;
              device.disconnect();
            });

            characteristic.lastValueStream.listen((List<int>? value) {
              if (shouldContinue && value != null) {
                print('Receiving data');
                List<int> parsedSamples = _parseECGData(value);
                _updateECGSamples(parsedSamples);
              }
            }, onError: (error) {
              print('Error in characteristic value stream: $error');
            });
          }
        }
      }
    } catch (e) {
      _showErrorSnackbar("Connect Error:", e);
    }
  }

  List<int> _parseECGData(List<int> rawData) {
    rawData = rawData.sublist(1);
    print("Raw ECG data: $rawData");

    List<int> parsedSamples = [];
    for (int i = 0; i < rawData.length; i += 2) {
      int sample = (rawData[i] & 0xFF) | ((rawData[i + 1] & 0xFF) << 8);
      parsedSamples.add(sample);
    }

    return parsedSamples;
  }

  void _updateECGSamples(List<int> samples) {
    if (samples.isNotEmpty) {
      print("Updating ECG samples: $samples");
      setState(() {
        _parsedECGSamples.addAll(samples);
      });
    }
  }

  Future<void> _onRefresh() async {
    if (!_isScanning) {
      await _startScan();
    }
    _updateState();
    await Future.delayed(Duration(milliseconds: 500));
  }

  Widget _buildScanButton(BuildContext context) {
    if (_isScanning) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: _stopScan,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(
        child: const Text("SCAN"),
        onPressed: _startScan,
      );
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen: () => _navigateToDeviceScreen(d),
            onConnect: () => _connectToDevice(d),
          ),
        )
        .toList();
  }

  void _navigateToDeviceScreen(BluetoothDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device),
        settings: RouteSettings(name: '/DeviceScreen'),
      ),
    );
  }

  void _navigateToECGDataScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ECGDataScreen(parsedECGSamples: _parsedECGSamples),
      ),
    );
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    List<ScanResult> filteredScanResults = _scanResults
        .where((r) =>
            r.device.platformName?.toLowerCase().contains("oxa") ?? false)
        .toList();

    return filteredScanResults
        .map((r) => ScanResultTile(
              result: r,
              onTap: () => _connectToDevice(r.device),
            ))
        .toList();
  }

  void _handleGoButton() {
    bool isBluetoothScreen = false;
    print("Parsed ECG samples in _handleGoButton: $_parsedECGSamples");
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == '/bluetooth-pairing') {
        isBluetoothScreen = true;
        return true;
      }
      return false;
    });

    if (isBluetoothScreen) {
      Navigator.of(context).pushNamed('/enroll');
    } else {
      final previousRoute = ModalRoute.of(context)?.settings?.name;
      if (previousRoute == '/create-account') {
        Navigator.of(context).pushNamed('/enroll');
      } else if (previousRoute == '/') {
        Navigator.of(context).pushNamed('/verification');
      } else {
        Navigator.of(context).pushNamed('/enroll');
      }
    }
  }

  void _showErrorSnackbar(String prefix, dynamic error) {
    Snackbar.show(ABC.b, prettyException("$prefix", error), success: false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices'),
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            children: <Widget>[
              ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => _handleGoButton(),
                child: Text('Go'),
              ),
              ElevatedButton(
                onPressed: _navigateToECGDataScreen,
                child: Text('View ECG Data'),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildScanButton(context),
      ),
    );
  }
}
