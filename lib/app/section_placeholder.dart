import 'package:flutter/material.dart';

import '../shared/context_ext.dart';
import '../shared/widgets/basics.dart';
import 'desktop_shell.dart';

/// Stand-in for a section that is built in a later phase.
class SectionPlaceholder extends StatelessWidget {
  const SectionPlaceholder({super.key, required this.section});
  final Section section;

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: sectionLabel(context.l10n, section),
    child: Text(context.l10n.loading),
  );
}
