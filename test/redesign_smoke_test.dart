import 'package:drift/native.dart';
import 'package:exptra/core/db/app_database.dart';
import 'package:exptra/core/routes/app_routes.dart';
import 'package:exptra/main.dart';
import 'package:exptra/modules/accounts/account_form_page.dart';
import 'package:exptra/modules/accounts/transfer_page.dart';
import 'package:exptra/modules/account_type/account_type_controller.dart';
import 'package:exptra/modules/reports/report_page.dart';
import 'package:exptra/modules/lend_borrow/lend_borrow_controller.dart';
import 'package:exptra/data/repositories/accounting_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late AppDatabase db;
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;
    Get.reset();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    Get.put<AppDatabase>(db);
  });
  tearDown(() async {
    await Get.delete<AppDatabase>(force: true);
    Get.reset();
    await db.close();
  });

  testWidgets('financial and management routes render on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    for (final tab in ['Inc/Exp', 'Accounts', 'Len/Bor', 'More']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$tab overflowed');
    }

    for (final label in [
      'Reports',
      'Expense Categories',
      'Income Sources',
      'Banks',
      'Account Types',
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label did not render');
      Get.back();
      await tester.pumpAndSettle();
    }

    for (final page in [
      const AccountFormPage(),
      const TransferPage(),
      const ReportPage(),
    ]) {
      Get.to(() => page);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      Get.back();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('new dropdown values are available after returning to forms', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    for (final (formRoute, manageLabel, newName) in [
      (AppRoutes.addIncome, 'Add income source', 'Project Bonus'),
      (AppRoutes.addExpense, 'Add expense category', 'Home Repairs'),
    ]) {
      Get.toNamed(formRoute);
      await tester.pumpAndSettle();
      await tester.tap(find.text(manageLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded).last);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      await tester.enterText(
        find.descendant(of: dialog, matching: find.byType(TextField)).first,
        newName,
      );
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Add')).last,
      );
      await tester.pumpAndSettle();
      Get.back();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      expect(find.text(newName), findsWidgets);
      Get.back();
      await tester.pumpAndSettle();
      Get.back();
      await tester.pumpAndSettle();
    }

    Get.to(() => const AccountFormPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add bank'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextField)).first,
      'Test Bank',
    );
    await tester.tap(
      find.descendant(of: dialog, matching: find.text('Add')).last,
    );
    await tester.pumpAndSettle();
    Get.back();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Test Bank'), findsWidgets);
  });

  testWidgets('dark theme and larger text keep the main pages usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'Dashboard overflowed in dark theme',
    );
    for (final tab in ['Inc/Exp', 'Accounts', 'Len/Bor', 'More']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '$tab overflowed in dark theme',
      );
    }
  });

  testWidgets('new account type is selected and saved from Add Account', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    Get.to(() => const AccountFormPage());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add account type'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Provident Fund');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Investment').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Account Type'));
    await tester.pumpAndSettle();
    expect(find.text('Account Name'), findsOneWidget);
    expect(find.text('Save Account Type'), findsNothing);
    expect(find.text('Provident Fund'), findsOneWidget);
    final type = Get.find<AccountTypeController>().types.firstWhere(
      (t) => t.name == 'Provident Fund',
    );
    await tester.enterText(find.byType(TextFormField).first, 'Retirement');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save Account'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(AccountFormPage),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Save Account'));
    await tester.pumpAndSettle();
    final account = (await db.select(db.accounts).get()).single;
    expect(account.accountTypeId, type.id);
  });

  testWidgets('partial lend repayment records with the keyboard open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await AccountingRepository(db).saveAccount(
      institutionName: '',
      name: 'Cash',
      type: 'Cash',
      openingBalance: 0,
      openingBalanceDate: DateTime.now(),
    );
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await Get.find<LendBorrowController>().addEntry(
      personName: 'Jabed',
      amount: 70000,
      type: LendBorrowController.typeLend,
      date: DateTime.now(),
    );
    await tester.tap(find.text('Len/Bor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Receive').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cash').last);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      '20000',
    );
    await tester.pumpAndSettle();
    expect(find.text('Receive repayment'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Record'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect((await db.select(db.lendRepayments).get()).single.amount, 20000);
    expect(
      Get.find<LendBorrowController>().outstandingLends.values.single,
      5000000,
    );
    expect(find.text('Lend • Partial'), findsOneWidget);
  });
}
