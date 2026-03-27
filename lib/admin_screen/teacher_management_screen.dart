import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherManagementScreen extends StatefulWidget {
  const TeacherManagementScreen({super.key});

  @override
  State<TeacherManagementScreen> createState() =>
      _TeacherManagementScreenState();
}

class _TeacherManagementScreenState extends State<TeacherManagementScreen> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String? editId;

  /// SAVE TEACHER
  void saveTeacher() async {

    String name = nameController.text.trim();
    String mobile = mobileController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty || mobile.isEmpty || password.isEmpty) {
      return;
    }

    if (editId == null) {

      await firestore.collection("teachers").add({
        "name": name,
        "mobile": mobile,
        "password": password,
        "time": DateTime.now(),
      });

    } else {

      await firestore.collection("teachers").doc(editId).update({
        "name": name,
        "mobile": mobile,
        "password": password,
      });

      editId = null;
    }

    nameController.clear();
    mobileController.clear();
    passwordController.clear();

    Navigator.pop(context);
  }

  /// DELETE
  void deleteTeacher(String id) async {
    await firestore.collection("teachers").doc(id).delete();
  }

  /// EDIT
  void editTeacher(DocumentSnapshot doc) {

    var data = doc.data() as Map;

    nameController.text = data["name"];
    mobileController.text = data["mobile"];
    passwordController.text = data["password"];

    editId = doc.id;

    openForm();
  }

  /// FORM DIALOG
  void openForm() {

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(

          title: const Text("Add / Edit Teacher"),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Teacher Name",
                ),
              ),

              TextField(
                controller: mobileController,
                decoration: const InputDecoration(
                  labelText: "Mobile Number",
                ),
              ),

              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                ),
              ),
            ],
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: saveTeacher,
              child: const Text("Submit"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Teacher Management"),
        backgroundColor: const Color(0xff4A86CF),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Teacher Management",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            /// ADD BUTTON
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
              ),
              onPressed: () {
                editId = null;
                nameController.clear();
                mobileController.clear();
                passwordController.clear();
                openForm();
              },
              child: const Text("+ Add Teacher"),
            ),

            const SizedBox(height: 20),

            /// TEACHER LIST
            Expanded(
              child: StreamBuilder(
                stream: firestore.collection("teachers").snapshots(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  var teachers = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: teachers.length,
                    itemBuilder: (context, index) {

                      var doc = teachers[index];
                      var data = doc.data() as Map;

                      return teacherCard(
                        name: data["name"],
                        mobile: data["mobile"],
                        password: data["password"],
                        onEdit: () => editTeacher(doc),
                        onDelete: () => deleteTeacher(doc.id),
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

  /// CARD UI
  Widget teacherCard({
    required String name,
    required String mobile,
    required String password,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text("Mobile: $mobile"),
          Text("Password: $password"),

          const SizedBox(height: 16),

          Row(
            children: [

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4A86CF),
                  ),
                  onPressed: onEdit,
                  child: const Text("Edit"),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: onDelete,
                  child: const Text("Delete"),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}