import 'package:flutter/material.dart';

class VitalsData {

  // 🔥 RAW SIGNALS
  static ValueNotifier<double> ecg =
      ValueNotifier<double>(0);

  static ValueNotifier<double> bioz =
      ValueNotifier<double>(0);

  // 🔥 CALCULATED VITALS
  static ValueNotifier<double> heartRate =
      ValueNotifier<double>(0);

  static ValueNotifier<double> temperature =
      ValueNotifier<double>(0);

  static ValueNotifier<double> respiratoryRate =
      ValueNotifier<double>(0);

  static ValueNotifier<String> bloodPressure =
      ValueNotifier<String>("--");

  static ValueNotifier<String> hydration =
      ValueNotifier<String>("--");

  static ValueNotifier<String> motion =
      ValueNotifier<String>("--");

  // 🔥 RESET ALL VALUES
  static void reset() {
    ecg.value = 0;
    bioz.value = 0;
    heartRate.value = 0;
    temperature.value = 0;
    respiratoryRate.value = 0;
    bloodPressure.value = "--";
    hydration.value = "--";
    motion.value = "--";
  }
}