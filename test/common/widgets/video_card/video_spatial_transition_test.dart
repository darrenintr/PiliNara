import 'package:PiliPlus/common/widgets/fullscreen_player_transition.dart';
import 'package:PiliPlus/common/widgets/video_card/video_hero.dart';
import 'package:PiliPlus/router/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoSpatialTransition plan', () {
    test('media and info tags share a source token', () {
      final mediaTag = VideoSpatialTransition.tagForVideo(
        'BV1same',
        sourceId: 7,
      );

      expect(mediaTag, 'video-hero-BV1same-source-7');
      expect(
        VideoSpatialTransition.infoTagForMediaTag(mediaTag),
        'video-hero-BV1same-source-7-info',
      );
      expect(
        VideoSpatialTransition.containerTagForMediaTag(mediaTag),
        'video-hero-BV1same-source-7-container',
      );
      expect(
        VideoSpatialTransition.tagForVideo('BV1same', sourceId: 8),
        isNot(mediaTag),
      );
      expect(VideoSpatialTransition.infoTagForMediaTag(null), isNull);
      final destinationInfo = VideoSpatialTransition.destinationInfo(
        tag: VideoSpatialTransition.infoTagForMediaTag(mediaTag),
        child: const SizedBox.shrink(),
      );
      expect((destinationInfo as VideoHero).tag, '$mediaTag-info');
      expect(
        VideoSpatialTransition.hasSourceTag({
          'videoHeroTag': mediaTag,
        }),
        isTrue,
      );
      expect(VideoSpatialTransition.hasSourceTag(const {}), isFalse);
    });

    test('secondary content waits for both primary containers', () {
      expect(VideoSpatialTransition.secondaryProgress(0), 0);
      expect(VideoSpatialTransition.secondaryProgress(0.79), 0);
      expect(VideoSpatialTransition.secondaryProgress(0.8), 0);
      expect(VideoSpatialTransition.secondaryProgress(0.86), greaterThan(0));
      expect(VideoSpatialTransition.secondaryProgress(1), 1);
    });

    test('secondary content reverses before the primary containers', () {
      expect(VideoSpatialTransition.secondaryProgress(1), 1);
      expect(VideoSpatialTransition.secondaryProgress(0.86), greaterThan(0));
      expect(VideoSpatialTransition.secondaryProgress(0.8), 0);
      expect(VideoSpatialTransition.secondaryProgress(0.5), 0);
    });

    test('destination backdrop follows primary geometry, not page opacity', () {
      expect(VideoSpatialTransition.destinationBackdropProgress(0), 0);
      expect(
        VideoSpatialTransition.destinationBackdropProgress(0.7),
        inExclusiveRange(0, 1),
      );
      expect(VideoSpatialTransition.destinationBackdropProgress(1), 1);
    });

    test('destination backdrop follows forward Hero progress on pop', () {
      for (final flightProgress in <double>[0, 0.25, 0.5, 0.75, 1]) {
        final routeProgress = 1 - flightProgress;
        expect(
          1 - VideoSpatialTransition.destinationBackdropProgress(
            routeProgress,
            reversing: true,
          ),
          closeTo(
            VideoSpatialTransition.geometryProgress(flightProgress),
            0.000001,
          ),
        );
      }
    });

    test('related video items use a bounded stagger after primary content', () {
      expect(VideoSpatialTransition.secondaryItemProgress(0.79, 0), 0);
      expect(
        VideoSpatialTransition.secondaryItemProgress(0.9, 0),
        greaterThan(VideoSpatialTransition.secondaryItemProgress(0.9, 3)),
      );
      expect(VideoSpatialTransition.secondaryItemProgress(1, 0), 1);
      expect(VideoSpatialTransition.secondaryItemProgress(1, 5), 1);
      expect(
        VideoSpatialTransition.secondaryItemProgress(0.9, 20),
        VideoSpatialTransition.secondaryItemProgress(0.9, 5),
      );
    });

    test('destination surface has a local fallback without a source', () {
      expect(
        VideoSpatialTransition.destinationSurfaceOpacity(
          routeProgress: 0,
          reversing: false,
          hasVisibleSource: false,
        ),
        1,
      );
      expect(
        VideoSpatialTransition.destinationSurfaceOpacity(
          routeProgress: 0.99,
          reversing: true,
          hasVisibleSource: true,
        ),
        0,
      );
      expect(
        VideoSpatialTransition.destinationSurfaceOpacity(
          routeProgress: 0,
          reversing: true,
          hasVisibleSource: false,
        ),
        1,
      );
      expect(
        VideoSpatialTransition.destinationSurfaceOpacity(
          routeProgress: 0,
          reversing: false,
          hasVisibleSource: true,
        ),
        0,
      );
      expect(
        VideoSpatialTransition.destinationSurfaceOpacity(
          routeProgress: 0.86,
          reversing: false,
          hasVisibleSource: true,
        ),
        0,
      );
      expect(
        VideoSpatialTransition.destinationSurfaceOpacity(
          routeProgress: 1,
          reversing: false,
          hasVisibleSource: true,
        ),
        1,
      );
    });

    test(
      'route scope carries the real route animation without page effects',
      () {
        final route = PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SizedBox.shrink(),
        );
        const child = SizedBox.shrink();
        final scoped = VideoSpatialTransition.routeTransition(
          route: route,
          animation: kAlwaysCompleteAnimation,
          child: child,
        );

        expect(scoped, isA<VideoSpatialRouteScope>());
        expect((scoped as VideoSpatialRouteScope).child, same(child));
      },
    );

    test('registry rejects unavailable or invalid source bounds', () {
      VideoSpatialTransitionRegistry.update(
        tag: 'source-test',
        videoId: 'BV1',
        rect: const Rect.fromLTWH(0, 0, 100, 60),
      );
      expect(
        VideoSpatialTransitionRegistry.lookup('source-test')?.isUsable,
        isTrue,
      );
      VideoSpatialTransitionRegistry.markUnavailable('source-test');
      expect(
        VideoSpatialTransitionRegistry.lookup('source-test')?.isUsable,
        isFalse,
      );
      VideoSpatialTransitionRegistry.update(
        tag: 'invalid-test',
        videoId: 'BV1',
        rect: Rect.zero,
      );
      expect(
        VideoSpatialTransitionRegistry.lookup('invalid-test')?.isUsable,
        isFalse,
      );
      VideoSpatialTransitionRegistry.remove('source-test');
      VideoSpatialTransitionRegistry.remove('invalid-test');
    });
  });

  testWidgets('player surface animates into and out of fullscreen bounds', (
    tester,
  ) async {
    final fullscreen = ValueNotifier(false);
    final playerKey = GlobalKey();
    final transitionKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder(
          valueListenable: fullscreen,
          builder: (context, isFullscreen, _) => Stack(
            children: [
              Positioned(
                left: isFullscreen ? 0 : 20,
                top: isFullscreen ? 0 : 30,
                width: isFullscreen ? 300 : 100,
                height: isFullscreen ? 200 : 50,
                child: FullscreenPlayerTransition(
                  key: transitionKey,
                  isFullscreen: isFullscreen,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.linear,
                  child: ColoredBox(key: playerKey, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getRect(find.byKey(playerKey)),
      const Rect.fromLTWH(20, 30, 100, 50),
    );

    fullscreen.value = true;
    await tester.pump();
    expect(
      tester.getRect(find.byKey(playerKey)),
      const Rect.fromLTWH(20, 30, 100, 50),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(
      tester.getRect(find.byKey(playerKey)),
      const Rect.fromLTWH(10, 15, 200, 125),
    );

    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(playerKey)),
      const Rect.fromLTWH(0, 0, 300, 200),
    );

    fullscreen.value = false;
    await tester.pump();
    expect(
      tester.getRect(find.byKey(playerKey)),
      const Rect.fromLTWH(0, 0, 300, 200),
    );

    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(playerKey)),
      const Rect.fromLTWH(20, 30, 100, 50),
    );
  });

  test('the real /videoV named route creates the spatial route', () {
    final route = Routes.onGenerateRoute(
      const RouteSettings(
        name: '/videoV',
        arguments: {'videoHeroTag': 'video-hero-BV1-source-1'},
      ),
    );
    final routePage = route as PageRoute<dynamic>;

    expect(routePage.transitionDuration, VideoSpatialTransition.duration);
    expect(
      routePage.reverseTransitionDuration,
      VideoSpatialTransition.duration,
    );

    expect(route.runtimeType.toString(), startsWith('_VideoDetailPageRoute'));
    expect(route.settings.arguments, {
      'videoHeroTag': 'video-hero-BV1-source-1',
    });
  });
}
