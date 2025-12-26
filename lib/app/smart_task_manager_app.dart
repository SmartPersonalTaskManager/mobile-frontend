import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_shell.dart';
import '../views/auth/pages/login_page.dart';

class SmartTaskManagerApp extends StatefulWidget {
  const SmartTaskManagerApp({ super.key });

  @override
  State<SmartTaskManagerApp> createState() => _SmartTaskManagerAppState();
}

class _SmartTaskManagerAppState extends State<SmartTaskManagerApp> {
  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("loggedIn") ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Smart Task Manager App",
        home: FutureBuilder<bool>(
          future: checkLogin(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final loggedIn = snapshot.data!;
            return loggedIn ? const MainShell() : const LoginPage();          },
        )
    );
  }
}