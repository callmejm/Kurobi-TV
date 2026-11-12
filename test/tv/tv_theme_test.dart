import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/tv_theme.dart';

void main() {
  test('buildTvTheme is dark on the TV background', () {
    final theme = buildTvTheme();
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, TvTokens.background);
  });

  test('type scale has explicit sizes for the 960x540 canvas', () {
    final text = buildTvTheme().textTheme;
    expect(text.displaySmall!.fontSize, 34);
    expect(text.bodyMedium!.fontSize, 13);
  });
}
