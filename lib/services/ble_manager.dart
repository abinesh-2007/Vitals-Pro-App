import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';

import 'ble_status.dart';
import 'vitals_data.dart';

class BleManager {
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  fbp.BluetoothDevice? _connectedDevice;
  fbp.BluetoothCharacteristic? _notifyChar;

  StreamSubscription<List<fbp.ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<fbp.BluetoothConnectionState>? _connectionSub;
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterSub;

  Timer? _retryTimer;

  final fbp.Guid serviceUUID =
      fbp.Guid("6E400010-B5A3-F393-E0A9-E50E24DCCA9E");

  final fbp.Guid characteristicUUID =
      fbp.Guid("6E400011-B5A3-F393-E0A9-E50E24DCCA9E");

  String _buffer = "";

  bool _isScanning = false;
  bool _isConnecting = false;

  /* ================= INITIALIZE ================= */

  Future<void> initialize() async {
    await _requestPermissions();

    _adapterSub?.cancel();
    _adapterSub =
        fbp.FlutterBluePlus.adapterState.listen((state) {
      if (state == fbp.BluetoothAdapterState.on) {
        BleStatus.isBluetoothOn.value = true;
        _startAutoReconnect();
      } else {
        BleStatus.isBluetoothOn.value = false;
        BleStatus.isConnected.value = false;
        _connectedDevice = null;
        _stopAutoReconnect();
      }
    });

    var state = await fbp.FlutterBluePlus.adapterState.first;

    if (state == fbp.BluetoothAdapterState.on) {
      BleStatus.isBluetoothOn.value = true;
      _startAutoReconnect();
    }
  }

  Future<void> _requestPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  /* ================= AUTO RECONNECT ================= */

  void _startAutoReconnect() {
    _retryTimer?.cancel();

    _retryTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (_connectedDevice == null &&
            !_isScanning &&
            !_isConnecting &&
            BleStatus.isBluetoothOn.value) {
          _startScan();
        }
      },
    );
  }

  void _stopAutoReconnect() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  /* ================= SCAN ================= */

  Future<void> _startScan() async {
    if (_isScanning || _connectedDevice != null) return;

    _isScanning = true;

    try {
      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
      );

      _scanSub?.cancel();

      _scanSub =
          fbp.FlutterBluePlus.scanResults.listen((results) {
        for (fbp.ScanResult r in results) {
          if (r.device.name == "VitalsPro_Pocket") {
            fbp.FlutterBluePlus.stopScan();
            _isScanning = false;
            _connect(r.device);
            break;
          }
        }
      });

      // Safety reset if scan times out
      Future.delayed(const Duration(seconds: 5), () {
        _isScanning = false;
      });
    } catch (_) {
      _isScanning = false;
    }
  }

  /* ================= CONNECT ================= */

  Future<void> _connect(fbp.BluetoothDevice device) async {
    if (_isConnecting) return;

    try {
      _isConnecting = true;
      _connectedDevice = device;

      await device.connect(autoConnect: false);
      await device.requestMtu(100);

      BleStatus.isConnected.value = true;

      _connectionSub?.cancel();
      _connectionSub =
          device.connectionState.listen((state) {
        if (state ==
            fbp.BluetoothConnectionState.disconnected) {
          BleStatus.isConnected.value = false;
          _connectedDevice = null;
          _notifyChar = null;
        }
      });

      await _discoverServices();
    } catch (_) {
      BleStatus.isConnected.value = false;
      _connectedDevice = null;
    } finally {
      _isConnecting = false;
    }
  }

  /* ================= DISCOVER ================= */

  Future<void> _discoverServices() async {
    if (_connectedDevice == null) return;

    List<fbp.BluetoothService> services =
        await _connectedDevice!.discoverServices();

    for (fbp.BluetoothService service in services) {
      if (service.uuid == serviceUUID) {
        for (fbp.BluetoothCharacteristic c
            in service.characteristics) {
          if (c.uuid == characteristicUUID) {
            _notifyChar = c;

            await c.setNotifyValue(true);

            _notifySub?.cancel();
            _notifySub =
                c.lastValueStream.listen(_handleData);

            break;
          }
        }
      }
    }
  }

  /* ================= DATA ================= */

  void _handleData(List<int> value) {
    try {
      String chunk = utf8.decode(value);
      _buffer += chunk;

      if (_buffer.contains("\n")) {
        List<String> packets =
            _buffer.split("\n");

        for (int i = 0;
            i < packets.length - 1;
            i++) {
          _parsePacket(packets[i].trim());
        }

        _buffer = packets.last;
      }
    } catch (_) {}
  }

  void _parsePacket(String packet) {
    if (packet.isEmpty) return;

    List<String> parts = packet.split(",");

    for (String part in parts) {
      List<String> keyVal = part.split(":");
      if (keyVal.length != 2) continue;

      String key = keyVal[0].trim();
      String value = keyVal[1].trim();

      switch (key) {
        case "E":
          VitalsData.ecg.value =
              double.tryParse(value) ?? 0;
          break;
        case "B":
          VitalsData.bioz.value =
              double.tryParse(value) ?? 0;
          break;
        case "HR":
          VitalsData.heartRate.value =
              double.tryParse(value) ?? 0;
          break;
        case "TEMP":
          VitalsData.temperature.value =
              double.tryParse(value) ?? 0;
          break;
        case "RR":
          VitalsData.respiratoryRate.value =
              double.tryParse(value) ?? 0;
          break;
        case "BP":
          VitalsData.bloodPressure.value = value;
          break;
        case "HYD":
          VitalsData.hydration.value = value;
          break;
        case "M":
          VitalsData.motion.value = value;
          break;
      }
    }
  }

  /* ================= MANUAL RECONNECT ================= */

  Future<void> forceReconnect() async {
    await disconnect();
    await Future.delayed(
        const Duration(milliseconds: 500));
    _startScan();
  }

  /* ================= DISCONNECT ================= */

  Future<void> disconnect() async {
    try {
      await _notifySub?.cancel();
      await _connectionSub?.cancel();
      await _connectedDevice?.disconnect();
    } catch (_) {}

    BleStatus.isConnected.value = false;
    _connectedDevice = null;
    _notifyChar = null;
  }

  /* ================= CLEANUP ================= */

  void dispose() {
    _retryTimer?.cancel();
    _scanSub?.cancel();
    _notifySub?.cancel();
    _connectionSub?.cancel();
    _adapterSub?.cancel();
  }
}