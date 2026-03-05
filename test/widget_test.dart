import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:himatalk_clone/main.dart';

void main() {
  testWidgets('App loads and shows timeline', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: HimaTalkApp()),
    );

    // Verify that the timeline tab is shown
    expect(find.text('Timeline'), findsWidgets);
  });
}
