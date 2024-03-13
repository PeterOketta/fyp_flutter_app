import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  static BluetoothCharacteristic? _characteristic;

  static setCharacteristic(BluetoothCharacteristic characteristic) {
    _characteristic = characteristic;
  }

  static BluetoothCharacteristic? getCharacteristic() {
    return _characteristic;
  }
}