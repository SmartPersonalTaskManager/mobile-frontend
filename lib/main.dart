import 'package:flutter/material.dart';
import 'package:sptm/core/constants.dart';
import 'core/theme.dart';
import 'views/auth/pages/login_page.dart';

void main() {
  runApp(const SmartTaskManagerApp());
}

class SmartTaskManagerApp extends StatelessWidget {
  const SmartTaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}

/*
  * TODO:
  *  - passwd yenileme kodu gönderildikten sonra kodu gireceği ekran
  *  - girilen email geçersizse login mümkün olmasın
 */
