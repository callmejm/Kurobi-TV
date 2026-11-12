// Bangumi mirror API credentials for the search signature flow.
// Release/PR CI injects them via --dart-define=KAZUMI_APPID / KAZUMI_KEY.
const Map<String, String> bangumiMirrorCredentials = {
  'id': String.fromEnvironment('KAZUMI_APPID'),
  'value': String.fromEnvironment('KAZUMI_KEY'),
};

/// Builds without the keys get 401 from the mirror's signed endpoints, so
/// those requests go to the official API instead.
bool get hasBangumiMirrorCredentials =>
    bangumiMirrorCredentials['id']!.isNotEmpty;

/// Whether the mirror requires a signature for this request path.
bool isSignedMirrorRequest(String method, String path) {
  if (method == 'POST' && path == '/v0/search/subjects') {
    return true;
  }
  if (method != 'GET') {
    return false;
  }
  return path.startsWith('/p1/subjects/') && path.endsWith('/comments') ||
      path.startsWith('/p1/episodes/') && path.endsWith('/comments') ||
      path.startsWith('/p1/characters/') && path.endsWith('/comments');
}
