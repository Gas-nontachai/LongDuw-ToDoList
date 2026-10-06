import 'dart:io';

import 'package:image/image.dart' as img;

/// Generate platform icons, then keep the web maskable artwork in its safe area.
Future<void> main() async {
  final xcodeProject = File('ios/Runner.xcodeproj/project.pbxproj');
  final symbolSetting = RegExp(
    r'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = [^;]+;',
  );
  final originalSymbolSettings = symbolSetting
      .allMatches(xcodeProject.readAsStringSync())
      .map((match) => match.group(0)!)
      .toList();
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    'flutter_launcher_icons',
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  // The generator also matches this unrelated Xcode flag. Preserve its values.
  var settingIndex = 0;
  final project = xcodeProject.readAsStringSync().replaceAllMapped(
    symbolSetting,
    (match) => originalSymbolSettings[settingIndex++],
  );
  xcodeProject.writeAsStringSync(project);
  if (result.exitCode != 0) {
    exitCode = result.exitCode;
    return;
  }

  final logo = img.decodePng(
    File('assets/icons/longduw_logo/longduw-logo-no-text.png')
        .readAsBytesSync(),
  )!;
  for (final size in [192, 512]) {
    // A centered square at 56% fits inside the maskable icon's safe circle
    // (radius 40%), including its corners.
    final artworkSize = (size * 0.56).round();
    final canvas = img.Image(width: size, height: size, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(252, 253, 254));
    final artwork = img.copyResize(
      logo,
      width: artworkSize,
      height: artworkSize,
      interpolation: img.Interpolation.average,
    );
    img.compositeImage(
      canvas,
      artwork,
      dstX: (size - artworkSize) ~/ 2,
      dstY: (size - artworkSize) ~/ 2,
    );
    File('web/icons/Icon-maskable-$size.png')
        .writeAsBytesSync(img.encodePng(canvas));
  }
  stdout.writeln('Web maskable icons padded for circular and rounded masks.');
}
