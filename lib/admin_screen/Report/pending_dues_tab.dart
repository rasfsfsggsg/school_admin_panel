import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingTab extends StatefulWidget {
  const PendingTab({super.key});

  @override
  State<PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends State<PendingTab> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  TextEditingController searchController = TextEditingController();

  List<QueryDocumentSnapshot> students = [];
  List<QueryDocumentSnapshot> filteredStudents = [];

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  /// 🔥 FETCH STUDENTS
  Future<void> fetchStudents() async {
    QuerySnapshot snapshot =
    await firestore.collection("students").get();

    setState(() {
      students = snapshot.docs;
      filteredStudents = students;
    });
  }

  /// 🔍 SEARCH
  void searchStudent(String text) {
    text = text.toLowerCase();

    final results = students.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final name =
      "${data['firstName']} ${data['lastName']}".toLowerCase();

      final enrollment =
      data['enrollmentNumber'].toString().toLowerCase();

      return name.contains(text) || enrollment.contains(text);
    }).toList();

    setState(() {
      filteredStudents = results;
    });
  }

  /// 🎯 GET FEE DATA
  Future<Map<String, double>> getFeeData(
      QueryDocumentSnapshot studentDoc) async {
    final student = studentDoc.data() as Map<String, dynamic>;
    String studentClass = student["class"].toString();

    QuerySnapshot feeSnap = await firestore
        .collection("fee_structures")
        .where("class", isEqualTo: studentClass)
        .get();

    double total = 0;
    for (var doc in feeSnap.docs) {
      total += (doc["amount"] ?? 0);
    }

    QuerySnapshot paySnap = await firestore
        .collection("fee_payments")
        .where("studentId", isEqualTo: studentDoc.id)
        .get();

    double paid = 0;
    for (var doc in paySnap.docs) {
      paid += (doc["amountPaid"] ?? 0);
    }

    return {
      "total": total,
      "paid": paid,
      "pending": total - paid
    };
  }

  /// 📱 WHATSAPP
  Future<void> sendWhatsApp(String phone, String message) async {
    String formattedPhone = phone.replaceAll("+", "").trim();

    final url =
        "https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    }
  }

  /// 💾 SAVE REMINDER (🔥 FINAL FIXED)
  Future<void> saveReminder({
    required String studentId,
    required Map<String, dynamic> student,
    required String message,
    required String dueDate,
    required double pendingAmount,
  }) async {
    Map<String, dynamic> data = {
      "studentId": studentId,

      /// 🔥 IMPORTANT (for FeeStatus fetch)
      "studentName":
      "${student['firstName']} ${student['lastName']}",
      "enrollmentNumber": student['enrollmentNumber'],
      "class": student['class'],

      "message": message,
      "dueDate": dueDate,
      "pendingAmount": pendingAmount,
      "timestamp": FieldValue.serverTimestamp(),
    };

    /// Global collection
    await firestore.collection("reminders").add(data);

    /// Student-wise collection
    await firestore
        .collection("students")
        .doc(studentId)
        .collection("reminders")
        .add(data);
  }

  /// 🔔 POPUP
  void showDetailsPopup(
      QueryDocumentSnapshot studentDoc,
      Map<String, double> feeData) {
    final student = studentDoc.data() as Map<String, dynamic>;
    String phone = student["phone"] ?? "";

    TextEditingController messageController =
    TextEditingController(
      text:
      "Dear ${student['firstName']}, your pending fee is ₹${feeData['pending']}. Please pay before the due date.",
    );

    TextEditingController dueDateController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
          title: const Text("Student Details & Reminder"),

          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                    "Name: ${student['firstName']} ${student['lastName']}"),
                Text("Class: ${student['class']}"),
                Text("Enrollment: ${student['enrollmentNumber']}"),
                Text("Phone: $phone"),

                const SizedBox(height: 10),

                Text("Total Fee: ₹${feeData['total']}"),
                Text("Paid: ₹${feeData['paid']}"),
                Text(
                  "Pending: ₹${feeData['pending']}",
                  style: const TextStyle(color: Colors.red),
                ),

                const SizedBox(height: 10),

                /// 📅 DATE PICKER
                TextField(
                  controller: dueDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: "Due Date",
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    DateTime? pickedDate =
                    await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365 * 5)),
                    );

                    if (pickedDate != null) {
                      dueDateController.text =
                      "${pickedDate.day}-${pickedDate.month}-${pickedDate.year}";
                    }
                  },
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: "Message",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green),
              onPressed: () async {

                if (dueDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Select Due Date")),
                  );
                  return;
                }

                String finalMessage =
                    "${messageController.text}\nDue Date: ${dueDateController.text}\nPending: ₹${feeData['pending']}";

                /// WhatsApp
                await sendWhatsApp(phone, finalMessage);

                /// Firestore save (🔥 fixed)
                await saveReminder(
                  studentId: studentDoc.id,
                  student: student,
                  message: finalMessage,
                  dueDate: dueDateController.text,
                  pendingAmount: feeData['pending']!,
                );

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                      Text("Reminder Sent & Saved ✅")),
                );
              },
              icon: const Icon(Icons.send),
              label: const Text("Send & Save"),
            ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
  }

  /// 🎨 CARD
  Widget studentCard(QueryDocumentSnapshot studentDoc) {
    final student = studentDoc.data() as Map<String, dynamic>;

    return FutureBuilder<Map<String, double>>(
      future: getFeeData(studentDoc),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        double pending = snapshot.data!["pending"]!;

        if (pending <= 0) return const SizedBox();

        return GestureDetector(
          onTap: () {
            showDetailsPopup(studentDoc, snapshot.data!);
          },
          child: Container(
            margin:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffFF6B6B), Color(0xffFF3D3D)],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(student['firstName'][0]),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${student['firstName']} ${student['lastName']}",
                        style:
                        const TextStyle(color: Colors.white),
                      ),
                      Text(
                        "Pending: ₹$pending",
                        style:
                        const TextStyle(color: Colors.yellow),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// UI
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: "Search student...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            onChanged: searchStudent,
          ),
        ),

        Expanded(
          child: ListView.builder(
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              return studentCard(filteredStudents[index]);
            },
          ),
        )
      ],
    );
  }
}