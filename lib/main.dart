import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy, primary: AppColors.navy, secondary: AppColors.tealDark, tertiary: AppColors.orangeDark),
        scaffoldBackgroundColor: AppColors.pageBg,
        fontFamily: AppStore.I.lang == 'script' ? 'NotoNastaliq' : null,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.navy, foregroundColor: Colors.white, centerTitle: false),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
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
  // Real back stack (P0-1): history of tabs, newest last. Back pops it;
  // it never jumps Home unless Home is genuinely the previous screen.
  final List<int> tabHistory = [0];
  String? learnStart;
  int? learnStartUnit;
  int learnSeed = 0;
  String mockDifficulty = 'basic';
  int mockSeed = 0;
  // Key to the Learn page, so Back can close a Unit/Skill detail first
  // (previous screen) instead of jumping to Home.
  final GlobalKey<_LearnPageState> learnKey = GlobalKey<_LearnPageState>();
  String get lang => AppStore.I.lang;
  String tr(String k) => t(lang, k);

  void _pushTab(int i) {
    if (tabHistory.isEmpty || tabHistory.last != i) tabHistory.add(i);
    if (tabHistory.length > 20) tabHistory.removeAt(0);
  }

  /// Choose a learning path. Sets the STARTING level only — it does NOT
  /// mark any unit done and does NOT lock anything: level is a display /
  /// Notebook-Time scale, not a gate.
  Future<void> choosePath(String path) async {
    if (path == 'basic') {
      await AppStore.I.setLevel(1);
      setState(() { learnStart = 'basic'; learnStartUnit = null; learnSeed++; tab = 1; _pushTab(1); });
    } else if (path == 'mid') {
      await AppStore.I.setLevel(3);
      setState(() { learnStart = 'mid'; learnStartUnit = null; learnSeed++; tab = 1; _pushTab(1); });
    } else if (path == 'expert') {
      await AppStore.I.setLevel(5);
      setState(() { learnStart = 'expert'; learnStartUnit = null; learnSeed++; tab = 1; _pushTab(1); });
    } else if (path == 'expert-mock') {
      await AppStore.I.setLevel(5);
      setState(() { mockDifficulty = 'expert'; mockSeed++; tab = 2; _pushTab(2); });
    }
  }

  /// Continue where the learner left off (P0-3): first unit not yet
  /// marked done, or Unit 0 for a brand-new learner.
  void goContinue() {
    int next = 0;
    for (int n = 0; n <= 60; n++) {
      if (!AppStore.I.isDone('unit_$n')) { next = n; break; }
      next = 0;
    }
    setState(() { learnStart = 'continue'; learnStartUnit = next; learnSeed++; tab = 1; _pushTab(1); });
  }

  /// Open Learn at a named section (e.g. 'life' for Life in Korea).
  void goLearnSection(String section) {
    setState(() { learnStart = 'section:$section'; learnStartUnit = null; learnSeed++; tab = 1; _pushTab(1); });
  }

  void goTab(int i, String name) {
    setState(() { tab = i; _pushTab(i); });
  }

  void goHome() => setState(() {
        tab = 0;
        tabHistory.clear();
        tabHistory.add(0);
      });

  void goBack() {
    // 1) Close an open Unit/Skill detail in Learn first.
    if (tab == 1 && learnKey.currentState != null && learnKey.currentState!.hasDetail) {
      setState(() => learnKey.currentState!.closeDetail());
      return;
    }
    // 2) Otherwise pop the real tab history — never jump Home blindly.
    setState(() {
      if (tabHistory.length > 1) {
        tabHistory.removeLast();
        tab = tabHistory.last;
      } else {
        tab = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (AppStore.I.session == null) return AuthScreen(onDone: () => setState(() {}));
    final pages = [
      HomePage(onGo: goTab, onStart: goContinue, onChoosePath: choosePath, onLearnSection: goLearnSection),
      LearnPage(key: learnKey, start: learnStart, startUnit: learnStartUnit),
      MockPage(key: ValueKey('mock-$mockSeed'), initialDifficulty: mockDifficulty, onGoLearn: () => goTab(1, 'Learn')),
      const TutorPage(),
      const MorePage(),
    ];
    final titles = [tr('home'), tr('learn'), tr('mock'), tr('tutor'), 'More'];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: tr('back'),
          onPressed: tab == 0 && tabHistory.length <= 1 ? null : goBack,
        ),
        title: Text(titles[tab]),
        actions: [
          IconButton(icon: const Icon(Icons.home), tooltip: tr('home'), onPressed: goHome),
        ],
      ),
      body: SafeArea(child: pages[tab]),
      // P0-1: 4 tabs only (Home / Learn / Mock / Tutor) + More.
      // Practice, Games and Settings live under More — 7 tabs did not
      // fit a phone and "Games" was hard-coded English.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.muted,
        onTap: (i) => setState(() { tab = i; _pushTab(i); }),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: tr('home')),
          BottomNavigationBarItem(icon: const Icon(Icons.school), label: tr('learn')),
          BottomNavigationBarItem(icon: const Icon(Icons.timer), label: tr('mock')),
          BottomNavigationBarItem(icon: const Icon(Icons.mic), label: tr('tutor')),
          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

/// "More" sheet-tab (P0-1): Practice, Games and Settings. Each opens as
/// a real pushed screen, so the system/AppBar Back returns here — a real
/// per-tab stack, not a trail that jumps Home.
class MorePage extends StatelessWidget {
  const MorePage({super.key});
  void _open(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title), backgroundColor: AppColors.navy, foregroundColor: Colors.white),
        body: SafeArea(child: page),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('More', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
      const SizedBox(height: 4),
      const Text('Practice, games and settings — everything else lives here so the bottom bar stays to 4 tabs.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 12),
      _row(context, Icons.edit, AppColors.navy, 'Practice', 'Speak Test • Culture & manners • Notebook', () => _open(context, 'Practice', const PracticePage())),
      _row(context, Icons.videogame_asset, AppColors.purple, 'Games', 'Listen and Tap — play & learn', () => _open(context, 'Games', const GamesPage())),
      _row(context, Icons.settings, AppColors.muted, 'Settings', 'Language • Account • Sound • Help', () => _open(context, 'Settings', const SettingsPage())),
    ]);
  }

  Widget _row(BuildContext context, IconData icon, Color c, String title, String sub, VoidCallback onTap) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: c, size: 24)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      );
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
                if (pwC.text.length < 6) { setState(() => msg = 'Enter a new password of 6+ characters in the password field first.'); return; }
                final ok = await AppStore.I.resetPassword(id, codeC.text.trim(), pwC.text);
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
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.muted)),
        ]),
      ),
    );
  }
}

// ---------------- Home ----------------
// CBD-inspired redesign (v1.2.0): Home shows ONLY the essentials, like a
// bank app's dashboard — one hero "balance" card, one row of quick
// actions, then Today / Tutor / Mock. Everything else lives in the
// bottom tabs (Learn / Practice / Mock / Tutor / Games / Settings),
// reached from the single "Explore" card. Nothing was deleted:
// free promise, syllabus, merit, units, skill test, culture, life &
// work, docs and the 12-week plan are all still in their tabs.
class HomePage extends StatefulWidget {
  final void Function(int, String) onGo;
  final VoidCallback onStart;
  final void Function(String) onChoosePath;
  final void Function(String) onLearnSection;
  const HomePage({super.key, required this.onGo, required this.onStart, required this.onChoosePath, required this.onLearnSection});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // CBD palette (from CBD's own promos / store listing): dark teal +
  // lime green, with a green-to-lime "balance" header, white cards on a
  // pale grey background, one accent per action, generous spacing.
  static const _tealDark = Color(0xFF004D40);
  static const _green = Color(0xFF00A859);
  static const _navy = Color(0xFF0B2C6B);
  static const _ink = Color(0xFF1A2B3C);
  static const _muted = Color(0xFF5F6B7A);
  static const _pageBg = Color(0xFFF3F5F7);

  @override
  Widget build(BuildContext context) {
    final lang = AppStore.I.lang;
    final store = AppStore.I;
    final words = (store.progress['words'] as Map? ?? {}).length;
    final days = (store.progress['days'] as List? ?? []).length;
    final mocks = (store.progress['mocks'] as List? ?? []).length;
    // Today's plan follows the 12-week plan: one week per 7 study days.
    final weekIdx = ((days / 7).floor()).clamp(0, selfStudyPlan.length - 1);
    final week = selfStudyPlan[weekIdx];
    // P0-3: Continue = first unit not yet done; best mock vs the 82.5 merit.
    int continueUnit = 0;
    for (int n = 0; n <= 60; n++) { if (!store.isDone('unit_$n')) { continueUnit = n; break; } }
    double bestMock = 0;
    for (final m in (store.progress['mocks'] as List? ?? [])) {
      final t = ((m['l'] ?? 0) + (m['r'] ?? 0)) * 2.5;
      if (t > bestMock) bestMock = t;
    }
    final meritGap = 82.5 - bestMock;
    return Container(
      color: _pageBg,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
        // HERO — the "balance" card: greeting, big Level figure, progress,
        // three small stats, one primary action. (CBD shows the balance
        // as one large white numeral in a green header.)
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.tealDark, AppColors.navy],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: _tealDark.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(28), child: Image.asset('assets/logo.png', height: 56, width: 56, fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Salaam, ${store.currentName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                Text(store.isGuest ? 'Guest — on this phone only' : 'EPS TOPIK Pro Pakistan • Korea Pakka!',
                    style: const TextStyle(fontSize: 14, color: Colors.white)),
              ])),
            ]),
            const SizedBox(height: 18),
            Text('Level ${store.level}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
            const Text('of 5  •  your test-ready level', style: TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (store.level / 5).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              _stat('$words', 'words'),
              _stat('$days', 'study days'),
              _stat('$mocks', 'mock tests'),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(
                bestMock > 0
                    ? (bestMock >= 82.5 ? 'Best mock $bestMock / 100 — above the 82.5 merit. Keep it up.' : 'Best mock $bestMock / 100 — ${meritGap.toStringAsFixed(1)} points below the 82.5 merit.')
                    : 'No mock yet — your best mock vs the 82.5 merit will show here.',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (bestMock / 82.5).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.tealDark,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: widget.onStart,
                child: Text(continueUnit == 0 && (store.progress['done'] as List? ?? []).isEmpty ? '▶  ${t(lang, 'startLearning')} — Lesson 1' : '▶  Continue — Unit $continueUnit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // CHOOSE YOUR PATH (v1.3.0) — the 2026 test is hard (pass 60/100,
        // Pakistan merit 82.5/100), so Home divides the rush into 3
        // starting points instead of one "Start Learning" for everyone.
        // Each card is a real tap: it sets the starting level (see
        // choosePath in RootPage) and opens the right first screen.
        const Text('Choose your path', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ink)),
        const SizedBox(height: 4),
        const Text('The 2026 test is hard — pass 60/100, merit 82.5/100. Pick where YOU start. You can change path any time; nothing is locked and finished units stay finished.',
            style: TextStyle(fontSize: 14, color: _muted)),
        const SizedBox(height: 10),
        _pathCard(
          icon: Icons.school, badge: 'BASIC', badgeColor: AppColors.greenDark,
          title: 'Basic — Start from zero',
          desc: 'You know no Korean yet, or only a few words.',
          includes: 'Hangul alphabet walk (21 vowels + 19 consonants) • Syllable / word builder • First words • Units 0–10 • Notebook Time',
          focus: 'Focus: read + write Korean letters first, then first words.',
          button: 'Start Basic — Hangul',
          isCurrent: store.level == 1,
          onTap: () => widget.onChoosePath('basic'),
        ),
        const SizedBox(height: 12),
        _pathCard(
          icon: Icons.menu_book, badge: 'MID', badgeColor: AppColors.orangeDark,
          title: 'Mid — I know some Korean',
          desc: 'You can read Hangul and know some words. Skip the basics.',
          includes: 'Start at Unit 11 • Units 11–30 daily life • Grammar • Vocabulary pages • Listening / reading practice',
          focus: 'Focus: daily-life Korean, grammar and longer sentences.',
          button: 'Start Mid — Unit 11',
          isCurrent: store.level == 3,
          onTap: () => widget.onChoosePath('mid'),
        ),
        const SizedBox(height: 12),
        _pathCard(
          icon: Icons.workspace_premium, badge: 'EXPERT / HARD', badgeColor: AppColors.red,
          title: 'Expert — Test-ready',
          desc: 'You are aiming at the 82.5/100 merit, not just the 60 pass.',
          includes: 'Units 31–60 workplace Korean • Safety signs, laws & insurance • Skill Test tasks • Expert Mock (40q / 50 min / 100) • Analytics',
          focus: 'Focus: workplace Korean + hard mock tests until you beat 82.5.',
          button: 'Start Expert — Unit 31',
          isCurrent: store.level == 5,
          onTap: () => widget.onChoosePath('expert'),
          secondaryButton: 'Take Expert Mock →',
          onSecondaryTap: () => widget.onChoosePath('expert-mock'),
        ),
        const SizedBox(height: 20),
        // QUICK ACTIONS — one row of 4 round actions, like CBD's
        // Transfers / Request / Pay row under its balance header.
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _quickAction(Icons.school, _navy, t(lang, 'learn'), () => widget.onGo(1, 'Learn')),
          _quickAction(Icons.mic, _green, t(lang, 'tutor'), () => widget.onGo(3, 'Tutor')),
          _quickAction(Icons.timer, AppColors.red, t(lang, 'mock'), () => widget.onGo(2, 'Mock')),
          _quickAction(Icons.videogame_asset, AppColors.purple, 'Games', () => widget.onGo(4, 'More')),
        ]),
        const SizedBox(height: 20),
        // TODAY — the only plan on Home; the full 12-week plan lives in Learn.
        _card(children: [
          _cardHead('📅', 'Today — ${week[0]}'),
          Text(week[1], style: const TextStyle(fontSize: 15, color: _ink)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => widget.onGo(1, 'Learn'),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('View in Learn  •  30 min', style: TextStyle(color: AppColors.greenDark, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft, minimumSize: const Size(48, 48)),
          ),
        ]),
        const SizedBox(height: 14),
        // TUTOR QUICK ASK — one tap on a starter question opens Tutor.
        _card(children: [
          _cardHead('🎤', t(lang, 'tutor')),
          const Text('Ask in Pashto, Sindhi, Saraiki, Punjabi, Urdu or English — hear the Korean answer.',
              style: TextStyle(fontSize: 14, color: _muted)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in tutorStarters.take(3))
              ActionChip(
                label: Text(s[1], style: const TextStyle(fontSize: 14)),
                backgroundColor: const Color(0xFFE8F5E9),
                onPressed: () => widget.onGo(3, 'Tutor'),
              ),
          ]),
        ]),
        const SizedBox(height: 14),
        // MOCK QUICK START — pass / merit lines live here and in Mock.
        _card(children: [
          _cardHead('📝', 'Mock Test — Basic & Expert'),
          const Text('40 questions  •  50 min  •  100 points', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _ink)),
          const Text('Pass 60  •  Pakistan 2026 merit 82.5', style: TextStyle(fontSize: 14, color: _muted)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => widget.onGo(2, 'Mock'),
              child: const Text('Open Mock Test', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        // EXPLORE — everything else, one card, five rows, each to its tab.
        // Learn holds Hangul, Vocabulary, Units 0–60, Skill Test, Culture,
        // Life & Work, Emergency phrases, Docs and the 12-week plan;
        // Practice holds Speak Test, Games and Notebook.
        const Text('Explore', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _ink)),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            _exploreRow(Icons.school, _navy, t(lang, 'learn'), 'Hangul • Vocabulary • Units 0–60', () => widget.onGo(1, 'Learn')),
            _exploreRow(Icons.edit, _green, t(lang, 'practice'), 'Speak Test • Games • Notebook', () => widget.onGo(4, 'More')),
            _exploreRow(Icons.timer, AppColors.red, t(lang, 'mock'), 'Basic & Expert • Results & analytics', () => widget.onGo(2, 'Mock')),
            _exploreRow(Icons.public, AppColors.tealDark, 'Life in Korea', 'Skill Test • Culture • Rights • Documents', () => widget.onLearnSection('life')),
            _exploreRow(Icons.settings, _muted, t(lang, 'settings'), 'Language • Account • Sound • Help', () => widget.onGo(4, 'More'), last: true),
          ]),
        ),
        const SizedBox(height: 14),
        const Text('Not affiliated with OEC or HRD Korea. Check the latest OEC notice at jobs.oec.gov.pk.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _muted)),
      ]),
    );
  }

  Widget _stat(String value, String label) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ]));

  Widget _quickAction(IconData icon, Color c, String label, VoidCallback onTap) => Expanded(child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Icon(icon, color: c, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
        ]),
      ));

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _cardHead(String emoji, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _ink))),
        ]),
      );

  Widget _pathCard({required IconData icon, required String badge, required Color badgeColor, required String title, required String desc, required String includes, required String focus, required String button, required bool isCurrent, required VoidCallback onTap, String? secondaryButton, VoidCallback? onSecondaryTap}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border(left: BorderSide(color: badgeColor, width: 6)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: badgeColor, size: 24),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
              child: Text(badge, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const Spacer(),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                child: const Text('✓ Your path', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
              ),
          ]),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _ink)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 14, color: _muted)),
          const SizedBox(height: 8),
          Text(includes, style: const TextStyle(fontSize: 14, color: _ink)),
          const SizedBox(height: 6),
          Text(focus, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: badgeColor, minimumSize: const Size.fromHeight(48)),
              onPressed: onTap,
              child: Text(button, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          if (secondaryButton != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondaryTap,
                child: Text(secondaryButton, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: badgeColor)),
              ),
            ),
          ],
        ]),
      );

  Widget _exploreRow(IconData icon, Color c, String title, String sub, VoidCallback onTap, {bool last = false}) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFEEF1F4)))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: c, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _ink)),
              Text(sub, style: const TextStyle(fontSize: 14, color: _muted)),
            ])),
            const Icon(Icons.arrow_forward_ios, size: 15, color: _muted),
          ]),
        ),
      );
}

// ---------------- Learn ----------------
class LearnPage extends StatefulWidget {
  /// v1.3.0 path entry point: 'basic' -> Hangul, 'mid' -> Unit 11,
  /// 'expert' -> Unit 31, 'continue' -> startUnit, 'section:life' -> Life.
  /// Null = normal Learn tab (Hangul).
  final String? start;
  final int? startUnit;
  const LearnPage({super.key, this.start, this.startUnit});
  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  String section = 'hangul';
  @override
  void initState() {
    super.initState();
    if (widget.start == 'mid') { section = 'course'; selectedUnit = 11; }
    if (widget.start == 'expert') { section = 'course'; selectedUnit = 31; }
    if (widget.start == 'continue' && widget.startUnit != null) { section = 'course'; selectedUnit = widget.startUnit; }
    if (widget.start != null && widget.start!.startsWith('section:')) { section = widget.start!.substring(8); }
    // 'basic' (and null) stay on Hangul — the alphabet walk is the start.
  }

  /// P0-1: Back from a Unit/Skill detail returns to the list, not Home.
  bool get hasDetail => selectedUnit != null || selectedSkill != null;
  void closeDetail() => setState(() { selectedUnit = null; selectedSkill = null; });
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
      const Text('✍️ Stroke order: always write top to bottom, left to right. One syllable = one block (e.g. ㅎ + ㅏ + ㄴ = 한). Trace the big letter in the air, then write it 5 times in your notebook.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
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
        _lessonBox('🎭 Situational roleplay — use it at work', u.book == '2'
            ? 'Roleplay with a colleague: you are at work and you must use this unit. Say the Korean sentence aloud, then answer your colleague. Example: boss asks you a question about ${u.en.toLowerCase()} — answer politely with -요 / -습니다, then check with a senior if you are unsure.'
            : 'Roleplay in daily life: you are in Korea and you need ${u.en.toLowerCase()}. Say the Korean sentence aloud to a shopkeeper, a friend or a doctor. If they do not understand, say it slowly again, then point and say “이거요”.'),
        _lessonBox('🔑 5 key words in this unit', ''),
        ...keyWords.map((w) => Card(child: ListTile(title: Text('${w[0]} • ${w[1]}', style: const TextStyle(fontSize: 17)), subtitle: Text('${w[2]} — ${w[3]}'), trailing: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(w[0]))))),
        const SizedBox(height: 8),
        const Text('✏️ Notebook task: write the 5 words above 5 times each, then write one sentence of your own. Tap “I wrote it” in Notebook Time when you finish.', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => speakSlowThenNormal(u.ko), child: const Text('🔊 Hear the unit title in Korean')),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: primaryButtonStyle(),
            onPressed: () async {
              await AppStore.I.setDone('unit_${u.n}', true);
              setState(() { selectedUnit = u.n < 60 ? u.n + 1 : null; });
            },
            child: Text(u.n < 60 ? '✓ Mark done & Next unit →' : '✓ Mark done — course finished'),
          ),
        ),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Life and Work in Korea', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('• Work: factory, farm and other E-9 workplaces. Normal day, working hours, breaks, safety gear. Winter is cold, summer is hot and humid.\n• Labour rights: minimum wage 2026 is 10,320 KRW per hour. Overtime pay, weekly rest day, paid holidays, contract, salary paid on time. Nobody may take your passport. You may change workplace in allowed cases. You may complain.\n• Safety: safety signs, PPE (helmet, gloves, goggles), what to do if hurt — tell your boss, call 119.\n• Help: employer, OEC, HRD Korea EPS Center, Korean labour helpline 1350, emergency 119. Do not pay any agent.\n• Life: housing (dormitory), food, transport, weather, manners at work, bank account.\n• Do NOT: do not overstay, do not work outside your allowed job, do not trust agents who promise a job for money.\n• Based on Units 57–60: EPS System, Labor Standards Act, Immigration Act, Worker Insurance. Check the latest OEC / HRD Korea notice — rules can change. jobs.oec.gov.pk'),
      SizedBox(height: 12),
      Text('Korean culture & manners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      SizedBox(height: 6),
      ...cultureLessons.map((c) => Card(child: Padding(padding: EdgeInsets.all(12), child: Row(children: [Icon(Icons.check_circle, color: AppColors.greenDark, size: 20), SizedBox(width: 8), Expanded(child: Text(c, style: TextStyle(fontSize: 14, color: AppColors.ink)))])))),
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
  int q = 0, score = 0, tries = 0, step = 0, maxStep = 0;
  String feedback = '';
  String heardText = '';
  bool done = false;
  bool listeningMic = false;
  // Tap options, shuffled ONCE per round in state (P0-4) — never in build().
  List<List<String>> tapOptions = [];

  @override
  void initState() {
    super.initState();
    _regenTapOptions();
  }

  void _regenTapOptions() {
    final w = vocab[q % vocab.length];
    final rnd = Random();
    final others = <List<String>>[];
    final used = {q % vocab.length};
    while (others.length < 3) {
      final i = rnd.nextInt(vocab.length);
      if (used.add(i)) others.add(vocab[i]);
    }
    tapOptions = [w, ...others]..shuffle(rnd);
  }

  void _advanceStep(int s) {
    setState(() {
      step = s;
      if (s > maxStep) maxStep = s;
    });
  }

  // Honest similarity (P0-4): exact match or Levenshtein <= 1-2 ONLY.
  // The old contains() shortcut let "물" pass for "물 주세요" — removed.
  bool _isClose(String heard, String target) {
    String norm(String x) => x.replaceAll(RegExp(r'[\s\.\?\!]+'), '').trim();
    final h = norm(heard), t = norm(target);
    if (h.isEmpty) return false;
    if (h == t) return true;
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
      const Text('Practice — Speak Test', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const Text('How to practise, like a teacher teaches it. Follow the steps in order — do not skip Step 1.'),
      const SizedBox(height: 10),
      // Locked sequence (P0-4): future steps are not tappable.
      LinearProgressIndicator(value: (step + 1) / 5, minHeight: 8, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.greenDark)),
      const SizedBox(height: 8),
      Text('Step ${step + 1} of 5 — ${steps[step].substring(3)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink)),
      const SizedBox(height: 8),
      Wrap(spacing: 6, children: steps.asMap().entries.map((e) => ChoiceChip(
        label: Text(e.value, style: const TextStyle(fontSize: 14)),
        selected: step == e.key,
        onSelected: e.key <= maxStep ? (_) => setState(() => step = e.key) : null,
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
          ElevatedButton(onPressed: () { _advanceStep(1); speakSlowThenNormal(w[0]); }, child: const Text('🔊 Listen')),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangeDark),
            onPressed: () { _advanceStep(2); _speakTest(w[0]); },
            child: const Text('🎤 Speak on mic'),
          ),
        ]),
        // Listening indicator (P0-4): visible state while the mic is live.
        if (listeningMic) Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.mic, color: AppColors.red, size: 24),
            SizedBox(width: 8),
            Text('Listening… say it now, clearly, once.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.red)),
          ]),
        ),
        const SizedBox(height: 8),
        const Text('Or tap the word you heard:'),
        Wrap(spacing: 8, children: tapOptions.map((v) => ElevatedButton(
          onPressed: () { _advanceStep(3); _answer(v[0] == w[0], w[0]); },
          child: Text(v[0]),
        )).toList()),
        if (heardText.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('You said: $heardText', style: const TextStyle(fontSize: 14, color: AppColors.muted))),
        if (heardText.isNotEmpty && heardText != '(nothing heard)')
          Padding(padding: const EdgeInsets.only(top: 6), child: TextButton.icon(
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Hear what you said', style: TextStyle(fontSize: 14)),
            onPressed: () => speakSlowThenNormal(heardText),
          )),
        if (heardText.isNotEmpty) const Padding(padding: EdgeInsets.only(top: 2), child: Text('(Replayed by TTS from the recognised text — not a recording of your voice.)', style: TextStyle(fontSize: 14, color: AppColors.muted))),
        if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(feedback, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        if (done) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Score: $score correct. ${score >= 3 ? "Wah bhai wah, Korea pakka!" : "Ghalat jawab, lekin himmat na haar, dobara kar!"}')),
        if (tries >= 3) TextButton(onPressed: () { setState(() { tries = 0; feedback = ''; step = 0; maxStep = 0; }); }, child: const Text('📚 Learn Again — back to this lesson')),
      ]))),
      const SizedBox(height: 14),
      const Text('Culture & manners — real situations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const Text('Tap a situation to see what to do, what NOT to do, and the Korean words to say.'),
      const SizedBox(height: 8),
      ...cultureScenarios.map((c) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c[0], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Situation: ${c[1]}'),
        Row(children: const [Icon(Icons.check_circle, color: AppColors.greenDark, size: 18), SizedBox(width: 6), Text('Do:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
        Text(c[2], style: const TextStyle(color: AppColors.greenDark, fontSize: 14)),
        Row(children: const [Icon(Icons.cancel, color: AppColors.red, size: 18), SizedBox(width: 6), Text('Do NOT:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]),
        Text(c[3], style: const TextStyle(color: AppColors.red, fontSize: 14)),
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
      if (step > maxStep) maxStep = 3;
      if (correct) {
        score++;
        feedback = 'Very good! ⭐ $target — correct.';
        q++;
        tries = 0;
        _regenTapOptions();
        if (q >= 5) done = true;
      } else {
        tries++;
        feedback = tries >= 3
            ? 'Not quite yet — listen again. Why: the sounds you said did not match $target. Listen to each letter of $target, then say it slowly. You have tried 3 times: tap Learn Again to go back to that lesson, then come back.'
            : 'Not quite yet — listen again. Why: the word you said was not $target — listen to the first sound again, then try ${3 - tries} more time(s).';
        speak(target);
      }
    });
  }

  Future<void> _speakTest(String target) async {
    final stt = SpeechToText();
    try {
      final ok = await stt.initialize();
      if (!ok) { setState(() { listeningMic = false; feedback = 'Mic / speech recognition is not available on this phone. Use Listen-and-Tap instead — the test is never blocked.'; }); return; }
      setState(() { listeningMic = true; feedback = 'Listening… say it now, clearly, once.'; heardText = ''; });
      await stt.listen(onResult: (r) {
        if (r.finalResult) {
          final heard = r.recognizedWords;
          setState(() { listeningMic = false; heardText = heard.isEmpty ? '(nothing heard)' : heard; });
          _answer(_isClose(heard, target), target);
          stt.stop();
        }
      }, localeId: 'ko-KR');
    } catch (_) {
      setState(() { listeningMic = false; feedback = 'Mic not available. Use Listen-and-Tap instead.'; });
    }
  }
}

// ---------------- Mock Test ----------------
class MockPage extends StatefulWidget {
  /// v1.3.0: Expert path can open Mock with 'expert' pre-selected.
  final String initialDifficulty;
  final VoidCallback? onGoLearn;
  const MockPage({super.key, this.initialDifficulty = 'basic', this.onGoLearn});
  @override
  State<MockPage> createState() => _MockPageState();
}

class _MockPageState extends State<MockPage> {
  int qi = 0, listening = 0, reading = 0;
  bool started = false, finished = false, paused = false;
  String difficulty = 'basic';
  @override
  void initState() {
    super.initState();
    difficulty = widget.initialDifficulty;
  }
  int secondsLeft = 50 * 60;
  // P0-2: palette + flag + per-question answers.
  final Set<int> flagged = {};
  final List<int> answers = List<int>.filled(40, -1);
  bool showPalette = false;
  int? selectedIdx;
  bool answered = false;
  // Listening: plays per question (auto-play counts as 1, max 2 total).
  final Map<int, int> listeningPlays = {};
  int autoPlayedQi = -1;

  List<String> _options(String correct, List<String> wrongs, int seed) {
    final opts = <String>[correct, ...wrongs]..shuffle(Random(seed));
    return opts;
  }

  int get _timeUsed => 50 * 60 - secondsLeft;

  @override
  Widget build(BuildContext context) {
    if (!started) {
      final mocks = (AppStore.I.progress['mocks'] as List? ?? []);
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Mock Test — 40 questions, 50 minutes, 100 points', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const Text('20 reading + 20 listening. Passing floor 60/100. Pakistan 2026 merit 82.5/100 (reported — check the latest OEC notice).'),
        const SizedBox(height: 12),
        const Text('Choose your difficulty:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Card(color: difficulty == 'basic' ? const Color(0xFFE8F5E9) : Colors.white, child: ListTile(
          leading: const Icon(Icons.check_circle_outline, color: AppColors.greenDark, size: 28),
          title: const Text('Basic — for beginners', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Easy words and short questions. Learn the format, build confidence.'),
          trailing: difficulty == 'basic' ? const Icon(Icons.check_circle, color: AppColors.greenDark) : null,
          onTap: () => setState(() => difficulty = 'basic'),
        )),
        Card(color: difficulty == 'expert' ? const Color(0xFFFFEBEE) : Colors.white, child: ListTile(
          leading: const Icon(Icons.workspace_premium, color: AppColors.red, size: 28),
          title: const Text('Expert — real test level', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Harder, longer, real EPS-TOPIK style reading and listening from the new syllabus (Units 1–60, safety, laws). Aiming at the 82.5/100 merit, not just the 60 pass floor.'),
          trailing: difficulty == 'expert' ? const Icon(Icons.check_circle, color: AppColors.red) : null,
          onTap: () => setState(() => difficulty = 'expert'),
        )),
        const SizedBox(height: 12),
        ElevatedButton(
          style: primaryButtonStyle(bg: AppColors.orangeDark),
          onPressed: () => setState(() { started = true; _tick(); }),
          child: Text('Start ${difficulty == 'expert' ? 'Expert' : 'Basic'} mock (50 min)', style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        const Text('Your past attempts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (mocks.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('No mock attempts yet — take your first mock above.', style: TextStyle(fontSize: 14, color: AppColors.muted))),
        ...mocks.map((m) => ListTile(
          title: Text('Listening ${m['l']}/20 • Reading ${m['r']}/20'),
          subtitle: Text('${(m['d'] ?? 'basic') == 'expert' ? 'Expert' : 'Basic'} • ${(m['date'] ?? '').toString().substring(0, 10)} • Score ${(m['l'] + m['r']) * 2.5}/100 — ${((m['l'] + m['r']) * 2.5) >= 60 ? 'Passed (60)' : 'Below passing'} • ${((m['l'] + m['r']) * 2.5) >= 82.5 ? 'Above merit 82.5' : 'Below merit 82.5'}${m['secs'] != null ? ' • Time ${formatMmSs(m['secs'] as int)}' : ''}'),
        )),
      ]);
    }
    if (finished) {
      final total = (listening + reading) * 2.5;
      final weakListening = listening <= reading;
      return Center(child: Padding(padding: const EdgeInsets.all(20), child: ListView(shrinkWrap: true, children: [
        Text('Result: $total / 100', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text('Listening $listening/20 • Reading $reading/20'),
        const SizedBox(height: 12),
        _resultBar('Listening', listening * 5),
        _resultBar('Reading', reading * 5),
        const SizedBox(height: 8),
        Text('Analytics: Listening ${listening * 5}%  •  Reading ${reading * 5}%  •  Pass line 60  •  Merit line 82.5'),
        Text(weakListening
            ? 'Weak area: Listening — do 10 minutes of Listen-and-Tap every day before your next mock.'
            : 'Weak area: Reading — re-read Units 1–30 slowly, then try the Expert mock again.',
            textAlign: TextAlign.center),
        Text('Time used: ${formatMmSs(_timeUsed)} of 50 minutes. In the real CBT test the clock never stops — finish each question in about 75 seconds.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        Text('${difficulty == 'expert' ? 'Expert' : 'Basic'} mock', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(total >= 82.5 ? 'Wah bhai wah, Korea pakka! Above merit.' : total >= 60 ? 'Passed the floor (60), but below merit 82.5 — practise your weak topics.' : 'Ghalat jawab, lekin himmat na haar, dobara kar! Below 60 — learn again.'),
        const SizedBox(height: 12),
        if (widget.onGoLearn != null)
          OutlinedButton(onPressed: widget.onGoLearn, child: Text(weakListening ? 'Practise Listening in Learn →' : 'Practise Reading in Learn →')),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => setState(() { started = false; finished = false; qi = 0; listening = 0; reading = 0; secondsLeft = 50 * 60; answers.fillRange(0, 40, -1); flagged.clear(); selectedIdx = null; answered = false; listeningPlays.clear(); autoPlayedQi = -1; }), child: const Text('Back')),
      ])));
    }
    final isListening = qi < 20;
    final isExpert = difficulty == 'expert';
    late String prompt, promptKo;
    late List<String> options;
    late String correctText;
    if (isExpert) {
      // P0-2: 40 UNIQUE questions — bank[qi] directly, never bank[qi % 20].
      final bank = isListening ? expertListening : expertReading;
      final e = bank[isListening ? qi : qi - 20];
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
    // P0-2: listening auto-plays ONCE when the question first shows.
    if (isListening && autoPlayedQi != qi) {
      autoPlayedQi = qi;
      listeningPlays[qi] = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => speak(promptKo));
    }
    final plays = listeningPlays[qi] ?? 0;
    const letters = ['A', 'B', 'C', 'D'];
    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: Text('⏱ ${formatMmSs(secondsLeft)} left — ${isExpert ? 'Expert' : 'Basic'} — Question ${qi + 1}/40 (${isListening ? 'Listening' : 'Reading'})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          IconButton(icon: Icon(paused ? Icons.play_arrow : Icons.pause, color: AppColors.navy), tooltip: paused ? 'Resume' : 'Pause', onPressed: () => setState(() => paused = !paused)),
          IconButton(icon: const Icon(Icons.exit_to_app, color: AppColors.red), tooltip: 'Exit mock', onPressed: _confirmExit),
        ]),
        if (paused)
          const Card(color: Color(0xFFFFF3E0), child: Padding(padding: EdgeInsets.all(14), child: Text('Paused — the clock is stopped. Tap Resume (top right) to continue.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.grid_view, size: 18), label: Text(showPalette ? 'Hide palette' : 'Question palette', style: const TextStyle(fontSize: 14)), onPressed: () => setState(() => showPalette = !showPalette))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            icon: Icon(flagged.contains(qi) ? Icons.flag : Icons.flag_outlined, size: 18, color: flagged.contains(qi) ? AppColors.orangeDark : AppColors.muted),
            label: Text(flagged.contains(qi) ? 'Flagged — review later' : 'Flag for review', style: const TextStyle(fontSize: 14)),
            onPressed: () => setState(() { flagged.contains(qi) ? flagged.remove(qi) : flagged.add(qi); }),
          )),
        ]),
        if (showPalette) ...[
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1),
            itemCount: 40,
            itemBuilder: (_, i) {
              final isCurrent = i == qi;
              final isAnswered = answers[i] != -1;
              final isFlagged = flagged.contains(i);
              return InkWell(
                onTap: () => setState(() { qi = i; selectedIdx = answers[i] == -1 ? null : answers[i]; answered = answers[i] != -1; }),
                child: Container(
                  decoration: BoxDecoration(
                    color: isAnswered ? AppColors.navy : Colors.white,
                    border: Border.all(color: isCurrent ? AppColors.orangeDark : AppColors.border, width: isCurrent ? 2 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text('${i + 1}${isFlagged ? '⚑' : ''}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isAnswered ? Colors.white : AppColors.ink))),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          Text(prompt, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          if (isListening) ...[
            // P0-2: audio-only listening — Korean text hidden until answered.
            if (!answered)
              const Text('Korean text hidden — listen carefully.', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.muted)),
            if (answered) Text(promptKo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: plays < 2 ? () { setState(() => listeningPlays[qi] = plays + 1); speak(promptKo); } : null,
              child: Text(plays == 0 ? '🔊 Hear it' : plays == 1 ? '🔊 Hear again (1 replay left)' : '🔊 No replays left'),
            ),
          ] else
            Text(promptKo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...options.asMap().entries.map((e) {
            final idx = e.key, opt = e.value;
            final isSelected = selectedIdx == idx;
            final isCorrect = opt == correctText;
            Color? bg;
            if (answered && isSelected) bg = isCorrect ? AppColors.greenDark : AppColors.red;
            if (answered && isCorrect) bg = AppColors.greenDark;
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
              style: bg != null ? ElevatedButton.styleFrom(backgroundColor: bg, minimumSize: const Size.fromHeight(52)) : null,
              onPressed: answered ? null : () {
                setState(() {
                  selectedIdx = idx;
                  answered = true;
                  answers[qi] = idx;
                  if (opt == correctText) { if (isListening) { listening++; } else { reading++; } }
                });
              },
              child: Text('${letters[idx]}. $opt', style: const TextStyle(fontSize: 14)),
            )));
          }),
          if (answered) ...[
            const SizedBox(height: 8),
            Text(selectedIdx != null && options[selectedIdx!] == correctText ? 'Correct! ✓' : 'Not correct — the right answer is: $correctText',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: primaryButtonStyle(),
                onPressed: () async {
                  if (qi + 1 >= 40) {
                    await AppStore.I.addMock(listening, reading, difficulty: difficulty, secondsUsed: _timeUsed);
                    setState(() => finished = true);
                  } else {
                    setState(() { qi++; selectedIdx = answers[qi] == -1 ? null : answers[qi]; answered = answers[qi] != -1; });
                  }
                },
                child: Text(qi + 1 >= 40 ? 'Finish & see result' : 'Next question →'),
              ),
            ),
          ],
        ]))),
      ]),
    );
  }

  Widget _resultBar(String label, int pct) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label — $pct%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: pct / 100, minHeight: 10, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.navy)),
        ]),
      );

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit the mock?'),
        content: const Text('Your progress in this mock will be lost. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Exit mock', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (leave == true) {
      setState(() { started = false; finished = false; qi = 0; listening = 0; reading = 0; secondsLeft = 50 * 60; answers.fillRange(0, 40, -1); flagged.clear(); selectedIdx = null; answered = false; listeningPlays.clear(); autoPlayedQi = -1; });
    }
  }

  void _tick() async {
    while (started && !finished && secondsLeft > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      if (paused) continue;
      setState(() => secondsLeft--);
    }
    if (started && secondsLeft <= 0 && !finished) {
      await AppStore.I.addMock(listening, reading, difficulty: difficulty, secondsUsed: _timeUsed);
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
      const Text('Note: speech recognition depends on the phone — if your language is not supported on this phone, the app says so and typing always works. The tutor answers from its built-in question bank; if it does not know your question, it says so honestly instead of guessing.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
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
  // Options shuffled ONCE per round in state — never in build(), or the
  // correct answer moves under the user's finger on every rebuild.
  List<List<String>> gameOptions = [];

  @override
  void initState() {
    super.initState();
    _regenOptions();
  }

  void _regenOptions() {
    final w = vocab[round % vocab.length];
    gameOptions = [w, vocab[(round + 5) % vocab.length], vocab[(round + 11) % vocab.length], vocab[(round + 17) % vocab.length]]..shuffle(rnd);
  }

  @override
  Widget build(BuildContext context) {
    final w = vocab[round % vocab.length];
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
        ...gameOptions.map((o) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: () {
            setState(() {
              if (o[0] == w[0]) { stars++; msg = 'Wah bhai wah, Korea pakka! ⭐'; round++; }
              else { msg = 'Ghalat jawab, lekin himmat na haar, dobara kar!'; }
              if (round >= 8) { msg += ' Game finished — $stars/8 stars!'; round = 0; stars = 0; }
              _regenOptions();
            });
          },
          child: Text('${o[0]} — ${o[2]}'),
        )))),
        if (msg.isNotEmpty) Text(msg, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ]))),
      const SizedBox(height: 12),
      const Text('Daily Challenge: play Listen and Tap every day and keep your streak.'),
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
      const Text('Help: if you are stuck, ask your teacher or message the app owner on WhatsApp. Version 1.4.0 (APK test build).', style: TextStyle(fontSize: 14, color: AppColors.muted)),
    ]);
  }
}
