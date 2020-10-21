import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './pop_in.dart';
import './cross_fade.dart';

import './backdrop_state_provider.dart';
import './leading_toggle_button.dart';

import 'package:major_components/src/backdrop/_simple_switcher.dart';
import 'package:major_components/src/backdrop/backdrop_bar_content.dart';

class BackdropBar extends StatefulWidget {
  BackdropBar({
    Key key,
    this.top,
    this.front,
    this.back,
    this.contentLayout = const BackdropBarContentLayout(),
  })  : assert(front != null || back != null || top != null),
        super(key: key);

  final BackdropBarContent back;

  final BackdropBarContent front;
  final double pixelToPercent = 0.01;

  final BackdropBarContentLayout contentLayout;

  /// A "top level" navigation element that is expected to be the same across pages.
  ///
  /// This allows for, say, having both detail front and categorical back content,
  /// as well as a overarching tab navigation.
  final BackdropBarContent top;

  @override
  _BackdropBarState createState() => _BackdropBarState();
}

class _BackdropBarState extends State<BackdropBar>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, watch, _) {
        final backdropState = watch(BackdropOpenState.current);
        return _BackdropBarRenderer(
          openState: backdropState,
          stack: widget,
        );
      },
    );
  }
}

/// Renders the given backdrops
///
/// Takes care of messy details like cross-fading defaults,
/// TODO and "peak" animations
///
/// Having this be it's own class also makes
/// managing the backdrop state easier
class _BackdropBarRenderer extends StatelessWidget {
  const _BackdropBarRenderer({
    Key key,
    @required this.openState,
    @required this.stack,
  }) : super(key: key);

  final BackdropOpenState openState;
  final BackdropBar stack;

  BackdropBarContent get top => stack.top;

  BackdropBarContent get front => stack.front;

  BackdropBarContent get back => stack.back;

  /// Applies peak animation to top bar if necessary
  Animation<double> get topBarAnimation {
    if (openState.peakBehavior == null) {
      return openState.controller.view;
    }
    return AnimationMax(
        openState.controller.view, openState.peakBehavior.controller.view);
  }

  Widget _withTop(Widget item, Widget top) {
    if (top == null) {
      return item;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PopIn(animation: topBarAnimation, child: top),
        item,
      ],
    );
  }

  /// Intelligently stack a BackdropBar widget
  Widget _stacked(Widget front, Widget back, Widget top) {
    if (back == null && front == null) {
      return top;
    }
    final item = crossFade(
      openState.isOpen,
      openState.controller,
      back,
      front,
    );
    return _withTop(
      switcher(item),
      switcher(top),
    );
  }

  Widget get leading {
    final lead = _stacked(front?.leading, back?.leading, top?.leading) ??
        LeadingToggleButton();
    assert(
      lead != null,
      'There must be at least one non-null leading widget in the BackdropBar stack.',
    );
    return lead;
  }

  Widget get title {
    final title = _stacked(front?.title, back?.title, top?.title);
    assert(
      title != null,
      'There must be at least one non-null title widget in the BackdropBar stack.',
    );
    return title;
  }

  Widget get trailing =>
      _stacked(front?.trailing, back?.trailing, top?.trailing);

  @override
  Widget build(BuildContext context) {
    final content = BackdropBarContent(
      leading: leading,
      title: title,
      trailing: trailing,
    );
    return stack.contentLayout.apply(context, content);
  }
}

class BackdropTitle extends StatelessWidget {
  const BackdropTitle({Key key, this.text, this.child})
      : assert(text != null || child != null),
        super(key: key);

  static BackdropTitle fromText(String text) =>
      BackdropTitle(text: text, key: Key(text));

  final Widget child;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
      child: child ??
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .headline5
                .copyWith(color: Colors.white),
          ),
    );
  }
}
