import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRegister extends StatefulWidget {
  const AdminRegister({super.key});

  @override
  State<AdminRegister> createState() => _AdminRegisterState();
}

class _AdminRegisterState extends State<AdminRegister> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirmPassword = true;

  /// REGISTER FUNCTION
  Future<void> registerAdmin() async {
    String name = nameController.text.trim();
    String userId = userIdController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || userId.isEmpty || password.isEmpty) {
      showMsg("All fields required");
      return;
    }

    if (password.length < 6) {
      showMsg("Password must be at least 6 characters");
      return;
    }

    if (password != confirmPassword) {
      showMsg("Password not match");
      return;
    }

    setState(() => isLoading = true);

    try {
      /// CHECK DUPLICATE USER ID
      var existing = await firestore
          .collection("admins")
          .where("userId", isEqualTo: userId)
          .get();

      if (existing.docs.isNotEmpty) {
        showMsg("User ID already exists");
        setState(() => isLoading = false);
        return;
      }

      /// SAVE DATA
      await firestore.collection("admins").add({
        "name": name,
        "userId": userId,
        "password": password,
        "createdAt": DateTime.now(),
      });

      showMsg("Registered Successfully ✅");
      Navigator.pop(context);
    } catch (e) {
      showMsg("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    /// RESPONSIVE WIDTH
    double containerWidth = width < 600
        ? width * 0.9
        : width < 1000
        ? 500
        : 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff8E2DE2),
              Color(0xff4A00E0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: Stack(
          children: [

            /// BACK BUTTON
            Positioned(
              top: 40,
              left: 15,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            /// MAIN UI
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: containerWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: EdgeInsets.all(width < 600 ? 20 : 30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),

                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              const Icon(
                                Icons.person_add,
                                size: 70,
                                color: Colors.white,
                              ),

                              const SizedBox(height: 15),

                              const Text(
                                "Register Admin",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 25),

                              /// NAME
                              TextField(
                                controller: nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: inputDecoration("Name", Icons.person),
                              ),

                              const SizedBox(height: 15),

                              /// USER ID
                              TextField(
                                controller: userIdController,
                                style: const TextStyle(color: Colors.white),
                                decoration: inputDecoration("User ID", Icons.badge),
                              ),

                              const SizedBox(height: 15),

                              /// PASSWORD
                              TextField(
                                controller: passwordController,
                                obscureText: hidePassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: inputDecoration(
                                  "Password",
                                  Icons.lock,
                                  suffix: IconButton(
                                    icon: Icon(
                                      hidePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              /// CONFIRM PASSWORD
                              TextField(
                                controller: confirmPasswordController,
                                obscureText: hideConfirmPassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: inputDecoration(
                                  "Confirm Password",
                                  Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(
                                      hideConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        hideConfirmPassword =
                                        !hideConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              /// REGISTER BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : registerAdmin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.deepPurple,
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator()
                                      : const Text(
                                    "Register",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }

  /// COMMON INPUT DECORATION
  InputDecoration inputDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white),
      suffixIcon: suffix,
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}