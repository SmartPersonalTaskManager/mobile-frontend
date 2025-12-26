import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';

import '../auth/pages/login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<Map<String, String>> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "username": prefs.getString("username") ?? prefs.getString("name") ?? "",
      "email": prefs.getString("email") ?? "",
    };
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppColors.surface),
        title: const Text(
          "Log Out",
          style: TextStyle(color: Color(AppColors.textMain)),
        ),
        content: const Text(
          "You can sign back in anytime.",
          style: TextStyle(color: Color(AppColors.textMuted)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.background),
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Color(AppColors.textMain),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textMain)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _loadUserProfile(),
        builder: (context, snapshot) {
          final username = snapshot.data?["username"] ?? "";
          final email = snapshot.data?["email"] ?? "";
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profileCard(username: username, email: email),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Log Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(AppColors.danger),
                    foregroundColor: const Color(AppColors.textMain),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileCard({required String username, required String email}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Username",
            style: TextStyle(
              color: Color(AppColors.textMuted),
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            username.isNotEmpty ? username : "Not set",
            style: const TextStyle(
              color: Color(AppColors.textMain),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Email",
            style: TextStyle(
              color: Color(AppColors.textMuted),
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email.isNotEmpty ? email : "Not set",
            style: const TextStyle(
              color: Color(AppColors.textMain),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
