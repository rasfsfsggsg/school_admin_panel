import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  final TextEditingController searchController = TextEditingController();

  bool searchByName = true;
  String searchText = "";

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// 🔥 FETCH PAYMENTS + STUDENT DATA
  Future<List<Map<String, dynamic>>> fetchPayments() async {
    QuerySnapshot paymentSnap = await firestore
        .collection("fee_payments")
        .orderBy("updatedAt", descending: true)
        .get();

    List<Map<String, dynamic>> finalData = [];

    for (var doc in paymentSnap.docs) {
      var data = doc.data() as Map<String, dynamic>;

      String studentId = data["studentId"] ?? "";

      /// 🔥 FETCH STUDENT DETAILS
      DocumentSnapshot studentSnap =
      await firestore.collection("students").doc(studentId).get();

      Map<String, dynamic> studentData =
          studentSnap.data() as Map<String, dynamic>? ?? {};

      double paid = (data["amountPaid"] ?? 0).toDouble();
      double total = (data["totalAmount"] ?? 0).toDouble();

      finalData.add({
        "docId": doc.id,
        "amountPaid": paid,
        "totalAmount": total,
        "remaining": total - paid,
        "updatedAt": data["updatedAt"],

        /// STUDENT DATA
        "name": studentData["firstName"] ?? "-",
        "lastName": studentData["lastName"] ?? "",
        "class": studentData["class"] ?? "-",
        "phone": studentData["phone"] ?? "-",
        "enrollment": studentData["enrollmentNumber"] ?? "-",
      });
    }

    return finalData;
  }

  /// 📅 TODAY CHECK
  bool isToday(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();

    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  /// 🔥 DETAILS POPUP (UPDATED UI)
  void showDetailsDialog(Map<String, dynamic> data) {
    Timestamp? time = data["updatedAt"];

    String date = time != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(time.toDate())
        : "-";

    double paid = data["amountPaid"] ?? 0;
    double total = data["totalAmount"] ?? 0;
    double remaining = data["remaining"] ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Payment Details",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),

                detailRow("Name", "${data["name"]} ${data["lastName"]}"),
                detailRow("Class", data["class"]),
                detailRow("Enrollment", data["enrollment"]),
                detailRow("Mobile", data["phone"]),

                const SizedBox(height: 10),

                /// 💰 NEW ATTRACTIVE BOX
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      amountRow("Total", total, Colors.black),
                      amountRow("Paid", paid, Colors.green),
                      amountRow("Remaining", remaining, Colors.red),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                detailRow("Date", date),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text("Close"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  /// 💰 AMOUNT ROW (NEW)
  Widget amountRow(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value?.toString() ?? "-",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 🎨 CARD UI (UNCHANGED)
  Widget paymentCard(Map<String, dynamic> data) {
    String name = "${data["name"]} ${data["lastName"]}";
    String enrollment = data["enrollment"];
    double amount = (data["amountPaid"] ?? 0).toDouble();

    Timestamp? time = data["updatedAt"];

    String date = time != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(time.toDate())
        : "-";

    bool today = time != null && isToday(time);

    return GestureDetector(
      onTap: () => showDetailsDialog(data),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade700],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                if (today)
                  const Chip(
                    label: Text("TODAY"),
                    backgroundColor: Colors.green,
                  )
              ],
            ),

            const SizedBox(height: 5),

            Text("Enrollment: $enrollment",
                style: const TextStyle(color: Colors.white70)),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date,
                    style: const TextStyle(color: Colors.white70)),
                Text("₹$amount",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔍 SEARCH UI (UNCHANGED)
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5)
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => searchByName = true),
                      child: toggleBox("By Name", searchByName),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => searchByName = false),
                      child: toggleBox("By Enrollment", !searchByName),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onChanged: (val) {
                  setState(() {
                    searchText = val.toLowerCase();
                  });
                },
              ),
            ],
          ),
        ),

        /// 📄 LIST
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchPayments(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              List data = snapshot.data!;

              data = data.where((item) {
                String name =
                "${item["name"]} ${item["lastName"]}".toLowerCase();
                String enroll =
                item["enrollment"].toString().toLowerCase();

                if (searchText.isEmpty) return true;

                return searchByName
                    ? name.contains(searchText)
                    : enroll.contains(searchText);
              }).toList();

              if (data.isEmpty) {
                return const Center(child: Text("No Data Found"));
              }

              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  return paymentCard(data[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget toggleBox(String text, bool active) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
              color: active ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}