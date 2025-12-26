import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/core/validators.dart';
import 'package:sptm/services/auth_service.dart';

enum Stage { enterEmail, enterCode }

class ForgotPasswdDialog extends StatefulWidget {
  final AuthService authService;

  const ForgotPasswdDialog({super.key, required this.authService});

  @override
  State<ForgotPasswdDialog> createState() => _ForgotPasswdDialogState();
}

class _ForgotPasswdDialogState extends State<ForgotPasswdDialog> {
  final formKey = GlobalKey<FormState>();

  final emailCtrl = TextEditingController();
  final codeCtrl = TextEditingController();
  final newPasswdCtrl = TextEditingController();
  final confirmPasswdCtrl = TextEditingController();

  static const int initialSecs = 180;
  int secsRemaining = 0;
  Timer? countdownTimer;
  Stage stage = Stage.enterEmail;
  bool loading = false;

  void _startTimer() {
    _cancelTimer();
    setState(() => secsRemaining = initialSecs);
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (secsRemaining > 0) {
          secsRemaining -= 1;
        } else {
          _cancelTimer();
        }
      });
    });
  }

  void _cancelTimer() {
    countdownTimer?.cancel();
    countdownTimer = null;
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _sendCode() async {
    //if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await widget.authService.requestPasswdReset(emailCtrl.text.trim());
      _startTimer();
      setState(() => stage = Stage.enterCode);
      Fluttertoast.showToast(
        msg: "If an account exists for this e-mail, you will receive a code.",
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unable to process request. Please try again later.",
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _submitCodeAndPasswd() async {
    //if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final success = await widget.authService.resetPasswdWithCode(
        emailCtrl.text.trim(),
        codeCtrl.text.trim(),
        newPasswdCtrl.text,
      );

      if (success) {
        Fluttertoast.showToast(
          msg:
              "Password changed successfully. Please login with your new password.",
        );
        Navigator.of(context).pop();
      } else {
        Fluttertoast.showToast(
          msg: "Invalid code or code expired. Please try again.",
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Unable to process request. Please try again later.",
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resendCode() async {
    if (secsRemaining > 0) return;
    setState(() => loading = true);
    try {
      await widget.authService.requestPasswdReset(emailCtrl.text.trim());
      _startTimer();
      Fluttertoast.showToast(
        msg: "If an account exists for this email, a new code will arrive.",
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Unable to resend code. Try again later.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    emailCtrl.dispose();
    codeCtrl.dispose();
    newPasswdCtrl.dispose();
    confirmPasswdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Reset Password"),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: stage == Stage.enterEmail
            ? _buildEmailEntry()
            : _buildCodeEntry(),
      ),
      actions: _buildActions(),
    );
  }

  List<Widget> _buildActions() {
    if (stage == Stage.enterEmail) {
      return [
        TextButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: loading ? null : _sendCode,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Send Code"),
        ),
      ];
    } else {
      return [
        TextButton(
          onPressed: loading
              ? null
              : () {
                  _cancelTimer();
                  setState(() => stage = Stage.enterEmail);
                },
          child: const Text("Change Email"),
        ),
        TextButton(
          onPressed: (loading || secsRemaining > 0) ? null : _resendCode,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Resend"),
        ),
        ElevatedButton(
          onPressed: loading ? null : _submitCodeAndPasswd,
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Verify & Reset"),
        ),
      ];
    }
  }

  Widget _buildEmailEntry() {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: Validators.validateEmail,
        decoration: const InputDecoration(
          labelText: "E-Mail",
          hintText: "you@example.com",
        ),
      ),
    );
  }

  Widget _buildCodeEntry() {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: emailCtrl.text.trim(),
            readOnly: true,
            decoration: const InputDecoration(labelText: "E-Mail"),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: codeCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Verification Code"),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: newPasswdCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "New Password"),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: confirmPasswdCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: "Confirm Password"),
          ),
          const SizedBox(height: 12),
          if (secsRemaining > 0)
            Text(
              'Code expires in ${_formatTime(secsRemaining)}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            )
          else
            const Text(
              'Code expired. You may resend.',
              style: TextStyle(color: Color(AppColors.danger)),
            ),
        ],
      ),
    );
  }
}
