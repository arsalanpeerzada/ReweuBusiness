import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reweu_business/features/incidents/widgets/resolution_modal.dart';
import 'package:reweu_business/theme/app_theme.dart';

import '../helpers/test_translations.dart';

void main() {
  setUpAll(loadEnglishTranslations);

  group('validation rules', () {
    test('voucher amount', () {
      expect(ResolutionModal.validateVoucherAmount(''), 'resolution.voucher_required');
      expect(ResolutionModal.validateVoucherAmount('abc'), 'resolution.voucher_invalid');
      expect(ResolutionModal.validateVoucherAmount('0'), 'resolution.voucher_positive');
      expect(ResolutionModal.validateVoucherAmount('-50'), 'resolution.voucher_positive');
      expect(ResolutionModal.validateVoucherAmount('50001'), 'resolution.voucher_too_high');
      expect(ResolutionModal.validateVoucherAmount('50000'), isNull);
      expect(ResolutionModal.validateVoucherAmount('9999999'), 'resolution.voucher_too_high');
      expect(ResolutionModal.validateVoucherAmount('1,500'), isNull);
      expect(ResolutionModal.validateVoucherAmount('250.50'), isNull);
    });

    test('summary length limits', () {
      expect(ResolutionModal.validateSummary('RESOLVED', 'ok'), 'resolution.summary_required');
      expect(ResolutionModal.validateSummary('RESOLVED', 'Replaced the dish and apologised'), isNull);
      expect(ResolutionModal.validateSummary('RESOLVED', 'a' * 501), 'resolution.summary_too_long');
      expect(ResolutionModal.validateSummary('RESOLVED', 'a' * 500), isNull);
      expect(ResolutionModal.validateSummary('ACKNOWLEDGED', ''), isNull);
      expect(ResolutionModal.validateSummary('ACKNOWLEDGED', 'a' * 600), isNull);
    });
  });

  testWidgets('blocks submission until the voucher amount is valid', (tester) async {
    final submitted = <List<Object?>>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => ResolutionModal(
                  incidentId: 1,
                  onConfirm: (status, summary, voucher, amount) =>
                      submitted.add([status, summary, voucher, amount]),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final summaryTextField = tester.widget<TextField>(find.byKey(const Key('resolution-summary')));
    expect(summaryTextField.textAlignVertical, TextAlignVertical.top);
    expect(summaryTextField.maxLength, 500);

    await tester.enterText(find.byKey(const Key('resolution-summary')), 'Manager apologised and refunded');
    await tester.tap(find.byKey(const Key('resolution-voucher-switch')));
    await tester.pumpAndSettle();

    final voucherTextField = tester.widget<TextField>(find.byKey(const Key('resolution-voucher-amount')));
    expect(voucherTextField.maxLength, 7);

    await tester.ensureVisible(find.byKey(const Key('resolution-submit')));
    await tester.tap(find.byKey(const Key('resolution-submit')));
    await tester.pumpAndSettle();
    expect(submitted, isEmpty);
    expect(find.text(en('resolution.voucher_required')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('resolution-voucher-amount')), '500');
    await tester.ensureVisible(find.byKey(const Key('resolution-submit')));
    await tester.tap(find.byKey(const Key('resolution-submit')));
    await tester.pumpAndSettle();

    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();

    expect(submitted, [
      ['RESOLVED', 'Manager apologised and refunded', true, 500.0],
    ]);
  });
}
