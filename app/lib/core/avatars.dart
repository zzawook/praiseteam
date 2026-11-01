import 'package:flutter/material.dart';

import '../app/theme.dart';

/// A person's initial on their own color, the same on every screen.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.name, required this.id, this.radius = 20});
  final String name;

  /// What picks the color (the user id), so renaming keeps it.
  final String id;
  final double radius;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: AppPalette.of(context).person(id),
    foregroundColor: Colors.white,
    child: Text(
      name.isEmpty ? '?' : name.characters.first,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: radius * 0.8),
    ),
  );
}
