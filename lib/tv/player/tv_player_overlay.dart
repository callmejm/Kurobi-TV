import 'package:flutter/material.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

String _clock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  return '${h > 0 ? '$h:' : ''}${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

/// Bottom bar: title, play state, progress and time.
class TvPlayerControls extends StatelessWidget {
  const TvPlayerControls({
    super.key,
    required this.title,
    required this.position,
    required this.duration,
    required this.playing,
  });

  final String title;
  final Duration position;
  final Duration duration;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 27),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                const SizedBox(width: 16),
                Expanded(child: LinearProgressIndicator(value: progress)),
                const SizedBox(width: 16),
                Text('${_clock(position)} / ${_clock(duration)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Episode picker for the current road; the playing episode starts focused.
class TvEpisodeList extends StatelessWidget {
  const TvEpisodeList({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final void Function(int index) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 24, 48, 27),
        child: TvRow<int>(
          title: '选集',
          items: List.generate(labels.length, (i) => i),
          itemExtent: 148,
          height: 72,
          itemBuilder: (context, index, _) => TvFocusable(
            autofocus: index == selectedIndex,
            onSelect: () => onSelect(index),
            child: ColoredBox(
              color: index == selectedIndex
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
              child: Center(
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
