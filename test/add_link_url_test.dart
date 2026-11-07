import 'package:flutter_test/flutter_test.dart';
import 'package:obtainium/app_sources/github.dart';
import 'package:obtainium/pages/home.dart';
import 'package:obtainium/providers/source_provider.dart';

// What ShizuStore's "Add to Obtainium" button sends:
// "obtainium://add/" + URLEncoder.encode(url, "UTF-8").
const String _encodedLink =
    'obtainium://add/https%3A%2F%2Fgithub.com%2Faistra0528%2FHail';
const String _url = 'https://github.com/aistra0528/Hail';

/// The URL that `interpretLink` takes from an `add` [link], which `AppLinks`
/// hands over parsed.
String _urlIn(String link) => addLinkUrl(Uri.parse(link));

void main() {
  test('an encoded URL is decoded', () {
    expect(_urlIn(_encodedLink), _url);
  });

  test('a decoded URL finds the source it belongs to', () {
    final String url = _urlIn(_encodedLink);
    final AppSource source = SourceProvider().getSource(url);

    expect(source, isA<GitHub>());
    expect(source.standardizeUrl(url), _url);
  });

  test('what an encoded URL holds comes through whole', () {
    expect(
      _urlIn('obtainium://add/https%3A%2F%2Fa.b%2Fc%3Fd%3D1%26e%3D2%23f'),
      'https://a.b/c?d=1&e=2#f',
    );
    expect(
      _urlIn('obtainium://add/https%3A%2F%2Fa.b%2F%E6%97%A5%E6%9C%AC'),
      'https://a.b/日本',
    );
  });

  test('a URL sent as it is stays as it is', () {
    expect(_urlIn('obtainium://add/$_url'), _url);
  });

  test('a link with no URL gives nothing', () {
    expect(_urlIn('obtainium://add'), '');
    expect(_urlIn('obtainium://add/'), '');
  });

  test('a url query parameter is read, ahead of the path', () {
    expect(
      _urlIn('obtainium://add?url=https%3A%2F%2Fgithub.com%2Fa%2Fb'),
      'https://github.com/a/b',
    );
    expect(
      _urlIn('obtainium://add/?url=https://github.com/a/b'),
      'https://github.com/a/b',
    );
    expect(
      _urlIn('obtainium://add/https%3A%2F%2Fa.b%2Fc?url=https://d.e/f'),
      'https://d.e/f',
    );
    // Any other query is not the URL. A sender that encodes keeps its URL's
    // query inside the path.
    expect(_urlIn('obtainium://add/https://a.b/c?d=e'), 'https://a.b/c');
  });

  test('a URL is decoded once, so what it encodes itself stays encoded', () {
    expect(
      _urlIn('obtainium://add/https%253A%252F%252Fgithub.com%252Fa%252Fb'),
      'https%3A%2F%2Fgithub.com%2Fa%2Fb',
    );
    expect(
      _urlIn('obtainium://add/https%3A%2F%2Fa.b%2Fc%252Fd'),
      'https://a.b/c%2Fd',
    );
  });

  test('a plus in the path is a plus, encoded or not', () {
    expect(
      _urlIn('obtainium://add/https%3A%2F%2Fa.b%2Fc%2Bd'),
      'https://a.b/c+d',
    );
    expect(_urlIn('obtainium://add/https://a.b/c+d'), 'https://a.b/c+d');
  });

  test('a percent sign that starts no escape is a percent sign', () {
    // Uri.parse reads these as an encoded percent sign.
    expect(_urlIn('obtainium://add/https://a.b/%ZZ'), 'https://a.b/%ZZ');
    expect(_urlIn('obtainium://add/https://a.b/c%'), 'https://a.b/c%');
  });

  test('escapes that are not UTF-8 are left as sent, without throwing', () {
    expect(_urlIn('obtainium://add/https://a.b/caf%E9'), 'https://a.b/caf%E9');
    expect(_urlIn('obtainium://add/%FF'), '%FF');
    expect(_urlIn('obtainium://add/%C3%28'), '%C3%28');
    expect(_urlIn('obtainium://add/https://a.b/c?d=%FF'), 'https://a.b/c');
    // Nothing to fall back on, so handleAddUrl reports an unsupported URL.
    expect(_urlIn('obtainium://add?url=%FF'), '');
  });

  test('app links are still decoded once, by linkJson', () {
    expect(
      linkJson(Uri.parse('obtainium://app/%7B%22a%22%3A%22%2525%22%7D')),
      '{"a":"%25"}',
    );
  });
}
