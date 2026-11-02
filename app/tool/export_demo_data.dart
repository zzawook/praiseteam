import 'dart:convert';
import 'dart:io';
import 'package:praiseteam/demo/demo_seed.dart';

void main(List<String> args) {
  final reference = jsonDecode(File('assets/demo/reference.json').readAsStringSync()) as Map<String,dynamic>;
  final target = File(args.isEmpty ? '../demo/media/work/seed.json' : args.first);
  target.parent.createSync(recursive:true);
  target.writeAsStringSync(jsonEncode(seedDemo(reference)));
}
