import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeeStructuresTab extends StatefulWidget {
  const FeeStructuresTab({super.key});

  @override
  State<FeeStructuresTab> createState() => _FeeStructuresTabState();
}

class _FeeStructuresTabState extends State<FeeStructuresTab> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String selectedClass = "1"; // Default selected class
  Map<String, DocumentSnapshot> classData = {}; // To store fetched class data

  /// ================= OPEN FORM =================
  void openForm({DocumentSnapshot? doc}) {
    String paymentType = doc?["type"] ?? "FULL";
    String feeCategory = doc?["category"] ?? "ACADEMIC FEES";

    TextEditingController amountController =
    TextEditingController(text: doc?["amount"]?.toString() ?? "");
    TextEditingController monthsController =
    TextEditingController(text: doc?["months"]?.toString() ?? "");
    double monthlyAmount = doc?["monthly"]?.toDouble() ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            void calculate() {
              double amount = double.tryParse(amountController.text) ?? 0;
              int months = 0;

              if (paymentType == "FULL") {
                months = 10;
              } else if (paymentType == "PARTIAL") {
                months = 5;
              } else {
                months = int.tryParse(monthsController.text) ?? 0;
              }

              monthlyAmount = months > 0 ? amount / months : 0;
              setStateSheet(() {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TITLE
                    Center(
                      child: Text(
                        doc == null
                            ? "Create Fee Structure"
                            : "Edit Fee Structure",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// CLASS
                    DropdownButtonFormField(
                      value: selectedClass,
                      decoration: const InputDecoration(
                        labelText: "Select Class",
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        12,
                            (index) => DropdownMenuItem(
                          value: "${index + 1}",
                          child: Text("Class ${index + 1}"),
                        ),
                      ),
                      onChanged: (value) async {
                        selectedClass = value!;
                        // Fetch existing class data if any
                        var snapshot = await firestore
                            .collection("fee_structures")
                            .where("class", isEqualTo: selectedClass)
                            .limit(1)
                            .get();
                        if (snapshot.docs.isNotEmpty) {
                          doc = snapshot.docs.first;
                          amountController.text =
                              doc!["amount"]?.toString() ?? "";
                          monthsController.text =
                              doc!["months"]?.toString() ?? "";
                          feeCategory = doc!["category"] ?? "ACADEMIC FEES";
                          paymentType = doc!["type"] ?? "FULL";
                        } else {
                          doc = null;
                          amountController.clear();
                          monthsController.clear();
                          feeCategory = "ACADEMIC FEES";
                          paymentType = "FULL";
                        }
                        calculate();
                        setStateSheet(() {});
                      },
                    ),

                    const SizedBox(height: 15),

                    /// CATEGORY
                    DropdownButtonFormField(
                      value: feeCategory,
                      decoration: const InputDecoration(
                        labelText: "Fee Type",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "ACADEMIC FEES",
                            child: Text("ACADEMIC FEES")),
                        DropdownMenuItem(
                            value: "MONTHLY FEES", child: Text("MONTHLY FEES")),
                        DropdownMenuItem(
                            value: "TRANSPORT FEES",
                            child: Text("TRANSPORT FEES")),
                        DropdownMenuItem(value: "OTHER", child: Text("OTHER")),
                      ],
                      onChanged: (value) {
                        feeCategory = value!;
                      },
                    ),

                    const SizedBox(height: 15),

                    /// PAYMENT TYPE
                    DropdownButtonFormField(
                      value: paymentType,
                      decoration: const InputDecoration(
                        labelText: "Payment Type",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "FULL", child: Text("Full Payment")),
                        DropdownMenuItem(
                            value: "PARTIAL", child: Text("Partial Payment")),
                        DropdownMenuItem(
                            value: "CUSTOM", child: Text("Custom Payment")),
                      ],
                      onChanged: (value) {
                        paymentType = value!;
                        calculate();
                      },
                    ),

                    const SizedBox(height: 15),

                    /// AMOUNT
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Total Amount ₹",
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => calculate(),
                    ),

                    const SizedBox(height: 15),

                    /// CUSTOM MONTHS
                    if (paymentType == "CUSTOM")
                      TextField(
                        controller: monthsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Enter Months",
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => calculate(),
                      ),

                    const SizedBox(height: 15),

                    /// RESULT
                    if (monthlyAmount > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Monthly Fee: ₹${monthlyAmount.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ),

                    const SizedBox(height: 20),

                    /// SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          double amount =
                              double.tryParse(amountController.text) ?? 0;
                          int months = 0;

                          if (paymentType == "FULL") {
                            months = 10;
                          } else if (paymentType == "PARTIAL") {
                            months = 5;
                          } else {
                            months =
                                int.tryParse(monthsController.text) ?? 0;
                          }

                          double monthly = months > 0 ? amount / months : 0;

                          Map<String, dynamic> data = {
                            "class": selectedClass,
                            "type": paymentType,
                            "category": feeCategory,
                            "amount": amount,
                            "monthly": monthly,
                            "months": months,
                            "createdAt": FieldValue.serverTimestamp(),
                          };

                          if (doc == null) {
                            await firestore
                                .collection("fee_structures")
                                .add(data);
                          } else {
                            await firestore
                                .collection("fee_structures")
                                .doc(doc?.id)
                                .update(data);
                          }

                          Navigator.pop(context);
                        },
                        child: const Text("Save Fee Structure"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ================= CARD =================
  Widget feeCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;

    Color statusColor = data["type"] == "FULL"
        ? Colors.green
        : data["type"] == "PARTIAL"
        ? Colors.orange
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Class ${data["class"]} Fee",
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Chip(
                label: Text(data["type"]),
                backgroundColor: statusColor.withOpacity(0.2),
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// CATEGORY
          Chip(
            label: Text(data["category"] ?? "N/A"),
            backgroundColor: Colors.blue.shade50,
          ),

          const SizedBox(height: 10),

          Text("Total Amount: ₹${data["amount"]}"),
          Text("Monthly Fee: ₹${data["monthly"].toStringAsFixed(0)}"),
          Text("Months: ${data["months"]}"),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => openForm(doc: doc),
                  child: const Text("Edit"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await firestore
                        .collection("fee_structures")
                        .doc(doc.id)
                        .delete();
                  },
                  child: const Text("Delete"),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// ================= MAIN UI =================
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestore
          .collection("fee_structures")
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => openForm(),
                child: const Text("+ Create Fee Structure"),
              ),
            ),
            const SizedBox(height: 20),
            ...docs.map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: feeCard(doc),
            ))
          ],
        );
      },
    );
  }
}