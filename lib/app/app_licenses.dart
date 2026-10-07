import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _registered = false;

/// Package licenses are bundled by Flutter; manually bundled assets need entries.
void registerAppLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Kanit',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'dbus (source availability)',
    ], await rootBundle.loadString('assets/licenses/dbus-source.txt'));
  });
}
