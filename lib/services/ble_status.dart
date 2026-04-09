import 'package:flutter/material.dart';

class BleStatus {

  /// True if Bluetooth adapter is ON
  static ValueNotifier<bool> isBluetoothOn =
      ValueNotifier<bool>(false);

  /// True if Pocket device is connected
  static ValueNotifier<bool> isConnected =
      ValueNotifier<bool>(false);

}