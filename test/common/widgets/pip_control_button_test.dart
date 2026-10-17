import 'package:PiliPlus/common/expressive/expressive_colors.dart';
import 'package:PiliPlus/common/widgets/pip_control_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('expressive mini-player action remains tappable', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PipControlButton(
              targetSize: 48,
              isPrimary: true,
              onTap: () => taps++,
              icon: const Icon(Icons.play_arrow),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PipControlButton));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(tester.getSize(find.byType(PipControlButton)), const Size(48, 48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary mini-player action uses expressive hover color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PipControlButton(
              targetSize: 48,
              isPrimary: true,
              onTap: () {},
              icon: const Icon(Icons.play_arrow),
            ),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byType(PipControlButton));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: center);
    await mouse.moveTo(center);
    await tester.pumpAndSettle();

    final surface = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    expect(
      (surface.decoration as ShapeDecoration).color,
      ExpressiveColors.dark.primary,
    );
    expect(tester.takeException(), isNull);
  });
}
