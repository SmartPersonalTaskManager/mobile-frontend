import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/core/validators.dart';

import '../auth/pages/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _changePwdFormKey = GlobalKey<FormState>();
  bool _hideOld = true;
  bool _hideNew = true;
  bool goalReminders = true;
  bool syncCloud = true;
  bool localOnly = false;
  bool biometricLock = false;
  bool shareUsage = true;

  String dailyBriefingTime = "08:00 AM";
  String reviewFrequency = "Weekly";
  String checkInDay = "Sunday";

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      goalReminders = prefs.getBool("goalReminders") ?? true;
      syncCloud = prefs.getBool("syncCloud") ?? true;
      localOnly = prefs.getBool("localOnly") ?? false;
      biometricLock = prefs.getBool("biometricLock") ?? false;
      shareUsage = prefs.getBool("shareUsage") ?? true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  Future<void> changePassword() async {
    final Color cardColor = const Color(AppColors.surface);
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    final prefs = await SharedPreferences.getInstance();
    final savedPassword = prefs.getString("passwd");
    debugPrint(savedPassword);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: const Text(
              "Change Password",
              style: TextStyle(color: Color(AppColors.textMain)),
            ),
            content: Form(
              key: _changePwdFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _passwordField(
                    label: "Old Password",
                    controller: oldCtrl,
                    obscure: _hideOld,
                    toggle: () => setModalState(() => _hideOld = !_hideOld),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Old password required";
                      }
                      if (savedPassword != v) {
                        return "Old password is incorrect";
                      }
                      return null;
                    },
                  ),
                  _passwordField(
                    label: "New Password",
                    controller: newCtrl,
                    obscure: _hideNew,
                    toggle: () => setModalState(() => _hideNew = !_hideNew),
                    validator: Validators.validatePasswd,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Password reset link sent to your email",
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(AppColors.primary),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text("Forgot password?"),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  final oldPwd = oldCtrl.text.trim();
                  final newPwd = newCtrl.text.trim();

                  if (savedPassword == null || savedPassword != oldPwd) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Old password is incorrect"),
                      ),
                    );
                    return;
                  }

                  if (!_changePwdFormKey.currentState!.validate()) return;

                  await prefs.setString("passwd", newPwd);

                  Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password changed successfully"),
                    ),
                  );
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(AppColors.surface),
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Color(AppColors.danger)),
        ),
        content: const Text(
          "This action cannot be undone.",
          style: TextStyle(color: Color(AppColors.textMuted)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _logout() async {
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

      if (!mounted) return;

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Settings",
          style: TextStyle(color: Color(AppColors.textMain)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(AppColors.textMain)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section("GENERAL"),
          _navTile(Icons.edit, "Change Name", () {}),
          _navTile(Icons.lock_outline, "Change Password", changePassword),
          _navTile(Icons.person, "Change Profile Picture", () {}),

          const SizedBox(height: 24),
          _section("REVIEW CADENCE"),
          _valueTile(Icons.refresh, "Frequency", reviewFrequency),
          _valueTile(Icons.calendar_today, "Check-in Day", checkInDay),

          const SizedBox(height: 24),
          _section("NOTIFICATIONS"),
          _timeTile(Icons.wb_sunny, "Review Briefing", dailyBriefingTime),
          _switchTile(
            Icons.notifications_active,
            "Goal Reminders",
            goalReminders,
            (v) {
              setState(() => goalReminders = v);
              _saveBool("goalReminders", v);
            },
          ),

          const SizedBox(height: 24),
          _section("SYNCHRONIZATION & DATA"),
          _switchTile(Icons.cloud_sync, "Sync to Cloud", syncCloud, (v) {
            setState(() => syncCloud = v);
            _saveBool("syncCloud", v);
          }),
          _switchTile(
            Icons.storage,
            "Local-only Storage",
            localOnly,
            (v) {
              setState(() => localOnly = v);
              _saveBool("localOnly", v);
            },
            subtitle: "Disable cloud backup",
          ),
          _navTile(Icons.download, "Export Data (CSV)", () {}),
          const SizedBox(height: 24),
          _navTile(Icons.logout, "Log Out", _logout),
          const SizedBox(height: 12),
          _dangerTile(Icons.delete, "Delete Account", _deleteAccount),
          const SizedBox(height: 32),
          const Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Color(AppColors.success)),
                SizedBox(height: 8),
                Text(
                  "Smart Task Manager",
                  style: TextStyle(color: Color(AppColors.textMuted)),
                ),
                Text(
                  "Version 1.0.0 (Build 2025.12)",
                  style: TextStyle(color: Color(AppColors.textMuted), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(AppColors.textMain)),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(AppColors.textMuted)),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: const Color(AppColors.textMuted),
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(AppColors.textMuted),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _navTile(IconData icon, String title, VoidCallback onTap) {
    return _baseTile(
      icon,
      title,
      trailing: const Icon(Icons.chevron_right, color: Color(AppColors.textMuted)),
      onTap: onTap,
    );
  }

  Widget _valueTile(IconData icon, String title, String value) {
    return _baseTile(
      icon,
      title,
      trailing: Text(
        value,
        style: const TextStyle(color: Color(AppColors.textMuted)),
      ),
    );
  }

  Widget _timeTile(IconData icon, String title, String value) {
    return _baseTile(
      icon,
      title,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(AppColors.surfaceBase),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: const TextStyle(color: Color(AppColors.textMain)),
        ),
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return _baseTile(
      icon,
      title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        activeThumbColor: const Color(AppColors.primary),
        onChanged: onChanged,
      ),
    );
  }

  Widget _dangerTile(IconData icon, String title, VoidCallback onTap) {
    return _baseTile(
      icon,
      title,
      onTap: onTap,
      iconColor: const Color(AppColors.danger),
      textColor: const Color(AppColors.danger),
    );
  }

  Widget _baseTile(
    IconData icon,
    String title, {
    Widget? trailing,
    VoidCallback? onTap,
    String? subtitle,
    Color iconColor = const Color(AppColors.primary),
    Color textColor = const Color(AppColors.textMain),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(
                  color: Color(AppColors.textMuted),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing,
      ),
    );
  }
}
