# VocabFlip

A multi-language vocabulary learning flashcard app built with Flutter.

## Features

- **Flashcard Learning** - Create and study flashcards with spaced repetition (SM-2 algorithm)
- **Multi-language Support** - Learn English, Vietnamese, Japanese, and Chinese
- **Dictionary Integration** - Auto-fill from online dictionaries (Laban, Mazii, LacViet)
- **Text-to-Speech** - Pronunciation for all supported languages
- **Public Library** - Browse, import, and share decks with the community
- **Cloud Sync** - Alpha Studio account sync, deck publishing, and public library
- **Dark Mode** - Light and dark theme support
- **Auto-Update** - Automatic updates via Backblaze B2 release metadata (Windows) and APK links (Android)

## Screenshots

*Coming soon*

## Getting Started

### Prerequisites

- Flutter SDK 3.38+
- Windows / Android / Web

### Installation

```bash
# Clone the repository
git clone https://github.com/LittleKai/vocab-flip.git
cd vocab-flip

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build

```bash
# Windows
flutter build windows --release

# Android
flutter build apk --release

# Web embedded in Alpha Studio
flutter build web --release --base-href "/vocab/"
```

## Tech Stack

- **Framework:** Flutter 3.38
- **State Management:** Provider
- **Database:** SQLite (sqflite)
- **Backend:** Alpha Studio Backend (Express + MongoDB)
- **Release Storage:** Backblaze B2 public CDN
- **APIs:** Free Dictionary, Laban, Mazii, LacViet

## Project Structure

```
lib/
├── core/           # Constants, theme, utilities
├── data/           # Models, DAOs, repositories, APIs
├── presentation/   # Providers, screens, widgets
└── l10n/           # Localization (EN, VI)
```

## License

This project is for personal/educational use.

## Author

LittleKai
