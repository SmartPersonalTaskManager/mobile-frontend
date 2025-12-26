import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/app/main_shell.dart';
import 'package:sptm/core/constants.dart';
// import 'package:sptm/core/validators.dart';
import 'package:sptm/services/auth_service.dart';
import 'package:sptm/views/auth/dialogs/forgot_passwd_dialog.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final authService = AuthService();
  final emailCtrl = TextEditingController();
  final passwdCtrl = TextEditingController();
  bool loading = false;
  bool obscure = true;

  void _showForgotPasswdDialog() {
    showDialog(
      context: context,
      builder: (_) => ForgotPasswdDialog(authService: authService),
    );
  }

  Future<void> _login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await authService.login(emailCtrl.text.trim(), passwdCtrl.text);
      await saveLoginState(true);
      Fluttertoast.showToast(msg: "Login successful!");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainShell()),
        (route) => false,
      );
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    } catch (_) {
      Fluttertoast.showToast(msg: "Login failed. Please try again.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> saveLoginState(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("loggedIn", val);
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Color(AppColors.textMain)),
        decoration: InputDecoration(
          icon: Icon(icon, color: const Color(AppColors.textMuted)),
          hintText: hint,
          hintStyle: const TextStyle(color: Color(AppColors.textMuted)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextFormField(
        controller: passwdCtrl,
        obscureText: obscure,
        // validator: Validators.validatePasswd,
        style: const TextStyle(color: Color(AppColors.textMain)),
        decoration: InputDecoration(
          icon: const Icon(
            Icons.lock_outline,
            color: Color(AppColors.textMuted),
          ),
          hintText: "Enter your password",
          hintStyle: const TextStyle(color: Color(AppColors.textMuted)),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(AppColors.textMuted),
            ),
            onPressed: () => setState(() => obscure = !obscure),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String text, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(AppColors.textMuted)),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Color(AppColors.textMain),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(AppColors.surfaceBase),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 50,
                    color: Color(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  maxLines: 2,
                  "Focus on what matters",
                  style: TextStyle(
                    fontSize: 30,
                    color: Color(AppColors.textMain),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Align your day with your mission.\nLog in to access your personal task manager.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(AppColors.textMuted),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 34),
                const Text(
                  "Email",
                  style: TextStyle(
                    color: Color(AppColors.textMain),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInputField(
                  controller: emailCtrl,
                  hint: "Enter your email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 22),
                const Text(
                  "Password",
                  style: TextStyle(
                    color: Color(AppColors.textMain),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPasswordField(),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswdDialog,
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Color(AppColors.primary),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: loading ? null : _login,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.primary),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            AppColors.primary,
                          ).withOpacity(0.4),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(AppColors.textInverted),
                              ),
                            )
                          : const Text(
                              "Log In",
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(AppColors.textInverted),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                    child: const Text(
                      "I don't have an account.",
                      style: TextStyle(color: Color(AppColors.textMuted)),
                    ),
                  ),
                ),
                Row(
                  children: const [
                    Expanded(
                      child: Divider(color: Color(AppColors.surfaceBase)),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "OR CONTINUE WITH",
                      style: TextStyle(
                        color: Color(AppColors.textMuted),
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Divider(color: Color(AppColors.surfaceBase)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton("Google", Icons.g_mobiledata),
                    _buildSocialButton("Apple", Icons.apple),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
