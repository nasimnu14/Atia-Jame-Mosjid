import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../shared/context_ext.dart';
import '../../shared/formatters.dart';
import '../../shared/period_choice.dart';
import '../../shared/widgets/basics.dart';
import '../../shared/widgets/period_selector.dart';
import 'pdf/pdf_pages.dart';
import 'pdf/report_blocks.dart';
import 'report_pdf_service.dart';
import 'save_pdf.dart';

/// Make a PDF report for any period: income only, expense only, or both with a
/// summary (PDF-1, PDF-2, PDF-5).
class PdfReportScreen extends StatefulWidget {
  const PdfReportScreen({super.key});

  @override
  State<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends State<PdfReportScreen> {
  PeriodChoice _choice = const PeriodChoice.currentMonth();
  ReportContent _content = ReportContent.both;
  bool _busy = false;
  RenderedPdf? _last;

  Future<void> _make() async {
    final l = context.l10n;
    final fmt = context.fmt;
    final services = context.services;
    final today = dateOnly(services.now());
    final period = _choice.resolve(today);
    if (period == null) return;
    setState(() {
      _busy = true;
      _last = null;
    });
    try {
      final name = periodChoiceName(l, fmt, _choice, today);
      final pdf = await services.reports.periodReport(
        l,
        fmt,
        period: period,
        periodName: name,
        content: _content,
      );
      if (!mounted) return;
      setState(() => _last = pdf);
      await savePdfWithDialog(context, pdf, reportFileName(_content, period));
    } catch (e) {
      if (mounted) showError(context, l.pdfFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final today = dateOnly(context.services.now());
    final ready = _choice.resolve(today) != null;
    final controls = AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pdfWhatToInclude,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          RadioGroup<ReportContent>(
            groupValue: _content,
            onChanged: (v) => setState(() => _content = v!),
            child: Column(
              children: [
                for (final (c, label) in [
                  (ReportContent.income, l.pdfIncomeOnly),
                  (ReportContent.expense, l.pdfExpenseOnly),
                  (ReportContent.both, l.pdfBoth),
                ])
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _content == c
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: RadioListTile<ReportContent>(
                        value: c,
                        dense: true,
                        title: Text(
                          label,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.periodLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          PeriodSelector(
            value: _choice,
            today: today,
            onChanged: (c) => setState(() {
              _choice = c;
              _last = null;
            }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l.pdfLanguageNote(
                context.appWatch.bangla ? l.langBangla : l.langEnglish,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: (_busy || !ready) ? null : _make,
            style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
            child: _busy
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(l.pdfGenerating),
                    ],
                  )
                : Text(l.makePdf, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 8),
          Text(
            l.pdfWhereNext,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
      ),
    );

    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.pdfPreview,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 10),
        if (_last == null)
          Container(
            height: 260,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 48,
              color: AppColors.muted.withValues(alpha: 0.5),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14141A18),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Image.memory(_last!.pagePngs.first, fit: BoxFit.fitWidth),
          ),
      ],
    );

    return PageScaffold(
      title: l.navPdf,
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 800) {
            return Column(
              children: [controls, const SizedBox(height: 20), preview],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: controls),
              const SizedBox(width: 20),
              Expanded(flex: 6, child: preview),
            ],
          );
        },
      ),
    );
  }
}
