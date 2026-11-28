import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:PiliPlus/services/btr_media_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'proxy serves ordered range bytes through parallel chunk requests',
    () async {
      const total = 900 * 1024;
      const requestStart = 1000;
      const requestEnd = total - 1;
      var active = 0;
      var maxActive = 0;
      var rangeRequests = 0;

      int byteAt(int index) => index % 251;

      final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final proxy = BtrMediaProxy.testing(threadCount: 4);
      final client = HttpClient();

      origin.listen((request) async {
        rangeRequests++;
        final match = RegExp(
          r'^bytes=(\d+)-(\d+)$',
        ).firstMatch(request.headers.value(HttpHeaders.rangeHeader) ?? '');
        if (match == null) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }
        final start = int.parse(match.group(1)!);
        final end = math.min(int.parse(match.group(2)!), total - 1);
        active++;
        maxActive = math.max(maxActive, active);
        try {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          final length = end - start + 1;
          final bytes = Uint8List(length);
          for (var i = 0; i < length; i++) {
            bytes[i] = byteAt(start + i);
          }
          request.response
            ..statusCode = HttpStatus.partialContent
            ..headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes $start-$end/$total',
            )
            ..headers.set(HttpHeaders.contentTypeHeader, 'video/mp4')
            ..contentLength = length
            ..add(bytes);
          await request.response.close();
        } finally {
          active--;
        }
      });

      try {
        final source = 'http://127.0.0.1:${origin.port}/video.m4s';
        final localUrl = await proxy.wrapUrl(source, isAudio: false);
        expect(localUrl, isNot(source));

        final request = await client.getUrl(Uri.parse(localUrl));
        request.headers.set(
          HttpHeaders.rangeHeader,
          'bytes=$requestStart-$requestEnd',
        );
        final response = await request.close();

        expect(response.statusCode, HttpStatus.partialContent);
        expect(
          response.headers.value(HttpHeaders.contentRangeHeader),
          'bytes $requestStart-$requestEnd/$total',
        );
        expect(response.contentLength, requestEnd - requestStart + 1);

        final builder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          builder.add(chunk);
        }
        final bytes = builder.takeBytes();
        expect(bytes, hasLength(requestEnd - requestStart + 1));
        for (final offset in [0, 4096, bytes.length ~/ 2, bytes.length - 1]) {
          expect(bytes[offset], byteAt(requestStart + offset));
        }
        expect(rangeRequests, greaterThan(1));
        expect(maxActive, greaterThan(1));
      } finally {
        client.close(force: true);
        await proxy.close();
        await origin.close(force: true);
      }
    },
  );

  test('proxy races the first chunk across candidates', () async {
    const total = 300 * 1024;
    const requestStart = 1000;
    const requestEnd = requestStart + 256 * 1024 - 1;

    int byteAt(int index) => index % 251;

    Future<HttpServer> createOrigin(int delayMs) async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final match = RegExp(
          r'^bytes=(\d+)-(\d+)$',
        ).firstMatch(request.headers.value(HttpHeaders.rangeHeader) ?? '');
        if (match == null) {
          request.response.statusCode = HttpStatus.badRequest;
          await request.response.close();
          return;
        }
        final start = int.parse(match.group(1)!);
        final end = math.min(int.parse(match.group(2)!), total - 1);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
        try {
          final length = end - start + 1;
          final bytes = Uint8List(length);
          for (var i = 0; i < length; i++) {
            bytes[i] = byteAt(start + i);
          }
          request.response
            ..statusCode = HttpStatus.partialContent
            ..headers.set(
              HttpHeaders.contentRangeHeader,
              'bytes $start-$end/$total',
            )
            ..headers.set(HttpHeaders.contentTypeHeader, 'video/mp4')
            ..contentLength = length
            ..add(bytes);
          await request.response.close();
        } catch (_) {}
      });
      return server;
    }

    final slowSource = await createOrigin(400);
    final fastMirror = await createOrigin(5);
    final slowMirror = await createOrigin(400);
    final client = HttpClient();
    final proxy = BtrMediaProxy.testing(
      threadCount: 4,
      candidatesOverride: (_) => [
        Uri.parse('http://127.0.0.1:${fastMirror.port}/video.m4s'),
        Uri.parse('http://127.0.0.1:${slowMirror.port}/video.m4s'),
      ],
    );

    try {
      final source = 'http://127.0.0.1:${slowSource.port}/video.m4s';
      final localUrl = await proxy.wrapUrl(source, isAudio: false);
      final watch = Stopwatch()..start();
      final request = await client.getUrl(Uri.parse(localUrl));
      request.headers.set(
        HttpHeaders.rangeHeader,
        'bytes=$requestStart-$requestEnd',
      );
      final response = await request.close();
      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      watch.stop();

      final bytes = builder.takeBytes();
      expect(response.statusCode, HttpStatus.partialContent);
      expect(bytes, hasLength(requestEnd - requestStart + 1));
      expect(bytes.first, byteAt(requestStart));
      expect(
        watch.elapsedMilliseconds,
        lessThan(300),
        reason: '首个分片应由最快候选节点胜出，而不是等待原始慢节点',
      );
    } finally {
      client.close(force: true);
      await proxy.close();
      await slowSource.close(force: true);
      await fastMirror.close(force: true);
      await slowMirror.close(force: true);
    }
  });
}
