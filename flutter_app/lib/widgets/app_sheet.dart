import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The shared sheet shell — MD3 modal bottom sheet / HIG sheet at a medium
/// detent with a grabber.
///
/// Dismisses on scrim tap, on drag-down, and on the system back gesture (the
/// route is a real [PopupRoute], so back is handled by the navigator).
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required bool reduceMotion,
}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push<T>(_SheetRoute<T>(builder: builder, reduceMotion: reduceMotion));
}

class _SheetRoute<T> extends PopupRoute<T> {
  _SheetRoute({required this.builder, required this.reduceMotion});

  final WidgetBuilder builder;
  final bool reduceMotion;

  @override
  Color? get barrierColor => AppColor.scrim;

  @override
  bool get barrierDismissible => true;

  @override
  String get barrierLabel => 'Kapat';

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration =>
      reduceMotion ? Duration.zero : Motion.sheetIn;

  @override
  Duration get reverseTransitionDuration =>
      reduceMotion ? Duration.zero : const Duration(milliseconds: 220);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _SheetShell(
      animation: animation,
      child: Builder(builder: builder),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 103% of the panel height, matching the mock's off-screen start.
    final curved = CurvedAnimation(parent: animation, curve: Motion.decelerate);
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1.03),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    );
  }
}

class _SheetShell extends StatefulWidget {
  const _SheetShell({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<_SheetShell> createState() => _SheetShellState();
}

class _SheetShellState extends State<_SheetShell> {
  double _drag = 0;
  double _height = 0;

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _drag = (_drag + d.delta.dy).clamp(0, double.infinity));
  }

  void _onDragEnd(DragEndDetails d) {
    final far = _drag > (_height * 0.3).clamp(80, double.infinity);
    final flung = d.velocity.pixelsPerSecond.dy > 700;
    if (far || flung) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Mock pads 32pt; keep that floor but clear the home indicator.
    final bottomPad = media.padding.bottom + Space.s12;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(0, _drag),
        child: GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: Padding(
            // Lift the panel above the software keyboard (create sheet).
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: _Measure(
              onHeight: (h) => _height = h,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(Radii.sheet),
                  ),
                  boxShadow: Elevation.sheet,
                ),
                // A real Material, not just a coloured box: anything from the
                // material library inside the sheet (the create sheet's
                // TextField, for one) needs a Material ancestor.
                child: Material(
                  type: MaterialType.card,
                  color: AppColor.surfaceBright,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Radii.sheet),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: Space.s14,
                      left: Space.s20,
                      right: Space.s20,
                      bottom: bottomPad < 32 ? 32 : bottomPad,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 34,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: Space.s16),
                            decoration: BoxDecoration(
                              color: AppColor.outlineSheet,
                              borderRadius: BorderRadius.circular(
                                Radii.grabber,
                              ),
                            ),
                          ),
                        ),
                        widget.child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reports the laid-out height so the drag-to-dismiss threshold can be a
/// fraction of the panel rather than a magic number.
class _Measure extends SingleChildRenderObjectWidget {
  const _Measure({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasure(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasure renderObject) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMeasure extends RenderProxyBox {
  _RenderMeasure(this.onHeight);

  ValueChanged<double> onHeight;

  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}
