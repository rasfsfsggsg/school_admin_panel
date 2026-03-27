import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../admin_login.dart';

import 'student_management_screen.dart';
import 'teacher_management_screen.dart';
import 'staff_management_screen.dart';
import 'fees_management_screen.dart';
import 'notice_screen.dart';
import 'reports_screen.dart';
import 'admission_form_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  /// ================= FETCH TOTAL FEES =================
  Stream<Map<String, double>> getFeesData() async* {
    await for (var snapshot in FirebaseFirestore.instance
        .collection('fee_payments')
        .snapshots()) {
      double totalCollected = 0;
      double totalPending = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data();

        double paid = (data["amountPaid"] ?? 0).toDouble();
        double total = (data["totalAmount"] ?? 0).toDouble();

        totalCollected += paid;
        totalPending += (total - paid);
      }

      yield {
        "collected": totalCollected,
        "pending": totalPending,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    bool isDesktop = width > 1000;
    bool isTablet = width > 600 && width <= 1000;

    int gridCount = isDesktop
        ? 4
        : isTablet
        ? 2
        : 1;

    return Scaffold(
      backgroundColor: Colors.grey.shade200,

      body: Row(
        children: [
          /// 🖥️ SIDEBAR (DESKTOP ONLY)
          if (isDesktop)
            Container(
              width: 220,
              color: const Color(0xffa18cd1),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Text("Admin Panel",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),

                  _sideItem(Icons.school, "Students", context,
                      const StudentManagementScreen()),
                  _sideItem(Icons.credit_card, "Fees", context,
                      const FeesManagementScreen()),
                  _sideItem(Icons.group, "Staff", context,
                      const StaffManagementScreen()),
                  _sideItem(Icons.person, "Teachers", context,
                      const TeacherManagementScreen()),
                  _sideItem(Icons.campaign, "Notices", context,
                      const NoticeScreen()),
                  _sideItem(Icons.bar_chart, "Reports", context,
                      const ReportsScreen()),
                ],
              ),
            ),

          /// MAIN CONTENT
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      /// HEADER
                      Container(
                        width: double.infinity,
                        padding:
                        const EdgeInsets.fromLTRB(20, 50, 20, 30),
                        decoration: const BoxDecoration(
                          color: Color(0xffa18cd1),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: const [
                            Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text("Welcome,",
                                    style: TextStyle(
                                        color: Colors.white)),
                                SizedBox(height: 5),
                                Text("Admin",
                                    style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Text("Administrator",
                                    style: TextStyle(
                                        color: Colors.white70)),
                              ],
                            ),
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              child: Text("A"),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 📊 STATS GRID
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: StreamBuilder<Map<String, double>>(
                          stream: getFeesData(),
                          builder: (context, feeSnapshot) {

                            double collected = feeSnapshot.data?["collected"] ?? 0;
                            double pending = feeSnapshot.data?["pending"] ?? 0;

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('students')
                                  .snapshots(),
                              builder: (context, studentSnapshot) {

                                int totalStudents =
                                studentSnapshot.hasData ? studentSnapshot.data!.docs.length : 0;

                                return LayoutBuilder(
                                  builder: (context, constraints) {

                                    int crossAxisCount;

                                    if (constraints.maxWidth > 1000) {
                                      crossAxisCount = 3; // Desktop
                                    } else if (constraints.maxWidth > 600) {
                                      crossAxisCount = 2; // Tablet
                                    } else {
                                      crossAxisCount = 1; // Mobile
                                    }

                                    return GridView.count(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.3, // 🔥 SAME SIZE CONTROL
                                      children: [

                                        /// STUDENTS
                                        _statCard(
                                          Icons.people,
                                          totalStudents.toString(),
                                          "Students",
                                        ),

                                        /// FEES COLLECTED
                                        _statCard(
                                          Icons.attach_money,
                                          "₹${collected.toStringAsFixed(0)}",
                                          "Fees Collected",
                                        ),

                                        /// PENDING FEES
                                        _statCard(
                                          Icons.hourglass_bottom,
                                          "₹${pending.toStringAsFixed(0)}",
                                          "Pending Fees",
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),

                      /// FEATURES
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 15,
                          runSpacing: 15,
                          children: [
                            _featureCard(context, Icons.school,
                                "Students", const StudentManagementScreen()),
                            _featureCard(context, Icons.description,
                                "Admission", const AdmissionFormScreen()),
                            _featureCard(context, Icons.credit_card,
                                "Fees", const FeesManagementScreen()),
                            _featureCard(context, Icons.group,
                                "Staff", const StaffManagementScreen()),
                            _featureCard(context, Icons.person,
                                "Teachers", const TeacherManagementScreen()),
                            _featureCard(context, Icons.campaign,
                                "Notices", const NoticeScreen()),
                            _featureCard(context, Icons.bar_chart,
                                "Reports", const ReportsScreen()),
                          ],
                        ),
                      ),

                      /// LOGOUT
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize:
                            const Size(double.infinity, 55),
                            backgroundColor: Colors.white,
                            side:
                            const BorderSide(color: Colors.red),
                          ),
                          icon: const Icon(Icons.logout,
                              color: Colors.red),
                          label: const Text("Logout",
                              style: TextStyle(color: Colors.red)),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const AdminLogin()),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SIDEBAR ITEM
  Widget _sideItem(IconData icon, String title,
      BuildContext context, Widget screen) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title,
          style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  /// STAT CARD
  static Widget _statCard(
      IconData icon, String value, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.blue),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(title),
        ],
      ),
    );
  }

  /// FEATURE CARD
  Widget _featureCard(BuildContext context, IconData icon,
      String title, Widget screen) {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 10),
            Text(title,
                style:
                const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}