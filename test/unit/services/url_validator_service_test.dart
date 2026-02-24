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

    test('validate rejects localhost hosts', () {
      final result = UrlValidatorService.validate('http://localhost:8080/file');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted network'));
    });

    test('validate rejects ipv6 loopback hosts', () {
      final result = UrlValidatorService.validate('http://[::1]:8080/file');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted network'));
    });

    test('validate rejects ipv6 unique-local hosts', () {
      final result = UrlValidatorService.validate('http://[fc00::1]/file');
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted network'));
    });

    test('validate rejects ipv4-mapped ipv6 private hosts', () {
      final result = UrlValidatorService.validate(
        'http://[::ffff:127.0.0.1]/file',
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('restricted network'));
    });

    test('validate allows public ip hosts', () {
      final result = UrlValidatorService.validate('https://8.8.8.8/resource');
      expect(result.isValid, isTrue);
      expect(result.isKnownSite, isFalse);
    });
  });
}
