import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String search = "";
  String? editId;

  // ADD / EDIT FORM
  void openStaffForm({String? id,String? name,String? mobile,String? password}){

    if(id != null){
      editId = id;
      nameController.text = name!;
      mobileController.text = mobile!;
      passwordController.text = password!;
    }else{
      editId = null;
      nameController.clear();
      mobileController.clear();
      passwordController.clear();
    }

    showDialog(
        context: context,
        builder: (context){

          return AlertDialog(

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),

            title: Text(editId == null ? "Add Staff" : "Edit Staff"),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Staff Name",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                ),

              ],
            ),

            actions: [

              TextButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                onPressed: saveStaff,
                child: const Text("Save"),
              )

            ],
          );
        }
    );
  }

  // SAVE STAFF
  Future<void> saveStaff() async{

    String name = nameController.text.trim();
    String mobile = mobileController.text.trim();
    String password = passwordController.text.trim();

    if(name.isEmpty || mobile.isEmpty || password.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all fields"))
      );
      return;
    }

    if(editId == null){

      await firestore.collection("staff").add({
        "name": name,
        "mobile": mobile,
        "password": password,
        "time": DateTime.now()
      });

    }else{

      await firestore.collection("staff").doc(editId).update({
        "name": name,
        "mobile": mobile,
        "password": password
      });

    }

    Navigator.pop(context);
  }

  // DELETE STAFF
  Future<void> deleteStaff(String id) async{
    await firestore.collection("staff").doc(id).delete();
  }

  Widget statusBadge(bool active){

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? "Active" : "Inactive",
        style: TextStyle(
            color: active ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey.shade200,

      appBar: AppBar(
        title: const Text("Staff Management"),
        backgroundColor: Colors.blue,
      ),

      body: Column(

        children: [

          const SizedBox(height: 10),

          // HEADER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [

                Text(
                  "Staff Management",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  "Manage staff accounts",
                  style: TextStyle(color: Colors.grey),
                )

              ],
            ),
          ),

          const SizedBox(height: 15),

          // SEARCH + ADD BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search staff...",
                      filled: true,
                      fillColor: Colors.grey.shade300,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value){
                      setState(() {
                        search = value.toLowerCase();
                      });
                    },
                  ),
                ),

                const SizedBox(width: 10),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20,vertical: 15
                    ),
                  ),
                  onPressed: (){
                    openStaffForm();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add Staff"),
                )

              ],
            ),
          ),

          const SizedBox(height: 10),

          // STAFF LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(

              stream: firestore.collection("staff")
                  .orderBy("time",descending: true)
                  .snapshots(),

              builder: (context,snapshot){

                if(!snapshot.hasData){
                  return const Center(child: CircularProgressIndicator());
                }

                var staff = snapshot.data!.docs;

                var filtered = staff.where((e){
                  return e["name"].toLowerCase().contains(search);
                }).toList();

                return ListView.builder(

                  padding: const EdgeInsets.all(15),

                  itemCount: filtered.length,

                  itemBuilder: (context,index){

                    var data = filtered[index];

                    return Container(

                      margin: const EdgeInsets.only(bottom: 15),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 5,
                          )
                        ],
                      ),

                      padding: const EdgeInsets.all(15),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Row(

                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [

                              Text(
                                data["name"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold
                                ),
                              ),

                              statusBadge(true)

                            ],
                          ),

                          const SizedBox(height: 8),

                          Text("Mobile: ${data["mobile"]}"),
                          Text("Password: ${data["password"]}"),

                          const SizedBox(height: 15),

                          Row(

                            children: [

                              Expanded(

                                child: ElevatedButton(

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),

                                  onPressed: (){
                                    openStaffForm(
                                        id: data.id,
                                        name: data["name"],
                                        mobile: data["mobile"],
                                        password: data["password"]
                                    );
                                  },

                                  child: const Text("Edit"),

                                ),

                              ),

                              const SizedBox(width: 10),

                              Expanded(

                                child: ElevatedButton(

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),

                                  onPressed: (){
                                    deleteStaff(data.id);
                                  },

                                  child: const Text("Remove"),

                                ),

                              )

                            ],

                          )

                        ],

                      ),

                    );

                  },
                );
              },
            ),
          )

        ],
      ),
    );
  }
}