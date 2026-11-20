# رفيقي القرآني — المرحلة 1

تطبيق Flutter + Supabase. المرحلة 1 تشمل: الحساب، إعداد الورد اليومي (الوقت، 3–5 آيات، أيام الالتزام، نقطة البداية)،
عرض آيات ورد اليوم، الاستماع للتلاوة (آية بآية)، وتسجيل إتمام الورد.
**ليست في هذه المرحلة:** التذكيرات (المرحلة 2)، التسميع والتقييم (المرحلة 3)، التفسير والأحاديث (المرحلة 4).

## مصدر القرآن
نص الآيات (الرسم العثماني) والصوت (مشاري العفاسي) يُجلبان من Al-Quran Cloud API (`api.alquran.cloud`) ويُحفظان على الجهاز بعد أول تحميل.
لا يوجد في المشروع أي نص قرآني مكتوب يدوياً أو مولَّد.
أول فتح لسورة يحتاج إنترنت.

## خطوات التشغيل

### 1) إعداد Supabase
1. أنشئ مشروعاً على supabase.com.
2. SQL Editor ← New query ← الصق محتوى `supabase/migrations/0001_init.sql` ← Run.
3. (اختياري للتجربة السريعة) Authentication ← Providers ← Email ← أوقف "Confirm email"، وإلا ستصلك رسالة تفعيل عند إنشاء الحساب.
4. Project Settings ← API: انسخ **Project URL** و **anon public key**.

### 2) GitHub
1. أنشئ مستودعاً جديداً وارفع كل محتويات هذا المجلد (بما فيه مجلد `.github`).
   إن لم يظهر `.github` عند الرفع: Add file ← Create new file، واكتب الاسم `.github/workflows/build-apk.yml` والصق محتوى الملف.
2. Settings ← Secrets and variables ← Actions ← New repository secret، أضف:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. تبويب Actions ← Build Android APK ← Run workflow (أو يعمل تلقائياً مع كل push على main).
4. بعد نجاح التشغيل: افتح التشغيل ← Artifacts ← نزّل `rafiqi-quranic-apk` ← فك الضغط ← ثبّت `app-release.apk`.

## هيكل المشروع
```
lib/
  core/        الإعدادات، الثيم، providers
  data/quran/  جلب نص القرآن والصوت وتخزينه محلياً
  data/wird/   نماذج الورد، منطق التخطيط، التخزين في Supabase
  features/    auth, wird_setup, home, mushaf
supabase/migrations/   قاعدة البيانات وسياسات الأمان (RLS)
test/                  اختبارات منطق الورد وتحليل الرد
```

## ملاحظات
- إن بقي في السورة أقل من عدد الآيات اليومي، يقتصر ورد اليوم على المتبقي ثم يبدأ اليوم التالي من السورة التالية.
- زر "أتممت الورد" يدوي في هذه المرحلة؛ في المرحلة 3 سيُربط بنتيجة التسميع.
- الـ APK موقَّع بمفتاح debug، مناسب للتجربة والتوزيع الداخلي وليس للنشر على Google Play.
