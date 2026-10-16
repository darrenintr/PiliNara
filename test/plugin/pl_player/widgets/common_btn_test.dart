import 'package:PiliPlus/plugin/pl_player/widgets/common_btn.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('expressive player button keeps primary and secondary actions', (
    tester,
  ) async {
    var taps = 0;
    var secondaryTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ComBtn(
              expressive: true,
              icon: const Icon(Icons.fullscreen),
              onTap: () => taps++,
              onSecondaryTap: () => secondaryTaps++,
            ),
          ),
        ),
      ),
    );

    final button = find.byType(ComBtn);
    await tester.tap(button);
    await tester.tap(
      button,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );

    expect(taps, 1);
    expect(secondaryTaps, 1);
    expect(tester.takeException(), isNull);
  });
}
