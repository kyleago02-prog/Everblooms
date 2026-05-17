import 'dart:io';

void main() {
  final file = File('lib/screens/map_screen.dart');
  String content = file.readAsStringSync();
  
  // Replace anything like ST.surface0 -> ST.surface
  content = content.replaceAllMapped(RegExp(r'ST\.([a-zA-Z]+)0'), (match) {
    return 'ST.${match.group(1)}';
  });

  file.writeAsStringSync(content);
  print('Removed trailing 0s from ST accessors.');
}
