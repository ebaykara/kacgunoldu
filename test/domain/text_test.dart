import 'package:flutter_test/flutter_test.dart';
import 'package:kac_gun_oldu/domain/text.dart';

void main() {
  group('capitalizeTr', () {
    test('capitalizes plain letters', () {
      expect(capitalizeTr('çamaşır yıkadım'), 'Çamaşır yıkadım');
    });

    test('turns a leading "i" into dotted "İ", not ASCII "I"', () {
      // The whole reason this helper exists: Dart's toUpperCase is
      // locale-insensitive and would produce "Ilaç".
      expect(capitalizeTr('ilaç aldım'), 'İlaç aldım');
      expect('ilaç'.toUpperCase().startsWith('İ'), isFalse);
    });

    test('turns a leading dotless "ı" into the dotless capital "I"', () {
      expect(capitalizeTr('ışık yaktım'), 'Işık yaktım');
    });

    test('is a no-op on empty input', () {
      expect(capitalizeTr(''), '');
    });

    test('leaves the rest of the sentence untouched', () {
      expect(capitalizeTr('diş hekimine gittim'), 'Diş hekimine gittim');
    });
  });

  group('upperTr', () {
    test('uppercases with Turkish i/ı rules', () {
      expect(upperTr('ne zaman yaptın?'), 'NE ZAMAN YAPTIN?');
      expect(upperTr('ilaç'), 'İLAÇ');
    });

    test('handles the month abbreviations used by the timeline gutter', () {
      expect(upperTr('Eyl'), 'EYL');
      expect(upperTr('Şub'), 'ŞUB');
    });
  });
}
