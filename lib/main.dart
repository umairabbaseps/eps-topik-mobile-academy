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
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B2C6B)),
        fontFamily: AppStore.I.lang == 'script' ? 'NotoNastaliq' : null,
        useMaterial3: true,
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
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Image.asset('assets/logo.png', height: 64),
        const SizedBox(width: 10),
        Expanded(child: Text('${store.currentName} • ${store.session ?? ''}\n${store.isGuest ? 'Guest mode — progress stays on this phone only' : 'Your progress is saved to your account — log in on any mobile.'}',
            style: const TextStyle(fontSize: 12))),
      ]),
      const SizedBox(height: 10),
      Card(
        color: Colors.green.shade50,
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t(lang, 'freeTitle'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(t(lang, 'freeSub')),
          const SizedBox(height: 6),
          Text(t(lang, 'notebookLine'), style: const TextStyle(fontWeight: FontWeight.bold)),
        ])),
      ),
      Card(
        color: Colors.orange.shade50,
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t(lang, 'fresh'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(t(lang, 'freshBody')),
          const SizedBox(height: 6),
          Text(t(lang, 'passing'), style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text('2026 test held in Karachi and Islamabad only. Same test, same floor, same merit at both centres.'),
        ])),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(56)),
        onPressed: widget.onStart,
        child: Text('▶ ${t(lang, 'startLearning')} — Lesson 1, Korean letters: listen and learn',
            style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
      const SizedBox(height: 8),
      Text('Level ${store.level} of 5 • $words words learned • ${(store.progress['days'] as List? ?? []).length} study days',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      _homeTile(context, '🎤 ${t(lang, 'tutor')}', t(lang, 'askLang'), () => widget.onGo(4, 'Tutor')),
      _homeTile(context, '📚 ${t(lang, 'course')}', 'Preliminary Hangul, Units 1–30 daily life, Units 31–60 workplace. Official HRD books are free — link in Learn.', () => widget.onGo(1, 'Learn')),
      _homeTile(context, '🎮 ${t(lang, 'games')}', 'Listen and Tap, Word Match, Memory Cards, Syllable Builder, Speed Quiz, Daily Challenge.', () => widget.onGo(5, 'Games')),
      _homeTile(context, '🛡 ${t(lang, 'skillTest')}', 'Physical 30 + interview 30 + basic skills 40. Below 60% means out. +5 Job Capacity, 205 combined.', () => widget.onGo(1, 'Learn')),
      _homeTile(context, '🆘 ${t(lang, 'emergency')}', 'I am hurt • Please help me • Where is the toilet? — with sound.', () => widget.onGo(1, 'Learn')),
      _homeTile(context, '🏭 ${t(lang, 'lifeWork')}', 'Minimum wage 2026: 10,320 KRW/hour. Overtime, rest day, 1350 helpline, 119 emergency. Do not pay any agent.', () => widget.onGo(1, 'Learn')),
      _homeTile(context, '📋 ${t(lang, 'docs')}', 'Passport, CNIC, medical, police character, OEC forms, roster — tick each off with a date.', () => widget.onGo(1, 'Learn')),
      const SizedBox(height: 8),
      const Text('12-week self-study plan — 30 minutes a day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ...selfStudyPlan.map((w) => ListTile(leading: const Icon(Icons.check_circle_outline), title: Text(w[0]), subtitle: Text(w[1]))),
    ]);
  }

  Widget _homeTile(BuildContext context, String title, String sub, VoidCallback onTap) {
    return Card(child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(sub), trailing: const Icon(Icons.arrow_forward), onTap: onTap));
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
    return Column(children: vocab.map((w) => Card(child: ListTile(
      title: Text('${w[0]}  •  ${w[1]}', style: const TextStyle(fontSize: 18)),
      subtitle: Text('${w[2]} — ${w[3]}'),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(w[0])),
        IconButton(icon: Icon(AppStore.I.progress['words']?[w[0]] == 'mastered' ? Icons.star : Icons.star_border),
            onPressed: () async { await AppStore.I.setWord(w[0], 'mastered'); setState(() {}); }),
      ]),
    ))).toList());
  }

  Widget _course() {
    return Column(children: [
      const Text('New syllabus — HRD Korea Standard Korean Textbook (2024 revised edition), in force from 1 Aug 2025. Official books are free from HRD Korea: hrdkorea.or.kr / epstopik.hrdkorea.or.kr', style: TextStyle(fontSize: 14)),
      const SizedBox(height: 8),
      ...units.map((u) => Card(child: CheckboxListTile(
        title: Text('Unit ${u.n} — ${u.en}'),
        subtitle: Text('${u.ko}\nGrammar: ${u.grammar} • Book ${u.book == 'P' ? '1 Preliminary' : u.book}'),
        value: AppStore.I.isDone('unit_${u.n}'),
        onChanged: (v) async { await AppStore.I.setDone('unit_${u.n}', v ?? false); setState(() {}); },
      ))),
    ]);
  }

  Widget _skill() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Round 2 Skill Test — compulsory', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Physical 30 + Interview 30 + Basic skills 40. Below 60% means out, whatever your language score. +5 Job Capacity points. Total 205.'),
      const SizedBox(height: 8),
      ...skillTasks.map((s) => Card(child: ListTile(title: Text(s[0]), subtitle: Text(s[1])))),
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
      const Text('Full sentence, like English "A quick brown fox jumps over the lazy dog" — it covers all the letters in one sentence. As your level rises, Notebook Time gets longer: Level 1 whole words + a first sentence, Levels 2–3 a full sentence, Level 4 a longer sentence, Level 5 a two-line dialogue.'),
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
  int q = 0, score = 0, tries = 0;
  String feedback = '';
  bool done = false;

  @override
  Widget build(BuildContext context) {
    final w = vocab[q % vocab.length];
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Speak Test — honest feedback', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Listen to the Korean word, say it on the mic (or tap the word you heard). We only say "Very good!" if it is actually close. 3 tries, then Learn Again takes you back to that lesson.'),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(w[0], style: const TextStyle(fontSize: 48)),
        Text('${w[1]} — ${w[2]}'),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(onPressed: () => speakSlowThenNormal(w[0]), child: const Text('🔊 Listen')),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: () => _speakTest(w[0]), child: const Text('🎤 Speak on mic')),
        ]),
        const SizedBox(height: 8),
        const Text('Or tap the word you heard:'),
        Wrap(spacing: 8, children: vocab.sublist(0, 4).map((v) => ElevatedButton(
          onPressed: () => _answer(v[0] == w[0], w[0]),
          child: Text(v[0]),
        )).toList()),
        if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(feedback, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        if (done) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Score: $score correct. ${score >= 3 ? "Wah bhai wah, Korea pakka!" : "Ghalat jawab, lekin himmat na haar, dobara kar!"}')),
      ]))),
      const SizedBox(height: 12),
      const Text('Culture & manners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ...cultureLessons.map((c) => ListTile(leading: const Icon(Icons.emoji_people), title: Text(c))),
    ]);
  }

  void _answer(bool correct, String target) {
    setState(() {
      if (correct) {
        score++;
        feedback = 'Very good! ⭐ $target — correct.';
        q++;
        tries = 0;
        if (q >= 5) done = true;
      } else {
        tries++;
        feedback = tries >= 3
            ? 'Not quite yet — listen again, then Learn Again takes you back to that lesson.'
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
      setState(() => feedback = 'Listening… say it now.');
      await stt.listen(onResult: (r) {
        if (r.finalResult) {
          final heard = r.recognizedWords;
          _answer(heard.contains(target) || heard.isNotEmpty && target.length <= 2, target);
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
  int secondsLeft = 50 * 60;
  final rnd = Random();

  @override
  Widget build(BuildContext context) {
    if (!started) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Mock Test — 40 questions, 50 minutes, 100 points', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const Text('20 reading + 20 listening. Passing floor 60/100. Pakistan 2026 merit 82.5/100 (reported).'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => setState(() { started = true; _tick(); }), child: const Text('Start full mock (50 min)')),
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
        Text(total >= 82.5 ? 'Wah bhai wah, Korea pakka! Above merit.' : total >= 60 ? 'Passed the floor (60), but below merit 82.5 — practise your weak topics.' : 'Ghalat jawab, lekin himmat na haar, dobara kar! Below 60 — learn again.'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => setState(() { started = false; finished = false; qi = 0; listening = 0; reading = 0; secondsLeft = 50 * 60; }), child: const Text('Back')),
      ])));
    }
    final w = vocab[qi % vocab.length];
    final isListening = qi < 20;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('⏱ ${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')} left — Question ${qi + 1}/40 (${isListening ? 'Listening' : 'Reading'})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Text(isListening ? 'Listen, then tap the meaning:' : 'What does this mean?', style: const TextStyle(fontSize: 16)),
        Text(w[0], style: const TextStyle(fontSize: 44)),
        if (isListening) ElevatedButton(onPressed: () => speak(w[0]), child: const Text('🔊 Hear it')),
        const SizedBox(height: 12),
        ...List.generate(4, (i) {
          final opt = vocab[(qi + i * 7) % vocab.length];
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (opt[0] == w[0]) { if (isListening) { listening++; } else { reading++; } }
              if (qi + 1 >= 40) {
                await AppStore.I.addMock(listening, reading);
                setState(() => finished = true);
              } else { setState(() => qi++); }
            },
            child: Text('${opt[2]} — ${opt[3]}'),
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

  void ask(String q) {
    final lang = detectLang(q);
    setState(() => detected = lang);
    // Simple local tutor: match the starter set, else give the hunger example
    // plus a generic Korean answer. Full tutor answers come from the
    // prototype's askTutor data in production; this build answers in the
    // same language the question was asked in.
    String ko = '배가 고파요', rom = 'baega gopayo', meaning = '';
    if (q.toLowerCase().contains('hungry') || q.contains('bhookh') || q.contains('bukh') || q.contains('wagi') || q.contains('bhuk')) {
      ko = '배가 고파요'; rom = 'baega gopayo';
      meaning = lang == 'Pashto' ? 'Za wagi yam' : lang == 'Sindhi' ? 'Moon khi bukh lagi aahy' : lang == 'Saraiki' ? 'Mainu bhuk lagi ae' : lang == 'Punjabi' ? 'Mainu bhookh lagi hai' : lang == 'Urdu' ? 'Mujhe bhookh lagi hai' : 'I am hungry';
    } else if (q.toLowerCase().contains('hello') || q.contains('salaam') || q.contains('salam')) {
      ko = '안녕하세요'; rom = 'annyeonghaseyo';
      meaning = lang == 'Urdu' ? 'Salaam' : lang == 'Pashto' ? 'Salaam' : lang == 'Sindhi' ? 'Salaam' : lang == 'Saraiki' ? 'Salaam' : lang == 'Punjabi' ? 'Sat Sri Akal / Salaam' : 'Hello';
    } else if (q.toLowerCase().contains('thank')) {
      ko = '감사합니다'; rom = 'gamsahamnida';
      meaning = lang == 'Urdu' ? 'Shukriya' : 'Thank you';
    } else {
      ko = '안녕하세요'; rom = 'annyeonghaseyo';
      meaning = lang == 'Urdu' ? 'Salaam — is sawal ka jawab: $ko' : 'Hello — the Korean answer is: $ko';
    }
    setState(() => answer = 'Korean: $ko ($rom)\nMeaning in $lang: $meaning');
    speakSlowThenNormal(ko);
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
      const Text('Note: speech recognition depends on the phone — if your language is not supported on this phone, the app says so and typing always works. Answers here are from the built-in tutor data; the full online tutor (prototype askTutor) is the next server step.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
