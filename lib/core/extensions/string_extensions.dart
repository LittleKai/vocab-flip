extension StringExtensions on String {
  /// Capitalize the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize the first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string contains only whitespace
  bool get isBlank => trim().isEmpty;

  /// Check if string is not blank
  bool get isNotBlank => !isBlank;

  /// Truncate string to specified length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Remove all whitespace from string
  String removeWhitespace() => replaceAll(RegExp(r'\s+'), '');

  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Convert string to slug (URL-friendly)
  String toSlug() {
    return toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  /// Parse comma-separated tags
  List<String> toTagList() {
    return split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  /// Check if string contains Japanese characters
  bool get containsJapanese {
    return RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]').hasMatch(this);
  }

  /// Check if string contains Chinese characters
  bool get containsChinese {
    return RegExp(r'[\u4E00-\u9FFF]').hasMatch(this);
  }

  /// Check if string contains only ASCII characters
  bool get isAsciiOnly {
    return RegExp(r'^[\x00-\x7F]*$').hasMatch(this);
  }
}

extension NullableStringExtensions on String? {
  /// Returns true if string is null or empty
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Returns true if string is null or blank
  bool get isNullOrBlank => this == null || this!.isBlank;

  /// Returns the string or a default value if null/empty
  String orDefault(String defaultValue) {
    return isNullOrEmpty ? defaultValue : this!;
  }
}
