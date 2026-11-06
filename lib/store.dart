// Local-first storage for EPS TOPIK Pro Pakistan.
// No server yet: accounts and progress live on the phone (SharedPreferences).
// OTP is a TESTING-ONLY prototype: the 6-digit code is generated on-device and
// shown in the app. No email/SMS provider is connected. Before any Play Store
// launch this MUST be replaced by real email/SMS delivery from a server, so
// the code is never shown in the app and cannot be requested by anyone who
// knows an identifier. Passwords are stored only as a salted hash (simple
// prototype hash — replace with a server-side verifier at launch).
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

String simpleHash(String s) {
  var h1 = 0xdeadbeef, h2 = 0x41c6ce57;
  for (var i = 0; i < s.length; i++) {
    final ch = s.codeUnitAt(i);
    h1 = (h1 ^ ch) * 2654435761 & 0xFFFFFFFF;
    h2 = (h2 ^ ch) * 1597334677 & 0xFFFFFFFF;
  }
  return '${h1.toRadixString(16)}${h2.toRadixString(16)}';
}

class AppStore {
  static final AppStore I = AppStore._();
  AppStore._();
  late SharedPreferences prefs;

  Future<void> init() async => prefs = await SharedPreferences.getInstance();

  // ---- language: 'english' | 'roman' | 'script' ----
  String get lang => prefs.getString('lang') ?? 'roman';
  Future<void> setLang(String v) => prefs.setString('lang', v);

  // ---- session ----
  String? get session => prefs.getString('session');
  Map<String, dynamic> get accounts {
    final raw = prefs.getString('accounts');
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> _saveAccounts(Map<String, dynamic> a) =>
      prefs.setString('accounts', jsonEncode(a));

  /// OTP prototype: returns the code so the UI can show it (testing only).
  String requestCode(String id) {
    final code = (100000 + Random().nextInt(900000)).toString();
    prefs.setString('otp_$id', simpleHash(code));
    prefs.setInt('otp_exp_$id', DateTime.now().millisecondsSinceEpoch + 10 * 60 * 1000);
    return code;
  }

  bool verifyCode(String id, String code) {
    final exp = prefs.getInt('otp_exp_$id') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch > exp) return false;
    return prefs.getString('otp_$id') == simpleHash(code);
  }

  Future<bool> register(String id, String name, String password, String code) async {
    if (!verifyCode(id, code)) return false;
    final a = accounts;
    if (a.containsKey(id)) return false;
    a[id] = {'name': name, 'pw': simpleHash(id + password), 'guest': false};
    await _saveAccounts(a);
    await prefs.setString('session', id);
    return true;
  }

  Future<bool> login(String id, String password) async {
    final a = accounts;
    if (!a.containsKey(id)) return false;
    if (a[id]['pw'] != simpleHash(id + password)) return false;
    await prefs.setString('session', id);
    return true;
  }

  Future<void> logout() => prefs.remove('session');

  Future<void> continueAsGuest() async {
    final id = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final a = accounts;
    a[id] = {'name': 'Guest', 'pw': '', 'guest': true};
    await _saveAccounts(a);
    await prefs.setString('session', id);
  }

  String get currentName {
    final s = session;
    if (s == null) return '';
    return accounts[s]?['name'] ?? '';
  }

  bool get isGuest {
    final s = session;
    if (s == null) return false;
    return accounts[s]?['guest'] == true;
  }

  Future<bool> changePassword(String current, String next) async {
    final s = session;
    if (s == null) return false;
    final a = accounts;
    if (a[s]['pw'] != simpleHash(s + current)) return false;
    a[s]['pw'] = simpleHash(s + next);
    await _saveAccounts(a);
    return true;
  }

  Future<bool> resetPassword(String id, String code, String next) async {
    if (!verifyCode(id, code)) return false;
    final a = accounts;
    if (!a.containsKey(id)) return false;
    a[id]['pw'] = simpleHash(id + next);
    await _saveAccounts(a);
    await logout();
    return true;
  }

  Future<void> deleteAccount(String password) async {
    final s = session;
    if (s == null) return;
    final a = accounts;
    if (a[s]['guest'] != true && a[s]['pw'] != simpleHash(s + password)) {
      throw Exception('Wrong password');
    }
    a.remove(s);
    await _saveAccounts(a);
    await prefs.remove('session');
    await prefs.remove('progress_$s');
  }

  // ---- progress, per account ----
  Map<String, dynamic> get progress {
    final s = session;
    if (s == null) return {};
    final raw = prefs.getString('progress_$s');
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> saveProgress(Map<String, dynamic> p) async {
    final s = session;
    if (s == null) return;
    await prefs.setString('progress_$s', jsonEncode(p));
  }

  Future<void> setDone(String key, bool done) async {
    final p = progress;
    final doneList = List<String>.from(p['done'] ?? []);
    if (done && !doneList.contains(key)) doneList.add(key);
    if (!done) doneList.remove(key);
    p['done'] = doneList;
    await saveProgress(p);
  }

  bool isDone(String key) => (progress['done'] as List? ?? []).contains(key);

  Future<void> setWord(String word, String status) async {
    final p = progress;
    final words = Map<String, dynamic>.from(p['words'] ?? {});
    words[word] = status;
    p['words'] = words;
    await saveProgress(p);
  }

  Future<void> logStudyDay() async {
    final p = progress;
    final days = List<String>.from(p['days'] ?? []);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (!days.contains(today)) days.add(today);
    p['days'] = days;
    await saveProgress(p);
  }

  Future<void> addMock(int listening, int reading,
      {String difficulty = 'basic', int secondsUsed = 0}) async {
    final p = progress;
    final mocks = List<Map<String, dynamic>>.from(
        (p['mocks'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    mocks.add({
      'l': listening,
      'r': reading,
      'date': DateTime.now().toIso8601String(),
      'd': difficulty,
      'secs': secondsUsed,
    });
    p['mocks'] = mocks;
    await saveProgress(p);
  }

  Future<void> resetProgress() async {
    final p = progress;
    p['done'] = [];
    p['words'] = {};
    p['days'] = [];
    p['mocks'] = [];
    p['level'] = 1;
    await saveProgress(p);
  }

  int get level => progress['level'] ?? 1;
  Future<void> setLevel(int v) async {
    final p = progress;
    p['level'] = v;
    await saveProgress(p);
  }
}

/// UI strings in the three explanation languages.
/// 'script' = Urdu written in Urdu script (Jameel Noori Nastaleeq / Noto
/// Nastaliq Urdu fallback — see pubspec fonts; if the font file is absent
/// the system Nastaliq is used).
String t(String lang, String key) {
  const en = {
    'home': 'Home', 'learn': 'Learn', 'practice': 'Practice', 'mock': 'Mock Test',
    'tutor': 'Voice Tutor', 'settings': 'Settings', 'back': 'Back',
    'startLearning': 'Start learning', 'freeTitle': 'No academy fee. Learn Korean free — on your own.',
    'freeSub': 'If you cannot pay academy fees, this app is for you: learn on your own, step by step, from zero to test-ready.',
    'notebookLine': 'Free — no academy fee. Just buy a notebook and a pen, a small expense.',
    'fresh': 'Fresh syllabus — the old one no longer matches the test',
    'freshBody': 'Old syllabus books stopped being used for EPS-TOPIK tests from 1 August 2025. This app follows the new HRD Korea Standard Korean Textbook (2024 revised edition). Syllabus updated time to time.',
    'login': 'Login', 'register': 'Register', 'guest': 'Continue as Guest',
    'logout': 'Logout', 'language': 'Explanation language',
    'hangul': 'Hangul — Korean letters', 'vocab': 'Vocabulary', 'grammar': 'Grammar',
    'course': 'Course — Units 1–60', 'games': 'Games — play & learn',
    'skillTest': 'Skill Test (Round 2)', 'emergency': 'Emergency Korean phrases',
    'lifeWork': 'Life and Work in Korea', 'culture': 'Korean culture & manners',
    'docs': 'Document & departure checklist', 'notebook': 'Notebook Time',
    'speakTest': 'Speak Test', 'mockTitle': 'Mock Test — 40 questions, 50 minutes, 100 points',
    'passing': 'Passing floor: 60/100 for all sectors. Pakistan 2026 merit: 82.5/100 (reported — check the latest OEC notice).',
    'askLang': 'Ask in your own language — Pashto, Sindhi, Saraiki, Punjabi, Urdu, English. Speak your question, hear the Korean answer.',
  };
  const roman = {
    'home': 'Ghar', 'learn': 'Seekho', 'practice': 'Mashq', 'mock': 'Mock Test',
    'tutor': 'Ustaad', 'settings': 'Settings', 'back': 'Wapas',
    'startLearning': 'Start learning', 'freeTitle': 'Koi academy fee nahi. Korean muft seekho — apne tor par.',
    'freeSub': 'Agar tum academy ki fee nahi de sakte, ye app tumhare liye hai: apne tor par seekho, qadam ba qadam, zero se test-ready tak.',
    'notebookLine': 'Muft — koi academy fee nahi. Bas ek notebook aur ek pen khareed lo — sirf yehi chhota sa kharcha hai, aur kuch nahi.',
    'fresh': 'Fresh syllabus — purana ab test se match nahi karta',
    'freshBody': 'Purane syllabus ki kitabein 1 August 2025 se EPS-TOPIK test mein istemal hona band ho gayi hain. Ye app NAYA syllabus parhati hai: HRD Korea ki Standard Korean Textbook (2024 revised edition). Syllabus waqt ke saath update hota hai.',
    'login': 'Login', 'register': 'Register', 'guest': 'Guest ke tor par jaari rakhein',
    'logout': 'Logout', 'language': 'Samjhane ki zuban',
    'hangul': 'Hangul — Korean haroof', 'vocab': 'Vocabulary', 'grammar': 'Grammar',
    'course': 'Course — Units 1–60', 'games': 'Games — khelo aur seekho',
    'skillTest': 'Skill Test (Round 2)', 'emergency': 'Emergency Korean jumlay',
    'lifeWork': 'Korea mein zindagi aur kaam', 'culture': 'Korean culture aur tameez',
    'docs': 'Document aur departure checklist', 'notebook': 'Notebook Time',
    'speakTest': 'Speak Test', 'mockTitle': 'Mock Test — 40 sawal, 50 minute, 100 points',
    'passing': 'Passing floor: 60/100 sab sectors ke liye. Pakistan 2026 merit: 82.5/100 (reported — latest OEC notice check karein).',
    'askLang': 'Apni zuban mein poochhein — Pashto, Sindhi, Saraiki, Punjabi, Urdu, English. Sawal bolein, Korean jawab sunein.',
  };
  const script = {
    'home': 'گھر', 'learn': 'سیکھو', 'practice': 'مشق', 'mock': 'موک ٹیسٹ',
    'tutor': 'استاد', 'settings': 'سیٹنگز', 'back': 'واپس',
    'startLearning': 'سیکھنا شروع کریں', 'freeTitle': 'کوئی اکیڈمی فیس نہیں۔ کورین مفت سیکھیں — اپنے طور پر۔',
    'freeSub': 'اگر آپ اکیڈمی کی فیس نہیں دے سکتے، یہ ایپ آپ کے لیے ہے: اپنے طور پر سیکھیں، قدم بہ قدم، صفر سے ٹیسٹ تک۔',
    'notebookLine': 'مفت — کوئی اکیڈمی فیس نہیں۔ بس ایک نوٹ بک اور ایک قلم خرید لیں — صرف یہی چھوٹا سا خرچہ ہے، اور کچھ نہیں۔',
    'fresh': 'نیا نصاب — پرانا اب ٹیسٹ سے میل نہیں کھاتا',
    'freshBody': 'پرانے نصاب کی کتابیں 1 اگست 2025 سے EPS-TOPIK ٹیسٹ میں استعمال ہونا بند ہو گئی ہیں۔ یہ ایپ نیا نصاب پڑھاتی ہے: HRD Korea کی Standard Korean Textbook (2024 revised edition)۔ نصاب وقت کے ساتھ اپڈیٹ ہوتا ہے۔',
    'login': 'لاگ ان', 'register': 'رجسٹر', 'guest': 'مہمان کے طور پر جاری رکھیں',
    'logout': 'لاگ آؤٹ', 'language': 'سمجھانے کی زبان',
    'hangul': 'ہنگل — کورین حروف', 'vocab': 'الفاظ', 'grammar': 'گرامر',
    'course': 'کورس — یونٹ 1–60', 'games': 'کھیل — کھیلو اور سیکھو',
    'skillTest': 'سکل ٹیسٹ (راؤنڈ 2)', 'emergency': 'ایمرجنسی کورین جملے',
    'lifeWork': 'کوریا میں زندگی اور کام', 'culture': 'کورین ثقافت اور آداب',
    'docs': 'دستاویز اور روانگی چیک لسٹ', 'notebook': 'نوٹ بک ٹائم',
    'speakTest': 'بولنے کا ٹیسٹ', 'mockTitle': 'موک ٹیسٹ — 40 سوال، 50 منٹ، 100 نمبر',
    'passing': 'پاسنگ فلور: 60/100 تمام شعبوں کے لیے۔ پاکستان 2026 میرٹ: 82.5/100 (رپورٹ شدہ — تازہ ترین OEC نوٹس چیک کریں)۔',
    'askLang': 'اپنی زبان میں پوچھیں — پشتو، سندھی، سرائیکی، پنجابی، اردو، انگریزی۔ سوال بولیں، کورین جواب سنیں۔',
  };
  final map = lang == 'english' ? en : (lang == 'script' ? script : roman);
  return map[key] ?? key;
}
