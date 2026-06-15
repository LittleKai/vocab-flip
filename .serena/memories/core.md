# VocabFlip core
- Flutter app for vocabulary flashcards, study sessions, public library publish/import, sync, backup, settings.
- State management: Provider only. Do not introduce Bloc/Riverpod.
- Remote backend: Alpha Studio REST API under `lib/data/remote/mongo/` plus `lib/data/api/api_client.dart`.
- Local storage: SQLite DAOs/repositories. Public library imports sync with local DB via import links.
- Web runtime constraints: deck/card data stays API-backed; dictionary `both` mode short-circuits to offline-only on web to avoid blocked third-party CORS; public deck image handling must avoid direct cross-origin downloads on web.
- Key source areas: `lib/data/`, `lib/presentation/`, `lib/l10n/`, `tools/`.