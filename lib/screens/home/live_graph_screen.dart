import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LiveGraphScreen extends StatefulWidget {
  final Stream<double> ecgStream;
  final Stream<double> biozStream;
  final Stream<double> hrStream;
  final Stream<double> tempStream;
  final Stream<String> motionStream;
  final Stream<String> hydrationStream;

  const LiveGraphScreen({
    super.key,
    required this.ecgStream,
    required this.biozStream,
    required this.hrStream,
    required this.tempStream,
    required this.motionStream,
    required this.hydrationStream,
  });

  @override
  State<LiveGraphScreen> createState() => _LiveGraphScreenState();
}

class _LiveGraphScreenState extends State<LiveGraphScreen>
    with SingleTickerProviderStateMixin {

  /* ================= DATA ================= */

  final List<FlSpot> ecgSpots = [];
  final List<FlSpot> biozSpots = [];
  final List<FlSpot> rPeaks = [];

  int x = 0;
  final int windowSize = 400;

  double ecgBaseline = 0;
  double ecgFiltered = 0;
  double prevEcg = 0;

  double biozBaseline = 0;
  double biozFiltered = 0;

  double heartRate = 0;
  double temperature = 0;

  bool highAlarm = false;
  bool lowAlarm = false;
  bool freeze = false;
  bool zoom2x = false;

  late AnimationController alarmBlink;

  StreamSubscription? ecgSub;
  StreamSubscription? biozSub;
  StreamSubscription? hrSub;
  StreamSubscription? tempSub;

  @override
  void initState() {
    super.initState();

    alarmBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    /* ================= ECG STREAM ================= */

    ecgSub = widget.ecgStream.listen((raw) {
      if (freeze) return;

      ecgBaseline = 0.995 * ecgBaseline + 0.005 * raw;
      double centered = raw - ecgBaseline;
      ecgFiltered = 0.9 * ecgFiltered + 0.1 * centered;

      double scaled = ecgFiltered / 120.0;
      if (zoom2x) scaled *= 2;

      // Auto gain soft clip
      if (scaled > 3) scaled = 3;
      if (scaled < -3) scaled = -3;

      // R peak detection
      if (scaled > 1.5 &&
          prevEcg < 1.0 &&
          (rPeaks.isEmpty || x - rPeaks.last.x > 45)) {
        rPeaks.add(FlSpot(x.toDouble(), scaled));
        if (rPeaks.length > 30) rPeaks.removeAt(0);
      }

      prevEcg = scaled;

      ecgSpots.add(FlSpot(x.toDouble(), scaled));
      if (ecgSpots.length > windowSize) ecgSpots.removeAt(0);

      x++;
      setState(() {});
    });

    /* ================= BIOZ STREAM ================= */

    biozSub = widget.biozStream.listen((raw) {
      if (freeze) return;

      biozBaseline = 0.995 * biozBaseline + 0.005 * raw;
      double centered = raw - biozBaseline;
      biozFiltered = 0.92 * biozFiltered + 0.08 * centered;

      double scaled = biozFiltered / 200.0;
      if (scaled > 2) scaled = 2;
      if (scaled < -2) scaled = -2;

      biozSpots.add(FlSpot(x.toDouble(), scaled));
      if (biozSpots.length > windowSize) biozSpots.removeAt(0);

      setState(() {});
    });

    /* ================= HR ================= */

    hrSub = widget.hrStream.listen((v) {
      heartRate = v;
      highAlarm = heartRate > 120;
      lowAlarm = heartRate < 50;
      setState(() {});
    });

    /* ================= TEMP ================= */

    tempSub = widget.tempStream.listen((v) {
      temperature = v;
      setState(() {});
    });
  }

  @override
  void dispose() {
    ecgSub?.cancel();
    biozSub?.cancel();
    hrSub?.cancel();
    tempSub?.cancel();
    alarmBlink.dispose();
    super.dispose();
  }

  /* ================= UI ================= */

  @override
  Widget build(BuildContext context) {

    Color hrColor =
        (highAlarm || lowAlarm) ? Colors.red : Colors.greenAccent;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("ICU Live Monitor"),
        actions: [
          IconButton(
            icon: Icon(zoom2x ? Icons.zoom_out : Icons.zoom_in),
            onPressed: () {
              setState(() => zoom2x = !zoom2x);
            },
          ),
          IconButton(
            icon: Icon(freeze ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              setState(() => freeze = !freeze);
            },
          ),
        ],
      ),
      body: Column(
        children: [

          /* ================= TOP VITALS ================= */

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                AnimatedBuilder(
                  animation: alarmBlink,
                  builder: (_, __) {
                    return Opacity(
                      opacity: (highAlarm || lowAlarm)
                          ? alarmBlink.value
                          : 1,
                      child: Text(
                        heartRate.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: hrColor,
                        ),
                      ),
                    );
                  },
                ),

                Text(
                  "${temperature.toStringAsFixed(1)} °C",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),

          /* ================= ECG PANEL ================= */

          Expanded(
            flex: 3,
            child: buildChart(
              title: "ECG",
              spots: ecgSpots,
              rSpots: rPeaks,
              color: Colors.greenAccent,
              minY: -3,
              maxY: 3,
              gridColor: Colors.red.withOpacity(0.15),
            ),
          ),

          /* ================= BIOZ PANEL ================= */

          Expanded(
            flex: 2,
            child: buildChart(
              title: "Respiration (BioZ)",
              spots: biozSpots,
              rSpots: const [],
              color: Colors.blueAccent,
              minY: -2,
              maxY: 2,
              gridColor: Colors.blue.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= CHART BUILDER ================= */

  Widget buildChart({
    required String title,
    required List<FlSpot> spots,
    required List<FlSpot> rSpots,
    required Color color,
    required double minY,
    required double maxY,
    required Color gridColor,
  }) {

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Expanded(
            child: LineChart(
              LineChartData(
                minX: spots.isEmpty ? 0 : spots.first.x,
                maxX: spots.isEmpty ? 0 : spots.last.x,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: (maxY - minY) / 6,
                  verticalInterval: 25,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: gridColor, strokeWidth: 0.5),
                  getDrawingVerticalLine: (value) =>
                      FlLine(color: gridColor, strokeWidth: 0.5),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [

                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),

                  if (rSpots.isNotEmpty)
                    LineChartBarData(
                      spots: rSpots,
                      isCurved: false,
                      barWidth: 0,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 4,
                              color: Colors.red,
                              strokeWidth: 0,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}