import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String search = "";

  /// SEND WHATSAPP MESSAGE
  Future<void> sendWhatsApp(String phone, String enrollment,
      String password) async {
    String message =
        "Welcome to School\n\nYour account has been approved.\n\nEnrollment Number: $enrollment\nPassword: $password";

    String url =
        "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  /// UPDATE STATUS
  void updateStatus(String id, Map<String, dynamic> data, String status) async {
    await firestore.collection("students").doc(id).update({
      "status": status
    });

    if (status == "accepted") {
      String phone = data["phone"] ?? "";
      String enrollment = data["enrollmentNumber"] ?? "";
      String password = data["password"] ?? "";

      sendWhatsApp(phone, enrollment, password);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Student $status")),
    );
  }

  /// DELETE
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(

          title: const Text("Delete Student"),

          content: const Text(
              "Are you sure you want to delete this student?"),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),

              onPressed: () async {
                await firestore
                    .collection("students")
                    .doc(id)
                    .delete();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Student deleted")),
                );
              },

              child: const Text("Delete"),
            )
          ],
        );
      },
    );
  }

  /// EDIT STUDENT FULL DETAILS
  void editStudent(String id, Map<String, dynamic> data) {
    TextEditingController firstName =
    TextEditingController(text: data["firstName"]);

    TextEditingController lastName =
    TextEditingController(text: data["lastName"]);

    TextEditingController classController =
    TextEditingController(text: data["class"]);

    TextEditingController phone =
    TextEditingController(text: data["phone"]);

    TextEditingController email =
    TextEditingController(text: data["email"]);

    TextEditingController address =
    TextEditingController(text: data["address"]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(

          title: const Text("Edit Student"),

          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: firstName,
                  decoration:
                  const InputDecoration(labelText: "First Name"),
                ),

                TextField(
                  controller: lastName,
                  decoration:
                  const InputDecoration(labelText: "Last Name"),
                ),

                TextField(
                  controller: classController,
                  decoration:
                  const InputDecoration(labelText: "Class"),
                ),

                TextField(
                  controller: phone,
                  decoration:
                  const InputDecoration(labelText: "Phone"),
                ),

                TextField(
                  controller: email,
                  decoration:
                  const InputDecoration(labelText: "Email"),
                ),

                TextField(
                  controller: address,
                  decoration:
                  const InputDecoration(labelText: "Address"),
                ),
              ],
            ),
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () async {
                await firestore.collection("students").doc(id).update({

                  "firstName": firstName.text,
                  "lastName": lastName.text,
                  "class": classController.text,
                  "phone": phone.text,
                  "email": email.text,
                  "address": address.text,
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Student Updated")),
                );
              },

              child: const Text("Update"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Management"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// SEARCH
            TextField(
              decoration: InputDecoration(
                hintText: "Search students...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),
            const SizedBox(height: 20),

            /// STUDENT LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore.collection("students").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var students = snapshot.data!.docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    String name =
                    "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}"
                        .toLowerCase();
                    return name.contains(search.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var student = students[index];
                      var data = student.data() as Map<String, dynamic>;
                      String id = student.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// STUDENT PHOTO
                              /// STUDENT PHOTO WITH FULLSCREEN ON TAP
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    if (data["photoUrl"] != null && data["photoUrl"] != "") {
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          child: InteractiveViewer(
                                            child: Image.network(
                                              data["photoUrl"],
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage: (data["photoUrl"] != null &&
                                        data["photoUrl"] != "")
                                        ? NetworkImage(data["photoUrl"])
                                        : null,
                                    child: (data["photoUrl"] == null || data["photoUrl"] == "")
                                        ? const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white,
                                    )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// STUDENT INFO
                              Text(
                                "${data["firstName"] ??
                                    ""} ${data["lastName"] ?? ""}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text("Father: ${data["fatherName"] ?? ""}"),
                              Text("Class: ${data["class"] ?? ""}"),
                              Text("Phone: ${data["phone"] ?? ""}"),
                              Text("Enrollment: ${data["enrollmentNumber"] ??
                                  ""}"),
                              const SizedBox(height: 10),

                              /// STATUS
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: data["status"] == "accepted"
                                      ? Colors.green
                                      : data["status"] == "rejected"
                                      ? Colors.red
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (data["status"] ?? "pending").toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// ACTION BUTTONS
                              Wrap(
                                spacing: 10,
                                children: [
                                  if (data["status"] == "pending")
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green),
                                      onPressed: () {
                                        updateStatus(id, data, "accepted");
                                      },
                                      child: const Text("Accept"),
                                    ),
                                  if (data["status"] == "pending")
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange),
                                      onPressed: () {
                                        updateStatus(id, data, "rejected");
                                      },
                                      child: const Text("Reject"),
                                    ),
                                  ElevatedButton(
                                    onPressed: () {
                                      editStudent(id, data);
                                    },
                                    child: const Text("Edit"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () {
                                      confirmDelete(id);
                                    },
                                    child: const Text("Delete"),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}