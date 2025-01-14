class Interpreter {
  String? name;
  String? email;
  String? district;
  String? currentEmployer;
  String? contact;
  String? yearsOfExperience;
  String? role;

  Interpreter(
      {this.name,
      this.email,
      this.district,
      this.currentEmployer,
      this.contact,
      this.yearsOfExperience,
      this.role});

  Interpreter.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    email = json['email'];
    district = json['district'];
    currentEmployer = json['current_employer'];
    contact = json['contact'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['email'] = this.email;
    data['district'] = this.district;
    data['current_employer'] = this.currentEmployer;
    data['contact'] = this.contact;
    data['years_of_experience'] = this.yearsOfExperience;
    data['role'] = this.role;
    return data;
  }
}

