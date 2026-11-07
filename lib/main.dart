import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';
import 'v17.dart'; // v1.7.0: OEC Tracker + Speak to Korea

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
    // v1.6.1: showcase blue theme + Dark Mode toggle (Settings).
    return ValueListenableBuilder<bool>(
      valueListenable: AppStore.darkModeNotifier,
      builder: (_, dark, __) => MaterialApp(
      title: 'EPS TOPIK Pro Pakistan',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.royalBlue, primary: AppColors.royalBlue, secondary: AppColors.tealDark, tertiary: AppColors.pakGreen),
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        fontFamily: AppStore.I.lang == 'script' ? 'NotoNastaliq' : null,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.royalDark, foregroundColor: Colors.white, centerTitle: false),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        cardTheme: const CardThemeData(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.royalBlue, primary: AppColors.royalBlue, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(backgroundColor: AppColors.royalDark, foregroundColor: Colors.white, centerTitle: false),
        elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
        cardTheme: const CardThemeData(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20)))),
      ),
      home: const RootPage(),
      ),
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
        selectedItemColor: AppColors.royalBlue,
        unselectedItemColor: AppColors.muted,
        selectedFontSize: 14,
        unselectedFontSize: 14,
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
      const Text('Learn more', style: AppHeadings.sectionTitle),
      const SizedBox(height: 8),
      _row(context, Icons.bar_chart, AppColors.royalBlue, 'My Progress', 'Overall score • Streak • Weak topics', () => _open(context, 'My Progress', const ProgressPage())),
      _row(context, Icons.star, AppColors.orangeDark, 'Daily Quiz', '10 questions • +50 coins', () => _open(context, 'Daily Quiz', const DailyQuizPage())),
      _row(context, Icons.text_fields, AppColors.purple, 'Grammar', '120 points • -아요 / -어요', () => _open(context, 'Grammar', const GrammarPage())),
      _row(context, Icons.style, AppColors.purple, 'Flashcards', 'Flip cards • Know / Don\'t know', () => _open(context, 'Flashcards', const FlashcardPage())),
      _row(context, Icons.headphones, AppColors.tealDark, 'Listening drills', 'Numbers & Time • Conversation', () => _open(context, 'Listening drills', const ListeningDrillPage())),
      _row(context, Icons.menu_book, AppColors.navy, 'Official books & checks', 'HRD Korea books • Colour-vision check', () => _open(context, 'Official books & checks', LearnPage(start: 'section:official'))),
      _row(context, Icons.public, AppColors.pakGreen, 'OEC Tracker', 'Lucky draw • Merit 82.5 • Your best mock', () => _open(context, 'OEC Tracker', const OecTrackerPage())),
      const SizedBox(height: 12),
      const Text('Practice & app', style: AppHeadings.sectionTitle),
      const SizedBox(height: 8),
      _row(context, Icons.edit, AppColors.navy, 'Practice', 'Speak Test • Culture & manners • Notebook', () => _open(context, 'Practice', const PracticePage())),
      _row(context, Icons.record_voice_over, AppColors.greenDark, 'Speak to Korea', 'Talk to your boss • Honest feedback', () => _open(context, 'Speak to Korea', const SpeakToKoreaPage())),
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
          // v1.6.1 showcase splash — OUR 9.5 handshake logo (never the
          // showcase flag logo), blue gradient, Korea Pakka! in green.
          Container(
            decoration: BoxDecoration(gradient: showcaseGradient, borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.asset('assets/logo.png', height: 140, width: 140, fit: BoxFit.cover)),
              ),
              const SizedBox(height: 12),
              const Text('EPS TOPIK Pro Pakistan', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Korean Language for a Better Tomorrow', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.pakGreen, borderRadius: BorderRadius.circular(20)),
                child: const Text('🇵🇰 Korea Pakka!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 12),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.menu_book, color: Colors.white, size: 18), SizedBox(width: 6),
                Text('Study Smart', style: TextStyle(fontSize: 14, color: Colors.white)),
                SizedBox(width: 12),
                Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 6),
                Text('Practice Better', style: TextStyle(fontSize: 14, color: Colors.white)),
              ]),
              const SizedBox(height: 6),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 18), SizedBox(width: 6),
                Text('Achieve Your Goal', style: TextStyle(fontSize: 14, color: Colors.white)),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
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
// v1.6.0 serious redesign — audit of the v1.5.0 Home (see report):
//   1. ~2,800px of scroll: hero (~380px, TWO progress bars, 3 stats,
//      merit line + bar) + 3 path cards (~950px of text walls) + 4 quick
//      actions + Today card + Tutor card + Mock card + 6-row Explore list.
//   2. ~18 competing tappable targets, 6+ "primary" actions (Continue,
//      3 path buttons + Expert Mock, Today View, Tutor chips, Mock Open).
//   3. Tutor chips navigated to Tutor WITHOUT the question (dead tap),
//      Today "View in Learn" opened Hangul, not the plan, and Games
//      quick-action opened the More tab (label mismatch).
//   4. Local colour constants duplicated AppColors; 69x 14pt text.
// New Home, one section at a time, ~1,300px:
//   Hero (ONE figure: your next unit + ONE button) -> Paths (3 compact
//   tiles in one row) -> Quick actions (one row of 4) -> Today strip
//   (one line, opens the 12-week plan sheet) -> Sections 3x3 grid
//   (every main area, one tap, counts where they belong) -> Free
//   promise strip + footer. Nothing deleted: every old Home destination
//   is in the grid, the quick row, or the plan sheet.
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
  void _showPlanSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            const Text('12-week Self-Study Plan — 30 min a day', style: AppHeadings.sectionTitle),
            const Text('Free. A notebook and a pen is all you need. One week at a time.', style: AppHeadings.sectionSub),
            const SizedBox(height: 12),
            ...selfStudyPlan.asMap().entries.map((e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: AppColors.navy, child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(e.value[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text(e.value[1], style: const TextStyle(fontSize: 14)),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStore.I.lang;
    final store = AppStore.I;
    final wordsMastered = (store.progress['words'] as Map? ?? {}).values.where((v) => v == 'mastered').length;
    final days = (store.progress['days'] as List? ?? []).length;
    final doneUnits = List.generate(61, (n) => store.isDone('unit_$n')).where((d) => d).length;
    final weekIdx = ((days / 7).floor()).clamp(0, selfStudyPlan.length - 1);
    final week = selfStudyPlan[weekIdx];
    int continueUnit = 0;
    for (int n = 0; n <= 60; n++) { if (!store.isDone('unit_$n')) { continueUnit = n; break; } }
    final continueName = units[continueUnit].en;
    double bestMock = 0;
    for (final m in (store.progress['mocks'] as List? ?? [])) {
      final totalQ = (m['total'] ?? 40) as int;
      final t = totalQ > 0 ? ((m['l'] ?? 0) + (m['r'] ?? 0)) * 100 / totalQ : 0.0;
      if (t > bestMock) bestMock = t;
    }
    final meritLine = bestMock > 0
        ? 'Best mock ${bestMock.toStringAsFixed(0)}/100 — ${bestMock >= 82.5 ? 'above the 82.5 merit ✓' : '${(82.5 - bestMock).toStringAsFixed(0)} points to the 82.5 merit'}'
        : 'No mock yet — pass 60, merit 82.5 (Pakistan 2026)';
    return Container(
      color: AppColors.pageBg,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
        // HERO — ONE figure, ONE action. The figure is your NEXT lesson
        // (Unit N + its name + units done), not a vanity Level number.
        // The merit line is text only — the second progress bar is gone.
        Container(
          decoration: BoxDecoration(
            gradient: heroGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
            boxShadow: [BoxShadow(color: AppColors.royalBlue.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/logo.png', height: 48, width: 48, fit: BoxFit.cover)),
              const SizedBox(width: 10),
              Expanded(child: Text('Salaam, ${store.currentName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.white), borderRadius: BorderRadius.circular(20)),
                child: Text('Level ${store.level}/5', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.pakGreen, borderRadius: BorderRadius.circular(20)),
              child: const Text('🇵🇰 Pro Pakistan • Korea Pakka!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 12),
            const Text('안녕하세요!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const Text('Ready to learn Korean?', style: TextStyle(fontSize: 15, color: Colors.white)),
            const SizedBox(height: 16),
            const Text('Your next lesson', style: TextStyle(fontSize: 14, color: Colors.white)),
            Text('Unit $continueUnit', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
            Text(continueName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: doneUnits / 61, minHeight: 8, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation(Colors.white)),
            ),
            const SizedBox(height: 6),
            Text('$doneUnits of 61 units done  •  $meritLine', style: const TextStyle(fontSize: 14, color: Colors.white)),
            const SizedBox(height: 8),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
                child: Text('🔥 $days study days', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppColors.pakGreen, borderRadius: BorderRadius.circular(20)),
                child: Text('⭐ $wordsMastered words known', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.royalDark, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusButton))),
                onPressed: widget.onStart,
                child: Text('▶  Continue — Unit $continueUnit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        // v1.6.1 showcase: one big blue Start Mock Test button.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalBlue, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusButton))),
            onPressed: () => widget.onGo(2, 'Mock'),
            child: const Text('Start Mock Test  >', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        // CHOOSE YOUR PATH — 3 compact tiles in ONE row, not 3 text walls.
        // Badge + icon + 2-line title + 1-line desc. Tap = start there.
        // The "✓ Your path" chip marks the current level; nothing is
        // locked and finished units stay finished.
        const Text('Choose your path', style: AppHeadings.sectionTitle),
        const Text('The 2026 test is hard — pass 60/100, merit 82.5/100. Pick where YOU start.', style: AppHeadings.sectionSub),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _pathTile(icon: Icons.school, badge: 'BASIC', badgeColor: AppColors.greenDark, title: 'Start from zero', desc: 'No Korean yet? Hangul first.', isCurrent: store.level == 1, onTap: () => widget.onChoosePath('basic')),
          const SizedBox(width: 8),
          _pathTile(icon: Icons.menu_book, badge: 'MID', badgeColor: AppColors.orangeDark, title: 'I know some Korean', desc: 'Skip basics — Unit 11.', isCurrent: store.level == 3, onTap: () => widget.onChoosePath('mid')),
          const SizedBox(width: 8),
          _pathTile(icon: Icons.workspace_premium, badge: 'EXPERT', badgeColor: AppColors.red, title: 'Test-ready', desc: 'Unit 31 + hard mock.', isCurrent: store.level == 5, onTap: () => widget.onChoosePath('expert')),
        ]),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => widget.onChoosePath('expert-mock'), child: const Text('Expert Mock → 40 questions, 50 min', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.red))),
        ),
        const SizedBox(height: 8),
        // QUICK ACTIONS — one row of 4. Flashcards replaces Games here:
        // Games opened the More tab, which confused the label; Games
        // still lives in the grid below and in More.
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _quickAction(Icons.school, AppColors.navy, t(lang, 'learn'), () => widget.onGo(1, 'Learn')),
          _quickAction(Icons.timer, AppColors.red, t(lang, 'mock'), () => widget.onGo(2, 'Mock')),
          _quickAction(Icons.mic, AppColors.greenDark, t(lang, 'tutor'), () => widget.onGo(3, 'Tutor')),
          _quickAction(Icons.style, AppColors.purple, 'Flashcards', () => widget.onLearnSection('flashcards')),
        ]),
        const SizedBox(height: AppSpacing.section),
        // TODAY — one slim strip, not a card. Tap opens the real
        // 12-week plan (bottom sheet), fixing the old "View in Learn"
        // link that opened Hangul instead of the plan.
        InkWell(
          onTap: _showPlanSheet,
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
            child: Row(children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Today — ${week[0]}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
                Text('${week[1]}  •  30 min  •  Tap for the 12-week plan →', style: const TextStyle(fontSize: 14, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        // SECTIONS — v1.6.1 showcase 3-col grid: Vocabulary / Listening /
        // Reading / Grammar / Daily Quiz / More. Counts are OURS (329 words,
        // 35 drills, 40 Expert questions, 120 grammar points, 10-question
        // Daily Quiz) — not the showcase's 600+ words.
        const Text('Learn & practise', style: AppHeadings.sectionTitle),
        const Text('Everything in the app — one tap.', style: AppHeadings.sectionSub),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.92,
          children: [
            _sectionTile(icon: Icons.book, tint: AppColors.softBlue, color: AppColors.royalBlue, label: 'Vocabulary', sub: '329 words • $wordsMastered ⭐', onTap: () => widget.onLearnSection('vocab')),
            _sectionTile(icon: Icons.headphones, tint: AppColors.softGreen, color: AppColors.greenDark, label: 'Listening', sub: 'Numbers • Talk', onTap: () => widget.onLearnSection('listening')),
            _sectionTile(icon: Icons.menu_book, tint: AppColors.softOrange, color: AppColors.orangeDark, label: 'Reading', sub: '20q • Passage', onTap: () => widget.onGo(2, 'Mock')),
            _sectionTile(icon: Icons.text_fields, tint: AppColors.softPurple, color: AppColors.purple, label: 'Grammar', sub: '120 points', onTap: () => _open(context, 'Grammar', const GrammarPage())),
            _sectionTile(icon: Icons.star, tint: AppColors.softAmber, color: AppColors.orangeDark, label: 'Daily Quiz', sub: '10q • +50 coins', onTap: () => _open(context, 'Daily Quiz', const DailyQuizPage())),
            _sectionTile(icon: Icons.more_horiz, tint: AppColors.softNavy, color: AppColors.navy, label: 'More', sub: 'Progress • Games', onTap: () => widget.onGo(4, 'More')),
          ],
        ),
        const SizedBox(height: 8),
        // STUDY MODULES — showcase coloured icon cards with > arrow.
        const Text('Study Modules', style: AppHeadings.sectionTitle),
        const Text('Pick a module — each one shows what is inside.', style: AppHeadings.sectionSub),
        const SizedBox(height: 10),
        _moduleRow(icon: Icons.menu_book, color: AppColors.royalBlue, title: 'Course — Units 0–60', sub: '$doneUnits/61 units • New syllabus 2024 • Grammar 120 points', onTap: () => widget.onLearnSection('course')),
        _moduleRow(icon: Icons.style, color: AppColors.purple, title: 'Flashcards', sub: '329 words • Flip • Know / Don\'t know', onTap: () => widget.onLearnSection('flashcards')),
        _moduleRow(icon: Icons.timer, color: AppColors.red, title: 'Mock Test', sub: bestMock > 0 ? 'Best ${bestMock.toStringAsFixed(0)}/100 • 40q • 50 min' : '40 questions • 50 min • Pass 60 • Merit 82.5', onTap: () => widget.onGo(2, 'Mock')),
        _moduleRow(icon: Icons.mic, color: AppColors.greenDark, title: 'Voice Tutor', sub: 'Ask in Pashto, Sindhi, Saraiki, Punjabi, Urdu, English', onTap: () => widget.onGo(3, 'Tutor')),
        _moduleRow(icon: Icons.build, color: AppColors.orangeDark, title: 'Skill Test — Round 2', sub: 'Physical 30 • Interview 30 • Basic skills 40', onTap: () => widget.onLearnSection('skill')),
        _moduleRow(icon: Icons.public, color: AppColors.tealDark, title: 'Life in Korea', sub: 'Rights • Safety • Culture & manners', onTap: () => widget.onLearnSection('life')),
        _moduleRow(icon: Icons.videogame_asset, color: AppColors.purple, title: 'Games', sub: 'Listen and Tap • Play & learn', onTap: () => widget.onGo(4, 'More')),
        _moduleRow(icon: Icons.edit, color: AppColors.greenDark, title: 'Practice', sub: 'Speak Test • Culture scenarios • Notebook', onTap: () => widget.onGo(4, 'More')),
        _moduleRow(icon: Icons.menu_book, color: AppColors.navy, title: 'Official books', sub: 'HRD Korea • Free • Colour-vision check', onTap: () => widget.onLearnSection('official')),
        _moduleRow(icon: Icons.bar_chart, color: AppColors.royalBlue, title: 'My Progress', sub: 'Overall score • Streak • Weak topics', onTap: () => _open(context, 'My Progress', const ProgressPage())),
        _moduleRow(icon: Icons.public, color: AppColors.pakGreen, title: 'OEC Tracker', sub: 'Lucky draw • Merit 82.5 • Your best mock', onTap: () => _open(context, 'OEC Tracker', const OecTrackerPage())),
        _moduleRow(icon: Icons.record_voice_over, color: AppColors.greenDark, title: 'Speak to Korea', sub: 'Talk to your boss • Honest feedback', onTap: () => _open(context, 'Speak to Korea', const SpeakToKoreaPage())),
        const SizedBox(height: AppSpacing.section),
        // FREE PROMISE — one slim strip. The full promise + 12-week
        // plan detail live on the Auth screen and in the plan sheet.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColors.softGreen, borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
          child: const Row(children: [
            Icon(Icons.check_circle, color: AppColors.greenDark, size: 22),
            SizedBox(width: 8),
            Expanded(child: Text('Free to learn — only official OEC fees. No ads, works offline. A notebook and a pen is all you need.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink))),
          ]),
        ),
        const SizedBox(height: 12),
        const Text('Not affiliated with OEC or HRD Korea. Check the latest OEC notice at jobs.oec.gov.pk.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.muted)),
      ]),
    );
  }

  void _open(BuildContext context, String title, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title), backgroundColor: AppColors.royalDark, foregroundColor: Colors.white),
        body: SafeArea(child: page),
      ),
    ));
  }

  Widget _moduleRow({required IconData icon, required Color color, required String title, required String sub, required VoidCallback onTap}) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: Colors.white, size: 24)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.ink)),
          subtitle: Text(sub, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      );

  Widget _pathTile({required IconData icon, required String badge, required Color badgeColor, required String title, required String desc, required bool isCurrent, required VoidCallback onTap}) => Expanded(child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border(top: BorderSide(color: badgeColor, width: 4)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: badgeColor, size: 22),
              const Spacer(),
              if (isCurrent) const Icon(Icons.check_circle, color: AppColors.greenDark, size: 20),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
              child: Text(badge, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
            Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          ]),
        ),
      ));

  Widget _quickAction(IconData icon, Color c, String label, VoidCallback onTap) => Expanded(child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Icon(icon, color: c, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
      ));

  Widget _sectionTile({required IconData icon, required Color tint, required Color color, required String label, required String sub, required VoidCallback onTap}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppSpacing.radiusCard), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 26)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
            Text(sub, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
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
    _applyStart(widget.start, widget.startUnit);
  }

  // v1.6.0 fix: LearnPage is kept alive under one GlobalKey, so initState
  // runs ONCE. Without this, tapping a Home path/grid tile a second time
  // (or after visiting another section) silently did nothing — the new
  // start was never applied. didUpdateWidget applies every new start.
  @override
  void didUpdateWidget(covariant LearnPage old) {
    super.didUpdateWidget(old);
    if (widget.start != old.start || widget.startUnit != old.startUnit) {
      _applyStart(widget.start, widget.startUnit);
    }
  }

  void _applyStart(String? start, int? startUnit) {
    selectedUnit = null;
    selectedSkill = null;
    if (start == 'mid') { section = 'course'; selectedUnit = 11; }
    else if (start == 'expert') { section = 'course'; selectedUnit = 31; }
    else if (start == 'continue' && startUnit != null) { section = 'course'; selectedUnit = startUnit; }
    else if (start != null && start.startsWith('section:')) { section = start.substring(8); }
    else if (start == 'basic') { section = 'hangul'; }
  }

  /// P0-1: Back from a Unit/Skill detail returns to the list, not Home.
  bool get hasDetail => selectedUnit != null || selectedSkill != null;
  void closeDetail() => setState(() { selectedUnit = null; selectedSkill = null; });
  int vowelIdx = 0, consIdx = 0, buildIdx = 0, buildStage = 0;
  int notebookStep = 0;
  int vocabPage = 0;
  String vocabSearch = '';
  String vocabCategory = 'All';
  int? selectedUnit;
  int? selectedSkill;

  // Short chip labels — the old 11-chip Wrap took 3 rows of screen.
  String _chipLabel(String s, String lang) {
    switch (s) {
      case 'hangul': return t(lang, 'hangul');
      case 'vocab': return t(lang, 'vocab');
      case 'course': return t(lang, 'course');
      case 'skill': return t(lang, 'skillTest');
      case 'emergency': return t(lang, 'emergency');
      case 'life': return t(lang, 'lifeWork');
      case 'docs': return t(lang, 'docs');
      case 'listening': return 'Listening';
      case 'flashcards': return 'Flashcards';
      case 'official': return 'Official';
      default: return t(lang, 'notebook');
    }
  }

  String _sectionTitle(String s, String lang) {
    switch (s) {
      case 'hangul': return 'Hangul — read & write Korean';
      case 'vocab': return 'Vocabulary — ${vocab.length} words';
      case 'course': return 'Course — Units 0–60';
      case 'skill': return 'Round 2 Skill Test';
      case 'emergency': return 'Emergency phrases';
      case 'life': return 'Life and Work in Korea';
      case 'docs': return 'Documents checklist';
      case 'listening': return 'Listening drills';
      case 'flashcards': return 'Flashcards';
      case 'official': return 'Official books & checks';
      default: return 'Notebook Time';
    }
  }

  String _sectionSub(String s) {
    switch (s) {
      case 'hangul': return 'Tap any letter to hear it. 21 vowels, 19 consonants.';
      case 'vocab': return 'Search, pick a category, tap 🔊 to hear a word, ⭐ when you know it.';
      case 'course': return 'New syllabus, HRD Korea 2024. Tap a unit for its lesson.';
      case 'skill': return 'Physical 30 + Interview 30 + Basic skills 40. Below 60% = out.';
      case 'emergency': return 'Say it in Korean — tap 🔊 to hear it slow, then normal.';
      case 'life': return 'Work, rights, safety, help — and culture & manners.';
      case 'docs': return 'Tick each document when you have it ready.';
      case 'listening': return 'Numbers & Time, and conversation — what comes next?';
      case 'flashcards': return 'Tap a card to flip it. Know it? Tap Know.';
      case 'official': return 'Free HRD Korea books, colour-vision check, official results.';
      default: return 'Write in your notebook — a pen and a notebook is all you need.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppStore.I.lang;
    final doneUnits = List.generate(61, (n) => AppStore.I.isDone('unit_$n')).where((d) => d).length;
    return ListView(padding: const EdgeInsets.all(16), children: [
      // v1.6.0: ONE scrollable chip row, not an 11-chip Wrap over 3 rows.
      // One row, one tap, no hunting — the section header below says
      // where you are and what to do there.
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final s in ['hangul', 'vocab', 'course', 'skill', 'emergency', 'life', 'docs', 'notebook', 'listening', 'flashcards', 'official'])
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(_chipLabel(s, lang), style: const TextStyle(fontSize: 14)),
                selected: section == s,
                onSelected: (_) => setState(() => section = s),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      Text(_sectionTitle(section, lang), style: AppHeadings.sectionTitle),
      Text(_sectionSub(section), style: AppHeadings.sectionSub),
      if (section == 'course')
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(value: doneUnits / 61, minHeight: 8, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.greenDark)),
        ),
      if (section == 'course')
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$doneUnits of 61 units done', style: AppHeadings.sectionSub),
        ),
      const SizedBox(height: 12),
      if (section == 'hangul') _hangul(lang),
      if (section == 'vocab') _vocab(),
      if (section == 'course') _course(),
      if (section == 'skill') _skill(),
      if (section == 'emergency') _emergency(),
      if (section == 'life') _life(),
      if (section == 'docs') _docs(),
      if (section == 'notebook') _notebook(),
      if (section == 'listening') const ListeningDrillPage(),
      if (section == 'flashcards') const FlashcardPage(),
      if (section == 'official') _official(),
    ]);
  }

  Widget _hangul(String lang) {
    final v = vowels[vowelIdx];
    final c = consonants[consIdx];
    final b = wordBuilds[buildIdx];
    final stages = ['Letter: ${b[0]}', 'Part: ${b[1]}', 'Whole word: ${b[2]}', 'Meaning: ${b[3]} (${b[4]})'];
    // v1.6.0: tap-any letter grids — the old Next-only walk forced a
    // beginner through 21 vowels in order to reach ㅓ. Now every letter
    // is one tap away; the big letter below is the selected one.
    Widget letterGrid(List<List<String>> letters, int selected, void Function(int) onTap) => Wrap(
          spacing: 6, runSpacing: 6,
          children: letters.asMap().entries.map((e) => InkWell(
                onTap: () => onTap(e.key),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: e.key == selected ? AppColors.navy : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(child: Text(e.value[0], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: e.key == selected ? Colors.white : AppColors.ink))),
                ),
              )).toList(),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('1) Full alphabets first — like A B C D', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Tap any letter to hear it. Vowels first, then consonants.'),
      const Text('✍️ Stroke order: always write top to bottom, left to right. One syllable = one block (e.g. ㅎ + ㅏ + ㄴ = 한). Trace the big letter in the air, then write it 5 times in your notebook.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 12),
      Text('Vowels — ${vowelIdx + 1} of 21: ${v[0]} (${v[1]})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      letterGrid(vowels, vowelIdx, (i) => setState(() => vowelIdx = i)),
      const SizedBox(height: 12),
      Text('Consonants — ${consIdx + 1} of 19: ${c[0]} (${c[1]})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      letterGrid(consonants, consIdx, (i) => setState(() => consIdx = i)),
      const SizedBox(height: 12),
      Card(
        color: AppColors.softTeal,
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Text(v[0], style: const TextStyle(fontSize: 64)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Vowel sound: ${v[1]}', style: const TextStyle(fontSize: 15)),
            Text('Consonant: ${c[0]} (${c[1]})', style: const TextStyle(fontSize: 15)),
          ])),
          Column(children: [
            ElevatedButton(onPressed: () => speak(v[0]), child: const Text('🔊 Hear it')),
            const SizedBox(height: 6),
            Row(children: [
              OutlinedButton(onPressed: () => setState(() { vowelIdx = (vowelIdx - 1 + vowels.length) % vowels.length; }), child: const Text('← Prev')),
              const SizedBox(width: 6),
              OutlinedButton(onPressed: () => setState(() => vowelIdx = (vowelIdx + 1) % vowels.length), child: const Text('Next →')),
            ]),
          ]),
        ])),
      ),
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
    final q = vocabSearch.trim().toLowerCase();
    final filtered = vocab.where((w) {
      if (vocabCategory != 'All' && w[4] != vocabCategory) return false;
      if (q.isEmpty) return true;
      return w[0].contains(q) || w[1].toLowerCase().contains(q) ||
          w[2].toLowerCase().contains(q) || w[3].toLowerCase().contains(q);
    }).toList();
    final pages = (filtered.length / pageSize).ceil().clamp(1, 999);
    final page = vocabPage.clamp(0, pages - 1);
    final items = filtered.sublist(page * pageSize, ((page + 1) * pageSize).clamp(0, filtered.length));
    return Column(children: [
      Text('Vocabulary — ${vocab.length} words${vocabCategory == 'All' ? '' : ' • $vocabCategory'}${q.isEmpty ? '' : ' • search: $vocabSearch'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Text('Tap 🔊 to hear a word, tap ⭐ when you know it. Search in Korean, English or Urdu. Pick a category to revise one topic.'),
      const SizedBox(height: 8),
      TextField(
        decoration: const InputDecoration(labelText: 'Search words — Korean, English or Urdu', border: OutlineInputBorder(), prefixIcon: Icon(Icons.search)),
        onChanged: (v) => setState(() { vocabSearch = v; vocabPage = 0; }),
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final c in vocabCategories)
          ChoiceChip(
            label: Text(c, style: const TextStyle(fontSize: 14)),
            selected: vocabCategory == c,
            onSelected: (_) => setState(() { vocabCategory = c; vocabPage = 0; }),
          ),
      ]),
      const SizedBox(height: 8),
      if (filtered.isEmpty)
        const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No words match that search or category. Try another word.', style: TextStyle(fontSize: 15)))),
      Text('Showing ${filtered.length} words — page ${page + 1} of $pages', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 4),
      ...items.map((w) => Card(child: ListTile(
        leading: Text(w[5], style: const TextStyle(fontSize: 28)),
        title: Text('${w[0]}  •  ${w[1]}', style: const TextStyle(fontSize: 18)),
        subtitle: Text('${w[2]} — ${w[3]}\nCategory: ${w[4]}'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speakSlowThenNormal(w[0])),
          IconButton(icon: Icon(AppStore.I.progress['words']?[w[0]] == 'mastered' ? Icons.star : Icons.star_border),
              onPressed: () async { await AppStore.I.setWord(w[0], AppStore.I.progress['words']?[w[0]] == 'mastered' ? 'learning' : 'mastered'); setState(() {}); }),
        ]),
      ))),
      const SizedBox(height: 8),
      Wrap(spacing: 6, alignment: WrapAlignment.center, children: [
        ElevatedButton(onPressed: page > 0 ? () => setState(() => vocabPage = page - 1) : null, child: const Text('← Prev')),
        for (int i = 0; i < pages; i++)
          Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: ChoiceChip(label: Text('${i + 1}'), selected: i == page, onSelected: (_) => setState(() => vocabPage = i))),
        ElevatedButton(onPressed: page < pages - 1 ? () => setState(() => vocabPage = page + 1) : null, child: const Text('Next →')),
      ]),
      const SizedBox(height: 8),
      OutlinedButton.icon(icon: const Icon(Icons.style), label: const Text('Open Flashcards for these words →'), onPressed: () => setState(() => section = 'flashcards')),
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

  Widget _official() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Official books & checks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('From HRD Korea (epstopik.hrdkorea.or.kr) — the official EPS-TOPIK site. This app is not affiliated with OEC or HRD Korea. Books are free from HRD Korea; we do not copy them here, we only link to them.'),
      const SizedBox(height: 12),
      const Text('📖 Official E-Book — Standard Korean Textbook (2024 revised edition)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Text('Book 1 = daily life (Units 1–30). Book 2 = workplace (Units 31–60). Same books as the Course tab, in your language. Open the HRD main page in your browser and choose your language book.'),
      const SizedBox(height: 6),
      const SelectableText('epstopik.hrdkorea.or.kr/epstopik/home/main/mainPage.do?lang=en', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 4),
      const SelectableText('hrdkorea.or.kr — Textbook download page: /1/3/3/2/1', style: TextStyle(fontSize: 14)),
      const SizedBox(height: 8),
      ...officialBooks.map((b) => Card(child: ListTile(
        leading: const Icon(Icons.menu_book, color: AppColors.navy),
        title: Text(b[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(b[1], style: const TextStyle(fontSize: 14)),
      ))),
      const SizedBox(height: 12),
      const Text('👁️ Colour-vision check — do this EARLY', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Text('Colour blindness disqualifies a student from EPS. This is a simple screening only — NOT a medical diagnosis. If you cannot see a number clearly, get the official colour-vision test at your OEC medical check.'),
      const SizedBox(height: 8),
      ...colorVisionPlates.asMap().entries.map((e) => Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: e.key % 2 == 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828), child: Text(e.value[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
        title: Text('Plate ${e.key + 1} — number ${e.value[0]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('Dots: ${e.value[1]} • Number: ${e.value[2]}. Can you see the number ${e.value[0]} clearly? If not, tell your teacher and get checked.'),
      ))),
      const SizedBox(height: 12),
      const Text('📋 Check official results & notices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const Text('Re-test results, exam dates and merit lists are published by OEC Pakistan and HRD Korea — not in this app. Check them yourself:'),
      const SizedBox(height: 6),
      const SelectableText('jobs.oec.gov.pk — OEC Pakistan (registration, draw, results)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 4),
      const SelectableText('epstopik.hrdkorea.or.kr — HRD Korea EPS-TOPIK (test criteria, books, results)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.navy)),
      const SizedBox(height: 6),
      const Text('Passing floor 60/100 for all sectors. Pakistan 2026 merit 82.5/100 (reported — check the latest OEC notice).', style: TextStyle(fontSize: 14)),
    ]);
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


// ---------------- Listening drills (v1.5.0) ----------------
/// HRD L1 Numbers & Time + L3 Conversation -> next sentence.
/// Audio-first: the Korean text is hidden until you answer, then shown.
/// All options are Korean. Original dialogues — no test questions copied.
class ListeningDrillPage extends StatefulWidget {
  const ListeningDrillPage({super.key});
  @override
  State<ListeningDrillPage> createState() => _ListeningDrillPageState();
}

class _ListeningDrillPageState extends State<ListeningDrillPage> {
  String mode = 'numbers'; // 'numbers' | 'conversation'
  int idx = 0, score = 0, done = 0;
  int? selected;
  bool answered = false;
  List<String> options = [];

  List<List<String>> get bank => mode == 'numbers' ? numbersDrill : conversationDrills;

  @override
  void initState() {
    super.initState();
    _regen();
  }

  void _regen() {
    final e = bank[idx % bank.length];
    // conversationDrills have 8 fields, numbersDrill 5 — correct is [2],
    // wrongs are [3],[4],[5] in both.
    final correct = e[2];
    options = [correct, e[3], e[4], e[5]]..shuffle(Random(777 + idx * 13));
    selected = null;
    answered = false;
  }

  void _setMode(String m) => setState(() { mode = m; idx = 0; score = 0; done = 0; _regen(); });

  String get _hearText {
    final e = bank[idx % bank.length];
    return mode == 'numbers' ? e[0] : e[0];
  }

  @override
  Widget build(BuildContext context) {
    final e = bank[idx % bank.length];
    final correct = e[2];
    final total = bank.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Listening drills', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('Listen first — the Korean text is hidden until you answer. Then it is shown so you can check what you heard.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Numbers & Time', style: TextStyle(fontSize: 14)), selected: mode == 'numbers', onSelected: (_) => _setMode('numbers')),
        ChoiceChip(label: const Text('Conversation — what comes next?', style: TextStyle(fontSize: 14)), selected: mode == 'conversation', onSelected: (_) => _setMode('conversation')),
      ]),
      const SizedBox(height: 12),
      Text(mode == 'numbers'
          ? 'Numbers & Time — hear a time, date, price or count, tap the right one. (${idx + 1}/$total • Score $score/$done)'
          : 'Conversation — hear a short dialogue between two people, tap the best next sentence. (${idx + 1}/$total • Score $score/$done)',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        if (!answered)
          const Text('Korean text hidden — listen carefully.', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.muted)),
        if (answered) Text(_hearText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => speak(_hearText), child: const Text('🔊 Hear it')),
        const SizedBox(height: 4),
        TextButton(onPressed: () => speak(_hearText, rate: 0.35), child: const Text('Hear it slowly')),
        if (mode == 'conversation' && answered)
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(e[1], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
        if (mode == 'conversation' && !answered)
          const Padding(padding: const EdgeInsets.only(top: 8), child: Text('Question: what should the next person say?', style: TextStyle(fontSize: 14))),
        const SizedBox(height: 8),
        ...options.asMap().entries.map((o) {
          final isSel = selected == o.key;
          final isCor = o.value == correct;
          Color? bg;
          if (answered && isSel) bg = isCor ? AppColors.greenDark : AppColors.red;
          if (answered && isCor) bg = AppColors.greenDark;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
            style: bg != null ? ElevatedButton.styleFrom(backgroundColor: bg, minimumSize: const Size.fromHeight(52)) : null,
            onPressed: answered ? null : () => setState(() {
              selected = o.key;
              answered = true;
              done++;
              if (isCor) score++;
            }),
            child: Text(o.value, style: const TextStyle(fontSize: 15)),
          )));
        }),
        if (answered) ...[
          Text(selected != null && options[selected!] == correct ? 'Correct! ✓' : 'Not correct — the right answer is: $correct',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: primaryButtonStyle(),
            onPressed: () => setState(() { idx = (idx + 1) % total; _regen(); }),
            child: Text(idx + 1 >= total ? 'Next drill (restart list) →' : 'Next drill →'),
          )),
        ],
      ]))),
      const SizedBox(height: 8),
      const Text('Tip: Numbers are a guaranteed HRD listening type — time, date, price, count. Practise 5 minutes a day.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
    ]);
  }
}

// ---------------- Flashcards (v1.5.0) ----------------
/// Big-card drill for the 329 vocabulary words. Tap to flip.
/// Know / Don't know is saved (⭐ = mastered) so the next mock and the
/// Home word count can use it.
class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});
  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  String category = 'All';
  String statusFilter = 'All'; // All | Familiar | Learning (showcase tabs)
  bool flipped = false;
  int idx = 0;
  List<List<String>> order = [];

  List<List<String>> get _filtered {
    final base = category == 'All' ? vocab : vocab.where((w) => w[4] == category).toList();
    if (statusFilter == 'Familiar') return base.where((w) => AppStore.I.progress['words']?[w[0]] == 'mastered').toList();
    if (statusFilter == 'Learning') return base.where((w) => AppStore.I.progress['words']?[w[0]] != 'mastered').toList();
    return base;
  }

  @override
  void initState() {
    super.initState();
    order = List.of(_filtered);
  }

  void _applyCategory(String c) => setState(() { category = c; idx = 0; flipped = false; order = List.of(_filtered); });

  void _shuffle() => setState(() { order.shuffle(Random()); idx = 0; flipped = false; });

  void _mark(String status) async {
    final w = order[idx % order.length];
    await AppStore.I.setWord(w[0], status);
    setState(() { idx = (idx + 1) % order.length; flipped = false; });
  }

  Widget _roundBtn(IconData icon, Color c, String label, VoidCallback onTap) => Column(children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(width: 56, height: 56, decoration: BoxDecoration(color: c, shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 28)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      ]);

  @override
  Widget build(BuildContext context) {
    if (order.isEmpty) order = List.of(_filtered);
    if (order.isEmpty) return const Text('No words in this category.');
    final w = order[idx % order.length];
    final known = (AppStore.I.progress['words'] as Map? ?? {}).values.where((v) => v == 'mastered').length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Flashcards', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      Text('Tap the card to flip it. ${idx + 1}/${order.length} • ⭐ Known: $known of ${vocab.length} words', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 8),
      // Showcase tabs: All / Familiar / Learning.
      Row(children: [
        for (final f in ['All', 'Familiar', 'Learning'])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(f, style: const TextStyle(fontSize: 14)), selected: statusFilter == f, onSelected: (_) => setState(() { statusFilter = f; idx = 0; flipped = false; order = List.of(_filtered); })),
          ),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final c in vocabCategories)
          ChoiceChip(label: Text(c, style: const TextStyle(fontSize: 14)), selected: category == c, onSelected: (_) => _applyCategory(c)),
      ]),
      const SizedBox(height: 8),
      InkWell(
        onTap: () => setState(() => flipped = !flipped),
        child: Card(
          color: flipped ? const Color(0xFFE8F5E9) : Colors.white,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(w[5], style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              if (!flipped) ...[
                Text(w[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Tap to see the meaning', style: TextStyle(fontSize: 14, color: AppColors.muted)),
              ] else ...[
                Text(w[0], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                Text(w[1], style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Text(w[2], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(w[3], style: const TextStyle(fontSize: 16)),
                Text('Category: ${w[4]}', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              ],
            ]),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() { idx = (idx - 1 + order.length) % order.length; flipped = false; }), child: const Text('← Prev'))),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton(onPressed: () => speakSlowThenNormal(w[0]), child: const Text('▶ Play'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () async { try { await tts.stop(); } catch (_) {} setState(() {}); }, child: const Text('■ Stop'))),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(onPressed: () => setState(() { idx = (idx + 1) % order.length; flipped = false; }), child: const Text('Next →'))),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _roundBtn(Icons.close, AppColors.red, 'Not yet', () => _mark('learning')),
        const SizedBox(width: 24),
        _roundBtn(Icons.shuffle, AppColors.royalBlue, 'Shuffle', _shuffle),
        const SizedBox(width: 24),
        _roundBtn(Icons.check, AppColors.pakGreen, 'I know it', () => _mark('mastered')),
      ]),
      const SizedBox(height: 8),
      const Text('Know / Don\'t know is saved on this phone (⭐ in Vocabulary too). Shuffle gives you a new order.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
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
  // v1.5.0 configurator: questions 10/20/40, time 10/25/50 min.
  // Real test preset = 40 questions / 50 min / Expert.
  int configQ = 40, configTime = 50;
  int get totalQ => configQ;
  int get perSection => configQ ~/ 2;
  int get _totalTimeSecs => configTime * 60;
  @override
  void initState() {
    super.initState();
    difficulty = widget.initialDifficulty;
  }
  int secondsLeft = 50 * 60;
  // P0-2: palette + flag + per-question answers.
  final Set<int> flagged = {};
  List<int> answers = List<int>.filled(40, -1);
  bool showPalette = false;
  bool showReview = false;
  int? selectedIdx;
  bool answered = false;
  // Listening: plays per question (auto-play counts as 1, max 2 total).
  final Map<int, int> listeningPlays = {};
  int autoPlayedQi = -1;

  List<String> _options(String correct, List<String> wrongs, int seed) {
    final opts = <String>[correct, ...wrongs]..shuffle(Random(seed));
    return opts;
  }

  int get _timeUsed => _totalTimeSecs - secondsLeft;

  @override
  Widget build(BuildContext context) {
    if (!started) {
      final mocks = (AppStore.I.progress['mocks'] as List? ?? []);
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Mock Test — set up your own mock exam', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.navy)),
        const Text('Real test: 40 questions, 50 minutes, 100 points (20 reading + 20 listening). Passing floor 60/100. Pakistan 2026 merit 82.5/100 (reported — check the latest OEC notice).'),
        const SizedBox(height: 12),
        const Text('Choose your difficulty:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _diffTile(icon: Icons.check_circle_outline, color: AppColors.greenDark, label: 'Easy', sub: 'Beginners', selected: difficulty == 'basic', onTap: () => setState(() => difficulty = 'basic')),
          const SizedBox(width: 8),
          _diffTile(icon: Icons.bolt, color: AppColors.orangeDark, label: 'Medium', sub: 'Half + half', selected: difficulty == 'medium', onTap: () => setState(() => difficulty = 'medium')),
          const SizedBox(width: 8),
          _diffTile(icon: Icons.workspace_premium, color: AppColors.red, label: 'Hard', sub: 'Real test level', selected: difficulty == 'expert', onTap: () => setState(() => difficulty = 'expert')),
        ]),
        const SizedBox(height: 12),
        const Text('Questions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Wrap(spacing: 8, children: [
          for (final n in [10, 20, 40])
            ChoiceChip(label: Text('$n questions', style: const TextStyle(fontSize: 14)), selected: configQ == n, onSelected: (_) => setState(() => configQ = n)),
        ]),
        const SizedBox(height: 8),
        const Text('Time:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Wrap(spacing: 8, children: [
          for (final n in [10, 25, 50])
            ChoiceChip(label: Text('$n min', style: const TextStyle(fontSize: 14)), selected: configTime == n, onSelected: (_) => setState(() => configTime = n)),
        ]),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => setState(() { difficulty = 'expert'; configQ = 40; configTime = 50; }),
          child: const Text('Real test preset — Hard • 40 questions • 50 min'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: primaryButtonStyle(),
          onPressed: () => setState(() {
            started = true;
            qi = 0; listening = 0; reading = 0;
            secondsLeft = _totalTimeSecs;
            answers = List<int>.filled(totalQ, -1);
            flagged.clear(); selectedIdx = null; answered = false;
            listeningPlays.clear(); autoPlayedQi = -1;
            _tick();
          }),
          child: Text('Start ${difficulty == 'expert' ? 'Hard' : difficulty == 'medium' ? 'Medium' : 'Easy'} mock ($configQ questions • $configTime min)', style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        const Text('Your past attempts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (mocks.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('No mock attempts yet — take your first mock above.', style: TextStyle(fontSize: 14, color: AppColors.muted))),
        ...mocks.map((m) {
          final tq = (m['total'] ?? 40) as int;
          final sc = tq > 0 ? ((m['l'] + m['r']) * 100 / tq) : 0.0;
          final diff = (m['d'] ?? 'basic') == 'expert' ? 'Hard' : (m['d'] ?? 'basic') == 'medium' ? 'Medium' : 'Easy';
          return ListTile(
            title: Text('Listening ${m['l']}/${tq ~/ 2} • Reading ${m['r']}/${tq ~/ 2}'),
            subtitle: Text('$diff • ${(m['date'] ?? '').toString().substring(0, 10)} • Score ${sc.toStringAsFixed(1)}/100 — ${sc >= 60 ? 'Passed (60)' : 'Below passing'} • ${sc >= 82.5 ? 'Above merit 82.5' : 'Below merit 82.5'}${m['secs'] != null ? ' • Time ${formatMmSs(m['secs'] as int)}' : ''}'),
          );
        }),
      ]);
    }
    if (finished) {
      final total = totalQ > 0 ? (listening + reading) * 100 / totalQ : 0.0;
      final weakListening = listening <= reading;
      final verdict = total >= 82.5 ? 'Excellent!' : (total >= 60 ? 'Great job!' : 'Keep going!');
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
        Text(verdict, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
        const Text('You scored', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: AppColors.muted)),
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 140, height: 140,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: total / 100, strokeWidth: 12, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.pakGreen))),
              Text('${total.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Text('${listening + reading} / $totalQ Correct', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        Text('Listening $listening/$perSection • Reading $reading/$perSection', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 12),
        _resultBar('Listening', perSection > 0 ? (listening * 100 ~/ perSection) : 0),
        _resultBar('Reading', perSection > 0 ? (reading * 100 ~/ perSection) : 0),
        const SizedBox(height: 8),
        Text('Analytics: Listening ${perSection > 0 ? (listening * 100 ~/ perSection) : 0}%  •  Reading ${perSection > 0 ? (reading * 100 ~/ perSection) : 0}%  •  Pass line 60  •  Merit line 82.5'),
        Text(weakListening
            ? 'Weak area: Listening — do 10 minutes of Listen-and-Tap every day before your next mock.'
            : 'Weak area: Reading — re-read Units 1–30 slowly, then try the Expert mock again.',
            textAlign: TextAlign.center),
        Text('Time used: ${formatMmSs(_timeUsed)} of $configTime minutes. In the real CBT test the clock never stops — finish each question in about 75 seconds.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        Text('${difficulty == 'expert' ? 'Hard' : difficulty == 'medium' ? 'Medium' : 'Easy'} mock • $totalQ questions', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          color: AppColors.softGreen,
          child: Padding(padding: const EdgeInsets.all(12), child: Text(total >= 82.5 ? '⭐ Keep it up! Wah bhai wah, Korea pakka! Above merit.' : total >= 60 ? '⭐ Keep it up! Passed the floor (60), but below merit 82.5 — practise your weak topics.' : '⭐ Keep it up! Ghalat jawab, lekin himmat na haar, dobara kar! Below 60 — learn again.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(style: primaryButtonStyle(), onPressed: () => setState(() => showReview = !showReview), child: Text(showReview ? 'Hide Answers' : 'Review Answers'))),
        const SizedBox(height: 8),
        if (showReview) ..._reviewList(),
        const SizedBox(height: 8),
        if (widget.onGoLearn != null)
          OutlinedButton(onPressed: widget.onGoLearn, child: Text(weakListening ? 'Practise Listening in Learn →' : 'Practise Reading in Learn →')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('My Progress'), backgroundColor: AppColors.royalDark, foregroundColor: Colors.white), body: const SafeArea(child: ProgressPage())))), child: const Text('View My Progress →')),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () => setState(() { started = false; finished = false; showReview = false; qi = 0; listening = 0; reading = 0; secondsLeft = _totalTimeSecs; answers = List<int>.filled(totalQ, -1); flagged.clear(); selectedIdx = null; answered = false; listeningPlays.clear(); autoPlayedQi = -1; }), child: const Text('↻ Try Again')),
      ]);
    }
    final isListening = qi < perSection;
    final isExpert = difficulty == 'expert';
    final isMediumExpertQ = difficulty == 'medium' && qi % 2 == 1;
    late String prompt, promptKo, hearText, emoji, passage;
    late List<String> options;
    late String correctText;
    emoji = '';
    passage = '';
    if (isExpert || isMediumExpertQ) {
      // v1.5.0: type-mixed Expert bank — picture, fill-blank, passage,
      // paraphrase (reading) / single sentence, picture (listening).
      // bank[qi] directly, never bank[qi % 20].
      final bank = isListening ? expertListening : expertReading;
      final e = bank[isListening ? qi : qi - perSection];
      promptKo = e[0];
      if (e.length > 5) emoji = e[5];
      if (e.length > 6) passage = e[6];
      hearText = (isListening && passage.isNotEmpty) ? passage : e[0];
      prompt = isListening
          ? (emoji.isNotEmpty ? 'Listen, then tap the picture that matches:' : 'Listen, then tap the correct Korean sentence:')
          : passage.isNotEmpty
              ? 'Read the passage, then answer:'
              : emoji.isNotEmpty
                  ? 'Look at the picture, then tap the correct Korean sentence:'
                  : e[0].contains('___')
                      ? 'Fill in the blank — tap the correct Korean word:'
                      : 'Read the sentence, then tap the correct Korean sentence:';
      correctText = e[1];
      options = _options(e[1], [e[2], e[3], e[4]], 9871 + qi * 37);
    } else {
      final w = vocab[qi % vocab.length];
      promptKo = w[0];
      hearText = w[0];
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
      WidgetsBinding.instance.addPostFrameCallback((_) => speak(hearText));
    }
    final plays = listeningPlays[qi] ?? 0;
    const letters = ['A', 'B', 'C', 'D'];
    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // Showcase timer: big 00:19:45, question counter 1/40.
        Card(
          child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.timer, color: AppColors.royalBlue, size: 18), SizedBox(width: 6), Text('Time Remaining', style: TextStyle(fontSize: 14, color: AppColors.muted))]),
            Text(formatHhMmSs(secondsLeft), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
            Text('Question ${qi + 1}/$totalQ • ${isListening ? 'Listening' : 'Reading'} • ${difficulty == 'expert' ? 'Hard' : difficulty == 'medium' ? 'Medium' : 'Easy'}', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton.icon(icon: Icon(paused ? Icons.play_arrow : Icons.pause, size: 18), label: Text(paused ? 'Resume' : 'Pause', style: const TextStyle(fontSize: 14)), onPressed: () => setState(() => paused = !paused)),
              TextButton.icon(icon: const Icon(Icons.exit_to_app, size: 18, color: AppColors.red), label: const Text('Exit', style: TextStyle(fontSize: 14, color: AppColors.red)), onPressed: _confirmExit),
            ]),
          ])),
        ),
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
            itemCount: totalQ,
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
            if (answered) ...[
              if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 48)),
              Text(hearText, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: plays < 2 ? () { setState(() => listeningPlays[qi] = plays + 1); speak(hearText); } : null,
              child: Text(plays == 0 ? '🔊 Hear it' : plays == 1 ? '🔊 Hear again (1 replay left)' : '🔊 No replays left'),
            ),
          ] else
            Column(children: [
              if (emoji.isNotEmpty) Text(emoji, style: const TextStyle(fontSize: 64)),
              if (passage.isNotEmpty)
                Card(color: const Color(0xFFE8F5F3), child: Padding(padding: const EdgeInsets.all(12), child: Text(passage, style: const TextStyle(fontSize: 15)))),
              const SizedBox(height: 6),
              Text(promptKo, style: TextStyle(fontSize: passage.isNotEmpty ? 20 : 28, fontWeight: FontWeight.bold)),
            ]),
          const SizedBox(height: 12),
          ...options.asMap().entries.map((e) {
            final idx = e.key, opt = e.value;
            final isSelected = selectedIdx == idx;
            final isCorrect = opt == correctText;
            Color circleBg = AppColors.softBlue;
            Color circleFg = AppColors.royalBlue;
            Color border = AppColors.border;
            if (answered && isCorrect) { circleBg = AppColors.pakGreen; circleFg = Colors.white; border = AppColors.pakGreen; }
            if (answered && isSelected && !isCorrect) { circleBg = AppColors.red; circleFg = Colors.white; border = AppColors.red; }
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(
              onTap: answered ? null : () {
                setState(() {
                  selectedIdx = idx;
                  answered = true;
                  answers[qi] = idx;
                  if (opt == correctText) { if (isListening) { listening++; } else { reading++; } }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 2)),
                child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: circleBg, child: Text(letters[idx], style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: circleFg))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(opt, style: const TextStyle(fontSize: 15, color: AppColors.ink))),
                ]),
              ),
            ));
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
                  if (qi + 1 >= totalQ) {
                    await AppStore.I.addMock(listening, reading, difficulty: difficulty, secondsUsed: _timeUsed, totalQ: totalQ);
                    setState(() => finished = true);
                  } else {
                    setState(() { qi++; selectedIdx = answers[qi] == -1 ? null : answers[qi]; answered = answers[qi] != -1; });
                  }
                },
                child: Text(qi + 1 >= totalQ ? 'Finish & see result' : 'Next  >', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ]))),
      ]),
    );
  }

  Widget _diffTile({required IconData icon, required Color color, required String label, required String sub, required bool selected, required VoidCallback onTap}) => Expanded(child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
            border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
            Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            if (selected) const Padding(padding: EdgeInsets.only(top: 4), child: Icon(Icons.check_circle, color: AppColors.greenDark, size: 18)),
          ]),
        ),
      ));

  /// Review Answers: rebuild each question's options from the same
  /// seeded shuffle used in the test, so the correct answer and the
  /// learner's answer can be shown side by side.
  List<Widget> _reviewList() {
    final items = <Widget>[];
    for (int i = 0; i < totalQ; i++) {
      final isL = i < perSection;
      final isExp = difficulty == 'expert' || (difficulty == 'medium' && i % 2 == 1);
      late String promptKo, correctText;
      late List<String> options;
      if (isExp) {
        final bank = isL ? expertListening : expertReading;
        final e = bank[isL ? i : i - perSection];
        promptKo = e[0];
        if (e.length > 5 && e[5].isNotEmpty) promptKo = '${e[5]} ${e[0]}';
        correctText = e[1];
        options = _options(e[1], [e[2], e[3], e[4]], 9871 + i * 37);
      } else {
        final w = vocab[i % vocab.length];
        promptKo = w[0];
        correctText = '${w[2]} — ${w[3]}';
        final wrongs = [vocab[(i + 5) % vocab.length], vocab[(i + 11) % vocab.length], vocab[(i + 17) % vocab.length]].map((v) => '${v[2]} — ${v[3]}').toList();
        options = _options(correctText, wrongs, 12345 + i * 31);
      }
      final mine = answers[i] == -1 ? 'Not answered' : options[answers[i]];
      final ok = mine == correctText;
      items.add(Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Q${i + 1} — $promptKo', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        Text('Your answer: $mine', style: TextStyle(fontSize: 14, color: ok ? AppColors.greenDark : AppColors.red)),
        Text('Correct answer: $correctText', style: const TextStyle(fontSize: 14, color: AppColors.greenDark)),
        Text(ok ? '✓ Correct' : '✗ Wrong', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ok ? AppColors.greenDark : AppColors.red)),
      ]))));
    }
    return items;
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
      setState(() { started = false; finished = false; qi = 0; listening = 0; reading = 0; secondsLeft = _totalTimeSecs; answers = List<int>.filled(totalQ, -1); flagged.clear(); selectedIdx = null; answered = false; listeningPlays.clear(); autoPlayedQi = -1; });
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
      await AppStore.I.addMock(listening, reading, difficulty: difficulty, secondsUsed: _timeUsed, totalQ: totalQ);
      setState(() => finished = true);
    }
  }
}


// ---------------- My Progress (v1.6.1 showcase) ----------------
/// Real data only, from AppStore: mock history, study days, words.
/// No invented scores: empty state says "No mock yet".
class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});
  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  String tab = 'Overview';
  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    final mocks = (store.progress['mocks'] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
    double scoreOf(Map<String, dynamic> m) {
      final tq = (m['total'] ?? 40) as int;
      return tq > 0 ? ((m['l'] ?? 0) + (m['r'] ?? 0)) * 100 / tq : 0.0;
    }
    final scores = mocks.map(scoreOf).toList();
    final overall = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final best = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a > b ? a : b);
    final trend = scores.length >= 2 ? scores.last - scores[scores.length - 2] : 0.0;
    final days = (store.progress['days'] as List? ?? []).length;
    final totalQs = mocks.fold<int>(0, (a, m) => a + ((m['total'] ?? 40) as int));
    final wordsMastered = (store.progress['words'] as Map? ?? {}).values.where((v) => v == 'mastered').length;
    int totL = 0, totR = 0, totPer = 0;
    for (final m in mocks) {
      totL += (m['l'] ?? 0) as int;
      totR += (m['r'] ?? 0) as int;
      totPer += ((m['total'] ?? 40) as int) ~/ 2;
    }
    final lpct = totPer > 0 ? totL * 100 ~/ totPer : 0;
    final rpct = totPer > 0 ? totR * 100 ~/ totPer : 0;
    final weakListening = lpct <= rpct;
    final weakName = weakListening ? 'Listening' : 'Reading';
    final weakPct = weakListening ? lpct : rpct;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        for (final t in ['Overview', 'Tests', 'Vocabulary'])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text(t, style: const TextStyle(fontSize: 14)), selected: tab == t, onSelected: (_) => setState(() => tab = t)),
          ),
      ]),
      const SizedBox(height: 14),
      if (tab == 'Overview') ...[
        Card(
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Overall Score', style: AppHeadings.sectionTitle),
            Row(children: [
              Text(scores.isEmpty ? '—' : '${overall.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
              const SizedBox(width: 8),
              if (scores.length >= 2)
                Text(trend >= 0 ? '↑ +${trend.toStringAsFixed(0)}%' : '↓ ${trend.toStringAsFixed(0)}%', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: trend >= 0 ? AppColors.greenDark : AppColors.red)),
              if (scores.length < 2) const Text('Take a mock to see your score', style: TextStyle(fontSize: 14, color: AppColors.muted)),
            ]),
            const SizedBox(height: 8),
            // Mini bar chart of mock scores (real data, no chart package).
            if (scores.isEmpty)
              const Text('No mock attempts yet — take your first mock above.', style: TextStyle(fontSize: 14, color: AppColors.muted))
            else
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: scores.map((v) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(children: [
                Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Container(height: (v / 100 * 60).clamp(4, 60), decoration: BoxDecoration(color: AppColors.royalBlue, borderRadius: BorderRadius.circular(6))),
              ])))).toList()),
            const SizedBox(height: 8),
            Text('Best mock: ${best.toStringAsFixed(0)}/100 • Pass 60 • Merit 82.5 (Pakistan 2026)', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          ])),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard('🔥 Study Streak', '$days days', 'Days you studied')),
          const SizedBox(width: 10),
          Expanded(child: _statCard('✅ Total Practice', '$totalQs Qs', 'Questions in mocks')),
        ]),
        const SizedBox(height: 12),
        const Text('Your Weak Topics', style: AppHeadings.sectionTitle),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(14)), child: Icon(weakListening ? Icons.headphones : Icons.menu_book, color: AppColors.royalBlue, size: 24)),
            title: Text(weakName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(mocks.isEmpty ? 'Take a mock to find your weak topic.' : '$weakPct% across your mocks • Listening $lpct% • Reading $rpct%'),
            trailing: TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Learn'), backgroundColor: AppColors.royalDark, foregroundColor: Colors.white), body: const SafeArea(child: LearnPage())))),
              child: const Text('Review >', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
            ),
          ),
        ),
      ] else if (tab == 'Tests') ...[
        const Text('Your past mock attempts', style: AppHeadings.sectionTitle),
        const SizedBox(height: 8),
        if (mocks.isEmpty) const Text('No mock attempts yet.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
        ...mocks.map((m) {
          final sc = scoreOf(m);
          return Card(child: ListTile(
            leading: CircleAvatar(backgroundColor: sc >= 82.5 ? AppColors.pakGreen : (sc >= 60 ? AppColors.royalBlue : AppColors.red), child: Text(sc.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
            title: Text('Listening ${m['l']}/${((m['total'] ?? 40) as int) ~/ 2} • Reading ${m['r']}/${((m['total'] ?? 40) as int) ~/ 2}'),
            subtitle: Text('${(m['d'] ?? 'basic')} • ${(m['date'] ?? '').toString().substring(0, 10)} • ${formatMmSs((m['secs'] ?? 0) as int)}'),
          ));
        }),
      ] else ...[
        const Text('Vocabulary progress', style: AppHeadings.sectionTitle),
        const SizedBox(height: 8),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('⭐ $wordsMastered of ${vocab.length} words known', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: vocab.isEmpty ? 0 : wordsMastered / vocab.length, minHeight: 10, backgroundColor: AppColors.border, valueColor: const AlwaysStoppedAnimation(AppColors.pakGreen)),
          const SizedBox(height: 8),
          const Text('Mark words ⭐ in Vocabulary or tap "I know it" in Flashcards. Words you know count here.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
        ]))),
      ],
    ]);
  }

  Widget _statCard(String title, String big, String sub) => Card(
        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(big, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
          Text(sub, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        ])),
      );
}

// ---------------- Daily Quiz (v1.6.1 showcase) ----------------
/// 10 questions from OUR 329-word bank. +50 coins if 7+ correct and not
/// already earned today; +10 coins otherwise (once per day). Practice
/// again any time — coins only once a day.
class DailyQuizPage extends StatefulWidget {
  const DailyQuizPage({super.key});
  @override
  State<DailyQuizPage> createState() => _DailyQuizPageState();
}

class _DailyQuizPageState extends State<DailyQuizPage> {
  late final List<List<String>> qs;
  late final List<List<String>> opts;
  int idx = 0, score = 0;
  int? selected;
  bool finished = false;
  int? coinsEarned;
  @override
  void initState() {
    super.initState();
    final day = DateTime.now().day;
    final pool = List<List<String>>.of(vocab)..shuffle(Random(day * 31 + 7));
    qs = pool.take(10).toList();
    opts = qs.map((w) {
      final wrongs = vocab.where((v) => v[0] != w[0]).take(30).toList()..shuffle(Random(w[0].length * 13 + 5));
      return [w, ...wrongs.take(3)].map((v) => '${v[2]} — ${v[3]}').toList()..shuffle(Random(w[0].length * 7 + 3));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (finished) {
      return ListView(padding: const EdgeInsets.all(20), children: [
        const Text('🏆', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
        Text(score >= 7 ? 'Excellent!' : (score >= 5 ? 'Good!' : 'Keep going!'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
        Text('You scored $score / 10', textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
        const SizedBox(height: 12),
        Card(
          color: AppColors.softAmber,
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            const Text('🎁', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(child: Text(coinsEarned == null ? 'Rewards: practice again tomorrow for coins.' : 'Rewards: +$coinsEarned Coins! Total: ${AppStore.I.coins} coins.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
          ])),
        ),
        const SizedBox(height: 12),
        ElevatedButton(style: primaryButtonStyle(), onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Home')),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => setState(() { idx = 0; score = 0; selected = null; finished = false; coinsEarned = null; }), child: const Text('Try Again (practice only)')),
      ]);
    }
    final w = qs[idx];
    final correct = '${w[2]} — ${w[3]}';
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('🎁 Answer today\'s quiz and earn rewards!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const Text('10 Questions • +50 Coins if you get 7 or more right • Once a day', style: TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 12),
      Card(
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text('Question ${idx + 1} / 10', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 8),
          Text(w[0], style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
          Text(w[1], style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          ...opts[idx].asMap().entries.map((e) {
            final isSel = selected == e.key;
            final isCor = e.value == correct;
            Color? bg;
            if (selected != null && isSel) bg = isCor ? AppColors.greenDark : AppColors.red;
            if (selected != null && isCor) bg = AppColors.greenDark;
            return Padding(padding: const EdgeInsets.only(bottom: 8), child: SizedBox(width: double.infinity, child: ElevatedButton(
              style: bg != null ? ElevatedButton.styleFrom(backgroundColor: bg, minimumSize: const Size.fromHeight(52)) : null,
              onPressed: selected != null ? null : () => setState(() {
                selected = e.key;
                if (isCor) score++;
              }),
              child: Text(e.value, style: const TextStyle(fontSize: 15)),
            )));
          }),
          if (selected != null) ...[
            const SizedBox(height: 8),
            Text(selected != null && opts[idx][selected!] == correct ? 'Correct! ✓' : 'Not correct — the right answer is: $correct', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: primaryButtonStyle(),
              onPressed: () async {
                if (idx + 1 >= 10) {
                  int? earned;
                  if (!AppStore.I.dailyQuizDoneToday) {
                    earned = score >= 7 ? 50 : 10;
                    await AppStore.I.addCoins(earned);
                    await AppStore.I.markDailyQuizDone();
                  }
                  setState(() { finished = true; coinsEarned = earned; });
                } else {
                  setState(() { idx++; selected = null; });
                }
              },
              child: Text(idx + 1 >= 10 ? 'See result' : 'Next >'),
            )),
          ],
        ])),
      ),
    ]);
  }
}

// ---------------- Grammar (v1.6.1 showcase) ----------------
/// OUR grammar: 2 points per unit, 120 total, from the 61 units.
/// One pattern at a time, with examples, Next > to move on.
class GrammarPage extends StatefulWidget {
  const GrammarPage({super.key});
  @override
  State<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends State<GrammarPage> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final u = units[idx % units.length];
    final parts = u.grammar.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final pattern = parts.isNotEmpty ? parts[0] : u.grammar;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Grammar — 120 points, 2 per unit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      Text('Unit ${u.n} — ${u.en} • ${idx + 1} of ${units.length}', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      const SizedBox(height: 12),
      Card(
        color: AppColors.softBlue,
        child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text(pattern, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.royalBlue)),
          const SizedBox(height: 6),
          Text('Used in: ${u.en} (${u.ko})', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
          if (parts.length > 1) Text('Also in this unit: ${parts.sublist(1).join(', ')}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
        ])),
      ),
      const SizedBox(height: 12),
      const Text('Examples', style: AppHeadings.sectionTitle),
      const SizedBox(height: 8),
      Card(child: ListTile(leading: const Icon(Icons.person, color: AppColors.royalBlue), title: Text('저는 ${u.ko}에 대해 이야기해요.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), subtitle: Text('Let us talk about ${u.en.toLowerCase()}.'))),
      Card(child: ListTile(leading: const Icon(Icons.work, color: AppColors.royalBlue), title: Text('직장에서 ${u.ko}이/가 중요해요.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), subtitle: Text('At work, ${u.en.toLowerCase()} is important.'))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: ElevatedButton(style: primaryButtonStyle(), onPressed: () => setState(() => idx = (idx + 1) % units.length), child: const Text('Next >'))),
      const SizedBox(height: 12),
      const Text('All grammar points', style: AppHeadings.sectionTitle),
      ...units.map((unit) => Card(child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.royalBlue, child: Text('${unit.n}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
        title: Text('Unit ${unit.n} — ${unit.en}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(unit.grammar, style: const TextStyle(fontSize: 14)),
        onTap: () => setState(() => idx = units.indexOf(unit)),
      ))),
    ]);
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
      // v1.6.1 showcase Settings — OUR logo, blue header, green accent.
      Container(
        decoration: BoxDecoration(gradient: showcaseGradient, borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/logo.png', height: 56, width: 56, fit: BoxFit.cover))),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('EPS TOPIK Pro Pakistan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('🇵🇰 Korea Pakka!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Not affiliated with OEC or HRD Korea.', style: TextStyle(fontSize: 14, color: Colors.white)),
          ])),
        ]),
      ),
      const SizedBox(height: 12),
      Card(
        child: Column(children: [
          ListTile(
            leading: const Icon(Icons.language, color: AppColors.royalBlue),
            title: const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: Text(lang == 'english' ? 'English' : (lang == 'roman' ? 'Roman Urdu' : 'اردو'), style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: AppColors.royalBlue),
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text('Daily reminder, 30 minutes a day', style: TextStyle(fontSize: 14)),
            value: AppStore.I.notifications,
            onChanged: (v) async { await AppStore.I.setNotifications(v); setState(() {}); },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: AppColors.royalBlue),
            title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: const Text('Dark background, blue buttons', style: TextStyle(fontSize: 14)),
            value: AppStore.I.darkMode,
            onChanged: (v) async { await AppStore.I.setDarkMode(v); setState(() {}); },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.royalBlue),
            title: const Text('About EPS TOPIK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
            onTap: () => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('About EPS TOPIK'), content: Text('EPS TOPIK Pro Pakistan — Korea Pakka! Free basic-to-test-ready EPS-TOPIK app for Pakistani students. Units 0–60, new HRD Korea syllabus 2024, 40-question mock, voice tutor in 6 languages. Not affiliated with OEC or HRD Korea.'))),
          ),
          ListTile(
            leading: const Icon(Icons.star, color: AppColors.royalBlue),
            title: const Text('Rate Our App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
            onTap: () => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Rate Our App'), content: Text('Thank you! Rating will open in Google Play Store once the app is published there. For now, tell your teacher what you like and what to fix.'))),
          ),
          ListTile(
            leading: const Icon(Icons.share, color: AppColors.royalBlue),
            title: const Text('Share with Friends', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
            onTap: () => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Share with Friends'), content: SelectableText('EPS TOPIK Pro Pakistan — Korea Pakka! Free Korean learning for EPS-TOPIK: Units 0–60, mock test, voice tutor. Pass 60, merit 82.5 (Pakistan 2026).'))),
          ),
          ListTile(
            leading: const Icon(Icons.contact_support, color: AppColors.royalBlue),
            title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
            onTap: () => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Contact Us'), content: Text('App support on WhatsApp is not set up yet. Ask your teacher, or message the app owner directly.'))),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: AppColors.royalBlue),
            title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppColors.muted),
            onTap: () => showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Privacy Policy'), content: Text('We collect only what you enter: your account name, email/mobile, and your learning progress. We do not sell your data. Your progress stays on your phone in this version. You can delete your account below — that deletes all your data on this phone.'))),
          ),
        ]),
      ),
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
      // v1.6.1 already has a Dark Mode switch in Settings (above) — do
      // NOT duplicate it. v1.7.0 adds only the Lite mode switch + card.
      SwitchListTile(
        title: const Text('Lite mode — low data, old phone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
        subtitle: const Text('Turns off auto-play. No ads, no downloads, works offline.', style: TextStyle(fontSize: 14, color: AppColors.muted)),
        value: AppStore.I.liteMode,
        onChanged: (v) async { await AppStore.I.setLiteMode(v); setState(() {}); },
      ),
      Card(
        color: AppColors.softGreen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📴 Offline & Lite — what is already on your phone', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text('No ads. No download needed — this is already in the app, and it works offline: ${vocab.length} vocabulary words • 61 course units • 40+40 Expert mock questions • 35 listening drills • 37 tutor answers • 10 Speak-to-Korea roleplays • 12-week plan.', style: const TextStyle(fontSize: 14, color: AppColors.ink)),
            const SizedBox(height: 6),
            const Text('Honest note: only two things need internet — the Korean voice (your phone’s Korean TTS voice) and the links to OEC / HRD Korea. Everything else works with no internet, on a slow connection, and on an old phone.', style: TextStyle(fontSize: 14, color: AppColors.ink)),
          ]),
        ),
      ),
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
      const Text('Help: if you are stuck, ask your teacher or message the app owner on WhatsApp. Version 1.7.0 (APK test build).', style: TextStyle(fontSize: 14, color: AppColors.muted)),
    ]);
  }
}
