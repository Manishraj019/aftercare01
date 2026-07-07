import 'dart:io';

void main() {
  final dir = Directory('lib/features');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('block_ui.dart')) continue;

    String content = file.readAsStringSync();
    bool changed = false;

    // Check if we need to replace Card
    if (content.contains('Card(') || content.contains('Card (')) {
      content = content.replaceAll(RegExp(r'\bCard\s*\('), 'BlockContainer(');
      
      // Ensure block_ui.dart is imported if we made a change
      if (!content.contains('block_ui.dart')) {
        // Insert after first import, or at the top
        final importMatch = RegExp(r'import\s+.*?;').firstMatch(content);
        if (importMatch != null) {
            content = content.replaceFirst(
                importMatch.group(0)!, 
                importMatch.group(0)! + '\nimport \'package:restaurantos/core/theme/block_ui.dart\';'
            );
        } else {
            content = 'import \'package:restaurantos/core/theme/block_ui.dart\';\n' + content;
        }
      }
      changed = true;
    }

    // Replace explicit BorderRadius.circular(...) with BorderRadius.zero
    if (content.contains('BorderRadius.circular')) {
      content = content.replaceAll(RegExp(r'BorderRadius\.circular\([^)]+\)'), 'BorderRadius.zero');
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
  print('Refactoring complete.');
}
