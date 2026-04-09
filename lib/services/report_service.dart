import 'dart:math';
import '../services/database_service.dart';
import '../models/daily_report.dart';

class ReportService {

  static Future<DailyReport?> generateDailyReport(
      DateTime date) async {

    final data =
        await DatabaseService.getVitalsByDate(date);

    if (data.isEmpty) return null;

    List<double> hrList = [];
    List<double> rrList = [];
    List<double> tempList = [];
    List<double> sysList = [];
    List<double> diaList = [];

    int lowHydrationCount = 0;
    int activeCount = 0;

    for (var row in data) {

      double hr = row['heartRate'] ?? 0;
      double rr = row['respiratoryRate'] ?? 0;
      double temp = row['temperature'] ?? 0;
      String bp = row['bloodPressure'] ?? "";
      String hyd = row['hydration'] ?? "";
      String motion = row['motion'] ?? "";

      if (hr > 0) hrList.add(hr);
      if (rr > 0) rrList.add(rr);
      if (temp > 0) tempList.add(temp);

      if (bp.contains("/")) {
        var parts = bp.split("/");
        sysList.add(double.tryParse(parts[0]) ?? 0);
        diaList.add(double.tryParse(parts[1]) ?? 0);
      }

      if (hyd == "Low") lowHydrationCount++;

      if (motion == "Walking" ||
          motion == "Running")
        activeCount++;
    }

    double avgHR = _average(hrList);
    double minHR = hrList.isEmpty ? 0 : hrList.reduce(min);
    double maxHR = hrList.isEmpty ? 0 : hrList.reduce(max);
    double hrVar = _stdDev(hrList);

    double avgRR = _average(rrList);
    double avgTemp = _average(tempList);
    double avgSys = _average(sysList);
    double avgDia = _average(diaList);

    double lowHydPercent =
        (lowHydrationCount / data.length) * 100;

    double activePercent =
        (activeCount / data.length) * 100;

    int risk = _calculateRisk(
      avgHR,
      avgSys,
      avgTemp,
      lowHydPercent,
    );

    return DailyReport(
      date: date,
      avgHR: avgHR,
      minHR: minHR,
      maxHR: maxHR,
      hrVariability: hrVar,
      avgRR: avgRR,
      avgTemp: avgTemp,
      avgSys: avgSys,
      avgDia: avgDia,
      lowHydrationPercent: lowHydPercent,
      activePercent: activePercent,
      riskScore: risk,
    );
  }

  /* ================= HELPERS ================= */

  static double _average(List<double> list) {
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  static double _stdDev(List<double> list) {
    if (list.length < 2) return 0;

    double mean = _average(list);
    double sum = 0;

    for (double v in list) {
      sum += pow(v - mean, 2);
    }

    return sqrt(sum / list.length);
  }

  static int _calculateRisk(
      double hr,
      double sys,
      double temp,
      double lowHydPercent) {

    int score = 0;

    if (hr < 50 || hr > 110) score += 25;
    if (sys > 140) score += 25;
    if (temp > 37.8) score += 20;
    if (lowHydPercent > 30) score += 20;

    return score > 100 ? 100 : score;
  }
}