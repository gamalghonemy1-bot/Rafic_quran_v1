import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/quran/quran_models.dart';
import '../data/quran/quran_repository.dart';
import '../data/wird/wird_models.dart';
import '../data/wird/wird_repository.dart';

final supabaseProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final quranRepoProvider = Provider<QuranRepository>((_) => QuranRepository());

final wirdRepoProvider = Provider<WirdRepository>(
  (ref) => WirdRepository(
    ref.watch(supabaseProvider),
    ref.watch(quranRepoProvider),
  ),
);

final surahsProvider = FutureProvider<List<SurahInfo>>(
  (ref) => ref.watch(quranRepoProvider).surahs(),
);

final surahContentProvider = FutureProvider.family<SurahContent, int>(
  (ref, surah) => ref.watch(quranRepoProvider).surah(surah),
);

final settingsProvider = FutureProvider.autoDispose<WirdSettings?>(
  (ref) => ref.watch(wirdRepoProvider).fetchSettings(),
);

/// ورد اليوم، أو null إن كان اليوم خارج أيام الالتزام.
final todayWirdProvider = FutureProvider.autoDispose<TodayWird?>(
  (ref) => ref.watch(wirdRepoProvider).todayWird(),
);
