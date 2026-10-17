import 'package:PiliPlus/common/widgets/progress_bar/audio_video_progress_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('wavy progress bar still seeks from a drag', (tester) async {
    int? seekMilliseconds;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: ProgressBar(
                progress: 30,
                total: 120,
                buffered: 90,
                isWavy: true,
                baseBarColor: Colors.white24,
                progressBarColor: Colors.pink,
                bufferedBarColor: Colors.white54,
                thumbColor: Colors.white,
                thumbGlowColor: Colors.white24,
                thumbRadius: 5,
                thumbGlowRadius: 0,
                onDragStart: (_) {},
                onSeek: (milliseconds) => seekMilliseconds = milliseconds,
              ),
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(find.byType(ProgressBar));
    await tester.dragFrom(
      Offset(bar.left + 20, bar.center.dy),
      const Offset(120, 0),
    );

    expect(seekMilliseconds, isNotNull);
    expect(seekMilliseconds, inInclusiveRange(60000, 80000));
    expect(tester.takeException(), isNull);
  });
}
