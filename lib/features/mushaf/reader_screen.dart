import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../data/quran/quran_models.dart';
import '../../data/wird/wird_models.dart';

/// عرض آيات ورد اليوم، الاستماع إليها، وتسجيل إتمام الورد.
class ReaderScreen extends ConsumerStatefulWidget {
  final TodayWird wird;
  const ReaderScreen({super.key, required this.wird});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _player = AudioPlayer();
  int _token = 0; // لإلغاء التشغيل الجاري عند الإيقاف
  int? _playingAyah;
  bool _playing = false;
  bool _completing = false;
  late bool _completed = widget.wird.completed;

  @override
  void dispose() {
    _token++;
    _player.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  /// تشغيل الآيات تباعاً بدءاً من الفهرس [index].
  Future<void> _playFrom(List<Ayah> ayahs, int index) async {
    final token = ++_token;
    await _player.stop();
    if (!mounted) return;
    setState(() => _playing = true);
    try {
      for (var i = index; i < ayahs.length; i++) {
        if (token != _token || !mounted) return;
        final url = ayahs[i].audioUrl;
        if (url == null) {
          _snack('الصوت غير متاح لهذه الآية');
          break;
        }
        setState(() => _playingAyah = ayahs[i].number);
        await _player.setUrl(url);
        if (token != _token || !mounted) return;
        await _player.play(); // يكتمل عند انتهاء الآية أو الإيقاف
      }
    } catch (_) {
      if (token == _token) {
        _snack('تعذّر تشغيل الصوت، تأكد من الاتصال بالإنترنت');
      }
    } finally {
      if (mounted && token == _token) {
        setState(() {
          _playing = false;
          _playingAyah = null;
        });
      }
    }
  }

  Future<void> _stop() async {
    _token++;
    await _player.stop();
    if (mounted) {
      setState(() {
        _playing = false;
        _playingAyah = null;
      });
    }
  }

  Future<void> _complete() async {
    setState(() => _completing = true);
    try {
      await ref.read(wirdRepoProvider).completeToday(widget.wird);
      ref.invalidate(todayWirdProvider);
      ref.invalidate(settingsProvider);
      if (mounted) setState(() => _completed = true);
      _snack('بارك الله فيك، تم تسجيل إنجاز ورد اليوم');
    } catch (_) {
      _snack('تعذّر حفظ الإنجاز، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wird = widget.wird;
    final content = ref.watch(surahContentProvider(wird.surah));
    final surahs = ref.watch(surahsProvider).valueOrNull;
    final title = surahs == null ? 'ورد اليوم' : surahs[wird.surah - 1].name;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: content.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('تعذّر تحميل الآيات. تأكد من الاتصال بالإنترنت.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(surahContentProvider(wird.surah)),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
        data: (c) => _buildBody(c),
      ),
    );
  }

  Widget _buildBody(SurahContent c) {
    final wird = widget.wird;
    final ayahs = c.ayahs
        .where((a) => a.number >= wird.fromAyah && a.number <= wird.toAyah)
        .toList();
    final showBasmala = c.basmala != null && wird.fromAyah == 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (showBasmala)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    c.basmala!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 26, color: kGold, height: 2),
                  ),
                ),
              for (var i = 0; i < ayahs.length; i++)
                _AyahCard(
                  ayah: ayahs[i],
                  highlighted: _playingAyah == ayahs[i].number,
                  onPlay: () => _playFrom(ayahs, i),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                        label: Text(_playing ? 'إيقاف' : 'استمع للورد'),
                        onPressed: _playing ? _stop : () => _playFrom(ayahs, 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('التسميع (قريباً)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('التفسير (قريباً)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: Icon(_completed ? Icons.check_circle : Icons.done_all),
                  label: Text(_completed ? 'تم إنجاز ورد اليوم' : 'أتممت الورد'),
                  onPressed: (_completed || _completing) ? null : _complete,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AyahCard extends StatelessWidget {
  final Ayah ayah;
  final bool highlighted;
  final VoidCallback onPlay;

  const _AyahCard({
    required this.ayah,
    required this.highlighted,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlighted ? const Color(0xFFE6F2E8) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ayah.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, height: 2.1),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: kGold,
                  child: Text(
                    toArabicDigits(ayah.number),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                IconButton(
                  tooltip: 'استمع من هذه الآية',
                  icon: const Icon(Icons.play_circle_outline, color: kGreen),
                  onPressed: onPlay,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
