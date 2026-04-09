import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealtimeDBService {
  static final _db = FirebaseDatabase.instance.ref();

  /// Write test vitals data
  static Future<void> writeTestVitals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _db.child("users").child(user.uid).set({
      "heartRate": 78,
      "spo2": 98,
      "temperature": 36.7,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  /// Listen to vitals data
  static DatabaseReference vitalsRef() {
    final user = FirebaseAuth.instance.currentUser;
    return _db.child("users").child(user!.uid);
  }
}
