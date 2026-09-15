import 'package:PiliPlus/common/widgets/video_card/video_cover_hero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps one unique cover Hero tag per card model', () {
    final firstCard = Object();
    final secondCard = Object();

    final firstTag = VideoCoverHero.tagFor(firstCard);

    expect(VideoCoverHero.tagFor(firstCard), same(firstTag));
    expect(VideoCoverHero.tagFor(secondCard), isNot(equals(firstTag)));
  });
}
