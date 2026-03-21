import 'dart:convert';
import 'dart:io';

void main() async {
  final process = await Process.run('flutter', ['analyze', '--machine'], runInShell: true);
  final output = process.stdout as String;
  final lines = const LineSplitter().convert(output);
  
  final errors = <Map<String, dynamic>>[];
  for (final line in lines) {
    if (line.startsWith('ERROR|COMPILE_TIME_ERROR|INVALID_CONSTANT|')) {
      final parts = line.split('|');
      if (parts.length >= 8) {
        errors.add({
          'file': parts[3],
          'line': int.parse(parts[4]),
          'col': int.parse(parts[5]),
        });
      }
    }
  }

  if (errors.isEmpty) {
    print('No INVALID_CONSTANT errors found.');
    return;
  }

  final filesToFix = <String, List<Map<String, dynamic>>>{};
  for (final err in errors) {
    filesToFix.putIfAbsent(err['file'] as String, () => []).add(err);
  }

  for (final entry in filesToFix.entries) {
    final filePath = entry.key;
    final file = File(filePath);
    if (!file.existsSync()) continue;

    var contentLines = file.readAsLinesSync();
    
    // Sort locations descending
    entry.value.sort((a, b) => (b['line'] as int).compareTo(a['line'] as int));
    
    for (final err in entry.value) {
      final lineIdx = (err['line'] as int) - 1;
      
      for (var offset = 0; offset < 10; offset++) {
        final targetIdx = lineIdx - offset;
        if (targetIdx < 0) break;
        
        var lineStr = contentLines[targetIdx];
        if (lineStr.contains('const ')) {
          final modified = lineStr.replaceFirst(RegExp(r'\bconst\s+'), '');
          if (modified != lineStr) {
            contentLines[targetIdx] = modified;
            print('Fixed const in \$filePath:\${targetIdx + 1}');
            break;
          }
        }
      }
    }
    
    file.writeAsStringSync(contentLines.join('\n') + '\n');
  }
}
