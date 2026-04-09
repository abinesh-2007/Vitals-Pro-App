import 'dart:async';
import 'database_service.dart';
import 'vitals_data.dart';

class VitalsRecorder {

  static Timer? _timer;

  /* ================= START RECORDING ================= */

  static void start() {

    // Prevent multiple timers
    if (_timer != null) return;

    _timer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) async {

        double hr = VitalsData.heartRate.value;
        double rr = VitalsData.respiratoryRate.value;
        double temp = VitalsData.temperature.value;
        String bp = VitalsData.bloodPressure.value;
        String hyd = VitalsData.hydration.value;
        String motion = VitalsData.motion.value;

        // Only save if device connected & values valid
        if (hr > 0 || temp > 0) {

          await DatabaseService.insertVitals(
            heartRate: hr,
            respRate: rr,
            temperature: temp,
            bloodPressure: bp,
            hydration: hyd,
            motion: motion,
          );

          print("Vitals Saved (1 min interval)");
        }
      },
    );
  }

  /* ================= STOP RECORDING ================= */

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}