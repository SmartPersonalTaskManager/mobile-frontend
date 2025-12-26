class Validators {
  static String? validateName(String? str) {
    if (str == null || str.trim().isEmpty) return "Please enter your full name";
    if (str.trim().length < 2) return "Name is too short";
    return null;
  }

  static String? validateEmailOrPhone(String? str) {
    final isEmail = validateEmail(str);
    final isPhone = validatePhone(str);
    if (isEmail == null || isPhone == null) return null;
    return "Invalid e-mail or phone number";
  }

  static String? validateEmail(String? str) {
    if (str == null || str.trim().isEmpty) return "Please enter your e-mail";
    final email = str.trim();
    final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
    if (!emailRegex.hasMatch(email)) return "Enter a valid e-mail";
    return null;
  }

  static String? validatePhone(String? str) {
    if (str == null || str.trim().isEmpty) return "Please enter your phone number";
    final phone = str.trim();
    final phoneRegex = RegExp(r"^\+?\d{7,15}$");
    if (!phoneRegex.hasMatch(phone)) return "Enter a valid phone number";
    return null;
  }

  static String? validatePasswd(String? str) {
    if (str == null || str.isEmpty) return "Please enter a password";
    if (str.length < 8) return "Password must be at least 8 characters";
    final digit = RegExp(r'\d');
    final letter = RegExp(r"[A-Za-z]");
    if (!digit.hasMatch(str) || !letter.hasMatch(str)) return "Password must contain letters and numbers";
    return null;
  }
}