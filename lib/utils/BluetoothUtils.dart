import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'snackbar.dart';

class BluetoothUtils {
  BluetoothCharacteristic? _targetCharacteristic;
  Future<BluetoothCharacteristic?> findTargetCharacteristic(BluetoothDevice device) async {
    try {
      await device.connect();
      print('Connected to device: ${device.name}');

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == "b7981234-6189-d7a6-5241-39acc25f2471") {
            _targetCharacteristic = characteristic;
            return characteristic;// Store globally
          }
        }
      }

      return null; // Characteristic not found

    } catch (e) {
      _showErrorSnackbar("Connect Error:", e);
      return null;
    }
  }

  Future<List<int>> collectDataFromCharacteristic(Duration duration, BluetoothCharacteristic characteristic) async {
    if (characteristic == null) { // Ensure characteristic is provided
      throw Exception('Bluetooth characteristic not found.');
    }

    List<int> collectedData = [];

    // Set up listening and timer (using provided characteristic)
    await characteristic.setNotifyValue(true);
    Future.delayed(duration, () => characteristic.setNotifyValue(false));

    // Collect data
    characteristic.value.listen((List<int>? value) {
      if (value != null) {
        collectedData.addAll(_parseECGData(value));
      }
    }, onError: (error) {
      print('Error in characteristic value stream: $error');
    });

    return collectedData;

  }
  List<int> _parseECGData(List<int> rawData) {
    rawData = rawData.sublist(1);
    List<int> parsedSamples = [];
    for (int i = 0; i < rawData.length; i += 2) {
      int sample = (rawData[i] & 0xFF) | ((rawData[i + 1] & 0xFF) << 8);
      parsedSamples.add(sample);
    }

    return parsedSamples;
  }
  void _showErrorSnackbar(String prefix, dynamic error) {
    Snackbar.show(ABC.b, prettyException("$prefix", error), success: false);
  }

}
