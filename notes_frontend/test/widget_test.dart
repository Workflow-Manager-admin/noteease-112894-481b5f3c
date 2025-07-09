import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_frontend/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NotesListPage), findsOneWidget);
  });

  testWidgets('FAB is present', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesApp());
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
