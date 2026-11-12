import 'package:flutter/material.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_bangumi_card.dart';

/// Title, one meta line (air date, score, rank, tags) and the summary.
class TvBangumiHeadline extends StatelessWidget {
  const TvBangumiHeadline({
    super.key,
    required this.item,
    this.titleLines = 1,
    this.summaryLines = 2,
  });

  final BangumiItem item;
  final int titleLines;
  final int summaryLines;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    final meta = [
      if (item.airDate.isNotEmpty) item.airDate,
      if (item.rank > 0) '排名 #${item.rank}',
      ...item.tags.take(3).map((tag) => tag.name),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tvBangumiTitle(item),
          maxLines: titleLines,
          overflow: TextOverflow.ellipsis,
          style: text.displaySmall,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (item.ratingScore > 0) ...[
              Icon(Icons.star_rounded, size: 18, color: accent),
              const SizedBox(width: 4),
              Text(
                item.ratingScore.toStringAsFixed(1),
                style: text.labelLarge!.copyWith(color: accent),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                meta.join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium!.copyWith(color: TvTokens.textMuted),
              ),
            ),
          ],
        ),
        if (item.summary.isNotEmpty && summaryLines > 0) ...[
          const SizedBox(height: 12),
          Text(
            item.summary.trim(),
            maxLines: summaryLines,
            overflow: TextOverflow.ellipsis,
            style: text.bodyLarge!.copyWith(color: TvTokens.textMuted),
          ),
        ],
      ],
    );
  }
}
