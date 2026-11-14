import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reweu_business/core/widgets/app_logo.dart';

void main() {
  testWidgets('AppLogo renders without badge by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo(height: 24),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('PARTNERS'), findsNothing);
  });

  testWidgets('AppLogo renders with PARTNERS badge when showBadge is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo(
            height: 24,
            showBadge: true,
          ),
        ),
      ),
    );

    await tester.runAsync(() => GoogleFonts.pendingFonts());
    await tester.pumpAndSettle();

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('PARTNERS'), findsOneWidget);
  });

  testWidgets('AppLogo.mark renders styled container', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppLogo.mark(size: 36),
        ),
      ),
    );

    expect(find.byType(AppLogo), findsOneWidget);
  });
}
