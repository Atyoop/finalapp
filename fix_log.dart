import 'dart:io';

void main() {
  final file = File('analyze.log');
  if (!file.existsSync()) return;
  
  final lines = file.readAsLinesSync();
  
  final errPattern = RegExp(r'error - Invalid constant value - (lib[\\/].*?\.dart):(\d+):(\d+)');
  final errors = <Map<String, dynamic>>[];
  
  for (final line in lines) {
    final match = errPattern.firstMatch(line);
    if (match != null) {
      errors.add({
        'file': match.group(1),
        'line': int.parse(match.group(2)!),
        'col': int.parse(match.group(3)!),
      });
    }
  }

  if (errors.isEmpty) {
    print('No INVALID_CONSTANT errors found in log.');
    return;
  }

  final filesToFix = <String, List<Map<String, dynamic>>>{};
  for (final err in errors) {
    var p = err['file'] as String;
    // Normalize path separators
    p = p.replaceAll('\\', '/');
    filesToFix.putIfAbsent(p, () => []).add(err);
  }

  int fixedCount = 0;
  for (final entry in filesToFix.entries) {
    final filePath = entry.key;
    final f = File(filePath);
    if (!f.existsSync()) {
      print('File not found: $filePath');
      continue;
    }

    var contentLines = f.readAsLinesSync();
    
    // Process backwards
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
            fixedCount++;
            break;
          }
        }
      }
    }
    
    f.writeAsStringSync(contentLines.join('\n') + '\n');
  }
  print('Fixed $fixedCount errors.');
}
