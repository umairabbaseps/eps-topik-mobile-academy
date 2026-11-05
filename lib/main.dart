import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'data.dart';
import 'store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.I.init();
  runApp(const EpsApp());
}

final FlutterTts tts = FlutterTts();
Future<void> speak(String text, {String lang = 'ko-KR', double rate = 0.45}) async {
  try {
    await tts.setLanguage(lang);
    await tts.setSpeechRate(rate);
    await tts.setVolume(1.0);
    await tts.speak(text);
  } catch (_) {}
}

Future<void> speakSlowThenNormal(String text) async {
  await speak(text, rate: 0.35);
  await Future.delayed(const Duration(milliseconds: 900));
  await speak(text, rate: 0.6);
}

class EpsApp extends StatefulWidget {
  const EpsApp({super.key});
  @override
  State<EpsApp> createState() => _EpsAppState();
}

class _EpsAppState extends State<EpsApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EPS TOPIK Pro Pakistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B2C6B), primary: const Color(0xFF0B2C6B), secondary: const Color(0xFF00897B), tertiary: const Color(0xFFFF7043)),
        scaffoldBackgroundColor: const Color(0xFFF2F5FA),
        fontFamily: AppStore.I.lang == 'script' ? 'NotoNastaliq' : null,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0B2C6B), foregroundColor: Colors.white, centerTitle: false),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B2C6B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
        cardTheme: const CardThemeData(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
      ),
      home: const RootPage(),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int tab = 0;
  final List<String> trail = [];
  String get lang => AppStore.I.lang;
  String tr(String k) => t(lang, k);

  void goTab(int i, String name) {
    setState(() {
      tab = i;
      trail.add(name);
    });
  }

  void goHome() => setState(() {
        tab = 0;
        trail.clear();
      });

  void goBack() => setState(() {
        if (trail.isNotEmpty) trail.removeLast();
        if (trail.isEmpty) tab = 0;
      });

  @override
  Widget build(BuildContext context) {
    if (AppStore.I.session == null) return AuthScreen(onDone: () => setState(() {}));
    final pages = [
      HomePage(onGo: goTab, onStart: () => goTab(1, 'Learn')),
      const LearnPage(),
      const PracticePage(),
      const MockPage(),
      const TutorPage(),
      const GamesPage(),
      const SettingsPage(),
    ];
    final titles = [tr('home'), tr('learn'), tr('practice'), tr('mock'), tr('tutor'), 'Games', tr('settings')];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: tr('back'),
          onPressed: tab == 0 && trail.isEmpty ? null : goBack,
        ),
        title: Text(titles[tab]),
        actions: [
          IconButton(icon: const Icon(Icons.home), tooltip: tr('home'), onPressed: goHome),
        ],
      ),
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0B2C6B),
        onTap: (i) => setState(() {
          tab = i;
          trail.clear();
        }),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: tr('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.school), label: tr('learn')),
          BottomNavigationBarItem(icon: const Icon(Icons.edit), label: tr('practice')),
          BottomNavigationBarItem(icon: const Icon(Icons.timer), label: tr('mock')),
          BottomNavigationBarItem(icon: const Icon(Icons.mic), label: tr('tutor')),
          const BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Games'),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: tr('settings')),
        ],
      ),
    );
  }
}

// ---------------- Auth ----------------
class AuthScreen extends StatefulWidget {
  final VoidCallback onDone;
  const AuthScreen({super.key, required this.onDone});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final idC = TextEditingController();
  final nameC = TextEditingController();
  final pwC = TextEditingController();
  final codeC = TextEditingController();
  String mode = 'login'; // login | register | reset
  String? shownCode;
  String msg = '';

  Future<void> doGuest() async {
    await AppStore.I.continueAsGuest();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStore.I.lang;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Image.asset('assets/logo.png', height: 180),
          const SizedBox(height: 8),
          Text('EPS TOPIK Pro Pakistan', textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0B2C6B))),
          const Text('Korea Pakka!', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 12),
          // language pills
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (final l in ['english', 'roman', 'script'])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(l == 'english' ? 'English' : (l == 'roman' ? 'Roman Urdu' : 'اردو')),
                  selected: lang == l,
                  onSelected: (_) async {
                    await AppStore.I.setLang(l);
                    setState(() {});
                  },
                ),
              ),
          ]),
          const SizedBox(height: 12),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(t(lang, 'freeTitle') + '\n' + t(lang, 'notebookLine'),
                  style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(t(lang, 'askLang'), style: const TextStyle(fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),
          if (mode == 'register')
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name (optional — leave empty for "Student")', border: OutlineInputBorder())),
          if (mode == 'register') const SizedBox(height: 8),
          TextField(controller: idC, decoration: const InputDecoration(labelText: 'Email or mobile number', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          if (mode != 'reset')
            TextField(controller: pwC, obscureText: true, decoration: const InputDecoration(labelText: 'Password (6+ characters)', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          if (mode != 'login') ...[
            Row(children: [
              Expanded(child: TextField(controller: codeC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '6-digit code', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (idC.text.trim().isEmpty) { setState(() => msg = 'Enter email or mobile first.'); return; }
                  setState(() { shownCode = AppStore.I.requestCode(idC.text.trim()); msg = ''; });
                },
                child: const Text('Get code'),
              ),
            ]),
            if (shownCode != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                color: Colors.amber.shade100,
                child: Text('Prototype note: no code was really sent by email/SMS yet. Your test code is: $shownCode\n(Testing only — before Play Store launch this will be replaced by real email/SMS delivery.)'),
              ),
            const SizedBox(height: 8),
          ],
          if (msg.isNotEmpty) Text(msg, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () async {
              final id = idC.text.trim();
              if (mode == 'login') {
                final ok = await AppStore.I.login(id, pwC.text);
                if (ok) { widget.onDone(); } else { setState(() => msg = 'Wrong email/mobile or password.'); }
              } else if (mode == 'register') {
                if (pwC.text.length < 6) { setState(() => msg = 'Password must be 6+ characters.'); return; }
                final name = nameC.text.trim().isEmpty ? 'Student' : nameC.text.trim();
                final ok = await AppStore.I.register(id, name, pwC.text, codeC.text.trim());
                if (ok) { widget.onDone(); } else { setState(() => msg = 'Wrong code, or this account already exists.'); }
              } else {
                final ok = await AppStore.I.resetPassword(id, codeC.text.trim(), pwC.text.isEmpty ? '123456' : pwC.text);
                // reset needs a new password: reuse pw field via dialog
                if (ok) { setState(() { mode = 'login'; msg = 'Password reset. Please log in.'; }); }
                else { setState(() => msg = 'Wrong code or no such account.'); }
              }
            },
            child: Text(mode == 'login' ? t(lang, 'login') : (mode == 'register' ? t(lang, 'register') : 'Reset password')),
          ),
          TextButton(
            onPressed: () => setState(() => mode = mode == 'login' ? 'register' : 'login'),
            child: Text(mode == 'login' ? 'No account? Register' : 'Have an account? Login'),
          ),
          TextButton(
            onPressed: () => setState(() => mode = 'reset'),
            child: const Text('Forgot password?'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: doGuest,
            child: Text(t(lang, 'guest')),
          ),
          const SizedBox(height: 8),
          const Text('Guest progress stays on this phone only — register to keep it on any mobile.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }
}

// ---------------- Home ----------------
class HomePage extends StatefulWidget {
  final void Function(int, String) onGo;
  final VoidCallback onStart;
  const HomePage({super.key, required this.onGo, required this.onStart});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final lang = AppStore.I.lang;
    final store = AppStore.I;
    final words = (store.progress['words'] as Map? ?? {}).length;
    final days = (store.progress['days'] as List? ?? []).length;
    final mocks = (store.progress['mocks'] as List? ?? []).length;
    final navy = const Color(0xFF0B2C6B);
    final teal = const Color(0xFF00897B);
    return ListView(padding: const EdgeInsets.all(16), children: [
      // HERO — gradient, logo, progress
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0B2C6B), Color(0xFF1565C0), Color(0xFF00897B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/logo.png', height: 72, width: 72, fit: BoxFit.cover)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('EPS TOPIK Pro Pakistan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Korea Pakka! 🇰🇷🇵🇰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFFE082))),
              Text('${store.currentName} • ${store.isGuest ? 'Guest — on this phone only' : 'Account saved'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ])),
          ]),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (store.level / 5).clamp(0.0, 1.0), minHeight: 10, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation(Color(0xFFFFCA28)))),
          const SizedBox(height: 6),
          Text('Level ${store.level} of 5  •  $words words learned  •  $days study days  •  $mocks mock tests', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF7043), minimumSize: const Size.fromHeight(54)),
            onPressed: widget.onStart,
            child: Text('▶  ${t(lang, 'startLearning')} — Lesson 1, Korean letters', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
      const SizedBox(height: 14),
      // FREE + FRESH — two compact cards side by side
      Row(children: [
        Expanded(child: _miniCard(Colors.green, '🎓 FREE', t(lang, 'freeTitle'), t(lang, 'notebookLine'))),
        const SizedBox(width: 10),
        Expanded(child: _miniCard(Colors.orange, '📖 Fresh syllabus', t(lang, 'fresh'), 'New HRD books, 2024 revised, in force 1 Aug 2025.')),
      ]),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFCA28), width: 2)),
        child: Row(children: [
          const Text('🎯', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(child: Text(t(lang, 'passing'), style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
      ),
      const SizedBox(height: 16),
      _sectionHead('🚀', 'Your learning path', navy),
      GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.35,
        children: [
          _gridCard(teal, '🎤', t(lang, 'tutor'), 'Ask in Pashto, Sindhi, Saraiki, Punjabi, Urdu, English', () => widget.onGo(4, 'Tutor')),
          _gridCard(navy, '📚', t(lang, 'course'), 'Hangul + Units 1–60, new syllabus', () => widget.onGo(1, 'Learn')),
          _gridCard(const Color(0xFF6A1B9A), '🎮', t(lang, 'games'), 'Listen & Tap, Match, Memory, Quiz', () => widget.onGo(5, 'Games')),
          _gridCard(const Color(0xFFEF6C00), '🎙️', t(lang, 'speakTest'), 'Listen, repeat, speak — honest score', () => widget.onGo(2, 'Practice')),
        ],
      ),
      const SizedBox(height: 16),
      _sectionHead('🏆', 'Test-ready', const Color(0xFFC62828)),
      _homeTile(context, '📝 Mock Test — Basic & Expert', '40 questions, 50 min, 100 points. Expert = real test level, merit 82.5.', () => widget.onGo(3, 'Mock')),
      _homeTile(context, '🛡 ${t(lang, 'skillTest')}', 'Physical 30 + interview 30 + skills 40. Below 60% means out. Total 205.', () => widget.onGo(1, 'Learn')),
      _homeTile(context, '🆘 ${t(lang, 'emergency')}', 'I am hurt • Please help me • Where is the toilet? — with sound.', () => widget.onGo(1, 'Learn')),
      const SizedBox(height: 16),
      _sectionHead('🌏', 'Life in Korea', teal),
      _homeTile(context, '🏭 ${t(lang, 'lifeWork')}', 'Minimum wage 2026: 10,320 KRW/hour. Rights, safety, helpline 1350, 119.', () => widget.onGo(1, 'Learn')),
      _homeTile(context, '📋 ${t(lang, 'docs')}', 'Passport, CNIC, medical, police character, OEC forms — tick each off.', () => widget.onGo(1, 'Learn')),
      const SizedBox(height: 16),
      _sectionHead('📅', '12-week self-study plan — 30 min a day', navy),
      Card(child: ExpansionTile(
        title: const Text('Weeks 1–12 — tap to open the plan', style: TextStyle(fontWeight: FontWeight.bold)),
        children: selfStudyPlan.map((w) => ListTile(leading: const Icon(Icons.check_circle_outline, color: Color(0xFF00897B)), title: Text(w[0], style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(w[1]))).toList(),
      )),
      const SizedBox(height: 10),
      const Text('Not affiliated with OEC or HRD Korea. Check the latest OEC notice at jobs.oec.gov.pk.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }

  Widget _sectionHead(String emoji, String title, Color c) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 20)), const SizedBox(width: 6), Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c))]),
  );

  Widget _miniCard(Color c, String title, String line1, String line2) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: c.withValues(alpha: 0.35))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 15)),
      const SizedBox(height: 4),
      Text(line1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      Text(line2, style: const TextStyle(fontSize: 12)),
    ]),
  );

  Widget _gridCard(Color c, String emoji, String title, String sub, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border(left: BorderSide(color: c, width: 5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: c, fontSize: 14)),
        Text(sub, style: const TextStyle(fontSize: 12)),
      ]),
    ),
  );

  Widget _homeTile(BuildContext context, String title, String sub, VoidCallback onTap) {
    return Card(child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(sub), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: onTap));
  }
}

// ---------------- Learn ----------------
class LearnPage extends StatefulWidget {
  const LearnPage({super.key});
  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String section = 'hangul';
  int vowelIdx = 0, consIdx = 0, buildIdx = 0, buildStage = 0;
  int notebookStep = 0;
  int vocabPage = 0;
  int? selectedUnit;
  int? selectedSkill;

  @override
  Widget build(BuildContext context) {
    final lang = AppStore.I.lang;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Wrap(spacing: 8, children: [
        for (final s in ['hangul', 'vocab', 'course', 'skill', 'emergency', 'life', 'docs', 'notebook'])
          ChoiceChip(
            label: Text(s == 'hangul' ? t(lang, 'hangul') : s == 'vocab' ? t(lang, 'vocab') : s == 'course' ? t(lang, 'course') : s == 'skill' ? t(lang, 'skillTest') : s == 'emergency' ? t(lang, 'emergency') : s == 'life' ? t(lang, 'lifeWork') : s == 'docs' ? t(lang, 'docs') : t(lang, 'notebook')),
            selected: section == s,
            onSelected: (_) => setState(() => section = s),
          ),
      ]),
      const SizedBox(height: 12),
      if (section == 'hangul') _hangul(lang),
      if (section == 'vocab') _vocab(),
      if (section == 'course') _course(),
      if (section == 'skill') _skill(),
      if (section == 'emergency') _emergency(),
      if (section == 'life') _life(),
      if (section == 'docs') _docs(),
      if (section == 'notebook') _notebook(),
    ]);
  }

  Widget _hangul(String lang) {
    final v = vowels[vowelIdx];
    final c = consonants[consIdx];
    final b = wordBuilds[buildIdx];
    final stages = ['Letter: ${b[0]}', 'Part: ${b[1]}', 'Whole word: ${b[2]}', 'Meaning: ${b[3]} (${b[4]})'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('1) Full alphabets first — like A B C D', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Tap a letter to hear it. Vowels first, then consonants.'),
      const SizedBox(height: 8),
      Text('Vowels — Letter ${vowelIdx + 1} of 21', style: const TextStyle(fontWeight: FontWeight.bold)),
      Row(children: [
        Text(v[0], style: const TextStyle(fontSize: 64)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sound: ${v[1]}'), ElevatedButton(onPressed: () => speak(v[0]), child: const Text('🔊 Hear it'))]),
        const Spacer(),
        ElevatedButton(onPressed: () => setState(() => vowelIdx = (vowelIdx + 1) % vowels.length), child: const Text('Next →')),
      ]),
      const SizedBox(height: 8),
      Text('Consonants — Letter ${consIdx + 1} of 19', style: const TextStyle(fontWeight: FontWeight.bold)),
      Row(children: [
        Text(c[0], style: const TextStyle(fontSize: 64)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Sound: ${c[1]}'), ElevatedButton(onPressed: () => speak(c[0]), child: const Text('🔊 Hear it'))]),
        const Spacer(),
        ElevatedButton(onPressed: () => setState(() => consIdx = (consIdx + 1) % consonants.length), child: const Text('Next →')),
      ]),
      const Divider(height: 28),
      const Text('2) Word builder — how letters join into a word', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Example: S + T = "st", then "udy" comes and it becomes "study" — and this is its meaning. Same in Korean.'),
      const SizedBox(height: 8),
      Text('Stage ${buildStage + 1} of 4: ${stages[buildStage]}', style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 8),
      Row(children: [
        ElevatedButton(onPressed: () => speak(b[2]), child: const Text('🔊 Hear the whole word')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () => setState(() { buildStage = (buildStage + 1) % 4; }), child: const Text('Next step →')),
        const SizedBox(width: 8),
        TextButton(onPressed: () => setState(() { buildIdx = (buildIdx + 1) % wordBuilds.length; buildStage = 0; }), child: const Text('New word')),
      ]),
      const Divider(height: 28),
      const Text('Grammar — 2 points per unit (120 total). Each unit in the Course tab lists its grammar.', style: TextStyle(fontSize: 15)),
    ]);
  }

  Widget _vocab() {
    const pageSize = 20;
    final pages = (vocab.length / pageSize).ceil();
    final page = vocabPage.clamp(0, pages - 1);
    final items = vocab.sublist(page * pageSize, ((page + 1) * pageSize).clamp(0, vocab.length));
    return Column(children: [
      Text('Vocabulary — ${vocab.length} words, page ${page + 1} of $pages', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Text('Tap 🔊 to hear a word, tap ⭐ when you know it. Words are in order — finish one page, then go to the next.'),
      const SizedBox(height: 8),
      ...items.map((w) => Card(child: ListTile(
        title: Text('${w[0]}  •  ${w[1]}', style: const TextStyle(fontSize: 18)),
        subtitle: Text('${w[2]} — ${w[3]}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(w[0])),
          IconButton(icon: Icon(AppStore.I.progress['words']?[w[0]] == 'mastered' ? Icons.star : Icons.star_border),
              onPressed: () async { await AppStore.I.setWord(w[0], 'mastered'); setState(() {}); }),
        ]),
      ))),
      const SizedBox(height: 8),
      Wrap(spacing: 6, alignment: WrapAlignment.center, children: [
        ElevatedButton(onPressed: page > 0 ? () => setState(() => vocabPage = page - 1) : null, child: const Text('← Prev')),
        for (int i = 0; i < pages; i++)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: ChoiceChip(label: Text('${i + 1}'), selected: i == page, onSelected: (_) => setState(() => vocabPage = i))),
        ElevatedButton(onPressed: page < pages - 1 ? () => setState(() => vocabPage = page + 1) : null, child: const Text('Next →')),
      ]),
    ]);
  }

  Widget _course() {
    if (selectedUnit != null) {
      final u = units.firstWhere((e) => e.n == selectedUnit);
      final keyWords = vocab.sublist((u.n * 5) % vocab.length, ((u.n * 5) % vocab.length + 5).clamp(0, vocab.length));
      final bookLabel = u.book == 'P' ? 'Book 1 Preliminary — Hangul' : (u.book == '1' ? 'Book 1 — Daily life' : 'Book 2 — Workplace');
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TextButton.icon(icon: const Icon(Icons.arrow_back), label: const Text('All units'), onPressed: () => setState(() => selectedUnit = null)),
          const Spacer(),
          TextButton(onPressed: () async { await AppStore.I.setDone('unit_${u.n}', true); setState(() {}); }, child: const Text('✓ Mark done')),
        ]),
        Text('Unit ${u.n} — ${u.en}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        Text(u.ko, style: const TextStyle(fontSize: 18)),
        Text(bookLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
        const SizedBox(height: 10),
        _lessonBox('🎯 What you will learn', 'In this unit you learn about ${u.en.toLowerCase()}. Read the Korean title, learn the grammar below, learn the 5 key words, say each one aloud, then write them in your notebook.'),
        _lessonBox('📖 Grammar', '${u.grammar} — use it in a short sentence. Example: say the Korean word, then make a sentence with it. Your teacher in the app: tap 🔊 on every word to hear it slow, then normal.'),
        _lessonBox('🗣️ Example sentences', u.n == 0
            ? '안녕하세요. — Hello.\n제 이름은 …입니다. — My name is …\n저는 파키스탄 사람이에요. — I am from Pakistan.'
            : u.book == '1'
                ? '이것은 ${u.ko}입니다. — This is about ${u.en.toLowerCase()}.\n${u.ko}에 대해 이야기해요. — Let us talk about ${u.en.toLowerCase()}.'
                : '직장에서 ${u.ko}이/가 중요해요. — At work, ${u.en.toLowerCase()} is important.\n안전하게 일하세요. — Work safely.'),
        _lessonBox('🔑 5 key words in this unit', ''),
        ...keyWords.map((w) => Card(child: ListTile(title: Text('${w[0]} • ${w[1]}', style: const TextStyle(fontSize: 17)), subtitle: Text('${w[2]} — ${w[3]}'), trailing: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(w[0]))))),
        const SizedBox(height: 8),
        const Text('✏️ Notebook task: write the 5 words above 5 times each, then write one sentence of your own. Tap “I wrote it” in Notebook Time when you finish.', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => speakSlowThenNormal(u.ko), child: const Text('🔊 Hear the unit title in Korean')),
      ]);
    }
    return Column(children: [
      const Text('New syllabus — HRD Korea Standard Korean Textbook (2024 revised edition), in force from 1 Aug 2025. Official books are free from HRD Korea: hrdkorea.or.kr / epstopik.hrdkorea.or.kr', style: TextStyle(fontSize: 14)),
      const SizedBox(height: 8),
      const Text('Tap any unit to open its lesson — what to learn, grammar, key words, example sentences and a notebook task.', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...units.map((u) => Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFF0B2C6B), child: Text('${u.n}', style: const TextStyle(color: Colors.white))),
        title: Text('Unit ${u.n} — ${u.en}'),
        subtitle: Text('${u.ko}\nGrammar: ${u.grammar} • Book ${u.book == 'P' ? '1 Preliminary' : u.book}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: Icon(AppStore.I.isDone('unit_${u.n}') ? Icons.check_circle : Icons.check_circle_outline, color: Colors.green), onPressed: () async { await AppStore.I.setDone('unit_${u.n}', !AppStore.I.isDone('unit_${u.n}')); setState(() {}); }),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ]),
        onTap: () => setState(() => selectedUnit = u.n),
      ))),
    ]);
  }

  Widget _lessonBox(String title, String body) => Card(
    color: const Color(0xFFE8F5F3),
    child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      if (body.isNotEmpty) Text(body),
    ])),
  );

  Widget _skill() {
    if (selectedSkill != null) {
      final s = skillTasks[selectedSkill!];
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextButton.icon(icon: const Icon(Icons.arrow_back), label: const Text('All skill tasks'), onPressed: () => setState(() => selectedSkill = null)),
        Text(s[0], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _lessonBox('🎯 What the examiner checks', 'Speed, accuracy and safety. Do the job in the right order, do not rush, do not skip a step. A safe, tidy worker scores higher than a fast, careless one.'),
        _lessonBox('📋 Steps — do them in this order', '1. Read the task and check your tools.\n2. ${s[1]}\n3. Check your work before you finish.\n4. Clean up and put tools back.\n5. Tell the examiner you are finished.'),
        _lessonBox('⚠️ Safety', 'Wear your helmet, gloves and safety shoes. If a tool feels wrong or a machine makes a strange sound, stop and tell the examiner. Never take a shortcut with safety.'),
        _lessonBox('🗣️ Say it in Korean', '시작하겠습니다. — I will start.\n끝났습니다. — I have finished.\n확인했습니다. — I have checked it.'),
        ElevatedButton(onPressed: () => speakSlowThenNormal('시작하겠습니다. 끝났습니다.'), child: const Text('🔊 Hear the Korean phrases')),
        const SizedBox(height: 12),
        const Text('Interview practice — say it aloud, then tap to hear the model answer:'),
        _qa('Tell me about yourself', '저는 파키스탄 사람이에요. 저는 열심히 일해요.'),
        _qa('Why do you want to work in Korea?', '한국에서 일하고 싶어요. 가족을 돕고 싶어요.'),
        _qa('What will you do if the work is hard?', '포기하지 않아요. 열심히 배울 거예요.'),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Round 2 Skill Test — compulsory', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Physical 30 + Interview 30 + Basic skills 40. Below 60% means out, whatever your language score. +5 Job Capacity points. Total 205.'),
      const SizedBox(height: 8),
      const Text('Tap any task to open its help: what the examiner checks, steps in order, safety, and Korean phrases.', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...skillTasks.asMap().entries.map((e) => Card(child: ListTile(
        leading: const Icon(Icons.build, color: Color(0xFFEF6C00)),
        title: Text(e.value[0]), subtitle: Text(e.value[1]),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => setState(() => selectedSkill = e.key),
      ))),
      const SizedBox(height: 8),
      const Text('Interview practice — say it aloud, then tap to hear the model answer:'),
      _qa('Tell me about yourself', '저는 파키스탄 사람이에요. 저는 열심히 일해요.'),
      _qa('Why do you want to work in Korea?', '한국에서 일하고 싶어요. 가족을 돕고 싶어요.'),
      _qa('What will you do if the work is hard?', '포기하지 않아요. 열심히 배울 거예요.'),
    ]);
  }

  Widget _qa(String q, String a) => Card(child: ListTile(
        title: Text(q),
        subtitle: Text(a),
        trailing: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(a)),
      ));

  Widget _emergency() {
    return Column(children: emergency.map((e) => Card(child: ListTile(
      title: Text('${e[0]}  •  ${e[1]}', style: const TextStyle(fontSize: 18)),
      subtitle: Text('${e[2]} — ${e[3]}'),
      trailing: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(e[0])),
    ))).toList());
  }

  Widget _life() {
    return const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Life and Work in Korea', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('• Work: factory, farm and other E-9 workplaces. Normal day, working hours, breaks, safety gear. Winter is cold, summer is hot and humid.\n• Labour rights: minimum wage 2026 is 10,320 KRW per hour. Overtime pay, weekly rest day, paid holidays, contract, salary paid on time. Nobody may take your passport. You may change workplace in allowed cases. You may complain.\n• Safety: safety signs, PPE (helmet, gloves, goggles), what to do if hurt — tell your boss, call 119.\n• Help: employer, OEC, HRD Korea EPS Center, Korean labour helpline 1350, emergency 119. Do not pay any agent.\n• Life: housing (dormitory), food, transport, weather, manners at work, bank account.\n• Do NOT: do not overstay, do not work outside your allowed job, do not trust agents who promise a job for money.\n• Based on Units 57–60: EPS System, Labor Standards Act, Immigration Act, Worker Insurance. Check the latest OEC / HRD Korea notice — rules can change. jobs.oec.gov.pk'),
      SizedBox(height: 12),
      Text('Korean culture & manners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      SizedBox(height: 6),
    ]);
  }

  Widget _docs() {
    return Column(children: docChecklist.map((d) => Card(child: CheckboxListTile(
      title: Text(d),
      value: AppStore.I.isDone('doc_$d'),
      onChanged: (v) async { await AppStore.I.setDone('doc_$d', v ?? false); setState(() {}); },
    ))).toList());
  }

  Widget _notebook() {
    final steps = [
      ['물', 'ㅁ + ㅜ + ㄹ = 물', 'Water — paani. Write the whole word 5 times.'],
      ['밥', 'ㅂ + ㅏ + ㅂ = 밥', 'Rice / meal — khana. Write the whole word 5 times.'],
      ['사람', 'ㅅ + ㅏ + ㄹ + ㅏ + ㅁ = 사람', 'Person — aadmi. Write the whole word 5 times.'],
      ['물 주세요', 'ㅈ+ㅜ=주 · ㅅ+ㅔ=세 · ㅇ+ㅛ=요', 'Please give me water. Write the whole sentence 3 times.'],
    ];
    final s = steps[notebookStep];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Notebook Time — step ${notebookStep + 1} of 4 (Level ${AppStore.I.level})', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Open your notebook now. Write this 5 times. Just buy a notebook and a pen — a small expense.'),
      const SizedBox(height: 8),
      Text(s[0], style: const TextStyle(fontSize: 48)),
      Text(s[1], style: const TextStyle(fontSize: 16)),
      Text(s[2], style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 8),
      Row(children: [
        ElevatedButton(onPressed: () => speakSlowThenNormal(s[0]), child: const Text('🔊 Slow, then normal')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () => setState(() => notebookStep = (notebookStep + 1) % steps.length), child: const Text('Next →')),
      ]),
      const SizedBox(height: 12),
      Card(
        color: const Color(0xFFFFF3E0),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('✏️ Your Korean sentence to write', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(notebookSentence[0], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text(notebookSentence[1], style: const TextStyle(fontSize: 14)),
            Text('${notebookSentence[2]} — ${notebookSentence[3]}', style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
            Row(children: [
              ElevatedButton(onPressed: () => speakSlowThenNormal(notebookSentence[0]), child: const Text('🔊 Hear the sentence')),
              const SizedBox(width: 8),
              const Expanded(child: Text('Write this whole sentence 3 times in your notebook. As your level rises, Notebook Time gets longer: Levels 2–3 a full sentence, Level 4 a longer sentence, Level 5 a two-line dialogue.')),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Photo of your notebook page, what you just wrote (optional)\nTake a photo of your own writing, for you only, optional, never checked or graded.'))),
      ElevatedButton(onPressed: () async { await AppStore.I.logStudyDay(); setState(() {}); }, child: const Text('✓ I wrote it')),
    ]);
  }
}

// ---------------- Practice (Speak Test + timer quiz) ----------------
class PracticePage extends StatefulWidget {
  const PracticePage({super.key});
  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  int q = 0, score = 0, tries = 0, step = 0;
  String feedback = '';
  String heardText = '';
  bool done = false;

  // Honest similarity: Hangul exact/contains, or edit distance <= 1-2.
  bool _isClose(String heard, String target) {
    String norm(String x) => x.replaceAll(RegExp(r'[\s\.\?\!]+'), '').trim();
    final h = norm(heard), t = norm(target);
    if (h.isEmpty) return false;
    if (h == t || h.contains(t) || t.contains(h)) return true;
    // Levenshtein distance, small allowance for short words.
    int dist(String a, String b) {
      final d = List.generate(a.length + 1, (i) => List.generate(b.length + 1, (j) => i == 0 ? j : (j == 0 ? i : 0)));
      for (var i = 1; i <= a.length; i++) {
        for (var j = 1; j <= b.length; j++) {
          d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)].reduce((x, y) => x < y ? x : y);
        }
      }
      return d[a.length][b.length];
    }
    return dist(h, t) <= (t.length <= 3 ? 1 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final w = vocab[q % vocab.length];
    const steps = ['1. Listen', '2. Repeat', '3. Speak on mic', '4. Honest result', '5. Listen again'];
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Practice — Speak Test', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0B2C6B))),
      const Text('How to practise, like a teacher teaches it. Follow the steps in order — do not skip Step 1.'),
      const SizedBox(height: 10),
      Wrap(spacing: 6, children: steps.asMap().entries.map((e) => ChoiceChip(
        label: Text(e.value, style: const TextStyle(fontSize: 12)),
        selected: step == e.key,
        onSelected: (_) => setState(() => step = e.key),
      )).toList()),
      const SizedBox(height: 10),
      Card(
        color: const Color(0xFFE8F5F3),
        child: Padding(padding: const EdgeInsets.all(14), child: Text(
          step == 0 ? 'Step 1 — Listen: tap 🔊 Listen. First slow, then normal speed. Listen 2 times before you speak. Do not guess.' :
          step == 1 ? 'Step 2 — Repeat: say the word quietly with the sound, 3 times. Break it into letters: listen to each sound, then join them.' :
          step == 2 ? 'Step 3 — Speak on mic: tap 🎤 Speak on mic, wait for “Listening…”, then say the word clearly, once. Or tap the word you heard below.' :
          step == 3 ? 'Step 4 — Honest result: we compare what you really said with the correct word. Correct / close = “Very good!” + ⭐. Wrong = “Not quite yet — listen again.” We never say Very good for a wrong word.' :
          'Step 5 — Listen again: if it was wrong, tap 🔊 Listen again, hear the correct sound, then try again. After 3 tries, tap Learn Again to go back to that lesson.',
          style: const TextStyle(fontSize: 15),
        )),
      ),
      const SizedBox(height: 10),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(w[0], style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
        Text('${w[1]} — ${w[2]} (${w[3]})'),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(onPressed: () { setState(() => step = 1); speakSlowThenNormal(w[0]); }, child: const Text('🔊 Listen')),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF6C00)),
            onPressed: () { setState(() => step = 2); _speakTest(w[0]); },
            child: const Text('🎤 Speak on mic'),
          ),
        ]),
        const SizedBox(height: 8),
        const Text('Or tap the word you heard:'),
        Wrap(spacing: 8, children: vocab.sublist(0, 4).map((v) => ElevatedButton(
          onPressed: () { setState(() => step = 3); _answer(v[0] == w[0], w[0]); },
          child: Text(v[0]),
        )).toList()),
        if (heardText.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('You said: $heardText', style: const TextStyle(fontSize: 14, color: Colors.grey))),
        if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(feedback, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        if (done) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Score: $score correct. ${score >= 3 ? "Wah bhai wah, Korea pakka!" : "Ghalat jawab, lekin himmat na haar, dobara kar!"}')),
        if (tries >= 3) TextButton(onPressed: () { setState(() { tries = 0; feedback = ''; step = 0; }); }, child: const Text('📚 Learn Again — back to this lesson')),
      ]))),
      const SizedBox(height: 14),
      const Text('🇰🇷 Culture & manners — real situations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0B2C6B))),
      const Text('Tap a situation to see what to do, what NOT to do, and the Korean words to say.'),
      const SizedBox(height: 8),
      ...cultureScenarios.map((c) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c[0], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('🎬 Situation: ${c[1]}'),
        Text('✅ Do: ${c[2]}', style: const TextStyle(color: Colors.green)),
        Text('❌ Do NOT: ${c[3]}', style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 6),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFE8F5F3), borderRadius: BorderRadius.circular(10)), child: Row(children: [
          Expanded(child: Text('${c[4]} (${c[5]}) — ${c[6]}', style: const TextStyle(fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(c[4])),
        ])),
      ])))),
    ]);
  }

  void _answer(bool correct, String target) {
    setState(() {
      step = 3;
      if (correct) {
        score++;
        feedback = 'Very good! ⭐ $target — correct.';
        q++;
        tries = 0;
        if (q >= 5) done = true;
      } else {
        tries++;
        feedback = tries >= 3
            ? 'Not quite yet — listen again. You have tried 3 times: tap Learn Again to go back to that lesson, then come back.'
            : 'Not quite yet — listen again. Try ${3 - tries} more time(s).';
        speak(target);
      }
    });
  }

  Future<void> _speakTest(String target) async {
    final stt = SpeechToText();
    try {
      final ok = await stt.initialize();
      if (!ok) { setState(() => feedback = 'Mic / speech recognition is not available on this phone. Use Listen-and-Tap instead — the test is never blocked.'); return; }
      setState(() { feedback = 'Listening… say it now, clearly, once.'; heardText = ''; });
      await stt.listen(onResult: (r) {
        if (r.finalResult) {
          final heard = r.recognizedWords;
          setState(() => heardText = heard.isEmpty ? '(nothing heard)' : heard);
          _answer(_isClose(heard, target), target);
          stt.stop();
        }
      }, localeId: 'ko-KR');
    } catch (_) {
      setState(() => feedback = 'Mic not available. Use Listen-and-Tap instead.');
    }
  }
}

// ---------------- Mock Test ----------------
class MockPage extends StatefulWidget {
  const MockPage({super.key});
  @override
  State<MockPage> createState() => _MockPageState();
}

class _MockPageState extends State<MockPage> {
  int qi = 0, listening = 0, reading = 0;
  bool started = false, finished = false;
  String difficulty = 'basic';
  int secondsLeft = 50 * 60;

  /// Shuffled options for question qi: correct + 3 wrong, position randomised.
  List<String> _options(String correct, List<String> wrongs, int seed) {
    final opts = <String>[correct, ...wrongs]..shuffle(Random(seed));
    return opts;
  }

  @override
  Widget build(BuildContext context) {
    if (!started) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Mock Test — 40 questions, 50 minutes, 100 points', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0B2C6B))),
        const Text('20 reading + 20 listening. Passing floor 60/100. Pakistan 2026 merit 82.5/100 (reported — check the latest OEC notice).'),
        const SizedBox(height: 12),
        const Text('Choose your difficulty:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(color: difficulty == 'basic' ? const Color(0xFFE8F5E9) : Colors.white, child: ListTile(
          leading: const Text('🟢', style: TextStyle(fontSize: 24)),
          title: const Text('Basic — for beginners', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Easy words and short questions. Learn the format, build confidence.'),
          trailing: difficulty == 'basic' ? const Icon(Icons.check_circle, color: Colors.green) : null,
          onTap: () => setState(() => difficulty = 'basic'),
        )),
        Card(color: difficulty == 'expert' ? const Color(0xFFFFEBEE) : Colors.white, child: ListTile(
          leading: const Text('🔴', style: TextStyle(fontSize: 24)),
          title: const Text('Expert — real test level', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Harder, longer, real EPS-TOPIK style reading and listening from the new syllabus (Units 1–60, safety, laws). Aiming at the 82.5/100 merit, not just the 60 pass floor.'),
          trailing: difficulty == 'expert' ? const Icon(Icons.check_circle, color: Colors.red) : null,
          onTap: () => setState(() => difficulty = 'expert'),
        )),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF6C00), minimumSize: const Size.fromHeight(52)),
          onPressed: () => setState(() { started = true; _tick(); }),
          child: Text('Start ${difficulty == 'expert' ? 'Expert' : 'Basic'} mock (50 min)', style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        const Text('Your past attempts:'),
        ...((AppStore.I.progress['mocks'] as List? ?? []).map((m) => ListTile(
          title: Text('Listening ${m['l']}/20 • Reading ${m['r']}/20'),
          subtitle: Text('Score ${(m['l'] + m['r']) * 2.5}/100 — ${((m['l'] + m['r']) * 2.5) >= 60 ? 'Passed (60)' : 'Below passing'} • ${((m['l'] + m['r']) * 2.5) >= 82.5 ? 'Above merit 82.5' : 'Below merit 82.5'}'),
        ))),
      ]);
    }
    if (finished) {
      final total = (listening + reading) * 2.5;
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Result: $total / 100', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Listening $listening/20 • Reading $reading/20'),
        Text('${difficulty == 'expert' ? 'Expert' : 'Basic'} mock', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(total >= 82.5 ? 'Wah bhai wah, Korea pakka! Above merit.' : total >= 60 ? 'Passed the floor (60), but below merit 82.5 — practise your weak topics.' : 'Ghalat jawab, lekin himmat na haar, dobara kar! Below 60 — learn again.'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => setState(() { started = false; finished = false; qi = 0; listening = 0; reading = 0; secondsLeft = 50 * 60; }), child: const Text('Back')),
      ])));
    }
    final isListening = qi < 20;
    final isExpert = difficulty == 'expert';
    // Correct answer text + 3 wrong texts, shuffled with a per-question seed
    // so the correct position varies across A–D and is never predictable.
    late String prompt, promptKo;
    late List<String> options;
    late String correctText;
    if (isExpert) {
      final bank = isListening ? expertListening : expertReading;
      final e = bank[qi % bank.length];
      promptKo = e[0];
      prompt = isListening ? 'Listen, then tap the correct meaning:' : 'Read the sentence, then tap the correct meaning:';
      correctText = e[1];
      options = _options(e[1], [e[2], e[3], e[4]], 9871 + qi * 37);
    } else {
      final w = vocab[qi % vocab.length];
      promptKo = w[0];
      prompt = isListening ? 'Listen, then tap the meaning:' : 'What does this mean?';
      correctText = '${w[2]} — ${w[3]}';
      final wrongs = [vocab[(qi + 5) % vocab.length], vocab[(qi + 11) % vocab.length], vocab[(qi + 17) % vocab.length]]
          .map((v) => '${v[2]} — ${v[3]}').toList();
      options = _options(correctText, wrongs, 12345 + qi * 31);
    }
    const letters = ['A', 'B', 'C', 'D'];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('⏱ ${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')} left — ${isExpert ? 'Expert' : 'Basic'} — Question ${qi + 1}/40 (${isListening ? 'Listening' : 'Reading'})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(prompt, style: const TextStyle(fontSize: 16)),
        Text(promptKo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        if (isListening) ElevatedButton(onPressed: () => speak(promptKo), child: const Text('🔊 Hear it')),
        const SizedBox(height: 12),
        ...options.asMap().entries.map((e) {
          final idx = e.key, opt = e.value;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (opt == correctText) { if (isListening) { listening++; } else { reading++; } }
              if (qi + 1 >= 40) {
                await AppStore.I.addMock(listening, reading);
                setState(() => finished = true);
              } else { setState(() => qi++); }
            },
            child: Text('${letters[idx]}. $opt'),
          )));
        }),
      ]))),
    ]);
  }

  void _tick() async {
    while (started && !finished && secondsLeft > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => secondsLeft--);
    }
    if (started && secondsLeft <= 0 && !finished) {
      await AppStore.I.addMock(listening, reading);
      setState(() => finished = true);
    }
  }
}

// ---------------- Voice Tutor ----------------
class TutorPage extends StatefulWidget {
  const TutorPage({super.key});
  @override
  State<TutorPage> createState() => _TutorPageState();
}

class _TutorPageState extends State<TutorPage> {
  String tutorLang = 'Urdu';
  final qC = TextEditingController();
  String answer = '', detected = '';
  final stt = SpeechToText();
  bool listeningMic = false;

  String detectLang(String q) {
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(q)) return 'Urdu';
    if (RegExp(r'[가-힣]').hasMatch(q)) return 'Korean';
    final lower = q.toLowerCase();
    if (lower.contains('za ') || lower.contains('wagi')) return 'Pashto';
    if (lower.contains('moon') || lower.contains('buk')) return 'Sindhi';
    if (lower.contains('mainu') || lower.contains('bhuk')) return 'Saraiki';
    return tutorLang;
  }

  String _meaningFor(List<String> e, String lang) {
    // tutorBank columns: 0 keywords, 1 ko, 2 rom, 3 en, 4 roman-urdu, 5 punjabi, 6 pashto, 7 sindhi, 8 saraiki
    switch (lang) {
      case 'Urdu': return e[4];
      case 'Punjabi': return e[5];
      case 'Pashto': return e[6];
      case 'Sindhi': return e[7];
      case 'Saraiki': return e[8];
      default: return e[3];
    }
  }

  void ask(String q) {
    final lang = detectLang(q);
    setState(() => detected = lang);
    final query = q.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() => answer = 'Please type or speak a question first. Try one of the starters below.');
      return;
    }
    // Match the tutor bank by keyword — never a default greeting.
    for (final e in tutorBank) {
      final keys = e[0].split(',');
      for (final k in keys) {
        final key = k.trim();
        if (key.length >= 2 && (query.contains(key) || (key.length >= 4 && key.split(' ').every((w) => w.isEmpty || query.contains(w))))) {
          final ko = e[1], rom = e[2];
          setState(() => answer = 'Korean: $ko ($rom)\nMeaning in $lang: ${_meaningFor(e, lang)}');
          speakSlowThenNormal(ko);
          return;
        }
      }
    }
    // No match: say so honestly, never return a default Salaam answer.
    setState(() => answer = lang == 'Urdu'
        ? 'Ye sawal main abhi nahi janta. Neeche diye gaye sawalon mein se ek try karein, ya sawal dobara aasan lafzon mein poochhein.'
        : lang == 'Pashto'
            ? 'Za da pohtana na pohegam. Lande pohtano na yaw wakhla.'
            : 'I do not know that question yet. Please try one of the starter questions below, or ask it again in simpler words.');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Voice Tutor — ask in your own language', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Pashto, Sindhi, Saraiki, Punjabi, Urdu, English. The answer comes in the SAME language you asked in, plus the Korean answer with sound.'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: tutorLanguages.map((l) => ChoiceChip(
        label: Text(l), selected: tutorLang == l,
        onSelected: (_) => setState(() => tutorLang = l),
      )).toList()),
      const SizedBox(height: 8),
      TextField(controller: qC, decoration: const InputDecoration(labelText: 'Type your question, or tap the mic', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      Row(children: [
        ElevatedButton.icon(icon: Icon(listeningMic ? Icons.mic_off : Icons.mic), label: const Text('Speak'), onPressed: () async {
          try {
            final ok = await stt.initialize();
            if (!ok) { setState(() => answer = 'Mic / speech recognition is not available on this phone. Please type your question — typing always works.'); return; }
            setState(() => listeningMic = true);
            await stt.listen(onResult: (r) {
              if (r.finalResult) { qC.text = r.recognizedWords; setState(() => listeningMic = false); ask(qC.text); stt.stop(); }
            });
          } catch (_) { setState(() => answer = 'Mic not available on this device. Please type.'); }
        }),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () => ask(qC.text), child: const Text('Ask')),
      ]),
      if (detected.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Chip(label: Text('Answered in: $detected'))),
      if (answer.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(answer, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () { final ko = answer.split('\n').first.replaceAll('Korean: ', '').split(' (').first; speakSlowThenNormal(ko); }, child: const Text('🔊 Hear Korean — slow, then normal')),
      ]))),
      const SizedBox(height: 12),
      const Text('Try one:', style: TextStyle(fontWeight: FontWeight.bold)),
      ...tutorStarters.map((s) => ListTile(
        title: Text('${s[0]}: ${s[1]}'),
        subtitle: Text('${s[2]} (${s[3]}) — ${s[4]}'),
        trailing: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(s[2])),
        onTap: () { qC.text = s[1]; ask(s[1]); },
      )),
      const Text('Note: speech recognition depends on the phone — if your language is not supported on this phone, the app says so and typing always works. The tutor answers from its built-in question bank; if it does not know your question, it says so honestly instead of guessing.', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}

// ---------------- Games ----------------
class GamesPage extends StatefulWidget {
  const GamesPage({super.key});
  @override
  State<GamesPage> createState() => _GamesPageState();
}

class _GamesPageState extends State<GamesPage> {
  int round = 0, stars = 0;
  String msg = '';
  final rnd = Random();

  @override
  Widget build(BuildContext context) {
    final w = vocab[round % vocab.length];
    final options = [w, vocab[(round + 5) % vocab.length], vocab[(round + 11) % vocab.length], vocab[(round + 17) % vocab.length]]..shuffle(rnd);
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Games — play & learn', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      Text('Listen and Tap — round ${round + 1}/8 • ⭐ $stars • No timer here, take your time.'),
      const SizedBox(height: 8),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        const Text('Hear a word, tap the right one from 4.'),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => speakSlowThenNormal(w[0]), child: const Text('🔊 Hear the word')),
        const SizedBox(height: 4),
        TextButton(onPressed: () => speakSlowThenNormal(w[0]), child: const Text('Repeat / Hear again')),
        const SizedBox(height: 8),
        ...options.map((o) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            setState(() {
              if (o[0] == w[0]) { stars++; msg = 'Wah bhai wah, Korea pakka! ⭐'; round++; }
              else { msg = 'Ghalat jawab, lekin himmat na haar, dobara kar!'; }
              if (round >= 8) { msg += ' Game finished — $stars/8 stars!'; round = 0; stars = 0; }
            });
          },
          child: Text('${o[0]} — ${o[2]}'),
        )))),
        if (msg.isNotEmpty) Text(msg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ]))),
      const SizedBox(height: 12),
      const Text('Daily Challenge: play Listen and Tap every day and keep your streak. Word Match and Memory Cards use the same words — tap a Korean word, then its meaning.'),
    ]);
  }
}

// ---------------- Settings ----------------
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final pwC = TextEditingController();
  final newPwC = TextEditingController();
  String msg = '';

  @override
  Widget build(BuildContext context) {
    final lang = AppStore.I.lang;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Image.asset('assets/logo.png', height: 120),
      const Text('EPS TOPIK Pro Pakistan — Korea Pakka!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Not affiliated with OEC or HRD Korea.', textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(t(lang, 'language'), style: const TextStyle(fontWeight: FontWeight.bold)),
      Row(children: [
        for (final l in ['english', 'roman', 'script'])
          Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
            label: Text(l == 'english' ? 'English' : (l == 'roman' ? 'Roman Urdu' : 'اردو')),
            selected: lang == l,
            onSelected: (_) async { await AppStore.I.setLang(l); setState(() {}); },
          )),
      ]),
      const SizedBox(height: 12),
      ListTile(title: Text('Account: ${AppStore.I.currentName} (${AppStore.I.session ?? ''})')),
      ListTile(title: const Text('Daily reminder'), subtitle: const Text('Study reminder: on, 30 minutes a day. Change the time on your phone’s clock app for now — in-app time picker is the next update.')),
      ListTile(title: const Text('Sound'), subtitle: const Text('Korean voice: slow, then normal. Volume follows your phone volume.')),
      ListTile(title: const Text('Offline'), subtitle: const Text('Lessons and words are stored on this phone and work offline. Audio uses the phone’s Korean voice (flutter_tts) — download a Korean voice in your phone settings for the best sound.')),
      const Divider(),
      const Text('Change password', style: TextStyle(fontWeight: FontWeight.bold)),
      TextField(controller: pwC, obscureText: true, decoration: const InputDecoration(labelText: 'Current password', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      TextField(controller: newPwC, obscureText: true, decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder())),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: () async {
        final ok = await AppStore.I.changePassword(pwC.text, newPwC.text);
        setState(() => msg = ok ? 'Password changed.' : 'Wrong current password.');
      }, child: const Text('Change password')),
      if (msg.isNotEmpty) Text(msg),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: () async { await AppStore.I.resetProgress(); setState(() => msg = 'Reset to Level 1. Progress cleared, account kept.'); }, child: const Text('Reset to Level 1')),
      const SizedBox(height: 8),
      const Text('Privacy Policy (simple)', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('We collect only what you enter: your account name, email/mobile, and your learning progress. We do not sell your data. Your progress stays on your phone in this version. You can delete your account below — that deletes all your data on this phone.'),
      const SizedBox(height: 8),
      const Text('Terms of Use (simple)', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('This app is free to learn. You only pay official OEC fees. Lessons are original — we do not copy the HRD Korea textbook or real test questions. This app is not affiliated with OEC or HRD Korea. Check the latest OEC notice at jobs.oec.gov.pk.'),
      const SizedBox(height: 12),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: () async {
          await AppStore.I.logout();
          setState(() {});
        },
        child: Text(t(lang, 'logout')),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () async {
          try {
            await AppStore.I.deleteAccount(pwC.text);
            setState(() => msg = 'Account deleted.');
          } catch (e) { setState(() => msg = 'Enter your current password above first.'); }
        },
        child: const Text('Delete account (needs current password above)'),
      ),
      const SizedBox(height: 8),
      const Text('Help: if you are stuck, ask your teacher or message the app owner on WhatsApp. Version 1.0.0 (APK test build).', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]);
  }
}
