import 'package:flutter/foundation.dart';

/// Opt in through the dev launch configuration; never available in release.
const devToolsEnabled = kDebugMode && bool.fromEnvironment('DEV_TOOLS');
