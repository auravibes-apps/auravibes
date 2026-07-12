import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('accepts public HTTP syntax only when HTTPS is not required', () {
    expect(
      requirePublicUriSyntax(
        'http://example.com/path',
        requireHttps: false,
      ).host,
      'example.com',
    );
    expect(
      () => requirePublicUriSyntax(
        'http://example.com/path',
        requireHttps: true,
      ),
      throwsFormatException,
    );
    expect(
      () => requirePublicUriSyntax('ftp://example.com', requireHttps: false),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          publicHttpUrlError,
        ),
      ),
    );
  });

  test('rejects credentials and localhost labels', () {
    for (final url in [
      'https://user:pass@example.com',
      'https://localhost',
      'https://api.localhost',
    ]) {
      expect(
        () => requirePublicUriSyntax(url, requireHttps: true),
        throwsFormatException,
      );
    }
  });

  test('classifies locked private and documentation IPv4 ranges', () {
    for (final address in [
      [10, 0, 0, 1],
      [100, 64, 0, 1],
      [172, 16, 0, 1],
      [192, 0, 2, 1],
      [198, 18, 0, 1],
      [198, 51, 100, 1],
      [203, 0, 113, 1],
      [224, 0, 0, 1],
    ]) {
      expect(isPrivateIpAddress(address, isIpv6: false), isTrue);
    }
    expect(isPrivateIpAddress([8, 8, 8, 8], isIpv6: false), isFalse);
  });

  test('classifies private, loopback, and mapped IPv6 addresses', () {
    expect(
      isPrivateIpAddress([...List.filled(15, 0), 1], isIpv6: true),
      isTrue,
    );
    expect(
      isPrivateIpAddress([0xfc, ...List.filled(15, 0)], isIpv6: true),
      isTrue,
    );
    expect(
      isPrivateIpAddress(
        [...List.filled(10, 0), 0xff, 0xff, 127, 0, 0, 1],
        isIpv6: true,
      ),
      isTrue,
    );
    expect(
      isPrivateIpAddress(
        [0x20, 1, 0x48, 0x60, ...List.filled(12, 0)],
        isIpv6: true,
      ),
      isFalse,
    );
  });
}
