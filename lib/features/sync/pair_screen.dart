import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../sign_in/language_switch.dart';
import 'sync_scan_screen.dart';

/// First launch on a phone: nobody can sign in until the phone has scanned the
/// desktop's QR code once (MOB-5).
class PairScreen extends StatelessWidget {
  const PairScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final steps = [l.pairStep1, l.pairStep2, l.pairStep3];
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: LanguageSwitch(),
              ),
              const SizedBox(height: 12),
              const Center(child: LogoMark(size: 64)),
              const SizedBox(height: 8),
              Text(
                l.appTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.mobilePairTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.mobilePairSub,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              for (final (i, text) in steps.indexed)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          fmt.integer(i + 1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(text, style: const TextStyle(fontSize: 15)),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warnBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l.sameWifiNote,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.warnText,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SyncScanScreen()),
                ),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
                child: Text(l.scanQr, style: const TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
