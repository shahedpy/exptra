import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:get/get.dart';

import 'package:exptra/main.dart';
import 'package:exptra/core/db/app_database.dart';
import 'package:exptra/modules/accounts/account_controller.dart';

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

  testWidgets('App boots without dependency errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });

  testWidgets('Dashboard sections fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.runAsync(() => Get.find<AccountController>().reload());
    await tester.pump();

    expect(find.text('Net Worth'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
