// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offline_posts_manager/main.dart'; // ✅ Ensure this matches your pubspec package name

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OfflinePostsApp()); // ✅ Fixed: MyApp → OfflinePostsApp

    // Verify that the PostListScreen title is displayed.
    expect(find.text('Offline Posts Manager'), findsOneWidget);
  });

  testWidgets('FloatingActionButton is visible', (WidgetTester tester) async {
    await tester.pumpWidget(const OfflinePostsApp());

    // Verify the "New Post" FAB exists.
    expect(find.text('New Post'), findsOneWidget);
  });

  testWidgets('Loading indicator appears initially', (WidgetTester tester) async {
    await tester.pumpWidget(const OfflinePostsApp());

    // Since _loadPosts() is async, we might see loading state briefly.
    // This test ensures the app doesn't crash during initial build.
    expect(find.byType(CircularProgressIndicator), findsAny); // May or may not be visible
    expect(find.text('Offline Posts Manager'), findsOneWidget); // AppBar should always be there
  });
}