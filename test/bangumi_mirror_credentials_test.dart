import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/utils/bangumi_mirror_credentials.dart';

void main() {
  test('only search and comments need a mirror signature', () {
    expect(isSignedMirrorRequest('POST', '/v0/search/subjects'), isTrue);
    expect(isSignedMirrorRequest('GET', '/p1/subjects/1/comments'), isTrue);
    expect(isSignedMirrorRequest('GET', '/v0/search/subjects'), isFalse);
    expect(isSignedMirrorRequest('GET', '/p1/subjects/1'), isFalse);
  });

  test('test builds carry no mirror keys', () {
    expect(hasBangumiMirrorCredentials, isFalse);
  });
}
