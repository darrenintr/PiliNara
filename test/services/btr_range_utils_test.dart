import 'package:PiliPlus/services/btr_range_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BtrByteRange.parse', () {
    test('parses open-ended and closed ranges', () {
      expect(BtrByteRange.parse(null)?.start, 0);
      expect(BtrByteRange.parse(null)?.end, isNull);
      expect(BtrByteRange.parse('bytes=128-')?.start, 128);
      expect(BtrByteRange.parse('bytes=128-')?.end, isNull);
      expect(BtrByteRange.parse('bytes=128-255')?.end, 255);
    });

    test('rejects malformed and inverted ranges', () {
      expect(BtrByteRange.parse('bytes=255-128'), isNull);
      expect(BtrByteRange.parse('bytes=-128'), isNull);
      expect(BtrByteRange.parse('items=0-1'), isNull);
      expect(BtrByteRange.parse('bytes=0-1,4-5'), isNull);
    });
  });

  group('BtrRangeUtils.buildCandidateUrls', () {
    const source =
        'https://upos-sz-mirrorcos.bilivideo.com/upgcxcode/1/2/video.m4s?deadline=123&uipk=5';

    test('keeps the signed original first and mirrors path/query', () {
      final candidates = BtrRangeUtils.buildCandidateUrls(
        source,
        hosts: const [
          'upos-sz-mirrorali.bilivideo.com',
          'upos-sz-mirrorhw.bilivideo.com',
        ],
      );

      expect(candidates, hasLength(3));
      expect(candidates.first.toString(), source);
      expect(candidates[1].host, 'upos-sz-mirrorali.bilivideo.com');
      expect(candidates[1].path, '/upgcxcode/1/2/video.m4s');
      expect(candidates[1].query, 'deadline=123&uipk=5');
      expect(candidates[2].host, 'upos-sz-mirrorhw.bilivideo.com');
    });

    test('does not duplicate the source host', () {
      final candidates = BtrRangeUtils.buildCandidateUrls(
        source,
        hosts: const ['upos-sz-mirrorcos.bilivideo.com'],
      );
      expect(candidates, hasLength(1));
    });

    test('does not move relay URLs to ordinary CDN hosts', () {
      for (final url in [
        'https://cn-test.mcdn.bilivideo.com/v1/resource/video.m4s?os=mcdn',
        'https://proxy-tf-all-ws.bilivideo.com/?url=https%3A%2F%2Fcn-test.mcdn.bilivideo.com%2Fv1%2Fresource%2Fvideo.m4s',
      ]) {
        final candidates = BtrRangeUtils.buildCandidateUrls(
          url,
          hosts: const ['upos-sz-mirrorali.bilivideo.com'],
        );
        expect(candidates, hasLength(1));
      }
    });

    test('rejects non-bilibili hosts', () {
      expect(
        BtrRangeUtils.buildCandidateUrls('https://example.com/video.m4s'),
        isEmpty,
      );
      expect(BtrRangeUtils.isBilibiliMediaUrl('https://example.com'), isFalse);
      expect(
        BtrRangeUtils.isBilibiliMediaUrl(
          'https://upos-sz-mirrorali.bilivideo.com/x.m4s',
        ),
        isTrue,
      );
    });
  });
}
