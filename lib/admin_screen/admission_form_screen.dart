import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdmissionFormScreen extends StatefulWidget {
  const AdmissionFormScreen({super.key});

  @override
  State<AdmissionFormScreen> createState() =>
      _AdmissionFormScreenState();
}

class _AdmissionFormScreenState
    extends State<AdmissionFormScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController fieldController =
  TextEditingController();

  /// ADD FIELD
  void addField() async {
    if (fieldController.text.trim().isEmpty) return;

    await firestore.collection("form_fields").add({
      "name": fieldController.text.trim(),
      "type": "text",
      "required": false,
      "createdAt": FieldValue.serverTimestamp()
    });

    fieldController.clear();
  }

  /// DELETE FIELD
  void deleteField(String id) async {
    await firestore.collection("form_fields").doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    bool isMobile = width < 600;
    bool isTablet = width >= 600 && width < 1000;

    double containerWidth = isMobile
        ? width * 0.95
        : isTablet
        ? 700
        : 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Admission Form Management"),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: containerWidth),

          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// HEADER
                const Text(
                  "Form Fields",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// 🔷 ADD FIELD CARD
                Container(
                  padding: EdgeInsets.all(isMobile ? 15 : 20),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),

                  child: isMobile
                      ? Column(
                    children: [
                      TextField(
                        controller: fieldController,
                        decoration: inputDecoration(),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: addField,
                          style: buttonStyle(),
                          child:
                          const Text("Add Field"),
                        ),
                      ),
                    ],
                  )
                      : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fieldController,
                          decoration: inputDecoration(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: addField,
                        style: buttonStyle(),
                        child: const Text("Add Field"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// 🔷 FIELD LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection("form_fields")
                        .orderBy("createdAt", descending: true)
                        .snapshots(),

                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const Center(
                          child:
                          CircularProgressIndicator(),
                        );
                      }

                      final fields = snapshot.data!.docs;

                      if (fields.isEmpty) {
                        return const Center(
                          child: Text(
                            "No custom fields added",
                            style: TextStyle(
                                color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: fields.length,

                        itemBuilder: (context, index) {
                          final field = fields[index];

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 8,
                                )
                              ],
                            ),

                            child: ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12),

                              leading: Container(
                                padding:
                                const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(
                                      10),
                                ),
                                child: const Icon(
                                  Icons.text_fields,
                                  color: Colors.deepPurple,
                                ),
                              ),

                              title: Text(
                                field["name"],
                                style: const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),

                              subtitle: Row(
                                children: [
                                  const Text("Type: TEXT"),
                                  const SizedBox(width: 10),
                                  if (field["required"] ==
                                      true)
                                    const Text(
                                      "(Required)",
                                      style: TextStyle(
                                          color: Colors.red),
                                    ),
                                ],
                              ),

                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  deleteField(field.id);
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// INPUT STYLE
  InputDecoration inputDecoration() {
    return InputDecoration(
      hintText: "Enter new field name",
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 15),
    );
  }

  /// BUTTON STYLE
  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      padding: const EdgeInsets.symmetric(
          horizontal: 25, vertical: 18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}