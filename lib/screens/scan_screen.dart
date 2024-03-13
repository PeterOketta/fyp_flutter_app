import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'device_screen.dart';
import '../utils/snackbar.dart';
import '../widgets/system_device_tile.dart';
import '../widgets/scan_result_tile.dart';
import 'ecg_data_screen.dart';
import '../utils/BluetoothUtils.dart';
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

  final List<int> _parsedECGSamples = [];

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

  void _findTargetCharacteristic(BluetoothDevice device) async {
    BluetoothUtils utils = BluetoothUtils(); // Create an instance
    await utils.findTargetCharacteristic(device);
  }
  Future<List<int>> _collectECGData(Duration duration, BluetoothCharacteristic characteristic) async {
    BluetoothUtils utils = BluetoothUtils(); // Create an instance if needed
    return await utils.collectDataFromCharacteristic(duration, characteristic);
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
            onConnect: () => _findTargetCharacteristic(d),
          ),
        )
        .toList();
  }

  void _navigateToDeviceScreen(BluetoothDevice device) async {
    try {
      await device.connect(); // Ensure connection
      BluetoothUtils utils = BluetoothUtils();
      BluetoothCharacteristic? characteristic = await utils.findTargetCharacteristic(device);

      if (characteristic != null) {
        Navigator.of(context).pushNamed(
          '/enroll',
          arguments: {'characteristic': characteristic},
        );

      } else {
        // Handle the case where the characteristic couldn't be found
        Snackbar.show(ABC.b, "Charasteristic not found", success: false);
      }

    } catch(e) {
      _showErrorSnackbar("Device Screen Error:", e);
    }
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
              onTap: () => _findTargetCharacteristic(r.device),
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
