import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vitals_pro/services/vitals_data.dart';
import 'package:vitals_pro/services/ble_status.dart';
import 'live_graph_screen.dart';

class LiveMonitoringScreen extends StatefulWidget {
  const LiveMonitoringScreen({super.key});

  @override
  State<LiveMonitoringScreen> createState() =>
      _LiveMonitoringScreenState();
}

class _LiveMonitoringScreenState
    extends State<LiveMonitoringScreen> {

  // Graph Stream Controllers
  final StreamController<double> ecgController =
      StreamController<double>.broadcast();
  final StreamController<double> biozController =
      StreamController<double>.broadcast();
  final StreamController<double> hrController =
      StreamController<double>.broadcast();
  final StreamController<double> tempController =
      StreamController<double>.broadcast();
  final StreamController<String> motionController =
      StreamController<String>.broadcast();
  final StreamController<String> hydrationController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    // 🔥 Forward ECG
    VitalsData.ecg.addListener(() {
      ecgController.add(VitalsData.ecg.value);
    });

    // 🔥 Forward BioZ
    VitalsData.bioz.addListener(() {
      biozController.add(VitalsData.bioz.value);
    });

    // Forward HR
    VitalsData.heartRate.addListener(() {
      hrController.add(VitalsData.heartRate.value);
    });

    // Forward Temp
    VitalsData.temperature.addListener(() {
      tempController.add(VitalsData.temperature.value);
    });

    // Forward Motion
    VitalsData.motion.addListener(() {
      motionController.add(VitalsData.motion.value);
    });

    // Forward Hydration
    VitalsData.hydration.addListener(() {
      hydrationController.add(VitalsData.hydration.value);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Monitoring"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 🔥 Bluetooth ON/OFF
            ValueListenableBuilder<bool>(
              valueListenable: BleStatus.isBluetoothOn,
              builder: (_, bluetoothOn, __) {
                if (!bluetoothOn) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Bluetooth is OFF. Please turn it ON.",
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),

            const SizedBox(height: 15),

            // 🔥 Connection Status
            ValueListenableBuilder<bool>(
              valueListenable: BleStatus.isConnected,
              builder: (_, connected, __) {
                return Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle,
                        color: connected
                            ? Colors.green
                            : Colors.red,
                        size: 14),
                    const SizedBox(width: 8),
                    Text(
                      connected
                          ? "Connected & Streaming"
                          : "Disconnected",
                      style: TextStyle(
                          color: connected
                              ? Colors.green
                              : Colors.red),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // 🔥 VITALS CARDS

            ValueListenableBuilder<double>(
              valueListenable: VitalsData.ecg,
              builder: (_, value, __) =>
                  vitalsCard("Raw ECG",
                      value.toStringAsFixed(0)),
            ),

            ValueListenableBuilder<double>(
              valueListenable: VitalsData.bioz,
              builder: (_, value, __) =>
                  vitalsCard("Raw BioZ",
                      value.toStringAsFixed(0)),
            ),

            ValueListenableBuilder<double>(
              valueListenable: VitalsData.heartRate,
              builder: (_, value, __) =>
                  vitalsCard("Heart Rate (BPM)",
                      value == 0
                          ? "--"
                          : value.toStringAsFixed(0)),
            ),

            ValueListenableBuilder<double>(
              valueListenable: VitalsData.temperature,
              builder: (_, value, __) =>
                  vitalsCard("Temperature (°C)",
                      value == 0
                          ? "--"
                          : value.toStringAsFixed(1)),
            ),

            ValueListenableBuilder<double>(
              valueListenable:
                  VitalsData.respiratoryRate,
              builder: (_, value, __) =>
                  vitalsCard("Respiratory Rate",
                      value == 0
                          ? "--"
                          : value.toStringAsFixed(0)),
            ),

            ValueListenableBuilder<String>(
              valueListenable:
                  VitalsData.bloodPressure,
              builder: (_, value, __) =>
                  vitalsCard("Blood Pressure",
                      value),
            ),

            ValueListenableBuilder<String>(
              valueListenable:
                  VitalsData.hydration,
              builder: (_, value, __) =>
                  vitalsCard("Hydration Status",
                      value),
            ),

            ValueListenableBuilder<String>(
              valueListenable:
                  VitalsData.motion,
              builder: (_, value, __) =>
                  vitalsCard("Motion Status",
                      value),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LiveGraphScreen(
                      ecgStream: ecgController.stream,
                      biozStream: biozController.stream,
                      hrStream: hrController.stream,
                      tempStream: tempController.stream,
                      motionStream: motionController.stream,
                      hydrationStream:
                          hydrationController.stream,
                    ),
                  ),
                );
              },
              child: const Text("Open Live Graph"),
            ),
          ],
        ),
      ),
    );
  }

  Widget vitalsCard(
      String title, String value) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    ecgController.close();
    biozController.close();
    hrController.close();
    tempController.close();
    motionController.close();
    hydrationController.close();
    super.dispose();
  }
}