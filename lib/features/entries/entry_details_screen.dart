import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/context_ext.dart';
import '../../shared/formatters.dart';
import '../../shared/permissions.dart';
import '../../shared/role_text.dart';
import '../../shared/widgets/basics.dart';
import '../reports/entry_pdf_button.dart';
import 'approval_dialog.dart';
import 'cancel_dialog.dart';
import 'entry_form_screen.dart';
import 'entry_service.dart';
import 'entry_text.dart';
import 'photo_viewer.dart';

/// Every field of an entry, who added / edited / cancelled it and when, and all
/// of its photos (DET-1). Edit and cancel start here (EDT-1 to EDT-4).
class EntryDetailsScreen extends StatefulWidget {
  const EntryDetailsScreen({super.key, required this.entryId});
  final String entryId;

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  EntryWithPhotos? _data;
  final Map<String, User?> _users = {};
  bool _missing = false;
  StreamSubscription<void>? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub == null) {
      _sub = context.services.entries.changes.listen((_) => _load());
      _load();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final services = context.services;
    final data = await services.entries.getWithPhotos(widget.entryId);
    if (data == null) {
      if (mounted) setState(() => _missing = true);
      return;
    }
    final e = data.entry;
    for (final id in [e.createdBy, e.editedBy, e.cancelledBy]) {
      if (id != null && !_users.containsKey(id)) {
        _users[id] = await services.users.byId(id);
      }
    }
    if (mounted) setState(() => _data = data);
  }

  Future<void> _edit(Entry e) async {
    final auth = await requireAuthority(context, e, Permission.editEntry);
    if (auth == null || !mounted) return;
    final data = _data!;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(
          type: e.type,
          existing: data,
          approver: auth.approver,
        ),
      ),
    );
  }

  Future<void> _cancel(Entry e) async {
    final auth = await requireAuthority(context, e, Permission.cancelEntry);
    if (auth == null || !mounted) return;
    final done = await showCancelEntryDialog(context, e, auth.approver);
    if (done && mounted) showInfo(context, context.l10n.entryCancelled);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    if (_missing) {
      return PageScaffold(
        title: l.entryNotFound,
        child: const SizedBox.shrink(),
      );
    }
    final data = _data;
    if (data == null) {
      return PageScaffold(title: l.loading, child: const SizedBox.shrink());
    }
    final e = data.entry;
    final cancelled = e.status == EntryStatus.cancelled;
    final isIncome = e.type == EntryType.income;
    final me = context.appWatch.user!;
    final deviceLabel = e.deviceId == context.services.deviceId
        ? l.fromComputer
        : l.fromPhone;

    final fields = <(String, String)>[
      (receiptNoLabel(l, e.type), fmt.integer(e.receiptNo)),
      (l.dateLabel, fmt.date(parseDayKey(e.entryDate))),
      (isIncome ? l.donorName : l.payeeName, displayName(l, e)),
      if (!isIncome) (l.purposeLabel, e.purpose ?? '—'),
      if (!isIncome) (l.approvedBy, e.approverName ?? '—'),
      (
        l.amountTaka,
        cancelled
            ? l.amountNotCounted(fmt.money(e.amount))
            : fmt.money(e.amount),
      ),
      (l.addressLabel, (e.address ?? '').isEmpty ? '—' : e.address!),
      if (isIncome) (l.typeLabel, l.typeIncome),
    ];

    return PageScaffold(
      breadcrumb: Breadcrumb(
        root: entryTitle(l, e.type),
        current: (isIncome ? l.crumbReceipt : l.crumbVoucher)(
          fmt.integer(e.receiptNo),
        ),
      ),
      title: isIncome ? l.incomeDetailsTitle : l.expenseDetailsTitle,
      subtitle: null,
      actions: [
        EntryPdfButton(entry: e),
        if (!cancelled) ...[
          OutlinedButton(onPressed: () => _edit(e), child: Text(l.editEntry)),
          OutlinedButton(
            onPressed: () => _cancel(e),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.cancelledText,
              side: const BorderSide(color: Color(0xFFE5B3B5)),
            ),
            child: Text(l.cancelEntry),
          ),
        ],
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              cancelled
                  ? StatusPill.cancelled(l.statusCancelled)
                  : StatusPill(l.statusActive),
              if (e.isDuplicate) ...[
                const SizedBox(width: 8),
                StatusPill.warn(l.statusDuplicate),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (cancelled) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cancelledBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.cancelledBanner,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6E1519),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.cancelledByLine(
                      _whoName(l, e.cancelledBy),
                      _roleOf(l, e.cancelledBy),
                      e.cancelledAt == null ? '' : fmt.dateTime(e.cancelledAt!),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E1519),
                    ),
                  ),
                  Text(
                    l.cancelReasonLine(e.cancelReason ?? ''),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6E1519),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (e.isDuplicate) ...[
            MessageBanner(l.duplicateDetailBanner),
            if (can(me.role, Permission.editEntry))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      context.services.entries.clearDuplicateFlag(me, e.id),
                  child: Text(l.markReviewed),
                ),
              ),
            const SizedBox(height: 14),
          ],
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = (c.maxWidth / 240).floor().clamp(1, 4);
                    final w = (c.maxWidth - (cols - 1) * 24) / cols;
                    return Wrap(
                      spacing: 24,
                      runSpacing: 18,
                      children: [
                        for (final (k, v) in fields)
                          SizedBox(
                            width: w,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  k,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  v,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const Divider(height: 32),
                Wrap(
                  spacing: 28,
                  runSpacing: 8,
                  children: [
                    _meta(
                      l.addedBy(
                        _whoName(l, e.createdBy),
                        _roleOf(l, e.createdBy),
                        deviceLabel,
                        fmt.dateTime(e.createdAt),
                      ),
                    ),
                    if (e.syncedAt != null)
                      _meta(l.syncedAtDesktop(fmt.dateTime(e.syncedAt!))),
                    _meta(
                      e.editedAt == null
                          ? l.notEdited
                          : l.editedByLine(
                              _whoName(l, e.editedBy),
                              _roleOf(l, e.editedBy),
                              fmt.dateTime(e.editedAt!),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.photosCount(fmt.integer(data.photos.length)),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (data.photos.isEmpty)
                    Text(
                      l.nothingToShow,
                      style: const TextStyle(color: AppColors.muted),
                    )
                  else
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (final (i, p) in data.photos.indexed)
                          SizedBox(
                            width: 200,
                            child: InkWell(
                              onTap: () =>
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).push(
                                    MaterialPageRoute(
                                      builder: (_) => PhotoViewerScreen(
                                        entry: e,
                                        photos: data.photos,
                                        initial: i,
                                      ),
                                    ),
                                  ),
                              child: Semantics(
                                button: true,
                                label: l.openPhoto(p.label),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 150,
                                      width: 200,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: AppColors.neutralPill,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: SavedPhotoImage(
                                        entryId: e.id,
                                        photo: p,
                                        cacheWidth: 400,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      p.label,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _whoName(AppLocalizations l, String? id) {
    final u = id == null ? null : _users[id];
    return u?.name ?? l.unknownUser;
  }

  String _roleOf(AppLocalizations l, String? id) {
    final u = id == null ? null : _users[id];
    return u == null ? '' : roleName(l, u.role);
  }

  Widget _meta(String text) =>
      Text(text, style: const TextStyle(fontSize: 13, color: AppColors.muted));
}
