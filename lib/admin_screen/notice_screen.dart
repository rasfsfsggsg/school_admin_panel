import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final groupLinkController = TextEditingController();
  final searchController = TextEditingController();

  String selectedAudience = "Teachers";
  String noticeType = "School Notice";

  // Teacher Fields
  String teacherCategory = "Single Teacher";
  String? selectedTeacherId;
  String selectedTeacherName = "";
  String selectedTeacherMobile = "";

  // Student Fields
  String studentCategory = "Single Student";
  String? selectedStudentId;
  String selectedStudentName = "";
  String selectedStudentMobile = "";

  /// SEND WHATSAPP TO SINGLE NUMBER
  Future<void> sendWhatsApp(String phone, String message) async {
    final Uri url =
    Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// OPEN GROUP LINK
  Future<void> openGroup(String link) async {
    final Uri url = Uri.parse(link);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// SEND MESSAGE TO ANY NUMBER (NO GROUP)
  Future<void> sendGroupMessage(String message) async {
    final Uri url =
    Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// CREATE NOTICE
  void createNotice() async {
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Enter title and content")));
      return;
    }

    String message =
        "*${titleController.text}*\n\n${contentController.text}";



    /// TEACHERS
    if (selectedAudience == "Teachers") {
      // Single Teacher
      if (teacherCategory == "Single Teacher") {
        if (selectedTeacherId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Select a Teacher")));
          return;
        }

        await sendWhatsApp(selectedTeacherMobile, message);

        await firestore.collection("notices").add({
          "title": titleController.text,
          "content": contentController.text,
          "noticeType": noticeType,
          "audience": "Teachers",
          "category": "single_teacher",
          "teacherName": selectedTeacherName,
          "teacherMobile": selectedTeacherMobile,
          "date": DateTime.now(),
        });
      }

      // All Teachers
      else if (teacherCategory == "All Teachers") {
        await firestore.collection("notices").add({
          "title": titleController.text,
          "content": contentController.text,
          "noticeType": noticeType,
          "audience": "Teachers",
          "category": "all_teachers",
          "groupLink": groupLinkController.text,
          "date": DateTime.now(),
        });

        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Notice copied! Open WhatsApp group and paste to send.")));

        if (groupLinkController.text.isNotEmpty) {
          await openGroup(groupLinkController.text);
        } else {
          await sendGroupMessage(message);
        }
      }
    }

    /// ALL (Teacher + Student)
    else if (selectedAudience == "All") {

      await firestore.collection("notices").add({
        "title": titleController.text,
        "content": contentController.text,
        "noticeType": noticeType,
        "audience": "All",
        "category": "all",
        "groupLink": groupLinkController.text,
        "date": DateTime.now(),
      });

      await Clipboard.setData(ClipboardData(text: message));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Notice copied! WhatsApp group open ho raha hai."
          ),
        ),
      );

      if (groupLinkController.text.isNotEmpty) {
        await openGroup(groupLinkController.text);
      } else {
        await sendGroupMessage(message);
      }
    }

    /// STUDENTS
    else if (selectedAudience == "Students") {
      // Single Student
      if (studentCategory == "Single Student") {
        if (selectedStudentId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Select a Student")));
          return;
        }

        await sendWhatsApp(selectedStudentMobile, message);

        await firestore.collection("notices").add({
          "title": titleController.text,
          "content": contentController.text,
          "audience": "Students",
          "noticeType": noticeType,
          "category": "single_student",
          "studentName": selectedStudentName,
          "studentMobile": selectedStudentMobile,
          "date": DateTime.now(),
        });
      }

      // All Students
      else if (studentCategory == "All Students") {
        await firestore.collection("notices").add({
          "title": titleController.text,
          "content": contentController.text,
          "audience": "Students",
          "category": "all_students",
          "noticeType": noticeType,
          "groupLink": groupLinkController.text,
          "date": DateTime.now(),
        });

        await Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Notice copied! Open WhatsApp group and paste to send.")));

        if (groupLinkController.text.isNotEmpty) {
          await openGroup(groupLinkController.text);
        } else {
          await sendGroupMessage(message);
        }
      }
    }

    // CLEAR ALL FIELDS
    titleController.clear();
    contentController.clear();
    groupLinkController.clear();
    selectedTeacherId = null;
    selectedTeacherName = "";
    selectedTeacherMobile = "";
    selectedStudentId = null;
    selectedStudentName = "";
    selectedStudentMobile = "";
  }

  /// SEARCHABLE TEACHER DIALOG
  void openTeacherSearch() async {
    var snapshot = await firestore.collection("teachers").get();
    List<QueryDocumentSnapshot> teachers = snapshot.docs;

    showDialog(
      context: context,
      builder: (context) {
        List<QueryDocumentSnapshot> filteredTeachers = teachers;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Teacher"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search teacher...",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        filteredTeachers = teachers.where((doc) {
                          var data = doc.data() as Map;
                          String name = data["name"].toLowerCase();
                          String mobile = data["mobile"];
                          return name.contains(value.toLowerCase()) ||
                              mobile.contains(value);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: ListView.builder(
                      itemCount: filteredTeachers.length,
                      itemBuilder: (context, index) {
                        var doc = filteredTeachers[index];
                        var data = doc.data() as Map;
                        return ListTile(
                          title: Text(data["name"]),
                          subtitle: Text(data["mobile"]),
                          onTap: () {
                            setState(() {
                              selectedTeacherId = doc.id;
                              selectedTeacherName = data["name"];
                              selectedTeacherMobile = data["mobile"];
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// SEARCHABLE STUDENT DIALOG
  void openStudentSearch() async {
    var snapshot = await firestore.collection("students").get();
    List<QueryDocumentSnapshot> students = snapshot.docs;

    showDialog(
      context: context,
      builder: (context) {
        List<QueryDocumentSnapshot> filteredStudents = students;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Select Student"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: "Search student...",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setStateDialog(() {
                        filteredStudents = students.where((doc) {
                          var data = doc.data() as Map;
                          String name =
                          "${data["firstName"] ?? ""} ${data["lastName"] ?? ""}".toLowerCase();
                          String phone = data["phone"] ?? "";
                          return name.contains(value.toLowerCase()) ||
                              phone.contains(value);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        var doc = filteredStudents[index];
                        var data = doc.data() as Map;
                        return ListTile(
                          title: Text("${data["firstName"]} ${data["lastName"]}"),
                          subtitle: Text(data["phone"] ?? ""),
                          onTap: () {
                            setState(() {
                              selectedStudentId = doc.id;
                              selectedStudentName =
                              "${data["firstName"]} ${data["lastName"]}";
                              selectedStudentMobile = data["phone"] ?? "";
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// AUDIENCE BUTTON
  Widget audienceButton(String title) {
    bool selected = selectedAudience == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedAudience = title;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.amber : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Notices Management"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            "Create Notice",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // TITLE
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: "Notice Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          DropdownButtonFormField(
            value: noticeType,
            decoration: const InputDecoration(
              labelText: "Notice Type",
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: "School Notice",
                child: Text("School Notice"),
              ),
              DropdownMenuItem(
                value: "Exam Notice",
                child: Text("Exam Notice"),
              ),
            ],
            onChanged: (value) {
              setState(() {
                noticeType = value!;
              });
            },
          ),
          const SizedBox(height: 10),
          // CONTENT
          TextField(
            controller: contentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: "Notice Content",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Target Audience"),
          const SizedBox(height: 10),
          Row(
            children: [
              audienceButton("Teachers"),
              audienceButton("Students"),
              audienceButton("All"),

            ],
          ),
          const SizedBox(height: 20),

          /// CATEGORY DROPDOWN
          if (selectedAudience == "Teachers")
            DropdownButtonFormField(
              value: teacherCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: "Single Teacher", child: Text("Single Teacher")),
                DropdownMenuItem(
                    value: "All Teachers", child: Text("All Teachers")),
              ],
              onChanged: (value) {
                setState(() {
                  teacherCategory = value!;
                });
              },
            ),
          if (selectedAudience == "Students")
            DropdownButtonFormField(
              value: studentCategory,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: "Single Student", child: Text("Single Student")),
                DropdownMenuItem(
                    value: "All Students", child: Text("All Students")),
              ],
              onChanged: (value) {
                setState(() {
                  studentCategory = value!;
                });
              },
            ),
          const SizedBox(height: 20),

          /// SINGLE SELECT
          if (selectedAudience == "Teachers" &&
              teacherCategory == "Single Teacher")
            GestureDetector(
              onTap: openTeacherSearch,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    selectedTeacherName.isEmpty
                        ? const Text("Select Teacher")
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedTeacherName),
                        Text(selectedTeacherMobile,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down)
                  ],
                ),
              ),
            ),
          if (selectedAudience == "Students" &&
              studentCategory == "Single Student")
            GestureDetector(
              onTap: openStudentSearch,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    selectedStudentName.isEmpty
                        ? const Text("Select Student")
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedStudentName),
                        Text(selectedStudentMobile,
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Icon(Icons.arrow_drop_down)
                  ],
                ),
              ),
            ),

          /// GROUP LINK
          if ((selectedAudience == "Teachers" &&
              teacherCategory == "All Teachers") ||
              (selectedAudience == "Students" &&
                  studentCategory == "All Students") ||
              (selectedAudience == "All"))
            TextField(
              controller: groupLinkController,
              decoration: const InputDecoration(
                labelText: "WhatsApp Group Link (optional)",
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 30),

          /// CREATE BUTTON
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: createNotice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              child: const Text(
                "Create Notice",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}