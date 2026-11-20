import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/wird/wird_models.dart';
import '../mushaf/reader_screen.dart';
import '../wird_setup/wird_setup_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayWirdProvider);
    final settings = ref.watch(settingsProvider).valueOrNull;
    final dateText = DateFormat.yMMMMEEEEd('ar').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('رفيقي القرآني'),
        actions: [
          IconButton(
            tooltip: 'تعديل الورد',
            icon: const Icon(Icons.tune),
            onPressed: settings == null
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => WirdSetupScreen(initial: settings),
                    )),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayWirdProvider);
          await ref.read(todayWirdProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'السلام عليكم ورحمة الله',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kGreen),
            ),
            const SizedBox(height: 4),
            Text(dateText, style: const TextStyle(fontSize: 15, color: kGold)),
            const SizedBox(height: 20),
            today.when(
              skipLoadingOnReload: true,
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorCard(
                onRetry: () => ref.invalidate(todayWirdProvider),
              ),
              data: (wird) => wird == null
                  ? const _RestDayCard()
                  : _WirdCard(wird: wird),
            ),
          ],
        ),
      ),
    );
  }
}

class _WirdCard extends ConsumerWidget {
  final TodayWird wird;
  const _WirdCard({required this.wird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahs = ref.watch(surahsProvider).valueOrNull;
    final name = surahs == null ? 'سورة ${wird.surah}' : surahs[wird.surah - 1].name;
    final range = wird.fromAyah == wird.toAyah
        ? 'الآية ${toArabicDigits(wird.fromAyah)}'
        : 'الآيات من ${toArabicDigits(wird.fromAyah)} إلى ${toArabicDigits(wird.toAyah)}';

    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('وردك اليوم',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: kGold)),
            const SizedBox(height: 8),
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold, color: kGreen)),
            const SizedBox(height: 4),
            Text(range, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            if (wird.completed)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: kGreen),
                  SizedBox(width: 6),
                  Text('تم إنجاز ورد اليوم', style: TextStyle(color: kGreen)),
                ],
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.menu_book),
              label: Text(wird.completed ? 'راجع الورد' : 'ابدأ الورد'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ReaderScreen(wird: wird),
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _RestDayCard extends StatelessWidget {
  const _RestDayCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'اليوم ليس من أيام التزامك بالورد.\nيمكنك تعديل أيام الالتزام من زر الإعدادات بالأعلى.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('تعذّر تحميل ورد اليوم. تأكد من الاتصال بالإنترنت.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}
