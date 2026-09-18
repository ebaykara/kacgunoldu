import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Adds the bundled fonts to the licence page (Ayarlar → Açık kaynak
/// lisansları). Both are under the SIL Open Font License 1.1, which requires
/// the notice to travel with the font. The full licence text is in
/// assets/fonts/OFL.txt.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(
      ['Instrument Serif'],
      'Copyright 2022 The Instrument Serif Project Authors '
      '(https://github.com/Instrument/instrument-serif)\n\n$ofl',
    );
    yield LicenseEntryWithLineBreaks(
      ['Archivo'],
      'Copyright 2020 The Archivo Project Authors '
      '(https://github.com/Omnibus-Type/Archivo)\n\n$ofl',
    );
  });
}
