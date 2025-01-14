// retrieve interpreter data 
import 'package:admin/models/interpreters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  

Future<List<Interpreter>> fetchInterpreters() async {  
  CollectionReference interpretersCollection = FirebaseFirestore.instance.collection('users');  
  
  // Fetch only interpreters with the role "interpreter"  
  QuerySnapshot querySnapshot = await interpretersCollection  
      .where('role', isEqualTo: 'interpreter') // Filter by role  
      .get();  

  List<Interpreter> interpreters = querySnapshot.docs.map((doc) {  
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;  
    return Interpreter(  
      name: data['name'],  
      email: data['email'],  
      district: data['district'],  
      currentEmployer: data['current_employer'],  
      contact: data['contact'],  
      yearsOfExperience: data['years_of_experience'],  
      role: data['role'],  
    );  
  }).toList();  

  return interpreters;  
}