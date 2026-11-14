import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/database.dart';
import '../../data/tables.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/bangla.dart';
import '../../shared/context_ext.dart';
import '../../shared/formatters.dart';
import '../../shared/period_choice.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/period_selector.dart';
import 'entry_details_screen.dart';
import 'entry_form_screen.dart';
import 'entry_service.dart';
import 'entry_text.dart';

const _pageSize = 25;

/// The income or expense list: periods, search, count and total, cancelled and
/// duplicate marks (FND-1 to FND-9). Opens on the current month (FND-6).
class EntryListScreen extends StatefulWidget {
  const EntryListScreen({super.key, required this.type});
  final EntryType type;

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  PeriodChoice _choice = const PeriodChoice.currentMonth();
  final _search = TextEditingController();
  Timer? _debounce;
  StreamSubscription<void>? _sub;
  EntryPage? _page;
  int _pageIndex = 0;
  int _duplicates = 0;
  bool _onlyDuplicates = false;
  bool _loadedOnce = false;
  int _generation = 0;

  bool get _isIncome => widget.type == EntryType.income;

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
    _debounce?.cancel();
    _sub?.cancel();
    _search.dispose();
    super.dispose();
  }

  DateTime get _today => dateOnly(context.services.now());

  Future<void> _load() async {
    final svc = context.services.entries;
    final period = _choice.resolve(_today);
    final gen = ++_generation;
    final dupes = await svc.duplicateCount(widget.type);
    EntryPage? page;
    if (period != null) {
      page = await svc.list(
        EntryQuery(
          type: widget.type,
          period: period,
          text: _search.text,
          onlyDuplicates: _onlyDuplicates,
        ),
        limit: _pageSize,
        offset: _pageIndex * _pageSize,
      );
    }
    if (!mounted || gen != _generation) return;
    setState(() {
      _page = page;
      _duplicates = dupes;
      _loadedOnce = true;
    });
  }

  void _reset() {
    _pageIndex = 0;
    _load();
  }

  /// FND-1: typing a receipt number and pressing Enter opens that entry,
  /// whatever its date.
  Future<void> _openByNumber(String text) async {
    final l = context.l10n;
    final no = int.tryParse(toEnglishDigits(text.trim()));
    if (no == null) return;
    final svc = context.services.entries;
    final matches = await svc.findByReceipt(widget.type, no);
    if (!mounted) return;
    if (matches.isEmpty) {
      showInfo(context, l.entryNotFoundByNumber(context.fmt.integer(no)));
    } else if (matches.length == 1) {
      _open(matches.single);
    } else {
      final picked = await showDialog<Entry>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: Text(
            '${receiptNoLabel(l, widget.type)} ${context.fmt.integer(no)}',
          ),
          children: [
            for (final m in matches)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, m),
                child: Text(entrySummaryLine(l, context.fmt, m)),
              ),
          ],
        ),
      );
      if (picked != null) _open(picked);
    }
  }

  void _open(Entry e) {
    // FND-9: selecting an entry opens its details.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EntryDetailsScreen(entryId: e.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final fmt = context.fmt;
    final period = _choice.resolve(_today);
    final page = _page;
    final from = _pageIndex * _pageSize;

    return PageScaffold(
      title: entryTitle(l, widget.type),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EntryFormScreen(type: widget.type),
            ),
          ),
          child: Text(_isIncome ? l.newIncome : l.newExpense),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_duplicates > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.warnBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warnText,
                  ),
                  Text(
                    l.duplicatesBanner(fmt.integer(_duplicates)),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.warnText,
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      _onlyDuplicates = !_onlyDuplicates;
                      _reset();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      foregroundColor: AppColors.warnText,
                      side: const BorderSide(color: AppColors.warnBorder),
                    ),
                    child: Text(
                      _onlyDuplicates ? l.showAll : l.showDuplicatesOnly,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PeriodSelector(
                  value: _choice,
                  today: _today,
                  onChanged: (c) {
                    setState(() => _choice = c);
                    _reset();
                  },
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: LabeledField(
                    label: l.searchLabel,
                    controller: _search,
                    hint: _isIncome ? l.searchHintReceipt : l.searchHintVoucher,
                    onChanged: (_) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 250),
                        _reset,
                      );
                    },
                    onSubmitted: _openByNumber,
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (period != null && page != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Wrap(
                spacing: 24,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    periodChoiceName(l, fmt, _choice, _today),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    l.entriesCount(fmt.integer(page.count)),
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${l.totalLabel} '),
                        TextSpan(
                          text: fmt.money(page.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _isIncome
                                ? AppColors.income
                                : AppColors.expense,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                  Text(
                    page.cancelledCount > 0
                        ? '${l.cancelledNotCounted} (${fmt.integer(page.cancelledCount)})'
                        : l.cancelledNotCounted,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: !_loadedOnce
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : (page == null || page.rows.isEmpty)
                  ? Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          l.noEntries,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MediaQuery.sizeOf(context).width < 640
                            ? _cards(l, fmt, page)
                            : _table(l, fmt, page),
                        _pager(l, fmt, page, from),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(AppLocalizations l, Fmt fmt, EntryPage page) {
    final income = _isIncome;
    // (title, flex or fixed width)
    final cols = income
        ? [
            (l.colReceiptNo, 90.0, false),
            (l.colDate, 110.0, false),
            (l.colDonor, 1.4, true),
            (l.colAddress, 1.0, true),
            (l.colPhotos, 70.0, false),
            (l.colAmount, 120.0, false),
            ('', 90.0, false),
          ]
        : [
            (l.colVoucherNo, 80.0, false),
            (l.colDate, 110.0, false),
            (l.payeeName, 1.1, true),
            (l.colPurpose, 1.2, true),
            (l.colApprover, 1.0, true),
            (l.colAmount, 120.0, false),
            ('', 100.0, false),
          ];
    Widget cell(int i, Widget child) {
      final (_, size, flex) = cols[i];
      return flex
          ? Expanded(flex: (size * 10).round(), child: child)
          : SizedBox(width: size, child: child);
    }

    Widget rowOf(
      List<Widget> cells, {
      Color? bg,
      VoidCallback? onTap,
      bool header = false,
      bool border = true,
    }) {
      final row = Container(
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: header ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: header ? AppColors.background : bg,
          border: border && !header
              ? const Border(top: BorderSide(color: AppColors.divider))
              : null,
        ),
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              cell(i, cells[i]),
              if (i < cells.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      );
      return onTap == null ? row : InkWell(onTap: onTap, child: row);
    }

    TextStyle headStyle() => const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.muted,
    );

    return LayoutBuilder(
      builder: (context, c) {
        final width = c.maxWidth < 800 ? 800.0 : c.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            child: Column(
              children: [
                rowOf([
                  for (var i = 0; i < cols.length; i++)
                    Text(
                      i == cols.length - 1 ? l.colStatus : cols[i].$1,
                      style: headStyle(),
                      textAlign: i == cols.length - 2
                          ? TextAlign.right
                          : TextAlign.left,
                    ),
                ], header: true),
                for (final e in page.rows)
                  rowOf(
                    _cells(l, fmt, e, page.photoCounts[e.id] ?? 0),
                    onTap: () => _open(e),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _cells(AppLocalizations l, Fmt fmt, Entry e, int photos) {
    final cancelled = e.status == EntryStatus.cancelled;
    final amount = Text(
      fmt.money(e.amount),
      textAlign: TextAlign.right,
      style: TextStyle(
        fontWeight: cancelled ? FontWeight.w400 : FontWeight.w600,
        color: cancelled ? AppColors.muted : AppColors.text,
        decoration: cancelled ? TextDecoration.lineThrough : null,
      ),
    );
    final status = Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (cancelled) StatusPill.cancelled(l.statusCancelled),
        if (e.isDuplicate) StatusPill.warn(l.statusDuplicate),
      ],
    );
    Text t(String s, {FontWeight? w, Color? c}) => Text(
      s,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 14, fontWeight: w, color: c),
    );
    final date = t(fmt.date(parseDayKey(e.entryDate)));
    final no = t(fmt.integer(e.receiptNo), w: FontWeight.w600);
    if (_isIncome) {
      return [
        no,
        date,
        t(displayName(l, e)),
        t((e.address ?? '').isEmpty ? '—' : e.address!, c: AppColors.muted),
        t(photos == 0 ? '—' : l.entriesCountPhotos(fmt.integer(photos))),
        amount,
        status,
      ];
    }
    return [
      no,
      date,
      t(displayName(l, e)),
      t(e.purpose ?? ''),
      t(e.approverName ?? '', c: AppColors.muted),
      amount,
      status,
    ];
  }

  /// The list on a phone: one card per entry.
  Widget _cards(AppLocalizations l, Fmt fmt, EntryPage page) {
    return Column(
      children: [
        for (final e in page.rows)
          InkWell(
            onTap: () => _open(e),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.type == EntryType.expense &&
                                  (e.purpose ?? '').isNotEmpty
                              ? '${displayName(l, e)} · ${e.purpose}'
                              : displayName(l, e),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${receiptNoLabel(l, e.type)} ${fmt.integer(e.receiptNo)} · ${fmt.date(parseDayKey(e.entryDate))}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.money(e.amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: e.status == EntryStatus.cancelled
                              ? AppColors.muted
                              : (_isIncome
                                    ? AppColors.income
                                    : AppColors.expense),
                          decoration: e.status == EntryStatus.cancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (e.status == EntryStatus.cancelled)
                            StatusPill.cancelled(l.statusCancelled),
                          if (e.isDuplicate) StatusPill.warn(l.statusDuplicate),
                          if (context.services.isPhone)
                            e.synced
                                ? StatusPill(l.syncedPill)
                                : StatusPill.warn(l.pendingPill),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _pager(AppLocalizations l, Fmt fmt, EntryPage page, int from) {
    final to = from + page.rows.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Text(
            l.showingRange(
              fmt.integer(from + 1),
              fmt.integer(to),
              fmt.integer(page.count),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: _pageIndex == 0
                    ? null
                    : () {
                        _pageIndex--;
                        _load();
                      },
                child: Text(l.prevPage),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: to >= page.count
                    ? null
                    : () {
                        _pageIndex++;
                        _load();
                      },
                child: Text(l.nextPage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
