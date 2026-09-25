import 'package:drift/native.dart';
import 'package:exptra/core/db/app_database.dart';
import 'package:exptra/core/theme/app_theme.dart';
import 'package:exptra/core/utils/helpers.dart';
import 'package:exptra/core/widgets/app_ui.dart';
import 'package:exptra/data/repositories/accounting_repository.dart';
import 'package:exptra/main.dart';
import 'package:exptra/modules/accounts/accounts_page.dart';
import 'package:exptra/modules/accounts/transfer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('account amount sits next to its menu with a long name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    Get.reset();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
    addTearDown(() async {
      await Get.delete<AppDatabase>(force: true);
      Get.reset();
      await db.close();
    });
    await AccountingRepository(db).saveAccount(
      institutionName: '',
      name: 'SHAHED MOHAMMAD HRIDOY',
      type: 'Savings',
      openingBalance: 12345678.90,
      openingBalanceDate: DateTime.now(),
    );
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    Get.to(() => const AccountsPage());
    await tester.pumpAndSettle();

    final row = find
        .ancestor(
          of: find.text('SHAHED MOHAMMAD HRIDOY'),
          matching: find.byType(InkWell),
        )
        .first;
    final amount = find.descendant(
      of: row,
      matching: find.text(CurrencyHelper.formatAmount(12345678.90)),
    );
    final menu = find.descendant(of: row, matching: find.byType(IconButton));
    expect(amount, findsOneWidget);
    expect(
      tester.getTopLeft(menu).dx - tester.getTopRight(amount).dx,
      closeTo(8, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'long financial titles keep complete amounts at the trailing edge',
    (tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const amounts = [
        '৳100.00',
        '৳4,406.63',
        '৳29,400.00',
        '৳1,152,457.00',
        '৳12,345,678.90',
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
                child: Column(
                  children: [
                    for (final amount in amounts)
                      AppFinancialListRow(
                        title: 'Very Long Family House Rent Description',
                        amount: amount,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      for (final amount in amounts) {
        final text = find.text(amount);
        expect(text, findsOneWidget);
        expect(tester.getTopRight(text).dx, closeTo(304, 1));
      }
    },
  );

  testWidgets('Transfer Fee and Transfer Date stay separated at larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.testMode = true;
    Get.reset();
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
    addTearDown(() async {
      await Get.delete<AppDatabase>(force: true);
      Get.reset();
      await db.close();
    });

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    Get.to(() => const TransferPage());
    await tester.pumpAndSettle();

    final fee = find.byWidgetPredicate(
      (widget) =>
          widget is AppAmountField && widget.label == 'Fee (optional expense)',
    );
    final date = find.byType(AppDateField);
    await tester.ensureVisible(date);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(date).dy - tester.getBottomLeft(fee).dy,
      greaterThanOrEqualTo(16),
    );
    expect(
      tester.getTopLeft(find.text('Transfer Date')).dy,
      greaterThan(tester.getBottomLeft(fee).dy),
    );
    expect(tester.takeException(), isNull);
  });
}
