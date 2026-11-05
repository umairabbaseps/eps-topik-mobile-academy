import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eps_topik_pro_pakistan/main.dart';
import 'package:eps_topik_pro_pakistan/store.dart';

void main() {
  testWidgets('app builds and shows auth screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppStore.I.init();
    await tester.pumpWidget(const EpsApp());
    await tester.pump();
    expect(find.text('EPS TOPIK Pro Pakistan'), findsWidgets);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    expect(find.text('Guest ke tor par jaari rakhein'), findsOneWidget);
  });
}
