import 'package:expense/screens/chat/components/type_selector_coach_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'PulsingHighlight with active=false mounts and disposes cleanly',
    (tester) async {
      // Regression: the controller used to be created lazily on first
      // access, which (when never active) happened inside dispose() and
      // crashed with "Looking up a deactivated widget's ancestor is unsafe".
      await tester.pumpWidget(
        const MaterialApp(
          home: PulsingHighlight(
            active: false,
            color: Colors.blue,
            child: Icon(Icons.add),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Unmount — must not throw during dispose.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PulsingHighlight with active=true pulses and disposes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PulsingHighlight(
          active: true,
          color: Colors.blue,
          child: Icon(Icons.add),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PulsingHighlight toggling active starts and stops the pulse', (
    tester,
  ) async {
    Widget build(bool active) => MaterialApp(
      home: PulsingHighlight(
        active: active,
        color: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );

    await tester.pumpWidget(build(false));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(build(false));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
