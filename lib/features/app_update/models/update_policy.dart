import 'dart:convert';

import 'package:pub_semver/pub_semver.dart';

class UpdatePolicy {
  const UpdatePolicy._(this.latest, this.storeUrl);

  final Version latest;
  final Uri? storeUrl;

  bool hasUpdate(String installed) => _version(installed) < latest;

  static UpdatePolicy parse(String source, String platform) {
    final decoded = jsonDecode(source);
    if (decoded is! Map || decoded[platform] is! Map) {
      throw const FormatException('Missing platform update policy');
    }
    final values = decoded[platform] as Map;
    final latest = _version(values['latest_version']);
    final url = values['store_url'];
    if (url is! String) throw const FormatException('Missing store URL');
    Uri? uri;
    if (url.isNotEmpty) {
      uri = Uri.tryParse(url);
      final validHost = platform == 'android'
          ? uri?.host == 'play.google.com' &&
                uri?.path == '/store/apps/details' &&
                (uri?.queryParameters['id']?.isNotEmpty ?? false)
          : uri?.host == 'apps.apple.com' &&
                RegExp(r'/id\d+').hasMatch(uri?.path ?? '');
      if (uri == null ||
          uri.scheme != 'https' ||
          !validHost ||
          uri.userInfo.isNotEmpty ||
          uri.hasPort) {
        throw const FormatException('Invalid Store listing URL');
      }
    }
    return UpdatePolicy._(latest, uri);
  }

  static Version _version(Object? value) {
    if (value is! String ||
        !RegExp(
          r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$',
        ).hasMatch(value)) {
      throw const FormatException('Invalid semantic version');
    }
    final parsed = Version.parse(value);
    final prerelease = value.split('+').first.split('-').skip(1).join('-');
    if (prerelease.split('.').any((part) => RegExp(r'^0\d+$').hasMatch(part))) {
      throw const FormatException('Invalid numeric prerelease identifier');
    }
    // pub_semver orders build metadata; SemVer precedence must ignore it.
    return Version(
      parsed.major,
      parsed.minor,
      parsed.patch,
      pre: parsed.preRelease.isEmpty ? null : parsed.preRelease.join('.'),
    );
  }
}
