import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/tv/tv_routes.dart';
import 'package:kazumi/tv/widgets/tv_poster_card.dart';

/// Poster card for a [BangumiItem]; OK opens its detail page.
TvPosterCard tvBangumiCard(
  BuildContext context,
  BangumiItem item, {
  bool autofocus = false,
  String? subtitle,
}) {
  return TvPosterCard(
    title: item.nameCn.isEmpty ? item.name : item.nameCn,
    subtitle: subtitle,
    autofocus: autofocus,
    cover: LayoutBuilder(
      builder: (context, constraints) => NetworkImgLayer(
        src: item.images['large'] ?? '',
        width: constraints.maxWidth,
        height: constraints.maxHeight,
      ),
    ),
    onSelect: () => context.pushNamed(TvRoutes.info, arguments: item),
  );
}
