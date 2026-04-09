import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home/home_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final emergencyNameController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  String selectedGender = "Male";
  String selectedBloodGroup = "O+";
  bool hasChronicDisease = false;
  bool isDialysisPatient = false;

  bool isLoading = false;

  Future<void> saveProfile() async {

    // 🔥 VALIDATION CHECK
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() => isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "name": nameController.text.trim(),
        "age": int.parse(ageController.text.trim()),
        "gender": selectedGender,
        "phone": phoneController.text.trim(),
        "height": double.parse(heightController.text.trim()),
        "weight": double.parse(weightController.text.trim()),
        "bloodGroup": selectedBloodGroup,
        "hasChronicDisease": hasChronicDisease,
        "isDialysisPatient": isDialysisPatient,
        "emergencyContactName":
            emergencyNameController.text.trim(),
        "emergencyContactPhone":
            emergencyPhoneController.text.trim(),
        "profileCompleted": true,
        "createdAt": Timestamp.now(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // 🔥 Cannot go back
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF141E30),
                Color(0xFF243B55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Patient Profile Setup",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildTextField("Full Name", nameController),
                      _buildNumberField("Age", ageController),
                      _buildTextField("Phone Number", phoneController),

                      const SizedBox(height: 10),

                      _buildDropdown(
                        "Gender",
                        ["Male", "Female", "Other"],
                        selectedGender,
                        (value) => setState(
                            () => selectedGender = value!),
                      ),

                      _buildDropdown(
                        "Blood Group",
                        ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"],
                        selectedBloodGroup,
                        (value) => setState(
                            () => selectedBloodGroup = value!),
                      ),

                      _buildNumberField("Height (cm)", heightController),
                      _buildNumberField("Weight (kg)", weightController),

                      SwitchListTile(
                        value: hasChronicDisease,
                        onChanged: (val) =>
                            setState(() => hasChronicDisease = val),
                        title: const Text("Chronic Disease",
                            style: TextStyle(color: Colors.white)),
                      ),

                      SwitchListTile(
                        value: isDialysisPatient,
                        onChanged: (val) =>
                            setState(() => isDialysisPatient = val),
                        title: const Text("Dialysis Patient",
                            style: TextStyle(color: Colors.white)),
                      ),

                      const SizedBox(height: 10),

                      _buildTextField(
                          "Emergency Contact Name",
                          emergencyNameController),

                      _buildTextField(
                          "Emergency Contact Phone",
                          emergencyPhoneController),

                      const SizedBox(height: 25),

                      isLoading
                          ? const Center(
                              child: CircularProgressIndicator())
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.cyanAccent,
                                  foregroundColor:
                                      Colors.black,
                                  shape:
                                      RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: saveProfile,
                                child: const Text(
                                  "Save & Continue",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.bold),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label,
      TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "This field is required";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label,
      TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "This field is required";
          }
          if (double.tryParse(value) == null) {
            return "Enter a valid number";
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items,
      String value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: Colors.black87,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item,
                      style: const TextStyle(
                          color: Colors.white)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
