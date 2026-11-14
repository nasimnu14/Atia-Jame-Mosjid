import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../app/theme.dart';
import '../../data/repositories/settings_repository.dart';
import '../../shared/context_ext.dart';
import '../../shared/widgets/basics.dart';
import 'sync_client.dart';
import 'sync_done_screen.dart';
import 'sync_offer.dart';

/// Scan the desktop's QR code (SYN-2), or type its code, then sync. Used for
/// pairing a new phone (MOB-5) and for every later sync.
class SyncScanScreen extends StatefulWidget {
  const SyncScanScreen({super.key});

  @override
  State<SyncScanScreen> createState() => _SyncScanScreenState();
}

class _SyncScanScreenState extends State<SyncScanScreen> {
  final _code = TextEditingController();
  MobileScannerController? _controller;
  bool get _useCamera => context.services.useCameraScanner;
  int _pending = 0;
  int _pendingPhotos = 0;
  bool _busy = false;
  int _sent = 0;
  int _total = 0;
  String? _error;
  bool _manual = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPending();
    if (_useCamera && _controller == null) {
      _controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
      );
    }
  }

  Future<void> _loadPending() async {
    final s = context.services;
    final n = await s.syncClient.pendingCount();
    final photos = await s.db
        .customSelect(
          'SELECT COUNT(*) AS c FROM photos WHERE removed_at IS NULL AND entry_id IN (SELECT id FROM entries WHERE synced = 0)',
        )
        .getSingle();
    if (mounted) {
      setState(() {
        _pending = n;
        _pendingPhotos = photos.read<int>('c');
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _controller?.dispose();
    super.dispose();
  }

  void _onScan(BarcodeCapture capture) {
    if (_busy) {
      return;
    }
    for (final b in capture.barcodes) {
      final offer = SyncOffer.tryDecode(b.rawValue ?? '');
      if (offer != null) {
        _run(offer);
        return;
      }
    }
  }

  void _typed() {
    final offer = SyncOffer.tryDecode(_code.text);
    if (offer == null) {
      setState(() => _error = context.l10n.invalidCode);
      return;
    }
    _run(offer);
  }

  Future<void> _run(SyncOffer offer) async {
    final l = context.l10n;
    final s = context.services;
    final app = context.app;
    final nav = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
      _sent = 0;
      _total = _pending;
    });
    await _controller?.stop();
    final deviceId = await s.settingsRepo.get(SettingKey.deviceId) ?? '';
    final who = app.user?.name;
    final phoneName = who == null
        ? 'Phone ${deviceId.substring(0, deviceId.length < 4 ? deviceId.length : 4)}'
        : l.syncPhoneOf(who);
    try {
      final report = await s.syncClient.sync(
        offer,
        phoneName: phoneName,
        onProgress: (r) {
          if (mounted) {
            setState(() => _sent = r.entriesSent);
          }
        },
      );
      // New accounts: lets people sign in on a new phone, and signs out a
      // user who has been disabled on the computer.
      await app.load();
      await app.refreshUser();
      if (app.user != null && !app.user!.isActive) {
        app.signOut();
      }
      if (!mounted) {
        return;
      }
      await nav.pushReplacement(
        MaterialPageRoute(builder: (_) => SyncDoneScreen(report: report)),
      );
    } on SyncException catch (e) {
      if (!mounted) {
        return;
      }
      await app.load();
      final p = e.partial;
      setState(() {
        _busy = false;
        _error = switch (e.failure) {
          SyncFailure.unauthorised => l.syncUnauthorised,
          SyncFailure.offline =>
            p.entriesSent > 0 || p.remaining > 0
                ? '${l.syncOffline} ${l.syncPartial(context.fmt.integer(p.entriesSent), context.fmt.integer(p.remaining))}'
                : l.syncOffline,
          SyncFailure.rejected => l.syncRejected(e.message),
          SyncFailure.other => l.genericError(e.message),
        };
      });
      await _loadPending();
      _controller?.start().catchError((_) {});
    } catch (e) {
      // Anything unexpected (for example a database error) must not leave the
      // screen stuck on "syncing".
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = l.genericError(e.toString());
      });
      await _loadPending();
      _controller?.start().catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    return Scaffold(
      backgroundColor: const Color(0xFF1B2421),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2421),
        foregroundColor: Colors.white,
        title: Text(
          l.scanTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_useCamera && _controller != null)
                SizedBox(
                  width: 260,
                  height: 260,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onScan,
                      errorBuilder: (context, error) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            l.cameraDenied,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l.scanHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 16),
              if (_busy) ...[
                Text(
                  l.syncing(fmt.integer(_sent), fmt.integer(_total)),
                  key: const Key('syncing'),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _total == 0 ? null : _sent / _total,
                ),
              ],
              if (_error != null) ...[
                MessageBanner(_error!, kind: BannerKind.error),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF26312D),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.willSend,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.willSendLine(
                        fmt.integer(_pending),
                        fmt.integer(_pendingPhotos),
                      ),
                      key: const Key('will-send'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFD3DDD9),
                      ),
                    ),
                    Text(
                      l.sameWifi,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFD3DDD9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _manual = !_manual),
                child: Text(
                  l.enterCodeInstead,
                  style: const TextStyle(color: Color(0xFF9FE3C4)),
                ),
              ),
              if (_manual || !_useCamera) ...[
                TextField(
                  controller: _code,
                  key: const Key('code-field'),
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(hintText: l.codeFieldLabel),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _busy ? null : _typed,
                  child: Text(l.connectBtn),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
