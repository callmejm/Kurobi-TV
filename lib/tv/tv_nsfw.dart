import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/tv/widgets/tv_passcode_dialog.dart';

/// Whether NSFW anime show in TV lists. Observable, so lists built in
/// an `Observer` update as soon as it is switched.
final tvShowNsfw = Observable<bool>(GStorage.getSetting(SettingsKeys.showNsfw));

/// Bangumi tags that mark an anime NSFW, editable behind the passcode.
final tvNsfwTags = Observable<Set<String>>(
  parseNsfwTags(GStorage.getSetting(SettingsKeys.nsfwTags)),
);

/// Splits user input on commas (either width) and whitespace.
Set<String> parseNsfwTags(String input) =>
    input.split(RegExp(r'[,，\s]+')).where((t) => t.isNotEmpty).toSet();

bool isNsfwTag(String name) => tvNsfwTags.value.contains(name);

bool isNsfwBangumi(BangumiItem item) =>
    item.tags.any((tag) => isNsfwTag(tag.name));

/// [items] without NSFW anime, unless they are switched on.
List<T> tvHideNsfw<T>(Iterable<T> items, BangumiItem Function(T) bangumi) {
  if (tvShowNsfw.value) return items.toList();
  return items.where((e) => !isNsfwBangumi(bangumi(e))).toList();
}

// A 4-digit code is guessable offline; this is a parental lock, not secrecy.
String _hash(String code) => sha256.convert(utf8.encode(code)).toString();

/// Asks for the passcode, creating one on first use. Returns whether it passed.
Future<bool> _unlock(BuildContext context) async {
  final stored = GStorage.getSetting(SettingsKeys.nsfwPasscode);
  if (stored.isEmpty) {
    final code = await showTvPasscodeDialog(context, title: '设置NSFW密码');
    if (code == null || !context.mounted) return false;
    final confirmed = await showTvPasscodeDialog(
      context,
      title: '再次输入密码',
      accept: (again) => again == code,
      error: '两次输入不一致',
    );
    if (confirmed == null) return false;
    await GStorage.putSetting(SettingsKeys.nsfwPasscode, _hash(code));
    return true;
  }
  final code = await showTvPasscodeDialog(
    context,
    title: '输入NSFW密码',
    accept: (code) => _hash(code) == stored,
  );
  return code != null;
}

/// Switches [tvShowNsfw] behind the passcode. Returns whether it switched.
Future<bool> tvToggleNsfw(BuildContext context) async {
  if (!await _unlock(context)) return false;
  final next = !tvShowNsfw.value;
  await GStorage.putSetting(SettingsKeys.showNsfw, next);
  runInAction(() => tvShowNsfw.value = next);
  return true;
}

/// Edits [tvNsfwTags] behind the passcode, since clearing them would show
/// everything. Returns whether they changed.
Future<bool> tvEditNsfwTags(BuildContext context) async {
  if (!await _unlock(context) || !context.mounted) return false;
  var input = tvNsfwTags.value.join(',');
  final saved = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('NSFW 标签'),
      content: TextFormField(
        initialValue: input,
        autofocus: true,
        decoration: const InputDecoration(helperText: '用逗号分隔，含任一标签即视为 NSFW'),
        onChanged: (value) => input = value,
        onFieldSubmitted: (value) => Navigator.of(dialogContext).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(input),
          child: const Text('确定'),
        ),
      ],
    ),
  );
  if (saved == null) return false;
  final tags = parseNsfwTags(saved);
  await GStorage.putSetting(SettingsKeys.nsfwTags, tags.join(','));
  runInAction(() => tvNsfwTags.value = tags);
  return true;
}
