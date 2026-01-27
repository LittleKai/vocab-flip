# Project Conventions

## File Naming

### Dart Files
- **Pattern:** `snake_case.dart`
- **Screens:** `{feature}_screen.dart` (e.g., `study_screen.dart`)
- **Widgets:** `{name}_widget.dart` or `{name}.dart` (e.g., `flip_card.dart`)
- **Providers:** `{domain}_provider.dart` (e.g., `deck_provider.dart`)
- **Models:** `{entity}.dart` (e.g., `flashcard.dart`)
- **DAOs:** `{entity}_dao.dart` (e.g., `deck_dao.dart`)
- **Repositories:** `{domain}_repository.dart` (e.g., `flashcard_repository.dart`)
- **APIs:** `{name}_api.dart` (e.g., `jisho_api.dart`)
- **Services:** `{name}_service.dart` (e.g., `tts_service.dart`)
- **Utils:** `{name}_utils.dart` (e.g., `date_utils.dart`)

### Folders
- **Pattern:** `snake_case`
- **Features:** Grouped by domain (e.g., `screens/deck/`, `screens/flashcard/`)
- **Widgets:** Placed in `widgets/` subfolder within screen folder or `presentation/widgets/`

---

## Class Naming

### General
- **Pattern:** `PascalCase`
- **Widgets:** `{Name}Widget` or just `{Name}` (e.g., `FlipCard`, `LoadingWidget`)
- **Screens:** `{Feature}Screen` (e.g., `StudyScreen`, `DeckListScreen`)
- **Providers:** `{Domain}Provider` (e.g., `FlashcardProvider`)
- **Models:** `{Entity}` (e.g., `Deck`, `Flashcard`)
- **DAOs:** `{Entity}Dao` (e.g., `FlashcardDao`)
- **Repositories:** `{Domain}Repository` (e.g., `DictionaryRepository`)
- **Enums:** `{Name}` (e.g., `StudyState`, `ReviewRating`)

### Private Members
- **Pattern:** Leading underscore (`_variableName`, `_methodName()`)
- **Used for:** Internal state in providers, controllers, private methods

---

## Component Structure

### Screen Pattern
```dart
class FeatureScreen extends StatefulWidget {
  // Final properties only
  final String requiredParam;

  const FeatureScreen({super.key, required this.requiredParam});

  @override
  State<FeatureScreen> createState() => _FeatureScreenState();
}

class _FeatureScreenState extends State<FeatureScreen> {
  // 1. State variables
  // 2. Lifecycle methods (initState, dispose)
  // 3. Build method
  // 4. Private helper methods
  // 5. Private widget builders
}
```

### Provider Pattern
```dart
class DomainProvider extends ChangeNotifier {
  // 1. Dependencies (repositories)
  final Repository _repository;

  // 2. Private state
  List<Entity> _items = [];
  bool _isLoading = false;
  String? _error;

  // 3. Constructor with DI
  DomainProvider({Repository? repository})
      : _repository = repository ?? Repository();

  // 4. Public getters
  List<Entity> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 5. Computed getters
  int get totalItems => _items.length;

  // 6. Public methods (async with try-catch)
  Future<void> loadItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Model Pattern
```dart
class Entity {
  // 1. Final fields
  final String id;
  final String name;
  final DateTime createdAt;

  // 2. Constructor with defaults
  Entity({
    String? id,
    required this.name,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  // 3. Computed getters
  bool get isNew => ...;

  // 4. copyWith method
  Entity copyWith({String? name, ...}) {
    return Entity(
      id: id, // Keep original id
      name: name ?? this.name,
      ...
    );
  }

  // 5. Database serialization
  Map<String, dynamic> toMap() => {...};
  factory Entity.fromMap(Map<String, dynamic> map) => ...;

  // 6. JSON serialization (for export)
  Map<String, dynamic> toJson() => {...};
  factory Entity.fromJson(Map<String, dynamic> json) => ...;

  // 7. Equality & hashCode (based on id)
  @override
  bool operator ==(Object other) => other is Entity && other.id == id;
  @override
  int get hashCode => id.hashCode;

  // 8. toString for debugging
  @override
  String toString() => 'Entity(id: $id, name: $name)';
}
```

### DAO Pattern
```dart
class EntityDao {
  final AppDatabase _appDatabase;

  EntityDao({AppDatabase? appDatabase})
      : _appDatabase = appDatabase ?? AppDatabase();

  Future<Database> get _db => _appDatabase.database;

  // CRUD operations
  Future<int> insert(Entity entity) async {...}
  Future<int> update(Entity entity) async {...}
  Future<int> delete(String id) async {...}
  Future<Entity?> getById(String id) async {...}
  Future<List<Entity>> getAll() async {...}

  // Query operations
  Future<List<Entity>> search(String query) async {...}
  Future<int> getCount() async {...}

  // Batch operations
  Future<void> insertBatch(List<Entity> entities) async {...}
}
```

---

## Import Order

Standard order for Dart imports:
```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. External packages (alphabetical)
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

// 4. Project imports - Core (alphabetical)
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

// 5. Project imports - Data (alphabetical)
import '../../data/models/flashcard.dart';
import '../../data/repositories/flashcard_repository.dart';

// 6. Project imports - Presentation (alphabetical)
import '../providers/flashcard_provider.dart';
import '../widgets/common/loading_widget.dart';

// 7. Relative imports (same folder)
import 'sub_widget.dart';
```

---

## Code Style

### Formatting
- **Line length:** 80 characters (Flutter default)
- **Indentation:** 2 spaces
- **Trailing commas:** Always use for multi-line parameters

### Naming
- **Variables:** `camelCase`
- **Constants:** `UPPER_SNAKE_CASE` in AppConstants, otherwise `camelCase`
- **Private:** `_leadingUnderscore`
- **Boolean getters:** `isLoading`, `hasError`, `canSubmit`

### Null Safety
- **Required params:** Use `required` keyword
- **Optional params:** Use `?` suffix and provide defaults
- **Null checks:** Use `?.`, `??`, `!` appropriately
- **Late initialization:** Avoid `late` when possible

### Async/Await
```dart
// Good - async method with proper error handling
Future<void> loadData() async {
  try {
    final data = await _repository.getData();
    _data = data;
  } catch (e) {
    _error = e.toString();
  } finally {
    notifyListeners();
  }
}
```

### String Interpolation
```dart
// Good
'Hello, $name!'
'Count: ${items.length}'

// Avoid
'Hello, ' + name + '!'
```

---

## Widget Guidelines

### Const Constructors
- Use `const` for stateless widgets when possible
- Add `const` to child widgets in build methods

### Build Method
- Keep build methods focused
- Extract complex widgets to private methods or separate widgets
- Use `Consumer` or `context.watch` for provider data

### Keys
- Use `ValueKey` for list items with unique IDs
- Use `GlobalKey` sparingly (form validation, navigators)

---

## State Management Rules

### Provider Usage
```dart
// Reading data (rebuilds on change)
final provider = context.watch<DeckProvider>();

// Reading data (no rebuild)
final provider = context.read<DeckProvider>();

// Using Consumer widget
Consumer<DeckProvider>(
  builder: (context, provider, child) {
    return Text(provider.totalDecks.toString());
  },
)

// Using Selector for optimization
Selector<DeckProvider, int>(
  selector: (_, provider) => provider.totalDecks,
  builder: (_, count, __) => Text('$count'),
)
```

### State Location
- **UI state:** In StatefulWidget (`_isExpanded`, `_selectedIndex`)
- **Feature state:** In Provider (`_decks`, `_isLoading`)
- **App state:** In Provider with SharedPreferences (`_isDarkMode`)

---

## Database Conventions

### Table Names
- **Pattern:** `snake_case`, plural (e.g., `decks`, `flashcards`)

### Column Names
- **Pattern:** `snake_case`
- **Foreign keys:** `{table}_id` (e.g., `deck_id`)
- **Timestamps:** `created_at`, `updated_at`, `reviewed_at`
- **Booleans:** Store as INTEGER (0/1)

### Queries
- Use parameterized queries to prevent SQL injection
- Use `ConflictAlgorithm.replace` for upsert operations
- Create indexes for frequently queried columns

---

## API Conventions

### HTTP Clients
- Use `http.Client` with dependency injection for testing
- Return `null` on error (graceful degradation)
- Dispose clients when done

### Response Handling
```dart
if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  return _parseResponse(data);
}
return null; // Graceful failure
```

---

## Error Handling

### Try-Catch Pattern
```dart
try {
  // Operation
} catch (e) {
  _error = e.toString(); // or specific error message
} finally {
  _isLoading = false;
  notifyListeners();
}
```

### User-Facing Errors
- Show SnackBar for transient errors
- Show Dialog for critical errors
- Display EmptyStateWidget for "no data" states

---

## Testing Conventions

### File Naming
- **Unit tests:** `{file}_test.dart`
- **Widget tests:** `{widget}_test.dart`
- **Integration tests:** `integration_test/{feature}_test.dart`

### Mocking
- Use `mockito` for mocking dependencies
- Create mock implementations in `test/mocks/` folder

---

## Documentation

### Code Comments
- Use `///` for documentation comments on public APIs
- Use `//` for implementation notes
- Mark unfinished work with `// TODO:`

### README
- Keep README.md updated with setup instructions
- Document any required API keys or configuration
