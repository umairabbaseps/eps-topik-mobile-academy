# EPS TOPIK Pro Pakistan

**Korea Pakka!**

Learn Korean for Korea Jobs. Free basic-to-test-ready EPS-TOPIK app for Pakistani students.

Focus: Pakistan only for now. Other EPS sending countries may be added later.

## Ownership

- Owner: umairabbaseps (GitHub account in the owner's name)
- App name: EPS TOPIK Pro Pakistan
- Tagline: Korea Pakka!
- Database: own PostgreSQL (Supabase self-hosted on own VPS when paid). Not Firebase.
- Launch: Google Play Store first, iPhone / App Store later.
- Start: FREE — test by direct APK first, pay $25 Play Store only when ready, move to paid Supabase / VPS when earning.

## What the app does

- Pakistan focus: explanation language — English, Roman Urdu, or Urdu written in Urdu script, changeable in settings. Voice tutor answers in the same language the question was asked in: Pashto, Sindhi, Saraiki, Punjabi, Urdu, English.
- OEC journey tracker: lucky draw, test, skill test, roster. Not affiliated with OEC or HRD Korea.
- Test format: 40 questions, 20 reading + 20 listening, 50 minutes, 100 points.
- Pakistan 2026, user-reported: passing floor 60/100 for all sectors, merit 82.5/100. Merit changes each round — check the latest OEC notice at jobs.oec.gov.pk.
- Round 2 Skill Test (compulsory): physical 30 + interview 30 + basic skills 40, below 60% means out, +5 Job Capacity, 205 combined, 2-year roster, no guaranteed job.
- Course: follows the new HRD Korea Standard Korean Textbook (2024 revised edition), Book 1 daily life + Book 2 workplace, in force from 1 Aug 2025, content updated June 2026. Original lessons only — do not copy the textbook or real test questions. Official books are free from HRD Korea.
- Hangul first: 21 vowels + 19 consonants walk, syllable/word builder (letter → part → whole word → meaning), notebook writing practice with full sentences, speak test with honest feedback, 5-level system, timer games, funny Urdu slogans.
- Vocabulary (100+ words with sound), grammar (2 points per unit, listed per unit), listening, reading, sector tracks (manufacturing and agriculture), timed mock simulator scored /100.
- Voice tutor: ask by mic or text in Pashto/Sindhi/Saraiki/Punjabi/Urdu/English, hear the Korean answer slow then normal, meaning in the same language.
- Games: Listen and Tap (full words, Repeat button, no auto-advance), Word Match, Memory Cards, Syllable Builder, Speed Quiz, Daily Challenge.
- Life and Work in Korea: labour rights, minimum wage 2026 10,320 KRW/hour, safety, helpline 1350, emergency 119, no-agent warning.
- Login / Register / Guest, with local progress on this phone. Settings, Privacy Policy, Terms, Reset to Level 1, Delete account, Back/Home navigation on every screen.

## OTP — testing only (important)

Registration and password reset use a 6-digit code. **In this build no email/SMS provider is connected**, so the code is generated on the phone and shown in the app, honestly labelled as a prototype note. It is NOT actually emailed or texted.

This is for testing only. Before any Play Store launch it MUST be replaced by real email/SMS delivery from a server (e.g. Resend for email, Twilio for SMS), so the code is never shown in the app. Anyone who knows a student's email/mobile could otherwise request a reset code and take over the account.

## Urdu font

Jameel Noori Nastaleeq is a licensed font and is not bundled. Urdu script in this app uses Noto Nastaliq Urdu (open font, bundled in `assets/fonts/`). If the owner obtains a Jameel Noori Nastaleeq licence, drop the .ttf into `assets/fonts/` and update `pubspec.yaml`.

## How to build / run

```bash
flutter pub get
flutter run                 # on a connected Android phone / emulator
flutter build apk --debug   # debug APK for testing on mobile
flutter build apk --release # release APK (needs signing for Play Store later)
```

Requirements: Flutter 3.35+ (stable), Android SDK. No paid server is needed for this build — accounts and progress are stored locally on the phone (SharedPreferences). A server / own PostgreSQL is the next step before Play Store, so progress can sync across devices.

## Status

- Prototype: Muse artifact `eps-topik-app` (web, under test).
- Real app: this Flutter code, v1.0.0+1, APK testing only. Not published to Play Store yet — that is a later step, decided by the owner.
