import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'quran_models.dart';

class QuranException implements Exception {
  final String message;
  QuranException(this.message);
  @override
  String toString() => message;
}

final RegExp _diacritics =
    RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u08D3-\u08FF\u0640]');

/// تحليل رد API لسورة واحدة. نص القرآن يأتي حرفياً من المصدر (نسخة quran-uthmani)
/// ولا يُعدَّل إلا بفصل البسملة التي يضيفها المصدر قبل أول آية.
SurahContent parseSurahData(int surah, List<dynamic> editions) {
  Map<String, dynamic>? textEd;
  Map<String, dynamic>? audioEd;
  for (final e in editions) {
    final m = e as Map<String, dynamic>;
    final id = (m['edition'] as Map<String, dynamic>)['identifier'];
    if (id == 'quran-uthmani') textEd = m;
    if (id == 'ar.alafasy') audioEd = m;
  }
  if (textEd == null) throw QuranException('نص السورة غير موجود في الرد');

  final textAyahs = (textEd['ayahs'] as List).cast<Map<String, dynamic>>();
  final expected = textEd['numberOfAyahs'] as int;
  if (textAyahs.length != expected) {
    throw QuranException('عدد الآيات المستلمة غير مطابق للمتوقع');
  }

  final audioByNumber = <int, String>{};
  if (audioEd != null) {
    for (final a in (audioEd['ayahs'] as List).cast<Map<String, dynamic>>()) {
      final url = a['audio'];
      if (url is String && url.isNotEmpty) {
        audioByNumber[a['numberInSurah'] as int] =
            url.replaceFirst('http://', 'https://');
      }
    }
  }

  String? basmala;
  final ayahs = <Ayah>[];
  for (final a in textAyahs) {
    final n = a['numberInSurah'] as int;
    var text = a['text'] as String;
    if (n == 1 && surah != 1 && surah != 9) {
      final tokens = text.split(' ');
      if (tokens.length > 4 && tokens.first.replaceAll(_diacritics, '') == 'بسم') {
        basmala = tokens.take(4).join(' ');
        text = tokens.skip(4).join(' ');
      }
    }
    ayahs.add(Ayah(number: n, text: text, audioUrl: audioByNumber[n]));
  }
  return SurahContent(surah: surah, basmala: basmala, ayahs: ayahs);
}

/// مصدر النص: Al-Quran Cloud API (النسخة العثمانية quran-uthmani).
/// يُحفظ كل ما يُجلب محلياً فلا يُطلب من الشبكة مرة ثانية.
class QuranRepository {
  static const _base = 'https://api.alquran.cloud/v1';
  static const _timeout = Duration(seconds: 25);

  Future<Map<String, dynamic>> _getJson(String path) async {
    final res = await http.get(Uri.parse('$_base$path')).timeout(_timeout);
    if (res.statusCode != 200) {
      throw QuranException('تعذّر جلب البيانات (${res.statusCode})');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<SurahInfo>> surahs() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'surahs_v1';
    final cached = prefs.getString(key);
    if (cached != null) {
      try {
        return _parseSurahs(jsonDecode(cached) as List);
      } catch (_) {}
    }
    final body = await _getJson('/surah');
    final data = body['data'] as List;
    final list = _parseSurahs(data);
    await prefs.setString(
      key,
      jsonEncode(list.map((s) => s.toJson()).toList()),
    );
    return list;
  }

  List<SurahInfo> _parseSurahs(List data) {
    final list = data
        .map((e) => SurahInfo.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    if (list.length != 114) throw QuranException('قائمة السور غير مكتملة');
    return list;
  }

  Future<SurahContent> surah(int number) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'surah_v1_$number';
    final cached = prefs.getString(key);
    if (cached != null) {
      try {
        return parseSurahData(number, jsonDecode(cached) as List);
      } catch (_) {}
    }
    final body = await _getJson('/surah/$number/editions/quran-uthmani,ar.alafasy');
    final data = body['data'] as List;
    final content = parseSurahData(number, data);
    await prefs.setString(key, jsonEncode(data));
    return content;
  }
}
