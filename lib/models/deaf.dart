class DeafUser {
  String? uid;
  String? name;
  String? email;
  String? district;
  String? currentEmployer;
  String? contact;
  String? yearsOfExperience;
  String? role;

  DeafUser(
      {this.uid,
      this.name,
      this.email,
      this.district,
      this.currentEmployer,
      this.contact,
      this.yearsOfExperience,
      this.role});

  DeafUser.fromJson(Map<String, dynamic> json, {String? documentId}) {
    uid = documentId;
    name = json['name'];
    email = json['email'];
    district = json['district'];
    currentEmployer = json['current_employer'];
    contact = json['contact'];
    yearsOfExperience = json['years_of_Experience'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['email'] = email;
    data['district'] = district;
    data['current_employer'] = currentEmployer;
    data['contact'] = contact;
    data['years_of_experience'] = yearsOfExperience;
    data['role'] = role;
    return data;
  }
}
