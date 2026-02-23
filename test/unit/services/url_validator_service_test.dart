import 'package:flutter_test/flutter_test.dart';
import 'package:swiftsave/services/url_validator_service.dart';
import '../../fixtures/test_data.dart';

void main() {
  group('UrlValidatorService', () {
    test('validate returns valid for validVideoUrl', () {
      final result = UrlValidatorService.validate(TestData.validVideoUrl);
      expect(result.isValid, isTrue);
      expect(result.isKnownSite, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('validate returns invalid for invalidUrl', () {
      final result = UrlValidatorService.validate(TestData.invalidUrl);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('validate returns invalid for blockedIp (SSRF check)', () {
      final result = UrlValidatorService.validate(TestData.blockedIp);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted network'));
    });

    test('validate identifies known sites correctly', () {
      final result = UrlValidatorService.validate(TestData.validVideoUrl);
      expect(result.isKnownSite, isTrue);
    });

    test('validate allows unknown sites but marks them as unknown', () {
      final result = UrlValidatorService.validate(TestData.unknownSiteUrl);
      expect(result.isValid, isTrue);
      expect(result.isKnownSite, isFalse);
    });
  });
}
