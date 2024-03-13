import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'snackbar.dart';
import 'BluetoothManager.dart';

class BluetoothUtils {
  Future<BluetoothCharacteristic?> findTargetCharacteristic(
      BluetoothDevice device) async {
    try {
      await device.connect();
      print('Connected to device: ${device.name}');

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
        in service.characteristics) {
          if (characteristic.uuid.toString() ==
              "b7981234-6189-d7a6-5241-39acc25f2471") {
            BluetoothManager.setCharacteristic(characteristic);
            return characteristic; // Store globally
          }
        }
      }

      return null; // Characteristic not found
    } catch (e) {
      _showErrorSnackbar("Connect Error:", e);
      return null;
    }
  }
  Future<List<int>> collectDataFromCharacteristic(
      Duration duration, BluetoothCharacteristic characteristic) async {
    if (characteristic == null) {
      throw Exception('Bluetooth characteristic not found.');
    }

    List<int> collectedData = [];
    Completer<List<int>> completer = Completer<List<int>>();

    // Initialize subscription with a no-op subscription
    StreamSubscription<List<int>> subscription = StreamController<List<int>>.broadcast().stream.listen((_) {});

    // Set up listening
    subscription = characteristic.value.listen(
          (List<int>? value) {
        if (value != null) {
          collectedData.addAll(_parseECGData(value));
        }
      },
      onDone: () {
        completer.complete(collectedData);
        subscription.cancel(); // Cancel the subscription when done
      },
      onError: (error) {
        completer.completeError(error);
      },
      cancelOnError: true,
    );

    // Set up timer
    Future.delayed(duration, () {
      if (!completer.isCompleted) {
        subscription.cancel(); // Cancel the subscription if timer expires
        completer.complete(collectedData);
      }
    });

    // Enable notifications
    await characteristic.setNotifyValue(true);

    return completer.future;
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
