import 'package:flutter/material.dart';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class WirdSettings {
  final TimeOfDay time;
  final int ayatPerDay;

  /// أيام الالتزام: 1 = الاثنين ... 7 = الأحد (مثل DateTime.weekday).
  final List<int> activeDays;
  final int nextSurah;
  final int nextAyah;

  const WirdSettings({
    required this.time,
    required this.ayatPerDay,
    required this.activeDays,
    required this.nextSurah,
    required this.nextAyah,
  });

  factory WirdSettings.fromRow(Map<String, dynamic> row) {
    final parts = (row['wird_time'] as String).split(':');
    return WirdSettings(
      time: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      ayatPerDay: row['ayat_per_day'] as int,
      activeDays: (row['active_days'] as List).map((e) => e as int).toList(),
      nextSurah: row['next_surah'] as int,
      nextAyah: row['next_ayah'] as int,
    );
  }

  Map<String, dynamic> toRow(String userId) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return {
      'user_id': userId,
      'wird_time': '$hh:$mm:00',
      'ayat_per_day': ayatPerDay,
      'active_days': activeDays,
      'next_surah': nextSurah,
      'next_ayah': nextAyah,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}

class TodayWird {
  final String day;
  final int surah;
  final int fromAyah;
  final int toAyah;
  final bool completed;

  const TodayWird({
    required this.day,
    required this.surah,
    required this.fromAyah,
    required this.toAyah,
    required this.completed,
  });

  factory TodayWird.fromRow(Map<String, dynamic> row) => TodayWird(
        day: row['day'] as String,
        surah: row['surah'] as int,
        fromAyah: row['from_ayah'] as int,
        toAyah: row['to_ayah'] as int,
        completed: row['status'] == 'completed',
      );
}
