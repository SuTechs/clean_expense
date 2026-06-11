# Clean Expense Manager

![Cover](/cover.png)

A beautiful, chat-based expense manager app built with Flutter.

## Features
- **Smart Chat Interface**: Add expenses naturally like `dinner #food 500` — note, #category and amount in any order.
- **Edit & Delete**: Long-press any chat bubble, WhatsApp style.
- **On-Device AI**: Ask "Where am I spending most?" and get answers with charts — runs 100% on your phone, private and offline (one-time model download, multiple model tiers).
- **Google Drive Backup**: Free, serverless backup & sync to your own Drive — no account with us, ever.
- **Export**: Branded PDF reports and CSV for Excel/Sheets.
- **Clean Dashboard**: Visualize your Balance, Incoming, Outgoing, and Investments.
- **Detailed Stats**: Breakdown of spending by category using interactive charts.
- **Offline First**: Fast and private with local storage using Hive.
- **Dark Mode**: Beautiful midnight theme support.

## Demo
[Watch how I made it on YouTube](https://youtu.be/KUim8kCIA4I)

## Download
- 🔗 [Official Website](https://sutechs.com/clean-expense)
- 🍎 [App Store](https://apps.apple.com/us/app/clean-expense-track-monney/id6757723320)
- 🤖 [Play Store](https://play.google.com/store/apps/details?id=com.sutechs.expense)

## Getting Started

1. Clone the repo
2. Run `flutter pub get`
3. Run `dart run build_runner build`
4. Run `flutter run`

Everything works out of the box — no keys or accounts needed. The only
optional feature that needs configuration is Google Drive backup (below).

### Optional: Google Drive backup credentials

No credentials live in this repo. To enable Drive backup in your own build,
create your own (free) Google OAuth clients — full walkthrough in
[`docs/google-drive-sync-setup.md`](docs/google-drive-sync-setup.md) — then:

1. Copy `env.example.json` → `env.json` (gitignored) and fill in your
   client IDs, then build with:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

2. **iOS only:** copy `ios/Flutter/Secrets.xcconfig.example` →
   `ios/Flutter/Secrets.xcconfig` (gitignored) and set your reversed
   client id. Info.plist picks it up automatically at build time.

Without these files the app builds and runs normally — the backup feature
simply shows as "not configured". (OAuth client IDs are public identifiers,
not secrets; keeping them out of the repo just prevents third-party builds
from impersonating the official app's consent screen.)

## Roadmap 🚀
We have exciting features planned for the future:
- [x] **Edit/Delete Expenses**: Long-press any chat bubble to edit or delete it.
- [x] **Onboarding**: First-launch walkthrough with a live typing demo.
- [x] **Export Data**: Export to PDF and CSV from the Stats screen.
- [x] **Google Drive Backup**: Free, serverless backup & sync to your own
      Drive (hidden app folder) — see `docs/google-drive-sync-setup.md` for
      the one-time OAuth setup maintainers need.
- [x] **AI Integration** (on-device, private, offline):
  - [x] Ask AI: "Where am I spending the most?" — answered with generated
        charts, powered by a local Qwen3 0.6B model (one-time ~475 MB download).
  - [ ] Multi-Expense Entry: Add multiple expenses in one go.
  - [ ] Conversational follow-ups ("what about last month?").
- [ ] **UPI Scanner**: Scan QR, select app, and auto-log expense.
- [ ] **Custom Themes**: Create and share your own chat themes.
- [ ] **Darker Logo**: A sleek new look.

## Contributing 🤝
Contributions are welcome! If you find any bugs or have feature requests, please file an issue.

## About
Check out our other apps at [SuTechs](https://sutechs.com).

Connect with us:
- [LinkedIn](https://linkedin.com/in/su-mit)
- [Instagram](https://instagram.com/sutechs)

## Credits
Huge thanks to **[Antigravity](https://antigravity.google/)** for the incredible assistance in building this project! 🚀

And to **[Claude Code](https://claude.com/claude-code)** for building v2 — edit/delete, onboarding, Google Drive sync, export, and the on-device AI assistant. 🤖

## License
Copyright © 2026 **SuTechs**. All Rights Reserved.

This project is licensed for personal and educational use only. You are **not allowed** to redistribute, resell, or upload this app to any app store (Google Play, App Store, etc.) without explicit permission.
