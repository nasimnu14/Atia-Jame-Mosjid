import 'package:flutter/material.dart';

import '../../data/database.dart';

/// "Export PDF" on the details screen (DET-2). Replaced in Phase 3.
class EntryPdfButton extends StatelessWidget {
  const EntryPdfButton({super.key, required this.entry});
  final Entry entry;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
