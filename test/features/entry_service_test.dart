import 'package:atia_masjid_accounts/data/tables.dart';
import 'package:atia_masjid_accounts/features/entries/entry_service.dart';
import 'package:atia_masjid_accounts/shared/formatters.dart';
import 'package:atia_masjid_accounts/shared/period.dart';
import 'package:atia_masjid_accounts/shared/permissions.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';

Matcher invalid(EntryField f, EntryProblem p) => throwsA(
    isA<EntryValidationException>().having((e) => e.errors[f], '$f', p));

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());

  group('required fields (INC-2, EXP-2)', () {
    test('income needs receipt no, date and an amount above 0', () async {
      final e = EntryDraft(type: EntryType.income);
      expect(await env.entries.validate(e), {
        EntryField.receiptNo: EntryProblem.required,
        EntryField.date: EntryProblem.required,
        EntryField.amount: EntryProblem.required,
      });
      e
        ..receiptNo = 5
        ..date = DateTime(2026, 11, 13)
        ..amount = 0;
      expect((await env.entries.validate(e))[EntryField.amount], EntryProblem.notPositive);
      e.amount = -10;
      expect((await env.entries.validate(e))[EntryField.amount], EntryProblem.notPositive);
      e.amount = 1;
      expect(await env.entries.validate(e), isEmpty);
    });
    test('income name is optional and saved as unknown (INC-3)', () async {
      final r = await env.addIncome(name: '   ');
      expect(r.entry.name, '');
    });
    test('expense needs payee, purpose and an approver from the list', () async {
      final e = EntryDraft(
          type: EntryType.expense,
          receiptNo: 1,
          date: DateTime(2026, 11, 13),
          amount: 100);
      expect(await env.entries.validate(e), {
        EntryField.name: EntryProblem.required,
        EntryField.purpose: EntryProblem.required,
        EntryField.approver: EntryProblem.required,
      });
      e
        ..name = 'ক'
        ..purpose = 'খ'
        ..approverName = 'কেউ একজন';
      expect((await env.entries.validate(e))[EntryField.approver],
          EntryProblem.notInApproverList); // EXP-6: not free text
    });
    test('a failed save writes nothing', () async {
      await expectLater(
          env.entries.create(env.user, EntryDraft(type: EntryType.income)),
          throwsA(isA<EntryValidationException>()));
      expect((await env.entries.list(EntryQuery(type: EntryType.income))).count, 0);
    });
  });

  group('receipt numbers (INC-4, INC-5, EXP-3)', () {
    test('first suggestion is 1; then highest + 1', () async {
      expect(await env.entries.suggestReceiptNo(EntryType.income), 1);
      await env.addIncome(receipt: 6684);
      await env.addIncome(receipt: 6685);
      expect(await env.entries.suggestReceiptNo(EntryType.income), 6686);
    });
    test('suggestion is the highest, not the latest typed', () async {
      await env.addIncome(receipt: 900);
      await env.addIncome(receipt: 12);
      expect(await env.entries.suggestReceiptNo(EntryType.income), 901);
    });
    test('cancelled entries still use their number', () async {
      final e = await env.addIncome(receipt: 10);
      await env.entries.cancel(env.admin, e.entry.id, 'ভুল');
      expect(await env.entries.suggestReceiptNo(EntryType.income), 11);
    });
    test('income and expense are separate series', () async {
      await env.addIncome(receipt: 6685);
      expect(await env.entries.suggestReceiptNo(EntryType.expense), 1);
      await env.addExpense(receipt: 6685); // same number is fine
      expect(await env.entries.findDuplicate(EntryType.expense, 6685), isNotNull);
      expect(await env.entries.findDuplicate(EntryType.income, 6685), isNotNull);
      expect(await env.entries.findDuplicate(EntryType.expense, 1), isNull);
    });
    test('duplicate warning ignores the entry being edited', () async {
      final a = await env.addIncome(receipt: 5);
      expect(await env.entries.findDuplicate(EntryType.income, 5), isNotNull);
      expect(await env.entries.findDuplicate(EntryType.income, 5, exceptId: a.entry.id),
          isNull);
    });
    test('a duplicate number is a warning, not an error: it still saves', () async {
      await env.addIncome(receipt: 5);
      await env.addIncome(receipt: 5);
      expect((await env.entries.findByReceipt(EntryType.income, 5)).length, 2);
    });
  });

  group('who and when (USR-8)', () {
    test('records the creator and time', () async {
      final r = await env.addIncome();
      expect(r.entry.createdBy, env.user.id);
      expect(r.entry.createdAt, env.clock);
      expect(r.entry.deviceId, 'desktop-1');
    });
    test('GEN-6: any role can add', () async {
      for (final u in [env.user, env.admin, env.superAdmin]) {
        await env.addIncome(receipt: u.name.length + 100, by: u);
      }
    });
    test('a disabled user cannot add', () async {
      await env.users.setActive(env.superAdmin, env.user.id, false);
      await expectLater(env.addIncome(), throwsA(anything));
    });
  });

  group('editing (EDT-1, EDT-2, INC-8)', () {
    EntryDraft draftOf(EntryWithPhotos r, {int? amount}) => EntryDraft(
          type: r.entry.type,
          receiptNo: r.entry.receiptNo,
          date: parseDayKey(r.entry.entryDate),
          name: r.entry.name,
          amount: amount ?? r.entry.amount,
          photos: [
            for (final p in r.photos)
              PhotoDraft(existingId: p.id, existingFileName: p.fileName, label: p.label)
          ],
        );

    test('a User cannot edit alone', () async {
      final r = await env.addIncome();
      await expectLater(
          env.entries.update(env.user, r.entry.id, draftOf(r, amount: 2000)),
          throwsA(isA<PermissionDeniedException>()));
      expect((await env.entries.getById(r.entry.id))!.amount, 1000);
    });
    test('an Admin edits; editor and time are recorded', () async {
      final r = await env.addIncome();
      env.clock = DateTime(2026, 11, 14, 9);
      final u = await env.entries.update(env.admin, r.entry.id, draftOf(r, amount: 2000));
      expect(u.entry.amount, 2000);
      expect(u.entry.editedBy, env.admin.id);
      expect(u.entry.editedAt, env.clock);
      expect(u.entry.createdBy, env.user.id); // creator unchanged
    });
    test('a User with an Admin approving on the spot can edit', () async {
      final r = await env.addIncome();
      final approver = await env.users.authorizeApprover('admin', 'secret2');
      final u = await env.entries.update(env.user, r.entry.id, draftOf(r, amount: 1500),
          approver: approver);
      expect(u.entry.amount, 1500);
      expect(u.entry.editedBy, env.admin.id);
    });
    test('an approver who is only a User is refused', () async {
      final r = await env.addIncome();
      await expectLater(
          env.entries.update(env.user, r.entry.id, draftOf(r), approver: env.user),
          throwsA(isA<PermissionDeniedException>()));
    });
    test('editing validates like creating', () async {
      final r = await env.addIncome();
      await expectLater(env.entries.update(env.admin, r.entry.id, draftOf(r, amount: 0)),
          invalid(EntryField.amount, EntryProblem.notPositive));
    });
    test('a cancelled entry cannot be edited', () async {
      final r = await env.addIncome();
      await env.entries.cancel(env.admin, r.entry.id, 'ভুল');
      await expectLater(env.entries.update(env.admin, r.entry.id, draftOf(r)),
          throwsA(isA<EntryActionException>()));
    });
    test('an expense keeps its saved approver even if the list changes (EXP-8)', () async {
      final r = await env.addExpense(approver: 'সভাপতি');
      final approver = (await env.settings.approvers()).firstWhere((a) => a.name == 'সভাপতি');
      await env.settings.renameApprover(env.admin, approver.id, 'নতুন সভাপতি');
      await env.settings.setApproverActive(env.admin, approver.id, false);
      expect((await env.entries.getById(r.entry.id))!.approverName, 'সভাপতি');
      // and the entry can still be edited while keeping that approver
      final d = EntryDraft(
          type: EntryType.expense,
          receiptNo: 1,
          date: DateTime(2026, 11, 13),
          name: 'দোকান',
          purpose: 'বালু',
          approverName: 'সভাপতি',
          amount: 600);
      expect((await env.entries.update(env.admin, r.entry.id, d)).entry.amount, 600);
    });
  });

  group('cancelling (EDT-3, EDT-4)', () {
    test('only Admin or Super Admin, with a reason; the entry stays', () async {
      final r = await env.addIncome();
      await expectLater(env.entries.cancel(env.user, r.entry.id, 'ভুল'),
          throwsA(isA<PermissionDeniedException>()));
      await expectLater(env.entries.cancel(env.admin, r.entry.id, '   '),
          throwsA(isA<EntryActionException>()));
      env.clock = DateTime(2026, 11, 15, 8);
      final c = await env.entries.cancel(env.admin, r.entry.id, 'ভুল এন্ট্রি');
      expect(c.status, EntryStatus.cancelled);
      expect(c.cancelReason, 'ভুল এন্ট্রি');
      expect(c.cancelledBy, env.admin.id);
      expect(c.cancelledAt, env.clock);
      expect(await env.entries.getById(r.entry.id), isNotNull); // never deleted
    });
    test('cancel with an Admin approving a User on the spot', () async {
      final r = await env.addIncome();
      final approver = await env.users.authorizeApprover('super', 'secret1');
      final c = await env.entries.cancel(env.user, r.entry.id, 'ভুল', approver: approver);
      expect(c.cancelledBy, env.superAdmin.id);
    });
    test('cannot cancel twice', () async {
      final r = await env.addIncome();
      await env.entries.cancel(env.admin, r.entry.id, 'ভুল');
      await expectLater(env.entries.cancel(env.admin, r.entry.id, 'আবার'),
          throwsA(isA<EntryActionException>()));
    });
  });

  group('photos (INC-6, INC-8, INC-10)', () {
    test('up to 10 photos; an 11th is refused', () async {
      final ten = [for (var i = 0; i < 10; i++) TestEnv.photo('ছবি $i')];
      final r = await env.addIncome(photos: ten);
      expect(r.photos.length, 10);
      expect([for (final p in r.photos) p.position], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      final eleven = [...ten, TestEnv.photo('একাদশ')];
      await expectLater(env.addIncome(receipt: 2, photos: eleven),
          invalid(EntryField.photos, EntryProblem.tooMany));
    });
    test('photo files are written next to the data and can be read back', () async {
      final r = await env.addIncome(photos: [TestEnv.photo()]);
      final bytes =
          await env.entries.photoStorage.read(r.entry.id, r.photos.single.fileName);
      expect(bytes, [1, 2, 3]);
    });
    test('adding a photo to a saved entry is an edit: User needs approval', () async {
      final r = await env.addIncome();
      final d = EntryDraft(
          type: EntryType.income,
          receiptNo: 1,
          date: DateTime(2026, 11, 13),
          name: 'দাতা',
          amount: 1000,
          photos: [TestEnv.photo()]);
      await expectLater(env.entries.update(env.user, r.entry.id, d),
          throwsA(isA<PermissionDeniedException>()));
      final u = await env.entries.update(env.admin, r.entry.id, d);
      expect(u.photos.length, 1);
      expect(u.entry.editedBy, env.admin.id);
    });
    test('removing a photo drops its row; labels may not be blank', () async {
      final r = await env.addIncome(photos: [TestEnv.photo('এক'), TestEnv.photo('দুই')]);
      final keep = r.photos.first;
      final d = EntryDraft(
          type: EntryType.income,
          receiptNo: 1,
          date: DateTime(2026, 11, 13),
          name: 'দাতা',
          amount: 1000,
          photos: [
            PhotoDraft(existingId: keep.id, existingFileName: keep.fileName, label: 'নতুন নাম')
          ]);
      final u = await env.entries.update(env.admin, r.entry.id, d);
      expect(u.photos.map((p) => p.label), ['নতুন নাম']);
      d.photos = [TestEnv.photo('  ')];
      await expectLater(env.entries.update(env.admin, r.entry.id, d),
          invalid(EntryField.photos, EntryProblem.blankLabel));
    });
    test('blank labels default to the description plus a number (INC-10)', () {
      final d = EntryDraft(
          type: EntryType.expense,
          purpose: 'সিলেট বালু ২ ট্রলি',
          photos: [TestEnv.photo(''), TestEnv.photo('রশিদ'), TestEnv.photo('')]);
      final labels = withDefaultLabels(d, const Fmt.bn(), unknownName: 'অজ্ঞাত')
          .map((p) => p.label)
          .toList();
      expect(labels, ['সিলেট বালু ২ ট্রলি ১', 'রশিদ', 'সিলেট বালু ২ ট্রলি ৩']);
      final inc = EntryDraft(type: EntryType.income, name: '', photos: [TestEnv.photo('')]);
      expect(withDefaultLabels(inc, const Fmt.en(), unknownName: 'Unknown').single.label,
          'Unknown 1');
    });
  });

  group('finding and listing (FND)', () {
    setUp(() async {
      await env.addIncome(receipt: 1, amount: 100, name: 'আব্দুল করিম', date: DateTime(2026, 11, 13));
      await env.addIncome(receipt: 2, amount: 200, name: 'করিম উদ্দিন', date: DateTime(2026, 11, 10));
      await env.addIncome(receipt: 3, amount: 400, name: 'রহিম', date: DateTime(2026, 10, 31));
      await env.addIncome(receipt: 4, amount: 800, name: 'রহিম', date: DateTime(2025, 12, 31));
      await env.addExpense(receipt: 1, amount: 50, date: DateTime(2026, 11, 13));
    });
    Future<EntryPage> q(String text, [Period? p]) =>
        env.entries.list(EntryQuery(type: EntryType.income, period: p, text: text));

    test('only the chosen type is listed', () async {
      expect((await q('')).count, 4);
      expect((await env.entries.list(EntryQuery(type: EntryType.expense))).count, 1);
    });
    test('FND-2: part of a name is enough', () async {
      expect((await q('করিম')).rows.map((e) => e.receiptNo).toSet(), {1, 2});
      expect((await q('রহি')).count, 2);
    });
    test('FND-1: a receipt number, in English or Bangla digits', () async {
      expect((await q('3')).rows.single.receiptNo, 3);
      expect((await q('৩')).rows.single.receiptNo, 3);
    });
    test('FND-3/4/5: day, month, year, range', () async {
      expect((await q('', Period.day(DateTime(2026, 11, 13)))).count, 1);
      expect((await q('', Period.monthOf(DateTime(2026, 11, 1)))).count, 2);
      expect((await q('', Period.yearOf(DateTime(2026, 1, 1)))).count, 3);
      expect((await q('', Period(DateTime(2026, 10, 31), DateTime(2026, 11, 10)))).count, 2);
    });
    test('FND-7: count and total, FND-8: cancelled shown but not totalled', () async {
      var page = await q('', Period.monthOf(DateTime(2026, 11, 1)));
      expect((page.count, page.total, page.cancelledCount), (2, 300, 0));
      final id = (await env.entries.findByReceipt(EntryType.income, 2)).single.id;
      await env.entries.cancel(env.admin, id, 'ভুল');
      page = await q('', Period.monthOf(DateTime(2026, 11, 1)));
      expect(page.rows.length, 2); // still listed
      expect(page.count, 2);
      expect(page.total, 100); // left out of the total
      expect(page.cancelledCount, 1);
    });
    test('newest first, and paging', () async {
      final all = await q('');
      expect(all.rows.map((e) => e.receiptNo), [1, 2, 3, 4]);
      final page2 = await env.entries.list(EntryQuery(type: EntryType.income),
          limit: 2, offset: 2);
      expect(page2.rows.map((e) => e.receiptNo), [3, 4]);
      expect(page2.count, 4);
    });
    test('search text with % or _ is taken literally', () async {
      expect((await q('%')).count, 0);
      expect((await q('_')).count, 0);
    });
  });
}
