import 'package:flutter/material.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';

/// Asks for a 4-digit passcode on an on-screen keypad (remotes rarely have
/// number keys). Pops the code once [accept] takes it; a refused code is
/// cleared and [error] shown. Back pops null.
Future<String?> showTvPasscodeDialog(
  BuildContext context, {
  required String title,
  bool Function(String code)? accept,
  String error = '密码错误',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) =>
        TvPasscodeDialog(title: title, accept: accept, error: error),
  );
}

class TvPasscodeDialog extends StatefulWidget {
  const TvPasscodeDialog({
    super.key,
    required this.title,
    this.accept,
    this.error = '密码错误',
  });

  static const length = 4;

  final String title;
  final bool Function(String code)? accept;
  final String error;

  @override
  State<TvPasscodeDialog> createState() => _TvPasscodeDialogState();
}

class _TvPasscodeDialogState extends State<TvPasscodeDialog> {
  String _code = '';
  bool _refused = false;

  void _press(String key) {
    setState(() {
      _refused = false;
      if (key == '⌫') {
        if (_code.isNotEmpty) _code = _code.substring(0, _code.length - 1);
        return;
      }
      _code += key;
    });
    if (_code.length < TvPasscodeDialog.length) return;
    if (widget.accept?.call(_code) ?? true) {
      Navigator.of(context).pop(_code);
    } else {
      setState(() {
        _code = '';
        _refused = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return Dialog(
      backgroundColor: TvTokens.surfaceHigh,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: text.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < TvPasscodeDialog.length; i++)
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _code.length
                          ? TvTokens.text
                          : const Color(0x33FFFFFF),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _refused ? widget.error : '',
              style: text.bodyMedium!.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 240,
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  for (final (i, key) in keys.indexed)
                    if (key.isEmpty)
                      const SizedBox.shrink()
                    else
                      Center(
                        child: TvButton(
                          label: key,
                          autofocus: i == 0,
                          onSelect: () => _press(key),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
