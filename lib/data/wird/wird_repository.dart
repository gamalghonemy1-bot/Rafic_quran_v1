import 'package:supabase_flutter/supabase_flutter.dart';

import '../quran/quran_repository.dart';
import 'wird_models.dart';
import 'wird_planner.dart';

class WirdRepository {
  final SupabaseClient _db;
  final QuranRepository _quran;

  WirdRepository(this._db, this._quran);

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw StateError('لا يوجد مستخدم مسجّل');
    return id;
  }

  Future<WirdSettings?> fetchSettings() async {
    final row = await _db
        .from('wird_settings')
        .select()
        .eq('user_id', _uid)
        .maybeSingle();
    return row == null ? null : WirdSettings.fromRow(row);
  }

  Future<void> saveSettings(WirdSettings s) async {
    await _db.from('wird_settings').upsert(s.toRow(_uid), onConflict: 'user_id');
    // لو تغيّرت الإعدادات والورد لم يُنجز بعد، يُعاد حساب ورد اليوم.
    await _db
        .from('wird_days')
        .delete()
        .eq('user_id', _uid)
        .eq('day', dateKey(DateTime.now()))
        .eq('status', 'pending');
  }

  /// ورد اليوم: يُنشأ عند أول طلب في اليوم ويبقى ثابتاً بعدها.
  /// يرجع null إن كان اليوم خارج أيام الالتزام ولا يوجد ورد مسجّل له.
  Future<TodayWird?> todayWird() async {
    final now = DateTime.now();
    final today = dateKey(now);

    final existing = await _db
        .from('wird_days')
        .select()
        .eq('user_id', _uid)
        .eq('day', today)
        .maybeSingle();
    if (existing != null) return TodayWird.fromRow(existing);

    final settings = await fetchSettings();
    if (settings == null) return null;
    if (!settings.activeDays.contains(now.weekday)) return null;

    final surahs = await _quran.surahs();
    final info = surahs[settings.nextSurah - 1];
    final range = planRange(
      surah: settings.nextSurah,
      ayah: settings.nextAyah,
      count: settings.ayatPerDay,
      ayahsInSurah: info.numberOfAyahs,
    );

    await _db.from('wird_days').upsert(
      {
        'user_id': _uid,
        'day': today,
        'surah': range.surah,
        'from_ayah': range.fromAyah,
        'to_ayah': range.toAyah,
        'status': 'pending',
      },
      onConflict: 'user_id,day',
      ignoreDuplicates: true,
    );

    final row = await _db
        .from('wird_days')
        .select()
        .eq('user_id', _uid)
        .eq('day', today)
        .single();
    return TodayWird.fromRow(row);
  }

  /// تسجيل إتمام الورد وتقديم الموضع التالي (في عملية واحدة على الخادم).
  Future<void> completeToday(TodayWird wird) async {
    final surahs = await _quran.surahs();
    final next = nextPosition(
      surah: wird.surah,
      lastAyahRead: wird.toAyah,
      ayahsInSurah: surahs[wird.surah - 1].numberOfAyahs,
    );
    await _db.rpc('complete_wird', params: {
      'p_day': wird.day,
      'p_next_surah': next.surah,
      'p_next_ayah': next.ayah,
    });
  }
}
