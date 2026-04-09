class DailyReport {

  final DateTime date;

  final double avgHR;
  final double minHR;
  final double maxHR;
  final double hrVariability;

  final double avgRR;

  final double avgTemp;

  final double avgSys;
  final double avgDia;

  final double lowHydrationPercent;
  final double activePercent;

  final int riskScore;

  DailyReport({
    required this.date,
    required this.avgHR,
    required this.minHR,
    required this.maxHR,
    required this.hrVariability,
    required this.avgRR,
    required this.avgTemp,
    required this.avgSys,
    required this.avgDia,
    required this.lowHydrationPercent,
    required this.activePercent,
    required this.riskScore,
  });
}