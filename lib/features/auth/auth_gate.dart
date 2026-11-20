import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../home/home_screen.dart';
import '../wird_setup/wird_setup_screen.dart';
import 'signed_out_screen.dart';

/// يختار الشاشة حسب حالة تسجيل الدخول.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, _) {
        final session = Supabase.instance.client.auth.currentSession;
        return session == null ? const SignedOutScreen() : const RootScreen();
      },
    );
  }
}

/// بعد الدخول: إعداد الورد أول مرة، ثم الشاشة الرئيسية.
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return settings.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تعذّر تحميل بياناتك. تأكد من الاتصال بالإنترنت.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(settingsProvider),
                  child: const Text('إعادة المحاولة'),
                ),
                TextButton(
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (s) => s == null ? const WirdSetupScreen() : const HomeScreen(),
    );
  }
}
