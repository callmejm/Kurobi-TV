import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/tv_nsfw.dart';

void main() {
  test('parseNsfwTags splits on either comma width and whitespace', () {
    expect(parseNsfwTags(' 肉番，卖肉, R18  里番,,'), {'肉番', '卖肉', 'R18', '里番'});
    expect(parseNsfwTags(''), isEmpty);
  });
}
