import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/env.dart';
import '../../core/widgets.dart';
import '../../l10n/app_localizations.dart';
import 'auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final auth = ref.read(authRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _StaffMark(),
                  const SizedBox(height: 28),
                  Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginTagline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _run(auth.signInWithGoogle),
                    icon: const Icon(Icons.login),
                    label: Text(l10n.continueWithGoogle),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => launchUrl(Env.privacyPolicy),
                    child: Text(l10n.privacyPolicy),
                  ),
                  if (Env.devLogin) ...[
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(l10n.devLoginTitle, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l10n.email),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(labelText: l10n.password),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _run(() => auth.signUpWithPassword(
                                      _email.text.trim(),
                                      _password.text,
                                    )),
                            child: Text(l10n.signUp),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: _busy
                                ? null
                                : () => _run(() => auth.signInWithPassword(
                                      _email.text.trim(),
                                      _password.text,
                                    )),
                            child: Text(l10n.signIn),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five staff lines with two strokes on them: one in team ink, one in
/// pencil. It is the app's one piece of decoration and shows its idea.
class _StaffMark extends StatelessWidget {
  const _StaffMark();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        width: 120,
        child: CustomPaint(
          painter: _StaffPainter(
            line: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      );
}

class _StaffPainter extends CustomPainter {
  _StaffPainter({required this.line});
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final staff = Paint()
      ..color = line
      ..strokeWidth = 1.5;
    final gap = size.height / 6;
    for (var i = 1; i <= 5; i++) {
      canvas.drawLine(Offset(0, gap * i), Offset(size.width, gap * i), staff);
    }
    final ink = Paint()
      ..color = AppColors.teamInk
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final pencil = Paint()
      ..color = AppColors.myPencil
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.12, gap * 4.2)
        ..cubicTo(size.width * 0.3, gap * 0.6, size.width * 0.42, gap * 5.4, size.width * 0.58, gap * 1.6),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.66, gap * 3.6)
        ..quadraticBezierTo(size.width * 0.8, gap * 2.0, size.width * 0.92, gap * 3.0),
      pencil,
    );
  }

  @override
  bool shouldRepaint(covariant _StaffPainter oldDelegate) => oldDelegate.line != line;
}
