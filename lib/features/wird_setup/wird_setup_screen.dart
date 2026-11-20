import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/quran/quran_models.dart';
import '../../data/wird/wird_models.dart';

/// إعداد الورد اليومي (أول مرة، أو تعديلاً لاحقاً).
class WirdSetupScreen extends ConsumerStatefulWidget {
  final WirdSettings? initial;
  const WirdSetupScreen({super.key, this.initial});

  bool get isEdit => initial != null;

  @override
  ConsumerState<WirdSetupScreen> createState() => _WirdSetupScreenState();
}

class _WirdSetupScreenState extends ConsumerState<WirdSetupScreen> {
  // الأسبوع يبدأ بالسبت. القيم مثل DateTime.weekday (الاثنين = 1 ... الأحد = 7).
  static const _days = <MapEntry<int, String>>[
    MapEntry(6, 'السبت'),
    MapEntry(7, 'الأحد'),
    MapEntry(1, 'الإثنين'),
    MapEntry(2, 'الثلاثاء'),
    MapEntry(3, 'الأربعاء'),
    MapEntry(4, 'الخميس'),
    MapEntry(5, 'الجمعة'),
  ];

  late TimeOfDay _time =
      widget.initial?.time ?? const TimeOfDay(hour: 5, minute: 0);
  late int _count = widget.initial?.ayatPerDay ?? 3;
  late final Set<int> _activeDays = {
    ...(widget.initial?.activeDays ?? const [1, 2, 3, 4, 5, 6, 7]),
  };
  late int _surah = widget.initial?.nextSurah ?? 1;
  late int _ayah = widget.initial?.nextAyah ?? 1;
  bool _saving = false;

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _save() async {
    if (_activeDays.isEmpty) {
      _snack('اختر يوماً واحداً على الأقل');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(wirdRepoProvider).saveSettings(WirdSettings(
            time: _time,
            ayatPerDay: _count,
            activeDays: _activeDays.toList()..sort(),
            nextSurah: _surah,
            nextAyah: _ayah,
          ));
      ref.invalidate(todayWirdProvider);
      ref.invalidate(settingsProvider);
      if (mounted && widget.isEdit) Navigator.of(context).pop();
    } catch (_) {
      _snack('تعذّر حفظ الإعدادات، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final surahs = ref.watch(surahsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'تعديل الورد' : 'إعداد وردك اليومي')),
      body: surahs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تعذّر تحميل قائمة السور. تأكد من الاتصال بالإنترنت.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(surahsProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: _buildForm,
      ),
    );
  }

  Widget _buildForm(List<SurahInfo> surahs) {
    final info = surahs[_surah - 1];
    if (_ayah > info.numberOfAyahs) _ayah = 1;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('وقت الورد اليومي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickTime,
          icon: const Icon(Icons.access_time),
          label: Text(_time.format(context)),
        ),
        const SizedBox(height: 24),
        const Text('عدد الآيات يومياً',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: [
            for (final n in [3, 4, 5])
              ButtonSegment(value: n, label: Text(toArabicDigits(n))),
          ],
          selected: {_count},
          onSelectionChanged: (s) => setState(() => _count = s.first),
        ),
        const SizedBox(height: 24),
        const Text('أيام الالتزام',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final d in _days)
              FilterChip(
                label: Text(d.value),
                selected: _activeDays.contains(d.key),
                onSelected: (on) => setState(() {
                  on ? _activeDays.add(d.key) : _activeDays.remove(d.key);
                }),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(widget.isEdit ? 'الموضع التالي في الورد' : 'ابدأ من',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          key: ValueKey('surah_$_surah'),
          value: _surah,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'السورة', border: OutlineInputBorder()),
          items: [
            for (final s in surahs)
              DropdownMenuItem(
                value: s.number,
                child: Text('${toArabicDigits(s.number)}. ${s.name}'),
              ),
          ],
          onChanged: (v) => setState(() {
            _surah = v ?? 1;
            _ayah = 1;
          }),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: ValueKey('ayah_${_surah}_$_ayah'),
          value: _ayah,
          decoration: const InputDecoration(
              labelText: 'رقم الآية', border: OutlineInputBorder()),
          items: [
            for (var i = 1; i <= info.numberOfAyahs; i++)
              DropdownMenuItem(value: i, child: Text(toArabicDigits(i))),
          ],
          onChanged: (v) => setState(() => _ayah = v ?? 1),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
