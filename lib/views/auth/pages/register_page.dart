import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sptm/core/constants.dart';
// import 'package:sptm/core/validators.dart';
import 'package:sptm/services/auth_service.dart';
import 'package:sptm/views/auth/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final authService = AuthService();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwdCtrl = TextEditingController();
  bool loading = false;
  bool obscure = true;

  Future<void> _register() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await authService.register(
        nameCtrl.text.trim(),
        emailCtrl.text.trim(),
        passwdCtrl.text.trim(),
      );
      Fluttertoast.showToast(msg: "Registration successful!");
      Navigator.pop(context);
    } on AuthException catch (e) {
      Fluttertoast.showToast(msg: e.message);
    } catch (_) {
      Fluttertoast.showToast(msg: "Registration failed. Please try again.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Color(AppColors.textMain), fontSize: 15),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(16),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: passwdCtrl,
        obscureText: obscure,
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

  @override
  void dispose() {
    nameCtrl.dispose();
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    Icons.person_add,
                    color: Color(AppColors.primary),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "Create your account",
                  style: TextStyle(
                    fontSize: 32,
                    color: Color(AppColors.textMain),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Start organizing your goals and tasks with a personalized account.",
                  style: TextStyle(
                    color: Color(AppColors.textMuted),
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 34),
                _buildLabel("Username"),
                _buildInputField(
                  controller: nameCtrl,
                  hint: "Create a username",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildLabel("Email"),
                _buildInputField(
                  controller: emailCtrl,
                  hint: "Enter your email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 20),
                _buildLabel("Password"),
                _buildPasswordField(),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: loading ? null : _register,
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
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(AppColors.textInverted),
                              ),
                            )
                          : const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(AppColors.textInverted),
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
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text(
                      "Already have an account?",
                      style: TextStyle(color: Color(AppColors.textMuted)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
