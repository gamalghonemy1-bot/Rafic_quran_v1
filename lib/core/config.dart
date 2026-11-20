/// قيم الاتصال بـ Supabase. تُمرَّر وقت البناء عبر --dart-define
/// (في GitHub Actions تؤخذ من Secrets).
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
