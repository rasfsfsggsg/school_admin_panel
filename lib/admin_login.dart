import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_screen/admin_home_screen.dart';
import 'admin_register.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});

  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isPasswordHidden = true;

  Future<void> loginAdmin() async {
    String userId = userIdController.text.trim();
    String password = passwordController.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      showMsg("Enter User ID & Password");
      return;
    }

    setState(() => isLoading = true);

    try {
      QuerySnapshot snapshot = await firestore
          .collection("admins")
          .where("userId", isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;

        if (data["password"] == password) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminHomeScreen(),
            ),
          );
        } else {
          showMsg("Wrong Password");
        }
      } else {
        showMsg("User Not Found");
      }
    } catch (e) {
      showMsg("Error: $e");
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    userIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    // Responsive width
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
              Color(0xff667eea),
              Color(0xff764ba2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            /// REGISTER BUTTON
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.person_add, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminRegister(),
                    ),
                  );
                },
              ),
            ),

            /// MAIN UI
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: containerWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter:
                        ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: EdgeInsets.all(width < 600 ? 20 : 30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.admin_panel_settings,
                                size: 70,
                                color: Colors.white,
                              ),

                              const SizedBox(height: 15),

                              const Text(
                                "Admin Login",
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 30),

                              /// USER ID
                              TextField(
                                controller: userIdController,
                                style:
                                const TextStyle(color: Colors.white),
                                decoration: inputDecoration(
                                    "Enter User ID", Icons.person),
                              ),

                              const SizedBox(height: 20),

                              /// PASSWORD
                              TextField(
                                controller: passwordController,
                                obscureText: isPasswordHidden,
                                style:
                                const TextStyle(color: Colors.white),
                                decoration: inputDecoration(
                                  "Enter Password",
                                  Icons.lock,
                                  suffix: IconButton(
                                    icon: Icon(
                                      isPasswordHidden
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isPasswordHidden =
                                        !isPasswordHidden;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 35),

                              /// LOGIN BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor:
                                    Colors.green.shade800,
                                    elevation: 10,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed:
                                  isLoading ? null : loginAdmin,
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                      color: Colors.green)
                                      : const Text(
                                    "Login as Admin",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight:
                                        FontWeight.bold),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              const Text(
                                "Authorized Admin Access Only",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13),
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

  /// COMMON INPUT DECORATION (Cleaner Code)
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
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }
}