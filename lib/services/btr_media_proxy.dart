import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/plugin/pl_player/models/data_source.dart';
import 'package:PiliPlus/services/btr_range_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Bilibili Thread Ripper 风格的本地媒体代理。
///
/// 播放器仍按普通 HTTP 流读取，但 loopback 代理会把读取窗口拆成固定大小
/// 的 Range 分片，并行分配到多个 bilivideo CDN 节点，再按原始字节顺序交给
/// mpv。仅监听 127.0.0.1，且只接受 bilibili 媒体域名，避免成为开放代理。
final class BtrMediaProxy {
  BtrMediaProxy._({
    this._enabledOverride,
    this._threadCountOverride,
    this._allowAnyHost = false,
  });

  static final BtrMediaProxy instance = BtrMediaProxy._();

  @visibleForTesting
  factory BtrMediaProxy.testing({int threadCount = 4}) => BtrMediaProxy._(
    enabledOverride: true,
    threadCountOverride: threadCount,
    allowAnyHost: true,
  );

  final bool? _enabledOverride;
  final int? _threadCountOverride;
  final bool _allowAnyHost;

  static const int _chunkSize = 256 * 1024;
  static const int _maxChunkAttempts = 4;
  static const Duration _connectTimeout = Duration(seconds: 6);
  static const Duration _receiveTimeout = Duration(seconds: 10);
  static const Duration _attemptTimeout = Duration(seconds: 12);

  HttpServer? _server;
  Future<void>? _starting;
  final Map<String, _BtrHostStats> _hostStats = {};

  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _connectTimeout,
      followRedirects: false,
      validateStatus: (_) => true,
      headers: {
        'user-agent': BrowserUa.pc,
        'referer': HttpString.baseUrl,
        'accept': '*/*',
      },
    ),
  );

  bool _isAllowedMediaUrl(String rawUrl) =>
      _allowAnyHost || BtrRangeUtils.isBilibiliMediaUrl(rawUrl);

  bool canAccelerate(
    String rawUrl, {
    required bool isAudio,
    required bool enabled,
    required bool audioEnabled,
  }) {
    if (!(_enabledOverride ?? enabled)) {
      return false;
    }
    if (isAudio && !(_enabledOverride ?? audioEnabled)) {
      return false;
    }
    return _isAllowedMediaUrl(rawUrl);
  }

  Future<String> wrapUrl(
    String rawUrl, {
    required bool isAudio,
    bool enabled = false,
    bool audioEnabled = true,
    int threadCount = 8,
  }) async {
    if (!canAccelerate(
      rawUrl,
      isAudio: isAudio,
      enabled: enabled,
      audioEnabled: audioEnabled,
    )) {
      return rawUrl;
    }
    try {
      await ensureStarted();
      final server = _server;
      if (server == null) {
        return rawUrl;
      }
      final kind = isAudio ? 'audio' : 'video';
      final threads = threadCount.clamp(1, 64);
      return 'http://127.0.0.1:${server.port}/media'
          '?kind=$kind&threads=$threads&src=${Uri.encodeComponent(rawUrl)}';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BTR] proxy start failed: $e');
      }
      return rawUrl;
    }
  }

  Future<NetworkSource> wrapSource(
    NetworkSource source, {
    bool enabled = false,
    bool audioEnabled = true,
    int threadCount = 8,
  }) async {
    final video = await wrapUrl(
      source.videoSource,
      isAudio: false,
      enabled: enabled,
      audioEnabled: audioEnabled,
      threadCount: threadCount,
    );
    final audio = switch (source.audioSource) {
      final audio? when audio.isNotEmpty => await wrapUrl(
        audio,
        isAudio: true,
        enabled: enabled,
        audioEnabled: audioEnabled,
        threadCount: threadCount,
      ),
      _ => source.audioSource,
    };
    if (video == source.videoSource && audio == source.audioSource) {
      return source;
    }
    return NetworkSource(videoSource: video, audioSource: audio);
  }

  Future<void> ensureStarted() {
    if (_server != null) {
      return Future.value();
    }
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  @visibleForTesting
  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    _dio.close(force: true);
  }

  Future<void> _start() async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
    server.autoCompress = false;
    _server = server;
    server.listen(
      _handleRequest,
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('[BTR] server error: $e');
        }
      },
    );
    if (kDebugMode) {
      debugPrint('[BTR] media proxy listening on 127.0.0.1:${server.port}');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    try {
      if (request.uri.path != '/media') {
        response.statusCode = HttpStatus.notFound;
        await response.close();
        return;
      }
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        await response.close();
        return;
      }
      final rawSource = request.uri.queryParameters['src'];
      if (rawSource == null || !_isAllowedMediaUrl(rawSource)) {
        response.statusCode = HttpStatus.forbidden;
        await response.close();
        return;
      }
      var candidates = BtrRangeUtils.buildCandidateUrls(rawSource);
      if (candidates.isEmpty && _allowAnyHost) {
        candidates = [Uri.parse(rawSource)];
      }
      if (candidates.isEmpty) {
        response.statusCode = HttpStatus.badRequest;
        await response.close();
        return;
      }
      final session = _BtrDownloadSession(
        proxy: this,
        source: Uri.parse(rawSource),
        candidates: candidates,
        isAudio: request.uri.queryParameters['kind'] == 'audio',
        threadCount:
            _threadCountOverride ??
            math.min(
              64,
              math.max(
                1,
                int.tryParse(
                      request.uri.queryParameters['threads'] ?? '',
                    ) ??
                    8,
              ),
            ),
      );
      await session.serve(request);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BTR] request error: $e');
      }
      try {
        response.statusCode = HttpStatus.badGateway;
        await response.close();
      } catch (_) {}
    }
  }

  Uri _selectCandidate(
    List<Uri> candidates,
    int assignment,
    int attempt,
  ) {
    if (candidates.length == 1) {
      return candidates.first;
    }
    final ordered = List<Uri>.of(candidates)
      ..sort((a, b) {
        final scoreA = _hostStats[a.host]?.score ?? 0;
        final scoreB = _hostStats[b.host]?.score ?? 0;
        return scoreB.compareTo(scoreA);
      });
    // 节点尚无测速结果时保持轮转，先完成测速；之后也保留轮转偏移，让所有
    // 快节点都能分到分片，而不是把全部并发压到单一 host。
    final offset = (assignment + attempt) % ordered.length;
    return ordered[offset];
  }

  void _recordSuccess(Uri uri, int bytes, Duration elapsed) {
    final stats = _hostStats.putIfAbsent(uri.host, _BtrHostStats.new);
    final seconds = math.max(elapsed.inMicroseconds / 1000000, 0.001);
    stats.recordSuccess(bytes / seconds);
  }

  void _recordFailure(Uri uri) {
    _hostStats.putIfAbsent(uri.host, _BtrHostStats.new).recordFailure();
  }

  Future<_BtrChunkResult> _downloadSingleRange(
    Uri uri,
    int start,
    int end,
    _BtrAbortToken token,
  ) async {
    token.throwIfCancelled();
    final cancelToken = CancelToken();
    void cancel() => cancelToken.cancel('btr aborted');
    token.addListener(cancel);
    final watch = Stopwatch()..start();
    final timeout = Timer(_attemptTimeout, () {
      cancelToken.cancel('btr range timeout');
    });
    try {
      final response = await _dio.getUri<ResponseBody>(
        uri,
        options: Options(
          responseType: ResponseType.stream,
          headers: {'range': 'bytes=$start-$end'},
        ),
        cancelToken: cancelToken,
      );
      if (response.statusCode != HttpStatus.partialContent) {
        throw StateError('CDN 未返回 206：${response.statusCode}');
      }
      final contentRange = response.headers.value('content-range');
      final range = _BtrContentRange.parse(contentRange);
      if (range == null || range.start != start || range.end > end) {
        throw StateError('媒体 Content-Range 校验失败：$contentRange');
      }
      final expectedLength = range.end - range.start + 1;
      final builder = BytesBuilder(copy: false);
      var received = 0;
      final body = response.data;
      if (body == null) {
        throw StateError('CDN 响应缺少 body');
      }
      await for (final chunk in body.stream) {
        token.throwIfCancelled();
        builder.add(chunk);
        received += chunk.length;
        if (received > expectedLength) {
          throw StateError('媒体分片长度超出预期');
        }
      }
      token.throwIfCancelled();
      if (received != expectedLength) {
        throw StateError('媒体分片长度不符：$received/$expectedLength');
      }
      final bytes = builder.takeBytes();
      if (bytes.length != expectedLength) {
        throw StateError('媒体分片拼接失败');
      }
      return _BtrChunkResult(
        bytes: bytes,
        totalLength: range.total,
        contentType: response.headers.value('content-type'),
        elapsed: watch.elapsed,
      );
    } finally {
      timeout.cancel();
      token.removeListener(cancel);
      watch.stop();
    }
  }
}

final class _BtrContentRange {
  const _BtrContentRange({
    required this.start,
    required this.end,
    required this.total,
  });

  final int start;
  final int end;
  final int total;

  static _BtrContentRange? parse(String? value) {
    if (value == null) {
      return null;
    }
    final match = RegExp(
      r'^bytes\s+(\d+)-(\d+)/(\d+)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    final start = int.tryParse(match.group(1)!);
    final end = int.tryParse(match.group(2)!);
    final total = int.tryParse(match.group(3)!);
    if (start == null || end == null || total == null || end < start) {
      return null;
    }
    return _BtrContentRange(start: start, end: end, total: total);
  }
}

final class _BtrChunkResult {
  const _BtrChunkResult({
    required this.bytes,
    required this.totalLength,
    required this.contentType,
    required this.elapsed,
  });

  final Uint8List bytes;
  final int totalLength;
  final String? contentType;
  final Duration elapsed;
}

final class _BtrAbortException implements Exception {
  const _BtrAbortException();

  @override
  String toString() => 'BTR 下载已取消';
}

final class _BtrAbortToken {
  bool _cancelled = false;
  final List<VoidCallback> _listeners = [];

  bool get isCancelled => _cancelled;

  void addListener(VoidCallback listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void cancel() {
    if (_cancelled) {
      return;
    }
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
    _listeners.clear();
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const _BtrAbortException();
    }
  }
}

final class _BtrHostStats {
  double _bps = 0;
  int _successes = 0;
  int _failures = 0;

  double get score {
    if (_successes == 0) {
      return 0;
    }
    return _bps / (1 + _failures * 0.5);
  }

  void recordSuccess(double bps) {
    _successes++;
    _bps = _bps == 0 ? bps : _bps * 0.65 + bps * 0.35;
  }

  void recordFailure() {
    _failures++;
  }
}

final class _BtrSemaphore {
  _BtrSemaphore(this.limit);

  final int limit;
  int _active = 0;
  final List<Completer<void>> _queue = [];

  Future<T> run<T>(Future<T> Function() task) async {
    await _acquire();
    try {
      return await task();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() {
    if (_active < limit) {
      _active++;
      return Future.value();
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  void _release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
      return;
    }
    _active--;
  }
}

final class _BtrDownloadSession {
  _BtrDownloadSession({
    required this.proxy,
    required this.source,
    required this.candidates,
    required this.isAudio,
    required int threadCount,
  }) : semaphore = _BtrSemaphore(threadCount),
       lookaheadBytes = isAudio
           ? 8 * 1024 * 1024
           : math.min(
               48 * 1024 * 1024,
               math.max(16 * 1024 * 1024, threadCount * 2 * 1024 * 1024),
             );

  final BtrMediaProxy proxy;
  final Uri source;
  final List<Uri> candidates;
  final bool isAudio;
  final _BtrSemaphore semaphore;
  final int lookaheadBytes;

  final _BtrAbortToken _abortToken = _BtrAbortToken();
  final Map<int, Future<_BtrChunkResult>> _chunks = {};

  int _assignment = 0;
  int? _finalEnd;
  int? _requestedEnd;
  int _baseStart = 0;

  int get _threadCount => semaphore.limit;

  Future<void> serve(HttpRequest request) async {
    final response = request.response;
    var responseStarted = false;
    unawaited(
      response.done.whenComplete(_abortToken.cancel),
    );

    try {
      final requestedRange = BtrByteRange.parse(
        request.headers.value(HttpHeaders.rangeHeader),
      );
      if (requestedRange == null) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        await response.close();
        return;
      }
      _baseStart = requestedRange.start;
      _requestedEnd = requestedRange.end;
      // 首个分片不等待完成后才并发：先让前几片一起建立连接，
      // 否则海外高 RTT 下代理本身会把起播延迟放大。
      final startupChunks = math.min(_threadCount, 4);
      for (var index = 1; index < startupChunks; index++) {
        final start = _baseStart + index * BtrMediaProxy._chunkSize;
        if (_requestedEnd == null || start <= _requestedEnd!) {
          _chunk(index);
        }
      }
      final firstChunk = await _chunk(0);
      final totalLength = firstChunk.totalLength;
      if (_baseStart >= totalLength ||
          (requestedRange.end != null && requestedRange.end! < _baseStart)) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes */$totalLength',
        );
        await response.close();
        return;
      }

      final end = math.min(
        requestedRange.end ?? totalLength - 1,
        totalLength - 1,
      );
      _finalEnd = end;
      final contentLength = end - _baseStart + 1;
      final hasRange = request.headers.value(HttpHeaders.rangeHeader) != null;

      response
        ..statusCode = hasRange ? HttpStatus.partialContent : HttpStatus.ok
        ..contentLength = contentLength;
      response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      response.headers.set(
        HttpHeaders.contentTypeHeader,
        firstChunk.contentType ?? (isAudio ? 'audio/mp4' : 'video/mp4'),
      );
      if (hasRange) {
        response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $_baseStart-$end/$totalLength',
        );
      }
      responseStarted = true;

      if (request.method == 'HEAD') {
        await response.close();
        return;
      }

      var position = _baseStart;
      while (position <= end) {
        _abortToken.throwIfCancelled();
        _ensureWindow(position);
        final index = (position - _baseStart) ~/ BtrMediaProxy._chunkSize;
        final chunk = await _chunk(index);
        final chunkStart = _baseStart + index * BtrMediaProxy._chunkSize;
        final offset = position - chunkStart;
        final availableEnd = chunkStart + chunk.bytes.length - 1;
        final writeEnd = math.min(end, availableEnd);
        if (writeEnd < position || offset >= chunk.bytes.length) {
          throw StateError('BTR 分片顺序校验失败');
        }
        response.add(
          Uint8List.sublistView(
            chunk.bytes,
            offset,
            offset + writeEnd - position + 1,
          ),
        );
        await response.flush();
        position = writeEnd + 1;
        _chunks.remove(index);
      }
      await response.close();
    } catch (e) {
      if (e is! _BtrAbortException && kDebugMode) {
        debugPrint('[BTR] accelerated stream failed: $e');
      }
      if (!responseStarted) {
        // 首包前失败仍可无损降级：让 mpv 跟随重定向直接连接原 CDN。
        try {
          response.statusCode = HttpStatus.temporaryRedirect;
          response.headers.set(HttpHeaders.locationHeader, source.toString());
          await response.close();
        } catch (_) {}
      } else {
        try {
          await response.close();
        } catch (_) {}
      }
    } finally {
      _abortToken.cancel();
      _chunks.clear();
    }
  }

  void _ensureWindow(int position) {
    final end = _finalEnd;
    if (end == null) {
      return;
    }
    final firstIndex = (position - _baseStart) ~/ BtrMediaProxy._chunkSize;
    final windowEnd = math.min(end, position + lookaheadBytes);
    final lastIndex = (windowEnd - _baseStart) ~/ BtrMediaProxy._chunkSize;
    for (var index = firstIndex; index <= lastIndex; index++) {
      _chunk(index);
    }
  }

  Future<_BtrChunkResult> _chunk(int index) {
    return _chunks.putIfAbsent(index, () {
      final future = _downloadChunk(index);
      // 起播时乐观 prefetch 的最后几片可能越过 EOF；这些 future 若最终
      // 不会被消费，也不应变成未处理的异步错误。真正 await 时仍会拿到原错误。
      return future..ignore();
    });
  }

  Future<_BtrChunkResult> _downloadChunk(int index) {
    final start = _baseStart + index * BtrMediaProxy._chunkSize;
    var end = start + BtrMediaProxy._chunkSize - 1;
    final requestedEnd = _requestedEnd;
    if (requestedEnd != null) {
      end = math.min(end, requestedEnd);
    }
    final finalEnd = _finalEnd;
    if (finalEnd != null) {
      end = math.min(end, finalEnd);
    }
    return semaphore.run(
      () => _downloadChunkWithRetry(start, end),
    );
  }

  Future<_BtrChunkResult> _downloadChunkWithRetry(int start, int end) async {
    Object? lastError;
    final attempts = math.min(
      BtrMediaProxy._maxChunkAttempts,
      math.max(2, candidates.length),
    );
    for (var attempt = 0; attempt < attempts; attempt++) {
      _abortToken.throwIfCancelled();
      final assignment = _assignment++;
      final candidate = proxy._selectCandidate(
        candidates,
        assignment,
        attempt,
      );
      try {
        final result = await proxy._downloadSingleRange(
          candidate,
          start,
          end,
          _abortToken,
        );
        proxy._recordSuccess(
          candidate,
          result.bytes.length,
          result.elapsed,
        );
        return result;
      } catch (e) {
        if (e is _BtrAbortException) {
          rethrow;
        }
        proxy._recordFailure(candidate);
        lastError = e;
      }
    }
    throw lastError ?? StateError('BTR 分片下载失败');
  }
}
