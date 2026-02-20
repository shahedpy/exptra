import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:exptra/main.dart';
import 'package:exptra/core/db/app_database.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Get.testMode = true;
    Get.reset();
    Get.put<AppDatabase>(AppDatabase());
  });

  tearDown(() async {
    await Get.delete<AppDatabase>(force: true);
    Get.reset();
  });

  testWidgets('App boots without dependency errors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MyApp), findsOneWidget);
  });
}
