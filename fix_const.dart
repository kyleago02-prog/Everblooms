import 'dart:io';

void main() {
  final file = File('lib/screens/map_screen.dart');
  String content = file.readAsStringSync();
  
  // Fix const BoxShadow with .withOpacity
  content = content.replaceAll(
    'const BoxShadow(color: ST.textPrimary.withOpacity(0.2)', 
    'BoxShadow(color: ST.textPrimary.withOpacity(0.2)'
  );

  content = content.replaceAll(
    'ST.primary.withOpacity(0.5).withValues(alpha: 0.6)',
    'ST.primary.withOpacity(0.6)'
  );

  // Fix other const BoxShadows that use withOpacity
  content = content.replaceAll(
    'const BoxShadow(color: ST.primary.withOpacity',
    'BoxShadow(color: ST.primary.withOpacity'
  );
  content = content.replaceAll(
    'const BoxShadow(color: ST.info.withOpacity',
    'BoxShadow(color: ST.info.withOpacity'
  );
  content = content.replaceAll(
    'const BoxShadow(color: ST.danger.withOpacity',
    'BoxShadow(color: ST.danger.withOpacity'
  );

  file.writeAsStringSync(content);
  print('Fixed const BoxShadows in map_screen.dart');
}
