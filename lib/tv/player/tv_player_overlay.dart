import 'package:flutter/material.dart';
import 'package:kazumi/tv/tv_theme.dart';
import 'package:kazumi/tv/widgets/tv_focusable.dart';
import 'package:kazumi/tv/widgets/tv_row.dart';

/// Episode names for one road: the site's label, else 第 N 集.
List<String> tvEpisodeLabels(List<String> identifiers, int count) => [
  for (var i = 0; i < count; i++)
    i < identifiers.length && identifiers[i].isNotEmpty
        ? identifiers[i]
        : '第 ${i + 1} 集',
];

String _clock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  return '${h > 0 ? '$h:' : ''}${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

/// Full-screen controls: title on top, scrub bar and key hints at the bottom.
/// [seekTarget] is the pending D-pad seek; the bar shows it before the player
/// jumps there.
class TvPlayerControls extends StatelessWidget {
  const TvPlayerControls({
    super.key,
    required this.title,
    required this.subtitle,
    required this.position,
    required this.duration,
    required this.playing,
    this.seekTarget,
    this.actions,
  });

  final String title;
  final String subtitle;
  final Duration position;
  final Duration duration;
  final bool playing;
  final Duration? seekTarget;

  /// Button bar under the time row, reached with Down.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = Theme.of(context).colorScheme.primary;
    final shown = seekTarget ?? position;
    double fraction(Duration d) => duration.inMilliseconds <= 0
        ? 0.0
        : (d.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final delta = seekTarget == null ? null : seekTarget! - position;
    return Stack(
      fit: StackFit.expand,
      children: [
        const Align(
          alignment: Alignment.topCenter,
          child: _Scrim(height: 140, fromTop: true),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: _Scrim(height: 280, fromTop: false),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TvTokens.edgeH,
            vertical: TvTokens.edgeV,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineSmall,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: text.bodyLarge!.copyWith(color: TvTokens.textMuted),
              ),
              const Spacer(),
              if (delta != null)
                Align(
                  alignment: Alignment(fraction(shown) * 2 - 1, 0),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${delta.isNegative ? '-' : '+'}'
                      '${delta.abs().inSeconds} 秒',
                      style: text.titleMedium,
                    ),
                  ),
                ),
              _ScrubBar(
                played: fraction(shown),
                color: seekTarget == null ? accent : TvTokens.focus,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_clock(shown)} / ${_clock(duration)}',
                    style: text.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '◀ ▶ 快退 / 快进（按住加速）    OK 暂停    ▼ 更多操作',
                    style: text.bodyMedium!.copyWith(color: TvTokens.textMuted),
                  ),
                ],
              ),
              if (actions != null) ...[const SizedBox(height: 16), actions!],
            ],
          ),
        ),
      ],
    );
  }
}

class _Scrim extends StatelessWidget {
  const _Scrim({required this.height, required this.fromTop});

  final double height;
  final bool fromTop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: fromTop ? Alignment.topCenter : Alignment.bottomCenter,
            end: fromTop ? Alignment.bottomCenter : Alignment.topCenter,
            colors: const [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}

class _ScrubBar extends StatelessWidget {
  const _ScrubBar({required this.played, required this.color});

  final double played;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final x = constraints.maxWidth * played;
          return Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0x40FFFFFF),
                  borderRadius: TvTokens.pillRadius,
                ),
              ),
              Container(
                width: x,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: TvTokens.pillRadius,
                ),
              ),
              Positioned(
                left: x - 7,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: TvTokens.focus,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Large pause glyph shown while playback is paused and controls are hidden.
class TvPausedBadge extends StatelessWidget {
  const TvPausedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          color: Color(0x99000000),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.pause_rounded, size: 48),
      ),
    );
  }
}

/// Episode picker for the current road; the playing episode is focused on open.
///
/// Focus is requested explicitly because `autofocus` is ignored while another
/// node (the player's key handler) already holds focus.
class TvEpisodeList extends StatefulWidget {
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
  State<TvEpisodeList> createState() => _TvEpisodeListState();
}

class _TvEpisodeListState extends State<TvEpisodeList> {
  final _selectedNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _selectedNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _selectedNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final style = Theme.of(context).textTheme.titleMedium!;
    return Stack(
      children: [
        const Align(
          alignment: Alignment.bottomCenter,
          child: _Scrim(height: 220, fromTop: false),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TvTokens.edgeH - TvTokens.itemInset,
              0,
              TvTokens.edgeH - TvTokens.itemInset,
              TvTokens.edgeV,
            ),
            child: TvRow<int>(
              title: '选集',
              items: List.generate(widget.labels.length, (i) => i),
              itemExtent: 148,
              height: 80,
              initialIndex: widget.selectedIndex,
              itemBuilder: (context, index, _) {
                final playing = index == widget.selectedIndex;
                return TvFocusable(
                  focusNode: playing ? _selectedNode : null,
                  onSelect: () => widget.onSelect(index),
                  ring: false,
                  scale: 1.06,
                  builder: (context, focused) => AnimatedContainer(
                    duration: TvTokens.focusDuration,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    color: focused
                        ? TvTokens.focus
                        : (playing
                              ? accent.withValues(alpha: 0.35)
                              : const Color(0xCC26262C)),
                    child: Text(
                      widget.labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.copyWith(
                        color: focused ? Colors.black : TvTokens.text,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
