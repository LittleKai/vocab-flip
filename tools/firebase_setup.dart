/// Firebase Setup Tool for VocabFlip
///
/// This script helps set up and update Firebase indexes and security rules.
///
/// Usage:
///   dart run tools/firebase_setup.dart [command]
///
/// Commands:
///   indexes  - Deploy Firestore indexes
///   rules    - Deploy Firestore security rules
///   all      - Deploy everything
///   generate - Generate firestore.indexes.json from code
///
/// Requirements:
///   - Firebase CLI installed (npm install -g firebase-tools)
///   - Logged in to Firebase (firebase login)
///   - Project configured (firebase use <project-id>)

import 'dart:io';

void main(List<String> args) async {
  print('╔════════════════════════════════════════════╗');
  print('║     VocabFlip Firebase Setup Tool         ║');
  print('╚════════════════════════════════════════════╝');
  print('');

  final command = args.isNotEmpty ? args[0] : 'help';

  switch (command) {
    case 'indexes':
      await deployIndexes();
      break;
    case 'rules':
      await deployRules();
      break;
    case 'all':
      await deployIndexes();
      await deployRules();
      break;
    case 'generate':
      await generateIndexes();
      break;
    case 'help':
    default:
      printHelp();
  }
}

void printHelp() {
  print('Available commands:');
  print('');
  print('  indexes   - Deploy Firestore indexes');
  print('  rules     - Deploy Firestore security rules');
  print('  all       - Deploy everything');
  print('  generate  - Generate firestore.indexes.json');
  print('  help      - Show this help message');
  print('');
  print('Example:');
  print('  dart run tools/firebase_setup.dart indexes');
}

Future<void> deployIndexes() async {
  print('📦 Deploying Firestore indexes...');
  print('');

  // Generate indexes file first
  await generateIndexes();

  // Deploy using Firebase CLI (use runInShell for Windows compatibility)
  final result = await Process.run(
    'firebase',
    ['deploy', '--only', 'firestore:indexes'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );

  print(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Indexes deployed successfully!');
  } else {
    print('❌ Failed to deploy indexes. Exit code: ${result.exitCode}');
    print('');
    print('Make sure you have:');
    print('  1. Firebase CLI installed: npm install -g firebase-tools');
    print('  2. Logged in: firebase login');
    print('  3. Project configured: firebase use <project-id>');
  }
}

Future<void> deployRules() async {
  print('🔐 Deploying Firestore security rules...');
  print('');

  // Generate rules file
  await generateRules();

  // Deploy using Firebase CLI (use runInShell for Windows compatibility)
  final result = await Process.run(
    'firebase',
    ['deploy', '--only', 'firestore:rules'],
    workingDirectory: Directory.current.path,
    runInShell: true,
  );

  print(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    print('Errors: ${result.stderr}');
  }

  if (result.exitCode == 0) {
    print('✅ Rules deployed successfully!');
  } else {
    print('❌ Failed to deploy rules. Exit code: ${result.exitCode}');
  }
}

Future<void> generateIndexes() async {
  print('📝 Generating firestore.indexes.json...');

  final indexesJson = '''
{
  "indexes": [
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "download_count", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "rating_sum", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "published_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "category_id", "order": "ASCENDING" },
        { "fieldPath": "download_count", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "category_id", "order": "ASCENDING" },
        { "fieldPath": "published_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "source_language", "order": "ASCENDING" },
        { "fieldPath": "download_count", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "target_language", "order": "ASCENDING" },
        { "fieldPath": "download_count", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "author_id", "order": "ASCENDING" },
        { "fieldPath": "updated_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "author_id", "order": "ASCENDING" },
        { "fieldPath": "is_active", "order": "ASCENDING" },
        { "fieldPath": "updated_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "public_decks",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "author_id", "order": "ASCENDING" },
        { "fieldPath": "published_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "sync_notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "user_id", "order": "ASCENDING" },
        { "fieldPath": "is_read", "order": "ASCENDING" },
        { "fieldPath": "created_at", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "sync_notifications",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "user_id", "order": "ASCENDING" },
        { "fieldPath": "created_at", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
''';

  final file = File('firestore.indexes.json');
  await file.writeAsString(indexesJson);
  print('✅ Generated firestore.indexes.json');
}

Future<void> generateRules() async {
  print('📝 Generating firestore.rules...');

  final rules = '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // Public decks - anyone can read, only authenticated users can create
    // Fields: name, description, author_id, author_name, source_language, target_language,
    //         category_id, tags, card_count, version, rating_sum, rating_count,
    //         download_count, is_active, created_at, updated_at, published_at,
    //         original_local_id, short_id, image_url, front_fields, back_fields
    match /public_decks/{deckId} {
      allow read: if true;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn() &&
        resource.data.author_id == request.auth.uid;

      // Flashcards subcollection
      // Fields: front, front_phonetic, back, example, notes, tags, order,
      //         front_image_url, back_image_url, share_image (Cloudinary image hosting)
      // Note: create/update use isSignedIn() only because batchWrite REST API
      // does not support get() in security rules evaluation.
      // delete still validates deck ownership via get().
      match /flashcards/{cardId} {
        allow read: if true;
        allow create, update: if isSignedIn();
        allow delete: if isSignedIn() &&
          get(/databases/\$(database)/documents/public_decks/\$(deckId)).data.author_id == request.auth.uid;
      }

      // Ratings subcollection
      match /ratings/{ratingId} {
        allow read: if true;
        allow create: if isSignedIn();
        allow update, delete: if isOwner(ratingId);
      }
    }

    // Public profiles - anyone can read, only owner can write
    match /public_profiles/{userId} {
      allow read: if true;
      allow write: if isOwner(userId);
    }

    // User data - only accessible by the owner
    match /users/{userId} {
      allow read, write: if isOwner(userId);

      match /imported_decks/{linkId} {
        allow read, write: if isOwner(userId);
      }
    }

    // Sync notifications - only accessible by the target user
    match /sync_notifications/{notificationId} {
      allow read: if isSignedIn() &&
        resource.data.user_id == request.auth.uid;
      allow update: if isSignedIn() &&
        resource.data.user_id == request.auth.uid;
      allow create: if isSignedIn();
      allow delete: if isSignedIn() &&
        resource.data.user_id == request.auth.uid;
    }
  }
}
''';

  final file = File('firestore.rules');
  await file.writeAsString(rules);
  print('✅ Generated firestore.rules');
}
