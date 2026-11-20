import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';

/// شاشة الترحيب + تسجيل الدخول / إنشاء حساب.
class SignedOutScreen extends StatefulWidget {
  const SignedOutScreen({super.key});

  @override
  State<SignedOutScreen> createState() => _SignedOutScreenState();
}

class _SignedOutScreenState extends State<SignedOutScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _arabicError(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login')) return 'البريد أو كلمة المرور غير صحيحة';
    if (m.contains('already registered')) return 'هذا البريد مسجّل بالفعل';
    if (m.contains('password')) return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
    if (m.contains('email not confirmed')) return 'فعّل بريدك أولاً من الرسالة التي وصلتك';
    return 'حدث خطأ: $msg';
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'اكتب البريد وكلمة المرور');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (_signUp) {
        final res = await auth.signUp(
          email: email,
          password: password,
          data: {'display_name': _name.text.trim()},
        );
        if (res.session == null && mounted) {
          setState(() => _info =
              'تم إنشاء الحساب. أرسلنا رسالة تفعيل لبريدك، فعّله ثم سجّل الدخول.');
        }
      } else {
        await auth.signInWithPassword(email: email, password: password);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _arabicError(e.message));
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر الاتصال. تأكد من الإنترنت.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 72, color: kGreen),
                  const SizedBox(height: 12),
                  const Text(
                    'رفيقي القرآني',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold, color: kGreen),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'رفيقك اليومي للمحافظة على وردك من القرآن الكريم',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: kGold),
                  ),
                  const SizedBox(height: 32),
                  if (_signUp) ...[
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        labelText: 'الاسم',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                    ),
                  if (_info != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_info!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: kGreen)),
                    ),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_signUp ? 'إنشاء حساب' : 'تسجيل الدخول'),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _signUp = !_signUp;
                              _error = null;
                              _info = null;
                            }),
                    child: Text(_signUp
                        ? 'عندي حساب بالفعل'
                        : 'ليس لدي حساب، أنشئ حساباً'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
