$file = "lib/data/repositories/dictionary_repository.dart"
$content = Get-Content $file -Raw

# Replace lookupAll to use fetchMode for all languages
# Actually I'll do this in python or dart to be safer, or just use edit tool block by block.
