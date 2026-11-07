// v1.7.0 — differentiation features.
// OEC Lucky Draw + Merit Tracker, and "Speak to Korea" honest roleplay.
// Kept in its own file so the parallel v1.6.1 showcase work in main.dart
// is not disturbed: main.dart only imports this file and wires 2 rows.
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';

final FlutterTts _v17tts = FlutterTts();

Future<void> _v17speak(String text, {double rate = 0.45}) async {
  try {
    await _v17tts.setLanguage('ko-KR');
    await _v17tts.setSpeechRate(rate);
    await _v17tts.setVolume(1.0);
    await _v17tts.speak(text);
  } catch (_) {}
}

Future<void> _v17speakSlowThenNormal(String text) async {
  await _v17speak(text, rate: 0.35);
  await Future.delayed(const Duration(milliseconds: 900));
  await _v17speak(text, rate: 0.6);
}

/// Honest similarity — same rule as the Speak Test (P0-4): exact match or
/// Levenshtein <= 1-2 ONLY. No contains() shortcut, no false praise.
bool v17IsClose(String heard, String target) {
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

// ---------------- A. OEC Lucky Draw + Merit Tracker ----------------
/// NOT live data: the app has no OEC feed. Every date/number is labelled
/// with its source, and the screen tells the student to check the latest
/// OEC notice at jobs.oec.gov.pk. 2027 dates are NOT invented.
class OecTrackerPage extends StatelessWidget {
  const OecTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    double bestMock = 0;
    for (final m in (AppStore.I.progress['mocks'] as List? ?? [])) {
      final totalQ = (m['total'] ?? 40) as int;
      final t = totalQ > 0 ? ((m['l'] ?? 0) + (m['r'] ?? 0)) * 100 / totalQ : 0.0;
      if (t > bestMock) bestMock = t;
    }
    final above = bestMock >= 82.5;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('OEC Tracker — Lucky Draw & Merit', style: AppHeadings.sectionTitle),
      const Text('Your road to Korea, step by step. This is NOT live data — the app has no OEC feed. Check the latest OEC notice yourself at jobs.oec.gov.pk.', style: AppHeadings.sectionSub),
      const SizedBox(height: 12),
      // Merit card — your best mock vs the 82.5 merit, real numbers only.
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.royalDark, AppColors.royalBlue, AppColors.tealDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pakistan 2026 merit: 82.5 / 100', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          const Text('Passing floor: 60 / 100 for all sectors. Aim for 85+ — above merit, not just above the floor.', style: TextStyle(fontSize: 14, color: Colors.white)),
          const SizedBox(height: 10),
          Text(
            bestMock > 0
                ? 'Your best mock: ${bestMock.toStringAsFixed(0)} / 100 — ${above ? 'above the 82.5 merit ✓ Korea pakka!' : '${(82.5 - bestMock).toStringAsFixed(0)} points to the 82.5 merit — keep practising!'}'
                : 'No mock yet — take a Mock Test (40 questions, 50 min) and your best score will show here.',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: bestMock > 0 ? (bestMock / 100).clamp(0, 1) : 0, minHeight: 8, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation(Colors.white)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      const Text('The numbers that matter', style: AppHeadings.sectionTitle),
      const SizedBox(height: 8),
      ...oecTrackerFacts.map((f) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${f[0]}: ${f[1]}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
              subtitle: Text(f[2], style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            ),
          )),
      const SizedBox(height: 12),
      const Text('Your journey — 6 steps', style: AppHeadings.sectionTitle),
      const Text('2026 round dates are as reported. 2027 dates are not announced yet — do not trust anyone who gives you a 2027 date before OEC does.', style: AppHeadings.sectionSub),
      const SizedBox(height: 8),
      ...oecTrackerSteps.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(s[1], style: const TextStyle(fontSize: 14, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(s[2], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.greenDark)),
              ]),
            ),
          )),
      const SizedBox(height: 12),
      const Text('Check official results & notices', style: AppHeadings.sectionTitle),
      const Text('Re-test results, exam dates and merit lists are published by OEC Pakistan and HRD Korea — not in this app. This app is not affiliated with OEC or HRD Korea.', style: AppHeadings.sectionSub),
      const SizedBox(height: 6),
      const SelectableText('jobs.oec.gov.pk — OEC Pakistan (registration, draw, results)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.royalDark)),
      const SizedBox(height: 4),
      const SelectableText('epstopik.hrdkorea.or.kr — HRD Korea EPS-TOPIK (test criteria, books, results)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.royalDark)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.softRed, borderRadius: BorderRadius.circular(AppSpacing.radiusCard)),
        child: const Text('⚠️ Scam warning: no agent can buy you a draw slot or a job. Only OEC + HRD Korea can. Never pay an agent for a draw, a test pass, or a job in Korea.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
      ),
    ]);
  }
}

// ---------------- B. "Speak to Korea" — honest roleplay ----------------
/// 10 original workplace + interview roleplays. The student speaks the
/// reply on the mic; the app compares it honestly (exact / Levenshtein
/// <= 1-2 only) and never says "Very good" for a wrong answer.
/// Model answer audio: slow, then normal. Mic unavailable = clear
/// message + tap-to-hear the model instead — the screen is never blocked.
class SpeakToKoreaPage extends StatefulWidget {
  const SpeakToKoreaPage({super.key});
  @override
  State<SpeakToKoreaPage> createState() => _SpeakToKoreaPageState();
}

class _SpeakToKoreaPageState extends State<SpeakToKoreaPage> {
  int idx = 0;
  int score = 0;
  int tries = 0;
  String feedback = '';
  String heardText = '';
  bool listeningMic = false;
  bool showModel = false;

  void _answer(bool correct, String target) {
    setState(() {
      if (correct) {
        score++;
        feedback = 'Very good! ⭐ That was correct and polite. $target';
        tries = 0;
      } else {
        tries++;
        feedback = tries >= 3
            ? 'Not quite yet — listen again. What you said did not match the polite reply. Tap "Show model answer", hear it slow, then try again. We never say Very good for a wrong answer.'
            : 'Not quite yet — listen again. That was not the polite reply. Hear the model answer below, then try ${3 - tries} more time(s).';
      }
    });
  }

  Future<void> _speakTest(String target) async {
    final stt = SpeechToText();
    try {
      final ok = await stt.initialize();
      if (!ok) {
        setState(() { listeningMic = false; feedback = 'Mic / speech recognition is not available on this phone. Tap "Show model answer" and hear it instead — the screen is never blocked.'; });
        return;
      }
      setState(() { listeningMic = true; feedback = 'Listening… say your reply now, clearly, once.'; heardText = ''; });
      await stt.listen(onResult: (r) {
        if (r.finalResult) {
          final heard = r.recognizedWords;
          setState(() { listeningMic = false; heardText = heard.isEmpty ? '(nothing heard)' : heard; });
          _answer(v17IsClose(heard, target), target);
          stt.stop();
        }
      }, localeId: 'ko-KR');
    } catch (_) {
      setState(() { listeningMic = false; feedback = 'Mic not available. Tap "Show model answer" and hear it instead.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = speakRoleplays[idx % speakRoleplays.length];
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Speak to Korea — talk to your boss', style: AppHeadings.sectionTitle),
      const Text('A Korean boss or colleague speaks to you. Answer on the mic — politely, like at work. The app tells you honestly if it was right. Score: correct answers only.', style: AppHeadings.sectionSub),
      const SizedBox(height: 12),
      Text('Roleplay ${idx + 1} of ${speakRoleplays.length}  •  Score: $score correct', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.ink)),
      const SizedBox(height: 8),
      Card(
        color: AppColors.softBlue,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r[0], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.ink)),
            Text(r[1], style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 10),
            Text(r[2], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.ink)),
            Text('${r[3]} — ${r[4]}', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 10),
            Row(children: [
              ElevatedButton(onPressed: () => _v17speakSlowThenNormal(r[2]), child: const Text('🔊 Hear them')),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.orangeDark),
                onPressed: () => _speakTest(r[5]),
                child: const Text('🎤 Answer on mic'),
              ),
            ]),
          ]),
        ),
      ),
      if (listeningMic)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.mic, color: AppColors.red, size: 24),
            SizedBox(width: 8),
            Text('Listening… say your reply now, clearly, once.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.red)),
          ]),
        ),
      if (heardText.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text('You said: $heardText', style: const TextStyle(fontSize: 14, color: AppColors.muted))),
      if (feedback.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 10), child: Text(feedback, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink))),
      const SizedBox(height: 12),
      Row(children: [
        ElevatedButton(
          onPressed: () => setState(() => showModel = !showModel),
          child: Text(showModel ? 'Hide model answer' : 'Show model answer'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => setState(() { idx = (idx + 1) % speakRoleplays.length; feedback = ''; heardText = ''; tries = 0; showModel = false; }),
          child: const Text('Next roleplay →'),
        ),
      ]),
      if (showModel)
        Card(
          color: AppColors.softGreen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Model answer — say it like this:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink)),
              const SizedBox(height: 6),
              Text(r[5], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
              Text('${r[6]} — ${r[7]}', style: const TextStyle(fontSize: 14, color: AppColors.muted)),
              const SizedBox(height: 6),
              Text('💡 ${r[8]}', style: const TextStyle(fontSize: 14, color: AppColors.ink)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => _v17speakSlowThenNormal(r[5]), child: const Text('🔊 Hear the model answer')),
            ]),
          ),
        ),
      const SizedBox(height: 12),
      const Text('Why this matters: in Round 2 (Skill Test interview) and at work in Korea, the examiner and your boss judge you on polite, correct Korean — not just on knowing words. Practise answering a real person, not just repeating a word.', style: AppHeadings.sectionSub),
    ]);
  }
}
