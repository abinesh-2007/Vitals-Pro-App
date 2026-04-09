import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vitals_pro/services/ble_status.dart';
import 'package:vitals_pro/services/vitals_data.dart';
import 'package:vitals_pro/services/ble_manager.dart';

import '../auth/login_screen.dart';
import '../reports/daily_report_screen.dart';
import 'live_monitoring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool _isRefreshing = false;

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /* ================= REFRESH ================= */

  Future<void> _refreshConnection() async {

    setState(() => _isRefreshing = true);

    await BleManager().forceReconnect();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1117),

      drawer: _buildDrawer(context, user),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text("SOS"),
        onPressed: () {},
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.redAccent,
          onRefresh: _refreshConnection,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// TOP BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Text(
                      "Vitals Pro",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.redAccent,
                            ),
                          )
                        : const SizedBox(width: 20),
                  ],
                ),

                const SizedBox(height: 25),

                /// USER INFO
                Text(
                  "Welcome Back 👋",
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 5),
                Text(
                  user?.email ?? "User",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 25),

                /// BLE STATUS
                ValueListenableBuilder<bool>(
                  valueListenable: BleStatus.isConnected,
                  builder: (context, connected, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: connected
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              size: 10,
                              color: connected ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            connected
                                ? "Device Connected"
                                : "Pull down to reconnect",
                            style: TextStyle(
                              color: connected ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                /// QUICK VITALS
                const Text(
                  "Quick Vitals",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    ValueListenableBuilder<double>(
                      valueListenable: VitalsData.heartRate,
                      builder: (context, value, _) {
                        return _miniVital(
                            "HR",
                            value == 0 ? "--" : value.toStringAsFixed(0),
                            "BPM",
                            Colors.redAccent);
                      },
                    ),

                    ValueListenableBuilder<double>(
                      valueListenable: VitalsData.temperature,
                      builder: (context, value, _) {
                        return _miniVital(
                            "Temp",
                            value == 0 ? "--" : value.toStringAsFixed(1),
                            "°C",
                            Colors.orangeAccent);
                      },
                    ),

                    ValueListenableBuilder<double>(
                      valueListenable: VitalsData.respiratoryRate,
                      builder: (context, value, _) {
                        return _miniVital(
                            "RR",
                            value == 0 ? "--" : value.toStringAsFixed(0),
                            "rpm",
                            Colors.blueAccent);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                /// QUICK ACCESS
                const Text(
                  "Quick Access",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    _dashboardCard(
                      icon: Icons.monitor_heart,
                      title: "Live Monitoring",
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const LiveMonitoringScreen()),
                        );
                      },
                    ),

                    _dashboardCard(
                      icon: Icons.bar_chart,
                      title: "Reports",
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DailyReportScreen()),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniVital(
      String title, String value, String unit, Color color) {

    return Container(
      width: 100,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(unit,
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _dashboardCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 35, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, User? user) {
    return Drawer(
      backgroundColor: const Color(0xFF161B22),
      child: Column(
        children: [

          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.redAccent,
            ),
            accountName: const Text("Patient"),
            accountEmail: Text(user?.email ?? "No Email"),
          ),

          ListTile(
            leading:
                const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text("Logout",
                style: TextStyle(color: Colors.redAccent)),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }
}