import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:todo_app/schema.graphql.dart';

import 'package:todo_app/stopwatch/arc_painter.dart';
import 'package:todo_app/stopwatch/helpers.dart';

export 'package:todo_app/stopwatch/helpers.dart';

enum StopwatchLifecycle {
  Started,
  Paused,
  Cancelled,
}

class DisplayStopwatch extends StatefulWidget {
  DisplayStopwatch({
    @required this.onChanged,
    @required this.value,
    this.placeholder,
    this.period = const Duration(minutes: 1),
  });

  final OnStopwatchChanged onChanged;
  final Duration period;
  final BuiltList<DatetimeInterval> value;

  final String placeholder;

  @override
  DisplayStopwatchState createState() => DisplayStopwatchState();
}

class DisplayStopwatchState extends State<DisplayStopwatch>
    with TickerProviderStateMixin {
  AnimationController controller;

  /// Number of times this stopwatch's arc has looped
  int loops;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loops = ((value?.elapsed ?? const Duration(minutes: 0)).inMilliseconds /
            widget.period.inMilliseconds)
        .floorToDouble()
        .toInt();
    controller = AnimationController(
      vsync: this,
      duration: widget.period,
      value: _animationValue,
    )..addStatusListener(handleLoop);
    if (value?.isOngoing ?? false) {
      animate();
    }
  }

  BuiltList<DatetimeInterval> get value => widget.value;

  // convert the elapsed into a part of the whole
  double get _animationValue {
    final dur = widget.period.inMilliseconds;
    final elapsed = (value?.elapsed?.inMilliseconds ?? 0) % dur;
    return 1.0 - ((dur - elapsed) / dur);
  }

  Duration get ellapsed {
    final dur = widget.period.inMilliseconds;
    final elapsedMilli = (dur * (loops + controller.value)).toInt();

    return Duration(milliseconds: elapsedMilli);
  }

  void handleLoop(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        loops++;
        animate();
      });
    }
  }

  void animate() {
    controller.forward(
      from: controller.value >= 1.0 ? 0.0 : controller.value,
    );
  }

  VoidCallback get timerToggle {
    final lifecycle = value?.isOngoing ?? false
        ? StopwatchLifecycle.Started
        : StopwatchLifecycle.Paused;
    switch (lifecycle) {
      case StopwatchLifecycle.Started:
        void pause() {
          setState(() {
            controller.stop();
            widget.onChanged(value.stopped);
          });
        }
        return pause;
      case StopwatchLifecycle.Paused:
      case StopwatchLifecycle.Cancelled:
      default:
        void start() {
          setState(() {
            animate();
            widget.onChanged(
              (value ?? <DatetimeInterval>[].build()).started,
            );
          });
        }
        return start;
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    final colorA = Colors.white;
    final colorB = themeData.indicatorColor;
    return Container(
      width: 108,
      // padding: EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, Widget child) {
                return DisplayDuration(
                  placeholder: widget.placeholder,
                  value: ellapsed,
                );
              }),
          StopwatchController(
            controller,
            timerToggle,
            backgroundColor: loops.isOdd ? colorA : colorB,
            color: loops.isOdd ? colorB : colorA,
          ),
          // TODO timer cancelation?
          if (false)
            ButtonContainer(
                size: 30,
                child: CircularButton(
                  padding: EdgeInsets.all(4),
                  iconColor: Colors.grey,
                  onPressed: value?.isEmpty ?? true
                      ? null
                      : () => setState(() {
                            controller
                                .fling(velocity: -5.0)
                                .then<void>((void cb) {
                              setState(() {});
                            });
                            widget.onChanged([].build());
                          }),
                  size: 25,
                  icon: Icons.clear,
                )),
        ],
      ),
    );
  }
}

class StopwatchController extends StatelessWidget {
  StopwatchController(
    this.controller,
    this.toggleStopwatch, {
    @required this.backgroundColor,
    @required this.color,
  });

  final Color backgroundColor;
  final Color color;
  final AnimationController controller;
  final VoidCallback toggleStopwatch;

  IconData get buttonIcon {
    if (controller.isAnimating) {
      switch (controller.status) {
        case AnimationStatus.forward:
          return Icons.pause;

        case AnimationStatus.reverse:
          return Icons.rotate_right;

        default:
          break;
      }
    }
    return toggleStopwatch == null ? Icons.check : Icons.play_arrow;
  }

  @override
  Widget build(BuildContext context) {
    // ThemeData themeData = Theme.of(context);
    final size = 50.0;
    final icon = buttonIcon;
    return ButtonContainer(
      size: size,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: <Widget>[
          if (false)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: controller,
                builder: (BuildContext context, Widget child) {
                  return CustomPaint(
                    size: Size.square(size),
                    painter: ArcPainter(
                      animation: controller,
                      backgroundColor: backgroundColor,
                      color: color,
                      direction: ArcDirection.Clockwise,
                    ),
                  );
                },
              ),
            ),
          ButtonContainer(
            margin: EdgeInsets.all(0.0),
            child: AnimatedBuilder(
              animation: controller,
              builder: (BuildContext context, Widget child) {
                return CircularButton(
                  size: size - 8,
                  icon: icon,
                  onPressed: toggleStopwatch,
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class CircularButton extends StatelessWidget {
  CircularButton({
    @required this.icon,
    @required this.size,
    @required this.onPressed,
    this.fillColor = Colors.white,
    this.iconColor,
    this.padding = const EdgeInsets.all(8.0),
  });

  final Color fillColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;
  final EdgeInsets padding;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size - padding.horizontal;
    return RawMaterialButton(
      onPressed: onPressed,
      shape: CircleBorder(),
      elevation: 2.0,
      fillColor: fillColor,
      padding: padding,
      child: Icon(
        icon,
        color: iconColor ?? Theme.of(context).accentColor,
        size: iconSize,
      ),
    );
  }
}

class ButtonContainer extends StatelessWidget {
  ButtonContainer({
    this.size,
    this.child,
    this.margin = const EdgeInsets.all(8),
  });

  final Widget child;
  final EdgeInsets margin;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      height: size,
      width: size,
      margin: margin,
      child: child,
    );
  }
}

class DisplayDuration extends StatelessWidget {
  const DisplayDuration({
    Key key,
    this.placeholder,
    this.value,
    this.style,
  }) : super(key: key);

  final String placeholder;
  final Duration value;
  final TextStyle style;

  String get timerString =>
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Text(
      value == null && placeholder != null ? placeholder : timerString,
      style: style ?? Theme.of(context).textTheme.caption,
    );
  }
}
