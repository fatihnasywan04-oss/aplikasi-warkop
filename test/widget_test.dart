import 'package:flutter_test/flutter_test.dart';
import 'package:warkop_digital/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Warkop Digital menampilkan halaman login', (WidgetTester tester) async {
    await tester.pumpWidget(const WarkopApp());
    expect(find.text('Warkop Digital'), findsWidgets);
    expect(find.byType(TextField), findsWidgets);
  });
}
