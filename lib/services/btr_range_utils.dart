/// BTR 媒体地址与 HTTP Range 的纯逻辑工具；保持无 Flutter 依赖以便单元测试。
abstract final class BtrRangeUtils {
  /// 与原 BTR 类似的节点池。原始/用户选择的 CDN 永远排第一，其余节点用于
  /// 分摊后续分片；失败与速度统计会随会话动态影响选择。
  static const List<String> accelerationHosts = [
    'upos-sz-mirrorcosov.bilivideo.com',
    'upos-sz-mirroraliov.bilivideo.com',
    'upos-sz-mirrorhwov.bilivideo.com',
    'upos-hz-mirrorakam.akamaized.net',
    'cn-hk-eq-bcache-01.bilivideo.com',
    'upos-sz-mirrorcos.bilivideo.com',
    'upos-sz-mirrorali.bilivideo.com',
    'upos-sz-mirrorhw.bilivideo.com',
    'upos-sz-mirrorcoso1.bilivideo.com',
    'upos-sz-mirroralio1.bilivideo.com',
    'upos-sz-mirrorhwo1.bilivideo.com',
    'upos-sz-mirror08c.bilivideo.com',
  ];

  static const _mediaHostSuffixes = [
    '.bilivideo.com',
    '.bilivideo.cn',
    '.bilivideo.net',
    '.acgvideo.com',
    '.akamaized.net',
  ];

  static bool isBilibiliMediaUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return false;
    }
    final host = uri.host.toLowerCase();
    return _mediaHostSuffixes.any(host.endsWith) ||
        host == 'edge.mountaintoys.cn';
  }

  static bool _isRelayUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host.contains('.mcdn.') ||
        host == 'proxy-tf-all-ws.bilivideo.com' ||
        uri.path.startsWith('/v1/resource/') ||
        uri.queryParameters['os']?.toLowerCase() == 'mcdn' ||
        uri.queryParameters.containsKey('url');
  }

  /// 生成可并行使用的 CDN 地址。mcdn/边缘缓存地址带有自己的路径与签名，
  /// 不能移植到普通 upos 节点，此时只保留原地址并行分片。
  static List<Uri> buildCandidateUrls(
    String rawUrl, {
    Iterable<String> hosts = accelerationHosts,
  }) {
    final source = Uri.tryParse(rawUrl);
    if (source == null || !isBilibiliMediaUrl(rawUrl)) {
      return const [];
    }
    final result = <Uri>[source];
    if (_isRelayUrl(source)) {
      return result;
    }
    final sourceHost = source.host.toLowerCase();
    for (final host in hosts) {
      final normalized = host.trim().toLowerCase();
      if (normalized.isEmpty || normalized == sourceHost) {
        continue;
      }
      final candidate = source.replace(host: normalized);
      if (!result.any((item) => item.host == candidate.host)) {
        result.add(candidate);
      }
    }
    return result;
  }
}

final class BtrByteRange {
  const BtrByteRange(this.start, this.end);

  final int start;
  final int? end;

  static BtrByteRange? parse(String? value) {
    if (value == null || value.isEmpty) {
      return const BtrByteRange(0, null);
    }
    final match = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    final start = int.tryParse(match.group(1)!);
    if (start == null) {
      return null;
    }
    final endText = match.group(2)!;
    final end = endText.isEmpty ? null : int.tryParse(endText);
    if (endText.isNotEmpty && end == null) {
      return null;
    }
    if (end != null && end < start) {
      return null;
    }
    return BtrByteRange(start, end);
  }
}
