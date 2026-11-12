import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/widgets/tv_poster_card.dart';

String tvBangumiTitle(BangumiItem item) =>
    item.nameCn.isEmpty ? item.name : item.nameCn;

/// Poster card for a [BangumiItem]; OK opens its detail page.
TvPosterCard tvBangumiCard(
  BuildContext context,
  BangumiItem item, {
  bool autofocus = false,
  String? subtitle,
  ValueChanged<bool>? onFocusChange,
  VoidCallback? onLongPress,
}) {
  return TvPosterCard(
    title: tvBangumiTitle(item),
    subtitle: subtitle,
    autofocus: autofocus,
    onFocusChange: onFocusChange,
    onLongPress: onLongPress,
    cover: LayoutBuilder(
      builder: (context, constraints) => NetworkImgLayer(
        src: item.images['large'] ?? '',
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        borderRadius: BorderRadius.zero,
      ),
    ),
    onSelect: () => context.pushNamed(TvRoutes.info, arguments: item),
  );
}
