import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'app_version.dart';

/// "App and updates" card in Settings: shows the version. The update check is
/// added in Phase 5 (UPD-1, UPD-2).
class UpdateCard extends StatefulWidget {
  const UpdateCard({super.key});

  @override
  State<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<UpdateCard> {
  String? _version;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_version == null) {
      appVersionText(context.l10n).then((v) {
        if (mounted) setState(() => _version = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.appAndUpdate,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            l.version(context.fmt.digits(_version ?? '…')),
            style: const TextStyle(fontSize: 14, color: AppColors.text),
          ),
        ],
      ),
    );
  }
}
