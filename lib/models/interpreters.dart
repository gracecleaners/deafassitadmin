class Interpreter {
  String? uid;
  String? name;
  String? email;
  String? district;
  String? currentEmployer;
  String? contact;
  String? yearsOfExperience;
  String? role;
  String? region; // New field

  Interpreter({
    this.uid,
    this.name,
    this.email,
    this.district,
    this.currentEmployer,
    this.contact,
    this.yearsOfExperience,
    this.role,
    this.region, // New field
  });

  Interpreter.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    district = json['district'];
    currentEmployer = json['currentEmployer'];
    contact = json['contact'];
    yearsOfExperience = json['yearsOfExperience'];
    role = json['role'];
    region = json['region']; // New field
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['district'] = this.district;
    data['currentEmployer'] = this.currentEmployer;
    data['contact'] = this.contact;
    data['yearsOfExperience'] = this.yearsOfExperience;
    data['role'] = this.role;
    data['region'] = this.region; // New field
    return data;
  }
}
