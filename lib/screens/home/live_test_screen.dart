import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/realtime_db_service.dart';

class LiveTestScreen extends StatelessWidget {
  const LiveTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    DatabaseReference ref = RealtimeDBService.vitalsRef();

    return Scaffold(
      appBar: AppBar(title: const Text("Live Vitals Test")),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }

          if (!snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No data yet"));
          }

          final data =
              Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Heart Rate: ${data['heartRate']} bpm"),
                Text("SpO₂: ${data['spo2']} %"),
                Text("Temperature: ${data['temperature']} °C"),
                const SizedBox(height: 20),
                Text("Updated at: ${data['timestamp']}"),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          RealtimeDBService.writeTestVitals();
        },
        child: const Icon(Icons.cloud_upload),
      ),
    );
  }
}
