import 'package:flutter/material.dart';

import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'drive_client.dart';

/// Signs in to Google (BAK-1). When a different account is connected, a full
/// backup goes to it at once (BAK-8) unless [backUpAfterChange] is false (the
/// first-launch restore, where there is nothing to back up yet).
Future<bool> connectGoogleAccount(
  BuildContext context, {
  bool backUpAfterChange = true,
}) async {
  final l = context.l10n;
  final s = context.services;
  if (!s.drive.auth.isConfigured) {
    showError(context, l.googleNotConfigured);
    return false;
  }
  try {
    final r = await s.drive.connect();
    if (r.changed && backUpAfterChange) {
      if (context.mounted) showInfo(context, l.accountChangedBackup);
      await s.scheduler.onAccountChanged();
      if (context.mounted) showInfo(context, l.accountChangedDone);
    }
    return true;
  } on DriveException catch (e) {
    if (context.mounted) showError(context, l.connectFailed(e.message));
    return false;
  }
}
