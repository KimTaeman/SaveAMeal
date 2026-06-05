import 'package:flutter_test/flutter_test.dart';
import 'package:saveameal/shared/utils/batch_id_formatter.dart';

void main() {
  group('formatBatchId', () {
    test('canonical UUID produces #XXXXXXXX (8 chars, no dashes, uppercase)', () {
      const uuid = '3f2c1a7b-e5d4-4c8b-9f1a-2b3c4d5e6f7a';
      expect(formatBatchId(uuid), '#3F2C1A7B');
    });

    test('dashes are stripped before taking 8 chars', () {
      // Without stripping, 'abcd-efgh' first 8 chars would include the dash.
      const id = 'abcd-efgh-ijkl';
      expect(formatBatchId(id), '#ABCDEFGH');
    });

    test('mixed-case input is uppercased', () {
      expect(formatBatchId('aAbBcCdDeEfFgG'), '#AABBCCDD');
    });

    test('short input (< 8 chars after dash removal) returns all chars', () {
      expect(formatBatchId('abc4092'), '#ABC4092'); // 7 chars
      expect(formatBatchId('abc'), '#ABC'); // 3 chars
    });

    test('empty string returns bare #', () {
      expect(formatBatchId(''), '#');
    });

    test('input already without dashes and exactly 8 chars', () {
      expect(formatBatchId('ABCD1234'), '#ABCD1234');
    });

    test('input longer than 8 chars is truncated to 8', () {
      expect(formatBatchId('aabbccddee'), '#AABBCCDD');
    });

    test('result always starts with #', () {
      expect(formatBatchId('any-id').startsWith('#'), isTrue);
    });
  });
}
