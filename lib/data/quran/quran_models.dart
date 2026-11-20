class SurahInfo {
  final int number;
  final String name;
  final int numberOfAyahs;

  const SurahInfo({
    required this.number,
    required this.name,
    required this.numberOfAyahs,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
        number: j['number'] as int,
        name: j['name'] as String,
        numberOfAyahs: j['numberOfAyahs'] as int,
      );

  Map<String, dynamic> toJson() => {
        'number': number,
        'name': name,
        'numberOfAyahs': numberOfAyahs,
      };
}

class Ayah {
  /// رقم الآية داخل السورة.
  final int number;
  final String text;
  final String? audioUrl;

  const Ayah({required this.number, required this.text, this.audioUrl});
}

class SurahContent {
  final int surah;

  /// البسملة (إن وُجدت في أول السورة وليست آية منها).
  final String? basmala;
  final List<Ayah> ayahs;

  const SurahContent({
    required this.surah,
    required this.basmala,
    required this.ayahs,
  });
}
