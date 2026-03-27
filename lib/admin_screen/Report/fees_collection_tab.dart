import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class FeesCollectionTab extends StatefulWidget {
  const FeesCollectionTab({super.key});

  @override
  State<FeesCollectionTab> createState() => _FeesCollectionTabState();
}

class _FeesCollectionTabState extends State<FeesCollectionTab> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  double totalCollected = 0;
  double totalPending = 0;

  Map<String, Map<String, double>> classData = {};

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  /// ================= FETCH DATA =================
  Future<void> fetchReport() async {

    QuerySnapshot snapshot =
    await firestore.collection("fee_payments").get();

    double collected = 0;
    double pending = 0;

    Map<String, Map<String, double>> tempClassData = {};

    for (var doc in snapshot.docs) {

      var data = doc.data() as Map<String, dynamic>;

      String studentClass = data["class"].toString();

      double paid = (data["amountPaid"] ?? 0).toDouble();
      double total = (data["totalAmount"] ?? 0).toDouble();

      double remain = total - paid;

      collected += paid;
      pending += remain;

      if (!tempClassData.containsKey(studentClass)) {
        tempClassData[studentClass] = {
          "collected": 0,
          "pending": 0,
        };
      }

      tempClassData[studentClass]!["collected"] =
          tempClassData[studentClass]!["collected"]! + paid;

      tempClassData[studentClass]!["pending"] =
          tempClassData[studentClass]!["pending"]! + remain;
    }

    setState(() {
      totalCollected = collected;
      totalPending = pending;
      classData = tempClassData;
      loading = false;
    });
  }

  /// ================= PDF GENERATE + SHARE =================
  Future<void> generateAndSharePDF() async {

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [

          pw.Text(
            "Fees Collection Report - January 2026",
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 20),

          pw.Text("Total Collected: ₹${totalCollected.toStringAsFixed(0)}"),
          pw.Text("Total Pending: ₹${totalPending.toStringAsFixed(0)}"),

          pw.SizedBox(height: 20),

          pw.Text(
            "Class Breakdown",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Table(
            border: pw.TableBorder.all(),
            children: [

              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("Class",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("Collected",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text("Pending",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),

              ...classData.entries.map((entry) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(entry.key),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                          "₹${entry.value["collected"]!.toStringAsFixed(0)}"),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                          "₹${entry.value["pending"]!.toStringAsFixed(0)}"),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/fees_report.pdf");

    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "Fees Collection Report",
    );
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// SUMMARY CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Summary - January 2026",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Collected"),
                        Text(
                          "₹${totalCollected.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Total Pending"),
                        Text(
                          "₹${totalPending.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Breakdown by Class",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          /// CLASS DATA
          ...classData.entries.map((entry) {

            String className = entry.key;
            double collected = entry.value["collected"]!;
            double pending = entry.value["pending"]!;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Class $className",
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [

                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text("Collected"),
                          Text(
                            "₹${collected.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text("Pending"),
                          Text(
                            "₹${pending.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 20),

          /// EXPORT BUTTON
          GestureDetector(
            onTap: generateAndSharePDF,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.teal, Colors.green],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "📤 Export Report",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}