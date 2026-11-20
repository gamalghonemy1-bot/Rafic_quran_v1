import 'dart:math';

const int kSurahCount = 114;

class WirdRange {
  final int surah;
  final int fromAyah;
  final int toAyah;
  const WirdRange(this.surah, this.fromAyah, this.toAyah);
  int get count => toAyah - fromAyah + 1;
}

class QuranPosition {
  final int surah;
  final int ayah;
  const QuranPosition(this.surah, this.ayah);
}

/// ورد اليوم: [count] آيات تبدأ من (surah:ayah) ولا تتجاوز نهاية السورة.
/// إن بقي في السورة أقل من [count] آيات يُقتصر الورد على المتبقي.
WirdRange planRange({
  required int surah,
  required int ayah,
  required int count,
  required int ayahsInSurah,
}) {
  final from = min(max(ayah, 1), ayahsInSurah);
  final to = min(from + count - 1, ayahsInSurah);
  return WirdRange(surah, from, to);
}

/// الموضع التالي بعد قراءة آخر آية [lastAyahRead]. بعد سورة الناس يعود للفاتحة.
QuranPosition nextPosition({
  required int surah,
  required int lastAyahRead,
  required int ayahsInSurah,
}) {
  if (lastAyahRead < ayahsInSurah) {
    return QuranPosition(surah, lastAyahRead + 1);
  }
  return QuranPosition(surah >= kSurahCount ? 1 : surah + 1, 1);
}
