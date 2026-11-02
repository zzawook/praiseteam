import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';

/// Errors the app knows how to explain. Database RPCs raise these SQLSTATEs
/// on purpose (see supabase/migrations), so the mapping is exact.
enum AppErrorKind { invalidCode, notAllowed, lastOwner, accountNeedsOwner, inUse, network, googleNotConfigured, other }

class AppError implements Exception {
  const AppError(this.kind, [this.detail = '']);
  final AppErrorKind kind;
  final String detail;

  static AppError from(Object error) {
    if (error is AppError) return error;
    if (error is PostgrestException) {
      switch (error.code) {
        case 'PT001':
          return AppError(AppErrorKind.accountNeedsOwner, error.message);
        case 'P0002':
          return AppError(AppErrorKind.invalidCode, error.message);
        case '42501':
          return AppError(AppErrorKind.notAllowed, error.message);
        case '23514':
          return AppError(AppErrorKind.lastOwner, error.message);
        case '23503': // foreign key: still referenced (e.g. a song in a setlist)
          return AppError(AppErrorKind.inUse, error.message);
      }
      return AppError(AppErrorKind.other, error.message);
    }
    if (error is AuthException) return AppError(AppErrorKind.other, error.message);
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup') ||
        text.contains('XMLHttpRequest')) {
      return AppError(AppErrorKind.network, text);
    }
    return AppError(AppErrorKind.other, text);
  }

  String message(AppLocalizations l10n) => switch (kind) {
    AppErrorKind.invalidCode => l10n.errorInvalidCode,
    AppErrorKind.notAllowed => l10n.errorNotAllowed,
    AppErrorKind.lastOwner => l10n.errorLastOwner,
    AppErrorKind.accountNeedsOwner => l10n.accountNeedsOwner,
    AppErrorKind.inUse => l10n.songInUse,
    AppErrorKind.network => l10n.errorNetwork,
    AppErrorKind.googleNotConfigured => l10n.errorGoogleNotConfigured,
    AppErrorKind.other => l10n.errorGeneric(detail),
  };

  @override
  String toString() => 'AppError($kind, $detail)';
}
