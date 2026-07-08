enum UrlRequestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH'),
  head('HEAD');

  const UrlRequestMethod(this.value);
  final String value;
}
