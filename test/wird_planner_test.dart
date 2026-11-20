import 'package:flutter_test/flutter_test.dart';
import 'package:rafiqi_quranic/data/quran/quran_repository.dart';
import 'package:rafiqi_quranic/data/wird/wird_planner.dart';

void main() {
  group('planRange', () {
    test('يأخذ العدد المطلوب من بداية السورة', () {
      final r = planRange(surah: 1, ayah: 1, count: 5, ayahsInSurah: 7);
      expect([r.surah, r.fromAyah, r.toAyah], [1, 1, 5]);
    });

    test('لا يتجاوز نهاية السورة', () {
      final r = planRange(surah: 1, ayah: 6, count: 5, ayahsInSurah: 7);
      expect([r.fromAyah, r.toAyah], [6, 7]);
    });

    test('آية بداية خارج النطاق تُقيَّد بآخر آية', () {
      final r = planRange(surah: 112, ayah: 99, count: 3, ayahsInSurah: 4);
      expect([r.fromAyah, r.toAyah], [4, 4]);
    });
  });

  group('nextPosition', () {
    test('يتقدم داخل السورة', () {
      final p = nextPosition(surah: 2, lastAyahRead: 5, ayahsInSurah: 286);
      expect([p.surah, p.ayah], [2, 6]);
    });

    test('ينتقل للسورة التالية عند نهاية السورة', () {
      final p = nextPosition(surah: 1, lastAyahRead: 7, ayahsInSurah: 7);
      expect([p.surah, p.ayah], [2, 1]);
    });

    test('بعد سورة الناس يعود للفاتحة', () {
      final p = nextPosition(surah: 114, lastAyahRead: 6, ayahsInSurah: 6);
      expect([p.surah, p.ayah], [1, 1]);
    });
  });

  group('parseSurahData', () {
    Map<String, dynamic> edition(String id, List<Map<String, dynamic>> ayahs) => {
          'number': 2,
          'numberOfAyahs': ayahs.length,
          'edition': {'identifier': id},
          'ayahs': ayahs,
        };

    test('يفصل البسملة المضافة قبل أول آية (غير الفاتحة والتوبة)', () {
      final data = [
        edition('quran-uthmani', [
          {'numberInSurah': 1, 'text': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ الٓمٓ'},
          {'numberInSurah': 2, 'text': 'نص ثان'},
        ]),
        edition('ar.alafasy', [
          {'numberInSurah': 1, 'audio': 'http://x/1.mp3'},
          {'numberInSurah': 2, 'audio': 'http://x/2.mp3'},
        ]),
      ];
      final c = parseSurahData(2, data);
      expect(c.basmala, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ');
      expect(c.ayahs.first.text, 'الٓمٓ');
      expect(c.ayahs.first.audioUrl, 'https://x/1.mp3');
    });

    test('لا يمسّ نص الفاتحة', () {
      final data = [
        edition('quran-uthmani', [
          {'numberInSurah': 1, 'text': 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ'},
        ]),
      ];
      final c = parseSurahData(1, data);
      expect(c.basmala, isNull);
      expect(c.ayahs.first.text, 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ');
    });

    test('يرفض رداً ناقص الآيات', () {
      final bad = edition('quran-uthmani', [
        {'numberInSurah': 1, 'text': 'x'},
      ]);
      bad['numberOfAyahs'] = 3;
      expect(() => parseSurahData(2, [bad]), throwsA(isA<QuranException>()));
    });
  });
}
