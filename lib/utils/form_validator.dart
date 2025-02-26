class FormValidator {
  static String? validateEmail(String? value) {
    if (value!.isEmpty) {
      return "Email cannot be empty";
    }
    if (!RegExp("^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+.[a-z]").hasMatch(value)) {
      return "Please enter a valid email";
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value!.isEmpty) {
      return "Password cannot be empty";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

   static String? validateUsername(String? value) {
    if (value!.isEmpty) {
      return "Username cannot be empty";
    }
    return null;
  }

  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword != password) {
      return "Passwords do not match";
    }
    return null;
  }
}
