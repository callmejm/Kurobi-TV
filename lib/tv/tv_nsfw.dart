import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/tv/widgets/tv_passcode_dialog.dart';

/// Whether adult (肉番) anime show in TV lists. Observable, so lists built in
/// an `Observer` update as soon as it is switched.
final tvShowNsfw = Observable<bool>(GStorage.getSetting(SettingsKeys.showNsfw));

/// Tags Bangumi users put on adult anime.
const _nsfwTags = {'肉番', '里番', 'R18'};

bool isNsfwTag(String name) => _nsfwTags.contains(name);

bool isNsfwBangumi(BangumiItem item) =>
    item.tags.any((tag) => isNsfwTag(tag.name));

/// [items] without adult anime, unless they are switched on.
List<T> tvHideNsfw<T>(Iterable<T> items, BangumiItem Function(T) bangumi) {
  if (tvShowNsfw.value) return items.toList();
  return items.where((e) => !isNsfwBangumi(bangumi(e))).toList();
}

// A 4-digit code is guessable offline; this is a parental lock, not secrecy.
String _hash(String code) => sha256.convert(utf8.encode(code)).toString();

/// Switches [tvShowNsfw] behind the passcode, creating one on first use.
/// Returns whether it switched.
Future<bool> tvToggleNsfw(BuildContext context) async {
  final stored = GStorage.getSetting(SettingsKeys.nsfwPasscode);
  if (stored.isEmpty) {
    final code = await showTvPasscodeDialog(context, title: '设置肉番密码');
    if (code == null || !context.mounted) return false;
    final confirmed = await showTvPasscodeDialog(
      context,
      title: '再次输入密码',
      accept: (again) => again == code,
      error: '两次输入不一致',
    );
    if (confirmed == null) return false;
    await GStorage.putSetting(SettingsKeys.nsfwPasscode, _hash(code));
  } else {
    final code = await showTvPasscodeDialog(
      context,
      title: '输入肉番密码',
      accept: (code) => _hash(code) == stored,
    );
    if (code == null) return false;
  }
  final next = !tvShowNsfw.value;
  await GStorage.putSetting(SettingsKeys.showNsfw, next);
  runInAction(() => tvShowNsfw.value = next);
  return true;
}
