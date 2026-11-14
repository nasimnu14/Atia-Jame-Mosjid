import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'sync_offer.dart';
import 'sync_server.dart';

/// The desktop's "Phone sync" page: a QR code for a phone to scan (SYN-2). The
/// server runs only while this page is open. Shows how many entries each sync
/// received (SYN-9).
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  SyncHost? _host;
  SyncOffer? _offer;
  StreamSubscription<SyncEvent>? _sub;
  String? _error;

  /// null = waiting; otherwise the phone that is connected now.
  String? _connectedPhone;
  int _receiving = 0;
  SyncFinished? _last;
  List<SyncLogData> _history = const [];
  StreamSubscription<void>? _logSub;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  Future<void> _start() async {
    final s = context.services;
    final l = context.l10n;
    _logSub = s.syncReceiver.changes.listen((_) => _loadHistory());
    _loadHistory();
    try {
      final host = await s.createSyncHost();
      final offer = await host.start();
      if (!mounted) {
        await host.stop();
        return;
      }
      _host = host;
      _sub = host.events.listen(_onEvent);
      setState(() => _offer = offer);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is SocketException && '$e'.contains('No network')
              ? l.syncNoNetwork
              : l.syncServerFailed('$e'),
        );
      }
    }
  }

  void _onEvent(SyncEvent e) {
    if (!mounted) {
      return;
    }
    setState(() {
      switch (e) {
        case OfferChanged(:final offer):
          _offer = offer;
        case PhoneConnected(:final phoneName):
          _connectedPhone = phoneName;
          _receiving = 0;
        case EntryReceived(:final entries):
          _receiving = entries;
        case SyncFinished():
          _last = e;
          _connectedPhone = null;
      }
    });
  }

  Future<void> _loadHistory() async {
    final h = await context.services.syncReceiver.history(limit: 8);
    if (mounted) {
      setState(() => _history = h);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _logSub?.cancel();
    _host?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final offer = _offer;

    final qrCard = AppCard(
      padding: const EdgeInsets.all(28),
      radius: 12,
      child: Column(
        children: [
          if (_error != null)
            MessageBanner(_error!, kind: BannerKind.error)
          else if (offer == null)
            const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Semantics(
                image: true,
                label: l.syncScanInstruction,
                child: QrImageView(
                  key: ValueKey('sync-qr-${offer.token}'),
                  data: offer.encode(),
                  size: 240,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.text,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            l.syncScanInstruction,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _connectedPhone == null
                      ? AppColors.primary
                      : AppColors.warnBorder,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _connectedPhone == null
                    ? l.waitingForPhone
                    : '${l.phoneConnected(_connectedPhone!)} ${l.receivedProgress(fmt.integer(_receiving))}',
                style: const TextStyle(fontSize: 14, color: AppColors.income),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.codeOnce,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          Text(
            l.sameWifi,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (offer != null) ...[
            const SizedBox(height: 14),
            Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                title: Text(
                  l.syncCodeLabel,
                  style: const TextStyle(fontSize: 13),
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  SelectableText(
                    offer.encode(),
                    key: const Key('sync-code'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: offer.encode()),
                      );
                      if (context.mounted) {
                        showInfo(context, l.codeCopied);
                      }
                    },
                    child: Text(l.copyCode),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _host == null ? null : () => _host!.newOffer(),
            child: Text(l.newCode),
          ),
        ],
      ),
    );

    final last = _last;
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (last != null) ...[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.incomeSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF0B4A3C),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.lastSyncDone(fmt.integer(last.entries)),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B4A3C),
                        ),
                      ),
                      Text(
                        l.syncBreakdown(
                          fmt.integer(last.income),
                          fmt.integer(last.expense),
                          fmt.integer(last.photos),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0B4A3C),
                        ),
                      ),
                      if (last.duplicates > 0)
                        Text(
                          l.syncDuplicateNote(fmt.integer(last.duplicates)),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0B4A3C),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.whatIsExchanged,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _kv(l.phoneToComputer, l.phoneToComputerDesc),
              const SizedBox(height: 10),
              _kv(l.computerToPhone, l.computerToPhoneDesc),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Text(
                  l.previousSyncs,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_history.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Text(
                    l.noSyncsYet,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final h in _history)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.divider)),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      SizedBox(
                        width: 180,
                        child: Text(
                          h.phoneName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: Text(
                          fmt.dateTime(h.at),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      Text(
                        l.entriesCount(fmt.integer(h.entriesReceived)),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    return PageScaffold(
      title: l.navSync,
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 800) {
            return Column(
              children: [qrCard, const SizedBox(height: 20), right],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: qrCard),
              const SizedBox(width: 20),
              Expanded(flex: 5, child: right),
            ],
          );
        },
      ),
    );
  }

  Widget _kv(String k, String v) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 150,
        child: Text(
          k,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 14))),
    ],
  );
}
