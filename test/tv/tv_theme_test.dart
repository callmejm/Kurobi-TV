import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/tv/tv_theme.dart';

void main() {
  test('buildTvTheme is dark', () {
    expect(buildTvTheme().brightness, Brightness.dark);
  });

  testWidgets('TvTextScale scales text by 1.3', (tester) async {
    late double scaled;
    await tester.pumpWidget(
      MaterialApp(
        home: TvTextScale(
          child: Builder(
            builder: (context) {
              scaled = MediaQuery.textScalerOf(context).scale(10);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(scaled, closeTo(13, 0.001));
  });
}
