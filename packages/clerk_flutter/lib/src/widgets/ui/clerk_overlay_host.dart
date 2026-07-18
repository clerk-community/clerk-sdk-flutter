import 'package:flutter/widgets.dart';

/// Abstract class to provide access to displaying an overlay
abstract class ClerkOverlay<T extends StatefulWidget> extends State<T> {
  /// Insert an [Widget]
  void insert(Widget overlay);

  /// Remove an [Widget]
  void remove(Widget overlay);

  /// Is the [Widget] on display?
  bool isDisplaying(Widget overlay);

  /// Find the overlay host in widget tree
  static ClerkOverlay of(BuildContext context) {
    return context.findAncestorStateOfType<ClerkOverlay>()!;
  }
}

/// Displays widgets overlaying content of [child]
class ClerkOverlayHost extends StatefulWidget {
  /// Constructs a [ClerkOverlayHost]
  const ClerkOverlayHost({
    super.key,
    required this.child,
  });

  /// Child widget to wrap
  final Widget child;

  @override
  State<ClerkOverlayHost> createState() => _ClerkOverlayHostState();
}

class _ClerkOverlayHostState extends State<ClerkOverlayHost>
    implements ClerkOverlay<ClerkOverlayHost> {
  final _overlays = <Widget>[];

  @override
  bool isDisplaying(Widget overlay) => _overlays.contains(overlay);

  @override
  void insert(Widget overlay) {
    setState(() => _overlays.add(overlay));
  }

  @override
  void remove(Widget overlay) {
    setState(() => _overlays.remove(overlay));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      textDirection: TextDirection.ltr,
      children: [
        IgnorePointer(
          ignoring: _overlays.isNotEmpty,
          child: widget.child,
        ),
        ..._overlays,
      ],
    );
  }
}
