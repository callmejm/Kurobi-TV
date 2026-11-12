import 'package:flutter/material.dart';
import 'package:kazumi/bean/card/network_img_layer.dart';
import 'package:kazumi/tv/tv_theme.dart';

/// Full-bleed artwork on the right of the screen that fades into the page
/// background towards the left and bottom; cross-fades when [imageUrl]
/// changes. Gradients instead of blur: TV GPUs are too weak for live blur.
class TvBackdrop extends StatelessWidget {
  const TvBackdrop({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.68;
        final height = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              right: 0,
              width: width,
              height: height,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: NetworkImgLayer(
                  key: ValueKey(imageUrl),
                  src: imageUrl,
                  width: width,
                  height: height,
                  type: 'bg',
                  borderRadius: BorderRadius.zero,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  // Opaque under the headline column (about 56% wide).
                  stops: [0.42, 0.8],
                  colors: [TvTokens.background, Color(0x000A0A0C)],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.45],
                  colors: [TvTokens.background, Color(0x000A0A0C)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
