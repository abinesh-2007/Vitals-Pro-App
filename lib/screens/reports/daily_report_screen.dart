import 'package:flutter/material.dart';
import '../../models/daily_report.dart';
import '../../services/report_service.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() =>
      _DailyReportScreenState();
}

class _DailyReportScreenState
    extends State<DailyReportScreen> {

  DailyReport? report;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    DailyReport? result =
        await ReportService.generateDailyReport(
            DateTime.now());

    setState(() {
      report = result;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Health Report"),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator())
          : report == null
              ? const Center(
                  child: Text(
                      "No Data Available Today"))
              : _buildReport(),
    );
  }

  Widget _buildReport() {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [

          _riskCard(),

          const SizedBox(height: 25),

          _metricCard(
              "Heart Rate",
              "Avg: ${report!.avgHR.toStringAsFixed(1)} BPM\n"
              "Min: ${report!.minHR.toStringAsFixed(0)}\n"
              "Max: ${report!.maxHR.toStringAsFixed(0)}\n"
              "HRV: ${report!.hrVariability.toStringAsFixed(2)}"),

          _metricCard(
              "Blood Pressure",
              "Avg: ${report!.avgSys.toStringAsFixed(0)}/"
              "${report!.avgDia.toStringAsFixed(0)}"),

          _metricCard(
              "Temperature",
              "Avg: ${report!.avgTemp.toStringAsFixed(1)} °C"),

          _metricCard(
              "Respiratory Rate",
              "Avg: ${report!.avgRR.toStringAsFixed(1)}"),

          _metricCard(
              "Hydration",
              "Low: ${report!.lowHydrationPercent.toStringAsFixed(1)} %"),

          _metricCard(
              "Activity",
              "Active: ${report!.activePercent.toStringAsFixed(1)} %"),

          const SizedBox(height: 25),

          _clinicalSummary(),
        ],
      ),
    );
  }

  Widget _riskCard() {

    Color riskColor =
        report!.riskScore > 60
            ? Colors.red
            : report!.riskScore > 30
                ? Colors.orange
                : Colors.green;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text("Daily Risk Score",
              style: TextStyle(
                  color: Colors.white70)),
          const SizedBox(height: 10),
          Text(
            "${report!.riskScore}",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
      String title, String value) {

    return Container(
      width: double.infinity,
      margin:
          const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white)),
        ],
      ),
    );
  }

  Widget _clinicalSummary() {

    String message;

    if (report!.riskScore > 60) {
      message =
          "⚠ Elevated risk detected. Clinical review recommended.";
    } else if (report!.riskScore > 30) {
      message =
          "Moderate variations observed. Monitor closely.";
    } else {
      message =
          "Vitals within acceptable daily range.";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Text(
        message,
        style: const TextStyle(
            fontSize: 14,
            color: Colors.white),
      ),
    );
  }
}