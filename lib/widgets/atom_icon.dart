import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AtomIcon extends StatelessWidget {
  const AtomIcon({super.key, this.size = 24});

  final double size;

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
  <circle cx="12" cy="12" r="2.5" fill="currentColor"/>
  
  <ellipse cx="12" cy="12" rx="3.5" ry="10" fill="none" stroke="currentColor" stroke-width="1.5" transform="rotate(30 12 12)"/>
  <ellipse cx="12" cy="12" rx="3.5" ry="10" fill="none" stroke="currentColor" stroke-width="1.5" transform="rotate(-30 12 12)"/>
  <ellipse cx="12" cy="12" rx="10" ry="3.5" fill="none" stroke="currentColor" stroke-width="1.5"/>
  
  <circle cx="12" cy="2" r="1.5" fill="currentColor" transform="rotate(30 12 2)"/>
  <circle cx="20.66" cy="17" r="1.5" fill="currentColor" transform="rotate(-30 20.66 17)"/>
  <circle cx="3.34" cy="17" r="1.5" fill="currentColor"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final color = iconTheme.color;
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
}

