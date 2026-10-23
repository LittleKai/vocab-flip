# VocabFlip 🎯

[![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Android%20%7C%20Web-blue.svg)](#-downloads--builds)
[![License](https://img.shields.io/badge/License-Educational-green.svg)](#-license--acknowledgments)

VocabFlip is a premium, feature-rich multi-language vocabulary flashcard learning application built with **Flutter**. Designed for maximum learning efficiency, it integrates the state-of-the-art **FSRS (Free Spaced Repetition Scheduler)** spaced repetition algorithm, vector-based **Writing Practice** with real-time stroke validation, and high-performance **Offline Dictionaries**.

---

## 📥 Downloads & Builds

The official distribution packages and builds for VocabFlip (Windows, Android, and Web) are available at:

👉 **[https://giaiphapsangtao.com/studio/vocab](https://giaiphapsangtao.com/studio/vocab)**

> [!NOTE]
> - **Windows Desktop:** Features in-app auto-update checks and updates directly via metadata hosted on Backblaze B2.
> - **Android App:** Downloads the latest APK package directly or redirects to the official release page.
> - **Web App:** Embedded and runs online directly within the Alpha Studio ecosystem.

---

## 🌟 Key Features

### 📅 Advanced Spaced Repetition (FSRS)
- Powered by the **Free Spaced Repetition Scheduler (FSRS v2)** algorithm to mathematically optimize card review intervals based on user feedback (`Again`, `Hard`, `Good`, `Easy`).
- Fully replaces the legacy SM-2 scheduler, providing a seamless background migration path for existing card states.

### ✍️ Interactive Kanji & Hanzi Writing Practice
- Active stroke practice mode for Chinese (**Hanzi**) and Japanese (**Kanji/Kana**) characters.
- **Stroke Animations & Guides:** Displays character outlines, stroke-by-stroke animations (reveal animation), and directional indicators.
- **Handwriting Validation:** Implements real-time geometric evaluation (resampling, Fréchet distance, and direction cosine similarity) to validate user strokes (accuracy, stroke direction, and order) directly in Dart.
- **Massive Database:** Supports over **16,000+** characters from the animCJK database, bundled locally as a highly compressed, ZLIB-packed `stroke_data.db`.

### ⚡ Blazing-Fast Offline Dictionaries
- Instant, 0ms-latency dictionary lookups using pre-bundled SQLite databases (`en_vi_dict.db`, `zh_vi_dict.db`, `ja_vi_dict.db`).
- Built-in automatic pronunciation via Text-to-Speech (TTS).
- Automatic fallbacks to online dictionaries (Laban, Mazii, LacViet) for edge-case definitions not present in the local database.

### 🎮 Multiple Study Modes
- **Classic Flip:** Traditional flashcard memorization (flip front/back) to reinforce active recall.
- **Multiple Choice:** Quick-fire selection of vocabulary meanings to improve character recognition.
- **Type Answer:** Typing practice for vocabulary spelling and retrieval.
- **Writing Practice:** Hand-drawn input mode to master character strokes.

### 👥 Public Library & Cloud Sync
- **Share Decks:** Share custom vocabulary decks with the community, or browse and import public decks.
- **Cloud Integration:** Syncs with the **Alpha Studio Backend** (Express + MongoDB) for secure account sync, public deck ratings, and library publishing.
- **Google Drive Backup:** Allows users to manually or automatically backup and restore study progress to their personal Google Drive.

### 🎨 Material 3 Premium Design
- Adaptive Light & Dark mode supporting WCAG AA high-contrast requirements.
- Modern dashboard presenting daily review stats, due card focus, and quick navigation.
- Rich learning statistics and weekly progress charts powered by `fl_chart`.

---

## 🛠️ Tech Stack

| Component | Technology | Details |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.5+** | Cross-platform desktop, mobile, and web |
| **State Management** | **Provider** | Predictable state handling and app architecture |
| **Database** | **SQLite** | High-performance local storage via `sqflite` |
| **Algorithm** | **FSRS** | Optimal spaced repetition scheduling (`fsrs` package) |
| **Backend** | **Alpha Studio API** | REST API services running on Express + MongoDB |
| **Cloud Storage** | **Backblaze B2** | Release version metadata and public deck assets |
| **Localization** | **Flutter l10n** | Multi-language support (English and Vietnamese) |

---

## 📂 Project Structure

```
lib/
├── core/           # Constants, app theme, and shared utilities
├── data/           # Data layer: Models, local DAOs, repositories, and remote APIs
│   ├── local/      # SQLite helper, DAOs (cards, decks, dictionaries, stroke data)
│   ├── models/     # Core data structures (Flashcard, Deck, StudySession, StrokeCharacter)
│   ├── remote/     # REST clients, MongoDB sync, and Backblaze B2 services
│   └── repositories/ # Repositories connecting local storage and remote services
├── l10n/           # App localization files (.arb)
└── presentation/   # Presentation layer: UI providers, Screens, and custom Widgets
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.5 or higher recommended)
- Git installed on your system

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/LittleKai/vocab-flip.git
cd vocab-flip

# 2. Get dependencies
flutter pub get

# 3. Configure public client settings only
cp .env.example assets/config.env

# 4. Run the project in debug mode
flutter run
```

### Build Release Artifacts

Run the following commands to compile and build release packages for target platforms:

```bash
# Build for Windows Desktop (ZIP/Installer)
flutter build windows --release

# Build for Android (APK package)
flutter build apk --release

# Build for Web (Embedded inside Alpha Studio)
flutter build web --release --base-href "/vocab/"
```

The app bundles only `assets/config.env`: `API_URL`, `GOOGLE_OAUTH_CLIENT_ID`,
`CLOUDINARY_CLOUD_NAMES`, and `CLOUDINARY_UPLOAD_PRESETS`. These values are public.
Keep operator credentials in the unbundled `.env` or backend environment; never
copy that file into a release. Rotate credentials exposed by older bundles.

Desktop Google Drive sign-in uses a loopback callback, state, and PKCE without
a client secret. Google desktop OAuth registrations that require `client_secret`
will reject this public-client exchange, even with PKCE. Such registrations cannot
support the packaged desktop flow under the no-client-secret policy. Use Drive
backup on Android/Web with the corresponding configured Google client, or use
local export/import on desktop. Re-enabling desktop Drive for those registrations
requires a separately approved server OAuth integration; no broker is included.
Do not restore a bundled client secret as a workaround. Live Google sign-in must
be verified with the operator's correct platform client before release.

Alpha Studio SSO uses same-origin `alpha_studio_token` storage when opening the
VocabFlip tab. Framed `AUTH_TOKEN` messages are accepted only from the same-origin
parent. Logout removes the shell alias only if it still equals the departing
VocabFlip token, preserving any newer shell session. Profiles use separate account
cache snapshots; old unowned profile preferences are retained but never uploaded
under a newly signed-in account.

---

## 📜 License & Acknowledgments

- **License:** Educational and personal use.
- **Ecosystem:** Part of the Alpha Studio project ecosystem.
- **Author:** [LittleKai](https://github.com/LittleKai)
