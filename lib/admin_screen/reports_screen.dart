import 'package:flutter/material.dart';

import 'Report/fees_collection_tab.dart';
import 'Report/pending_dues_tab.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 👈 back jayega
          },
        ),

        title: const Text(
          "Reports",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// HEADER SECTION (Same as Image)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Reports",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "View fees collection and pending dues reports",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// TAB BAR (Styled Like Screenshot)
          TabBar(
            controller: tabController,
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600),

            tabs: const [
              Tab(text: "Fees Collection"),
              Tab(text: "Pending Dues"),
            ],
          ),

          /// Divider Line
          const Divider(height: 1),

          /// TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: const [
                FeesCollectionTab(),
                PendingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}