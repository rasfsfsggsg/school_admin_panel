import 'package:flutter/material.dart';
import 'feesmange/fee_structures_tab.dart';
import 'feesmange/payments_tab.dart';
import 'feesmange/pending_tab.dart';


class FeesManagementScreen extends StatelessWidget {
  const FeesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,

        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("Fees Management"),
        ),

        body: Column(
          children: [

            /// TITLE SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    "Fees Management",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Manage fee structures and track payments",
                    style: TextStyle(color: Colors.grey),
                  ),

                ],
              ),
            ),

            /// TAB BAR
            const TabBar(
              labelColor: Colors.blue,
              tabs: [
                Tab(text: "Fee Structures"),
                Tab(text: "Payments"),
                Tab(text: "Pending"),
              ],
            ),

            /// TAB VIEW
            const Expanded(
              child: TabBarView(
                children: [
                  FeeStructuresTab(),
                  PaymentsTab(),
                  PendingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}