import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthodox_chant/app.dart';

void main() {
  testWidgets('app launches without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App(skipOnboarding: true)));
    await tester.pump();
    expect(find.byType(App), findsOneWidget);
  });
}
